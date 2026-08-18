import 'package:flutter/services.dart'; // MethodChannel للتواصل مع Android/iOS

import '../domain/face_lips_result.dart'; // كلاس نتيجة الوجه والفم

class MediaPipeFaceLandmarkExtractor { // جسر Flutter مع MediaPipe على Android
  static const MethodChannel _channel = MethodChannel('lips/offline/face'); // قناة التواصل مع Kotlin
  bool _initialized = false; // هل تم تهيئة Face Landmarker؟

  bool get isInitialized => _initialized; // getter للتحقق من التهيئة

  Future<void> initialize() async { // تهيئة MediaPipe على الجانب الأصلي (native)
    if (_initialized) return; // إذا مهيّأ مسبقاً لا تفعل شيء
    try { // محاولة التهيئة
      await _channel.invokeMethod('initializeFaceLandmarker'); // استدعاء Kotlin
      _initialized = true; // وضع علامة نجاح
    } on PlatformException catch (e) { // خطأ من المنصة
      throw Exception( // رمي استثناء واضح للمستخدم/المطور
        e.message ?? // رسالة الخطأ إن وجدت
            'Face landmarker failed to initialize (${e.code}). ' // رسالة افتراضية
                'Ensure face_landmarker.task exists in android/app/src/main/assets '
                '(and iOS Runner bundle).', // تذكير بملف النموذج
      ); // نهاية Exception
    } // نهاية catch
  } // نهاية initialize

  Future<FaceLipsResult> processFrame({ // معالجة إطار واحد وإرجاع نتائج الفم
    required Uint8List bytes, // بيانات JPEG للإطار
    required int width, // عرض الإطار
    required int height, // ارتفاع الإطار
    required int rotation, // دوران الإطار (0 عادة)
  }) async { // دالة async
    if (!_initialized || bytes.isEmpty || width <= 0 || height <= 0) { // تحقق من صحة المدخلات
      return FaceLipsResult( // نتيجة فارغة
        faceDetected: false, // لا وجه
        mouthOpen: 0, //
        mouthPucker: 0, //
        smile: 0, //
        isLipsing: false, //
        ts: DateTime.now().millisecondsSinceEpoch, // وقت الآن
      ); // نهاية FaceLipsResult
    } // نهاية if

    Map<String, dynamic>? response; // متغير لاستقبال الرد من Kotlin
    try { // محاولة المعالجة
      response = await _channel.invokeMapMethod<String, dynamic>( // استدعاء processFaceFrame
        'processFaceFrame', // اسم الدالة في Kotlin
        { // الخريطة المرسلة
          'bytes': bytes, // بايتات JPEG
          'width': width, // العرض
          'height': height, // الارتفاع
          'rotation': rotation, // الدوران
        }, // نهاية الخريطة
      ); // نهاية invokeMapMethod
    } on PlatformException { // خطأ من المنصة
      response = null; // اعتبر الرد فارغ
    } // نهاية catch

    if (response == null) { // إذا لم يرجع Kotlin شيء
      return FaceLipsResult( // نتيجة فارغة
        faceDetected: false, //
        mouthOpen: 0, //
        mouthPucker: 0, //
        smile: 0, //
        isLipsing: false, //
        ts: DateTime.now().millisecondsSinceEpoch, //
      ); // نهاية FaceLipsResult
    } // نهاية if null

    return FaceLipsResult( // بناء النتيجة من خريطة Kotlin
      faceDetected: response['faceDetected'] == true, // هل وجه؟
      mouthOpen: (response['mouthOpen'] as num?)?.toDouble() ?? 0, // فتح الفم
      mouthPucker: (response['mouthPucker'] as num?)?.toDouble() ?? 0, // pucker
      smile: (response['smile'] as num?)?.toDouble() ?? 0, // ابتسام
      mouthClose: (response['mouthClose'] as num?)?.toDouble() ?? 0, // إغلاق
      mouthFunnel: (response['mouthFunnel'] as num?)?.toDouble() ?? 0, // funnel
      mouthStretch: (response['mouthStretch'] as num?)?.toDouble() ?? 0, // stretch
      isLipsing: false, // lipsing يُحسب لاحقاً في Dart
      ts: (response['ts'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch, // الوقت
      mouthMinX: (response['mouthMinX'] as num?)?.toDouble() ?? 0, // مربع الفم
      mouthMinY: (response['mouthMinY'] as num?)?.toDouble() ?? 0, //
      mouthMaxX: (response['mouthMaxX'] as num?)?.toDouble() ?? 0, //
      mouthMaxY: (response['mouthMaxY'] as num?)?.toDouble() ?? 0, //
    ); // نهاية FaceLipsResult
  } // نهاية processFrame
} // نهاية MediaPipeFaceLandmarkExtractor
