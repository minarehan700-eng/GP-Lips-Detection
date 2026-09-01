// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Lips Offline';

  @override
  String get brandName => 'Lips';

  @override
  String get splashTagline => 'Detect lipsing and mouth letters A–E';

  @override
  String get onboardLipsingTitle => 'What is lipsing?';

  @override
  String get onboardLipsingBody =>
      'Lipsing is mouthing words without voice — common in sign language. This app watches your mouth shape in real time and tells you when lipsing is detected.';

  @override
  String get onboardLipsingPoint1 => 'Face must be visible in the camera';

  @override
  String get onboardLipsingPoint2 => 'Green box highlights your mouth region';

  @override
  String get onboardLipsingPoint3 =>
      '“Lipsing: Yes” means active mouth movement';

  @override
  String get onboardLettersTitle => 'Letters A – E';

  @override
  String get onboardLettersBody =>
      'MediaPipe tracks mouth landmarks and maps shapes to viseme letters A through E.';

  @override
  String get onboardLetterA => 'A — wide open mouth';

  @override
  String get onboardLetterB => 'B — lips closed';

  @override
  String get onboardLetterC => 'C — rounded / puckered lips';

  @override
  String get onboardLetterD => 'D — slightly open';

  @override
  String get onboardLetterE => 'E — smile shape';

  @override
  String get onboardCameraTitle => 'Using the camera';

  @override
  String get onboardCameraBody =>
      'Hold the phone at eye level, face the front camera, and keep good lighting.';

  @override
  String get onboardCameraPoint1 =>
      'Tap a letter chip to set a practice target';

  @override
  String get onboardCameraPoint2 =>
      'Adjust thresholds in Settings if detection feels off';

  @override
  String get onboardCameraPoint3 =>
      'Works fully offline — no internet required';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get homeTitle => 'Lips Detection';

  @override
  String get settings => 'Settings';

  @override
  String get face => 'Face';

  @override
  String get detected => 'Detected';

  @override
  String get notDetected => 'Not detected';

  @override
  String get lipsing => 'Lipsing';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get letterShapeHint =>
      'Smile=E · Round=C · Closed=B · Wide open=A · Slight open=D';

  @override
  String get detectedLetter => 'Detected letter';

  @override
  String confidencePercent(int percent) {
    return '$percent% confidence';
  }

  @override
  String get matched => 'Matched!';

  @override
  String get practiceTarget => 'Practice target';

  @override
  String get mouthOpen => 'Mouth open';

  @override
  String get pucker => 'Pucker';

  @override
  String get smile => 'Smile';

  @override
  String get closeShape => 'Close';

  @override
  String get funnel => 'Funnel';

  @override
  String get stretch => 'Stretch';

  @override
  String percentValue(int percent) {
    return '$percent%';
  }

  @override
  String cameraResolution(int width, int height) {
    return 'Camera: $width×$height';
  }

  @override
  String get detectorThresholds => 'Detector thresholds';

  @override
  String get mouthOpenThreshold => 'Mouth-open threshold';

  @override
  String get mouthOpenThresholdHelp =>
      'Higher = mouth must open more to count as lipsing';

  @override
  String get motionThreshold => 'Motion threshold';

  @override
  String get motionThresholdHelp =>
      'Lower = small mouth movement counts as lipsing';

  @override
  String get letterMinScore => 'Letter min-score';

  @override
  String get letterMinScoreHelp => 'Higher = stricter A–E classification';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get resetDefaults => 'Reset to defaults';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Match my device';

  @override
  String get errorNoCamera => 'No camera found on this device.';

  @override
  String get errorCameraInit =>
      'Failed to initialize camera at any supported resolution.';

  @override
  String get errorLandmarkerMissing =>
      'The face landmarker could not be loaded. Make sure face_landmarker.task exists in android/app/src/main/assets (and the iOS Runner bundle).';

  @override
  String errorInitFailed(String error) {
    return 'Initialization failed:\n$error\n\nMake sure the model file is bundled and camera permission is granted.';
  }

  @override
  String get tryAgain => 'Try Again';

  @override
  String get a11yOpenSettings => 'Open settings';

  @override
  String get a11yCameraPreview =>
      'Live camera preview. Your mouth is tracked here.';

  @override
  String a11yLetterChip(String letter) {
    return 'Letter $letter. Double tap to practise this letter.';
  }

  @override
  String a11yLetterChipSelected(String letter) {
    return 'Letter $letter, currently your practice target. Double tap to stop practising it.';
  }

  @override
  String a11yAnnounceLetter(String letter, int percent) {
    return 'Letter $letter detected, $percent percent confidence';
  }

  @override
  String a11yAnnounceMatched(String letter) {
    return 'Matched letter $letter';
  }

  @override
  String get a11yAnnounceFaceLost => 'Face no longer visible';

  @override
  String get a11yAnnounceFaceFound => 'Face detected';

  @override
  String get haptics => 'Vibrate on a match';

  @override
  String get hapticsHelp =>
      'Buzz when your mouth shape matches the letter you are practising';

  @override
  String get announceDetections => 'Speak detections aloud';

  @override
  String get announceDetectionsHelp =>
      'Sends each detected letter to your screen reader';

  @override
  String get practice => 'Practice';

  @override
  String get practiceStart => 'Start a round';

  @override
  String get practiceMakeShape => 'Make this shape';

  @override
  String get practiceHold => 'Hold it…';

  @override
  String get practiceGotIt => 'Got it!';

  @override
  String get practiceMissed => 'Missed — moving on';

  @override
  String practiceProgress(int done, int total) {
    return '$done of $total';
  }

  @override
  String practiceScore(int hits, int total) {
    return '$hits of $total held';
  }

  @override
  String practiceBestStreak(int streak) {
    return 'Best streak: $streak';
  }

  @override
  String get practiceAgain => 'Practise again';

  @override
  String get practiceDone => 'Round finished';

  @override
  String practiceNearMiss(String letter) {
    return 'You were close on $letter';
  }

  @override
  String get progress => 'Progress';

  @override
  String get progressNone =>
      'No rounds yet. Finish one and your results appear here.';

  @override
  String get progressPerLetter => 'How each letter is going';

  @override
  String progressAttempts(int hits, int attempts) {
    return '$hits/$attempts';
  }

  @override
  String get progressUntried => 'not tried yet';

  @override
  String progressWeakest(String letter) {
    return 'Worth practising: $letter';
  }

  @override
  String progressRounds(int count) {
    return '$count rounds saved';
  }

  @override
  String get progressClear => 'Clear history';

  @override
  String get progressCleared => 'History cleared';

  @override
  String a11yPracticeTarget(String letter) {
    return 'Make the shape for letter $letter';
  }

  @override
  String a11yPracticeHeld(String letter) {
    return 'Letter $letter held';
  }

  @override
  String a11yPracticeMissed(String letter) {
    return 'Letter $letter missed';
  }

  @override
  String get chart => 'Shape guide';

  @override
  String get chartIntro =>
      'Five shapes cover the whole alphabet. A shape is not one letter — it is every letter that looks the same on the lips.';

  @override
  String get chartWhySame => 'Why P, B and M share one shape';

  @override
  String get chartWhySameBody =>
      'They are made in different places inside the mouth, but the lips do exactly the same thing. No camera can separate them. Lip reading uses context to choose between them — which is why words are easier to read than letters.';

  @override
  String get chartLetters => 'Letters';

  @override
  String get chartTry => 'Try saying';

  @override
  String get words => 'Words';

  @override
  String get wordsIntro =>
      'A single shape is ambiguous. A run of shapes is much less so — this is how lip reading actually works.';

  @override
  String get wordsGreetings => 'Greetings';

  @override
  String get wordsNumbers => 'Numbers';

  @override
  String get wordsEmergency => 'Emergency';

  @override
  String get wordsEveryday => 'Everyday';

  @override
  String wordShapes(int count) {
    return '$count shapes';
  }

  @override
  String get wordSayIt => 'Mouth this word';

  @override
  String wordNextShape(String shape) {
    return 'Next shape: $shape';
  }

  @override
  String get wordComplete => 'Word complete';

  @override
  String get wordExpired => 'Time up — try again';

  @override
  String get wordEnglishOnly =>
      'The word library is English. Other scripts need their own shape rules.';

  @override
  String get about => 'About';

  @override
  String get aboutWhat => 'What this app can and cannot do';

  @override
  String get aboutCan =>
      'It reads five mouth shapes in real time, entirely on the phone, with no internet connection at any point.';

  @override
  String get aboutCannot =>
      'It is not speech recognition. It reports shapes, not words, and it cannot tell letters apart that the lips make identically.';

  @override
  String get aboutPrivacy => 'Privacy';

  @override
  String get aboutPrivacyBody =>
      'No camera frame ever leaves the phone. The app contains no networking code at all, and asks for one permission: the camera.';

  @override
  String a11yWordShape(int position, int total, String shape) {
    return 'Shape $position of $total: $shape';
  }
}
