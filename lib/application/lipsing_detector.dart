import '../domain/face_lips_result.dart';

/// Detects active lipsing (mouth movement) using frame history and hysteresis
/// to avoid flickering between Yes/No states.
class LipsingDetector {
  LipsingDetector({
    this.historySize = 8,
    this.mouthOpenThreshold = 0.25,
    this.motionThreshold = 0.035,
    this.hysteresisFrames = 3,
  });

  final int historySize;
  final double mouthOpenThreshold;
  final double motionThreshold;
  final int hysteresisFrames;

  final List<_MouthSample> _history = <_MouthSample>[];
  bool _isLipsing = false;
  int _onCount = 0;
  int _offCount = 0;

  bool get isLipsing => _isLipsing;

  /// Updates lipsing state from a new detection frame and returns the result
  /// with a stabilized [isLipsing] flag.
  FaceLipsResult update(FaceLipsResult raw) {
    if (!raw.faceDetected) {
      _history.clear();
      _onCount = 0;
      _offCount++;
      if (_offCount >= hysteresisFrames) {
        _isLipsing = false;
        _offCount = 0;
      }
      return raw.copyWith(isLipsing: _isLipsing);
    }

    final sample = _MouthSample(
      mouthOpen: raw.mouthOpen,
      mouthPucker: raw.mouthPucker,
      smile: raw.smile,
    );
    _history.add(sample);
    while (_history.length > historySize) {
      _history.removeAt(0);
    }

    final openEnough = raw.mouthOpen > mouthOpenThreshold;
    final motionEnough = _averageMouthDelta() > motionThreshold;
    final active = openEnough || motionEnough;

    if (active) {
      _onCount++;
      _offCount = 0;
      if (_onCount >= hysteresisFrames || raw.mouthOpen > mouthOpenThreshold * 1.4) {
        _isLipsing = true;
      }
    } else {
      _offCount++;
      _onCount = 0;
      if (_offCount >= hysteresisFrames) {
        _isLipsing = false;
      }
    }

    return raw.copyWith(isLipsing: _isLipsing);
  }

  void reset() {
    _history.clear();
    _isLipsing = false;
    _onCount = 0;
    _offCount = 0;
  }

  /// Average mouth metric change between consecutive frames in history.
  double _averageMouthDelta() {
    if (_history.length < 2) return 0;
    var sum = 0.0;
    var count = 0;
    for (var i = 1; i < _history.length; i++) {
      final prev = _history[i - 1];
      final curr = _history[i];
      sum += (curr.mouthOpen - prev.mouthOpen).abs();
      sum += (curr.mouthPucker - prev.mouthPucker).abs() * 0.5;
      sum += (curr.smile - prev.smile).abs() * 0.35;
      count++;
    }
    if (count == 0) return 0;
    return sum / count;
  }
}

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
