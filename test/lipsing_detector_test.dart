import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/application/lipsing_detector.dart';

import 'helpers/fake_frames.dart';

/// Tests for the Yes/No lipsing decision.
///
/// The two things worth proving here are:
///   1. the detector says Yes when the mouth is open or moving, and
///   2. it does NOT flicker — it waits for several frames to agree.
void main() {
  group('LipsingDetector', () {
    test('starts with lipsing switched off', () {
      final detector = LipsingDetector();
      expect(detector.isLipsing, isFalse);
    });

    test('a still, closed mouth never counts as lipsing', () {
      final detector = LipsingDetector();

      for (var i = 0; i < 20; i++) {
        final result = detector.update(frame(mouthOpen: 0));
        expect(result.isLipsing, isFalse);
      }
    });

    test('a clearly wide-open mouth switches on immediately', () {
      final detector = LipsingDetector();

      // 0.8 is well above threshold (0.25) x instant multiplier (1.4) = 0.35,
      // so the detector does not wait for more frames.
      final result = detector.update(frame(mouthOpen: 0.8));

      expect(result.isLipsing, isTrue);
    });

    test('a slightly open mouth waits for three agreeing frames', () {
      final detector = LipsingDetector();

      // 0.30 is above the 0.25 threshold but below the 0.35 instant level.
      expect(detector.update(frame(mouthOpen: 0.30)).isLipsing, isFalse);
      expect(detector.update(frame(mouthOpen: 0.30)).isLipsing, isFalse);
      expect(detector.update(frame(mouthOpen: 0.30)).isLipsing, isTrue);
    });

    test('mouth movement alone counts as lipsing, even when barely open', () {
      final detector = LipsingDetector();

      // Each value stays under the 0.25 open threshold, but the mouth keeps
      // changing, which is exactly what silent mouthing looks like.
      final movements = [0.05, 0.20, 0.05, 0.20, 0.05, 0.20];
      var lipsing = false;
      for (final mouthOpen in movements) {
        lipsing = detector.update(frame(mouthOpen: mouthOpen)).isLipsing;
      }

      expect(lipsing, isTrue);
    });

    test('switches off again once the mouth goes still', () {
      final detector = LipsingDetector();
      detector.update(frame(mouthOpen: 0.8));
      expect(detector.isLipsing, isTrue);

      // Enough still frames to push the movement out of the history window
      // and then satisfy the three-frame wait.
      for (var i = 0; i < 15; i++) {
        detector.update(frame(mouthOpen: 0));
      }

      expect(detector.isLipsing, isFalse);
    });

    test('losing the face switches lipsing off after three frames', () {
      final detector = LipsingDetector();
      detector.update(frame(mouthOpen: 0.8));
      expect(detector.isLipsing, isTrue);

      expect(detector.update(noFaceFrame()).isLipsing, isTrue);
      expect(detector.update(noFaceFrame()).isLipsing, isTrue);
      expect(detector.update(noFaceFrame()).isLipsing, isFalse);
    });

    test('reset() clears the state completely', () {
      final detector = LipsingDetector();
      detector.update(frame(mouthOpen: 0.8));
      expect(detector.isLipsing, isTrue);

      detector.reset();

      expect(detector.isLipsing, isFalse);
    });

    test('a higher threshold makes detection stricter', () {
      final strict = LipsingDetector(mouthOpenThreshold: 0.60);

      // 0.30 would be enough with the default 0.25 threshold, but not here.
      for (var i = 0; i < 5; i++) {
        strict.update(frame(mouthOpen: 0.30));
      }

      expect(strict.isLipsing, isFalse);
    });

    test('the original frame values are passed through untouched', () {
      final detector = LipsingDetector();
      final input = frame(mouthOpen: 0.42, smile: 0.31, mouthPucker: 0.17);

      final output = detector.update(input);

      expect(output.mouthOpen, input.mouthOpen);
      expect(output.smile, input.smile);
      expect(output.mouthPucker, input.mouthPucker);
      expect(output.faceDetected, isTrue);
    });
  });
}
