import 'dart:math' as math;

import '../domain/face_lips_result.dart';

/// Turns a mouth shape into one practice letter: A, B, C, D or E.
///
/// Why this class is needed:
/// MediaPipe gives us numbers (how open, how puckered, how wide the mouth is),
/// not letters. This class applies a small set of written rules that map those
/// numbers onto the five mouth shapes the app teaches:
///
///   A — mouth wide open        ("aah")
///   B — lips closed            ("mm")
///   C — lips rounded/puckered  ("oo")
///   D — mouth slightly open    (a small, neutral opening)
///   E — smiling / stretched    ("ee")
///
/// The rules are checked in a fixed order (E, then C, then B, then A, then D).
/// Order matters because real mouth shapes overlap: a smile is also slightly
/// open, so the smile rule must be asked first or every smile would be read as
/// D. The first rule that matches wins, which is why this is called a
/// *priority tree*.
///
/// Two tricks keep the displayed letter steady:
///   * the median of the last few frames is used instead of a single frame,
///     so one bad reading cannot change the letter;
///   * a letter must win [hysteresisFrames] frames in a row before it is shown.
class LipLetterDetector {
  LipLetterDetector({
    this.minScore = defaultMinScore,
    this.hysteresisFrames = defaultHysteresisFrames,
    this.windowSize = defaultWindowSize,
  });

  /// The letters this app can recognise, in the order shown on screen.
  static const supportedLetters = ['A', 'B', 'C', 'D', 'E'];

  /// A letter must score at least this much before it is shown to the user.
  static const double defaultMinScore = 0.28;

  /// How many frames in a row a letter must win before it is displayed.
  static const int defaultHysteresisFrames = 2;

  /// How many recent frames the median is taken over.
  static const int defaultWindowSize = 5;

  // ---------------------------------------------------------------------
  // How the "open" feature is built.
  // ---------------------------------------------------------------------

  /// Weight given to MediaPipe's own jaw-open value.
  static const double blendshapeOpenWeight = 0.85;

  /// Weight given to the mouth box shape (height ÷ width).
  /// It is only a small correction: the box is a rough rectangle, so it is
  /// less reliable than the model's own value, but it helps when the jaw
  /// value lags behind a fast movement.
  static const double geometryOpenWeight = 0.15;

  /// Smallest mouth width used as a divisor, so we never divide by zero.
  static const double minimumMouthWidth = 0.01;

  // ---------------------------------------------------------------------
  // Thresholds used by the letter rules. All values are 0.0 – 1.0.
  // ---------------------------------------------------------------------

  /// Smile/stretch value at which the mouth counts as clearly smiling (E).
  static const double strongSmileThreshold = 0.28;

  /// A smile still wins over a round shape if it is behind by no more than
  /// this much. Without this small allowance, a smile that also puckers a
  /// little would be read as C.
  static const double smileOverRoundAllowance = 0.05;

  /// Pucker/funnel value at which the mouth counts as clearly rounded (C).
  static const double strongRoundThreshold = 0.22;

  /// Above this openness the mouth is no longer considered closed (B).
  static const double closedMouthMaxOpen = 0.14;

  /// A mouth this "pressed together" counts as closed even if not fully shut.
  static const double closedMouthMinClose = 0.20;

  /// A mouth this near to shut counts as closed on its own.
  static const double definitelyClosedOpen = 0.10;

  /// Openness at which the mouth counts as wide open (A).
  static const double wideOpenThreshold = 0.45;

  /// The openness band that counts as "slightly open" (D).
  static const double slightOpenMin = 0.16;
  static const double slightOpenMax = 0.44;

  /// The most typical "slightly open" value; D scores highest here.
  static const double slightOpenIdeal = 0.30;

  /// How far openness may drift from [slightOpenIdeal] before the D score
  /// drops to zero.
  static const double slightOpenTolerance = 0.14;

  /// How the D score is split between "how close to the ideal shape" and
  /// "how open the mouth is". The two weights add up to 1.0.
  static const double slightOpenShapeWeight = 0.85;
  static const double slightOpenSizeWeight = 0.15;

  final double minScore;
  final int hysteresisFrames;
  final int windowSize;

  /// The mouth features of the last [windowSize] frames, oldest first.
  final List<_MouthFeatures> _recentFeatures = [];

  /// The letter currently shown on screen.
  String? _displayedLetter;

  /// The letter that is trying to take over, and how many frames it has won.
  String? _candidateLetter;
  int _candidateFrameStreak = 0;

