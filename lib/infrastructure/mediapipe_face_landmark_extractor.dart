import 'package:flutter/services.dart';

import '../domain/face_lips_result.dart';

/// The Dart half of the bridge to native MediaPipe face detection.
///
/// Why this class is needed:
/// MediaPipe's Face Landmarker is a native library — there is no Dart version.
/// Flutter talks to native code through a *method channel*: Dart sends a
/// message with a method name and arguments, native code answers with a map.
/// This class is the only place in the app that knows about that channel, so
/// the rest of the Dart code can work with a plain [FaceLipsResult] object.
///
/// The matching native code lives in:
///   * Android — `android/app/src/main/kotlin/.../FaceLandmarkerBridge.kt`
///   * iOS     — `ios/Runner/FaceLandmarkerBridge.swift`
class MediaPipeFaceLandmarkExtractor {
  /// The channel name. It must match the string used on both native sides
  /// exactly, or the call is never delivered.
  static const String channelName = 'lips/offline/face';

  /// Native method that loads the `face_landmarker.task` model file.
  static const String initializeMethod = 'initializeFaceLandmarker';

  /// Native method that analyses one JPEG frame.
  static const String processFrameMethod = 'processFaceFrame';

  static const MethodChannel _channel = MethodChannel(channelName);

  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Asks the native side to load the MediaPipe model.
  ///
  /// Output: nothing on success; throws an [Exception] with a readable message
  /// on failure, which the home screen shows to the user.
  ///
  /// Calling this twice is safe — the second call returns immediately, because
  /// loading a 3.7 MB model more than once would waste time and memory.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    try {
      await _channel.invokeMethod(initializeMethod);
      _initialized = true;
    } on PlatformException catch (e) {
      // The usual cause is a missing model file, so the message says where the
      // file belongs instead of only showing an error code.
      throw Exception(
        e.message ??
            'Face landmarker failed to initialize (${e.code}). '
                'Ensure face_landmarker.task exists in android/app/src/main/assets '
                '(and iOS Runner bundle).',
      );
    } on MissingPluginException {
      // MissingPluginException is NOT a subtype of PlatformException — both
      // implement Exception separately — so it needs its own clause or it
      // escapes as a raw error with no explanation. It means the native half
      // of the bridge was never registered on this platform.
      throw Exception(
        'The native face landmarker is not available on this platform. '
            'The Android bridge is registered in MainActivity.kt and the iOS '
            'one in AppDelegate.swift; on a fresh checkout a full restart '
            '(not hot reload) is needed after either is added.',
      );
    }
  }

  /// Sends one JPEG frame to native MediaPipe and returns the mouth data.
  ///
  /// Input:  [bytes] — the frame as JPEG.
  ///         [width], [height] — the frame size in pixels.
  ///         [rotation] — extra rotation in degrees the native side should
  ///         apply (the app currently sends 0; the frame is already upright).
  /// Output: a [FaceLipsResult] holding the mouth blendshapes and mouth box.
  ///         When no face is found — or anything goes wrong — a result with
  ///         `faceDetected: false` is returned instead of throwing, so one bad
  ///         frame never interrupts the live camera.
  ///
  /// Steps:
  ///   1. Refuse obviously unusable input early.
  ///   2. Call native code across the method channel.
  ///   3. Read each value out of the reply map, defaulting to 0 if missing.
  Future<FaceLipsResult> processFrame({
    required Uint8List bytes,
    required int width,
    required int height,
    required int rotation,
  }) async {
    final bool inputIsUsable =
        _initialized && bytes.isNotEmpty && width > 0 && height > 0;
    if (!inputIsUsable) {
      return _noFaceResult();
    }

    Map<String, dynamic>? response;
    try {
      response = await _channel.invokeMapMethod<String, dynamic>(
        processFrameMethod,
        {
          'bytes': bytes,
          'width': width,
          'height': height,
          'rotation': rotation,
        },
      );
    } on PlatformException {
      // Native side failed on this frame; treat it as "no face this time".
      response = null;
    } on MissingPluginException {
      // Not a PlatformException, so it needs its own clause. Without it every
      // single frame throws instead of returning "no face" when the native
      // bridge is absent. initialize() reports that case properly; here the
      // frame is simply dropped.
      response = null;
    }

    if (response == null) {
      return _noFaceResult();
    }

    return _parseResponse(response);
  }

  /// Reads the native reply map into a [FaceLipsResult].
  ///
  /// Every value is read defensively (`as num?` then a default of 0) because
  /// the map crosses a platform boundary: a key could be missing or arrive as
  /// an int where a double is expected, and neither should crash the app.
  ///
  /// The mouth-box values are *normalized*: 0.0–1.0 fractions of the frame
  /// size, not pixels, so they work at any camera resolution.
  FaceLipsResult _parseResponse(Map<String, dynamic> response) {
    return FaceLipsResult(
      faceDetected: response['faceDetected'] == true,
      mouthOpen: _readNumber(response, 'mouthOpen'),
      mouthPucker: _readNumber(response, 'mouthPucker'),
      smile: _readNumber(response, 'smile'),
      mouthClose: _readNumber(response, 'mouthClose'),
      mouthFunnel: _readNumber(response, 'mouthFunnel'),
      mouthStretch: _readNumber(response, 'mouthStretch'),
      isLipsing: false, // Decided later by LipsingDetector, not by MediaPipe.
      ts: (response['ts'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      mouthMinX: _readNumber(response, 'mouthMinX'),
      mouthMinY: _readNumber(response, 'mouthMinY'),
      mouthMaxX: _readNumber(response, 'mouthMaxX'),
      mouthMaxY: _readNumber(response, 'mouthMaxY'),
    );
  }

  /// Reads one number from the native reply, or 0 when it is missing.
  static double _readNumber(Map<String, dynamic> response, String key) {
    return (response[key] as num?)?.toDouble() ?? 0;
  }

  /// The result used whenever no usable face data is available.
  /// The timestamp is still filled in so the screen can tell frames apart.
  FaceLipsResult _noFaceResult() {
    return FaceLipsResult(
      faceDetected: false,
      mouthOpen: 0,
      mouthPucker: 0,
      smile: 0,
      isLipsing: false,
      ts: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
