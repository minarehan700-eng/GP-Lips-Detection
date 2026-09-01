import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/application/lip_letter_detector.dart';
import 'package:lips_offline/domain/face_lips_result.dart';
import 'package:lips_offline/domain/viseme_group.dart';
import 'package:lips_offline/domain/word_challenge.dart';
import 'package:lips_offline/domain/word_session.dart';

void main() {
  final start = DateTime(2026, 1, 1, 12);

  FaceLipsResult seeing(String? shape, {double confidence = 0.9}) {
    return FaceLipsResult(
      faceDetected: shape != null,
      mouthOpen: 0.5,
      mouthPucker: 0,
      smile: 0,
      isLipsing: false,
      ts: 0,
      detectedLetter: shape,
      letterConfidence: shape == null ? 0 : confidence,
    );
  }

  group('what the five shapes cover', () {
    test('every letter of the alphabet belongs to a shape', () {
      // The claim the reference chart makes is that nothing is left out. This
      // is that claim, checked.
      final missing = <String>[];
      for (var c = 'a'.codeUnitAt(0); c <= 'z'.codeUnitAt(0); c++) {
        final letter = String.fromCharCode(c);
        if (VisemeGroup.shapeForLetter(letter) == null) {
          missing.add(letter);
        }
      }
      expect(missing, isEmpty,
          reason: 'these letters map to no mouth shape: $missing');
    });

    test('every digit can be practised as a spoken word', () {
      // A digit is not a mouth shape, but the word for it is a run of shapes.
      const spoken = [
        'zero', 'one', 'two', 'three', 'four',
        'five', 'six', 'seven', 'eight', 'nine',
      ];
      for (final word in spoken) {
        expect(WordChallenge.fromWord(word), isNotNull, reason: word);
        expect(WordLibrary.allWords, contains(word));
      }
    });

    test('every shape the detector reports has a group', () {
      for (final letter in LipLetterDetector.supportedLetters) {
        expect(VisemeGroup.forShape(letter), isNotNull,
            reason: 'the detector can report $letter with nothing to show');
      }
    });

    test('no letter is claimed by two shapes at once', () {
      final seen = <String, String>{};
      for (final group in VisemeGroup.all) {
        for (final letter in group.letters) {
          expect(seen.containsKey(letter), isFalse,
              reason: '"$letter" is in both ${seen[letter]} and ${group.shape}');
          seen[letter] = group.shape;
        }
      }
    });

    test('p, b and m share one shape, which is the whole point', () {
      // If this ever splits, the app is claiming to see a difference the lips
      // do not make.
      expect(VisemeGroup.shapeForLetter('p'), 'B');
      expect(VisemeGroup.shapeForLetter('b'), 'B');
      expect(VisemeGroup.shapeForLetter('m'), 'B');
    });

    test('every group offers words to try it with', () {
      for (final group in VisemeGroup.all) {
        expect(group.exampleWords, isNotEmpty, reason: group.shape);
        expect(group.mouthHint, isNotEmpty, reason: group.shape);
      }
    });
  });

  group('turning a word into shapes', () {
    test('a word becomes the run of shapes needed to say it', () {
      final challenge = WordChallenge.fromWord('mama')!;

      expect(challenge.shapes, ['B', 'A', 'B', 'A']);
    });

    test('a doubled letter is one shape, not two', () {
      // The mouth does not make the neutral shape twice for "ll"; asking for
      // that would be asking for something invisible.
      final challenge = WordChallenge.fromWord('hello')!;

      expect(challenge.shapes, ['D', 'E', 'D', 'C']);
    });

    test('a word of nothing but unmapped characters has no challenge', () {
      expect(WordChallenge.fromWord('123'), isNull);
      expect(WordChallenge.fromWord('!!'), isNull);
    });

    test('capitals make no difference', () {
      expect(
        WordChallenge.fromWord('HELLO')!.shapes,
        WordChallenge.fromWord('hello')!.shapes,
      );
    });

    test('every word in the library can actually be practised', () {
      for (final word in WordLibrary.allWords) {
        final challenge = WordChallenge.fromWord(word);
        expect(challenge, isNotNull, reason: word);
        expect(challenge!.length, greaterThan(0), reason: word);
        // A very long run stops being a lip-reading exercise and becomes a
        // memory test.
        expect(challenge.length, lessThanOrEqualTo(6),
            reason: '"$word" needs ${challenge.length} shapes');
      }
    });

    test('the library has no duplicates', () {
      final all = WordLibrary.allWords;
      expect(all.toSet().length, all.length);
    });
  });

  group('mouthing a word', () {
    WordSession sessionFor(String word) =>
        WordSession(challenge: WordChallenge.fromWord(word)!)..start(start);

    test('shapes must be made in order', () {
      final session = sessionFor('mama'); // B A B A

      // Making the second shape first gets the user nowhere.
      session.update(seeing('A'), start);
      expect(session.completedShapes, 0);
      expect(session.currentShape, 'B');
    });

    test('holding each shape steps through the word', () {
      final session = sessionFor('mama');
      var now = start;

      for (final shape in ['B', 'A', 'B', 'A']) {
        session.update(seeing(shape), now);
        now = now.add(WordSession.defaultHoldDuration);
        session.update(seeing(shape), now);
      }

      expect(session.isComplete, isTrue);
      expect(session.phase, WordPhase.complete);
    });

    test('a shape passed through without holding does not count', () {
      final session = sessionFor('mama');

      session.update(seeing('B'), start);
      final phase = session.update(
        seeing('A'),
        start.add(const Duration(milliseconds: 100)),
      );

      expect(phase, WordPhase.waiting);
      expect(session.completedShapes, 0);
    });

    test('running out of time ends the attempt', () {
      final session = sessionFor('mama');

      final phase = session.update(
        seeing('B'),
        start.add(WordSession.defaultTimeLimit),
      );

      expect(phase, WordPhase.expired);
      expect(session.isComplete, isFalse);
    });

    test('progress reports how far through the word the user is', () {
      final session = sessionFor('mama');
      expect(session.progress, 0.0);

      session.update(seeing('B'), start);
      session.update(seeing('B'), start.add(WordSession.defaultHoldDuration));

      expect(session.progress, 0.25);
      expect(session.completedShapes, 1);
    });

    test('a low-confidence reading does not advance the word', () {
      final session = sessionFor('mama');

      session.update(seeing('B', confidence: 0.05), start);
      session.update(
        seeing('B', confidence: 0.05),
        start.add(WordSession.defaultHoldDuration),
      );

      expect(session.completedShapes, 0);
    });

    test('time remaining falls from one to zero', () {
      final session = sessionFor('mama');

      expect(session.timeRemaining(start), 1.0);
      expect(session.timeRemaining(start.add(const Duration(seconds: 10))),
          closeTo(0.5, 0.01));
      expect(session.timeRemaining(start.add(const Duration(minutes: 5))), 0.0);
    });
  });
}
