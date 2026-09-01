import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/domain/face_lips_result.dart';
import 'package:lips_offline/domain/practice_session.dart';

/// Tests for the guided practice round.
///
/// Time is passed into the session rather than read from a clock, so these run
/// instantly and deterministically instead of sleeping.
void main() {
  final start = DateTime(2026, 1, 1, 12);

  FaceLipsResult seeing(String? letter, {double confidence = 0.9}) {
    return FaceLipsResult(
      faceDetected: letter != null,
      mouthOpen: 0.5,
      mouthPucker: 0,
      smile: 0,
      isLipsing: false,
      ts: 0,
      detectedLetter: letter,
      letterConfidence: letter == null ? 0 : confidence,
    );
  }

  PracticeSession sessionOf(List<String> targets) {
    final session = PracticeSession(targets: targets)..start(start);
    return session;
  }

  group('holding a shape', () {
    test('one good frame is not enough', () {
      final session = sessionOf(['A']);

      final phase = session.update(seeing('A'), start);

      // The classifier passes through neighbouring shapes on the way to the
      // right one. Crediting a single frame would score those too.
      expect(phase, PracticePhase.holding);
      expect(session.completedCount, 0);
    });

    test('holding for the full duration confirms the letter', () {
      final session = sessionOf(['A']);

      session.update(seeing('A'), start);
      final phase = session.update(
        seeing('A'),
        start.add(PracticeSession.defaultHoldDuration),
      );

      expect(phase, PracticePhase.finished);
      expect(session.attempts.single.succeeded, isTrue);
      expect(session.attempts.single.letter, 'A');
    });

    test('losing the shape restarts the hold from nothing', () {
      final session = sessionOf(['A']);

      session.update(seeing('A'), start);
      // Flicker off the shape...
      session.update(seeing('B'), start.add(const Duration(milliseconds: 300)));
      // ...and back on. The earlier 300 ms must not count towards the hold.
      session.update(seeing('A'), start.add(const Duration(milliseconds: 400)));
      final phase = session.update(
        seeing('A'),
        start.add(const Duration(milliseconds: 900)),
      );

      expect(phase, PracticePhase.holding,
          reason: 'only 500 ms of unbroken hold has passed');
      expect(session.completedCount, 0);
    });

    test('a different letter never counts', () {
      final session = sessionOf(['A']);

      session.update(seeing('C'), start);
      final phase = session.update(
        seeing('C'),
        start.add(PracticeSession.defaultHoldDuration),
      );

      expect(phase, PracticePhase.waiting);
      expect(session.completedCount, 0);
    });

    test('a low-confidence detection does not sustain a hold', () {
      final session = sessionOf(['A']);

      session.update(seeing('A', confidence: 0.10), start);
      final phase = session.update(
        seeing('A', confidence: 0.10),
        start.add(PracticeSession.defaultHoldDuration),
      );

      expect(phase, PracticePhase.waiting);
    });

    test('losing the face entirely breaks the hold', () {
      final session = sessionOf(['A']);

      session.update(seeing('A'), start);
      session.update(seeing(null), start.add(const Duration(milliseconds: 300)));
      final phase = session.update(
        seeing('A'),
        start.add(const Duration(milliseconds: 800)),
      );

      expect(phase, PracticePhase.holding);
      expect(session.completedCount, 0);
    });
  });

  group('running out of time', () {
    test('a letter that is never made is marked missed and moves on', () {
      final session = sessionOf(['A', 'B']);

      final phase = session.update(
        seeing('C'),
        start.add(PracticeSession.defaultTimeLimit),
      );

      expect(phase, PracticePhase.missed);
      expect(session.attempts.single.succeeded, isFalse);
      expect(session.currentTarget, 'B',
          reason: 'a shape the user cannot make must not strand the session');
    });

    test('the clock restarts for each new letter', () {
      final session = sessionOf(['A', 'B']);
      final missedAt = start.add(PracticeSession.defaultTimeLimit);

      session.update(seeing('C'), missedAt);
      // B has just been presented, so it has its full time, not zero.
      expect(session.timeRemaining(missedAt), 1.0);

      session.update(seeing('B'), missedAt);
      final phase = session.update(
        seeing('B'),
        missedAt.add(PracticeSession.defaultHoldDuration),
      );

      expect(phase, PracticePhase.finished);
      expect(session.attempts.last.succeeded, isTrue);
    });

    test('a miss still records how close the user got', () {
      final session = sessionOf(['A']);

      session.update(seeing('A', confidence: 0.55), start);
      session.update(
        seeing('C'),
        start.add(PracticeSession.defaultTimeLimit),
      );

      // "You nearly had it" is a different message from "you were nowhere
      // near", and only the best confidence can tell them apart.
      expect(session.attempts.single.bestConfidence, closeTo(0.55, 0.001));
    });
  });

  group('progress reporting', () {
    test('hold progress runs from zero to one and stops there', () {
      final session = sessionOf(['A']);
      session.update(seeing('A'), start);

      expect(session.holdProgress(start), 0.0);
      expect(
        session.holdProgress(start.add(const Duration(milliseconds: 350))),
        closeTo(0.5, 0.01),
      );
      // A late frame must not push the ring past full.
      expect(session.holdProgress(start.add(const Duration(seconds: 5))), 1.0);
    });

    test('time remaining falls from one to zero and stops there', () {
      final session = sessionOf(['A']);
      session.update(seeing('C'), start);

      expect(session.timeRemaining(start), 1.0);
      expect(session.timeRemaining(start.add(const Duration(seconds: 6))),
          closeTo(0.5, 0.01));
      expect(session.timeRemaining(start.add(const Duration(minutes: 1))), 0.0);
    });

    test('counts describe how far through the round the user is', () {
      final session = sessionOf(['A', 'B', 'C']);

      expect(session.totalCount, 3);
      expect(session.completedCount, 0);
      expect(session.currentTarget, 'A');

      session.update(seeing('A'), start);
      session.update(seeing('A'), start.add(PracticeSession.defaultHoldDuration));

      expect(session.completedCount, 1);
      expect(session.currentTarget, 'B');
    });
  });

  group('finishing', () {
    test('every letter attempted ends the session', () {
      final session = sessionOf(['A', 'B']);
      var now = start;

      for (final letter in ['A', 'B']) {
        session.update(seeing(letter), now);
        now = now.add(PracticeSession.defaultHoldDuration);
        session.update(seeing(letter), now);
      }

      expect(session.isFinished, isTrue);
      expect(session.currentTarget, isNull);
      expect(session.attempts.length, 2);
    });

    test('feeding a finished session more frames changes nothing', () {
      final session = sessionOf(['A']);
      session.update(seeing('A'), start);
      session.update(seeing('A'), start.add(PracticeSession.defaultHoldDuration));

      final phase = session.update(
        seeing('A'),
        start.add(const Duration(seconds: 30)),
      );

      expect(phase, PracticePhase.finished);
      expect(session.attempts.length, 1);
    });

    test('starting again clears the previous score', () {
      final session = sessionOf(['A']);
      session.update(seeing('A'), start);
      session.update(seeing('A'), start.add(PracticeSession.defaultHoldDuration));
      expect(session.attempts, isNotEmpty);

      session.start(start.add(const Duration(minutes: 1)));

      expect(session.attempts, isEmpty);
      expect(session.isFinished, isFalse);
      expect(session.currentTarget, 'A');
    });
  });
}
