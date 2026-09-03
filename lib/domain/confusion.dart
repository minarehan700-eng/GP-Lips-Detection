/// How often one shape was made when another was asked for.
class ConfusionPair {
  const ConfusionPair({
    required this.target,
    required this.mistakenFor,
    required this.count,
  });

  /// The shape the user was asked to make.
  final String target;

  /// The shape that kept being detected instead.
  final String mistakenFor;

  final int count;
}

/// Counts which shapes get mistaken for which, across practice history.
///
/// Why this is more useful than an accuracy percentage:
/// "you get C wrong" tells the user nothing they can act on. "you make D when
/// you mean C" tells them exactly what to change — their lips are not rounding
/// far enough, they are stopping at neutral. A per-letter score cannot say
/// that, because it throws away what happened instead.
///
/// It is also a diagnosis of the *detector*, not only the user. If everybody
/// confuses the same pair, the thresholds separating those two shapes are
/// wrong, and that is worth knowing.
class ConfusionMatrix {
  ConfusionMatrix();

  final Map<String, Map<String, int>> _counts = {};

  /// Records that [detected] was seen while [target] was being asked for.
  ///
  /// A correct attempt is not recorded: the matrix is only about mistakes, and
  /// counting the diagonal would bury the interesting cells under it.
  void record({required String target, String? detected}) {
    if (detected == null || detected == target) {
      return;
    }
    final row = _counts.putIfAbsent(target, () => <String, int>{});
    row[detected] = (row[detected] ?? 0) + 1;
  }

  int countFor({required String target, required String detected}) =>
      _counts[target]?[detected] ?? 0;

  bool get isEmpty => _counts.isEmpty;

  /// Every recorded confusion, worst first.
  List<ConfusionPair> get pairs {
    final all = <ConfusionPair>[];
    _counts.forEach((target, row) {
      row.forEach((detected, count) {
        all.add(ConfusionPair(
          target: target,
          mistakenFor: detected,
          count: count,
        ));
      });
    });
    all.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      // Ties are broken by name so the list does not reshuffle between builds
      // for no visible reason.
      if (byCount != 0) {
        return byCount;
      }
      final byTarget = a.target.compareTo(b.target);
      return byTarget != 0 ? byTarget : a.mistakenFor.compareTo(b.mistakenFor);
    });
    return all;
  }

  /// The single confusion worth telling the user about, or null when there is
  /// no clear one.
  ///
  /// [minimumCount] keeps a one-off slip from being presented as a pattern.
  ConfusionPair? worst({int minimumCount = 3}) {
    for (final pair in pairs) {
      if (pair.count >= minimumCount) {
        return pair;
      }
    }
    return null;
  }

  /// Builds a matrix from stored attempts.
  static ConfusionMatrix fromRecords(
    Iterable<({String target, String? detected})> attempts,
  ) {
    final matrix = ConfusionMatrix();
    for (final attempt in attempts) {
      matrix.record(target: attempt.target, detected: attempt.detected);
    }
    return matrix;
  }
}
