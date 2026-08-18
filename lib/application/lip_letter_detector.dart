import 'dart:math' as math;

import '../domain/face_lips_result.dart';

/// Classifies mouth shape into viseme letters A–E using simple rule-based logic.
class LipLetterDetector {
  LipLetterDetector({
    this.minScore = 0.28,
    this.hysteresisFrames = 2,
    this.windowSize = 5,
  });

  static const supportedLetters = ['A', 'B', 'C', 'D', 'E'];

  final double minScore;
  final int hysteresisFrames;
  final int windowSize;

  final List<_MouthFeatures> _window = [];

  String? _displayedLetter;
  String? _candidateLetter;
  int _candidateCount = 0;

  /// Updates letter classification from a new frame; hysteresis stabilizes display.
  FaceLipsResult update(FaceLipsResult raw) {
    if (!raw.faceDetected) {
      reset();
      return raw.copyWith(clearDetectedLetter: true, letterConfidence: 0);
    }

    _pushFeature(_extractFeatures(raw));
    final feats = _medianFeatures();
    final match = _classify(feats);

    if (match == null) {
      _candidateLetter = null;
      _candidateCount = 0;
      _displayedLetter = null;
      return raw.copyWith(clearDetectedLetter: true, letterConfidence: 0);
    }

    final (letter, score) = match;

    if (letter == _candidateLetter) {
      _candidateCount++;
    } else {
      _candidateLetter = letter;
      _candidateCount = 1;
    }

    if (_candidateCount >= hysteresisFrames) {
      _displayedLetter = letter;
    }

    return raw.copyWith(
      detectedLetter: _displayedLetter ?? letter,
      letterConfidence: score,
    );
  }

  void reset() {
    _window.clear();
    _displayedLetter = null;
    _candidateLetter = null;
    _candidateCount = 0;
  }

  _MouthFeatures _extractFeatures(FaceLipsResult raw) {
    final mouthW = math.max(raw.mouthMaxX - raw.mouthMinX, 0.01);
    final mouthH = math.max(raw.mouthMaxY - raw.mouthMinY, 0.0);
    final geoOpen = (mouthH / mouthW).clamp(0.0, 1.0);
    final open = (0.85 * raw.mouthOpen.clamp(0.0, 1.0) + 0.15 * geoOpen)
        .clamp(0.0, 1.0);

    return _MouthFeatures(
      open: open,
      close: raw.mouthClose.clamp(0.0, 1.0),
      pucker: raw.mouthPucker.clamp(0.0, 1.0),
      funnel: raw.mouthFunnel.clamp(0.0, 1.0),
      stretch: raw.mouthStretch.clamp(0.0, 1.0),
      smile: raw.smile.clamp(0.0, 1.0),
    );
  }

  void _pushFeature(_MouthFeatures feature) {
    _window.add(feature);
    while (_window.length > windowSize) {
      _window.removeAt(0);
    }
  }

  _MouthFeatures _medianFeatures() {
    if (_window.isEmpty) {
      return const _MouthFeatures(
        open: 0,
        close: 0,
        pucker: 0,
        funnel: 0,
        stretch: 0,
        smile: 0,
      );
    }

    double med(double Function(_MouthFeatures f) pick) {
      final values = _window.map(pick).toList()..sort();
      final mid = values.length ~/ 2;
      return values.length.isOdd
          ? values[mid]
          : (values[mid - 1] + values[mid]) / 2;
    }

    return _MouthFeatures(
      open: med((f) => f.open),
      close: med((f) => f.close),
      pucker: med((f) => f.pucker),
      funnel: med((f) => f.funnel),
      stretch: med((f) => f.stretch),
      smile: med((f) => f.smile),
    );
  }

  /// Exclusive priority: E → C → B → A → D.
  (String, double)? _classify(_MouthFeatures f) {
    final round = math.max(f.pucker, f.funnel);
    final smileWide = math.max(f.smile, f.stretch);

    // E — smile or stretch (not dominated by pucker)
    if (smileWide >= 0.28 && smileWide >= round - 0.05) {
      final score = _clamp01(smileWide);
      if (score >= minScore) return ('E', score);
    }

    // C — rounded / puckered lips
    if (round >= 0.22) {
      final score = _clamp01(round);
      if (score >= minScore) return ('C', score);
    }

    // B — closed mouth
    if (f.open <= 0.14 && (f.close >= 0.20 || f.open <= 0.10)) {
      final score = _clamp01(
        math.max(f.close, 1.0 - f.open),
      );
      if (score >= minScore) return ('B', score);
    }

    // A — wide open, no strong smile or pucker
    if (f.open >= 0.45 && smileWide < 0.28 && round < 0.22) {
      final score = _clamp01(f.open);
      if (score >= minScore) return ('A', score);
    }

    // D — medium open when nothing else matches
    if (f.open >= 0.16 && f.open <= 0.44) {
      final midStrength = 1.0 - ((f.open - 0.30).abs() / 0.14).clamp(0.0, 1.0);
      final score = _clamp01(midStrength * 0.85 + f.open * 0.15);
      if (score >= minScore) return ('D', score);
    }

    return null;
  }

  static double _clamp01(double v) => v.clamp(0.0, 1.0);
}

class _MouthFeatures {
  const _MouthFeatures({
    required this.open,
    required this.close,
    required this.pucker,
    required this.funnel,
    required this.stretch,
    required this.smile,
  });

  final double open;
  final double close;
  final double pucker;
  final double funnel;
  final double stretch;
  final double smile;
}
