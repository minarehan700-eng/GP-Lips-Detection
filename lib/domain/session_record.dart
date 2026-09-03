import 'dart:convert';

import 'practice_session.dart';

/// One finished practice round, kept so progress can be shown over time.
///
/// Stored as JSON rather than in a database: a round is a handful of numbers,
/// there are never many of them, and `shared_preferences` is already a
/// dependency. Adding a database for this would be more moving parts than the
/// data deserves.
class SessionRecord {
  const SessionRecord({
    required this.finishedAt,
    required this.results,
    required this.totalMilliseconds,
  });

  /// When the round ended.
  final DateTime finishedAt;

  /// Whether each attempted letter was held successfully, in order.
  final List<({String letter, bool succeeded, double bestConfidence, String? confusedWith})>
      results;

  final int totalMilliseconds;

  int get hits => results.where((r) => r.succeeded).length;

  int get total => results.length;

  /// Share of letters held successfully, 0.0 to 1.0.
  double get accuracy => total == 0 ? 0 : hits / total;

  /// The longest run of successes, which is the number people actually chase.
  int get bestStreak {
    var best = 0;
    var run = 0;
    for (final r in results) {
      run = r.succeeded ? run + 1 : 0;
      if (run > best) {
        best = run;
      }
    }
    return best;
  }

  static SessionRecord fromAttempts(
    List<PracticeAttempt> attempts,
    DateTime finishedAt,
  ) {
    return SessionRecord(
      finishedAt: finishedAt,
      results: [
        for (final a in attempts)
          (
            letter: a.letter,
            succeeded: a.succeeded,
            bestConfidence: a.bestConfidence,
            confusedWith: a.confusedWith,
          ),
      ],
      totalMilliseconds:
          attempts.fold(0, (sum, a) => sum + a.millisecondsTaken),
    );
  }

  Map<String, dynamic> toJson() => {
        'at': finishedAt.millisecondsSinceEpoch,
        'ms': totalMilliseconds,
        'results': [
          for (final r in results)
            {
              'l': r.letter,
              'ok': r.succeeded,
              'c': r.bestConfidence,
              // Omitted when there was no clear confusion, so old records stay
              // readable and new ones stay small.
              if (r.confusedWith != null) 'x': r.confusedWith,
            },
        ],
      };

  /// Reads one record back, or null when the stored shape is not usable.
  ///
  /// Returning null rather than throwing matters: one corrupt entry — from an
  /// older version, or a half-finished write — must not stop the whole history
  /// from loading.
  static SessionRecord? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final at = raw['at'];
    final list = raw['results'];
    if (at is! int || list is! List) {
      return null;
    }
    final results =
        <({String letter, bool succeeded, double bestConfidence, String? confusedWith})>[];
    for (final entry in list) {
      if (entry is! Map) {
        return null;
      }
      final letter = entry['l'];
      final ok = entry['ok'];
      if (letter is! String || ok is! bool) {
        return null;
      }
      final confidence = entry['c'];
      final confused = entry['x'];
      results.add((
        letter: letter,
        succeeded: ok,
        bestConfidence: confidence is num ? confidence.toDouble() : 0.0,
        // Records written before confusion was tracked simply have no 'x'.
        confusedWith: confused is String ? confused : null,
      ));
    }
    final ms = raw['ms'];
    return SessionRecord(
      finishedAt: DateTime.fromMillisecondsSinceEpoch(at),
      results: results,
      totalMilliseconds: ms is int ? ms : 0,
    );
  }

  String encode() => jsonEncode(toJson());

  static SessionRecord? decode(String raw) {
    try {
      return fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }
}

/// How one letter has gone across every stored round.
class LetterStat {
  const LetterStat({
    required this.letter,
    required this.attempts,
    required this.hits,
  });

  final String letter;
  final int attempts;
  final int hits;

  double get accuracy => attempts == 0 ? 0 : hits / attempts;
}

/// Reads a confusion matrix out of stored rounds.
extension ConfusionFromHistory on List<SessionRecord> {
  /// Every recorded mistake, in the shape [ConfusionMatrix.fromRecords] wants.
  Iterable<({String target, String? detected})> get confusionAttempts sync* {
    for (final record in this) {
      for (final result in record.results) {
        if (!result.succeeded) {
          yield (target: result.letter, detected: result.confusedWith);
        }
      }
    }
  }
}
