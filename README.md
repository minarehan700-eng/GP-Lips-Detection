# Lips Offline

Standalone Flutter app that detects **lipsing** (mouth moving) and classifies mouth shape as **A, B, C, D, or E**. It reuses Signly’s MediaPipe Face Landmarker pipeline only — no ASL hands, TFLite classifier, dictionary, translate, auth, or practice.

Sibling of `mobile_offline` (Signly). Signly is not modified by this project.

## Requirements

- Flutter 3.3+ (tested with Flutter 3.38)
- Android 7+ (minSdk 24) or iOS 15+
- Front camera
- **`face_landmarker.task` is required**

This repo already includes the model copied from Signly:

- Android: `android/app/src/main/assets/face_landmarker.task`
- iOS: `ios/Runner/face_landmarker.task` (must stay in the Runner Xcode bundle)

If the file is missing, download it and place it in both locations:

https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task

## How to run

From this folder (`lips_offline/`):

```bash
flutter pub get
flutter run
```

Pick a connected Android device/emulator, or an iOS simulator/device.

On iOS, after `flutter pub get`, run CocoaPods so MediaPipe is linked:

```bash
cd ios
pod install
cd ..
flutter run
```

The iOS Podfile pins `MediaPipeTasksVision` `0.10.21`. Android pins `com.google.mediapipe:tasks-vision:0.10.29` (16 KB page-size aligned; needed on Android 15/16).

## What you should see

1. Short splash
2. Home: live front-camera preview, mouth box overlay, **Lipsing Yes/No**, letter **A–E**
3. Settings (gear icon): sliders for mouth-open, motion, and letter min-score — saved with SharedPreferences

Viseme cheat sheet on Home: Smile=E · Round=C · Closed=B · Wide open=A · Slight open=D

## Architecture

- Method channel: `lips/offline/face`
  - `initializeFaceLandmarker()` — Android initializes Face Landmarker on the **main thread** (Android 16 SIGSEGV workaround)
  - `processFaceFrame({bytes, ...})` → blendshapes + mouth box
- Camera JPEG frame → Face Landmarker → `LipsingDetector` + `LipLetterDetector` → UI

Release Android builds keep minify/shrink **disabled**, matching Signly, because R8 + MediaPipe JNI has crashed on Android 16.
