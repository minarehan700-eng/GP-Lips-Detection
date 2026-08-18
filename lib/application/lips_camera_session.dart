import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import '../application/lip_letter_detector.dart';
import '../application/lipsing_detector.dart';
import '../core/detector_settings.dart';
import '../domain/face_lips_result.dart';
import '../infrastructure/camera_frame_encoder.dart';
import '../infrastructure/mediapipe_face_landmark_extractor.dart';

/// Manages camera streaming, frame processing, and detector state for the home screen.
class LipsCameraSession {
  LipsCameraSession({
    MediaPipeFaceLandmarkExtractor? extractor,
    CameraFrameEncoder? encoder,
  })  : _extractor = extractor ?? MediaPipeFaceLandmarkExtractor(),
        _encoder = encoder ?? CameraFrameEncoder();

  final MediaPipeFaceLandmarkExtractor _extractor;
  final CameraFrameEncoder _encoder;

  LipsingDetector _lipsingDetector = LipsingDetector();
  LipLetterDetector _lipLetterDetector = LipLetterDetector();

  CameraController? camera;
  String? cameraResolutionLabel;
  bool isFrontCamera = true;
  int frameImageWidth = 0;
  int frameImageHeight = 0;

  String initPhase = 'Starting...';
  String? error;
  FaceLipsResult result = FaceLipsResult.empty;

  bool _isProcessing = false;
  DateTime _lastProcessed = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> applyDetectorSettings() async {
    final settings = await DetectorSettings.load();
    _lipsingDetector = LipsingDetector(
      mouthOpenThreshold: settings.mouthOpenThreshold,
      motionThreshold: settings.motionThreshold,
    );
    _lipLetterDetector = LipLetterDetector(minScore: settings.letterMinScore);
  }

  /// Loads settings, initializes MediaPipe, opens the front camera, and starts the image stream.
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

      final cams = await availableCameras();
      if (cams.isEmpty) {
        error = 'No camera found on this device.';
        return;
      }

      final cam = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );

      final controller = await _openCamera(cam);
      if (controller == null) {
        error = 'Failed to initialize camera at any supported resolution.';
        return;
      }

      await controller.startImageStream((image) => _onFrame(image, onUpdate));
      final previewSize = controller.value.previewSize;
      camera = controller;
      isFrontCamera = cam.lensDirection == CameraLensDirection.front;
      cameraResolutionLabel = previewSize != null
          ? 'Camera: ${previewSize.width.toInt()}×${previewSize.height.toInt()}'
          : null;
      initPhase = 'Ready';
      error = null;
      onUpdate();
    } on PlatformException catch (e) {
      error = e.message ?? e.code;
      onUpdate();
    } catch (e) {
      error = e.toString();
      onUpdate();
    }
  }

  /// Tries several resolution presets until one initializes successfully.
  Future<CameraController?> _openCamera(CameraDescription cam) async {
    const presets = [
      ResolutionPreset.veryHigh,
      ResolutionPreset.high,
      ResolutionPreset.medium,
    ];
    for (final preset in presets) {
      final candidate = CameraController(
        cam,
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

  /// Throttled pipeline: encode frame → native face detect → update lipsing + letter detectors.
  Future<void> _onFrame(CameraImage image, void Function() onUpdate) async {
    if (_isProcessing) return;
    final now = DateTime.now();
    if (now.difference(_lastProcessed).inMilliseconds < 150) return;
    _lastProcessed = now;
    _isProcessing = true;

    try {
      final jpeg = await _encoder.encodeToJpeg(image, quality: 92);
      if (jpeg == null) return;

      final raw = await _extractor.processFrame(
        bytes: jpeg,
        width: image.width,
        height: image.height,
        rotation: 0,
      );
      final lipsing = _lipsingDetector.update(raw);
      result = _lipLetterDetector.update(lipsing);
      frameImageWidth = image.width;
      frameImageHeight = image.height;
      onUpdate();
    } finally {
      _isProcessing = false;
    }
  }

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

  Future<void> dispose() async {
    await camera?.dispose();
    camera = null;
  }
}
