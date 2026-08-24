# Code Discussion Guide

Everything you need to explain this project confidently.

---

# 1. The project in 60 seconds

> "Lips Offline is a Flutter app that helps someone practising sign language check their mouth shapes. Sign languages use **mouthing** to tell similar hand signs apart, but a learner alone cannot see their own mouth.
>
> The app **starts** at `main.dart`, shows a splash screen, then onboarding, then the home screen. On the home screen it opens the **front camera**.
>
> The user provides nothing but their face. About **seven times a second**, one camera frame is converted to JPEG and sent to Google's **MediaPipe Face Landmarker**, which runs natively on the device.
>
> MediaPipe returns numbers describing the mouth — how open, how puckered, how wide. Two classes of mine turn those numbers into answers: `LipsingDetector` decides whether the user is lipsing, and `LipLetterDetector` classifies the mouth shape into a practice letter **A to E**.
>
> The result appears on the home screen with a confidence percentage and a green box around the mouth. Everything runs on the phone — no internet, and no video ever leaves the device."

**بالعربي:** تطبيق Flutter بيساعد اللي بيتعلّم لغة الإشارة إنه يتأكد من شكل فمه. بيبدأ من `main.dart`، وبعدين splash، وبعدين ٣ صفحات تعريف، وبعدين الشاشة الرئيسية اللي بتفتح الكاميرا الأمامية. كل ١٥٠ ملي ثانية بناخد فريم، نحوّله JPEG، ونبعته لـ MediaPipe اللي شغال native على الجهاز. بيرجّعلنا أرقام الفم، وكلاسين بتوعي بيحوّلوا الأرقام دي لإجابة Yes/No وحرف من A لـ E. وكل ده على الموبايل من غير إنترنت.

---

# 2. File-by-file explanation

**Essential** = study this, examiners will likely open it.

| File | Why it exists | What calls it | What it calls | Feature | Essential? |
|------|---------------|---------------|---------------|---------|-----------|
| `lib/main.dart` | App entry point; sets the theme and the first screen | Flutter runtime | `SplashScreen`, `AppTheme` | Starting the app | **Yes** |
| `lib/domain/face_lips_result.dart` | Carries one frame's mouth data through every stage | Everything | Nothing | All detection | **Yes** |
| `lib/application/lips_camera_session.dart` | Owns the camera and runs the whole pipeline | `HomeScreen` | Encoder, extractor, both detectors, settings | Camera + processing | **Yes** |
| `lib/application/lipsing_detector.dart` | Decides Lipsing Yes/No | `LipsCameraSession` | Nothing | Lipsing detection | **Yes** |
| `lib/application/lip_letter_detector.dart` | Classifies the mouth shape A–E | `LipsCameraSession` | Nothing | Letter detection | **Yes** |
| `lib/infrastructure/mediapipe_face_landmark_extractor.dart` | The only Dart file that talks to native code | `LipsCameraSession` | Kotlin/Swift over the method channel | Model + detection | **Yes** |
| `lib/infrastructure/camera_frame_encoder.dart` | Converts camera pixels into JPEG | `LipsCameraSession` | `image` package | Frame conversion | Yes |
| `lib/widgets/lips_camera_preview.dart` | Draws the camera and the mouth box | `HomeScreen` | `MouthBoxPainter` | Preview + overlay | **Yes** |
| `lib/screens/home_screen.dart` | The main screen; shows loading, error or results | `OnboardingScreen` | `LipsCameraSession`, all panels | Main UI | **Yes** |
| `lib/core/detector_settings.dart` | Loads and saves the three thresholds | Settings screen, camera session | `shared_preferences` | Settings | Yes |
| `lib/screens/settings_screen.dart` | Three sliders, Save, Reset | `HomeScreen` | `DetectorSettings` | Settings UI | Yes |
| `lib/widgets/lips_detection_panels.dart` | The letter panel and metrics panel | `HomeScreen` | `detection_ui.dart` | Result display | Yes |
| `lib/screens/splash_screen.dart` | 2.2-second branded opening | `main.dart` | `OnboardingScreen` | Splash | No |
| `lib/screens/onboarding/` | Three intro pages | `SplashScreen` | `HomeScreen` | Onboarding | No |
| `lib/widgets/detection_ui.dart` | Status card, letter chip, metric tile | Panels, home | `GlassCard` | Small UI parts | No |
| `lib/widgets/glass_card.dart` | The frosted-glass card look | Everywhere | Nothing | Styling | No |
| `lib/widgets/gradient_background.dart` | The blue→purple background | Every screen | `AppTheme` | Styling | No |
| `lib/widgets/animated_brand_text.dart` | Animated "Lips" wordmark | `SplashScreen` | Nothing | Branding | No |
| `lib/core/app_theme.dart` | All colours in one place | Everywhere | Nothing | Appearance | No |
| `lib/core/app_navigation.dart` | The shared fade transition | Splash, onboarding | Nothing | Navigation | No |
| `android/.../FaceLandmarkerBridge.kt` | Runs MediaPipe on Android | `MainActivity` | MediaPipe, the `.task` model | Detection | **Yes** |
| `android/.../MainActivity.kt` | Receives channel calls, manages threads | Flutter engine | `FaceLandmarkerBridge` | Detection | **Yes** |
| `ios/Runner/FaceLandmarkerBridge.swift` | The same job on iOS | `AppDelegate` | MediaPipe | Detection | No |

