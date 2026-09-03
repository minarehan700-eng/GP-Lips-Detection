import 'face_lips_result.dart';

/// What the practice screen should be showing right now.
enum PracticePhase {
  /// Waiting for the user to make the target shape.
  waiting,

  /// The target shape is being made and the hold timer is running.
  holding,

  /// The shape was held long enough. The target counts as learned.
  confirmed,

  /// The time ran out before the shape was held. Moving on.
  missed,

  /// Every target has been attempted.
  finished,
}

/// How one target letter turned out.
class PracticeAttempt {
  const PracticeAttempt({
    required this.letter,
    required this.succeeded,
    required this.millisecondsTaken,
    required this.bestConfidence,
    this.confusedWith,
  });

  final String letter;
  final bool succeeded;

  /// Time from the letter being presented to it being confirmed, or the whole
  /// time limit when it was missed.
  final int millisecondsTaken;

  /// The highest confidence reached while trying, which says something useful
  /// even about a miss: 0.05 is "nowhere near", 0.26 is "almost".
  final double bestConfidence;

  /// The shape that kept turning up instead of the target, if any one shape
  /// dominated.
  ///
  /// This is the difference between "you get C wrong" and "you make D when you
  /// mean C" — the second tells the user their lips are stopping at neutral
  /// instead of rounding, which is something they can act on.
  final String? confusedWith;
}

/// Runs one guided practice round: present a letter, wait for the user to hold
/// that mouth shape, score it, move on.
///
/// Why this is a class of its own, with no Flutter in it:
/// the rules — how long a shape must be held, when an attempt has run out of
/// time, what counts as a hit — are the part worth testing, and they can be
/// tested exhaustively only if they do not need a camera or a widget tree.
/// Time is passed in rather than read from the clock for the same reason.
class PracticeSession {
  PracticeSession({
    required this.targets,
    this.holdDuration = defaultHoldDuration,
    this.timeLimitPerTarget = defaultTimeLimit,
    this.minimumConfidence = defaultMinimumConfidence,
  }) : assert(targets.isNotEmpty, 'a session needs at least one target');

  /// How long the shape must be held before it counts.
  ///
  /// A single frame is not evidence of anything: the classifier passes through
  /// neighbouring shapes on the way to the right one, so without a hold the
  /// user is credited for shapes they only flickered through.
  static const Duration defaultHoldDuration = Duration(milliseconds: 700);

  /// How long one letter may be attempted before the session moves on, so a
  /// shape the user cannot make does not strand them.
  static const Duration defaultTimeLimit = Duration(seconds: 12);

  /// Confidence below this does not start or sustain a hold.
  static const double defaultMinimumConfidence = 0.30;

  final List<String> targets;
  final Duration holdDuration;
  final Duration timeLimitPerTarget;
  final double minimumConfidence;

  final List<PracticeAttempt> _attempts = [];

  int _index = 0;
  DateTime? _targetShownAt;
  DateTime? _holdStartedAt;
  double _bestConfidence = 0;
  PracticePhase _phase = PracticePhase.waiting;

  /// How often each wrong shape was seen while the current target was up.
  final Map<String, int> _wrongShapeCounts = {};

  /// Everything scored so far.
  List<PracticeAttempt> get attempts => List.unmodifiable(_attempts);

  /// Which target is being attempted, or null once the session is over.
  String? get currentTarget => isFinished ? null : targets[_index];

  /// How many targets have been attempted, for a "3 of 5" style label.
  int get completedCount => _attempts.length;

  int get totalCount => targets.length;

  bool get isFinished => _index >= targets.length;

  PracticePhase get phase => _phase;