  /// Feeds one new frame in and returns it with a letter and confidence added.
  ///
  /// Input:  [raw] — one frame of mouth data from MediaPipe (already carrying
  ///         the lipsing flag, because the lipsing detector runs first).
  /// Output: a copy of [raw] with `detectedLetter` and `letterConfidence` set.
  ///         `detectedLetter` is null when no rule matched.
  /// Side effect: updates the feature window and the candidate streak.
  ///
  /// Steps:
  ///   1. No face → forget everything and show no letter.
  ///   2. Turn the raw numbers into tidy features and remember them.
  ///   3. Take the median of the window so one odd frame cannot decide.
  ///   4. Run the priority tree to pick a letter.
  ///   5. Only show the letter once it has won several frames in a row.
  FaceLipsResult update(FaceLipsResult raw) {
    if (!raw.faceDetected) {
      reset();
      return raw.copyWith(clearDetectedLetter: true, letterConfidence: 0);
    }

    _remember(_extractFeatures(raw));
    final _MouthFeatures steadyFeatures = _medianFeatures();
    final _LetterMatch? match = _classify(steadyFeatures);

    if (match == null) {
      _candidateLetter = null;
      _candidateFrameStreak = 0;
      _displayedLetter = null;
      return raw.copyWith(clearDetectedLetter: true, letterConfidence: 0);
    }

    _countVoteFor(match.letter);

    // Before a candidate has won enough frames, show the current best guess
    // so the very first frame is not blank.
    final String letterToShow = _displayedLetter ?? match.letter;

    return raw.copyWith(
      detectedLetter: letterToShow,
      letterConfidence: match.score,
    );
  }

  /// Clears the window and the displayed letter.
  void reset() {
    _recentFeatures.clear();
    _displayedLetter = null;
    _candidateLetter = null;
    _candidateFrameStreak = 0;
  }

  /// Counts one frame's vote and promotes the candidate to the displayed
  /// letter once it has won [hysteresisFrames] frames in a row.
  void _countVoteFor(String letter) {
    if (letter == _candidateLetter) {
      _candidateFrameStreak++;
    } else {
      _candidateLetter = letter;
      _candidateFrameStreak = 1;
    }

    if (_candidateFrameStreak >= hysteresisFrames) {
      _displayedLetter = letter;
    }
  }

  /// Converts one raw frame into the six tidy features the rules use.
  ///
  /// Every value is forced into the 0.0 – 1.0 range so a rule can never be
  /// tripped by an out-of-range number.
  ///
  /// The "open" feature is special: it mixes MediaPipe's jaw-open value with
  /// the shape of the mouth box (tall box = open mouth, flat box = closed).
  _MouthFeatures _extractFeatures(FaceLipsResult raw) {
    // Step 1: measure the mouth box. Width is floored so the division below
    // is always safe, even when no box was reported.
    final double mouthWidth =
        math.max(raw.mouthMaxX - raw.mouthMinX, minimumMouthWidth);
    final double mouthHeight = math.max(raw.mouthMaxY - raw.mouthMinY, 0.0);

    // Step 2: a tall-and-narrow box means an open mouth.
    final double geometricOpen = _clamp01(mouthHeight / mouthWidth);

    // Step 3: blend the model's value with the geometric hint.
    final double blendedOpen = _clamp01(
      blendshapeOpenWeight * _clamp01(raw.mouthOpen) +
          geometryOpenWeight * geometricOpen,
    );

    return _MouthFeatures(
      open: blendedOpen,
      close: _clamp01(raw.mouthClose),
      pucker: _clamp01(raw.mouthPucker),
      funnel: _clamp01(raw.mouthFunnel),
      stretch: _clamp01(raw.mouthStretch),
      smile: _clamp01(raw.smile),
    );
  }

  /// Stores one frame's features, dropping the oldest when the window is full.
  void _remember(_MouthFeatures features) {
    _recentFeatures.add(features);
    while (_recentFeatures.length > windowSize) {
      _recentFeatures.removeAt(0);
    }
  }

  /// Returns the middle value of each feature across the stored frames.
  ///
  /// The median is used instead of the average because it ignores a single
  /// extreme reading: if four frames say "closed" and one says "wide open",
  /// the median still says "closed", while an average would be dragged up.
  _MouthFeatures _medianFeatures() {
    if (_recentFeatures.isEmpty) {
      return const _MouthFeatures(
        open: 0,
        close: 0,
        pucker: 0,
        funnel: 0,
        stretch: 0,
        smile: 0,
      );
    }

    final List<double> openValues = [];
    final List<double> closeValues = [];
    final List<double> puckerValues = [];
    final List<double> funnelValues = [];
    final List<double> stretchValues = [];
    final List<double> smileValues = [];

    for (final features in _recentFeatures) {
      openValues.add(features.open);
      closeValues.add(features.close);
      puckerValues.add(features.pucker);
      funnelValues.add(features.funnel);
      stretchValues.add(features.stretch);
      smileValues.add(features.smile);
    }

    return _MouthFeatures(
      open: _median(openValues),
      close: _median(closeValues),
      pucker: _median(puckerValues),
      funnel: _median(funnelValues),
      stretch: _median(stretchValues),
      smile: _median(smileValues),
    );
  }

