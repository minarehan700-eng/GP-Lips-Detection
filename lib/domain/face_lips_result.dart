class FaceLipsResult { // كلاس يحمل نتائج كشف الوجه والفم من MediaPipe
  const FaceLipsResult({ // مُنشئ يأخذ كل القيم المطلوبة
    required this.faceDetected, // هل تم اكتشاف وجه؟
    required this.mouthOpen, // درجة فتح الفم (0 إلى 1)
    required this.mouthPucker, // درجة ضم الشفاه (pucker)
    required this.smile, // درجة الابتسام
    required this.isLipsing, // هل يحدث lipsing (حركة فم نشطة)؟
    required this.ts, // الطابع الزمني بالميلي ثانية
    this.mouthClose = 0, // درجة إغلاق الفم (افتراضي 0)
    this.mouthFunnel = 0, // شكل القمع للفم (افتراضي 0)
    this.mouthStretch = 0, // مد الشفاه (افتراضي 0)
    this.detectedLetter, // الحرف المكتشف A-E أو null
    this.letterConfidence = 0, // ثقة تصنيف الحرف (0 إلى 1)
    this.mouthMinX = 0, // أصغر X لمربع الفم (إحداثيات نسبية)
    this.mouthMinY = 0, // أصغر Y لمربع الفم
    this.mouthMaxX = 0, // أكبر X لمربع الفم
    this.mouthMaxY = 0, // أكبر Y لمربع الفم
  }); // نهاية المُنشئ

  static const empty = FaceLipsResult( // نتيجة فارغة عندما لا يوجد وجه
    faceDetected: false, // لا يوجد وجه
    mouthOpen: 0, // فم مغلق
    mouthPucker: 0, // بدون pucker
    smile: 0, // بدون ابتسام
    isLipsing: false, // بدون lipsing
    ts: 0, // بدون وقت
  ); // نهاية empty

  final bool faceDetected; // هل الوجه مكتشف
  final double mouthOpen; // قيمة فتح الفم
  final double mouthPucker; // قيمة ضم الشفاه
  final double smile; // قيمة الابتسام
  final double mouthClose; // قيمة إغلاق الفم
  final double mouthFunnel; // قيمة شكل القمع
  final double mouthStretch; // قيمة مد الشفاه
  final String? detectedLetter; // الحرف A-E أو null
  final double letterConfidence; // نسبة ثقة الحرف
  final bool isLipsing; // هل lipsing نشط
  final int ts; // وقت الإطار
  final double mouthMinX; // حد أيسر لمربع الفم
  final double mouthMinY; // حد أعلى لمربع الفم
  final double mouthMaxX; // حد أيمن لمربع الفم
  final double mouthMaxY; // حد أسفل لمربع الفم

  bool get hasMouthBox => // هل لدينا مربع فم صالح للرسم؟
      faceDetected && (mouthMaxX - mouthMinX) > 0.01 && (mouthMaxY - mouthMinY) > 0.01; // وجه + أبعاد كافية

  FaceLipsResult copyWith({ // إنشاء نسخة جديدة مع تغيير بعض الحقول
    bool? faceDetected, // وجه جديد (اختياري)
    double? mouthOpen, // فتح فم جديد
    double? mouthPucker, // pucker جديد
    double? smile, // ابتسام جديد
    double? mouthClose, // إغلاق جديد
    double? mouthFunnel, // funnel جديد
    double? mouthStretch, // stretch جديد
    String? detectedLetter, // حرف جديد
    bool clearDetectedLetter = false, // مسح الحرف المكتشف؟
    double? letterConfidence, // ثقة جديدة
    bool? isLipsing, // lipsing جديد
    int? ts, // وقت جديد
    double? mouthMinX, // حد X أيسر جديد
    double? mouthMinY, // حد Y أعلى جديد
    double? mouthMaxX, // حد X أيمن جديد
    double? mouthMaxY, // حد Y أسفل جديد
  }) { // بداية copyWith
    return FaceLipsResult( // إرجاع كائن جديد
      faceDetected: faceDetected ?? this.faceDetected, // استخدم الجديد أو القديم
      mouthOpen: mouthOpen ?? this.mouthOpen, // نفس المنطق لكل حقل
      mouthPucker: mouthPucker ?? this.mouthPucker, //
      smile: smile ?? this.smile, //
      mouthClose: mouthClose ?? this.mouthClose, //
      mouthFunnel: mouthFunnel ?? this.mouthFunnel, //
      mouthStretch: mouthStretch ?? this.mouthStretch, //
      detectedLetter: clearDetectedLetter ? null : (detectedLetter ?? this.detectedLetter), // مسح أو تحديث الحرف
      letterConfidence: letterConfidence ?? this.letterConfidence, //
      isLipsing: isLipsing ?? this.isLipsing, //
      ts: ts ?? this.ts, //
      mouthMinX: mouthMinX ?? this.mouthMinX, //
      mouthMinY: mouthMinY ?? this.mouthMinY, //
      mouthMaxX: mouthMaxX ?? this.mouthMaxX, //
      mouthMaxY: mouthMaxY ?? this.mouthMaxY, //
    ); // نهاية FaceLipsResult الجديد
  } // نهاية copyWith
} // نهاية كلاس FaceLipsResult
