import 'package:shared_preferences/shared_preferences.dart';

import '../domain/session_record.dart';

/// Keeps finished practice rounds on the phone and answers questions about
/// them.
///
/// Why this matters to the app rather than being a nicety:
/// without it every round starts from nothing, and the user has no way of
/// knowing which mouth shape they are actually bad at. The per-letter
/// breakdown is the one number that tells them what to practise next.
///
/// Everything is local. The app has no network code at all, and practice data
/// is exactly the sort of thing that should not acquire any.
class PracticeHistoryStore {
  PracticeHistoryStore({this.maxRecords = defaultMaxRecords});

  static const String storageKey = 'practice_history';

  /// How many rounds are kept. Old ones fall off the end.
  ///
  /// Bounded on purpose: this lives in `shared_preferences`, which loads
  /// wholly into memory at start-up, so an unbounded list would slow the app's
  /// launch down a little more every time it was used.
  static const int defaultMaxRecords = 200;

  final int maxRecords;

  /// Every stored round, newest first.
  ///
  /// Entries that cannot be read are skipped rather than throwing, so one bad
  /// row — written by an older version, or a write cut short — cannot cost the
  /// user their whole history.
  Future<List<SessionRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(storageKey) ?? const [];
    final records = <SessionRecord>[];
    for (final entry in raw) {
      final record = SessionRecord.decode(entry);
      if (record != null) {
        records.add(record);
      }
    }
    records.sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    return records;
  }

  /// Adds one finished round and returns the history including it.
  Future<List<SessionRecord>> add(SessionRecord record) async {
    final existing = await load();
    final updated = [record, ...existing];
    if (updated.length > maxRecords) {
      updated.removeRange(maxRecords, updated.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      storageKey,
      [for (final r in updated) r.encode()],
    );
    return updated;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  /// Per-letter totals across [records], in the order of [letters] so the
  /// display does not reshuffle as the numbers change.
  static List<LetterStat> statsByLetter(
    List<SessionRecord> records,
    List<String> letters,
  ) {
    final attempts = <String, int>{};
    final hits = <String, int>{};
    for (final record in records) {
      for (final result in record.results) {
        attempts[result.letter] = (attempts[result.letter] ?? 0) + 1;
        if (result.succeeded) {
          hits[result.letter] = (hits[result.letter] ?? 0) + 1;
        }
      }
    }
    return [
      for (final letter in letters)
        LetterStat(
          letter: letter,
          attempts: attempts[letter] ?? 0,
          hits: hits[letter] ?? 0,
        ),
    ];
  }

  /// The letter with the worst record, ignoring any tried fewer than
  /// [minimumAttempts] times.
  ///
  /// The threshold is the point: one unlucky attempt should not label a letter
  /// as someone's weakness.
  static LetterStat? weakestLetter(
    List<LetterStat> stats, {
    int minimumAttempts = 3,
  }) {
    final eligible =
        stats.where((s) => s.attempts >= minimumAttempts).toList();
    if (eligible.isEmpty) {
      return null;
    }
    eligible.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return eligible.first;
  }

  /// The history as CSV, one row per attempted letter.
  ///
  /// This is the only way data leaves the app, and it leaves as a file the
  /// user asked for. Useful for a report: the rows drop straight into a
  /// spreadsheet.
  static String toCsv(List<SessionRecord> records) {
    final buffer = StringBuffer('finished_at,letter,succeeded,best_confidence\n');
    for (final record in records) {
      final at = record.finishedAt.toIso8601String();
      for (final result in record.results) {
        buffer.writeln(
          '$at,${result.letter},${result.succeeded},'
          '${result.bestConfidence.toStringAsFixed(3)}',
        );
      }
    }
    return buffer.toString();
  }
}