---

# 3. The most important functions

### `LipsCameraSession._onFrame()`
- **Purpose:** run the whole pipeline for one camera frame.
- **Inputs:** a `CameraImage`, a redraw callback. **Output:** none — replaces `result`.
- **Steps:** skip if busy → skip if <150 ms → JPEG → native MediaPipe → lipsing detector → letter detector → redraw.
- **Difficult line:** `finally { _isProcessing = false; }`
- **Why this way:** the camera produces ~30 frames/sec, MediaPipe handles ~7.
- **Q: What if you removed the `finally`?** After the first error the flag stays `true` forever and detection stops silently.

### `LipsingDetector.update()`
- **Purpose:** turn per-frame numbers into a steady Yes/No.
- **Steps:** no face → fade to No; else remember the frame, check open **OR** moving, count the vote, flip only after 3 agree.
- **Difficult line:** the weighted movement sum (1.0 / 0.5 / 0.35).
- **Q: What is hysteresis?** Requiring several agreeing readings before changing state, so the label does not flicker.

### `LipLetterDetector._classify()`
- **Purpose:** pick a letter A–E.
- **Input:** the median of the last 5 frames. **Output:** letter + confidence, or `null`.
- **Difficult line:** `smileBeatsRound` — stops an "oo" shape with a slight smile being read as E.
- **Q: Why that order?** Mouth shapes overlap; a smile is also slightly open, so the distinctive shapes must be asked first.

### `MouthBoxPainter.computeMouthRect()`
- **Purpose:** turn MediaPipe's 0–1 coordinates into screen pixels.
- **Difficult lines:** `y = 1.0 - originalX` (quarter-turn) and `x = 1.0 - x` (front-camera mirror).
- **Q: How did you test it without a camera?** It is a pure function taking numbers and returning a rectangle — 11 unit tests cover it, including 6,000 random inputs.

### `MediaPipeFaceLandmarkExtractor.processFrame()`
- **Purpose:** the bridge into native code.
- **Difficult line:** `(response[key] as num?)?.toDouble() ?? 0`
- **Q: Why so defensive?** The map crosses a platform boundary; a key could be missing or arrive as the wrong numeric type.

---

# 4. The Random-File Method

**If the examiner opens a file you did not revise, do not panic.** Answer these eight questions in order. The structure of the project answers most of them for you.

### Step 1 — Which folder is it in?
Look at the path. That alone tells you its job:

| Folder | Its one responsibility |
|--------|------------------------|
| `lib/domain/` | Data only. No logic, no camera, no UI. |
| `lib/application/` | The logic — the "brain". Decides what the answer is. |
| `lib/infrastructure/` | Talks to the outside world: camera format, native code, phone storage. |
| `lib/core/` | Settings, colours, page transitions. Used everywhere. |
| `lib/screens/` | A complete page the user sees. |
| `lib/widgets/` | A reusable piece of UI used inside screens. |
| `android/` `ios/` | Native code that runs MediaPipe. |
| `test/` | Automated tests. |

