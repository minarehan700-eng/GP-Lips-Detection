import 'dart:async'; // Future و async

import 'package:camera/camera.dart'; // الكاميرا
import 'package:flutter/services.dart'; // PlatformException

import '../application/lip_letter_detector.dart'; // كاشف الحروف
import '../application/lipsing_detector.dart'; // كاشف lipsing
import '../core/detector_settings.dart'; // إعدادات الكاشف
import '../domain/face_lips_result.dart'; // نتيجة الوجه
import '../infrastructure/camera_frame_encoder.dart'; // تحويل الإطار لـ JPEG
import '../infrastructure/mediapipe_face_landmark_extractor.dart'; // MediaPipe

/// يدير الكاميرا ومعالجة الإطارات وحالة الكاشفات للشاشة الرئيسية.
class LipsCameraSession { // جلسة كاميرا + كشف فم
  LipsCameraSession({ // مُنشئ (يمكن حقن extractor/encoder للاختبار)
    MediaPipeFaceLandmarkExtractor? extractor, //
    CameraFrameEncoder? encoder, //
  })  : _extractor = extractor ?? MediaPipeFaceLandmarkExtractor(), // MediaPipe افتراضي
        _encoder = encoder ?? CameraFrameEncoder(); // Encoder افتراضي

  final MediaPipeFaceLandmarkExtractor _extractor; // جسر MediaPipe
  final CameraFrameEncoder _encoder; // محوّل JPEG

  LipsingDetector _lipsingDetector = LipsingDetector(); // كاشف lipsing
  LipLetterDetector _lipLetterDetector = LipLetterDetector(); // كاشف الحروف

  CameraController? camera; // متحكم الكاميرا (nullable قبل التهيئة)
  String? cameraResolutionLabel; // نص يعرض دقة الكاميرا
  bool isFrontCamera = true; // هل الكاميرا الأمامية؟
  int frameImageWidth = 0; // عرض آخر إطار
  int frameImageHeight = 0; // ارتفاع آخر إطار

  String initPhase = 'Starting...'; // مرحلة التهيئة للعرض
  String? error; // رسالة خطأ إن وجدت
  FaceLipsResult result = FaceLipsResult.empty; // آخر نتيجة كشف

  bool _isProcessing = false; // هل نعالج إطاراً الآن؟ (منع التزامن)
  DateTime _lastProcessed = DateTime.fromMillisecondsSinceEpoch(0); // وقت آخر إطار

  Future<void> applyDetectorSettings() async { // تحميل الإعدادات وإنشاء كاشفات جديدة
    final settings = await DetectorSettings.load(); // من SharedPreferences
    _lipsingDetector = LipsingDetector( // كاشف lipsing بإعدادات المستخدم
      mouthOpenThreshold: settings.mouthOpenThreshold, //
      motionThreshold: settings.motionThreshold, //
    ); //
    _lipLetterDetector = LipLetterDetector(minScore: settings.letterMinScore); // كاشف حروف
  } // نهاية applyDetectorSettings

  Future<void> initialize(void Function() onUpdate) async { // تهيئة كاملة
    try { // محاولة التهيئة
      initPhase = 'Loading settings...'; // مرحلة 1
      onUpdate(); // أخبر الواجهة
      await applyDetectorSettings(); // حمّل الإعدادات

      initPhase = 'Loading face landmarker...'; // مرحلة 2
      onUpdate(); //
      await _extractor.initialize(); // MediaPipe على Android

      initPhase = 'Starting camera...'; // مرحلة 3
      onUpdate(); //

      final cams = await availableCameras(); // قائمة الكاميرات
      if (cams.isEmpty) { // لا كاميرا
        error = 'No camera found on this device.'; //
        return; //
      } // نهاية if empty

      final cam = cams.firstWhere( // اختر الكاميرا الأمامية
        (c) => c.lensDirection == CameraLensDirection.front, //
        orElse: () => cams.first, // أو الأولى المتاحة
      ); //

      final controller = await _openCamera(cam); // افتح الكاميرا
      if (controller == null) { // فشل
        error = 'Failed to initialize camera at any supported resolution.'; //
        return; //
      } // نهاية if null

      await controller.startImageStream((image) => _onFrame(image, onUpdate)); // بث الإطارات
      final previewSize = controller.value.previewSize; // حجم المعاينة
      camera = controller; // احفظ المتحكم
      isFrontCamera = cam.lensDirection == CameraLensDirection.front; //
      cameraResolutionLabel = previewSize != null // نص الدقة
          ? 'Camera: ${previewSize.width.toInt()}×${previewSize.height.toInt()}' //
          : null; //
      initPhase = 'Ready'; // جاهز
      error = null; // بدون خطأ
      onUpdate(); // حدّث الواجهة
    } on PlatformException catch (e) { // خطأ منصة (صلاحيات مثلاً)
      error = e.message ?? e.code; //
      onUpdate(); //
    } catch (e) { // أي خطأ آخر
      error = e.toString(); //
      onUpdate(); //
    } // نهاية try-catch
  } // نهاية initialize

  Future<CameraController?> _openCamera(CameraDescription cam) async { // محاولة دقات متعددة
    const presets = [ // قائمة الدقات من الأعلى للأقل
      ResolutionPreset.veryHigh, //
      ResolutionPreset.high, //
      ResolutionPreset.medium, //
    ]; //
    for (final preset in presets) { // جرّب كل preset
      final candidate = CameraController( // متحكم جديد
        cam, //
        preset, //
        enableAudio: false, // بدون صوت
        imageFormatGroup: ImageFormatGroup.yuv420, // YUV420 للمعالجة
      ); //
      try { //
        await candidate.initialize(); // تهيئة
        return candidate; // نجح — أرجعه
      } catch (_) { //
        await candidate.dispose(); // فشل — نظّف
      } //
    } //
    return null; // كل المحاولات فشلت
  } // نهاية _openCamera

  Future<void> _onFrame(CameraImage image, void Function() onUpdate) async { // معالجة إطار
    if (_isProcessing) return; // تجاهل إذا مشغول
    final now = DateTime.now(); // الوقت الآن
    if (now.difference(_lastProcessed).inMilliseconds < 150) return; // حد ~6-7 fps
    _lastProcessed = now; //
    _isProcessing = true; //

    try { //
      final jpeg = await _encoder.encodeToJpeg(image, quality: 92); // JPEG للـ native
      if (jpeg == null) return; //

      final raw = await _extractor.processFrame( // MediaPipe
        bytes: jpeg, //
        width: image.width, //
        height: image.height, //
        rotation: 0, //
      ); //
      final lipsing = _lipsingDetector.update(raw); // lipsing
      result = _lipLetterDetector.update(lipsing); // حرف A-E
      frameImageWidth = image.width; //
      frameImageHeight = image.height; //
      onUpdate(); // حدّث الشاشة
    } finally { //
      _isProcessing = false; // حرّر القفل
    } //
  } // نهاية _onFrame

  Future<void> reset(void Function() onUpdate) async { // إعادة تشغيل الجلسة
    await camera?.dispose(); // أغلق الكاميرا
    camera = null; //
    cameraResolutionLabel = null; //
    _lipsingDetector.reset(); //
    _lipLetterDetector.reset(); //
    error = null; //
    initPhase = 'Starting...'; //
    result = FaceLipsResult.empty; //
    onUpdate(); //
    await initialize(onUpdate); // ابدأ من جديد
  } // نهاية reset

  Future<void> dispose() async { // تنظيف عند إغلاق الشاشة
    await camera?.dispose(); //
    camera = null; //
  } // نهاية dispose
} // نهاية LipsCameraSession
