/// Detection output for one frame: face/mouth blendshapes, lipsing flag, letter, and mouth box.
class FaceLipsResult {
  const FaceLipsResult({
    required this.faceDetected,
    required this.mouthOpen,
    required this.mouthPucker,
    required this.smile,
    required this.isLipsing,
    required this.ts,
    this.mouthClose = 0,
    this.mouthFunnel = 0,
    this.mouthStretch = 0,
    this.detectedLetter,
    this.letterConfidence = 0,
    this.mouthMinX = 0,
    this.mouthMinY = 0,
    this.mouthMaxX = 0,
    this.mouthMaxY = 0,
  });

  static const empty = FaceLipsResult(
    faceDetected: false,
    mouthOpen: 0,
    mouthPucker: 0,
    smile: 0,
    isLipsing: false,
    ts: 0,
  );

  final bool faceDetected;
  final double mouthOpen;
  final double mouthPucker;
  final double smile;
  final double mouthClose;
  final double mouthFunnel;
  final double mouthStretch;
  final String? detectedLetter;
  final double letterConfidence;
  final bool isLipsing;
  final int ts;
  final double mouthMinX;
  final double mouthMinY;
  final double mouthMaxX;
  final double mouthMaxY;

  /// True when a face is detected and the mouth box has usable dimensions.
  bool get hasMouthBox =>
      faceDetected && (mouthMaxX - mouthMinX) > 0.01 && (mouthMaxY - mouthMinY) > 0.01;

  /// Returns a copy with selectively updated fields.
  FaceLipsResult copyWith({
    bool? faceDetected,
    double? mouthOpen,
    double? mouthPucker,
    double? smile,
    double? mouthClose,
    double? mouthFunnel,
    double? mouthStretch,
    String? detectedLetter,
    bool clearDetectedLetter = false,
    double? letterConfidence,
    bool? isLipsing,
    int? ts,
    double? mouthMinX,
    double? mouthMinY,
    double? mouthMaxX,
    double? mouthMaxY,
  }) {
    return FaceLipsResult(
      faceDetected: faceDetected ?? this.faceDetected,
      mouthOpen: mouthOpen ?? this.mouthOpen,
      mouthPucker: mouthPucker ?? this.mouthPucker,
      smile: smile ?? this.smile,
      mouthClose: mouthClose ?? this.mouthClose,
      mouthFunnel: mouthFunnel ?? this.mouthFunnel,
      mouthStretch: mouthStretch ?? this.mouthStretch,
      detectedLetter: clearDetectedLetter ? null : (detectedLetter ?? this.detectedLetter),
      letterConfidence: letterConfidence ?? this.letterConfidence,
      isLipsing: isLipsing ?? this.isLipsing,
      ts: ts ?? this.ts,
      mouthMinX: mouthMinX ?? this.mouthMinX,
      mouthMinY: mouthMinY ?? this.mouthMinY,
      mouthMaxX: mouthMaxX ?? this.mouthMaxX,
      mouthMaxY: mouthMaxY ?? this.mouthMaxY,
    );
  }
}
