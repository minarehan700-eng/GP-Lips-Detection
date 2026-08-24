# VIVA_CODE_GUIDE — Lips Offline

**A complete guide to defending this project's code.**
Every section is written in simple English first, then summarised in Arabic.

> **How to use this file**
> 1. Read **Part 1–3** once, slowly, to understand the whole app.
> 2. Study the **ten code sections** in Part 8 — those are what examiners ask about.
> 3. The night before, read only **Part 10 (Quick Revision Sheet)**.

---

## Contents

| Part | Title |
|------|-------|
| 1 | Project Overview |
| 2 | Project Structure — every folder and file |
| 3 | Application Execution Flow |
| 4 | Important Classes and Functions |
| 5 | Code Walkthroughs (feature by feature) |
| 6 | Expected Discussion Questions and Model Answers |
| 7 | Presentation Scripts (60 seconds / 3 minutes / 10 minutes) |
| 8 | The Ten Code Sections You Must Study |
| 9 | Honest Limitations |
| 10 | Quick Revision Sheet |

---

# Part 1 — Project Overview

## What the project does

**Lips Offline** is an Android/iOS mobile app. It uses the phone's **front camera** to watch the user's mouth in real time and answers two questions:

1. **Are you lipsing?** — Yes or No. ("Lipsing" means mouthing words silently, without voice.)
2. **Which mouth shape are you making?** — one of five practice letters, **A, B, C, D, E**, with a confidence percentage.

The user can tap a letter as a **practice target**. When their mouth shape matches that target, the app shows **"Matched!"**

Everything runs **on the phone**. No internet, no server, no video ever leaves the device.

> **بالعربي:** تطبيق موبايل يستخدم الكاميرا الأمامية ليراقب الفم مباشرةً. يجاوب على سؤالين: هل المستخدم بيحرّك شفايفه (lipsing)؟ وأي شكل فم من خمسة أشكال (A–E) بيعمله دلوقتي؟ يقدر يختار حرف كهدف للتدريب ويشوف كلمة "Matched!" لما يظبطه. كل حاجة بتشتغل على الموبايل نفسه من غير إنترنت ومن غير ما الفيديو يخرج من الجهاز.

## The problem it solves

Many sign languages use **mouthing** alongside hand signs to tell similar signs apart. A learner practising alone cannot see their own mouth clearly, and has no way of knowing whether their mouth shape is right. This app gives **instant visual feedback** on the phone.

> **بالعربي:** لغات الإشارة بتستخدم حركة الشفايف مع إشارات اليد عشان تفرّق بين إشارات متشابهة. الطالب اللي بيتدرب لوحده مش شايف فمه ولا عارف إذا كان الشكل صح. التطبيق بيديله ردّ فعل فوري على الشاشة.

## Main technologies

| Layer | Technology | Why it was chosen |
|-------|-----------|-------------------|
| App framework | **Flutter (Dart)** | One codebase runs on both Android and iOS |
| Camera | **`camera` plugin** | Gives a live stream of frames, not just photos |
| Image conversion | **`image` package** | Converts raw camera frames into JPEG |
| Face / mouth AI | **MediaPipe Face Landmarker** | A ready-made, pre-trained model that runs on-device |
| Android bridge | **Kotlin** + MediaPipe Tasks Vision `0.10.29` | MediaPipe is a native library, so it needs native code |
| iOS bridge | **Swift** + MediaPipeTasksVision `0.10.21` | The same pipeline on iOS |
| Saved settings | **`shared_preferences`** | Simple key–value storage on the phone |
| Animations | **`flutter_animate`** | Short, readable fade and scale animations |

> **بالعربي:** فلاتر عشان كود واحد يشتغل على أندرويد و iOS. MediaPipe عشان هو موديل جاهز ومدرَّب بيشتغل على الجهاز نفسه. كوتلن وسويفت عشان MediaPipe مكتبة native ولازم كود native يشغّلها. shared_preferences عشان نحفظ إعدادات المستخدم.

## Main inputs and outputs

| | |
|---|---|
| **Input** | Live frames from the front camera + three threshold settings the user can adjust |
| **Output** | Face detected Yes/No · Lipsing Yes/No · Letter A–E + confidence % · six mouth measurements · a green box drawn around the mouth |

## The complete workflow in simple steps

1. The app opens → **splash** (2.2 s) → **onboarding** (3 pages) → **home**.
2. The home screen loads the saved settings, loads the MediaPipe model, and opens the front camera.
3. The camera streams frames. The app analyses **one frame every 150 ms** (about 6–7 per second).
4. Each chosen frame is converted to **JPEG** and sent to **native code** (Kotlin on Android, Swift on iOS).
5. MediaPipe finds the face and returns **blendshapes** (numbers describing the mouth) and a **mouth box**.
6. **`LipsingDetector`** decides Yes/No from how open and how *moving* the mouth is.
7. **`LipLetterDetector`** picks a letter A–E using a fixed priority tree.
8. The home screen shows everything, and draws the mouth box on the preview.

> **بالعربي:** التطبيق يفتح → شاشة البداية → ٣ صفحات تعريف → الشاشة الرئيسية. الكاميرا بتشتغل، وكل ١٥٠ ملي ثانية بناخد صورة واحدة، نحوّلها JPEG، نبعتها للكود الـ native اللي فيه MediaPipe، يرجّعلنا أرقام الفم، وبعدين كلاسين بيحوّلوا الأرقام دي لإجابة Yes/No وحرف من A لـ E.

---

# Part 2 — Project Structure

> **Focus column:** ⭐⭐⭐ = study deeply, examiners will ask. ⭐⭐ = know what it does. ⭐ = just recognise the name.

## `lib/` — all the Dart code