> **Say:** *"This file is in `lib/widgets/`, so it is a reusable piece of user interface — it does not contain detection logic."*

### Step 2 — What class is inside?
Scroll to the top. There is a `///` comment above every important class explaining what it represents and why it exists. **Read it out.** That is what the comments are for.

### Step 3–6 — Inputs, processing, output, feature
Every important function has a docstring listing its inputs, output, side effects and steps. Find the main function and read its docstring.

For a **widget**, the answer is almost always the same shape:
> *"Its inputs are the constructor fields at the top. Its processing is the `build` method. Its output is what appears on screen. It is used by [the screen that creates it]."*

### Step 7 — Which feature uses it?
Use `Ctrl+Shift+F` in VS Code to search for the class name and see who creates it. Or use the file-by-file table in §2.

### Step 8 — Use the comments
The project has **672 lines of documentation comments and 99 explanatory comments**. If you are unsure, read the comment aloud and then say it in your own words. That is not cheating — it is exactly what documentation is for.

### The safe sentence for any file
> *"This file is in `<folder>`, which is responsible for `<responsibility>`. It contains `<class name>`, which `<read the class comment>`. It is used by `<caller>`. Would you like me to walk through its main function?"*

**بالعربي — طريقة الملف العشوائي:** لو المناقش فتح ملف ما ذاكرتهوش، متتوترش. بصّ على الفولدر الأول — الفولدر لوحده بيقولك وظيفة الملف. وبعدين اقرا التعليق اللي فوق الكلاس، وبعدين التعليق اللي فوق أهم دالة. المشروع فيه ٦٧٢ سطر توثيق و٩٩ تعليق، فاقرا التعليق وقوله بكلامك — دي وظيفة التوثيق أصلاً.

---

# 5. Expected questions (35)

Each has a **short answer** (say this first), a **detailed answer** (if pressed), the **code location**, and a **likely follow-up**.

---

## Flutter and Dart basics

**Q1. Why did you choose Flutter?**
- **Short:** One codebase runs on both Android and iOS.
- **Detailed:** It has a strong camera plugin, a method-channel system that made calling native MediaPipe straightforward, and a built-in test framework — which is how I have 73 automated tests.
- **Location:** `pubspec.yaml`
- **Follow-up:** *"Why not native Android only?"* → Then the project would work on one platform only, and I would have to write the UI twice to support iPhone.

**Q2. Why Dart?**
- **Short:** Dart is the language Flutter uses — you cannot use Flutter without it.
- **Detailed:** It compiles to fast native ARM code for release builds, and it supports hot reload during development, which made testing mouth thresholds much faster.
- **Follow-up:** *"Is Dart object-oriented?"* → Yes. Everything is an object, and my project uses classes throughout.

**Q3. What does `main()` do?**
- **Short:** It is the first function Dart runs — the entry point.
- **Detailed:** It calls `WidgetsFlutterBinding.ensureInitialized()` to prepare the connection to the phone's platform code, then `runApp()` with the root widget.
- **Location:** `lib/main.dart`
- **Follow-up:** *"Why `ensureInitialized`?"* → My app uses camera and saved settings, which are platform plugins. They must be ready before any widget is built.

**Q4. What does `runApp()` do?**
- **Short:** It takes the root widget and attaches it to the screen.
- **Detailed:** It inflates the widget into the render tree and starts Flutter's rendering loop, so the widget is drawn and kept updated.
- **Location:** `lib/main.dart`

**Q5. What is a widget?**
- **Short:** A widget is a description of one part of the user interface.
- **Detailed:** In Flutter everything visible is a widget — text, buttons, padding, even the whole app. Widgets are cheap descriptions; Flutter rebuilds them constantly and only repaints what actually changed.
- **Follow-up:** *"Give an example from your code."* → `GlassCard` in `lib/widgets/glass_card.dart` is a widget I wrote; it draws a frosted-glass panel.

