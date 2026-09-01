// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Lips Offline';

  @override
  String get brandName => 'Lips';

  @override
  String get splashTagline => 'اكتشاف النطق الصامت وحروف الفم من A إلى E';

  @override
  String get onboardLipsingTitle => 'ما هو النطق الصامت؟';

  @override
  String get onboardLipsingBody =>
      'النطق الصامت هو تحريك الشفاه بالكلمات دون صوت، وهو شائع في لغة الإشارة. يراقب هذا التطبيق شكل فمك لحظة بلحظة ويخبرك عند اكتشاف النطق الصامت.';

  @override
  String get onboardLipsingPoint1 => 'يجب أن يكون وجهك ظاهرًا أمام الكاميرا';

  @override
  String get onboardLipsingPoint2 => 'المربع الأخضر يحدد منطقة الفم';

  @override
  String get onboardLipsingPoint3 =>
      '«النطق الصامت: نعم» تعني وجود حركة نشطة للفم';

  @override
  String get onboardLettersTitle => 'الحروف A – E';

  @override
  String get onboardLettersBody =>
      'يتتبع MediaPipe معالم الفم ويحوّل أشكاله إلى حروف نطق من A إلى E.';

  @override
  String get onboardLetterA => 'A — فم مفتوح على اتساعه';

  @override
  String get onboardLetterB => 'B — شفتان مغلقتان';

  @override
  String get onboardLetterC => 'C — شفتان مستديرتان';

  @override
  String get onboardLetterD => 'D — فتحة صغيرة';

  @override
  String get onboardLetterE => 'E — شكل الابتسامة';

  @override
  String get onboardCameraTitle => 'استخدام الكاميرا';

  @override
  String get onboardCameraBody =>
      'أمسك الهاتف على مستوى العين، وواجه الكاميرا الأمامية، واحرص على إضاءة جيدة.';

  @override
  String get onboardCameraPoint1 => 'اضغط على حرف لتختاره هدفًا للتدريب';

  @override
  String get onboardCameraPoint2 =>
      'عدّل الحدود من الإعدادات إذا لم يكن الاكتشاف دقيقًا';

  @override
  String get onboardCameraPoint3 => 'يعمل بالكامل دون إنترنت';

  @override
  String get skip => 'تخطٍ';

  @override
  String get next => 'التالي';

  @override
  String get getStarted => 'لنبدأ';

  @override
  String get homeTitle => 'اكتشاف الشفاه';

  @override
  String get settings => 'الإعدادات';

  @override
  String get face => 'الوجه';

  @override
  String get detected => 'مُكتشَف';

  @override
  String get notDetected => 'غير مُكتشَف';

  @override
  String get lipsing => 'النطق الصامت';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get letterShapeHint =>
      'ابتسامة=E · استدارة=C · إغلاق=B · فتح واسع=A · فتح بسيط=D';

  @override
  String get detectedLetter => 'الحرف المُكتشَف';

  @override
  String confidencePercent(int percent) {
    return 'نسبة الثقة $percent٪';
  }

  @override
  String get matched => 'تطابق!';

  @override
  String get practiceTarget => 'هدف التدريب';

  @override
  String get mouthOpen => 'انفتاح الفم';

  @override
  String get pucker => 'ضم الشفتين';

  @override
  String get smile => 'الابتسامة';

  @override
  String get closeShape => 'إغلاق الشفتين';

  @override
  String get funnel => 'استدارة الشفتين';

  @override
  String get stretch => 'مط الشفتين';

  @override
  String percentValue(int percent) {
    return '$percent٪';
  }

  @override
  String cameraResolution(int width, int height) {
    return 'الكاميرا: $width×$height';
  }

  @override
  String get detectorThresholds => 'حدود الاكتشاف';

  @override
  String get mouthOpenThreshold => 'حد انفتاح الفم';

  @override
  String get mouthOpenThresholdHelp =>
      'كلما زاد، لزم فتح الفم أكثر ليُحتسب نطقًا صامتًا';

  @override
  String get motionThreshold => 'حد الحركة';

  @override
  String get motionThresholdHelp =>
      'كلما قل، احتُسبت الحركات الصغيرة نطقًا صامتًا';

  @override
  String get letterMinScore => 'أدنى درجة للحرف';

  @override
  String get letterMinScoreHelp => 'كلما زاد، صار تصنيف A–E أكثر صرامة';

  @override
  String get saveSettings => 'حفظ الإعدادات';

  @override
  String get settingsSaved => 'تم حفظ الإعدادات';

  @override
  String get resetDefaults => 'استعادة الإعدادات الافتراضية';

  @override
  String get language => 'اللغة';

  @override
  String get languageSystem => 'حسب لغة الجهاز';

  @override
  String get errorNoCamera => 'لا توجد كاميرا في هذا الجهاز.';

  @override
  String get errorCameraInit => 'تعذّر تشغيل الكاميرا بأي دقة مدعومة.';

  @override
  String get errorLandmarkerMissing =>
      'تعذّر تحميل نموذج معالم الوجه. تأكد من وجود الملف face_landmarker.task داخل android/app/src/main/assets (وداخل حزمة iOS Runner).';

  @override
  String errorInitFailed(String error) {
    return 'فشل بدء التشغيل:\n$error\n\nتأكد من إرفاق ملف النموذج ومن منح إذن الكاميرا.';
  }

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get a11yOpenSettings => 'فتح الإعدادات';

  @override
  String get a11yCameraPreview =>
      'معاينة مباشرة من الكاميرا، ويجري تتبع فمك هنا.';

  @override
  String a11yLetterChip(String letter) {
    return 'الحرف $letter. انقر مرتين للتدرب عليه.';
  }

  @override
  String a11yLetterChipSelected(String letter) {
    return 'الحرف $letter، وهو هدف تدريبك الحالي. انقر مرتين لإيقاف التدرب عليه.';
  }

  @override
  String a11yAnnounceLetter(String letter, int percent) {
    return 'اكتُشف الحرف $letter بنسبة ثقة $percent بالمئة';
  }

  @override
  String a11yAnnounceMatched(String letter) {
    return 'تطابق الحرف $letter';
  }

  @override
  String get a11yAnnounceFaceLost => 'لم يعد الوجه ظاهرًا';

  @override
  String get a11yAnnounceFaceFound => 'تم اكتشاف الوجه';

  @override
  String get haptics => 'اهتزاز عند التطابق';

  @override
  String get hapticsHelp =>
      'يهتز الهاتف عندما يطابق شكل فمك الحرف الذي تتدرب عليه';

  @override
  String get announceDetections => 'نطق الاكتشافات بصوت عالٍ';

  @override
  String get announceDetectionsHelp => 'يرسل كل حرف مُكتشَف إلى قارئ الشاشة';

  @override
  String get practice => 'التدريب';

  @override
  String get practiceStart => 'ابدأ جولة';

  @override
  String get practiceMakeShape => 'كوّن هذا الشكل';

  @override
  String get practiceHold => 'استمر…';

  @override
  String get practiceGotIt => 'أحسنت!';

  @override
  String get practiceMissed => 'لم يُضبط — ننتقل';

  @override
  String practiceProgress(int done, int total) {
    return '$done من $total';
  }

  @override
  String practiceScore(int hits, int total) {
    return 'ضبطت $hits من $total';
  }

  @override
  String practiceBestStreak(int streak) {
    return 'أطول سلسلة: $streak';
  }

  @override
  String get practiceAgain => 'تدرب مرة أخرى';

  @override
  String get practiceDone => 'انتهت الجولة';

  @override
  String practiceNearMiss(String letter) {
    return 'كنت قريبًا من $letter';
  }

  @override
  String get progress => 'تقدمك';

  @override
  String get progressNone => 'لا توجد جولات بعد. أنهِ جولة وستظهر نتائجك هنا.';

  @override
  String get progressPerLetter => 'أداؤك في كل حرف';

  @override
  String progressAttempts(int hits, int attempts) {
    return '$hits/$attempts';
  }

  @override
  String get progressUntried => 'لم تُجرَّب بعد';

  @override
  String progressWeakest(String letter) {
    return 'يستحق التدريب: $letter';
  }

  @override
  String progressRounds(int count) {
    return '$count جولة محفوظة';
  }

  @override
  String get progressClear => 'مسح السجل';

  @override
  String get progressCleared => 'تم مسح السجل';

  @override
  String a11yPracticeTarget(String letter) {
    return 'كوّن شكل الحرف $letter';
  }

  @override
  String a11yPracticeHeld(String letter) {
    return 'تم ضبط الحرف $letter';
  }

  @override
  String a11yPracticeMissed(String letter) {
    return 'فاتك الحرف $letter';
  }

  @override
  String get chart => 'دليل الأشكال';

  @override
  String get chartIntro =>
      'خمسة أشكال تغطي الأبجدية كاملة. الشكل ليس حرفًا واحدًا، بل كل الحروف التي تبدو متطابقة على الشفاه.';

  @override
  String get chartWhySame => 'لماذا تشترك P وB وM في شكل واحد';

  @override
  String get chartWhySameBody =>
      'تُنطق في مواضع مختلفة داخل الفم، لكن الشفاه تفعل الشيء نفسه تمامًا. لا كاميرا تستطيع التفريق بينها. قراءة الشفاه تعتمد على السياق للاختيار بينها، ولهذا قراءة الكلمات أسهل من الحروف.';

  @override
  String get chartLetters => 'الحروف';

  @override
  String get chartTry => 'جرّب أن تقول';

  @override
  String get words => 'الكلمات';

  @override
  String get wordsIntro =>
      'الشكل الواحد غامض، أما تتابع الأشكال فأوضح بكثير — وهكذا تعمل قراءة الشفاه فعلاً.';

  @override
  String get wordsGreetings => 'التحيات';

  @override
  String get wordsNumbers => 'الأرقام';

  @override
  String get wordsEmergency => 'الطوارئ';

  @override
  String get wordsEveryday => 'يومية';

  @override
  String wordShapes(int count) {
    return '$count أشكال';
  }

  @override
  String get wordSayIt => 'انطق هذه الكلمة بصمت';

  @override
  String wordNextShape(String shape) {
    return 'الشكل التالي: $shape';
  }

  @override
  String get wordComplete => 'اكتملت الكلمة';

  @override
  String get wordExpired => 'انتهى الوقت — حاول مجددًا';

  @override
  String get wordEnglishOnly =>
      'مكتبة الكلمات بالإنجليزية. اللغات ذات الحروف الأخرى تحتاج قواعد أشكال خاصة بها.';

  @override
  String get about => 'حول التطبيق';

  @override
  String get aboutWhat => 'ما يستطيعه هذا التطبيق وما لا يستطيعه';

  @override
  String get aboutCan =>
      'يقرأ خمسة أشكال للفم لحظيًا، بالكامل على الهاتف، ودون أي اتصال بالإنترنت.';

  @override
  String get aboutCannot =>
      'ليس تعرفًا على الكلام. يبلّغ عن أشكال لا كلمات، ولا يميّز بين حروف تصنعها الشفاه بالشكل نفسه.';

  @override
  String get aboutPrivacy => 'الخصوصية';

  @override
  String get aboutPrivacyBody =>
      'لا تغادر أي لقطة من الكاميرا الهاتف أبدًا. لا يحتوي التطبيق على أي كود شبكة، ويطلب إذنًا واحدًا فقط: الكاميرا.';

  @override
  String a11yWordShape(int position, int total, String shape) {
    return 'الشكل $position من $total: $shape';
  }
}
