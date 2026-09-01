import 'package:shared_preferences/shared_preferences.dart';

/// The three sensitivity settings the user can change, saved on the phone.
///
/// Why this class is needed:
/// Every person's face and every room's lighting is different, so one fixed
/// set of thresholds cannot suit everyone. These three values let the user
/// tune the detectors from the Settings screen, and `shared_preferences`
/// keeps the choice after the app is closed.
///
/// This is also the single place where those values — their defaults, their
/// storage keys and their allowed ranges — are written down.
class DetectorSettings {
  const DetectorSettings({
    required this.mouthOpenThreshold,
    required this.motionThreshold,
    required this.letterMinScore,
  });

  // --- Storage keys ------------------------------------------------------
  // The exact text used to save each value on the phone. Changing one of
  // these would make the app forget the user's saved setting, so they stay
  // fixed.

  static const mouthOpenKey = 'mouth_open_threshold';
  static const motionKey = 'motion_threshold';
  static const letterMinScoreKey = 'letter_min_score';

  // --- Defaults ----------------------------------------------------------
  // Used on first launch, and by the "Reset to defaults" button.

  static const defaultMouthOpen = 0.25;
  static const defaultMotion = 0.035;
  static const defaultLetterMinScore = 0.28;

  // --- Slider ranges -----------------------------------------------------
  // The limits the Settings sliders may move between. They are kept here,
  // next to the defaults, so all the tuning numbers live in one file.

  static const mouthOpenMin = 0.05;
  static const mouthOpenMax = 0.70;
  static const mouthOpenDivisions = 13;

  static const motionMin = 0.010;
  static const motionMax = 0.080;
  static const motionDivisions = 14;

  static const letterMinScoreMin = 0.10;
  static const letterMinScoreMax = 0.70;
  static const letterMinScoreDivisions = 12;

  /// How open the mouth must be before it counts as active lipsing.
  final double mouthOpenThreshold;

  /// How much the mouth must move between frames to count as lipsing.
  final double motionThreshold;

  /// The lowest confidence a letter may have and still be shown.
  final double letterMinScore;

  /// The values used before the user has changed anything.
  static const defaults = DetectorSettings(
    mouthOpenThreshold: defaultMouthOpen,
    motionThreshold: defaultMotion,
    letterMinScore: defaultLetterMinScore,
  );

  /// Reads the saved settings from the phone.
  ///
  /// Output: the stored values, or the defaults for any value never saved.
  /// This is why the app works correctly on a completely fresh install.
  /// Every value is clamped to its slider range on the way out. What is on
  /// disk is not necessarily what this app wrote: an older build may have
  /// stored a value from a range that has since changed, and the stored file
  /// is editable on a rooted or debug device. The Settings screen already
  /// clamps before handing a value to a [Slider], which would otherwise throw;
  /// clamping here means the *detectors* are given a usable threshold too,
  /// instead of one that silently disables detection.
  static Future<DetectorSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return DetectorSettings(
      mouthOpenThreshold: _within(
        prefs.getDouble(mouthOpenKey) ?? defaultMouthOpen,
        mouthOpenMin,
        mouthOpenMax,
      ),
      motionThreshold: _within(
        prefs.getDouble(motionKey) ?? defaultMotion,
        motionMin,
        motionMax,
      ),
      letterMinScore: _within(
        prefs.getDouble(letterMinScoreKey) ?? defaultLetterMinScore,
        letterMinScoreMin,
        letterMinScoreMax,
      ),
    );
  }

  /// Brings one stored value back inside its allowed range.
  ///
  /// A NaN cannot be compared into range — `clamp` returns NaN for it — so it
  /// is replaced by the midpoint of the range instead of being passed on.
  static double _within(double value, double min, double max) {
    if (value.isNaN) {
      return (min + max) / 2;
    }
    return value.clamp(min, max);
  }

  /// Writes these settings to the phone so they survive a restart.
  ///
  /// Side effect: replaces the three stored values. The detectors do not
  /// change until [LipsCameraSession.applyDetectorSettings] reloads them,
  /// which the home screen does when the user comes back from Settings.
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(mouthOpenKey, mouthOpenThreshold);
    await prefs.setDouble(motionKey, motionThreshold);
    await prefs.setDouble(letterMinScoreKey, letterMinScore);
  }

  /// Returns a copy with only the named values changed.
  ///
  /// Used by the sliders: moving one slider must not disturb the other two.
  DetectorSettings copyWith({
    double? mouthOpenThreshold,
    double? motionThreshold,
    double? letterMinScore,
  }) {
    return DetectorSettings(
      mouthOpenThreshold: mouthOpenThreshold ?? this.mouthOpenThreshold,
      motionThreshold: motionThreshold ?? this.motionThreshold,
      letterMinScore: letterMinScore ?? this.letterMinScore,
    );
  }
}