**Q6. Difference between `StatelessWidget` and `StatefulWidget`?**
- **Short:** Stateless never changes after it is built; stateful can change over time.
- **Detailed:** `LipsOfflineApp` and `GlassCard` are stateless — they look the same every time. `HomeScreen` is stateful because the detection result changes many times per second and the screen must redraw.
- **Location:** `lib/main.dart` (stateless) vs `lib/screens/home_screen.dart` (stateful)
- **Follow-up:** *"Why is `SettingsScreen` stateful?"* → Because the slider values change while the user drags them.

**Q7. What does `setState()` do?**
- **Short:** It tells Flutter that the data changed, so the screen must be redrawn.
- **Detailed:** You change your variables inside `setState`, and Flutter marks the widget as dirty and calls `build()` again on the next frame. Changing a variable *without* `setState` would update the data but not the screen.
- **Location:** `HomeScreen._notifySessionChanged()`
- **Follow-up:** *"What if you call it after the screen is closed?"* → It throws. That is why I check `if (mounted)` first.

**Q8. What are `Future`, `async` and `await`?**
- **Short:** A `Future` is a value that will arrive later; `async`/`await` let you wait for it without freezing the screen.
- **Detailed:** Opening the camera and calling MediaPipe both take time. If I waited normally, the UI would freeze. `await` pauses just that function and lets Flutter keep drawing.
- **Location:** `LipsCameraSession.initialize()` and `_onFrame()`
- **Follow-up:** *"What happens if you forget `await`?"* → The code continues before the result arrives, so you would use an empty value.

**Q9. Why is `dispose()` important?**
- **Short:** It releases resources when a screen closes.
- **Detailed:** `HomeScreen.dispose()` closes the camera. Without it, the camera would keep running in the background — the phone would show the camera-in-use indicator and the battery would drain. `SplashScreen.dispose()` cancels its timer, and animation controllers are disposed too.
- **Location:** `lib/screens/home_screen.dart`
- **Follow-up:** *"What is a memory leak?"* → When you keep resources you no longer need, like a camera or a timer still running after its screen is gone.

**Q10. How does navigation work?**
- **Short:** With `Navigator`, which manages a stack of screens.
- **Detailed:** Splash and onboarding use `pushReplacement`, so the Back button cannot return to them — you should not go back to a splash screen. Settings uses a normal `push`, so Back returns to home. All transitions use one shared fade in `AppNavigation.fadeTransition`.
- **Location:** `lib/core/app_navigation.dart`
- **Follow-up:** *"Why replacement and not push?"* → So the user cannot press Back and land on the splash screen again.

---

## The architecture

**Q11. Why this folder structure?**
- **Short:** It is a layered architecture — each layer only depends on the ones below.
- **Detailed:** `domain` holds data with no dependencies; `application` holds the logic; `infrastructure` talks to the camera and native code; `screens`/`widgets` are the UI. The practical benefit is that my detection logic knows nothing about the camera, so I can unit-test it with fake frames on a laptop — which is exactly how my 73 tests run.
- **Follow-up:** *"Is that not over-engineering for a small app?"* → It earns its place here for one concrete reason: testability. Without the split, none of my detectors could be tested without a phone.

**Q12. How does data move through the app?**
- **Short:** In one direction, through a single object.
- **Detailed:** Camera → encoder → native bridge → `FaceLipsResult` → lipsing detector → letter detector → screen. Each stage adds information and returns a **copy**; it never changes what an earlier stage produced.
- **Location:** `lib/domain/face_lips_result.dart`

**Q13. How does data move between screens?**
- **Short:** Very little needs to move — each screen owns what it needs.
- **Detailed:** Settings does not pass data back directly. It saves to the phone with `shared_preferences`, and when `HomeScreen` resumes it calls `applyDetectorSettings()` to reload. That keeps the screens independent.
- **Location:** `HomeScreen._openSettings()`

**Q14. What state management do you use?**
- **Short:** Plain `setState` — no external package.
- **Detailed:** The app has one screen with live state. Adding Provider, BLoC or Riverpod would add a dependency and a layer of concepts without solving a problem I actually have. The session holds the data and calls a callback; the screen calls `setState`.
- **Follow-up:** *"When would you use BLoC?"* → If the app grew to many screens sharing the same state, or needed complex event streams.

---

## The algorithm

**Q15. Where is the main functionality implemented?**
- **Short:** `lib/application/` — three files.
- **Detailed:** `lips_camera_session.dart` runs the pipeline, `lipsing_detector.dart` decides Yes/No, `lip_letter_detector.dart` picks the letter.