| Path | What it contains | Feature it controls | Focus |
|------|------------------|---------------------|-------|
| `main.dart` | App entry point, root `MaterialApp`, dark theme, first screen | Starting the app | ⭐⭐ |
| **`domain/`** | **The shared data model** | | |
| `domain/face_lips_result.dart` | `FaceLipsResult` — everything known about the mouth in ONE frame | Carries data between every stage | ⭐⭐⭐ |
| **`application/`** | **The business logic — the "brain"** | | |
| `application/lipsing_detector.dart` | `LipsingDetector` — the Yes/No decision | Lipsing detection | ⭐⭐⭐ |
| `application/lip_letter_detector.dart` | `LipLetterDetector` — the A–E rule tree | Letter classification | ⭐⭐⭐ |
| `application/lips_camera_session.dart` | `LipsCameraSession` — runs the whole pipeline | Camera + frame processing | ⭐⭐⭐ |
| **`infrastructure/`** | **Talking to the outside world** | | |
| `infrastructure/camera_frame_encoder.dart` | `CameraFrameEncoder` — YUV/BGRA → JPEG | Frame conversion | ⭐⭐ |
| `infrastructure/mediapipe_face_landmark_extractor.dart` | The Dart side of the method channel | Flutter ↔ native bridge | ⭐⭐⭐ |
| **`core/`** | **Settings and app-wide values** | | |
| `core/detector_settings.dart` | `DetectorSettings` — load/save the three thresholds | Settings persistence | ⭐⭐ |
| `core/app_theme.dart` | All colours and the Material theme | App appearance | ⭐ |
| `core/app_navigation.dart` | The shared fade page transition | Screen changes | ⭐ |
| **`screens/`** | **Full pages the user sees** | | |
| `screens/splash_screen.dart` | Animated logo, 2.2 s, then onboarding | Splash | ⭐ |
| `screens/onboarding/` | Three intro pages + their text | Onboarding | ⭐ |
| `screens/home_screen.dart` | The main screen — loading / error / running | Main UI | ⭐⭐⭐ |
| `screens/settings_screen.dart` | Three sliders, Save, Reset | Settings UI | ⭐⭐ |
| **`widgets/`** | **Reusable pieces of UI** | | |
| `widgets/lips_camera_preview.dart` | `MouthBoxPainter` + the camera preview | Drawing the mouth box | ⭐⭐⭐ |
| `widgets/lips_detection_panels.dart` | Letter panel + mouth metrics panel | Result display | ⭐⭐ |
| `widgets/detection_ui.dart` | Status card, letter chip, metric tile | Small UI parts | ⭐ |
| `widgets/glass_card.dart` | The frosted-glass card look | Styling | ⭐ |
| `widgets/gradient_background.dart` | The blue → purple background | Styling | ⭐ |
| `widgets/animated_brand_text.dart` | The animated "Lips" wordmark | Splash branding | ⭐ |

## `android/` and `ios/` — the native side

| Path | What it contains | Focus |
|------|------------------|-------|
| `android/.../FaceLandmarkerBridge.kt` | Runs MediaPipe on Android; extracts blendshapes and the mouth box | ⭐⭐⭐ |
| `android/.../MainActivity.kt` | Receives method-channel calls, manages threading | ⭐⭐⭐ |
| `android/app/src/main/assets/face_landmarker.task` | **The pre-trained model (3.7 MB)** — this is what makes it offline | ⭐⭐ |
| `android/app/build.gradle.kts` | Android build settings, MediaPipe dependency, minify disabled | ⭐⭐ |
| `ios/Runner/FaceLandmarkerBridge.swift` | The same job on iOS | ⭐ |
| `ios/Runner/AppDelegate.swift` | The iOS method-channel handler | ⭐ |

## `test/` — the automated tests

| Path | What it tests | Focus |
|------|---------------|-------|
| `test/lipsing_detector_test.dart` | The Yes/No decision and the anti-flicker wait | ⭐⭐⭐ |
| `test/lip_letter_detector_test.dart` | One test per letter + the priority order | ⭐⭐⭐ |
| `test/mouth_box_painter_test.dart` | Pixel mapping, mirroring, rotation | ⭐⭐ |
| `test/face_lips_result_test.dart` | The data model | ⭐ |
| `test/detector_settings_test.dart` | Save and load settings | ⭐ |
| `test/widget_test.dart` | The app starts and reaches onboarding | ⭐ |
| `test/onboarding_screen_test.dart` | Page navigation | ⭐ |
| `test/settings_screen_test.dart` | The save workflow | ⭐ |
| `test/detected_letter_panel_test.dart` | The "Matched!" practice workflow | ⭐⭐ |
| `test/helpers/fake_frames.dart` | Builds fake frames so tests stay short | ⭐ |

> **بالعربي:** المشروع مقسّم لطبقات. `domain` فيه شكل البيانات. `application` فيه المنطق (العقل). `infrastructure` بيكلّم الكاميرا والكود الـ native. `core` فيه الإعدادات والألوان. `screens` و `widgets` هما الواجهة. الجزء الـ native في `android/` و `ios/` هو اللي بيشغّل MediaPipe فعلياً.

### Why these layer names?

An examiner may ask why the folders are called `domain`, `application` and `infrastructure`. The honest answer:

> "It is a **layered architecture**. `domain` holds the data with no dependencies on anything. `application` holds the rules — my detectors — and depends only on `domain`. `infrastructure` holds the code that talks to the outside world (the camera, the native model, the phone's storage). The screens depend on the layers below, but the layers below never depend on the screens. That means I can unit-test my detection logic with no camera and no phone — which is exactly what my 73 tests do."

> **بالعربي:** التقسيم ده اسمه Layered Architecture. الطبقة الجوّانية (`domain`) مش معتمدة على حاجة، والمنطق (`application`) معتمد عليها بس، والطبقة اللي بتكلّم الكاميرا والـ native (`infrastructure`) منفصلة. الفايدة العملية: أقدر أختبر منطق الكشف من غير كاميرا ومن غير موبايل.

---

# Part 3 — Application Execution Flow

## Which file starts the application?

