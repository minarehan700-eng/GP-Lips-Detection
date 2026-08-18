import 'package:flutter/services.dart';

import '../domain/face_lips_result.dart';

/// Flutter bridge to the native MediaPipe Face Landmarker (Android/iOS).
class MediaPipeFaceLandmarkExtractor {
  static const MethodChannel _channel = MethodChannel('lips/offline/face');
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Loads the face landmarker model on the native side.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _channel.invokeMethod('initializeFaceLandmarker');
      _initialized = true;
    } on PlatformException catch (e) {
      throw Exception(
        e.message ??
            'Face landmarker failed to initialize (${e.code}). '
                'Ensure face_landmarker.task exists in android/app/src/main/assets '
                '(and iOS Runner bundle).',
      );
    }
  }

  /// Sends a JPEG frame to native code and parses mouth metrics from the response.
  Future<FaceLipsResult> processFrame({
    required Uint8List bytes,
    required int width,
    required int height,
    required int rotation,
  }) async {
    if (!_initialized || bytes.isEmpty || width <= 0 || height <= 0) {
      return FaceLipsResult(
        faceDetected: false,
        mouthOpen: 0,
        mouthPucker: 0,
        smile: 0,
        isLipsing: false,
        ts: DateTime.now().millisecondsSinceEpoch,
      );
    }

    Map<String, dynamic>? response;
    try {
      response = await _channel.invokeMapMethod<String, dynamic>(
        'processFaceFrame',
        {
          'bytes': bytes,
          'width': width,
          'height': height,
          'rotation': rotation,
        },
      );
    } on PlatformException {
      response = null;
    }

    if (response == null) {
      return FaceLipsResult(
        faceDetected: false,
        mouthOpen: 0,
        mouthPucker: 0,
        smile: 0,
        isLipsing: false,
        ts: DateTime.now().millisecondsSinceEpoch,
      );
    }

    return FaceLipsResult(
      faceDetected: response['faceDetected'] == true,
      mouthOpen: (response['mouthOpen'] as num?)?.toDouble() ?? 0,
      mouthPucker: (response['mouthPucker'] as num?)?.toDouble() ?? 0,
      smile: (response['smile'] as num?)?.toDouble() ?? 0,
      mouthClose: (response['mouthClose'] as num?)?.toDouble() ?? 0,
      mouthFunnel: (response['mouthFunnel'] as num?)?.toDouble() ?? 0,
      mouthStretch: (response['mouthStretch'] as num?)?.toDouble() ?? 0,
      isLipsing: false,
      ts: (response['ts'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      mouthMinX: (response['mouthMinX'] as num?)?.toDouble() ?? 0,
      mouthMinY: (response['mouthMinY'] as num?)?.toDouble() ?? 0,
      mouthMaxX: (response['mouthMaxX'] as num?)?.toDouble() ?? 0,
      mouthMaxY: (response['mouthMaxY'] as num?)?.toDouble() ?? 0,
    );
  }
}