**Q16. How is the model called?**
- **Short:** Through a Flutter **method channel** named `lips/offline/face`.
- **Detailed:** MediaPipe is a native library with no Dart version. Dart sends the method name plus the JPEG bytes; Kotlin (or Swift) runs detection and replies with a map of numbers.
- **Location:** `mediapipe_face_landmark_extractor.dart`
- **Follow-up:** *"Why not a Dart package?"* → There is no official Dart binding for the Face Landmarker; the model must run natively.

**Q17. What is a blendshape?**
- **Short:** A number from 0.0 to 1.0 describing one facial movement.
- **Detailed:** MediaPipe returns about 52. I use six mouth ones: `jawOpen`, `mouthPucker`, `mouthClose`, `mouthFunnel`, plus smile and stretch, which come separately for each side of the face and are averaged.
- **Location:** `FaceLandmarkerBridge.kt`

**Q18. What is a viseme?**
- **Short:** A mouth shape linked to a speech sound.
- **Detailed:** Several sounds look identical on the lips — "p", "b" and "m" all look like closed lips. That is exactly why lip reading alone is ambiguous, and why my app maps to five practice shapes rather than claiming to recognise words.

**Q19. Why only five letters?**
- **Short:** They are five clearly distinguishable mouth shapes.
- **Detailed:** Because different sounds share the same shape, adding more classes would make them overlap and accuracy would fall. Five gives honest, reliable feedback.
- **Follow-up:** *"Could you add more?"* → Yes, but I would need a labelled dataset and probably a trained classifier rather than rules.

**Q20. Why rules instead of training a neural network?**
- **Short:** I have no labelled dataset of signer mouth shapes.
- **Detailed:** Training needs data, computing power and time I did not have. MediaPipe already gives normalised, meaningful measurements, so simple rules on top are transparent, instant, need no training data, and — importantly — I can explain every decision.
- **Follow-up:** *"Is that a weakness?"* → It is a trade-off. Rules cannot adapt per person, which is why I made the thresholds adjustable in Settings.

**Q21. Why the order E → C → B → A → D?**
- **Short:** Because mouth shapes overlap.
- **Detailed:** A smile is also slightly open. If D ("slightly open") were asked first, every smile would be reported as D. So the most distinctive shapes are asked first and the vaguest is last as a fallback.
- **Location:** `LipLetterDetector._classify()`
- **Follow-up:** *"What if two rules both match?"* → The first one wins. That is what makes it a priority tree.

**Q22. Why the median of 5 frames, not the average?**
- **Short:** The median ignores one extreme reading.
- **Detailed:** If four frames say "closed" and one says "wide open", the median still says closed. An average would be dragged upward and could change the letter.
- **Location:** `LipLetterDetector._median()`

**Q23. How do you stop the display flickering?**
- **Short:** Three separate mechanisms.
- **Detailed:** Throttling (only ~7 frames/sec analysed), the median of 5 frames, and hysteresis — a new answer must win several frames in a row before being shown.

**Q24. Why 150 milliseconds?**
- **Short:** A mouth shape does not change meaningfully in 33 ms.
- **Detailed:** The camera gives ~30 frames/sec but MediaPipe handles ~7. Analysing every frame would drain the battery and cause stutter without improving accuracy.
- **Location:** `LipsCameraSession.minMillisecondsBetweenFrames`

---

## Validation, errors and testing

**Q25. How is input validated?**
- **Short:** At several points, before anything expensive happens.
- **Detailed:** The extractor refuses empty bytes or a zero width/height before calling native code. The encoder returns `null` for an unknown frame format. Every value from native is read as `num?` with a default of 0. Every feature is clamped to 0.0–1.0 before the rules run. The mouth width is floored at 0.01 so a division can never be by zero.
- **Location:** `processFrame()` and `_extractFeatures()`

**Q26. How are errors handled?**
- **Short:** On three levels.
- **Detailed:** (1) One bad frame → return "no face" and carry on, because a single frame must never interrupt a live camera. (2) Start-up failure → show an error screen with a **Try Again** button. (3) A malformed native reply → default every value to 0.
- **Location:** `LipsCameraSession.initialize()`, `HomeScreen._ErrorView`

