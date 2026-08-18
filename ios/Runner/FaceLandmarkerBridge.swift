import Foundation
import MediaPipeTasksVision
import UIKit

final class FaceLandmarkerBridge {
  private var faceLandmarker: FaceLandmarker?

  func isInitialized() -> Bool { faceLandmarker != nil }

  func initialize(modelPath: String) throws {
    if faceLandmarker != nil { return }

    let baseOptions = BaseOptions(modelAssetPath: modelPath)
    var options = FaceLandmarkerOptions()
    options.baseOptions = baseOptions
    options.runningMode = .image
    options.numFaces = 1
    options.minFaceDetectionConfidence = 0.5
    options.minFacePresenceConfidence = 0.5
    options.minTrackingConfidence = 0.5
    options.outputFaceBlendshapes = true
    faceLandmarker = try FaceLandmarker(options: options)
  }

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

    let blendshapes = extractBlendshapes(from: result)
    let mouthOpen = blendshapes["jawOpen"] ?? 0
    let mouthPucker = blendshapes["mouthPucker"] ?? 0
    let smileLeft = blendshapes["mouthSmileLeft"] ?? 0
    let smileRight = blendshapes["mouthSmileRight"] ?? 0
    let smile = (smileLeft + smileRight) / 2.0
    let mouthClose = blendshapes["mouthClose"] ?? 0
    let mouthFunnel = blendshapes["mouthFunnel"] ?? 0
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

  private func mouthBoundingBox(landmarks: [NormalizedLandmark]) -> (Double, Double, Double, Double) {
    // Tight outer-lip box: 61/291 corners, 0/17 vertical, 13/14 mid lip
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
