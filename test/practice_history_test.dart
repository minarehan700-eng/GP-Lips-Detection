import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/domain/practice_session.dart';
import 'package:lips_offline/domain/session_record.dart';
import 'package:lips_offline/infrastructure/practice_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests for keeping practice results between launches.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  SessionRecord recordOf(
    List<(String, bool)> results, {
    DateTime? at,
  }) {
    return SessionRecord(
      finishedAt: at ?? DateTime(2026, 1, 1),
      results: [
        for (final (letter, ok) in results)
          (
            letter: letter,
            succeeded: ok,
            bestConfidence: ok ? 0.8 : 0.2,
            confusedWith: null,
          ),
      ],
      totalMilliseconds: 1000 * results.length,
    );
  }

  group('scoring one round', () {
    test('accuracy is the share of letters held', () {
      final record = recordOf([('A', true), ('B', false), ('C', true)]);

      expect(record.hits, 2);
      expect(record.total, 3);
      expect(record.accuracy, closeTo(2 / 3, 0.001));
    });

    test('an empty round does not divide by zero', () {
      final record = recordOf([]);

      expect(record.accuracy, 0);
      expect(record.bestStreak, 0);
    });

    test('the best streak is the longest unbroken run', () {
      final record = recordOf([
        ('A', true),
        ('B', true),
        ('C', false),
        ('D', true),
        ('E', true),
        ('A', true),
      ]);

      expect(record.bestStreak, 3, reason: 'the run of three at the end');
    });

    test('a round is built from what the session scored', () {
      final attempts = [
        const PracticeAttempt(
            letter: 'A',
            succeeded: true,
            millisecondsTaken: 900,
            bestConfidence: 0.91),
        const PracticeAttempt(
            letter: 'B',
            succeeded: false,
            millisecondsTaken: 12000,
            bestConfidence: 0.14),
      ];

      final record = SessionRecord.fromAttempts(attempts, DateTime(2026, 5, 5));

      expect(record.total, 2);
      expect(record.hits, 1);
      expect(record.totalMilliseconds, 12900);
      expect(record.results.first.bestConfidence, closeTo(0.91, 0.001));
    });
  });

  group('storing rounds', () {
    test('a saved round survives being read back', () async {
      final store = PracticeHistoryStore();
      final record = recordOf([('A', true), ('B', false)]);

      await store.add(record);
      final loaded = await store.load();

      expect(loaded, hasLength(1));
      expect(loaded.single.hits, 1);
      expect(loaded.single.results.map((r) => r.letter), ['A', 'B']);
      expect(loaded.single.finishedAt, record.finishedAt);
    });

    test('rounds come back newest first', () async {
      final store = PracticeHistoryStore();

      await store.add(recordOf([('A', true)], at: DateTime(2026, 1, 1)));
      await store.add(recordOf([('B', true)], at: DateTime(2026, 3, 1)));
      await store.add(recordOf([('C', true)], at: DateTime(2026, 2, 1)));

      final loaded = await store.load();

      expect(
        loaded.map((r) => r.results.single.letter),
        ['B', 'C', 'A'],
      );
    });

    test('the oldest rounds fall off once the cap is reached', () async {
      // Unbounded growth would slow every launch: shared_preferences reads the
      // whole store into memory at start-up.
      final store = PracticeHistoryStore(maxRecords: 3);

      for (var i = 1; i <= 5; i++) {
        await store.add(recordOf([('A', true)], at: DateTime(2026, 1, i)));
      }

      final loaded = await store.load();

      expect(loaded, hasLength(3));
      expect(loaded.first.finishedAt, DateTime(2026, 1, 5));
      expect(loaded.last.finishedAt, DateTime(2026, 1, 3));
    });

    test('one unreadable row does not cost the user the rest', () async {
      // An entry written by an older version, or a write cut short, must not
      // take the whole history down with it.
      final good = recordOf([('A', true)]).encode();
      SharedPreferences.setMockInitialValues({
        'flutter.${PracticeHistoryStore.storageKey}': <String>[
          good,
          'not json at all',
          '{"at": "wrong type"}',
        ],
      });

      final loaded = await PracticeHistoryStore().load();

      expect(loaded, hasLength(1));
      expect(loaded.single.results.single.letter, 'A');
    });

    test('clearing removes everything', () async {
      final store = PracticeHistoryStore();
      await store.add(recordOf([('A', true)]));

      await store.clear();

      expect(await store.load(), isEmpty);
    });
  });

  group('what to practise next', () {
    test('per-letter totals add up across rounds', () {
      final records = [
        recordOf([('A', true), ('B', false)]),
        recordOf([('A', false), ('B', false)]),
      ];

      final stats = PracticeHistoryStore.statsByLetter(records, ['A', 'B', 'C']);

      expect(stats.map((s) => s.letter), ['A', 'B', 'C']);
      expect(stats[0].attempts, 2);
      expect(stats[0].hits, 1);
      expect(stats[1].hits, 0);
      expect(stats[2].attempts, 0, reason: 'C has never been tried');
      expect(stats[2].accuracy, 0, reason: 'and must not divide by zero');
    });

    test('letters keep the order they were given in', () {
      // Otherwise the list reshuffles under the user's finger as scores change.
      final stats = PracticeHistoryStore.statsByLetter(
        [recordOf([('E', true), ('A', true)])],
        ['A', 'B', 'C', 'D', 'E'],
      );

      expect(stats.map((s) => s.letter), ['A', 'B', 'C', 'D', 'E']);
    });

    test('the weakest letter is the one to work on', () {
      final records = [
        recordOf([('A', true), ('A', true), ('A', true)]),
        recordOf([('B', false), ('B', false), ('B', true)]),
      ];
      final stats = PracticeHistoryStore.statsByLetter(records, ['A', 'B']);

      expect(PracticeHistoryStore.weakestLetter(stats)?.letter, 'B');
    });

    test('a letter barely tried is not called a weakness', () {
      // One unlucky attempt should not brand a letter as the user's problem.
      final records = [
        recordOf([('A', false)]),
        recordOf([('B', false), ('B', false), ('B', true), ('B', true)]),
      ];
      final stats = PracticeHistoryStore.statsByLetter(records, ['A', 'B']);

      expect(PracticeHistoryStore.weakestLetter(stats)?.letter, 'B');
    });

    test('with nothing practised enough, there is no advice to give', () {
      final stats = PracticeHistoryStore.statsByLetter(
        [recordOf([('A', false)])],
        ['A'],
      );

      expect(PracticeHistoryStore.weakestLetter(stats), isNull);
    });
  });

  group('exporting', () {
    test('CSV has a header and one row per attempted letter', () {
      final csv = PracticeHistoryStore.toCsv([
        recordOf([('A', true), ('B', false)], at: DateTime.utc(2026, 4, 1)),
      ]);
      final lines = csv.trim().split('\n');

      expect(lines.first, 'finished_at,letter,succeeded,best_confidence');
      expect(lines, hasLength(3));
      expect(lines[1], contains('2026-04-01'));
      expect(lines[1], contains(',A,true,'));
      expect(lines[2], contains(',B,false,'));
    });

    test('an empty history still produces a usable file', () {
      final csv = PracticeHistoryStore.toCsv([]);

      expect(csv.trim(), 'finished_at,letter,succeeded,best_confidence');
    });
  });
}
