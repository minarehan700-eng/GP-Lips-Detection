# Line-by-Line Study Guide

The most important code in the project, explained one statement at a time.
Each block gives you: the code, what every line does, what would break if it were removed, and a short sentence you can say to the examiner.

Simple English first, then a short Arabic explanation.

---

## Contents

| # | File | Function |
|---|------|----------|
| 1 | `lib/main.dart` | `main()` |
| 2 | `lib/application/lipsing_detector.dart` | `update()` |
| 3 | `lib/application/lipsing_detector.dart` | `_averageMouthMovement()` |
| 4 | `lib/application/lip_letter_detector.dart` | `_classify()` |
| 5 | `lib/application/lip_letter_detector.dart` | `_median()` |
| 6 | `lib/application/lips_camera_session.dart` | `_onFrame()` |
| 7 | `lib/application/lips_camera_session.dart` | `initialize()` |
| 8 | `lib/infrastructure/mediapipe_face_landmark_extractor.dart` | `processFrame()` |
| 9 | `lib/infrastructure/camera_frame_encoder.dart` | `_encodeYuv420()` |
| 10 | `lib/widgets/lips_camera_preview.dart` | `computeMouthRect()` |
| 11 | `lib/domain/face_lips_result.dart` | `copyWith()` |
| 12 | `lib/screens/home_screen.dart` | `_scheduleSetup()` |

---

# 1. `main()` — where everything starts