**Q27. What if the model file is missing?**
- **Short:** A clear message, not a crash.
- **Detailed:** Native initialisation throws; Dart catches it and produces a message naming the exact folder the file belongs in; the home screen shows it with a retry button.

**Q28. What if camera permission is denied?**
- **Short:** The camera plugin throws a `PlatformException`, caught in `initialize()`, shown in the error view.

**Q29. How did you test the project?**
- **Short:** 73 automated tests, static analysis, and manual testing on a real phone.
- **Detailed:** Unit tests for both detectors, the data model, settings and the geometry; widget tests for onboarding, settings and the practice panel. `flutter analyze` reports zero issues. Face detection itself needs a real face, so that part was tested manually on a device.
- **Location:** `test/`
- **Follow-up:** *"Show me."* → Run `flutter test` live. It takes 9 seconds.

**Q30. How can you test detection without a camera?**
- **Short:** The detectors take a plain data object, not a camera image.
- **Detailed:** A test builds a fake `FaceLipsResult` saying "mouth 90% open, no smile" and checks the answer is A. That is the practical payoff of separating the layers.
- **Location:** `test/helpers/fake_frames.dart`

**Q31. What is your accuracy?**
- **Short:** I do not claim a percentage, because I did not measure one.
- **Detailed:** I did not collect a labelled test set, so any number would be invented. What I can say is that the five shapes are distinguishable in normal lighting, and that the thresholds are adjustable because faces and lighting differ.
- ⚠️ **Never invent a number here.** Saying "I did not measure it" is a strong, honest answer.

---

## "What if you changed this?"

**Q32. What if you removed the `finally` block in `_onFrame`?**
- After the first error, `_isProcessing` stays `true` forever, every future frame is skipped, and detection stops silently. The app would look frozen with no error message.

**Q33. What if `hysteresisFrames` were 1 instead of 3?**
- The Lipsing label would flicker between Yes and No several times a second whenever a value sat near the threshold.

**Q34. What if you removed `x = 1.0 - x` for the front camera?**
- The mouth box would move the wrong way — move your head left and the box goes right. It is the most visible possible bug.

**Q35. What are the limitations?**
- Not speech recognition (mouth shapes, not words); rule-based with no per-user calibration; no measured accuracy figure; lighting and angle affect results; one face only; ~7 analyses per second; onboarding shows every launch; iOS untested on a device.

---

# 6. Quick revision sheet

## The ten most important files
1. `lib/application/lip_letter_detector.dart`
2. `lib/application/lipsing_detector.dart`
3. `lib/application/lips_camera_session.dart`
4. `lib/domain/face_lips_result.dart`
5. `lib/infrastructure/mediapipe_face_landmark_extractor.dart`
6. `lib/widgets/lips_camera_preview.dart`
7. `lib/screens/home_screen.dart`
8. `android/.../FaceLandmarkerBridge.kt`
9. `android/.../MainActivity.kt`
10. `lib/core/detector_settings.dart`

## The ten most important functions
1. `LipsCameraSession._onFrame()`
2. `LipsCameraSession.initialize()`
3. `LipsingDetector.update()`
4. `LipsingDetector._averageMouthMovement()`
5. `LipLetterDetector._classify()`
6. `LipLetterDetector._median()`
7. `MediaPipeFaceLandmarkExtractor.processFrame()`
8. `MouthBoxPainter.computeMouthRect()`
9. `FaceLipsResult.copyWith()`
10. `HomeScreen._scheduleSetup()`

## The ten most important code blocks
1. The two guards + `finally` in `_onFrame`
2. The open **OR** moving condition
3. The weighted movement sum (1.0 / 0.5 / 0.35)
4. The E rule with `smileBeatsRound`
5. The D score (`shapeMatch * 0.85 + open * 0.15`)
6. `_median()` — odd vs even
7. The rotation `y = 1.0 - originalX`
8. The mirror `x = 1.0 - x`
9. `(response[key] as num?)?.toDouble() ?? 0`
10. `clearDetectedLetter ? null : (...)`