**`lib/main.dart`** → the `main()` function.

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LipsOfflineApp());
}
```

**Why `ensureInitialized()`?** Because the app talks to the platform — the camera, saved settings, and the MediaPipe method channel. That machinery must be ready *before* the first widget is built. Without this line the app can crash when a plugin is used too early.

## Step by step, from launch to result

| # | What happens | Where |
|---|--------------|-------|
| 1 | `main()` runs, Flutter is initialised | `main.dart` |
| 2 | `LipsOfflineApp` builds a dark `MaterialApp` whose home is `SplashScreen` | `main.dart` |
| 3 | Splash shows the animated logo, and a `Timer` waits 2.2 s | `splash_screen.dart` |
| 4 | Splash is **replaced** by `OnboardingScreen` (replaced, so Back cannot return to it) | `app_navigation.dart` |
| 5 | The user reads 3 pages, taps **Get Started** (or **Skip**) | `onboarding_screen.dart` |
| 6 | `HomeScreen` is created. Camera start-up is **deferred to after the first frame** so the loading spinner appears immediately | `home_screen.dart` → `_scheduleSetup()` |
| 7 | `LipsCameraSession.initialize()` runs four steps: load settings → load model → find front camera → start the frame stream | `lips_camera_session.dart` |
| 8 | Every camera frame calls `_onFrame()`. Most are **skipped** (busy, or less than 150 ms since the last one) | `lips_camera_session.dart` |
| 9 | An accepted frame → JPEG → method channel → native MediaPipe | `camera_frame_encoder.dart`, `mediapipe_face_landmark_extractor.dart` |
| 10 | Native code returns a map of numbers; it is parsed into a `FaceLipsResult` | `mediapipe_face_landmark_extractor.dart` |
| 11 | `LipsingDetector.update()` adds the `isLipsing` flag | `lipsing_detector.dart` |
| 12 | `LipLetterDetector.update()` adds `detectedLetter` + `letterConfidence` | `lip_letter_detector.dart` |
| 13 | `onUpdate()` is called → `setState()` → the screen redraws | `home_screen.dart` |
| 14 | The mouth box is drawn on top of the preview | `lips_camera_preview.dart` |

## Where is the result created, and where is it shown?

- **Created** in `LipsCameraSession._onFrame()`, in the line `result = _lipLetterDetector.update(withLipsing);`
- **Shown** in `HomeScreen._buildBody()`, which reads `_session.result` and passes it to the panels.

> **بالعربي:** التطبيق يبدأ من `main.dart`. بعدين splash → onboarding → home. الشاشة الرئيسية بتشغّل `LipsCameraSession` اللي بيعمل ٤ خطوات: يحمّل الإعدادات، يحمّل الموديل، يفتح الكاميرا الأمامية، ويبدأ ياخد صور. كل صورة مقبولة بتتحوّل JPEG وتروح للكود الـ native، وبعدين الكلاسين بيحوّلوا النتيجة لإجابة، والشاشة بتترسم من جديد.

---

# Part 4 — Important Classes and Functions

---

## 4.1 `FaceLipsResult`

| | |
|---|---|
| **File** | `lib/domain/face_lips_result.dart` |
| **Purpose** | Hold everything known about the mouth in **one** frame |
| **Inputs** | Values from MediaPipe, then values added by each detector |
| **Outputs** | An immutable object; `copyWith()` returns a modified **copy** |

### Step by step

1. Created by `MediaPipeFaceLandmarkExtractor` with the raw MediaPipe numbers.
2. `LipsingDetector` returns a copy with `isLipsing` filled in.
3. `LipLetterDetector` returns a copy with `detectedLetter` and `letterConfidence` filled in.
4. The screen reads the finished object.

### Why this approach?

Passing **one object** through the pipeline is much easier to follow than passing fifteen separate numbers. Making it **immutable** (never edited in place) means an earlier stage's values can always be trusted — a later stage cannot secretly change them.

### The hardest part

```dart
detectedLetter: clearDetectedLetter ? null : (detectedLetter ?? this.detectedLetter),
```

**Say this to the examiner:** *"In `copyWith`, passing `null` normally means 'don't change this field'. But sometimes I genuinely need to erase the letter — when the face leaves the camera. I cannot express that with `null`, so I added a separate `clearDetectedLetter` flag. If it is true, the letter is erased on purpose."*

> **بالعربي:** الكلاس ده بيشيل كل معلومات الفم في فريم واحد. مش بيتعدّل، لكن كل مرحلة بترجّع نسخة جديدة منه. الحتة الصعبة: في `copyWith` لما أبعت `null` معناها "ما تغيّرش"، فمحتاج flag منفصل اسمه `clearDetectedLetter` عشان أقدر أمسح الحرف بشكل مقصود.

**Likely questions**

- *Q: Why not just change the values directly?*
  A: Because each stage would then be able to overwrite the previous stage's work by accident. Copies make the flow one-directional and easy to trace.
- *Q: What is `hasMouthBox` for?*
  A: It answers "is there a real, drawable mouth box?". It needs both a detected face **and** a box bigger than 1% of the frame — a collapsed box would draw a tiny rectangle in the corner.

---

## 4.2 `LipsingDetector.update()` ⭐ most important

| | |
|---|---|
| **File** | `lib/application/lipsing_detector.dart` |
| **Purpose** | Turn per-frame mouth numbers into a **steady** Yes/No answer |
| **Input** | `FaceLipsResult raw` — one frame |
| **Output** | A copy of that frame with a smoothed `isLipsing` |
| **Side effects** | Updates the frame history and the streak counters |

### Step by step

1. **No face?** Clear the history and fade the answer to No after 3 missing frames.
2. **Remember** this frame's mouth shape (keeping the last 8).
3. Decide if this single frame looks **active**:
   - `mouthIsOpenEnough` — mouth open above the threshold (default `0.25`), **OR**
   - `mouthIsMovingEnough` — the average change between frames is above `0.035`.
4. **Count the vote.** Only flip the shown answer once **3 frames in a row** agree — except a very wide-open mouth (above `0.25 × 1.4 = 0.35`), which switches to Yes immediately.

### Why this approach?

A single frame is not enough. Someone can lip a word with a barely-open mouth (caught by *movement*) or hold a wide "aah" almost still (caught by *openness*). Either sign alone is enough, so the two tests are combined with **OR**.

The 3-frame wait is called **hysteresis**. Without it the label would flash between Yes and No several times a second and be unreadable.

### The hardest part

```dart
totalChange += openChange;
totalChange += puckerChange * puckerMotionWeight;   // 0.5
totalChange += smileChange * smileMotionWeight;     // 0.35
```

**Say this to the examiner:** *"I measure movement by adding up how much three mouth values changed between frames. They do not move by the same amount — the jaw swings widest, so it counts fully; the pucker moves about half as much, and the smile least. The weights 1.0, 0.5 and 0.35 balance them so one slow-moving value cannot dominate."*

> **بالعربي:** الكلاس ده بيحوّل أرقام كل فريم لإجابة ثابتة Yes/No. بيقول "نشط" لو الفم مفتوح كفاية **أو** بيتحرّك كفاية. وبعدين مش بيغيّر الإجابة غير لما ٣ فريمات ورا بعض يتفقوا — ده اسمه hysteresis وبيمنع الشاشة من الرفرفة. الأوزان (١، ٠.٥، ٠.٣٥) عشان الفك بيتحرّك أكتر من الشفايف والابتسامة.

**Likely questions**

- *Q: What is hysteresis and why do you need it?*
  A: It means requiring several agreeing readings before changing state. Without it, a value sitting right on the threshold makes the label flicker on and off continuously.
- *Q: Why does a very wide-open mouth skip the wait?*
  A: Responsiveness. If the answer is obvious there is no reason to make the user wait ~450 ms.
- *Q: What happens if the face disappears for one frame?*
  A: Nothing visible. The answer only fades after 3 missing frames, so one dropped frame does not blank the screen.

---

## 4.3 `LipLetterDetector._classify()` ⭐ most important

| | |
|---|---|
| **File** | `lib/application/lip_letter_detector.dart` |
| **Purpose** | Decide which letter A–E a mouth shape is |
| **Input** | `_MouthFeatures` — the **median** of the last 5 frames |
| **Output** | `_LetterMatch` (letter + confidence), or `null` if nothing matched |

### The priority tree: **E → C → B → A → D**

| Order | Letter | Rule (in words) | Threshold |
|-------|--------|-----------------|-----------|
| 1 | **E** | Smiling or stretched, and not beaten by a round shape | `wideness >= 0.28` |
| 2 | **C** | Lips rounded or funnelled | `roundness >= 0.22` |
| 3 | **B** | Barely open, AND (lips pressed OR practically shut) | `open <= 0.14` |
| 4 | **A** | Wide open, and not smiling, and not rounded | `open >= 0.45` |
| 5 | **D** | Slightly open — the fallback | `0.16 <= open <= 0.44` |

### Why an order at all?

**Because real mouth shapes overlap.** A smile is also slightly open. If D were asked first, every smile would be reported as D. Asking the most *distinctive* shapes first (smile, round) and leaving the vaguest (slightly open) last means the specific rules win.

### The hardest part

```dart
final bool smilingClearly = wideness >= strongSmileThreshold;
final bool smileBeatsRound = wideness >= roundness - smileOverRoundAllowance;
if (smilingClearly && smileBeatsRound) { ... }
```

**Say this to the examiner:** *"A mouth can be a bit smiley and strongly puckered at the same time. The first test asks 'is there a real smile?'. The second asks 'is the smile at least as strong as the roundness?' — with a small 0.05 allowance so a smile that is only marginally behind still wins. Without the second test, an 'oo' shape with a slight smile would be misread as E instead of C."*

### The second hardest part — the D score

```dart
final double distanceFromIdeal = (f.open - slightOpenIdeal).abs();   // ideal = 0.30
final double shapeMatch = 1.0 - (distanceFromIdeal / slightOpenTolerance).clamp(0.0, 1.0);
final double score = _clamp01(shapeMatch * 0.85 + f.open * 0.15);
```

**Say this:** *"D has no strong signal of its own — it is 'a bit open, nothing special'. So I score it by how close the opening is to the typical D size, 0.30. It scores 1.0 exactly at 0.30 and falls to 0 once it drifts 0.14 away. Then 85% of the final score comes from that shape match and 15% from the raw openness."*

> **بالعربي:** الترتيب E ثم C ثم B ثم A ثم D مهم جداً لأن أشكال الفم بتتداخل. الابتسامة كمان فمها مفتوح شوية، فلو سألنا عن D الأول كل ابتسامة هتطلع D. فبنسأل عن الأشكال الواضحة الأول والغامضة في الآخر. حرف D ملوش علامة مميزة، فبنحسب درجته بقد إيه فتحة الفم قريبة من ٠.٣٠.

**Likely questions**

- *Q: Why rules instead of training a neural network?*
  A: I do not have a labelled dataset of Arabic-signer mouth shapes. MediaPipe already gives me meaningful, normalised measurements, so simple rules on top are transparent, need no training data, run instantly, and — importantly — I can **explain every decision**.
- *Q: Why the median of 5 frames and not the average?*
  A: The median ignores a single extreme reading. If four frames say "closed" and one says "wide open", the median still says closed; an average would be dragged upward.
- *Q: What happens if no rule matches?*
  A: `_classify` returns `null` and the screen shows a dash `—`. That is deliberate: saying nothing is better than guessing.
- *Q: Can a rule match but still be rejected?*
  A: Yes. If the shape matches but the score is below `minScore`, the code falls through and the **next** rule gets its turn.

---

## 4.4 `LipsCameraSession._onFrame()`

| | |
|---|---|
| **File** | `lib/application/lips_camera_session.dart` |
| **Purpose** | Run the full pipeline for one camera frame |
| **Input** | `CameraImage image`, and an `onUpdate` callback |
| **Output** | None; it replaces `result` and calls `onUpdate()` |

### Step by step

1. **Skip** if the previous frame is still being processed (`_isProcessing`).
2. **Skip** if less than **150 ms** has passed since the last accepted frame.
3. Convert the frame to **JPEG** (quality 92).
4. Send it to native MediaPipe.
5. Run `LipsingDetector`, then `LipLetterDetector` **on its output**.
6. Call `onUpdate()` so the screen redraws.

### The hardest part — the two guards

```dart
if (_isProcessing) return;
...
if (millisecondsSinceLastFrame < minMillisecondsBetweenFrames) return;
...
try { ... } finally { _isProcessing = false; }
```

**Say this to the examiner:** *"The camera produces frames far faster than MediaPipe can analyse them — around 30 per second versus about 7. Two guards protect the app. The first stops a second frame starting while one is still being analysed. The second enforces a 150 ms gap, which saves battery. The `finally` block is essential: if analysis throws an error, the flag must still be cleared, otherwise it would stay `true` forever and the app would freeze with no further detection."*

> **بالعربي:** الدالة دي بتشغّل الـ pipeline كله لفريم واحد. فيها حارسين: الأول بيمنع إن فريم جديد يبدأ والقديم لسه شغال، والتاني بيفرض ١٥٠ ملي ثانية بين الفريمات عشان البطارية. الـ `finally` مهمة جداً — لو حصل خطأ لازم الـ flag يترجع `false`، وإلا التطبيق هيقف عن الكشف نهائياً.

**Likely questions**

- *Q: Why 150 ms and not every frame?*
  A: A mouth shape does not meaningfully change in 33 ms. Analysing every frame would drain the battery and cause stutter without improving accuracy.
- *Q: What would happen if you removed the `finally`?*
  A: On the first exception `_isProcessing` would stay `true` forever. Every future frame would hit the first guard and return immediately — detection would silently stop.

---

## 4.5 `MediaPipeFaceLandmarkExtractor` — the bridge

| | |
|---|---|
| **File** | `lib/infrastructure/mediapipe_face_landmark_extractor.dart` |
| **Purpose** | The only place in Dart that knows about native code |
| **Channel** | `'lips/offline/face'` — must match the native side **exactly** |

### The two methods

| Method | What it does |
|--------|--------------|
| `initializeFaceLandmarker` | Loads `face_landmarker.task` on the native side |
| `processFaceFrame` | Sends `{bytes, width, height, rotation}`, returns the mouth numbers |

### Why this approach?

MediaPipe has no Dart version. Flutter's **method channel** is the standard way for Dart to call platform code: Dart sends a method name plus arguments, native code replies with a map. Keeping it in one class means the rest of the app works with a plain `FaceLipsResult` and never sees a channel.

### The hardest part

```dart
mouthOpen: _readNumber(response, 'mouthOpen'),
// static double _readNumber(...) => (response[key] as num?)?.toDouble() ?? 0;
```

**Say this:** *"Every value is read defensively. The map crosses a platform boundary, so a key could be missing, or a value could arrive as an integer where I expect a double. Reading it as `num?` and defaulting to 0 means a malformed reply can never crash the app — it just looks like 'no face this frame'."*

> **بالعربي:** الكلاس ده هو المكان الوحيد اللي بيعرف حاجة عن الكود الـ native. بيستخدم MethodChannel: Dart بيبعت اسم دالة ومعاها بيانات، والـ native بيرجّع map. كل قيمة بتتقرا بحذر (`as num?` وبعدين `?? 0`) عشان لو حصل أي مشكلة التطبيق ما يقعش.

---

## 4.6 `MouthBoxPainter.computeMouthRect()` — the hardest maths

| | |
|---|---|
| **File** | `lib/widgets/lips_camera_preview.dart` |
| **Purpose** | Convert MediaPipe's 0.0–1.0 mouth position into screen pixels |
| **Input** | Four mouth fractions, the frame size, front-camera flag, preview size |
| **Output** | A `Rect` in pixels |

### Why is this hard?

Two things get in the way:

1. **Rotation.** Many phone cameras always deliver a **landscape** image even when the phone is held upright. Then X and Y must be swapped.
2. **Mirroring.** The front camera shows a **mirror** image. Without flipping X, the box would move the wrong way when the user moves their head.

### Step by step

1. Decide whether the axes must be swapped (landscape frame + portrait preview).
2. Map both mouth corners into pixels, applying rotation and mirroring.
3. Build a rectangle from them, taking min/max because rotation can reorder the corners.
4. If the box came out **taller than wide**, turn it on its side around its centre — a mouth never stands upright.
5. Clamp the height to between **22%** and **48%** of the width, so the box always looks like a mouth.

### The hardest lines

```dart
if (swapAxes) {
  final double originalX = x;
  x = y;
  y = 1.0 - originalX;
}
if (isFrontCamera) {
  x = 1.0 - x;
}
```

**Say this to the examiner:** *"This is a quarter-turn rotation. The old Y becomes the new X, and the old X becomes the new Y — but measured from the other end, which is why it is `1.0 - x`. I have to save the old X in a variable first, because the line above already overwrote it. The second block mirrors the image for the front camera: `1.0 - x` flips left and right."*

> **بالعربي:** دي أصعب حتة حسابية في المشروع. فيها مشكلتين: الكاميرا بتدّي صورة أفقية والموبايل واقف، فلازم نبدّل المحاور؛ والكاميرا الأمامية بتدّي صورة مقلوبة زي المراية، فلازم نعكس X. لازم أحفظ X القديمة في متغير الأول لأن السطر اللي فوق غيّرها بالفعل.

**Likely questions**

- *Q: How did you test this? It needs a camera.*
  A: I did not test it through the camera. I pulled the geometry out of the drawing code into a plain function that takes numbers and returns a rectangle. `test/mouth_box_painter_test.dart` then checks pixel mapping, mirroring and rotation directly, plus two properties over 6,000 random inputs.
- *Q: Why force the box to be wider than tall?*
  A: A mouth always is. After rotation the maths can produce an upright box, which would look obviously wrong on screen.

---

# Part 5 — Code Walkthroughs

## 5.1 Starting the application

```
main() → ensureInitialized() → runApp(LipsOfflineApp)
       → MaterialApp(theme: AppTheme.dark(), home: SplashScreen)
       → SplashScreen starts a 2.2 s Timer
       → pushReplacement(OnboardingScreen)   ← "replacement" so Back can't go back
       → user taps Get Started
       → pushReplacement(HomeScreen)