**File:** `lib/main.dart`

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LipsOfflineApp());
}
```

### Line by line

| Line | What it does |
|------|--------------|
| `void main()` | The first function Dart runs. Every Dart program starts here. |
| `WidgetsFlutterBinding.ensureInitialized()` | Starts the bridge between Flutter and the phone's operating system, **before** any widget exists. |
| `runApp(const LipsOfflineApp())` | Hands the root widget to Flutter, which draws it on screen and keeps it running. |

**Input:** none. **Output:** none — it starts the app.

### Why the middle line is needed
This app talks to the platform: the camera, saved settings, and the MediaPipe method channel. That machinery must exist before a widget tries to use it.

### If it were removed
The app might work by luck, or might crash with *"Binding has not yet been initialized"* the first time a plugin is used.

> **Say to the examiner:** *"`main()` is the entry point. `ensureInitialized()` prepares the connection to the phone's platform code, because my app uses the camera and saved settings. Then `runApp` shows the root widget."*

**بالعربي:** `main()` هي أول دالة بتشتغل. السطر التاني بيجهّز الاتصال بين Flutter ونظام الموبايل قبل ما أي واجهة تظهر، لأن التطبيق بيستخدم الكاميرا والإعدادات المحفوظة. و`runApp` بيعرض الواجهة الرئيسية.

---

# 2. `LipsingDetector.update()` — the Yes/No decision

**File:** `lib/application/lipsing_detector.dart`

```dart
FaceLipsResult update(FaceLipsResult raw) {
  if (!raw.faceDetected) {
    return raw.copyWith(isLipsing: _handleMissingFace());
  }

  _remember(raw);

  final bool mouthIsOpenEnough = raw.mouthOpen > mouthOpenThreshold;
  final bool mouthIsMovingEnough = _averageMouthMovement() > motionThreshold;
  final bool frameLooksActive = mouthIsOpenEnough || mouthIsMovingEnough;

  if (frameLooksActive) {
    _countActiveFrame(raw.mouthOpen);
  } else {
    _countInactiveFrame();
  }

  return raw.copyWith(isLipsing: _isLipsing);
}
```

### Line by line

| Line | What it does |
|------|--------------|
| `if (!raw.faceDetected)` | **Guard clause.** No face in this frame, so there is nothing to measure. |
| `_handleMissingFace()` | Clears the history and fades the answer to No after 3 missing frames. Returns the answer to show now. |
| `_remember(raw)` | Stores this frame's mouth shape, keeping only the last 8. |
| `mouthIsOpenEnough` | Sign 1 — the mouth is open past the threshold (default `0.25`). |
| `mouthIsMovingEnough` | Sign 2 — the mouth is *changing* faster than the threshold (default `0.035`). |
| `frameLooksActive` | Combines them with **OR** — either sign alone is enough. |
| `_countActiveFrame` / `_countInactiveFrame` | Adds this frame's vote. Only these can change `_isLipsing`. |
| `return raw.copyWith(...)` | Returns a **copy** with the answer attached; the input is never modified. |

### The variables

| Name | Meaning |
|------|---------|
| `raw` | One frame of mouth data straight from MediaPipe |
| `_isLipsing` | The stable answer currently on screen |
| `_activeFrameStreak` | How many frames in a row voted "active" |
| `_inactiveFrameStreak` | How many frames in a row voted "not active" |

**Input:** one `FaceLipsResult`. **Output:** a copy with `isLipsing` set. **Side effect:** updates the history and the two streak counters.

### Why the OR is important
Someone can lip a word with a **barely open** mouth — caught by movement. Someone can hold a wide "aah" **almost still** — caught by openness. Requiring both would miss half of real lipsing.

### If the guard clause were removed
A frame with no face would still be added to the history and compared against the previous face, producing a huge fake "movement" and a wrong Yes.

> **Say to the examiner:** *"A frame counts as active if the mouth is open enough **or** moving enough. But I never change the displayed answer from one frame — the vote goes to a counter, and the answer only flips when three frames agree."*

**بالعربي:** الفريم بيتحسب "نشط" لو الفم مفتوح كفاية **أو** بيتحرّك كفاية. لكن الإجابة على الشاشة ما بتتغيّرش من فريم واحد — الصوت بيروح لعدّاد، والإجابة ما بتتقلبش غير لما ٣ فريمات يتفقوا.

---

# 3. `_averageMouthMovement()` — measuring movement

**File:** `lib/application/lipsing_detector.dart`

```dart
double _averageMouthMovement() {
  if (_recentSamples.length < 2) {
    return 0;
  }

  var totalChange = 0.0;
  var comparisons = 0;

  for (var i = 1; i < _recentSamples.length; i++) {
    final previous = _recentSamples[i - 1];
    final current = _recentSamples[i];

    final openChange = (current.mouthOpen - previous.mouthOpen).abs();
    final puckerChange = (current.mouthPucker - previous.mouthPucker).abs();
    final smileChange = (current.smile - previous.smile).abs();

    totalChange += openChange;
    totalChange += puckerChange * puckerMotionWeight;   // 0.50
    totalChange += smileChange * smileMotionWeight;     // 0.35
    comparisons++;
  }

  if (comparisons == 0) {
    return 0;
  }
  return totalChange / comparisons;
}
```

### Line by line

| Line | What it does |
|------|--------------|
| `if (_recentSamples.length < 2)` | You cannot measure *change* with fewer than two frames. |
| `for (var i = 1; ...)` | Starts at **1**, not 0, because each step compares frame `i` with frame `i-1`. |
| `.abs()` | Absolute value — opening and closing are both movement. Without it, opening and closing would cancel out to zero. |
| `* puckerMotionWeight` | The pucker moves about half as much as the jaw, so it counts half. |
| `* smileMotionWeight` | The smile moves least, so it counts least. |
| `totalChange / comparisons` | The **average** change per frame pair, so the result does not depend on how full the history is. |

**Input:** none (reads the stored history). **Output:** roughly 0.0 (still) to ~1.0 (changing a lot).

### If `.abs()` were removed
A mouth opening then closing by the same amount would score **zero movement**, and the detector would report "not lipsing" for exactly the motion it is meant to catch.

### If it returned the total instead of the average
The score would grow just because more frames were stored, so the threshold would mean nothing.

> **Say to the examiner:** *"I add up how much three mouth values changed between consecutive frames. The three are weighted because they do not move by the same amount — the jaw swings widest, so it counts fully; the pucker about half; the smile least. Then I divide by the number of comparisons to get an average."*

**بالعربي:** بجمع مقدار تغيّر ٣ قيم للفم بين كل فريمين ورا بعض. والقيم ليها أوزان مختلفة لأنها مش بتتحرّك بنفس المقدار — الفك أوسع فبياخد الوزن كامل، والزمّ نصّه، والابتسامة أقلهم. وبعدين بقسم على عدد المقارنات عشان أطلّع المتوسط.

---

# 4. `LipLetterDetector._classify()` — the A–E priority tree

**File:** `lib/application/lip_letter_detector.dart`

```dart
_LetterMatch? _classify(_MouthFeatures f) {
  final double roundness = math.max(f.pucker, f.funnel);
  final double wideness = math.max(f.smile, f.stretch);

  // --- E: smiling or stretched wide ---
  final bool smilingClearly = wideness >= strongSmileThreshold;
  final bool smileBeatsRound = wideness >= roundness - smileOverRoundAllowance;
  if (smilingClearly && smileBeatsRound) {
    final double score = _clamp01(wideness);
    if (score >= minScore) {
      return _LetterMatch('E', score);
    }
  }

  // --- C: rounded or puckered lips ---
  if (roundness >= strongRoundThreshold) { ... return _LetterMatch('C', score); }

  // --- B: lips closed ---
  final bool barelyOpen = f.open <= closedMouthMaxOpen;
  final bool lipsPressed = f.close >= closedMouthMinClose;
  final bool practicallyShut = f.open <= definitelyClosedOpen;
  if (barelyOpen && (lipsPressed || practicallyShut)) {
    final double score = _clamp01(math.max(f.close, 1.0 - f.open));
    ...
  }

  // --- A: wide open, not a smile or a pucker ---
  // --- D: slightly open, the fallback ---

  return null;
}
```

### Line by line

| Line | What it does |
|------|--------------|
| `roundness = max(pucker, funnel)` | "Roundness" has two possible sources; take whichever is stronger. |
| `wideness = max(smile, stretch)` | Same idea for "wideness". |
| `smilingClearly` | Is there a real smile at all? (≥ `0.28`) |
| `smileBeatsRound` | Is the smile at least as strong as the roundness, allowing a small `0.05` margin? |
| `if (score >= minScore)` | Even a matching shape is rejected if it is not confident enough — and then the **next rule gets its turn**. |
| `math.max(f.close, 1.0 - f.open)` | B's confidence rises both when lips press harder *and* when the mouth is more fully shut, so take the stronger reading. |
| `return null` | Nothing matched. The screen shows a dash `—` rather than guessing. |

**Input:** the median features of the last 5 frames. **Output:** a letter + confidence, or `null`.

### Why the order E → C → B → A → D
Mouth shapes **overlap**. A smile is also slightly open. If D ("slightly open") were asked first, every smile would be reported as D. So the most distinctive shapes are asked first and the vaguest is left last as a fallback.

### If `smileBeatsRound` were removed
An "oo" shape (strongly puckered) that also has a slightly raised smile value would be reported as **E** instead of **C**.

### If the `return null` became a default letter
The app would show a confident-looking letter for a mouth that matches nothing — worse than showing nothing.

> **Say to the examiner:** *"It is a priority tree — five rules asked in a fixed order, first match wins. The order matters because real mouth shapes overlap: a smile is also slightly open, so if I asked about D first, every smile would come out as D."*

**بالعربي:** دي شجرة أولويات — خمس قواعد بترتيب ثابت وأول واحدة تتحقق تكسب. والترتيب مهم لأن أشكال الفم بتتداخل: الابتسامة كمان فمها مفتوح شوية، فلو سألت عن D الأول كل ابتسامة هتطلع D.

---

# 5. `_median()` — why median, not average

**File:** `lib/application/lip_letter_detector.dart`

```dart
static double _median(List<double> values) {
  values.sort();
  final int middle = values.length ~/ 2;

  if (values.length.isOdd) {
    return values[middle];
  }
  return (values[middle - 1] + values[middle]) / 2;
}
```

### Line by line

| Line | What it does |
|------|--------------|
| `values.sort()` | Puts the numbers in order — the median is meaningless without this. |
| `~/` | **Integer division.** `5 ~/ 2` is `2`, not `2.5`. A list index must be a whole number. |
| `isOdd` → `values[middle]` | With an odd count there is a true middle item. |
| else | With an even count there is no single middle, so the two middle items are averaged. |

**Input:** a list of one feature's recent values. **Output:** the middle value.

### Why median and not average
The median **ignores one extreme reading**. If four frames say "closed" (0.05) and one bad frame says "wide open" (0.95), the median is still 0.05. The average would be 0.23 — enough to change the letter.

### If it were removed and a single frame used instead
The displayed letter would jump around whenever MediaPipe produced one poor reading, which happens regularly with normal lighting changes.

> **Say to the examiner:** *"I take the median of the last five frames, not the average, because the median throws away a single strange reading. Four frames saying closed and one saying wide open still gives closed."*

**بالعربي:** بستخدم الوسيط لآخر ٥ فريمات مش المتوسط، لأن الوسيط بيتجاهل القراءة الشاذة الواحدة. لو ٤ فريمات قالوا "مقفول" وواحد قال "مفتوح جداً"، الوسيط لسه هيقول مقفول.

---

# 6. `_onFrame()` — the heart of the app

**File:** `lib/application/lips_camera_session.dart`

```dart
Future<void> _onFrame(CameraImage image, void Function() onUpdate) async {
  if (_isProcessing) {
    return;
  }

  final DateTime now = DateTime.now();
  final int millisecondsSinceLastFrame =
      now.difference(_lastProcessed).inMilliseconds;
  if (millisecondsSinceLastFrame < minMillisecondsBetweenFrames) {
    return;
  }

  _lastProcessed = now;
  _isProcessing = true;

  try {
    final jpegBytes = await _encoder.encodeToJpeg(image, quality: frameJpegQuality);
    if (jpegBytes == null) {
      return;
    }

    final FaceLipsResult rawResult = await _extractor.processFrame(
      bytes: jpegBytes,
      width: image.width,
      height: image.height,
      rotation: frameRotationDegrees,
    );

    final FaceLipsResult withLipsing = _lipsingDetector.update(rawResult);
    result = _lipLetterDetector.update(withLipsing);

    frameImageWidth = image.width;
    frameImageHeight = image.height;
    onUpdate();
  } finally {
    _isProcessing = false;
  }
}
```

### Line by line

| Line | What it does |
|------|--------------|
| `if (_isProcessing) return;` | **Guard 1.** A frame is already being analysed — drop this one. |
| `millisecondsSinceLastFrame < 150` | **Guard 2.** Not enough time has passed — drop this one. |
| `_isProcessing = true` | Claims the pipeline so no other frame can enter. |
| `await _encoder.encodeToJpeg(...)` | Converts the camera's raw pixels into JPEG. `await` = wait for it without freezing the screen. |
| `if (jpegBytes == null) return;` | Unknown frame format — skip this frame silently. |
| `await _extractor.processFrame(...)` | Sends the JPEG to native MediaPipe and waits for the mouth numbers. |
| `_lipsingDetector.update(rawResult)` | First detector — adds the `isLipsing` flag. |
| `_lipLetterDetector.update(withLipsing)` | Second detector — receives the *first one's output* and adds the letter. |
| `onUpdate()` | Tells the screen to redraw. |
| `finally { _isProcessing = false; }` | **Always** releases the pipeline, even if something above threw. |

**Input:** one camera frame + a redraw callback. **Output:** none — it replaces `result`.

### Why two guards
The camera produces ~30 frames per second; MediaPipe can analyse ~7. Without the guards, work would pile up faster than it completes.

### If `finally` were removed — the most important question here
On the **first exception**, `_isProcessing` would stay `true` forever. Every future frame would hit Guard 1 and return immediately. **Detection would stop permanently and silently** — the app would look frozen with no error message.

> **Say to the examiner:** *"Two guards stop frames piling up: one blocks a second frame while one is being analysed, the other enforces a 150 ms gap to save battery. The `finally` is essential — if analysis throws, the flag must still be cleared, otherwise the app would stop detecting forever."*

**بالعربي:** فيه حارسين بيمنعوا تكدّس الفريمات: واحد بيمنع فريم جديد والقديم لسه شغال، والتاني بيفرض ١٥٠ ملي ثانية عشان البطارية. والـ `finally` مهمة جداً — لو حصل خطأ لازم الـ flag يترجع `false`، وإلا التطبيق هيبطّل كشف للأبد من غير ما يقول حاجة.

---

# 7. `initialize()` — starting everything in order

**File:** `lib/application/lips_camera_session.dart`

```dart
Future<void> initialize(void Function() onUpdate) async {
  try {
    initPhase = 'Loading settings...';
    onUpdate();
    await applyDetectorSettings();

    initPhase = 'Loading face landmarker...';
    onUpdate();
    await _extractor.initialize();

    initPhase = 'Starting camera...';
    onUpdate();

    final CameraDescription? chosenCamera = await _pickFrontCamera();
    if (chosenCamera == null) {
      error = 'No camera found on this device.';
      return;
    }

    final CameraController? controller = await _openCamera(chosenCamera);
    if (controller == null) {
      error = 'Failed to initialize camera at any supported resolution.';
      return;
    }

    await controller.startImageStream((image) => _onFrame(image, onUpdate));

    camera = controller;
    isFrontCamera = chosenCamera.lensDirection == CameraLensDirection.front;
    cameraResolutionLabel = _describeResolution(controller);
    initPhase = 'Ready';
    error = null;
    onUpdate();
  } on PlatformException catch (e) {
    error = e.message ?? e.code;
    onUpdate();
  } catch (e) {
    error = e.toString();
    onUpdate();
  }
}
```

### The four steps

| Step | Line | Why in this order |
|------|------|-------------------|
| 1 | `applyDetectorSettings()` | The detectors need their thresholds before any frame arrives |
| 2 | `_extractor.initialize()` | The model must be loaded before a frame can be analysed |
| 3 | `_pickFrontCamera()` / `_openCamera()` | Only now do we open the hardware |
| 4 | `startImageStream(...)` | Frames start flowing — everything else is ready |

### Other lines

| Line | What it does |
|------|--------------|
| `initPhase = '...'` then `onUpdate()` | Updates the text under the loading spinner so the user sees progress. |
| `camera = controller` **after** `startImageStream` | The screen only draws the preview when `camera` is not null, so it is assigned last — when everything really is ready. |
| `on PlatformException catch (e)` | The specific error from the camera plugin or the method channel — for example refused camera permission. |
| `catch (e)` | Anything else, so nothing can escape and crash the app. |

**Input:** a redraw callback. **Output:** none — reports through `initPhase` and `error`.

### If the two `catch` blocks were removed
Denying camera permission would throw an uncaught exception and the screen would go red/blank instead of showing a friendly message with a **Try Again** button.

> **Say to the examiner:** *"Start-up is four steps in a fixed order: settings, then the model, then find the camera, then start the stream. Each step updates the loading text, so if it ever stops the user can see exactly where. Everything is wrapped in try/catch so a refused permission becomes a message, not a crash."*

**بالعربي:** التشغيل ٤ خطوات بترتيب ثابت: الإعدادات، بعدين الموديل، بعدين نلاقي الكاميرا، بعدين نبدأ الفريمات. وكل خطوة بتغيّر النص تحت علامة التحميل، فلو وقف في أي مكان المستخدم يشوف وقف فين. وكل ده جوّه try/catch عشان رفض الإذن يبقى رسالة مش كراش.

---

# 8. `processFrame()` — crossing into native code

**File:** `lib/infrastructure/mediapipe_face_landmark_extractor.dart`

```dart
final bool inputIsUsable =
    _initialized && bytes.isNotEmpty && width > 0 && height > 0;
