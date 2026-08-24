import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import '../application/lip_letter_detector.dart';
import '../application/lipsing_detector.dart';
import '../core/detector_settings.dart';
import '../domain/face_lips_result.dart';
import '../infrastructure/camera_frame_encoder.dart';
import '../infrastructure/mediapipe_face_landmark_extractor.dart';

/// Runs the whole detection pipeline for the home screen.
///
/// Why this class is needed:
/// The home screen should only *show* results. Everything about opening the
/// camera, throttling frames, calling MediaPipe and running the two detectors
/// lives here, so the screen code stays short and the pipeline can be read
/// top-to-bottom in one file.
///
/// The pipeline for one frame is:
///   camera frame → JPEG → native MediaPipe → LipsingDetector →
///   LipLetterDetector → [result] → screen redraw
class LipsCameraSession {
  LipsCameraSession({
    MediaPipeFaceLandmarkExtractor? extractor,
    CameraFrameEncoder? encoder,
  })  : _extractor = extractor ?? MediaPipeFaceLandmarkExtractor(),
        _encoder = encoder ?? CameraFrameEncoder();

  /// Only one frame in every 150 ms is analysed (about 6–7 per second).
  ///
  /// The camera pushes frames far faster than MediaPipe can process them.
  /// Analysing every frame would drain the battery and make the app stutter
  /// without making the letters any more accurate, because a mouth shape does
  /// not change meaningfully in a few milliseconds.
  static const int minMillisecondsBetweenFrames = 150;

  /// JPEG quality used when handing a frame to native code.
  /// High, because compression blur would blur the lip edges MediaPipe reads.
  static const int frameJpegQuality = 92;

  /// The camera image is already upright, so no extra rotation is applied.
  static const int frameRotationDegrees = 0;

  /// Resolutions to try, best first. Not every device supports every preset,
  /// so the session falls back down this list until one opens successfully.
  static const List<ResolutionPreset> resolutionPresetsToTry = [
    ResolutionPreset.veryHigh,
    ResolutionPreset.high,
    ResolutionPreset.medium,
  ];

  final MediaPipeFaceLandmarkExtractor _extractor;
  final CameraFrameEncoder _encoder;

  LipsingDetector _lipsingDetector = LipsingDetector();
  LipLetterDetector _lipLetterDetector = LipLetterDetector();

  /// The open camera, or null while starting up or after an error.
  CameraController? camera;

  /// Text such as "Camera: 1280×720", shown under the preview.
  String? cameraResolutionLabel;

  /// Front cameras show a mirrored image, which the mouth overlay must undo.
  bool isFrontCamera = true;

  /// Size of the last analysed frame, used to place the mouth box correctly.
  int frameImageWidth = 0;
  int frameImageHeight = 0;

  /// What the loading screen currently says.
  String initPhase = 'Starting...';

  /// The error message to show, or null when everything is fine.
  String? error;

  /// The latest detection result the screen should display.
  FaceLipsResult result = FaceLipsResult.empty;

  /// True while a frame is being analysed, so frames are not processed on top
  /// of each other.
  bool _isProcessing = false;

  /// When the last frame was accepted, used for the 150 ms throttle.
  DateTime _lastProcessed = DateTime.fromMillisecondsSinceEpoch(0);

  /// Rebuilds both detectors from the thresholds saved in Settings.
  ///
  /// Called at start-up and again every time the user returns from the
  /// Settings screen, so new slider values take effect immediately.
  /// The detectors are recreated rather than edited because their thresholds
  /// are final, and a fresh detector also clears any stale frame history.
  Future<void> applyDetectorSettings() async {
    final settings = await DetectorSettings.load();
    _lipsingDetector = LipsingDetector(
      mouthOpenThreshold: settings.mouthOpenThreshold,
      motionThreshold: settings.motionThreshold,
    );
    _lipLetterDetector = LipLetterDetector(minScore: settings.letterMinScore);
  }