```

## 5.2 Loading the model

```
HomeScreen.initState()
  → _scheduleSetup()  (waits for the first frame to be drawn)
  → LipsCameraSession.initialize()
      1. initPhase = 'Loading settings...'        → DetectorSettings.load()
      2. initPhase = 'Loading face landmarker...' → _extractor.initialize()
             → MethodChannel 'lips/offline/face'.invokeMethod('initializeFaceLandmarker')
             → Kotlin: MainActivity posts to the MAIN thread  ← Android 15/16 crash fix
             → FaceLandmarkerBridge.initialize() reads face_landmarker.task from assets
      3. initPhase = 'Starting camera...'         → _pickFrontCamera(), _openCamera()
      4. controller.startImageStream(_onFrame)
      5. initPhase = 'Ready'
```

**If the model file is missing**, the native side throws, the Dart side turns it into a readable message, and `HomeScreen` shows `_ErrorView` with a **Try Again** button.

## 5.3 Processing one image (the main loop)

```
camera frame
  → _onFrame()   guard 1: busy?   guard 2: < 150 ms?
  → CameraFrameEncoder.encodeToJpeg(image, quality: 92)
        YUV420 → RGB pixel by pixel (BT.601) → JPEG
  → extractor.processFrame(bytes, width, height, rotation: 0)
        → native MediaPipe → 478 face points + ~52 blendshapes
        → keeps 6 mouth blendshapes + 6 lip landmarks → mouth box
  → FaceLipsResult (faceDetected, mouthOpen, pucker, smile, close, funnel, stretch, box)
  → LipsingDetector.update()      → adds isLipsing
  → LipLetterDetector.update()    → adds detectedLetter + letterConfidence
  → onUpdate() → setState() → screen redraws
