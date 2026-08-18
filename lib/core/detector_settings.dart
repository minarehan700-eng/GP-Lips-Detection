import 'package:shared_preferences/shared_preferences.dart';

/// Persisted thresholds for lipsing and letter detection (SharedPreferences).
class DetectorSettings {
  const DetectorSettings({
    required this.mouthOpenThreshold,
    required this.motionThreshold,
    required this.letterMinScore,
  });

  static const mouthOpenKey = 'mouth_open_threshold';
  static const motionKey = 'motion_threshold';
  static const letterMinScoreKey = 'letter_min_score';

  static const defaultMouthOpen = 0.25;
  static const defaultMotion = 0.035;
  static const defaultLetterMinScore = 0.28;

  final double mouthOpenThreshold;
  final double motionThreshold;
  final double letterMinScore;

  static const defaults = DetectorSettings(
    mouthOpenThreshold: defaultMouthOpen,
    motionThreshold: defaultMotion,
    letterMinScore: defaultLetterMinScore,
  );

  /// Loads saved settings or returns defaults when keys are missing.
  static Future<DetectorSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return DetectorSettings(
      mouthOpenThreshold: prefs.getDouble(mouthOpenKey) ?? defaultMouthOpen,
      motionThreshold: prefs.getDouble(motionKey) ?? defaultMotion,
      letterMinScore: prefs.getDouble(letterMinScoreKey) ?? defaultLetterMinScore,
    );
  }

  /// Persists the current threshold values to SharedPreferences.
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(mouthOpenKey, mouthOpenThreshold);
    await prefs.setDouble(motionKey, motionThreshold);
    await prefs.setDouble(letterMinScoreKey, letterMinScore);
  }

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
