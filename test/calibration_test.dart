import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/core/detector_settings.dart';
import 'package:lips_offline/domain/calibration.dart';
import 'package:lips_offline/domain/confusion.dart';
import 'package:lips_offline/domain/face_lips_result.dart';

/// Tests for measuring one person's face instead of guessing at it.
void main() {
  FaceLipsResult frame(double open, {bool face = true}) => FaceLipsResult(
        faceDetected: face,
        mouthOpen: open,
        mouthPucker: 0,
        smile: 0,
        isLipsing: false,
        ts: 0,
      );

  /// Fills a step with [count] readings around [centre], wobbling by [noise].
  void feed(
    Calibration calibration,
    CalibrationStep step,
    double centre, {
    double noise = 0.005,
    int count = Calibration.minimumSamplesPerStep,
    int seed = 7,
  }) {
    final random = Random(seed);
    for (var i = 0; i < count; i++) {
      calibration.addSample(
        step,
        frame(centre + (random.nextDouble() - 0.5) * 2 * noise),
      );
    }
  }

  /// A well-behaved calibration: still at rest, a real range when open.
  Calibration goodCalibration() {
    final c = Calibration();
    feed(c, CalibrationStep.rest, 0.06);
    feed(c, CalibrationStep.wideOpen, 0.62);
    feed(c, CalibrationStep.rounded, 0.20);
    feed(c, CalibrationStep.spread, 0.14);
    return c;
  }

  group('collecting readings', () {
    test('a step needs enough frames before it counts', () {
      final c = Calibration();
      feed(c, CalibrationStep.rest, 0.05, count: 3);

      expect(c.isStepComplete(CalibrationStep.rest), isFalse);
      expect(c.stepProgress(CalibrationStep.rest),
          closeTo(3 / Calibration.minimumSamplesPerStep, 0.001));
    });

    test('frames with no face are dropped, not counted as zero', () {
      // A zero would drag the average towards a mouth that is not there, and
      // calibrate the user against the moment they looked away.
      final c = Calibration();
      for (var i = 0; i < 20; i++) {
        c.addSample(CalibrationStep.rest, frame(0, face: false));
      }

      expect(c.samplesFor(CalibrationStep.rest), 0);
      expect(c.isStepComplete(CalibrationStep.rest), isFalse);
    });

    test('progress never runs past full', () {
      final c = Calibration();
      feed(c, CalibrationStep.rest, 0.05, count: 200);

      expect(c.stepProgress(CalibrationStep.rest), 1.0);
    });

    test('clearing starts over', () {
      final c = goodCalibration();
      expect(c.isComplete, isTrue);

      c.clear();

      expect(c.isComplete, isFalse);
      expect(c.samplesFor(CalibrationStep.rest), 0);
    });
  });

  group('deriving thresholds', () {
    test('a good calibration produces usable settings', () {
      final outcome = goodCalibration().derive();

      expect(outcome.accepted, isTrue);
      final settings = outcome.settings!;
      // The threshold has to sit inside the person's own measured range: above
      // their resting mouth, below their widest.
      expect(settings.mouthOpenThreshold, greaterThan(0.06));
      expect(settings.mouthOpenThreshold, lessThan(0.62));
    });

    test('a wider face gets a higher threshold than a narrower one', () {
      // The whole point: the same 0.25 that is wide open on one person is a
      // resting face on another.
      final narrow = Calibration();
      feed(narrow, CalibrationStep.rest, 0.04);
      feed(narrow, CalibrationStep.wideOpen, 0.30);
      feed(narrow, CalibrationStep.rounded, 0.12);
      feed(narrow, CalibrationStep.spread, 0.10);

      final wide = Calibration();
      feed(wide, CalibrationStep.rest, 0.10);
      feed(wide, CalibrationStep.wideOpen, 0.68);
      feed(wide, CalibrationStep.rounded, 0.22);
      feed(wide, CalibrationStep.spread, 0.16);

      expect(
        wide.derive().settings!.mouthOpenThreshold,
        greaterThan(narrow.derive().settings!.mouthOpenThreshold),
      );
    });

    test('a restless face gets a higher motion threshold', () {
      // Motion has to clear the wobble measured while holding still, or
      // lipsing reads "yes" on a motionless face.
      final steady = goodCalibration();

      final jittery = Calibration();
      feed(jittery, CalibrationStep.rest, 0.06, noise: 0.04);
      feed(jittery, CalibrationStep.wideOpen, 0.62);
      feed(jittery, CalibrationStep.rounded, 0.20);
      feed(jittery, CalibrationStep.spread, 0.14);

      expect(
        jittery.derive().settings!.motionThreshold,
        greaterThan(steady.derive().settings!.motionThreshold),
      );
    });

    test('a single wild frame does not move the result much', () {
      // The median is used rather than the mean for exactly this.
      final clean = goodCalibration();
      final withOutlier = goodCalibration()
        ..addSample(CalibrationStep.wideOpen, frame(0.99));

      expect(
        withOutlier.derive().settings!.mouthOpenThreshold,
        closeTo(clean.derive().settings!.mouthOpenThreshold, 0.02),
      );
    });

    test('the result always sits inside the slider ranges', () {
      // Otherwise the Settings screen would be handed a value its own sliders
      // cannot display.
      final extreme = Calibration();
      feed(extreme, CalibrationStep.rest, 0.80);
      feed(extreme, CalibrationStep.wideOpen, 0.99);
      feed(extreme, CalibrationStep.rounded, 0.85);
      feed(extreme, CalibrationStep.spread, 0.82);

      final settings = extreme.derive().settings!;

      expect(settings.mouthOpenThreshold,
          inInclusiveRange(
              DetectorSettings.mouthOpenMin, DetectorSettings.mouthOpenMax));
      expect(settings.motionThreshold,
          inInclusiveRange(
              DetectorSettings.motionMin, DetectorSettings.motionMax));
    });
  });

  group('refusing a bad calibration', () {
    test('an unfinished walk-through is rejected, naming the step', () {
      final c = Calibration();
      feed(c, CalibrationStep.rest, 0.06);

      final outcome = c.derive();

      expect(outcome.accepted, isFalse);
      expect(outcome.problem, CalibrationProblem.tooFewSamples);
      expect(outcome.detail, contains('wideOpen'));
    });

    test('a mouth that never opened is rejected', () {
      // Silently accepting this would leave the user with thresholds worse
      // than the defaults and no idea why detection got worse.
      final c = Calibration();
      feed(c, CalibrationStep.rest, 0.20);
      feed(c, CalibrationStep.wideOpen, 0.22);
      feed(c, CalibrationStep.rounded, 0.20);
      feed(c, CalibrationStep.spread, 0.21);

      final outcome = c.derive();

      expect(outcome.problem, CalibrationProblem.noRange);
      expect(outcome.settings, isNull);
    });

    test('a face that would not hold still is rejected', () {
      final c = Calibration();
      feed(c, CalibrationStep.rest, 0.30, noise: 0.35);
      feed(c, CalibrationStep.wideOpen, 0.70);
      feed(c, CalibrationStep.rounded, 0.20);
      feed(c, CalibrationStep.spread, 0.14);

      expect(c.derive().problem, CalibrationProblem.tooRestless);
    });
  });

  group('learning which shapes get mixed up', () {
    test('a correct attempt is not a confusion', () {
      final m = ConfusionMatrix()..record(target: 'C', detected: 'C');

      expect(m.isEmpty, isTrue);
    });

    test('nothing detected is not a confusion either', () {
      // "No face in shot" says nothing about which shapes look alike.
      final m = ConfusionMatrix()..record(target: 'C', detected: null);

      expect(m.isEmpty, isTrue);
    });

    test('counts build up per pair', () {
      final m = ConfusionMatrix();
      for (var i = 0; i < 3; i++) {
        m.record(target: 'C', detected: 'D');
      }
      m.record(target: 'A', detected: 'B');

      expect(m.countFor(target: 'C', detected: 'D'), 3);
      expect(m.countFor(target: 'A', detected: 'B'), 1);
      expect(m.countFor(target: 'A', detected: 'D'), 0);
    });

    test('the worst pair is the one worth reporting', () {
      final m = ConfusionMatrix();
      for (var i = 0; i < 5; i++) {
        m.record(target: 'C', detected: 'D');
      }
      m.record(target: 'A', detected: 'E');

      final worst = m.worst()!;
      expect(worst.target, 'C');
      expect(worst.mistakenFor, 'D');
      expect(worst.count, 5);
    });

    test('a one-off slip is not presented as a pattern', () {
      final m = ConfusionMatrix()..record(target: 'C', detected: 'D');

      expect(m.worst(), isNull);
    });

    test('ties keep a stable order between builds', () {
      final a = ConfusionMatrix()
        ..record(target: 'B', detected: 'D')
        ..record(target: 'A', detected: 'C');
      final b = ConfusionMatrix()
        ..record(target: 'A', detected: 'C')
        ..record(target: 'B', detected: 'D');

      expect(
        a.pairs.map((p) => '${p.target}>${p.mistakenFor}'),
        b.pairs.map((p) => '${p.target}>${p.mistakenFor}'),
      );
    });
  });
}