if (!inputIsUsable) {
  return _noFaceResult();
}

Map<String, dynamic>? response;
try {
  response = await _channel.invokeMapMethod<String, dynamic>(
    processFrameMethod,
    {'bytes': bytes, 'width': width, 'height': height, 'rotation': rotation},
  );
} on PlatformException {
  response = null;
}

if (response == null) {
  return _noFaceResult();
}

return _parseResponse(response);
```

and the defensive reader:

```dart
static double _readNumber(Map<String, dynamic> response, String key) {
  return (response[key] as num?)?.toDouble() ?? 0;
}
```

### Line by line

| Line | What it does |
|------|--------------|
| `inputIsUsable` | **Input validation** — four checks in one named variable: the model is loaded, there are bytes, and the size is real. |
| `invokeMapMethod` | Sends a message across the **method channel** to Kotlin/Swift and waits for a map back. |
| `on PlatformException { response = null; }` | Native code failed on this frame. Treat it as "no face" rather than crashing. |
| `(response[key] as num?)` | Read as a **nullable number**. `as num` (without `?`) would throw if the key were missing. |
| `?.toDouble() ?? 0` | Convert to double if present; use 0 if not. |

**Input:** JPEG bytes + frame size + rotation. **Output:** a `FaceLipsResult` — never an exception.

### Why every value is read this way
The map crosses a **platform boundary**. A key could be missing, or a value could arrive as an `int` where a `double` is expected. Reading defensively means a malformed reply looks like "no face this frame" instead of crashing the app.

### If `as num?` became `as double`
A native side returning `0` (an int) instead of `0.0` would throw a type error and kill the frame — a bug that would only appear on some devices.

> **Say to the examiner:** *"This is the only Dart file that knows about native code. It owns the method channel `lips/offline/face`. Every value coming back is read defensively as a nullable number with a default of zero, because the data crosses a platform boundary and I cannot fully trust its types."*

**بالعربي:** ده الملف الوحيد في Dart اللي بيعرف حاجة عن الكود الـ native، وهو المسؤول عن القناة `lips/offline/face`. وكل قيمة راجعة بتتقرا بحذر كرقم ممكن يكون فاضي وبقيمة افتراضية صفر، لأن البيانات بتعدّي حدود المنصة ومقدرش أثق في نوعها ١٠٠٪.

---

# 9. `_encodeYuv420()` — the pixel conversion

**File:** `lib/infrastructure/camera_frame_encoder.dart`

```dart
final int brightnessIndex = y * brightnessPlane.bytesPerRow + x;

