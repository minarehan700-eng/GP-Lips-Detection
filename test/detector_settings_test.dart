import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/core/detector_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests for loading and saving the three user settings.
///
/// `SharedPreferences.setMockInitialValues` stands in for the real phone
/// storage, so these tests run without a device.
void main() {
  // Needed because SharedPreferences talks to the platform.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DetectorSettings', () {
    test('a fresh install gets the default values', () async {
      SharedPreferences.setMockInitialValues({});

      final settings = await DetectorSettings.load();

      expect(settings.mouthOpenThreshold, DetectorSettings.defaultMouthOpen);
      expect(settings.motionThreshold, DetectorSettings.defaultMotion);
      expect(settings.letterMinScore, DetectorSettings.defaultLetterMinScore);
    });

    test('saved values are read back correctly', () async {
      SharedPreferences.setMockInitialValues({});

      const chosen = DetectorSettings(
        mouthOpenThreshold: 0.42,
        motionThreshold: 0.055,
        letterMinScore: 0.33,
      );
      await chosen.save();
      final reloaded = await DetectorSettings.load();

      expect(reloaded.mouthOpenThreshold, 0.42);
      expect(reloaded.motionThreshold, 0.055);
      expect(reloaded.letterMinScore, 0.33);
    });

    test('a partly filled store falls back to defaults for the rest', () async {
      // Only one value was ever saved, e.g. by an older version of the app.
      SharedPreferences.setMockInitialValues({
        'flutter.${DetectorSettings.mouthOpenKey}': 0.5,
      });

      final settings = await DetectorSettings.load();

      expect(settings.mouthOpenThreshold, 0.5);
      expect(settings.motionThreshold, DetectorSettings.defaultMotion);
      expect(settings.letterMinScore, DetectorSettings.defaultLetterMinScore);
    });

    test('copyWith changes one value and leaves the others alone', () {
      const settings = DetectorSettings.defaults;

      final updated = settings.copyWith(motionThreshold: 0.07);

      expect(updated.motionThreshold, 0.07);
      expect(updated.mouthOpenThreshold, settings.mouthOpenThreshold);
      expect(updated.letterMinScore, settings.letterMinScore);
    });

    test('every default sits inside its own slider range', () {
      // If a default fell outside its range the Settings slider would throw.
      expect(
        DetectorSettings.defaultMouthOpen,
        inInclusiveRange(
          DetectorSettings.mouthOpenMin,
          DetectorSettings.mouthOpenMax,
        ),
      );
      expect(
        DetectorSettings.defaultMotion,
        inInclusiveRange(
          DetectorSettings.motionMin,
          DetectorSettings.motionMax,
        ),
      );
      expect(
        DetectorSettings.defaultLetterMinScore,
        inInclusiveRange(
          DetectorSettings.letterMinScoreMin,
          DetectorSettings.letterMinScoreMax,
        ),
      );
    });

    test('a value stored above its range is brought back to the maximum', () async {
      SharedPreferences.setMockInitialValues({
        DetectorSettings.mouthOpenKey: 9.5,
        DetectorSettings.motionKey: 4.0,
        DetectorSettings.letterMinScoreKey: 2.0,
      });

      final settings = await DetectorSettings.load();

      expect(settings.mouthOpenThreshold, DetectorSettings.mouthOpenMax);
      expect(settings.motionThreshold, DetectorSettings.motionMax);
      expect(settings.letterMinScore, DetectorSettings.letterMinScoreMax);
    });

    test('a value stored below its range is brought back to the minimum', () async {
      SharedPreferences.setMockInitialValues({
        DetectorSettings.mouthOpenKey: -3.0,
        DetectorSettings.motionKey: 0.0,
        DetectorSettings.letterMinScoreKey: -0.5,
      });

      final settings = await DetectorSettings.load();

      expect(settings.mouthOpenThreshold, DetectorSettings.mouthOpenMin);
      expect(settings.motionThreshold, DetectorSettings.motionMin);
      expect(settings.letterMinScore, DetectorSettings.letterMinScoreMin);
    });

    test('a stored NaN cannot leak through as a threshold', () async {
      // clamp() returns NaN for a NaN input, so this needs handling of its
      // own: a NaN threshold compares false against everything, which would
      // switch detection off completely rather than loosen it.
      SharedPreferences.setMockInitialValues({
        DetectorSettings.mouthOpenKey: double.nan,
      });

      final settings = await DetectorSettings.load();

      expect(settings.mouthOpenThreshold.isNaN, isFalse);
      expect(
        settings.mouthOpenThreshold,
        inInclusiveRange(
          DetectorSettings.mouthOpenMin,
          DetectorSettings.mouthOpenMax,
        ),
      );
    });
  });
}
