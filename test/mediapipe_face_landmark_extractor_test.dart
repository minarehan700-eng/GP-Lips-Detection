import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/infrastructure/mediapipe_face_landmark_extractor.dart';

/// Tests for the Dart half of the native MediaPipe bridge.
///
/// The native side cannot run here, so the method channel is answered by a
/// mock. That is enough to cover what this class is responsible for: turning
/// whatever the platform returns — including nothing at all — into a
/// [FaceLipsResult] the pipeline can keep using.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(MediaPipeFaceLandmarkExtractor.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Answers the channel with [handler]; pass null to simulate a platform
  /// where the native bridge was never registered.
  void mockChannel(Future<Object?>? Function(MethodCall call)? handler) {
    messenger.setMockMethodCallHandler(channel, handler);
  }

  tearDown(() => mockChannel(null));

  final frame = Uint8List.fromList(List<int>.filled(16, 7));

  group('initialize', () {
    test('reports a readable error when the native bridge is missing', () async {
      // No mock handler is installed, so the channel raises
      // MissingPluginException — which is NOT a PlatformException and so
      // needs its own catch clause to be reported rather than escape raw.
      mockChannel(null);
      final extractor = MediaPipeFaceLandmarkExtractor();

      await expectLater(
        extractor.initialize(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('not available on this platform'),
          ),
        ),
      );
      expect(extractor.isInitialized, isFalse);
    });

    test('explains where the model file belongs when native reports failure',
        () async {
      mockChannel((_) async => throw PlatformException(code: 'NO_MODEL'));
      final extractor = MediaPipeFaceLandmarkExtractor();

      await expectLater(
        extractor.initialize(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('face_landmarker.task'),
          ),
        ),
      );
    });

    test('loading the model a second time does no further work', () async {
      var calls = 0;
      mockChannel((_) async {
        calls++;
        return null;
      });
      final extractor = MediaPipeFaceLandmarkExtractor();

      await extractor.initialize();
      await extractor.initialize();

      expect(calls, 1);
      expect(extractor.isInitialized, isTrue);
    });
  });

  group('processFrame', () {
    Future<MediaPipeFaceLandmarkExtractor> initialized(
      Future<Object?>? Function(MethodCall call) handler,
    ) async {
      mockChannel((call) async {
        if (call.method == MediaPipeFaceLandmarkExtractor.initializeMethod) {
          return null;
        }
        return handler(call);
      });
      final extractor = MediaPipeFaceLandmarkExtractor();
      await extractor.initialize();
      return extractor;
    }

    test('a missing native bridge drops the frame instead of throwing',
        () async {
      // The regression this guards: without a MissingPluginException clause
      // every frame threw, rather than one frame being skipped.
      final extractor = await initialized((_) async {
        throw MissingPluginException('no implementation found');
      });

      final result = await extractor.processFrame(
          bytes: frame, width: 4, height: 4, rotation: 0);

      expect(result.faceDetected, isFalse);
    });

    test('a native failure on one frame is reported as "no face"', () async {
      final extractor = await initialized(
          (_) async => throw PlatformException(code: 'DECODE_FAILED'));

      final result = await extractor.processFrame(
          bytes: frame, width: 4, height: 4, rotation: 0);

      expect(result.faceDetected, isFalse);
    });

    test('unusable input is rejected without calling native code', () async {
      var frameCalls = 0;
      final extractor = await initialized((_) async {
        frameCalls++;
        return <String, dynamic>{'faceDetected': true};
      });

      expect(
        (await extractor.processFrame(
                bytes: Uint8List(0), width: 4, height: 4, rotation: 0))
            .faceDetected,
        isFalse,
      );
      expect(
        (await extractor.processFrame(
                bytes: frame, width: 0, height: 4, rotation: 0))
            .faceDetected,
        isFalse,
      );

      expect(frameCalls, 0);
    });

    test('a full reply is read into the result', () async {
      final extractor = await initialized((_) async => <String, dynamic>{
            'faceDetected': true,
            'mouthOpen': 0.5,
            'mouthPucker': 0.25,
            'smile': 0.75,
            'mouthClose': 0.1,
            'mouthFunnel': 0.2,
            'mouthStretch': 0.3,
            'ts': 1234,
            'mouthMinX': 0.1,
            'mouthMinY': 0.2,
            'mouthMaxX': 0.8,
            'mouthMaxY': 0.9,
          });

      final result = await extractor.processFrame(
          bytes: frame, width: 4, height: 4, rotation: 0);

      expect(result.faceDetected, isTrue);
      expect(result.mouthOpen, 0.5);
      expect(result.smile, 0.75);
      expect(result.ts, 1234);
      expect(result.mouthMaxY, 0.9);
      // Lipsing is decided by LipsingDetector, never by the native side.
      expect(result.isLipsing, isFalse);
    });

    test('missing keys and int-for-double both survive the crossing', () async {
      // Values cross a platform boundary, where an int may arrive where a
      // double is expected and a key may simply be absent.
      final extractor = await initialized((_) async => <String, dynamic>{
            'faceDetected': true,
            'mouthOpen': 1, // int, not double
          });

      final result = await extractor.processFrame(
          bytes: frame, width: 4, height: 4, rotation: 0);

      expect(result.mouthOpen, 1.0);
      expect(result.mouthPucker, 0.0);
      expect(result.mouthMaxX, 0.0);
    });
  });
}