final int chromaIndex =
    (y ~/ chromaSubsampleFactor) * uPlane.bytesPerRow +
        (x ~/ chromaSubsampleFactor) * chromaBytesPerPixel;

final int brightness = brightnessPlane.bytes[brightnessIndex];
final int blueDifference = uPlane.bytes[chromaIndex] - chromaNeutral;
final int redDifference = vPlane.bytes[chromaIndex] - chromaNeutral;

final int red = _toColorByte(brightness + redFromV * redDifference);
final int green = _toColorByte(
  brightness - greenFromU * blueDifference - greenFromV * redDifference,
);
final int blue = _toColorByte(brightness + blueFromU * blueDifference);

output.setPixelRgb(x, y, red, green, blue);
```

### Line by line

| Line | What it does |
|------|--------------|
| `y * bytesPerRow + x` | Finds this pixel's brightness. **`bytesPerRow`, not `width`** — a row can be padded by the hardware to a convenient length, making it wider than the image. |
| `(y ~/ 2)` and `(x ~/ 2)` | The colour values are shared by each **2×2 block** of pixels, so their indexes are halved. This is called *chroma subsampling*. |
| `- chromaNeutral` (128) | U and V are stored centred on 128. Subtracting it gives a signed "how far from grey" value. |
| `redFromV`, `greenFromU`… | Fixed **BT.601** coefficients from the video standard. They are not tuning values — they cannot be changed. |
| `_toColorByte(...)` | Rounds and clamps into 0–255, because the formula can overshoot slightly. |

**Input:** one `CameraImage` in YUV420. **Output:** JPEG bytes.

### The core idea
YUV420 stores a frame in three planes: **Y** (brightness, one value per pixel) and **U**/**V** (colour, one value per 2×2 block). So every pixel needs its own Y but shares U and V with its neighbours.

### If `bytesPerRow` were replaced with `width`
On devices that pad their rows, every row would be read at a slight offset and the image would appear **skewed diagonally** — and MediaPipe would find no face.

> **Say to the examiner:** *"The camera gives YUV420, which stores brightness per pixel but colour per 2×2 block — that is why the colour indexes are divided by two. I use `bytesPerRow` rather than `width` because some devices pad each row, and using width would skew the image."*

**بالعربي:** الكاميرا بتدّي صيغة YUV420، اللي بتخزّن الإضاءة لكل بكسل لكن اللون لكل مربّع ٢×٢ — وعشان كده بنقسم أرقام اللون على ٢. وبستخدم `bytesPerRow` مش `width` لأن بعض الأجهزة بتزوّد حشو في آخر كل صف، ولو استخدمت العرض الصورة هتطلع مايلة.

---

# 10. `computeMouthRect()` — the hardest maths

**File:** `lib/widgets/lips_camera_preview.dart`

```dart
static Offset _toScreenPoint({...}) {
  double x = normalizedX;
  double y = normalizedY;

  if (swapAxes) {
    final double originalX = x;
    x = y;
    y = 1.0 - originalX;
  }

  if (isFrontCamera) {
    x = 1.0 - x;
  }

  return Offset(x * widgetSize.width, y * widgetSize.height);
}
```

### Line by line

| Line | What it does |
|------|--------------|
| `final double originalX = x;` | **Saves the old X first.** The next line overwrites `x`, so without this the rotation would use the wrong value. |
| `x = y;` | A quarter-turn: the old **Y** becomes the new **X**. |
| `y = 1.0 - originalX;` | The old **X** becomes the new **Y**, measured **from the other end** — that is what `1.0 -` means. |
| `if (isFrontCamera) x = 1.0 - x;` | Mirrors left↔right, because a front camera shows a mirror image. |
| `x * widgetSize.width` | Converts the 0.0–1.0 fraction into actual screen pixels. |

**Input:** a point as two 0.0–1.0 fractions. **Output:** a point in screen pixels.

### Why two corrections are needed
1. **Rotation** — many phone cameras always deliver a *landscape* image even when the phone is upright.
2. **Mirroring** — the front camera shows you as a mirror does.

### If `x = 1.0 - x` were removed
The mouth box would move the **wrong way**: move your head left and the box goes right. This is the single most visible bug in the whole app.

### If `originalX` were not saved
The rotation would compute `y = 1.0 - y_new`, using the already-overwritten value, and the box would land in a completely wrong place.

> **Say to the examiner:** *"This maps MediaPipe's 0-to-1 coordinates onto screen pixels. Two things get in the way: the camera frame may be sideways, so I swap the axes with a quarter-turn; and the front camera is mirrored, so I flip X. I have to save the old X in a variable first, because the line above already overwrote it."*

**بالعربي:** الكود ده بيحوّل إحداثيات MediaPipe من ٠ لـ ١ لبكسلات على الشاشة. وفيه حاجتين بيعقّدوا الموضوع: الفريم ممكن يكون مقلوب على جنب فبنبدّل المحاور بربع لفة؛ والكاميرا الأمامية مقلوبة زي المراية فبنعكس X. ولازم أحفظ X القديمة في متغير الأول لأن السطر اللي فوق غيّرها بالفعل.

---

# 11. `copyWith()` — and the flag that looks strange

**File:** `lib/domain/face_lips_result.dart`

```dart
FaceLipsResult copyWith({
  ...
  String? detectedLetter,
  bool clearDetectedLetter = false,
  ...
}) {
  return FaceLipsResult(
    ...
    detectedLetter:
        clearDetectedLetter ? null : (detectedLetter ?? this.detectedLetter),
    ...
  );
}
```

### Line by line

| Part | What it does |
|------|--------------|
| `String? detectedLetter` | Optional. If you do not pass it, it is `null`. |
| `detectedLetter ?? this.detectedLetter` | "Use the new value if given, otherwise keep the old one." |
| `clearDetectedLetter ? null : (...)` | If the flag is true, deliberately **erase** the letter. |

### Why the extra flag exists — a very likely question
In `copyWith`, passing `null` normally means *"don't change this field"*. But sometimes the letter genuinely must be **erased** — when the face leaves the camera. There is no way to say that with `null`, because `null` already means "leave it alone". So a separate boolean expresses the difference.

### If the flag were removed
Once a letter had been shown, it could never be cleared. The last detected letter would stay frozen on screen after you walked away from the camera.

> **Say to the examiner:** *"`copyWith` returns a modified copy instead of editing the object, so an earlier stage's values can always be trusted. The `clearDetectedLetter` flag exists because passing `null` already means 'leave it unchanged' — I needed a separate way to say 'erase it on purpose', which happens when the face disappears."*

**بالعربي:** `copyWith` بترجّع نسخة معدّلة بدل ما تعدّل الكائن نفسه، عشان أقدر أثق دايماً في قيم المرحلة اللي قبلها. والـ flag اسمه `clearDetectedLetter` موجود لأن إني أبعت `null` معناها أصلاً "ما تغيّرش"، فكنت محتاج طريقة تانية أقول بيها "امسحه بشكل مقصود" — وده بيحصل لما الوش يختفي.

---

# 12. `_scheduleSetup()` — why the camera waits one frame

**File:** `lib/screens/home_screen.dart`

```dart
void _scheduleSetup() {
  if (_setupStarted) return;
  _setupStarted = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) {
      _setupStarted = false;
      return;
    }
    unawaited(_setup());
  });
}
```

### Line by line

| Line | What it does |
|------|--------------|
| `if (_setupStarted) return;` | Guard against starting the camera twice. |
| `addPostFrameCallback` | "Run this **after** the first frame has been drawn." |
| `if (!mounted)` | The user left the screen before the callback ran — do nothing. Calling `setState` on a disposed widget throws. |
| `unawaited(_setup())` | Start the async work without waiting. `unawaited` tells the linter this is deliberate, not a forgotten `await`. |

### Why wait for one frame — a good question to be ready for
Opening the camera during `initState` would block the very first build. The user would stare at a **blank white screen** for a second or two with no feedback. Waiting one frame means the loading spinner is already on screen while the camera warms up.

### If the `mounted` check were removed
Leaving the home screen quickly would produce *"setState() called after dispose()"* — a crash in debug and a memory leak in release.

> **Say to the examiner:** *"I deliberately delay opening the camera until after the first frame is drawn, so the loading spinner appears immediately instead of the user seeing a blank screen. The `mounted` check protects against the user leaving before the camera finishes opening."*

**بالعربي:** بأخّر فتح الكاميرا لحد ما أول فريم يترسم، عشان علامة التحميل تظهر فوراً بدل ما المستخدم يشوف شاشة فاضية. وفحص `mounted` بيحمي لو المستخدم خرج من الشاشة قبل ما الكاميرا تخلص فتح.

---

## Common errors and what they mean

| Error you might see | What it means | Fix |
|---------------------|---------------|-----|
| `Binding has not yet been initialized` | A plugin was used before `ensureInitialized()` | Keep that line in `main()` |
| `setState() called after dispose()` | The screen was closed while an async task was still running | Check `mounted` before `setState` |
| `Value 'C:\Program Files\...' does not exist` | The machine-specific Gradle lines | Delete them in `android/gradle.properties` |
| `Initialization failed: face_landmarker.task` | The model file is missing from assets | Check `android/app/src/main/assets/` |
| `type 'int' is not a subtype of type 'double'` | A number crossed the platform boundary with the wrong type | This is why `as num?` is used everywhere |
| App freezes, no detection, no error | `_isProcessing` stuck at `true` | This is exactly what the `finally` block prevents |
