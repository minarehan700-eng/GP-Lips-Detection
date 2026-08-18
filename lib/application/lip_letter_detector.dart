import 'dart:math' as math; // مكتبة رياضيات (max, clamp)

import '../domain/face_lips_result.dart'; // كلاس نتيجة الوجه والفم

/// مصنّف بسيط للحروف A–E من شكل الفم (viseme) باستخدام قواعد if.
class LipLetterDetector { // يحول blendshapes إلى حرف A أو B أو C أو D أو E
  LipLetterDetector({ // مُنشئ
    this.minScore = 0.28, // أقل درجة لقبول حرف
    this.hysteresisFrames = 2, // إطارات قبل تثبيت الحرف المعروض
    this.windowSize = 5, // عدد الإطارات للمتوسط (median)
  }); // نهاية المُنشئ

  static const supportedLetters = ['A', 'B', 'C', 'D', 'E']; // الحروف المدعومة

  final double minScore; // الحد الأدنى للدرجة
  final int hysteresisFrames; // إطارات hysteresis
  final int windowSize; // حجم النافذة الزمنية

  final List<_MouthFeatures> _window = []; // نافذة آخر قيم الفم

  String? _displayedLetter; // الحرف المعروض (مثبت)
  String? _candidateLetter; // الحرف المرشح الحالي
  int _candidateCount = 0; // كم إطار متتالي للمرشح

  FaceLipsResult update(FaceLipsResult raw) { // تحديث التصنيف بإطار جديد
    if (!raw.faceDetected) { // بدون وجه
      reset(); // أعد التعيين
      return raw.copyWith(clearDetectedLetter: true, letterConfidence: 0); // امسح الحرف
    } // نهاية if

    _pushFeature(_extractFeatures(raw)); // استخرج ميزات الفم وأضف للنافذة
    final feats = _medianFeatures(); // خذ median لتقليل الضوضاء
    final match = _classify(feats); // صنّف الحرف

    if (match == null) { // لا يطابق أي حرف
      _candidateLetter = null; // امسح المرشح
      _candidateCount = 0; //
      _displayedLetter = null; //
      return raw.copyWith(clearDetectedLetter: true, letterConfidence: 0); //
    } // نهاية if null

    final (letter, score) = match; // فك الحرف والدرجة

    if (letter == _candidateLetter) { // نفس المرشح السابق
      _candidateCount++; // زِد العداد
    } else { // مرشح جديد
      _candidateLetter = letter; // احفظ المرشح
      _candidateCount = 1; // ابدأ العد من 1
    } // نهاية if-else candidate

    if (_candidateCount >= hysteresisFrames) { // إذا ثبت المرشح
      _displayedLetter = letter; // ثبّت الحرف المعروض
    } // نهاية if hysteresis

    // نعرض أفضل حرف حي؛ hysteresis يثبت العرض عندما يتوفر
    return raw.copyWith( // أرجع النتيجة
      detectedLetter: _displayedLetter ?? letter, // المعروض أو الحي
      letterConfidence: score, // درجة الثقة
    ); // نهاية copyWith
  } // نهاية update

  void reset() { // إعادة تعيين
    _window.clear(); // امسح النافذة
    _displayedLetter = null; //
    _candidateLetter = null; //
    _candidateCount = 0; //
  } // نهاية reset

  _MouthFeatures _extractFeatures(FaceLipsResult raw) { // استخراج ميزات من النتيجة الخام
    final mouthW = math.max(raw.mouthMaxX - raw.mouthMinX, 0.01); // عرض الفم (حد أدنى 0.01)
    final mouthH = math.max(raw.mouthMaxY - raw.mouthMinY, 0.0); // ارتفاع الفم
    // نسبة الارتفاع/العرض؛ وزن هندسي منخفض
    final geoOpen = (mouthH / mouthW).clamp(0.0, 1.0); // فتح هندسي
    final open = (0.85 * raw.mouthOpen.clamp(0.0, 1.0) + 0.15 * geoOpen) // مزج blendshape + هندسة
        .clamp(0.0, 1.0); // تقييد 0-1

    return _MouthFeatures( // بناء كائن الميزات
      open: open, // فتح
      close: raw.mouthClose.clamp(0.0, 1.0), // إغلاق
      pucker: raw.mouthPucker.clamp(0.0, 1.0), // pucker
      funnel: raw.mouthFunnel.clamp(0.0, 1.0), // funnel
      stretch: raw.mouthStretch.clamp(0.0, 1.0), // stretch
      smile: raw.smile.clamp(0.0, 1.0), // ابتسام
    ); // نهاية _MouthFeatures
  } // نهاية _extractFeatures

