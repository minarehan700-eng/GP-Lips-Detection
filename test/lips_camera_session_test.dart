import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/application/lips_camera_session.dart';
import 'package:lips_offline/domain/face_lips_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests for the parts of the session that do not need camera hardware.
///
/// Opening a camera cannot be simulated here, so what is covered is the
/// state handling around it: suspending for the background, coming back, and
/// failing in a way the user can recover from. The camera path itself still
/// has to be checked on a phone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('suspend', () {
    test('is safe when no camera was ever opened', () async {
      final session = LipsCameraSession();

      await expectLater(session.suspend(), completes);

      expect(session.camera, isNull);
    });

    test('clears what the screen was showing', () async {
      final session = LipsCameraSession()
        ..cameraPreviewSize = const Size(1280, 720)
        ..result = const FaceLipsResult(
          faceDetected: true,
          mouthOpen: 0.9,
          mouthPucker: 0.1,
          smile: 0.2,
          isLipsing: true,
          ts: 42,
        );

      await session.suspend();

      // A stale "Lipsing: Yes" left frozen on screen while the app is in the
      // background would be wrong by the time the user came back.
      expect(session.result.faceDetected, isFalse);
      expect(session.result.isLipsing, isFalse);
      expect(session.cameraPreviewSize, isNull);
    });
  });

  group('initialize without a camera plugin', () {
    test('reports an error rather than throwing', () async {
      // No native side exists in a test, so the face landmarker channel
      // raises MissingPluginException. That has to arrive as a readable
      // error on screen, not as an unhandled exception.
      final session = LipsCameraSession();
      var updates = 0;

      await session.initialize(() => updates++);

      expect(session.error, isNotNull);
      expect(updates, greaterThan(0));
    });

    test('leaves no camera behind when start-up fails', () async {
      // The leak this guards: a controller opened but never handed to the
      // session stayed unreachable, so every retry opened another one.
      final session = LipsCameraSession();

      await session.initialize(() {});

      expect(session.camera, isNull);
      expect(session.cameraPreviewSize, isNull);
    });

    test('retrying after a failure still ends in a reportable state', () async {
      final session = LipsCameraSession();

      await session.initialize(() {});
      await session.reset(() {});

      expect(session.error, isNotNull);
      expect(session.camera, isNull);
    });
  });

  group('resume', () {
    test('tries to open the camera again after a suspend', () async {
      final session = LipsCameraSession();

      await session.suspend();
      await session.resume(() {});

      // No camera exists in a test, so the attempt fails — but it must be an
      // attempt, not a silent no-op, or the screen stays black on return.
      expect(session.error, isNotNull);
    });
  });
}
