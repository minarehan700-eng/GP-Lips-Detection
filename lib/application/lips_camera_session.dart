import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import '../application/lip_letter_detector.dart';
import '../application/lipsing_detector.dart';
import '../core/detector_settings.dart';
import '../domain/face_lips_result.dart';
import '../infrastructure/camera_frame_encoder.dart';
import '../infrastructure/mediapipe_face_landmark_extractor.dart';

/// Why a start-up attempt failed, in a form the screen can translate.
///
/// The session has no BuildContext and so cannot look up wording itself.
/// Reporting the *kind* of failure lets the screen say it in the user's
/// language, and keeps the one case with no friendly wording — a raw platform
/// message — clearly separate.
enum SessionFailure {
  /// The device reported no cameras at all.
  noCamera,

  /// Every resolution in [LipsCameraSession.resolutionPresetsToTry] failed.
  cameraInit,

  /// The MediaPipe model could not be loaded.
  landmarker,

  /// Anything else; [LipsCameraSession.errorDetail] carries the raw text.
  unknown,
}

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

  /// Size of the camera preview, or null before one is open.
  ///
  /// Kept as numbers rather than a finished string: the label around them
  /// ("Camera: 1280×720") is translated, so only the screen can build it.
  Size? cameraPreviewSize;

  /// Front cameras show a mirrored image, which the mouth overlay must undo.
  bool isFrontCamera = true;

  /// Size of the last analysed frame, used to place the mouth box correctly.
  int frameImageWidth = 0;
  int frameImageHeight = 0;

  /// What the loading screen currently says.
  String initPhase = 'Starting...';

  /// Why start-up failed, or null when everything is fine.
  SessionFailure? error;

  /// The raw platform text behind [error], shown only for
  /// [SessionFailure.unknown] where there is nothing friendlier to say.
  String? errorDetail;

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
      try {
        await _extractor.initialize();
      } catch (e) {
        error = SessionFailure.landmarker;
        errorDetail = e.toString();
        onUpdate();
        return;
      }

      initPhase = 'Starting camera...';
      onUpdate();

      final CameraDescription? chosenCamera = await _pickFrontCamera();
      if (chosenCamera == null) {
        error = SessionFailure.noCamera;
        onUpdate();
        return;
      }

      final CameraController? controller = await _openCamera(chosenCamera);
      if (controller == null) {
        error = SessionFailure.cameraInit;
        onUpdate();
        return;
      }

      // The controller is handed over BEFORE the stream starts. If
      // startImageStream throws, the catch below can only dispose what the
      // session owns; a controller still held in a local variable was
      // unreachable, so every failed attempt — and every "Try Again" after
      // one — left an initialized camera open.
      camera = controller;

      await controller.startImageStream((image) => _onFrame(image, onUpdate));

      isFrontCamera = chosenCamera.lensDirection == CameraLensDirection.front;
      cameraPreviewSize = controller.value.previewSize;
      initPhase = 'Ready';
      error = null;
      errorDetail = null;
      onUpdate();
    } on PlatformException catch (e) {
      // Raised by the camera plugin or the method channel, e.g. when the user
      // denies camera permission.
      error = SessionFailure.unknown;
      errorDetail = e.message ?? e.code;
      await _releaseFailedCamera();
      onUpdate();
    } catch (e) {
      error = SessionFailure.unknown;
      errorDetail = e.toString();
      await _releaseFailedCamera();
      onUpdate();
    }
  }

  /// Closes a camera that was opened but could not be brought into service.
  ///
  /// Without this the hardware stays held until the screen is closed, and the
  /// error view offers "Try Again", which would open a second one on top.
  Future<void> _releaseFailedCamera() async {
    final CameraController? failed = camera;
    camera = null;
    cameraPreviewSize = null;
    if (failed != null) {
      try {
        await failed.dispose();
      } catch (_) {
        // Disposing a controller that never fully opened can itself throw.
        // Nothing useful is left to do, and the original error is the one
        // worth showing the user.
      }
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
    } catch (_) {
      // One frame failing must not take the pipeline down with it. Without
      // this catch the error escapes into the camera plugin's stream callback
      // as an unhandled async error, once per bad frame. The previous result
      // stays on screen until a frame succeeds.
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
    cameraPreviewSize = null;
    _lipsingDetector.reset();
    _lipLetterDetector.reset();
    error = null;
    errorDetail = null;
    initPhase = 'Starting...';
    result = FaceLipsResult.empty;
    onUpdate();
    await initialize(onUpdate);
  }

  /// Closes the camera while the app is not on screen.
  ///
  /// Android reclaims the camera from a backgrounded app anyway, and a
  /// controller that was taken away does not recover — the preview comes back
  /// frozen. Releasing it deliberately means [resume] can open a fresh one.
  /// It also stops the phone showing the camera-in-use indicator for an app
  /// the user has switched away from.
  ///
  /// Detector state is kept, so returning to the app does not lose the
  /// practice target or the thresholds.
  Future<void> suspend() async {
    final CameraController? open = camera;
    camera = null;
    cameraPreviewSize = null;
    result = FaceLipsResult.empty;
    if (open != null) {
      try {
        await open.dispose();
      } catch (_) {
        // The platform may already have taken the camera back. Nothing is
        // gained by reporting that here — resume() opens a new one.
      }
    }
  }

  /// Opens the camera again after [suspend], when the app returns to screen.
  ///
  /// Does nothing when a camera is already open, so a duplicate lifecycle
  /// callback cannot open two.
  Future<void> resume(void Function() onUpdate) async {
    if (camera != null) {
      return;
    }
    await initialize(onUpdate);
  }

  /// Releases the camera when the screen is closed.
  /// Without this the camera would stay switched on in the background.
  Future<void> dispose() async {
    await camera?.dispose();
    camera = null;
  }
}
