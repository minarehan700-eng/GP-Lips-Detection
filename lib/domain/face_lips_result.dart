/// Everything the app knows about the mouth in ONE camera frame.
///
/// Why this class is needed:
/// The detection pipeline has several steps, and each step adds a little more
/// information. Passing one object along — instead of a long list of loose
/// numbers — keeps the steps easy to follow:
///
///   1. [MediaPipeFaceLandmarkExtractor] creates it from the native reply
///      (face found? mouth blendshapes, mouth box).
///   2. [LipsingDetector] fills in [isLipsing].
///   3. [LipLetterDetector] fills in [detectedLetter] and [letterConfidence].
///   4. The home screen reads it and draws the result.
///
/// The object is never edited in place. Each step returns a copy through
/// [copyWith], so an earlier step's values can always be trusted.
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

  /// The starting value used before the first frame arrives, and after a reset.
  static const empty = FaceLipsResult(
    faceDetected: false,
    mouthOpen: 0,
    mouthPucker: 0,
    smile: 0,
    isLipsing: false,
    ts: 0,
  );

  /// A mouth box smaller than this (as a fraction of the frame) is treated as
  /// no box at all — it would be a stray reading, not a real mouth.
  static const double minimumUsableBoxSize = 0.01;

  /// True when MediaPipe found a face in this frame.
  final bool faceDetected;

  // --- Mouth blendshapes -------------------------------------------------
  // A blendshape is a number from 0.0 (not at all) to 1.0 (fully) describing
  // one facial movement. They come straight from the MediaPipe model.

  /// How far the jaw is open (MediaPipe `jawOpen`).
  final double mouthOpen;

  /// How much the lips are pushed forward into a small circle (`mouthPucker`).
  final double mouthPucker;

  /// How much the mouth is smiling — the average of the left and right sides.
  final double smile;

  /// How firmly the lips are pressed together (`mouthClose`).
  final double mouthClose;

  /// How much the lips form a wide oval (`mouthFunnel`).
  final double mouthFunnel;

  /// How much the mouth is pulled sideways — the average of both sides.
  final double mouthStretch;

  // --- Results added by the detectors ------------------------------------

  /// The letter A–E being shown, or null when no rule matched.
  final String? detectedLetter;

  /// Confidence in [detectedLetter], from 0.0 to 1.0.
  final double letterConfidence;

  /// True when the user is judged to be lipsing (see [LipsingDetector]).
  final bool isLipsing;

  /// When this frame was analysed, in milliseconds since 1970.
  final int ts;

  // --- Mouth box ---------------------------------------------------------
  // Corners of the mouth region as fractions of the frame (0.0 – 1.0), not
  // pixels, so the same numbers work at any camera resolution.

  final double mouthMinX;
  final double mouthMinY;
  final double mouthMaxX;
  final double mouthMaxY;

  /// True when there is a face AND the mouth box is big enough to draw.
  ///
  /// Both checks are needed: a frame can report a face while the mouth box
  /// collapses to almost nothing, and drawing that would put a tiny box in
  /// the corner of the preview.
  bool get hasMouthBox {
    if (!faceDetected) {
      return false;
    }
    final double boxWidth = mouthMaxX - mouthMinX;
    final double boxHeight = mouthMaxY - mouthMinY;
    return boxWidth > minimumUsableBoxSize && boxHeight > minimumUsableBoxSize;
  }

  /// Returns a copy of this result with only the named fields changed.
  ///
  /// [clearDetectedLetter] exists because a plain `detectedLetter: null` could
  /// not be told apart from "leave the letter as it is". Passing
  /// `clearDetectedLetter: true` deliberately removes the letter, which is
  /// what happens when the face leaves the camera.
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
      detectedLetter:
          clearDetectedLetter ? null : (detectedLetter ?? this.detectedLetter),
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
