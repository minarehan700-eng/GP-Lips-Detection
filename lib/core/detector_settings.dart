import 'package:shared_preferences/shared_preferences.dart'; // مكتبة حفظ الإعدادات محلياً على الجهاز

class DetectorSettings { // كلاس يحفظ إعدادات كاشف lipsing والحروف
  const DetectorSettings({ // مُنشئ يأخذ كل القيم
    required this.mouthOpenThreshold, // حد فتح الفم لاعتبار lipsing
    required this.motionThreshold, // حد حركة الفم
    required this.letterMinScore, // أقل درجة لقبول حرف A-E
  }); // نهاية المُنشئ

  static const mouthOpenKey = 'mouth_open_threshold'; // مفتاح الحفظ لفتح الفم
  static const motionKey = 'motion_threshold'; // مفتاح الحفظ للحركة
  static const letterMinScoreKey = 'letter_min_score'; // مفتاح الحفظ لدرجة الحرف

  static const defaultMouthOpen = 0.25; // القيمة الافتراضية لفتح الفم
  static const defaultMotion = 0.035; // القيمة الافتراضية للحركة
  static const defaultLetterMinScore = 0.28; // القيمة الافتراضية لدرجة الحرف

  final double mouthOpenThreshold; // حد فتح الفم الحالي
  final double motionThreshold; // حد الحركة الحالي
  final double letterMinScore; // أقل درجة للحرف الحالية

  static const defaults = DetectorSettings( // إعدادات افتراضية جاهزة
    mouthOpenThreshold: defaultMouthOpen, // فتح فم افتراضي
    motionThreshold: defaultMotion, // حركة افتراضية
    letterMinScore: defaultLetterMinScore, // درجة حرف افتراضية
  ); // نهاية defaults

  static Future<DetectorSettings> load() async { // تحميل الإعدادات من الذاكرة المحلية
    final prefs = await SharedPreferences.getInstance(); // فتح SharedPreferences
    return DetectorSettings( // بناء كائن الإعدادات
      mouthOpenThreshold: prefs.getDouble(mouthOpenKey) ?? defaultMouthOpen, // قراءة أو افتراضي
      motionThreshold: prefs.getDouble(motionKey) ?? defaultMotion, // قراءة أو افتراضي
      letterMinScore: prefs.getDouble(letterMinScoreKey) ?? defaultLetterMinScore, // قراءة أو افتراضي
    ); // نهاية DetectorSettings
  } // نهاية load

  Future<void> save() async { // حفظ الإعدادات الحالية
    final prefs = await SharedPreferences.getInstance(); // فتح SharedPreferences
    await prefs.setDouble(mouthOpenKey, mouthOpenThreshold); // حفظ حد فتح الفم
    await prefs.setDouble(motionKey, motionThreshold); // حفظ حد الحركة
    await prefs.setDouble(letterMinScoreKey, letterMinScore); // حفظ حد الحرف
  } // نهاية save

  DetectorSettings copyWith({ // نسخة جديدة مع تغيير بعض القيم
    double? mouthOpenThreshold, // فتح فم جديد (اختياري)
    double? motionThreshold, // حركة جديدة
    double? letterMinScore, // درجة حرف جديدة
  }) { // بداية copyWith
    return DetectorSettings( // إرجاع كائن جديد
      mouthOpenThreshold: mouthOpenThreshold ?? this.mouthOpenThreshold, // جديد أو قديم
      motionThreshold: motionThreshold ?? this.motionThreshold, //
      letterMinScore: letterMinScore ?? this.letterMinScore, //
    ); // نهاية DetectorSettings
  } // نهاية copyWith
} // نهاية DetectorSettings