  /// Starts everything the home screen needs, in order.
  ///
  /// Input:  [onUpdate] — called whenever the screen should redraw.
  /// Output: nothing; progress and problems are reported through [initPhase],
  ///         [error] and [onUpdate].
  ///
  /// Steps:
  ///   1. Load the saved thresholds.
  ///   2. Load the MediaPipe model on the native side.
  ///   3. Find and open the front camera.
  ///   4. Start the frame stream that drives [_onFrame].
  ///
  /// Any failure is caught and turned into a readable [error] message, because
  /// missing camera permission or a missing model file must not crash the app.
  Future<void> initialize(void Function() onUpdate) async {
    try {
      initPhase = 'Loading settings...';
      onUpdate();
      await applyDetectorSettings();

      initPhase = 'Loading face landmarker...';
      onUpdate();
      await _extractor.initialize();

      initPhase = 'Starting camera...';
      onUpdate();

      final CameraDescription? chosenCamera = await _pickFrontCamera();
      if (chosenCamera == null) {
        error = 'No camera found on this device.';
        return;
      }

      final CameraController? controller = await _openCamera(chosenCamera);
      if (controller == null) {
        error = 'Failed to initialize camera at any supported resolution.';
        return;
      }

      await controller.startImageStream((image) => _onFrame(image, onUpdate));

      camera = controller;
      isFrontCamera = chosenCamera.lensDirection == CameraLensDirection.front;
      cameraResolutionLabel = _describeResolution(controller);
      initPhase = 'Ready';
      error = null;
      onUpdate();
    } on PlatformException catch (e) {
      // Raised by the camera plugin or the method channel, e.g. when the user
      // denies camera permission.
      error = e.message ?? e.code;
      onUpdate();
    } catch (e) {
      error = e.toString();
      onUpdate();
    }
  }

  /// Returns the front camera, or the first available one if the device has no
  /// front camera. Returns null when the device reports no cameras at all.
  Future<CameraDescription?> _pickFrontCamera() async {
    final List<CameraDescription> cameras = await availableCameras();
    if (cameras.isEmpty) {
      return null;
    }

    return cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
  }

  /// Tries each resolution in [resolutionPresetsToTry] until one opens.
  ///
  /// Output: an initialized controller, or null when every preset failed.
  /// A failed candidate is disposed before trying the next one so the camera
  /// hardware is not left locked.
  Future<CameraController?> _openCamera(CameraDescription cameraDescription) async {
    for (final preset in resolutionPresetsToTry) {
      final candidate = CameraController(
        cameraDescription,
        preset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      try {
        await candidate.initialize();
        return candidate;
      } catch (_) {
        await candidate.dispose();
      }
    }
    return null;
  }

  /// Builds the "Camera: 1280×720" label, or null if the size is unknown.
  String? _describeResolution(CameraController controller) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return null;
    }
    return 'Camera: ${previewSize.width.toInt()}×${previewSize.height.toInt()}';
  }

  /// Handles one camera frame: this is the heart of the app.
  ///
  /// Input:  [image] — a raw frame from the camera stream.
  ///         [onUpdate] — called once a new [result] is ready.
  /// Side effect: replaces [result], [frameImageWidth] and [frameImageHeight].
  ///
  /// Steps:
  ///   1. Skip the frame if the previous one is still being analysed.
  ///   2. Skip the frame if less than 150 ms has passed (the throttle).
  ///   3. Convert the frame to JPEG.
  ///   4. Send it to native MediaPipe and get mouth numbers back.
  ///   5. Run the lipsing detector, then the letter detector on its output.
  ///   6. Tell the screen to redraw.
  Future<void> _onFrame(CameraImage image, void Function() onUpdate) async {
    if (_isProcessing) {
      return;
    }

    final DateTime now = DateTime.now();
    final int millisecondsSinceLastFrame =
        now.difference(_lastProcessed).inMilliseconds;
    if (millisecondsSinceLastFrame < minMillisecondsBetweenFrames) {
      return;
    }

    _lastProcessed = now;
    _isProcessing = true;

    try {
      final jpegBytes =
          await _encoder.encodeToJpeg(image, quality: frameJpegQuality);
      if (jpegBytes == null) {
        // The frame format was not one we can convert; just skip it.
        return;
      }

      final FaceLipsResult rawResult = await _extractor.processFrame(
        bytes: jpegBytes,
        width: image.width,
        height: image.height,
        rotation: frameRotationDegrees,
      );

      // The detectors run in order: the letter detector receives the result
      // that already carries the lipsing flag, so one object holds everything
      // the screen needs.
      final FaceLipsResult withLipsing = _lipsingDetector.update(rawResult);
      result = _lipLetterDetector.update(withLipsing);

      frameImageWidth = image.width;
      frameImageHeight = image.height;
      onUpdate();
    } finally {
      // Always clear the flag, even after an error, or the pipeline would
      // freeze and no further frame would ever be analysed.
      _isProcessing = false;
    }
  }

  /// Closes the camera, clears all detector state, and starts over.
  ///
  /// Used by the "Try Again" button on the error screen.
  Future<void> reset(void Function() onUpdate) async {
    await camera?.dispose();
    camera = null;
    cameraResolutionLabel = null;
    _lipsingDetector.reset();
    _lipLetterDetector.reset();
    error = null;
    initPhase = 'Starting...';
    result = FaceLipsResult.empty;
    onUpdate();
    await initialize(onUpdate);
  }

  /// Releases the camera when the screen is closed.
  /// Without this the camera would stay switched on in the background.
  Future<void> dispose() async {
    await camera?.dispose();
    camera = null;
  }
}
