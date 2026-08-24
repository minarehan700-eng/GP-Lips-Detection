import Flutter
import UIKit

/// The iOS entry point, and the switchboard between Flutter and MediaPipe.
///
/// It listens on the same method channel as the Android `MainActivity` and
/// answers the same three methods, so the Dart code is identical on both
/// platforms.
@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Must match the channel name used in the Dart extractor.
  private let faceChannelName = "lips/offline/face"

  private let faceBridge = FaceLandmarkerBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let faceChannel = FlutterMethodChannel(
      name: faceChannelName,
      binaryMessenger: controller.binaryMessenger
    )

    faceChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self else { return }
      switch call.method {
      case "initializeFaceLandmarker":
        guard let modelPath = Bundle.main.path(forResource: "face_landmarker", ofType: "task") else {
          result(FlutterError(code: "model_missing", message: "face_landmarker.task not found", details: nil))
          return
        }
        do {
          try self.faceBridge.initialize(modelPath: modelPath)
          result(nil)
        } catch {
          result(FlutterError(
            code: "init_failed",
            message: "Failed to initialize face landmarker. Ensure face_landmarker.task is in the Runner bundle.",
            details: error.localizedDescription
          ))
        }
      case "isFaceLandmarkerInitialized":
        result(self.faceBridge.isInitialized())
      case "processFaceFrame":
        guard
          let args = call.arguments as? [String: Any],
          let typedData = args["bytes"] as? FlutterStandardTypedData
        else {
          result(FlutterError(code: "bad_args", message: "Missing bytes", details: nil))
          return
        }
        let payload = self.faceBridge.processFrame(frameBytes: typedData.data)
        result(payload)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
