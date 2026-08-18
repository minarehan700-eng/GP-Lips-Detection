import '../domain/face_lips_result.dart'; // كلاس نتيجة الوجه والفم

/// كاشف lipsing يعتمد على تاريخ قيم الفم — يمنع الوميض بتأخير بسيط (hysteresis).
class LipsingDetector { // يحدد هل المستخدم يقوم بـ lipsing (حركة فم نشطة)
  LipsingDetector({ // مُنشئ مع قيم افتراضية قابلة للتعديل
    this.historySize = 8, // عدد العينات المحفوظة في الذاكرة
    this.mouthOpenThreshold = 0.25, // حد فتح الفم لاعتبار lipsing
    this.motionThreshold = 0.035, // حد متوسط الحركة بين الإطارات
    this.hysteresisFrames = 3, // عدد الإطارات قبل تغيير حالة Yes/No
  }); // نهاية المُنشئ

  final int historySize; // حجم التاريخ
  final double mouthOpenThreshold; // حد الفتح
  final double motionThreshold; // حد الحركة
  final int hysteresisFrames; // إطارات الـ hysteresis

  final List<_MouthSample> _history = <_MouthSample>[]; // قائمة عينات الفم السابقة
  bool _isLipsing = false; // الحالة الحالية: هل lipsing؟
  int _onCount = 0; // عداد إطارات "نشط"
  int _offCount = 0; // عداد إطارات "غير نشط"

  bool get isLipsing => _isLipsing; // getter للحالة الحالية

  FaceLipsResult update(FaceLipsResult raw) { // تحديث الحالة بإطار جديد
    if (!raw.faceDetected) { // إذا لا يوجد وجه
      _history.clear(); // امسح التاريخ
      _onCount = 0; // صفّر عداد ON
      _offCount++; // زِد عداد OFF
      if (_offCount >= hysteresisFrames) { // إذا OFF كافٍ
        _isLipsing = false; // أوقف lipsing
        _offCount = 0; // صفّر العداد
      } // نهاية if off
      return raw.copyWith(isLipsing: _isLipsing); // أرجع النتيجة مع حالة lipsing
    } // نهاية if no face

    final sample = _MouthSample( // حفظ عينة من هذا الإطار
      mouthOpen: raw.mouthOpen, // فتح الفم
      mouthPucker: raw.mouthPucker, // pucker
      smile: raw.smile, // ابتسام
    ); // نهاية _MouthSample
    _history.add(sample); // أضف للتاريخ
    while (_history.length > historySize) { // إذا تجاوزنا الحجم
      _history.removeAt(0); // احذف أقدم عينة
    } // نهاية while

    final openEnough = raw.mouthOpen > mouthOpenThreshold; // هل الفم مفتوح بما يكفي؟
    final motionEnough = _averageMouthDelta() > motionThreshold; // هل الحركة كافية؟
    final active = openEnough || motionEnough; // نشط إذا فتح أو حركة

    if (active) { // إذا الإطار نشط
      _onCount++; // زِد ON
      _offCount = 0; // صفّر OFF
      if (_onCount >= hysteresisFrames || raw.mouthOpen > mouthOpenThreshold * 1.4) { // تأكيد أو فتح قوي
        _isLipsing = true; // فعّل lipsing
      } // نهاية if confirm
    } else { // إذا الإطار غير نشط
      _offCount++; // زِد OFF
      _onCount = 0; // صفّر ON
      if (_offCount >= hysteresisFrames) { // إذا OFF كافٍ
        _isLipsing = false; // أوقف lipsing
      } // نهاية if off
    } // نهاية if-else active

    return raw.copyWith(isLipsing: _isLipsing); // أرجع النتيجة المحدّثة
  } // نهاية update

  void reset() { // إعادة تعيين الكاشف
    _history.clear(); // امسح التاريخ
    _isLipsing = false; // أوقف lipsing
    _onCount = 0; // صفّر العدادات
    _offCount = 0; //
  } // نهاية reset

  double _averageMouthDelta() { // حساب متوسط التغير بين الإطارات
    if (_history.length < 2) return 0; // نحتاج إطارين على الأقل
    var sum = 0.0; // مجموع الفروقات
    var count = 0; // عدد المقارنات
    for (var i = 1; i < _history.length; i++) { // من الإطار الثاني
      final prev = _history[i - 1]; // الإطار السابق
      final curr = _history[i]; // الإطار الحالي
      sum += (curr.mouthOpen - prev.mouthOpen).abs(); // فرق فتح الفم
      sum += (curr.mouthPucker - prev.mouthPucker).abs() * 0.5; // فرق pucker (وزن أقل)
      sum += (curr.smile - prev.smile).abs() * 0.35; // فرق ابتسام (وزن أقل)
      count++; // زِد العداد
    } // نهاية for
    if (count == 0) return 0; // لا مقارنات
    return sum / count; // المتوسط
  } // نهاية _averageMouthDelta
} // نهاية LipsingDetector

class _MouthSample { // عينة بسيطة لقيم الفم في إطار واحد
  const _MouthSample({ // مُنشئ
    required this.mouthOpen, // فتح الفم
    required this.mouthPucker, // pucker
    required this.smile, // ابتسام
  }); // نهاية المُنشئ

  final double mouthOpen; // قيمة فتح الفم
  final double mouthPucker; // قيمة pucker
  final double smile; // قيمة الابتسام
} // نهاية _MouthSample