  /// Returns the middle value of [values].
  ///
  /// With an odd count the middle item is returned; with an even count the two
  /// middle items are averaged. The list is sorted in place first, which is
  /// safe because each list is built fresh in [_medianFeatures].
  static double _median(List<double> values) {
    values.sort();
    final int middle = values.length ~/ 2;

    if (values.length.isOdd) {
      return values[middle];
    }
    return (values[middle - 1] + values[middle]) / 2;
  }

  /// Picks the letter that best describes this mouth shape.
  ///
  /// Input:  [f] — the median features of the recent frames.
  /// Output: the winning letter with its confidence score, or null when no
  ///         rule matched (the app then shows a dash).
  ///
  /// The rules are asked in the order E → C → B → A → D. A rule can match on
  /// shape but still be rejected because its score is below [minScore]; when
  /// that happens the next rule gets its turn.
  _LetterMatch? _classify(_MouthFeatures f) {
    // "Roundness" and "wideness" each have two possible sources, so take
    // whichever is stronger.
    final double roundness = math.max(f.pucker, f.funnel);
    final double wideness = math.max(f.smile, f.stretch);

    // --- E: smiling or stretched wide -----------------------------------
    // The second test stops a mouth that is mostly puckered from being read
    // as a smile just because the smile value is also a little high.
    final bool smilingClearly = wideness >= strongSmileThreshold;
    final bool smileBeatsRound = wideness >= roundness - smileOverRoundAllowance;
    if (smilingClearly && smileBeatsRound) {
      final double score = _clamp01(wideness);
      if (score >= minScore) {
        return _LetterMatch('E', score);
      }
    }

    // --- C: rounded or puckered lips ------------------------------------
    if (roundness >= strongRoundThreshold) {
      final double score = _clamp01(roundness);
      if (score >= minScore) {
        return _LetterMatch('C', score);
      }
    }

    // --- B: lips closed -------------------------------------------------
    // A mouth counts as closed either because the model reports the lips
    // pressed together, or because it is simply barely open at all.
    final bool barelyOpen = f.open <= closedMouthMaxOpen;
    final bool lipsPressed = f.close >= closedMouthMinClose;
    final bool practicallyShut = f.open <= definitelyClosedOpen;
    if (barelyOpen && (lipsPressed || practicallyShut)) {
      // Confidence rises both when the lips press harder and when the mouth
      // is more fully shut, so take the stronger of the two readings.
      final double score = _clamp01(math.max(f.close, 1.0 - f.open));
      if (score >= minScore) {
        return _LetterMatch('B', score);
      }
    }

    // --- A: wide open, and not a smile or a pucker ----------------------
    final bool wideOpen = f.open >= wideOpenThreshold;
    final bool notSmiling = wideness < strongSmileThreshold;
    final bool notRounded = roundness < strongRoundThreshold;
    if (wideOpen && notSmiling && notRounded) {
      final double score = _clamp01(f.open);
      if (score >= minScore) {
        return _LetterMatch('A', score);
      }
    }

    // --- D: slightly open, when nothing else fits -----------------------
    final bool slightlyOpen = f.open >= slightOpenMin && f.open <= slightOpenMax;
    if (slightlyOpen) {
      // How close is the opening to the ideal "slightly open" size?
      // 1.0 at exactly [slightOpenIdeal], falling to 0.0 once it drifts a
      // full [slightOpenTolerance] away in either direction.
      final double distanceFromIdeal = (f.open - slightOpenIdeal).abs();
      final double shapeMatch =
          1.0 - _clamp01(distanceFromIdeal / slightOpenTolerance);

      final double score = _clamp01(
        shapeMatch * slightOpenShapeWeight + f.open * slightOpenSizeWeight,
      );
      if (score >= minScore) {
        return _LetterMatch('D', score);
      }
    }

    // Nothing matched — the app shows a dash instead of a letter.
    return null;
  }

  /// Keeps a value inside the 0.0 – 1.0 range.
  static double _clamp01(double value) => value.clamp(0.0, 1.0);
}

/// One rule's answer: which letter won, and how confident the rule is.
class _LetterMatch {
  const _LetterMatch(this.letter, this.score);

  final String letter;

  /// Confidence from 0.0 to 1.0; shown on screen as a percentage.
  final double score;
}

/// The six mouth measurements the letter rules work with.
///
/// All values run from 0.0 (not at all) to 1.0 (fully). They come from
/// MediaPipe blendshapes, except [open], which also mixes in the mouth box
/// shape — see [LipLetterDetector._extractFeatures].
class _MouthFeatures {
  const _MouthFeatures({
    required this.open,
    required this.close,
    required this.pucker,
    required this.funnel,
    required this.stretch,
    required this.smile,
  });

  /// How far the mouth is open.
  final double open;

  /// How firmly the lips are pressed together.
  final double close;

  /// How much the lips are pushed forward into a small circle ("oo").
  final double pucker;

  /// How much the lips form a wider funnel/oval shape.
  final double funnel;

  /// How much the mouth is pulled sideways.
  final double stretch;

  /// How much the mouth is smiling.
  final double smile;
}