  void _pushFeature(_MouthFeatures feature) { // إضافة ميزة للنافذة
    _window.add(feature); // أضف
    while (_window.length > windowSize) { // إذا تجاوزنا الحجم
      _window.removeAt(0); // احذف الأقدم
    } // نهاية while
  } // نهاية _pushFeature

  _MouthFeatures _medianFeatures() { // حساب median لكل ميزة
    if (_window.isEmpty) { // نافذة فارغة
      return const _MouthFeatures( // قيم صفر
        open: 0, //
        close: 0, //
        pucker: 0, //
        funnel: 0, //
        stretch: 0, //
        smile: 0, //
      ); // نهاية _MouthFeatures
    } // نهاية if empty

    double med(double Function(_MouthFeatures f) pick) { // دالة مساعدة للmedian
      final values = _window.map(pick).toList()..sort(); // جمع وترتيب
      final mid = values.length ~/ 2; // منتصف القائمة
      return values.length.isOdd // فردي أو زوجي
          ? values[mid] // عنصر الوسط
          : (values[mid - 1] + values[mid]) / 2; // متوسط عنصرين
    } // نهاية med

    return _MouthFeatures( // median لكل حقل
      open: med((f) => f.open), //
      close: med((f) => f.close), //
      pucker: med((f) => f.pucker), //
      funnel: med((f) => f.funnel), //
      stretch: med((f) => f.stretch), //
      smile: med((f) => f.smile), //
    ); // نهاية _MouthFeatures
  } // نهاية _medianFeatures

  /// أولوية حصرية: E ثم C ثم B ثم A ثم D
  (String, double)? _classify(_MouthFeatures f) { // تصنيف الحرف
    final round = math.max(f.pucker, f.funnel); // مدور = pucker أو funnel
    final smileWide = math.max(f.smile, f.stretch); // ابتسام/مد

    // 1) E — ابتسام أو مد (وليس pucker أقوى)
    if (smileWide >= 0.28 && smileWide >= round - 0.05) { //
      final score = _clamp01(smileWide); // درجة
      if (score >= minScore) return ('E', score); // حرف E
    } // نهاية E

    // 2) C — شفاه مدورة / pucker / funnel
    if (round >= 0.22) { //
      final score = _clamp01(round); //
      if (score >= minScore) return ('C', score); // حرف C
    } // نهاية C

    // 3) B — فم مغلق
    if (f.open <= 0.14 && (f.close >= 0.20 || f.open <= 0.10)) { //
      final score = _clamp01( // درجة الإغلاق
        math.max(f.close, 1.0 - f.open), //
      ); //
      if (score >= minScore) return ('B', score); // حرف B
    } // نهاية B

    // 4) A — فم مفتوح wide، بدون ابتسام/pucker قوي
    if (f.open >= 0.45 && smileWide < 0.28 && round < 0.22) { //
      final score = _clamp01(f.open); //
      if (score >= minScore) return ('A', score); // حرف A
    } // نهاية A

    // 5) D — فتح متوسط فقط إذا لم يطابق شيء أعلاه
    if (f.open >= 0.16 && f.open <= 0.44) { //
      final midStrength = 1.0 - ((f.open - 0.30).abs() / 0.14).clamp(0.0, 1.0); // قرب 0.30
      final score = _clamp01(midStrength * 0.85 + f.open * 0.15); // مزج
      if (score >= minScore) return ('D', score); // حرف D
    } // نهاية D

    return null; // لا حرف مناسب
  } // نهاية _classify

  static double _clamp01(double v) => v.clamp(0.0, 1.0); // تقييد بين 0 و 1
} // نهاية LipLetterDetector

class _MouthFeatures { // ميزات الفم المستخدمة في التصنيف
  const _MouthFeatures({ // مُنشئ
    required this.open, //
    required this.close, //
    required this.pucker, //
    required this.funnel, //
    required this.stretch, //
    required this.smile, //
  }); // نهاية المُنشئ

  final double open; // فتح
  final double close; // إغلاق
  final double pucker; // pucker
  final double funnel; // funnel
  final double stretch; // stretch
  final double smile; // ابتسام
} // نهاية _MouthFeatures
