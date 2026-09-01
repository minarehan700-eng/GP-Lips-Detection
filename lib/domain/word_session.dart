import 'face_lips_result.dart';
import 'word_challenge.dart';

/// How a word attempt is going.
enum WordPhase {
  /// Waiting for the next shape in the sequence.
  waiting,

  /// The next shape is being held.
  holding,

  /// Every shape in the word has been made, in order.
  complete,

  /// The time ran out.
  expired,
}

/// Walks a user through mouthing one word, shape by shape.
///
/// Why this is separate from [PracticeSession]:
/// a single letter is one target held once. A word is an ordered run of
/// shapes, and the interesting rules are different — what happens when a shape
/// is skipped, what happens when the user goes back, and how long the whole
/// word may take rather than each part of it.
///
/// As everywhere else in this app's logic, the time is passed in rather than
/// read, so the rules can be tested without waiting for a clock.
class WordSession {
  WordSession({
    required this.challenge,
    this.holdDuration = defaultHoldDuration,
    this.timeLimit = defaultTimeLimit,
    this.minimumConfidence = defaultMinimumConfidence,
  });

  /// Shorter than the single-letter hold: a word is a run of shapes, and
  /// holding each one for the full letter duration turns a four-shape word
  /// into an unnatural three-second performance.
  static const Duration defaultHoldDuration = Duration(milliseconds: 350);

  static const Duration defaultTimeLimit = Duration(seconds: 20);

  static const double defaultMinimumConfidence = 0.28;

  final WordChallenge challenge;
  final Duration holdDuration;
  final Duration timeLimit;
  final double minimumConfidence;

  int _index = 0;
  DateTime? _startedAt;
  DateTime? _holdStartedAt;
  WordPhase _phase = WordPhase.waiting;

  /// How many shapes of the word are done.
  int get completedShapes => _index;

  /// The shape the user should be making, or null once the word is finished.
  String? get currentShape =>
      _index < challenge.shapes.length ? challenge.shapes[_index] : null;

  bool get isComplete => _index >= challenge.shapes.length;

  WordPhase get phase => _phase;

  /// Progress through the word, 0.0 to 1.0, for a bar under the word.
  double get progress =>
      challenge.shapes.isEmpty ? 1 : _index / challenge.shapes.length;

  void start(DateTime now) {
    _index = 0;
    _startedAt = now;
    _holdStartedAt = null;
    _phase = WordPhase.waiting;
  }

  /// Feeds one detection in and advances through the word.
  ///
  /// Steps:
  ///   1. Stop once the word is done or the time is up.
  ///   2. Hold the current shape until it has been held long enough.
  ///   3. Step to the next shape, and finish when the last one is made.
  WordPhase update(FaceLipsResult result, DateTime now) {
    if (isComplete) {
      return _phase = WordPhase.complete;
    }
    _startedAt ??= now;

    if (now.difference(_startedAt!) >= timeLimit) {
      return _phase = WordPhase.expired;
    }

    final bool onShape = result.detectedLetter == currentShape &&
        result.letterConfidence >= minimumConfidence;

    if (!onShape) {
      // The run has to be unbroken, for the same reason a single letter's hold
      // does: passing through a shape is not making it.
      _holdStartedAt = null;
      return _phase = WordPhase.waiting;
    }

    _holdStartedAt ??= now;
    if (now.difference(_holdStartedAt!) < holdDuration) {
      return _phase = WordPhase.holding;
    }

    _index++;
    _holdStartedAt = null;
    return _phase = isComplete ? WordPhase.complete : WordPhase.waiting;
  }

  /// How much of the overall time is left, 1.0 down to 0.0.
  double timeRemaining(DateTime now) {
    final startedAt = _startedAt;
    if (startedAt == null || timeLimit.inMilliseconds == 0) {
      return 1;
    }
    final spent = now.difference(startedAt).inMilliseconds;
    return (1 - spent / timeLimit.inMilliseconds).clamp(0.0, 1.0);
  }

  /// How far through the current shape's hold, 0.0 to 1.0.
  double holdProgress(DateTime now) {
    final startedAt = _holdStartedAt;
    if (startedAt == null || holdDuration.inMilliseconds == 0) {
      return 0;
    }
    return (now.difference(startedAt).inMilliseconds /
            holdDuration.inMilliseconds)
        .clamp(0.0, 1.0);
  }
}