```

## 5.4 Displaying the result

`HomeScreen._buildBody()` chooses one of three views:

| Condition | View |
|-----------|------|
| Still starting, no camera, no error | `_LoadingView` with the current `initPhase` |
| `_session.error != null` | `_ErrorView` with the message and **Try Again** |
| Otherwise | Preview + status cards + letter panel + metrics |

## 5.5 The practice-target workflow

```
user taps chip "C"
  → LetterChip.onTap → HomeScreen._toggleTargetLetter('C')
  → setState: _targetLetter = 'C'   (tapping 'C' again clears it)
  → DetectedLetterPanel receives targetLetter: 'C'
  → matched = targetLetter != null && detectedLetter == targetLetter
  → if matched → "Matched!" in green
```

## 5.6 Saving settings

```
Settings screen: user drags a slider
  → setState → _settings = _settings.copyWith(...)   (memory only)
user taps "Save Settings"
  → DetectorSettings.save() → SharedPreferences.setDouble × 3
  → SnackBar "Settings saved"
user taps Back
  → HomeScreen._openSettings() resumes after the await
  → _session.applyDetectorSettings()  → rebuilds BOTH detectors with the new values
```

**Note:** the detectors are **recreated**, not edited, because their thresholds are `final`. A fresh detector also clears stale frame history — which is correct, since the old history was judged by different thresholds.

## 5.7 Handling an error

```
Camera permission denied
  → camera plugin throws PlatformException
  → caught in LipsCameraSession.initialize()
  → error = e.message
  → onUpdate() → HomeScreen shows _ErrorView
  → user taps "Try Again" → _retrySetup() → session.reset() → initialize() again