  /// How far through the current hold the user is, from 0.0 to 1.0.
  ///
  /// Drives the progress ring, so it is clamped: a late frame can arrive after
  /// the hold is already complete.
  double holdProgress(DateTime now) {
    final startedAt = _holdStartedAt;
    if (startedAt == null || holdDuration.inMilliseconds == 0) {
      return 0;
    }
    final held = now.difference(startedAt).inMilliseconds;
    return (held / holdDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// How much of the time limit is left, from 1.0 down to 0.0.
  double timeRemaining(DateTime now) {
    final shownAt = _targetShownAt;
    if (shownAt == null || timeLimitPerTarget.inMilliseconds == 0) {
      return 1;
    }
    final spent = now.difference(shownAt).inMilliseconds;
    return (1 - spent / timeLimitPerTarget.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Starts, or restarts, the session.
  void start(DateTime now) {
    _attempts.clear();
    _index = 0;
    _bestConfidence = 0;
    _holdStartedAt = null;
    _targetShownAt = now;
    _wrongShapeCounts.clear();
    _phase = PracticePhase.waiting;
  }

  /// Feeds in one detection and advances the round.
  ///
  /// Input:  [result] — the latest frame's detection.
  ///         [now] — the current time, passed in so tests are not timing
  ///         dependent.
  /// Output: the phase the screen should now show.
  ///
  /// Steps:
  ///   1. Do nothing once the session is over.
  ///   2. Start the clock on the first frame, if [start] was not called.
  ///   3. Extend or break the hold, depending on whether the target shape is
  ///      still being made.
  ///   4. Score a hit once the hold is long enough, or a miss once the time
  ///      limit passes.
  PracticePhase update(FaceLipsResult result, DateTime now) {
    if (isFinished) {
      return _phase = PracticePhase.finished;
    }
    _targetShownAt ??= now;

    final bool onTarget = result.detectedLetter == targets[_index] &&
        result.letterConfidence >= minimumConfidence;

    if (onTarget && result.letterConfidence > _bestConfidence) {
      _bestConfidence = result.letterConfidence;
    }

    // A confidently detected *wrong* shape is the useful signal. A frame with
    // nothing detected, or a barely-there reading, says only that the user was
    // between shapes, which every attempt passes through.
    final wrong = result.detectedLetter;
    if (!onTarget && wrong != null && result.letterConfidence >= minimumConfidence) {
      _wrongShapeCounts[wrong] = (_wrongShapeCounts[wrong] ?? 0) + 1;
    }

    if (onTarget) {
      _holdStartedAt ??= now;
      if (now.difference(_holdStartedAt!) >= holdDuration) {
        return _score(succeeded: true, now: now);
      }
      return _phase = PracticePhase.holding;
    }

    // The shape was lost, so the hold starts again from nothing. Letting it
    // accumulate across gaps would pass someone who flickered onto the shape
    // repeatedly without ever holding it.
    _holdStartedAt = null;

    if (now.difference(_targetShownAt!) >= timeLimitPerTarget) {
      return _score(succeeded: false, now: now);
    }
    return _phase = PracticePhase.waiting;
  }

  /// The wrong shape that turned up most, or null when none stood out.
  ///
  /// A shape only counts as *the* confusion when it accounts for more than
  /// half the wrong frames. Passing through two or three shapes on the way to
  /// the right one is normal and says nothing; returning repeatedly to one of
  /// them says something worth telling the user.
  String? _dominantWrongShape() {
    if (_wrongShapeCounts.isEmpty) {
      return null;
    }
    final total = _wrongShapeCounts.values.reduce((a, b) => a + b);
    String? best;
    var bestCount = 0;
    _wrongShapeCounts.forEach((shape, count) {
      if (count > bestCount) {
        best = shape;
        bestCount = count;
      }
    });
    return bestCount * 2 > total ? best : null;
  }

  /// Records the current target's outcome and moves to the next one.
  PracticePhase _score({required bool succeeded, required DateTime now}) {
    _attempts.add(PracticeAttempt(
      letter: targets[_index],
      succeeded: succeeded,
      millisecondsTaken: now.difference(_targetShownAt!).inMilliseconds,
      bestConfidence: _bestConfidence,
      confusedWith: _dominantWrongShape(),
    ));

    _index++;
    _bestConfidence = 0;
    _holdStartedAt = null;
    _targetShownAt = now;
    _wrongShapeCounts.clear();

    if (isFinished) {
      return _phase = PracticePhase.finished;
    }
    return _phase = succeeded ? PracticePhase.confirmed : PracticePhase.missed;
  }
}
