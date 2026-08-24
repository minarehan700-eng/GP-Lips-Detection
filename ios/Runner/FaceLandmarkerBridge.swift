import Foundation
import MediaPipeTasksVision
import UIKit

/// Runs Google's MediaPipe Face Landmarker on iOS.
///
/// This is the iOS twin of `FaceLandmarkerBridge.kt`. Both listen on the same
/// method channel name and return maps with exactly the same keys, so the Dart
/// code works on either platform without knowing which one it is running on.
final class FaceLandmarkerBridge {
  private var faceLandmarker: FaceLandmarker?

  func isInitialized() -> Bool { faceLandmarker != nil }

  /// Loads the face landmarker model from the app bundle.
  ///
  /// The model file travels inside the app, which is what makes detection work
  /// with no internet. Calling this twice is safe.
  func initialize(modelPath: String) throws {
    if faceLandmarker != nil { return }

    let baseOptions = BaseOptions(modelAssetPath: modelPath)
    var options = FaceLandmarkerOptions()
    options.baseOptions = baseOptions
    // Each frame is judged on its own; smoothing happens in the Dart detectors.
    options.runningMode = .image
    // One user practising in front of the phone, so one face.
    options.numFaces = 1
    // MediaPipe's balanced defaults: lower invents faces, higher misses them.
    options.minFaceDetectionConfidence = 0.5
    options.minFacePresenceConfidence = 0.5
    options.minTrackingConfidence = 0.5
    // Blendshapes are the mouth numbers the whole app is built on.
    options.outputFaceBlendshapes = true
    faceLandmarker = try FaceLandmarker(options: options)
  }

  /// Analyses one JPEG frame and returns the mouth numbers for Flutter.
  ///
  /// Input:  frameBytes — one camera frame encoded as JPEG.
  /// Output: a map with `faceDetected`, the six mouth blendshapes, the four
  ///         mouth-box values and a timestamp. Every failure path returns the
  ///         same map shape with `faceDetected: false`, so a single bad frame
  ///         never interrupts the live camera.
  func processFrame(frameBytes: Data) -> [String: Any] {
    guard !frameBytes.isEmpty else { return emptyFaceResult() }
    guard let faceLandmarker else { return emptyFaceResult() }
    guard let image = UIImage(data: frameBytes), let cgImage = image.cgImage else {
      return emptyFaceResult()
    }
    guard cgImage.width > 0, cgImage.height > 0 else { return emptyFaceResult() }

    let mpImage = try? MPImage(uiImage: UIImage(cgImage: cgImage))
    guard let mpImage else { return emptyFaceResult() }
    guard let result = try? faceLandmarker.detect(image: mpImage) else { return emptyFaceResult() }
    guard let face = result.faceLandmarks.first else { return emptyFaceResult() }

    // MediaPipe returns ~52 blendshapes for the whole face; only the mouth
    // ones are needed. Each is a score from 0.0 (not at all) to 1.0 (fully).
    let blendshapes = extractBlendshapes(from: result)
    let mouthOpen = blendshapes["jawOpen"] ?? 0
    let mouthPucker = blendshapes["mouthPucker"] ?? 0
    let mouthClose = blendshapes["mouthClose"] ?? 0
    let mouthFunnel = blendshapes["mouthFunnel"] ?? 0

    // Smile and stretch are reported per side of the face and averaged into
    // one value, because the app asks "is the mouth smiling?" rather than
    // "which side smiles more?".
    let smileLeft = blendshapes["mouthSmileLeft"] ?? 0
    let smileRight = blendshapes["mouthSmileRight"] ?? 0
    let smile = (smileLeft + smileRight) / 2.0
    let stretchLeft = blendshapes["mouthStretchLeft"] ?? 0
    let stretchRight = blendshapes["mouthStretchRight"] ?? 0
    let mouthStretch = (stretchLeft + stretchRight) / 2.0
    let box = mouthBoundingBox(landmarks: face)

    return [
      "faceDetected": true,
      "mouthOpen": mouthOpen,
      "mouthPucker": mouthPucker,
      "smile": smile,
      "mouthClose": mouthClose,
      "mouthFunnel": mouthFunnel,
      "mouthStretch": mouthStretch,
      "mouthMinX": box.0,
      "mouthMinY": box.1,
      "mouthMaxX": box.2,
      "mouthMaxY": box.3,
      "ts": Int(Date().timeIntervalSince1970 * 1000)
    ]
  }

  private func extractBlendshapes(from result: FaceLandmarkerResult) -> [String: Double] {
    var out: [String: Double] = [:]
    guard let classifications = result.faceBlendshapes.first else { return out }
    for category in classifications.categories {
      let name = category.categoryName
      guard !name.isEmpty else { continue }
      out[name] = Double(category.score)
    }
    return out
  }

  /// Works out a rectangle around the lips.
  ///
  /// Output: (minX, minY, maxX, maxY) as fractions of the frame (0.0 – 1.0),
  /// or four zeros when no landmarks were available.
  private func mouthBoundingBox(landmarks: [NormalizedLandmark]) -> (Double, Double, Double, Double) {
    // Fixed point numbers from MediaPipe's 478-point face mesh:
    //  61  = left mouth corner      291 = right mouth corner
    //  0   = top of the upper lip   17  = bottom of the lower lip
    //  13  = inner upper lip        14  = inner lower lip
    // Together they cover the full width and height of the lips.
    let lipIndices = [61, 291, 0, 17, 13, 14]
    var minX = 1.0
    var minY = 1.0
    var maxX = 0.0
    var maxY = 0.0
    var any = false
    for idx in lipIndices {
      guard idx >= 0, idx < landmarks.count else { continue }
      let x = Double(landmarks[idx].x)
      let y = Double(landmarks[idx].y)
      minX = min(minX, x)
      minY = min(minY, y)
      maxX = max(maxX, x)
      maxY = max(maxY, y)
      any = true
    }
    return any ? (minX, minY, maxX, maxY) : (0, 0, 0, 0)
  }

  /// The reply used whenever no face could be measured.
  ///
  /// It has exactly the same keys as a successful reply, so the Dart side can
  /// read every field without checking whether a face was found first.
  private func emptyFaceResult() -> [String: Any] {
    [
      "faceDetected": false,
      "mouthOpen": 0.0,
      "mouthPucker": 0.0,
      "smile": 0.0,
      "mouthClose": 0.0,
      "mouthFunnel": 0.0,
      "mouthStretch": 0.0,
      "mouthMinX": 0.0,
      "mouthMinY": 0.0,
      "mouthMaxX": 0.0,
      "mouthMaxY": 0.0,
      "ts": Int(Date().timeIntervalSince1970 * 1000)
    ]
  }
}
