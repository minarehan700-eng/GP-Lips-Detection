import 'dart:math' as math;

import '../core/detector_settings.dart';
import 'face_lips_result.dart';

/// One step of the calibration walk-through.
enum CalibrationStep {
  /// Face relaxed, mouth closed and still. This is where the noise floor and
  /// the resting baseline come from.
  rest,

  /// Mouth opened as wide as is comfortable.
  wideOpen,

  /// Lips pushed forward into a circle.
  rounded,

  /// Lips pulled wide, a small smile.
  spread,
}

/// Why a calibration was rejected.
///
/// Rejecting with a reason is the point: silently accepting a bad calibration
/// would leave the user with thresholds worse than the defaults and nothing to
/// tell them why detection got worse.
enum CalibrationProblem {
  /// Not enough usable frames — the face was not found for long enough.
  tooFewSamples,

  /// Rest and wide-open look the same, so the mouth was probably never opened.
  noRange,

  /// The face moved so much at rest that no threshold can sit above the noise.
  tooRestless,
}

/// The result of a calibration attempt.
class CalibrationOutcome {
  const CalibrationOutcome._({this.settings, this.problem, this.detail = ''});

  const CalibrationOutcome.accepted(DetectorSettings settings)
      : this._(settings: settings);

  const CalibrationOutcome.rejected(CalibrationProblem problem,
      [String detail = ''])
      : this._(problem: problem, detail: detail);

  /// The personalised thresholds, or null when the attempt was rejected.
  final DetectorSettings? settings;

  final CalibrationProblem? problem;

  /// A number worth showing the user, e.g. how much range was measured.
  final String detail;

  bool get accepted => settings != null;
}

/// Measures one person's face and derives thresholds that suit it.
///
/// Why this is worth having:
/// the shipped thresholds are one set of numbers chosen by testing on a few
/// faces. Mouth size, lip shape, beard, camera distance and lighting all move
/// the raw signals, so the same 0.25 that is a wide-open mouth on one person
/// is a resting face on another. Calibration replaces the guess with a
/// measurement.
///
/// The interesting part is the rest step. Its *spread* — how much the readings
/// wobble while the face is deliberately still — is that person's noise floor,
/// and a motion threshold below it would fire on nothing at all.
class Calibration {
  /// How many usable frames a step needs before it is trusted.
  ///
  /// At roughly seven frames a second, this is about two seconds of holding
  /// still, which is short enough to sit through and long enough to average.
  static const int minimumSamplesPerStep = 12;

  /// The open threshold is placed this far along the gap between a resting
  /// mouth and a wide-open one.
  ///
  /// Below the midpoint: catching a mouth that is on its way open matters more
  /// than avoiding the occasional false positive, because a missed word is
  /// worse than an extra one.
  static const double openThresholdFraction = 0.40;

  /// The smallest usable gap between rest and wide open. Under this, the two
  /// readings are within noise of each other.
  static const double minimumOpenRange = 0.08;

  /// Motion must clear the resting wobble by this multiple.
  static const double motionSafetyFactor = 2.5;

  /// A resting face wobbling by more than this cannot be calibrated — usually
  /// a moving camera or very poor light.
  static const double maximumRestingNoise = 0.12;

  final Map<CalibrationStep, List<double>> _openBy = {
    for (final step in CalibrationStep.values) step: <double>[],
  };

  /// How many usable frames a step has collected.
  int samplesFor(CalibrationStep step) => _openBy[step]!.length;

  /// Whether a step has been held long enough.
  bool isStepComplete(CalibrationStep step) =>
      samplesFor(step) >= minimumSamplesPerStep;

  bool get isComplete =>
      CalibrationStep.values.every(isStepComplete);

  /// How far through a step the user is, 0.0 to 1.0, for a progress ring.
  double stepProgress(CalibrationStep step) =>
      (samplesFor(step) / minimumSamplesPerStep).clamp(0.0, 1.0);

  /// Records one frame against [step].
  ///
  /// Frames with no face are dropped rather than counted as zero: a zero would
  /// drag the average towards a mouth that is not there, and the user would be
  /// calibrated against a moment they looked away.
  void addSample(CalibrationStep step, FaceLipsResult result) {
    if (!result.faceDetected) {
      return;
    }
    _openBy[step]!.add(result.mouthOpen);
  }

  void clear() {
    for (final samples in _openBy.values) {
      samples.clear();
    }
  }

  /// Turns the collected frames into thresholds, or explains why it cannot.
  CalibrationOutcome derive() {
    for (final step in CalibrationStep.values) {
      if (!isStepComplete(step)) {
        return CalibrationOutcome.rejected(
          CalibrationProblem.tooFewSamples,
          '${step.name}: ${samplesFor(step)}/$minimumSamplesPerStep',
        );
      }
    }

    final restOpen = _median(_openBy[CalibrationStep.rest]!);
    final wideOpen = _median(_openBy[CalibrationStep.wideOpen]!);
    final restingNoise = _spread(_openBy[CalibrationStep.rest]!);

    if (restingNoise > maximumRestingNoise) {
      return CalibrationOutcome.rejected(
        CalibrationProblem.tooRestless,
        restingNoise.toStringAsFixed(3),
      );
    }

    final range = wideOpen - restOpen;
    if (range < minimumOpenRange) {
      return CalibrationOutcome.rejected(
        CalibrationProblem.noRange,
        range.toStringAsFixed(3),
      );
    }

    // Sit the open threshold inside the person's own range rather than at a
    // fixed number that may be above their widest mouth or below their rest.
    final open = restOpen + range * openThresholdFraction;

    // Motion has to clear the wobble measured while they were holding still,
    // or lipsing would read as "yes" on a motionless face.
    final motion = restingNoise * motionSafetyFactor;

    return CalibrationOutcome.accepted(
      DetectorSettings(
        mouthOpenThreshold: open.clamp(
          DetectorSettings.mouthOpenMin,
          DetectorSettings.mouthOpenMax,
        ),
        motionThreshold: motion.clamp(
          DetectorSettings.motionMin,
          DetectorSettings.motionMax,
        ),
        // Left at the default: the letter score is a blend of shape features
        // rather than a raw signal, so it does not shift with face size the
        // way the open reading does.
        letterMinScore: DetectorSettings.defaultLetterMinScore,
      ),
    );
  }

  /// The middle value, which ignores the occasional wild frame in a way a mean
  /// does not — one dropped detection would otherwise pull the whole step.
  static double _median(List<double> values) {
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[middle];
    }
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  /// How much the readings wobble, as a standard deviation.
  static double _spread(List<double> values) {
    if (values.length < 2) {
      return 0;
    }
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        (values.length - 1);
    return math.sqrt(variance);
  }
}