```

There are **three** levels of error handling:

| Level | Behaviour | Why |
|-------|-----------|-----|
| One bad frame | Return "no face", carry on | A single frame must never interrupt a live camera |
| Start-up failure | Show `_ErrorView` + Try Again | The user can fix permissions and retry |
| Malformed native reply | Default every value to 0 | A platform-boundary bug must not crash the app |

> **بالعربي:** معالجة الأخطاء على ٣ مستويات: فريم واحد غلط → نتجاهله ونكمّل؛ فشل في التشغيل → شاشة خطأ فيها زرار "حاول تاني"؛ رد ناقص من الـ native → كل القيم تبقى صفر. الفكرة إن التطبيق ما يقعش أبداً بسبب فريم واحد.

---

# Part 6 — Expected Discussion Questions and Model Answers

## About the technology choices

**Q: Why Flutter?**
> One codebase gives me both Android and iOS. It has a strong camera plugin, and its method-channel system made it straightforward to call the native MediaPipe library. It also has a built-in test framework, which is how I have 73 automated tests.

**Q: Why MediaPipe and not your own trained model?**
> Training a face model needs a large labelled dataset, a lot of computing power, and time I did not have. MediaPipe Face Landmarker is already trained on a huge dataset, runs on the phone, and gives me 478 face points and around 52 blendshapes. My contribution is the layer on top: turning those numbers into lipsing detection and viseme letters, with smoothing so the output is stable.

**Q: Why does the app need native Kotlin and Swift code?**
> MediaPipe is a native library — there is no Dart version. So the model has to run natively, and Flutter talks to it through a method channel.

**Q: Why is the app offline?**
> Two reasons. **Privacy** — camera video of a person's face is sensitive and never leaves the phone. **Practicality** — a learner should be able to practise anywhere, without needing a connection, and there is no server latency.

> **بالعربي:** فلاتر عشان كود واحد للمنصتين. MediaPipe عشان تدريب موديل بنفسي محتاج داتا كبيرة ووقت مش متاح، والموديل ده جاهز ودقيق وبيشتغل على الجهاز. مساهمتي هي الطبقة اللي فوقه. والتطبيق offline عشان الخصوصية وعشان يشتغل في أي مكان.

## About the architecture

**Q: Why did you split the code into layers?**
> So that the detection logic does not depend on the camera or on Flutter. That is not just theory — it is why I can unit-test the detectors with fake frames and no device at all.

**Q: What is `LipsCameraSession` for? Why not put it in the screen?**
> If it were in the screen, the screen would be doing camera management, throttling, native calls and drawing all at once. Separating it means `HomeScreen` only decides *what to show*, and the session only decides *what the answer is*.

**Q: How does data move through the app?**
> In one direction. Camera → encoder → native bridge → `FaceLipsResult` → lipsing detector → letter detector → screen. Each stage adds information and never changes what an earlier stage produced.

## About the algorithm

**Q: What is a blendshape?**
> A number from 0.0 to 1.0 describing one facial movement. MediaPipe gives around 52 of them. I use six mouth ones: `jawOpen`, `mouthPucker`, `mouthClose`, `mouthFunnel`, plus smile and stretch, which are reported separately for each side of the face and averaged.

**Q: What is a viseme?**
> A mouth shape linked to a speech sound. Several different sounds can look identical on the lips — for example "p", "b" and "m" all look like closed lips. That is exactly why lip reading alone is ambiguous, and why my app maps to five practice shapes rather than claiming to recognise words.

**Q: Why only five letters?**
> They are five clearly distinguishable mouth shapes. Because different sounds share the same shape, adding more classes would mean the classes overlapped and accuracy would fall. Five gives honest, reliable feedback.

**Q: How do you stop the display from flickering?**
> Three separate mechanisms. First, throttling — only about 7 frames per second are analysed. Second, the median of the last 5 frames, so one bad reading is out-voted. Third, hysteresis — a new answer must win several frames in a row before it is displayed.

> **بالعربي:** الـ blendshape رقم من ٠ لـ ١ بيوصف حركة واحدة في الوش. الـ viseme شكل فم مرتبط بصوت — وفيه أصوات كتير شكلها واحد (زي p و b و m)، وده سبب إن قراءة الشفايف لوحدها مش كافية. ٥ حروف بس عشان أشكال أكتر هتتداخل وتقلّل الدقة. ومنع الرفرفة بـ٣ طرق: تقليل عدد الفريمات، الوسيط لآخر ٥ فريمات، والـ hysteresis.

## About validation and errors

**Q: How do you validate input?**
> At several points. The extractor refuses empty bytes or a zero width/height before calling native code. The encoder returns `null` for a frame format it does not understand. Every value from the native side is read as `num?` with a default of 0. Every feature is clamped to 0.0–1.0 before the rules run. And the mouth width is floored at 0.01 so a division can never be by zero.

**Q: What happens if `face_landmarker.task` is missing?**
> Native initialisation throws. The Dart side catches it and produces a message that names the exact folder the file belongs in. The home screen shows that message with a Try Again button. The app does not crash.

**Q: What if the user denies camera permission?**
> The camera plugin throws a `PlatformException`, which is caught in `initialize()` and shown in the error view.

## About testing

**Q: How did you test this project?**
> Three ways. **73 automated tests** — unit tests for the detectors, the data model, the settings and the geometry, plus widget tests for onboarding, settings and the practice panel. **Static analysis** — `flutter analyze` reports zero issues. **Manual testing on a real device**, because face detection needs a real face and a real camera.

**Q: How can you test detection without a camera?**
> The detectors take a plain `FaceLipsResult`, not a camera image. So a test can build a fake frame that says "mouth 90% open, no smile" and check that the answer is A. That is exactly why the logic is separated from the camera.

**Q: How do you know the refactoring did not break anything?**
> I wrote a differential test: it held a copy of the original algorithms and ran the same randomised frame sequences through both the old and the new code. It compared 200 runs × 120 frames for each detector, and 20,000 random cases for the geometry. Every output matched exactly — including the floating-point digits.

> **بالعربي:** الاختبار على ٣ مستويات: ٧٣ اختبار أوتوماتيكي، وتحليل ساكن (`flutter analyze`) من غير أي ملاحظة، واختبار يدوي على موبايل حقيقي لأن كشف الوش محتاج وش حقيقي. وأثبتّ إن التبسيط ما غيّرش السلوك عن طريق اختبار قارن الكود القديم بالجديد على آلاف الحالات العشوائية وطلعت النتيجة متطابقة تماماً.

## "What if you changed this line?" questions

| If you removed / changed | What would happen |
|--------------------------|-------------------|
| `_isProcessing = false` in the `finally` | After the first error, detection would stop forever and the app would look frozen |
| The 150 ms throttle | Battery drain and stutter; accuracy would not improve |
| `hysteresisFrames = 3` → `1` | The Lipsing label would flicker several times a second |
| The median → a single frame | One bad reading would change the letter |
| The E rule moved after D | Almost every smile would be reported as D |
| `x = 1.0 - x` for the front camera | The mouth box would move the wrong way when the head moves |
| `WidgetsFlutterBinding.ensureInitialized()` | Plugin calls before initialisation could crash the app |
| `_session.dispose()` in `dispose()` | The camera would keep running in the background |
| `setNumFaces(1)` → `2` | It would track two faces; the app only reads the first, so it would just be slower |

---

# Part 7 — Presentation Scripts

## 7.1 The 60-second overview

> "Lips Offline is a Flutter app that helps someone practising sign language check their mouth shapes. Sign languages use mouthing to tell similar hand signs apart, but a learner alone cannot see their own mouth.
>
> The app opens the front camera and, about seven times a second, sends one frame to Google's MediaPipe Face Landmarker running natively on the device. MediaPipe returns numbers describing the mouth — how open, how puckered, how wide. Two classes of mine turn those numbers into answers: one decides whether the user is lipsing, and one classifies the mouth shape into a practice letter A to E.
>
> Everything runs on the phone, so it works with no internet and no video ever leaves the device. The code is layered so the detection logic can be tested without a camera — I have 73 automated tests."

## 7.2 The 3-minute technical explanation

> "The architecture has four layers. `domain` holds `FaceLipsResult`, the object carrying one frame's data. `application` holds the logic — the camera session and the two detectors. `infrastructure` talks to the outside world — the JPEG encoder and the method-channel bridge to MediaPipe. Then the screens and widgets on top.
>
> The pipeline works like this. The camera streams frames far faster than we can analyse them, so `LipsCameraSession` has two guards: it skips a frame if the previous one is still processing, and it enforces a 150 millisecond gap. An accepted frame is converted from the camera's YUV420 format into JPEG, then sent over a method channel called `lips/offline/face`. On the Android side, Kotlin loads the `face_landmarker.task` model from the app's assets and runs detection on a background thread, replying on the main thread as Flutter requires.
>
> MediaPipe gives back 478 face points and about 52 blendshapes. I keep six mouth blendshapes and six lip landmarks, which give me a mouth bounding box.
>
> Then two detectors run in order. `LipsingDetector` says a frame is active if the mouth is open past a threshold **or** if it is moving enough — measured as the weighted average change over the last eight frames. It only changes its displayed answer after three frames agree, which is hysteresis and stops flickering.
>
> `LipLetterDetector` first takes the median of the last five frames, so one bad reading cannot decide. Then it runs a priority tree: E, C, B, A, D. The order matters because mouth shapes overlap — a smile is also slightly open, so the distinctive shapes must be asked before the vague ones.
>
> All three thresholds are adjustable in Settings and saved with `shared_preferences`, because every face and every room's lighting is different."

## 7.3 The 10-minute walkthrough

Follow this route through the code, with the files open:

| Minute | File | What to say |
|--------|------|-------------|
| 0–1 | `main.dart` | Entry point, `ensureInitialized()`, dark theme, splash first |
| 1–2 | `splash_screen.dart` → `onboarding_screen.dart` | Timer, `pushReplacement`, the 3 pages |
| 2–3 | `home_screen.dart` | The three states; `_scheduleSetup()` and why it waits a frame |
| 3–5 | `lips_camera_session.dart` | `initialize()`'s four steps; `_onFrame()`'s two guards and the `finally` |
| 5–6 | `camera_frame_encoder.dart` | YUV420: Y per pixel, U and V per 2×2 block; why `bytesPerRow` not `width` |
| 6–7 | `mediapipe_face_landmark_extractor.dart` + `FaceLandmarkerBridge.kt` | The channel name, the two methods, threading, the six lip landmark indices |
| 7–8 | `lipsing_detector.dart` | Open **OR** moving; the weights; hysteresis |
| 8–9 | `lip_letter_detector.dart` | Median of 5; the E→C→B→A→D tree; why the order matters |
| 9–10 | `lips_camera_preview.dart` + `test/` | Rotation and mirroring; then show the tests passing |

**Finish with:** `flutter test` — 73 tests passing, live, in front of the examiner.

---

# Part 8 — The Ten Code Sections You Must Study

| # | File | What to know cold |
|---|------|-------------------|
| 1 | `lipsing_detector.dart` → `update()` | The OR condition, the 3-frame hysteresis, the instant-on shortcut |
| 2 | `lip_letter_detector.dart` → `_classify()` | The whole E→C→B→A→D tree and **why** that order |
| 3 | `lip_letter_detector.dart` → `_medianFeatures()` | Median vs average, and why median is safer |
| 4 | `lips_camera_session.dart` → `_onFrame()` | The two guards, the 150 ms throttle, the `finally` |
| 5 | `lips_camera_session.dart` → `initialize()` | The four start-up steps and the error handling |
| 6 | `mediapipe_face_landmark_extractor.dart` | The method channel, its two methods, defensive reading |
| 7 | `FaceLandmarkerBridge.kt` → `processFrame()` | Blendshape names, the six lip indices, the empty-result contract |
| 8 | `MainActivity.kt` | Main thread for init, background thread for frames, and why |
| 9 | `lips_camera_preview.dart` → `computeMouthRect()` | Rotation (`y = 1.0 - originalX`) and mirroring (`x = 1.0 - x`) |
| 10 | `face_lips_result.dart` → `copyWith()` | Immutability, and why `clearDetectedLetter` exists |

> **بالعربي:** دول أهم ١٠ حتت في الكود. لو مذاكرتهم كويس تقدر تجاوب على أي سؤال في المناقشة. أهمهم: شجرة الحروف وترتيبها، والـ hysteresis، والحارسين بتوع الفريمات، وحسابات المربع حوالين الفم.

---

# Part 9 — Honest Limitations

State these confidently. Knowing your own limits is a strength in a viva.

| Limitation | Honest explanation |
|------------|--------------------|
| **Not speech recognition** | The app reports mouth *shapes*, not words. Different sounds share the same shape, so lips alone cannot identify a word. |
| **Rule-based, not learned** | The thresholds were chosen by testing, not fitted to a dataset. They can be tuned in Settings, but there is no per-user calibration. |
| **No measured accuracy figure** | I did not collect a labelled test set, so I do **not** claim a percentage. Claiming one without measuring it would be dishonest. |
| **Lighting and angle affect results** | Blendshape values depend on the model seeing the face clearly. |
| **One face only** | `setNumFaces(1)` — the app is designed for one user practising. |
| **About 7 analyses per second** | A deliberate trade-off for battery life; it adds slight lag. |
| **Onboarding shows every launch** | There is no "seen it already" flag saved yet. This is listed as future work. |
| **iOS not tested on a device** | The Swift bridge mirrors the Kotlin one and is structurally complete, but I only had an Android device to test on. |

> **بالعربي:** التطبيق بيقول شكل الفم مش الكلام، لأن أصوات مختلفة ليها نفس الشكل. القواعد اتظبطت بالتجربة مش بالتدريب على داتا. وما بدّعيش نسبة دقة معيّنة لأني ما عملتش قياس رسمي — ادّعاء رقم من غير قياس ده غش. الإضاءة وزاوية الوش بتأثر. وشغّال لوش واحد بس.

---

# Part 10 — Quick Revision Sheet

**Read only this on the day.**

### The one-sentence answer
> "A Flutter app that watches your mouth with the front camera and tells you, offline, whether you are lipsing and which of five mouth shapes A–E you are making."

### The numbers to remember

| Number | Meaning |
|--------|---------|
| **150 ms** | Gap between analysed frames (~7 per second) |
| **0.25** | Default mouth-open threshold |
| **0.035** | Default motion threshold |
| **0.28** | Default minimum letter score |
| **3 frames** | Lipsing hysteresis |
| **2 frames** | Letter hysteresis |
| **5 frames** | Median window for letters |
| **8 frames** | History window for movement |
| **478** | Face points MediaPipe returns |
| **~52** | Blendshapes MediaPipe returns |
| **6** | Mouth blendshapes actually used |
| **6** | Lip landmarks used for the box (61, 291, 0, 17, 13, 14) |
| **73** | Automated tests |

### The five letters
**A** wide open · **B** closed · **C** rounded · **D** slightly open · **E** smile
Priority order: **E → C → B → A → D**

### The pipeline in eight words
**Camera → JPEG → MediaPipe → Lipsing → Letter → Screen**

### The three anti-flicker tricks
1. Throttle (150 ms)
2. Median of 5 frames
3. Hysteresis (wait for agreement)

### The three error levels
1. Bad frame → skip it
2. Start-up failure → error screen + Try Again
3. Bad native reply → default to 0

### If you are asked something you do not know
> "I did not measure that, so I would rather not guess. What I can tell you is how the code behaves in that situation..."

Then explain the behaviour you **do** know. Never invent a number.

> **بالعربي — المراجعة السريعة:** التطبيق بيراقب الفم بالكاميرا الأمامية ويقول lipsing ولا لأ، وأي حرف من A لـ E، كله offline. الأرقام المهمة: ١٥٠ ملي ثانية بين الفريمات، عتبة الفتح ٠.٢٥، عتبة الحركة ٠.٠٣٥، أقل درجة للحرف ٠.٢٨، و٧٣ اختبار. ترتيب الشجرة E ثم C ثم B ثم A ثم D. ولو سؤال ما تعرفش إجابته، ما تخترعش رقم — قول إنك ما قستهوش واشرح السلوك اللي إنت متأكد منه.

---

## Good luck 🎓

You wrote this project, you understand it, and every number in this guide comes from the code itself. Answer calmly, and when you do not know something, say so and explain what you do know.
