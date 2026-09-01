import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// Application name, shown in the task switcher
  ///
  /// In en, this message translates to:
  /// **'Lips Offline'**
  String get appTitle;

  /// The animated word on the splash screen
  ///
  /// In en, this message translates to:
  /// **'Lips'**
  String get brandName;

  /// One-line description under the app name
  ///
  /// In en, this message translates to:
  /// **'Detect lipsing and mouth letters A–E'**
  String get splashTagline;

  /// No description provided for @onboardLipsingTitle.
  ///
  /// In en, this message translates to:
  /// **'What is lipsing?'**
  String get onboardLipsingTitle;

  /// No description provided for @onboardLipsingBody.
  ///
  /// In en, this message translates to:
  /// **'Lipsing is mouthing words without voice — common in sign language. This app watches your mouth shape in real time and tells you when lipsing is detected.'**
  String get onboardLipsingBody;

  /// No description provided for @onboardLipsingPoint1.
  ///
  /// In en, this message translates to:
  /// **'Face must be visible in the camera'**
  String get onboardLipsingPoint1;

  /// No description provided for @onboardLipsingPoint2.
  ///
  /// In en, this message translates to:
  /// **'Green box highlights your mouth region'**
  String get onboardLipsingPoint2;

  /// No description provided for @onboardLipsingPoint3.
  ///
  /// In en, this message translates to:
  /// **'“Lipsing: Yes” means active mouth movement'**
  String get onboardLipsingPoint3;

  /// No description provided for @onboardLettersTitle.
  ///
  /// In en, this message translates to:
  /// **'Letters A – E'**
  String get onboardLettersTitle;

  /// No description provided for @onboardLettersBody.
  ///
  /// In en, this message translates to:
  /// **'MediaPipe tracks mouth landmarks and maps shapes to viseme letters A through E.'**
  String get onboardLettersBody;

  /// No description provided for @onboardLetterA.
  ///
  /// In en, this message translates to:
  /// **'A — wide open mouth'**
  String get onboardLetterA;

  /// No description provided for @onboardLetterB.
  ///
  /// In en, this message translates to:
  /// **'B — lips closed'**
  String get onboardLetterB;

  /// No description provided for @onboardLetterC.
  ///
  /// In en, this message translates to:
  /// **'C — rounded / puckered lips'**
  String get onboardLetterC;

  /// No description provided for @onboardLetterD.
  ///
  /// In en, this message translates to:
  /// **'D — slightly open'**
  String get onboardLetterD;

  /// No description provided for @onboardLetterE.
  ///
  /// In en, this message translates to:
  /// **'E — smile shape'**
  String get onboardLetterE;

  /// No description provided for @onboardCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Using the camera'**
  String get onboardCameraTitle;

  /// No description provided for @onboardCameraBody.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone at eye level, face the front camera, and keep good lighting.'**
  String get onboardCameraBody;

  /// No description provided for @onboardCameraPoint1.
  ///
  /// In en, this message translates to:
  /// **'Tap a letter chip to set a practice target'**
  String get onboardCameraPoint1;

  /// No description provided for @onboardCameraPoint2.
  ///
  /// In en, this message translates to:
  /// **'Adjust thresholds in Settings if detection feels off'**
  String get onboardCameraPoint2;

  /// No description provided for @onboardCameraPoint3.
  ///
  /// In en, this message translates to:
  /// **'Works fully offline — no internet required'**
  String get onboardCameraPoint3;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Lips Detection'**
  String get homeTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @face.
  ///
  /// In en, this message translates to:
  /// **'Face'**
  String get face;

  /// No description provided for @detected.
  ///
  /// In en, this message translates to:
  /// **'Detected'**
  String get detected;

  /// No description provided for @notDetected.
  ///
  /// In en, this message translates to:
  /// **'Not detected'**
  String get notDetected;

  /// No description provided for @lipsing.
  ///
  /// In en, this message translates to:
  /// **'Lipsing'**
  String get lipsing;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @letterShapeHint.
  ///
  /// In en, this message translates to:
  /// **'Smile=E · Round=C · Closed=B · Wide open=A · Slight open=D'**
  String get letterShapeHint;

  /// No description provided for @detectedLetter.
  ///
  /// In en, this message translates to:
  /// **'Detected letter'**
  String get detectedLetter;

  /// How sure the classifier is about the current letter
  ///
  /// In en, this message translates to:
  /// **'{percent}% confidence'**
  String confidencePercent(int percent);

  /// No description provided for @matched.
  ///
  /// In en, this message translates to:
  /// **'Matched!'**
  String get matched;

  /// No description provided for @practiceTarget.
  ///
  /// In en, this message translates to:
  /// **'Practice target'**
  String get practiceTarget;

  /// No description provided for @mouthOpen.
  ///
  /// In en, this message translates to:
  /// **'Mouth open'**
  String get mouthOpen;

  /// No description provided for @pucker.
  ///
  /// In en, this message translates to:
  /// **'Pucker'**
  String get pucker;

  /// No description provided for @smile.
  ///
  /// In en, this message translates to:
  /// **'Smile'**
  String get smile;

  /// No description provided for @closeShape.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeShape;

  /// No description provided for @funnel.
  ///
  /// In en, this message translates to:
  /// **'Funnel'**
  String get funnel;

  /// No description provided for @stretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch'**
  String get stretch;

  /// A bare percentage shown inside a meter
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String percentValue(int percent);

  /// Preview size shown under the camera
  ///
  /// In en, this message translates to:
  /// **'Camera: {width}×{height}'**
  String cameraResolution(int width, int height);

  /// No description provided for @detectorThresholds.
  ///
  /// In en, this message translates to:
  /// **'Detector thresholds'**
  String get detectorThresholds;

  /// No description provided for @mouthOpenThreshold.
  ///
  /// In en, this message translates to:
  /// **'Mouth-open threshold'**
  String get mouthOpenThreshold;

  /// No description provided for @mouthOpenThresholdHelp.
  ///
  /// In en, this message translates to:
  /// **'Higher = mouth must open more to count as lipsing'**
  String get mouthOpenThresholdHelp;

  /// No description provided for @motionThreshold.
  ///
  /// In en, this message translates to:
  /// **'Motion threshold'**
  String get motionThreshold;

  /// No description provided for @motionThresholdHelp.
  ///
  /// In en, this message translates to:
  /// **'Lower = small mouth movement counts as lipsing'**
  String get motionThresholdHelp;

  /// No description provided for @letterMinScore.
  ///
  /// In en, this message translates to:
  /// **'Letter min-score'**
  String get letterMinScore;

  /// No description provided for @letterMinScoreHelp.
  ///
  /// In en, this message translates to:
  /// **'Higher = stricter A–E classification'**
  String get letterMinScoreHelp;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @resetDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get resetDefaults;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Use whatever language the phone is set to
  ///
  /// In en, this message translates to:
  /// **'Match my device'**
  String get languageSystem;

  /// No description provided for @errorNoCamera.
  ///
  /// In en, this message translates to:
  /// **'No camera found on this device.'**
  String get errorNoCamera;

  /// No description provided for @errorCameraInit.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize camera at any supported resolution.'**
  String get errorCameraInit;

  /// No description provided for @errorLandmarkerMissing.
  ///
  /// In en, this message translates to:
  /// **'The face landmarker could not be loaded. Make sure face_landmarker.task exists in android/app/src/main/assets (and the iOS Runner bundle).'**
  String get errorLandmarkerMissing;

  /// Fallback when start-up fails for a reason with no friendlier wording
  ///
  /// In en, this message translates to:
  /// **'Initialization failed:\n{error}\n\nMake sure the model file is bundled and camera permission is granted.'**
  String errorInitFailed(String error);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Screen-reader label for the toolbar gear
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get a11yOpenSettings;

  /// No description provided for @a11yCameraPreview.
  ///
  /// In en, this message translates to:
  /// **'Live camera preview. Your mouth is tracked here.'**
  String get a11yCameraPreview;

  /// No description provided for @a11yLetterChip.
  ///
  /// In en, this message translates to:
  /// **'Letter {letter}. Double tap to practise this letter.'**
  String a11yLetterChip(String letter);

  /// No description provided for @a11yLetterChipSelected.
  ///
  /// In en, this message translates to:
  /// **'Letter {letter}, currently your practice target. Double tap to stop practising it.'**
  String a11yLetterChipSelected(String letter);

  /// Spoken aloud when a new letter is recognised
  ///
  /// In en, this message translates to:
  /// **'Letter {letter} detected, {percent} percent confidence'**
  String a11yAnnounceLetter(String letter, int percent);

  /// No description provided for @a11yAnnounceMatched.
  ///
  /// In en, this message translates to:
  /// **'Matched letter {letter}'**
  String a11yAnnounceMatched(String letter);

  /// No description provided for @a11yAnnounceFaceLost.
  ///
  /// In en, this message translates to:
  /// **'Face no longer visible'**
  String get a11yAnnounceFaceLost;

  /// No description provided for @a11yAnnounceFaceFound.
  ///
  /// In en, this message translates to:
  /// **'Face detected'**
  String get a11yAnnounceFaceFound;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on a match'**
  String get haptics;

  /// No description provided for @hapticsHelp.
  ///
  /// In en, this message translates to:
  /// **'Buzz when your mouth shape matches the letter you are practising'**
  String get hapticsHelp;

  /// No description provided for @announceDetections.
  ///
  /// In en, this message translates to:
  /// **'Speak detections aloud'**
  String get announceDetections;

  /// No description provided for @announceDetectionsHelp.
  ///
  /// In en, this message translates to:
  /// **'Sends each detected letter to your screen reader'**
  String get announceDetectionsHelp;

  /// No description provided for @practice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practice;

  /// No description provided for @practiceStart.
  ///
  /// In en, this message translates to:
  /// **'Start a round'**
  String get practiceStart;

  /// No description provided for @practiceMakeShape.
  ///
  /// In en, this message translates to:
  /// **'Make this shape'**
  String get practiceMakeShape;

  /// No description provided for @practiceHold.
  ///
  /// In en, this message translates to:
  /// **'Hold it…'**
  String get practiceHold;

  /// No description provided for @practiceGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get practiceGotIt;

  /// No description provided for @practiceMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed — moving on'**
  String get practiceMissed;

  /// How far through a round
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String practiceProgress(int done, int total);

  /// No description provided for @practiceScore.
  ///
  /// In en, this message translates to:
  /// **'{hits} of {total} held'**
  String practiceScore(int hits, int total);

  /// No description provided for @practiceBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak: {streak}'**
  String practiceBestStreak(int streak);

  /// No description provided for @practiceAgain.
  ///
  /// In en, this message translates to:
  /// **'Practise again'**
  String get practiceAgain;

  /// No description provided for @practiceDone.
  ///
  /// In en, this message translates to:
  /// **'Round finished'**
  String get practiceDone;

  /// Shown when a missed letter still scored well
  ///
  /// In en, this message translates to:
  /// **'You were close on {letter}'**
  String practiceNearMiss(String letter);

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @progressNone.
  ///
  /// In en, this message translates to:
  /// **'No rounds yet. Finish one and your results appear here.'**
  String get progressNone;

  /// No description provided for @progressPerLetter.
  ///
  /// In en, this message translates to:
  /// **'How each letter is going'**
  String get progressPerLetter;

  /// hits out of attempts for one letter
  ///
  /// In en, this message translates to:
  /// **'{hits}/{attempts}'**
  String progressAttempts(int hits, int attempts);

  /// No description provided for @progressUntried.
  ///
  /// In en, this message translates to:
  /// **'not tried yet'**
  String get progressUntried;

  /// No description provided for @progressWeakest.
  ///
  /// In en, this message translates to:
  /// **'Worth practising: {letter}'**
  String progressWeakest(String letter);

  /// No description provided for @progressRounds.
  ///
  /// In en, this message translates to:
  /// **'{count} rounds saved'**
  String progressRounds(int count);

  /// No description provided for @progressClear.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get progressClear;

  /// No description provided for @progressCleared.
  ///
  /// In en, this message translates to:
  /// **'History cleared'**
  String get progressCleared;

  /// No description provided for @a11yPracticeTarget.
  ///
  /// In en, this message translates to:
  /// **'Make the shape for letter {letter}'**
  String a11yPracticeTarget(String letter);

  /// No description provided for @a11yPracticeHeld.
  ///
  /// In en, this message translates to:
  /// **'Letter {letter} held'**
  String a11yPracticeHeld(String letter);

  /// No description provided for @a11yPracticeMissed.
  ///
  /// In en, this message translates to:
  /// **'Letter {letter} missed'**
  String a11yPracticeMissed(String letter);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
