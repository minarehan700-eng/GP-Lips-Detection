import '../domain/face_lips_result.dart';

/// Decides whether the user is currently "lipsing" (mouthing words silently).
///
/// Why this class is needed:
/// MediaPipe tells us the mouth shape of ONE frame. One frame is not enough to
/// know if the user is *moving* the mouth, and raw per-frame answers flicker
/// between Yes and No many times per second. This class looks at the last few
/// frames and only changes its answer when several frames agree, so the label
/// on screen stays readable.
///
/// Two independent signs make a frame count as "active":
///   1. The mouth is open wider than [mouthOpenThreshold] (a held-open mouth).
///   2. The mouth shape is *changing* fast enough (movement between frames).
///
/// Either one is enough, because a user can lip a word with a barely-open
/// mouth (sign 2) or hold a wide "aah" shape almost still (sign 1).
class LipsingDetector {
  LipsingDetector({
    this.historySize = defaultHistorySize,
    this.mouthOpenThreshold = defaultMouthOpenThreshold,
    this.motionThreshold = defaultMotionThreshold,
    this.hysteresisFrames = defaultHysteresisFrames,
  });

  /// How many recent frames are kept to measure movement.
  static const int defaultHistorySize = 8;

  /// Mouth-open value (0.0 – 1.0) above which the mouth counts as open.
  static const double defaultMouthOpenThreshold = 0.25;

  /// Average frame-to-frame change above which the mouth counts as moving.
  static const double defaultMotionThreshold = 0.035;

  /// How many frames in a row must agree before the Yes/No answer flips.
  static const int defaultHysteresisFrames = 3;

  /// A mouth this much wider than [mouthOpenThreshold] switches to "Yes"
  /// immediately, without waiting for [hysteresisFrames] frames. This keeps
  /// the app responsive when the user clearly opens their mouth.
  static const double instantOnMultiplier = 1.4;

  /// Weight of the pucker change inside the movement score.
  /// Pucker moves less than the jaw, so it counts for half.
  static const double puckerMotionWeight = 0.5;

  /// Weight of the smile change inside the movement score.
  /// Smiling is the smallest of the three movements, so it counts least.
  static const double smileMotionWeight = 0.35;

  final int historySize;
  final double mouthOpenThreshold;
  final double motionThreshold;
  final int hysteresisFrames;

  /// The most recent mouth measurements, oldest first.
  final List<_MouthSample> _recentSamples = <_MouthSample>[];

  /// The stable answer currently shown on screen.
  bool _isLipsing = false;

  /// How many frames in a row have voted "active" / "not active".
  int _activeFrameStreak = 0;
  int _inactiveFrameStreak = 0;

  bool get isLipsing => _isLipsing;

  /// Feeds one new frame in and returns the same frame with a stable
  /// `isLipsing` flag attached.
  ///
  /// Input:  [raw] — one frame of mouth data straight from MediaPipe.
  /// Output: a copy of [raw] whose `isLipsing` is the smoothed answer.
  /// Side effect: updates the frame history and the streak counters.
  ///
  /// Steps:
  ///   1. If no face is visible, forget the history and fade the answer to No.
  ///   2. Otherwise remember this frame's mouth shape.
  ///   3. Decide if this single frame looks active (open enough OR moving enough).
  ///   4. Only flip the shown answer once enough frames in a row agree.
  FaceLipsResult update(FaceLipsResult raw) {
    if (!raw.faceDetected) {
      return raw.copyWith(isLipsing: _handleMissingFace());
    }

    _remember(raw);

    final bool mouthIsOpenEnough = raw.mouthOpen > mouthOpenThreshold;
    final bool mouthIsMovingEnough = _averageMouthMovement() > motionThreshold;
    final bool frameLooksActive = mouthIsOpenEnough || mouthIsMovingEnough;

    if (frameLooksActive) {
      _countActiveFrame(raw.mouthOpen);
    } else {
      _countInactiveFrame();
    }

    return raw.copyWith(isLipsing: _isLipsing);
  }

  /// Clears everything back to the "no lipsing yet" state.
  void reset() {
    _recentSamples.clear();
    _isLipsing = false;
    _activeFrameStreak = 0;
    _inactiveFrameStreak = 0;
  }

  /// Handles a frame where MediaPipe found no face.
  ///
  /// The history is dropped (the next face may be a different person or pose),
  /// and the answer fades to No after [hysteresisFrames] missing frames rather
  /// than instantly, so a single dropped frame does not blank the label.
  ///
  /// Returns the answer to show for this frame.
  bool _handleMissingFace() {
    _recentSamples.clear();
    _activeFrameStreak = 0;
    _inactiveFrameStreak++;

    if (_inactiveFrameStreak >= hysteresisFrames) {
      _isLipsing = false;
      _inactiveFrameStreak = 0;
    }
    return _isLipsing;
  }

  /// Stores this frame's mouth shape, dropping the oldest sample when the
  /// history is full.
  void _remember(FaceLipsResult raw) {
    _recentSamples.add(
      _MouthSample(
        mouthOpen: raw.mouthOpen,
        mouthPucker: raw.mouthPucker,
        smile: raw.smile,
      ),
    );
    while (_recentSamples.length > historySize) {
      _recentSamples.removeAt(0);
    }
  }

  /// Records an "active" vote and switches the answer to Yes when the vote is
  /// convincing enough.
  void _countActiveFrame(double mouthOpen) {
    _activeFrameStreak++;
    _inactiveFrameStreak = 0;

    final bool enoughFramesAgree = _activeFrameStreak >= hysteresisFrames;
    final bool mouthIsClearlyWideOpen =
        mouthOpen > mouthOpenThreshold * instantOnMultiplier;

    if (enoughFramesAgree || mouthIsClearlyWideOpen) {
      _isLipsing = true;
    }
  }

  /// Records a "not active" vote and switches the answer to No once enough
  /// quiet frames have passed.
  void _countInactiveFrame() {
    _inactiveFrameStreak++;
    _activeFrameStreak = 0;

    if (_inactiveFrameStreak >= hysteresisFrames) {
      _isLipsing = false;
    }
  }

  /// Measures how much the mouth changed, on average, from one stored frame to
  /// the next.
  ///
  /// Output: a number around 0.0 (mouth held still) to ~1.0 (mouth changing a
  /// lot). Returns 0 when there is not yet a pair of frames to compare.
  ///
  /// The three mouth values are added together with different weights because
  /// they do not move by the same amount: the jaw swings widest, so it counts
  /// fully, while pucker and smile changes are smaller and are scaled down.
  double _averageMouthMovement() {
    if (_recentSamples.length < 2) {
      return 0;
    }

    var totalChange = 0.0;
    var comparisons = 0;

    for (var i = 1; i < _recentSamples.length; i++) {
      final previous = _recentSamples[i - 1];
      final current = _recentSamples[i];

      final openChange = (current.mouthOpen - previous.mouthOpen).abs();
      final puckerChange = (current.mouthPucker - previous.mouthPucker).abs();
      final smileChange = (current.smile - previous.smile).abs();

      totalChange += openChange;
      totalChange += puckerChange * puckerMotionWeight;
      totalChange += smileChange * smileMotionWeight;
      comparisons++;
    }

    if (comparisons == 0) {
      return 0;
    }
    return totalChange / comparisons;
  }
}

/// One frame's mouth measurements, kept only long enough to measure movement.
class _MouthSample {
  const _MouthSample({
    required this.mouthOpen,
    required this.mouthPucker,
    required this.smile,
  });

  final double mouthOpen;
  final double mouthPucker;
  final double smile;
}
