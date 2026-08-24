import 'package:lips_offline/domain/face_lips_result.dart';

/// Builds a fake detection frame, as if MediaPipe had just measured a mouth.
///
/// Why this helper exists:
/// Every test needs a [FaceLipsResult], but a test usually only cares about
/// one or two values. This helper fills the rest with sensible zeros so each
/// test can say exactly what it is testing and nothing more.
///
/// The mouth box defaults to a wide, flat rectangle (a realistic mouth shape)
/// whose height is zero, so the geometric part of the "open" feature is 0 and
/// the tests depend only on the blendshape values they set.
FaceLipsResult frame({
  bool faceDetected = true,
  double mouthOpen = 0,
  double mouthPucker = 0,
  double smile = 0,
  double mouthClose = 0,
  double mouthFunnel = 0,
  double mouthStretch = 0,
  double mouthMinX = 0.0,
  double mouthMinY = 0.5,
  double mouthMaxX = 1.0,
  double mouthMaxY = 0.5,
}) {
  return FaceLipsResult(
    faceDetected: faceDetected,
    mouthOpen: mouthOpen,
    mouthPucker: mouthPucker,
    smile: smile,
    mouthClose: mouthClose,
    mouthFunnel: mouthFunnel,
    mouthStretch: mouthStretch,
    isLipsing: false,
    ts: 0,
    mouthMinX: mouthMinX,
    mouthMinY: mouthMinY,
    mouthMaxX: mouthMaxX,
    mouthMaxY: mouthMaxY,
  );
}

/// A frame where MediaPipe found no face at all.
FaceLipsResult noFaceFrame() => frame(faceDetected: false);
