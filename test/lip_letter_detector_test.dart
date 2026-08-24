import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/application/lip_letter_detector.dart';

import 'helpers/fake_frames.dart';

/// Tests for the A–E mouth-shape classifier.
///
/// These tests are the clearest description of the rule tree: each one sets up
/// one mouth shape and checks which letter comes out, including the cases
/// where two rules could both match and the priority order decides.
void main() {
  group('LipLetterDetector — one letter per mouth shape', () {
    test('A — a wide open mouth', () {
      final detector = LipLetterDetector();

      final result = detector.update(frame(mouthOpen: 1.0));

      expect(result.detectedLetter, 'A');
      expect(result.letterConfidence, closeTo(0.85, 0.001));
    });

    test('B — lips closed', () {
      final detector = LipLetterDetector();

      final result = detector.update(frame(mouthOpen: 0.0));

      expect(result.detectedLetter, 'B');
    });

    test('C — rounded, puckered lips', () {
      final detector = LipLetterDetector();

      final result = detector.update(frame(mouthPucker: 0.9));

      expect(result.detectedLetter, 'C');
      expect(result.letterConfidence, closeTo(0.9, 0.001));
    });

    test('D — a slightly open mouth', () {
      final detector = LipLetterDetector();

      final result = detector.update(frame(mouthOpen: 0.4));

      expect(result.detectedLetter, 'D');
    });

    test('E — a smile', () {
      final detector = LipLetterDetector();

      final result = detector.update(frame(smile: 0.9));

      expect(result.detectedLetter, 'E');
      expect(result.letterConfidence, closeTo(0.9, 0.001));
    });

    test('a funnel shape also counts as C', () {
      final detector = LipLetterDetector();

      final result = detector.update(frame(mouthFunnel: 0.8));

      expect(result.detectedLetter, 'C');
    });

    test('a sideways stretch also counts as E', () {
      final detector = LipLetterDetector();

      final result = detector.update(frame(mouthStretch: 0.8));

      expect(result.detectedLetter, 'E');
    });
  });

  group('LipLetterDetector — priority order', () {
    test('a smiling open mouth is E, not A', () {
      final detector = LipLetterDetector();

      // Both the smile rule and the wide-open rule match this shape.
      // E is asked first, so E wins.
      final result = detector.update(frame(mouthOpen: 1.0, smile: 0.9));

      expect(result.detectedLetter, 'E');
    });

    test('a strong pucker beats a weak smile', () {
      final detector = LipLetterDetector();

      // The smile passes its own threshold (0.30 >= 0.28), but it is far
      // weaker than the pucker, so the C rule takes over instead.
      final result = detector.update(frame(smile: 0.30, mouthPucker: 0.9));

      expect(result.detectedLetter, 'C');
    });

    test('a wide open mouth that is also puckered is not A', () {
      final detector = LipLetterDetector();

      final result = detector.update(frame(mouthOpen: 1.0, mouthPucker: 0.9));

      expect(result.detectedLetter, 'C');
    });
  });

  group('LipLetterDetector — steadiness and edge cases', () {
    test('no face means no letter at all', () {
      final detector = LipLetterDetector();
      detector.update(frame(mouthOpen: 1.0));

      final result = detector.update(noFaceFrame());

      expect(result.detectedLetter, isNull);
      expect(result.letterConfidence, 0);
    });

    test('a raised minimum score can reject every letter', () {
      final strict = LipLetterDetector(minScore: 0.95);

      final result = strict.update(frame(mouthOpen: 0.4));

      expect(result.detectedLetter, isNull);
      expect(result.letterConfidence, 0);
    });

    test('one odd frame does not change the letter', () {
      final detector = LipLetterDetector();

      // Four closed-mouth frames build up a solid "B" reading.
      for (var i = 0; i < 4; i++) {
        detector.update(frame(mouthOpen: 0.0));
      }

      // A single wide-open frame is out-voted by the median of the window.
      final result = detector.update(frame(mouthOpen: 1.0));

      expect(result.detectedLetter, 'B');
    });

    test('a real change of shape does come through', () {
      final detector = LipLetterDetector();
      for (var i = 0; i < 4; i++) {
        detector.update(frame(mouthOpen: 0.0));
      }

      // Held long enough to fill the whole window, the new shape wins.
      var letter = detector.update(frame(mouthOpen: 1.0)).detectedLetter;
      for (var i = 0; i < 5; i++) {
        letter = detector.update(frame(mouthOpen: 1.0)).detectedLetter;
      }

      expect(letter, 'A');
    });

    test('reset() clears the remembered letter', () {
      final detector = LipLetterDetector();
      for (var i = 0; i < 5; i++) {
        detector.update(frame(mouthOpen: 1.0));
      }

      detector.reset();

      // After a reset the very next frame decides on its own.
      final result = detector.update(frame(mouthOpen: 0.0));
      expect(result.detectedLetter, 'B');
    });

    test('confidence always stays between 0 and 1', () {
      final detector = LipLetterDetector();
      final shapes = [
        frame(mouthOpen: 1.0),
        frame(mouthPucker: 1.0),
        frame(smile: 1.0),
        frame(mouthOpen: 0.4),
        frame(mouthOpen: 0.0, mouthClose: 1.0),
      ];

      for (final shape in shapes) {
        final result = detector.update(shape);
        expect(result.letterConfidence, inInclusiveRange(0.0, 1.0));
      }
    });

    test('every letter it can report is one of the five it advertises', () {
      final detector = LipLetterDetector();
      final shapes = [
        frame(mouthOpen: 1.0),
        frame(mouthOpen: 0.0),
        frame(mouthPucker: 0.9),
        frame(mouthOpen: 0.4),
        frame(smile: 0.9),
      ];

      for (final shape in shapes) {
        final letter = detector.update(shape).detectedLetter;
        if (letter != null) {
          expect(LipLetterDetector.supportedLetters, contains(letter));
        }
      }
    });
  });
}
