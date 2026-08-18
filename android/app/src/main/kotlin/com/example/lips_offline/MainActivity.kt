package com.example.lips_offline // اسم الحزمة (package) للتطبيق

import android.os.Handler // Handler للتشغيل على الخيط الرئيسي
import android.os.Looper // Looper للخيط الرئيسي
import io.flutter.embedding.android.FlutterActivity // نشاط Flutter الأساسي
import io.flutter.embedding.engine.FlutterEngine // محرك Flutter
import io.flutter.plugin.common.MethodChannel // قناة التواصل مع Dart
import java.util.concurrent.Executors // Executor للعمل في الخلفية

class MainActivity : FlutterActivity() { // النشاط الرئيسي — يربط Flutter بـ MediaPipe
    private val faceChannelName = "lips/offline/face" // اسم القناة (يجب أن يطابق Dart)
    private lateinit var faceBridge: FaceLandmarkerBridge // جسر MediaPipe
    private val faceFrameExecutor = Executors.newSingleThreadExecutor() // خيط واحد لمعالجة الإطارات
    private val mainHandler = Handler(Looper.getMainLooper()) // Handler للعودة للخيط الرئيسي

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) { // تهيئة القناة عند بدء المحرك
        super.configureFlutterEngine(flutterEngine) // استدعاء الأب
        faceBridge = FaceLandmarkerBridge(this) // إنشاء الجسر

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, faceChannelName) // إنشاء MethodChannel
            .setMethodCallHandler { call, result -> // معالج استدعاءات Dart
                when (call.method) { // حسب اسم الدالة
                    "initializeFaceLandmarker" -> { // تهيئة Face Landmarker
                        // MediaPipe يجب أن يُهيّأ على الخيط الرئيسي (تجنب crash على Android 15/16)
                        mainHandler.post { // نشر على main thread
                            if (isFinishing) { // إذا النشاط يُغلق
                                result.error("init_failed", "Activity is finishing", null) // خطأ
                                return@post // خروج
                            } // نهاية if
                            try { // محاولة التهيئة
                                faceBridge.initialize() // تهيئة MediaPipe
                                result.success(null) // نجاح
                            } catch (e: Exception) { // خطأ
                                result.error( // إرجاع خطأ لـ Dart
                                    "init_failed", //
                                    "Failed to initialize face landmarker. Ensure android/app/src/main/assets/face_landmarker.task exists. Root error: ${e.message}", //
                                    null //
                                ) // نهاية error
                            } // نهاية try-catch
                        } // نهاية post
                    } // نهاية initializeFaceLandmarker
                    "isFaceLandmarkerInitialized" -> { // هل تم التهيئة؟
                        result.success(faceBridge.isInitialized()) // true/false
                    } // نهاية isFaceLandmarkerInitialized
                    "processFaceFrame" -> { // معالجة إطار JPEG
                        if (!faceBridge.isInitialized()) { // غير مهيّأ
                            result.success(emptyFacePayload()) // نتيجة فارغة
                            return@setMethodCallHandler // خروج
                        } // نهاية if

                        val bytes = call.argument<ByteArray>("bytes") // بايتات JPEG من Dart
                        if (bytes == null) { // مفقود
                            result.error("bad_args", "Missing frame bytes", null) //
                            return@setMethodCallHandler //
                        } // نهاية if

                        faceFrameExecutor.execute { // معالجة في خيط خلفي
                            val payload = try { // محاولة
                                faceBridge.processFrame(bytes) // MediaPipe detect
                            } catch (_: Exception) { //
                                emptyFacePayload() // فارغ عند الخطأ
                            } // نهاية try
                            if (!isFinishing) { // إذا النشاط ما زال حياً
                                mainHandler.post { result.success(payload) } // أرجع النتيجة على main
                            } // نهاية if
                        } // نهاية execute
                    } // نهاية processFaceFrame
                    else -> result.notImplemented() // دالة غير معروفة
                } // نهاية when
            } // نهاية setMethodCallHandler
    } // نهاية configureFlutterEngine

    override fun onDestroy() { // عند تدمير النشاط
        faceFrameExecutor.shutdown() // إيقاف executor
        if (::faceBridge.isInitialized) { // إذا الجسر موجود
            faceBridge.close() // إغلاق MediaPipe
        } // نهاية if
        super.onDestroy() // استدعاء الأب
    } // نهاية onDestroy

    private fun emptyFacePayload(): Map<String, Any> = mapOf( // خريطة نتيجة فارغة
        "faceDetected" to false, //
        "mouthOpen" to 0.0, //
        "mouthPucker" to 0.0, //
        "smile" to 0.0, //
        "mouthClose" to 0.0, //
        "mouthFunnel" to 0.0, //
        "mouthStretch" to 0.0, //
        "mouthMinX" to 0.0, //
        "mouthMinY" to 0.0, //
        "mouthMaxX" to 0.0, //
        "mouthMaxY" to 0.0, //
        "ts" to System.currentTimeMillis() // وقت الآن
    ) // نهاية mapOf
} // نهاية MainActivity
