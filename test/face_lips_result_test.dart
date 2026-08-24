import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/domain/face_lips_result.dart';

import 'helpers/fake_frames.dart';

/// Tests for the object that carries one frame's data through the pipeline.
void main() {
  group('FaceLipsResult.empty', () {
    test('describes "nothing detected yet"', () {
      const result = FaceLipsResult.empty;

      expect(result.faceDetected, isFalse);
      expect(result.isLipsing, isFalse);
      expect(result.detectedLetter, isNull);
      expect(result.letterConfidence, 0);
      expect(result.mouthOpen, 0);
      expect(result.hasMouthBox, isFalse);
    });
  });

  group('hasMouthBox', () {
    test('is false when no face was found', () {
      final result = frame(faceDetected: false, mouthMaxX: 1.0, mouthMaxY: 0.9);
      expect(result.hasMouthBox, isFalse);
    });

    test('is true for a normal mouth box', () {
      final result = frame(
        mouthMinX: 0.4,
        mouthMinY: 0.6,
        mouthMaxX: 0.6,
        mouthMaxY: 0.7,
      );
      expect(result.hasMouthBox, isTrue);
    });

    test('is false when the box has collapsed to almost nothing', () {
      // A box this small is a stray reading, not a real mouth.
      final result = frame(
        mouthMinX: 0.5,
        mouthMinY: 0.5,
        mouthMaxX: 0.5005,
        mouthMaxY: 0.5005,
      );
      expect(result.hasMouthBox, isFalse);
    });

    test('is false when the box is wide but completely flat', () {
      final result = frame(
        mouthMinX: 0.2,
        mouthMinY: 0.5,
        mouthMaxX: 0.8,
        mouthMaxY: 0.5,
      );
      expect(result.hasMouthBox, isFalse);
    });
  });

  group('copyWith', () {
    test('changes only the named field', () {
      final original = frame(mouthOpen: 0.4, smile: 0.2);

      final updated = original.copyWith(isLipsing: true);

      expect(updated.isLipsing, isTrue);
      expect(updated.mouthOpen, 0.4);
      expect(updated.smile, 0.2);
    });

    test('keeps the existing letter when none is given', () {
      final withLetter = frame().copyWith(detectedLetter: 'C');

      final updated = withLetter.copyWith(isLipsing: true);

      expect(updated.detectedLetter, 'C');
    });

    test('clearDetectedLetter removes the letter on purpose', () {
      final withLetter = frame().copyWith(detectedLetter: 'C');

      final updated = withLetter.copyWith(clearDetectedLetter: true);

      expect(updated.detectedLetter, isNull);
    });

    test('does not change the object it was called on', () {
      final original = frame(mouthOpen: 0.4);

      original.copyWith(mouthOpen: 0.9);

      expect(original.mouthOpen, 0.4);
    });
  });
}