## The ten most important terms
| Term | One-line definition |
|------|---------------------|
| **Widget** | A description of one part of the UI |
| **State** | Data that changes while the screen is open |
| **`setState`** | Tells Flutter the data changed, so redraw |
| **Future / async / await** | A value arriving later, and waiting without freezing the UI |
| **Method channel** | How Dart calls native Kotlin/Swift code |
| **Blendshape** | A 0.0–1.0 number describing one facial movement |
| **Viseme** | A mouth shape linked to a speech sound |
| **Hysteresis** | Requiring several agreeing frames before changing state |
| **Median** | The middle value — ignores one extreme reading |
| **Throttling** | Deliberately processing fewer frames to save battery |

## The five hardest questions
1. **"Why that folder structure?"** → Layers, and the payoff is testability without a phone.
2. **"Why rules and not machine learning?"** → No labelled dataset; rules are transparent and explainable.
3. **"What is your accuracy?"** → I did not measure it, so I will not claim a number.
4. **"Explain the mouth box maths."** → Quarter-turn rotation plus a front-camera mirror; save the old X first.
5. **"What if you removed the `finally`?"** → Detection stops forever, silently.

---

# 7. Five-minute mock discussion

**Examiner:** *Tell us briefly what your project does.*
> "It is a Flutter app that helps someone practising sign language check their mouth shapes. It uses the front camera and tells them, completely offline, whether they are lipsing and which of five mouth shapes A to E they are making."

**Examiner:** *Show us it working.*
> [Open the app. Turn on airplane mode.] "I have put the phone in airplane mode to show it is genuinely offline — the AI model is bundled inside the app." [Demonstrate A, B, C, D, E. Tap a chip and show "Matched!".]

**Examiner:** *Where does the app start?*
> "At `main.dart`. `main()` calls `ensureInitialized()` — because the app uses camera and storage plugins that must be ready first — then `runApp()` with the root widget. That opens the splash screen, then onboarding, then home."

**Examiner:** *Where does the actual detection happen?*
> "In three files in `lib/application/`. `LipsCameraSession` runs the pipeline, `LipsingDetector` decides Yes/No, and `LipLetterDetector` picks the letter. The AI itself is MediaPipe running natively — I call it through a method channel."

**Examiner:** *Did you train the model yourself?*
> "No. I use Google's pre-trained MediaPipe Face Landmarker. My contribution is the layer on top: it returns about 52 blendshapes, and I turn six mouth ones into a stable lipsing answer and a letter, with smoothing so the display does not flicker."

**Examiner:** *How do you stop it flickering?*
> "Three ways. I only analyse about seven frames a second. I take the median of the last five frames, so one bad reading is out-voted. And I use hysteresis — a new answer must win three frames in a row before it is displayed."

**Examiner:** *Open `lip_letter_detector.dart`. Explain `_classify`.*
> "It is a priority tree — five rules in a fixed order, first match wins. The order is E, C, B, A, D, and it matters because mouth shapes overlap. A smile is also slightly open, so if I asked about D first, every smile would come out as D. Each threshold is a named constant with a comment explaining it."

**Examiner:** *How did you test this?*
> "73 automated tests — I can run them now if you like." [Run `flutter test`.] "They cover both detectors, the data model, the settings and the box geometry, plus widget tests. Face detection itself needs a real face, so I tested that manually on this phone."

**Examiner:** *What is the accuracy?*
> "I did not collect a labelled test set, so I will not quote a number — that would be a guess. What I can tell you is that the five shapes are distinguishable in normal lighting, and because faces and lighting differ, I made the three thresholds adjustable in Settings."

**Examiner:** *What would you improve?*
> "First, per-user calibration — a short step where you hold each shape once so the app tunes to your face. Second, a proper accuracy study with labelled clips and a confusion matrix. And saving a flag so onboarding only shows on the first launch."

---

**بالعربي — نصيحة أخيرة:** لو سؤال ما تعرفش إجابته، ما تخترعش رقم ولا معلومة. قول: "أنا ما قستش الحاجة دي، بس أقدر أقولك الكود بيتصرّف إزاي في الحالة دي" — وبعدين اشرح اللي إنت متأكد منه. الصراحة دي نقطة قوة مش ضعف.
