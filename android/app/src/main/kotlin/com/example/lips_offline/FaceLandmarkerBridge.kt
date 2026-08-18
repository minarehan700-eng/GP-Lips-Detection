package com.example.lips_offline // اسم الحزمة

import android.content.Context // Context للوصول للأصول (assets)
import android.graphics.Bitmap // Bitmap للصورة
import android.graphics.BitmapFactory // فك JPEG إلى Bitmap
import com.google.mediapipe.framework.image.BitmapImageBuilder // تحويل Bitmap لصورة MediaPipe
import com.google.mediapipe.tasks.core.BaseOptions // خيارات النموذج
import com.google.mediapipe.tasks.vision.core.RunningMode // وضع التشغيل (IMAGE)
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker // Face Landmarker
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarkerResult // نتيجة الكشف
import java.io.ByteArrayInputStream // قراءة بايتات JPEG كـ stream

class FaceLandmarkerBridge(private val context: Context) { // جسر MediaPipe Face Landmarker
    private var faceLandmarker: FaceLandmarker? = null // كائن Landmarker (nullable قبل التهيئة)
    private val processLock = Any() // قفل للتزامن بين الخيوط

    fun isInitialized(): Boolean = synchronized(processLock) { faceLandmarker != null } // هل مهيّأ؟

    fun initialize(modelAssetPath: String = "face_landmarker.task") { // تحميل النموذج من assets
        synchronized(processLock) { // قفل
            if (faceLandmarker != null) return // مهيّأ مسبقاً

            // تحميل كلاس MediaPipe على هذا الخيط قبل أي عمل خلفي
            // BaseVisionTaskApi.<clinit> قد يسبب SIGSEGV على Android 16 إذا off-main
            Class.forName("com.google.mediapipe.tasks.vision.core.BaseVisionTaskApi") //

            // التحقق من وجود ملف النموذج
            context.assets.open(modelAssetPath).use { } //

            val baseOptions = BaseOptions.builder() // بناء BaseOptions
                .setModelAssetPath(modelAssetPath) // مسار النموذج في assets
                .build() //

            val options = FaceLandmarker.FaceLandmarkerOptions.builder() // خيارات Landmarker
                .setBaseOptions(baseOptions) //
                .setRunningMode(RunningMode.IMAGE) // وضع صورة واحدة (ليس فيديو)
                .setNumFaces(1) // وجه واحد فقط
                .setMinFaceDetectionConfidence(0.5f) // ثقة كشف الوجه
                .setMinFacePresenceConfidence(0.5f) // ثقة وجود الوجه
                .setMinTrackingConfidence(0.5f) // ثقة التتبع
                .setOutputFaceBlendshapes(true) // نريد blendshapes للفم
                .build() //
            faceLandmarker = FaceLandmarker.createFromOptions(context, options) // إنشاء Landmarker
        } // نهاية synchronized
    } // نهاية initialize

    fun processFrame(frameBytes: ByteArray): Map<String, Any> { // معالجة إطار JPEG
        if (frameBytes.isEmpty()) { //
            return emptyFaceResult() //
        } //

        synchronized(processLock) { //
            val landmarker = faceLandmarker ?: return emptyFaceResult() // Landmarker أو فارغ

            var bitmap: Bitmap? = null // Bitmap مؤقت
            try { //
                val decodeOptions = BitmapFactory.Options().apply { //
                    inPreferredConfig = Bitmap.Config.ARGB_8888 // صيغة ARGB
                } //
                bitmap = BitmapFactory.decodeStream(ByteArrayInputStream(frameBytes), null, decodeOptions) //
                    ?: return emptyFaceResult() // فشل فك JPEG
                if (bitmap.width <= 0 || bitmap.height <= 0) return emptyFaceResult() //

                val softwareBitmap = ensureSoftwareBitmap(bitmap) // تأكد ARGB software
                if (softwareBitmap !== bitmap) { //
                    bitmap.recycle() // تخلص من القديم
                    bitmap = softwareBitmap //
                } //

                val mpImage = BitmapImageBuilder(softwareBitmap).build() // صورة MediaPipe
                val result: FaceLandmarkerResult = landmarker.detect(mpImage) // كشف
                if (result.faceLandmarks().isEmpty()) { //
                    return emptyFaceResult() // لا وجه
                } //

                val blendshapes = extractBlendshapes(result) // استخراج blendshapes
                val mouthOpen = blendshapes["jawOpen"] ?: 0.0 // فتح الفك
                val mouthPucker = blendshapes["mouthPucker"] ?: 0.0 //
                val smileLeft = blendshapes["mouthSmileLeft"] ?: 0.0 //
                val smileRight = blendshapes["mouthSmileRight"] ?: 0.0 //
                val smile = (smileLeft + smileRight) / 2.0 // متوسط الابتسام
                val mouthClose = blendshapes["mouthClose"] ?: 0.0 //
                val mouthFunnel = blendshapes["mouthFunnel"] ?: 0.0 //
                val stretchLeft = blendshapes["mouthStretchLeft"] ?: 0.0 //
                val stretchRight = blendshapes["mouthStretchRight"] ?: 0.0 //
                val mouthStretch = (stretchLeft + stretchRight) / 2.0 //

                val mouthBox = mouthBoundingBox(result) // مربع الفم

                return mapOf( // خريطة النتيجة لـ Dart
                    "faceDetected" to true, //
                    "mouthOpen" to mouthOpen, //
                    "mouthPucker" to mouthPucker, //
                    "smile" to smile, //
                    "mouthClose" to mouthClose, //
                    "mouthFunnel" to mouthFunnel, //
                    "mouthStretch" to mouthStretch, //
                    "mouthMinX" to mouthBox[0], //
                    "mouthMinY" to mouthBox[1], //
                    "mouthMaxX" to mouthBox[2], //
                    "mouthMaxY" to mouthBox[3], //
                    "ts" to System.currentTimeMillis() //
                ) //
            } catch (_: Exception) { //
                return emptyFaceResult() //
            } finally { //
                bitmap?.recycle() // تحرير الذاكرة
            } //
        } // نهاية synchronized
    } // نهاية processFrame

    fun close() { // إغلاق Landmarker
        synchronized(processLock) { //
            faceLandmarker?.close() //
            faceLandmarker = null //
        } //
    } // نهاية close

    private fun extractBlendshapes(result: FaceLandmarkerResult): Map<String, Double> { // blendshapes كـ Map
        val out = HashMap<String, Double>() //
        val optional = result.faceBlendshapes() //
        if (!optional.isPresent) return out //
        val faces = optional.get() //
        if (faces.isEmpty()) return out //
        for (category in faces[0]) { // أول وجه
            val name = category.categoryName() ?: continue //
            out[name] = category.score().toDouble() //
        } //
        return out //
    } // نهاية extractBlendshapes

    /** مربع الشفاه الخارجية: زوايا + منتصف علوي/سفلي */
    private fun mouthBoundingBox(result: FaceLandmarkerResult): DoubleArray { //
        val landmarks = result.faceLandmarks().firstOrNull() ?: return doubleArrayOf(0.0, 0.0, 0.0, 0.0) //
        // 61/291 = زوايا الفم؛ 0/17 = شفاه علوية/سفلية؛ 13/14 = منتصف الشفاه
        val lipIndices = intArrayOf(61, 291, 0, 17, 13, 14) //
        var minX = 1.0 //
        var minY = 1.0 //
        var maxX = 0.0 //
        var maxY = 0.0 //
        var any = false //
        for (idx in lipIndices) { //
            if (idx < 0 || idx >= landmarks.size) continue //
            val lm = landmarks[idx] //
            val x = lm.x().toDouble() //
            val y = lm.y().toDouble() //
            if (x < minX) minX = x //
            if (y < minY) minY = y //
            if (x > maxX) maxX = x //
            if (y > maxY) maxY = y //
            any = true //
        } //
        return if (any) doubleArrayOf(minX, minY, maxX, maxY) else doubleArrayOf(0.0, 0.0, 0.0, 0.0) //
    } // نهاية mouthBoundingBox

    private fun emptyFaceResult(): Map<String, Any> = mapOf( // نتيجة فارغة
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
        "ts" to System.currentTimeMillis() //
    ) //

    private fun ensureSoftwareBitmap(source: Bitmap): Bitmap { // Bitmap ARGB software
        if (source.config == Bitmap.Config.ARGB_8888 && !source.isRecycled) { //
            return source //
        } //
        return source.copy(Bitmap.Config.ARGB_8888, false) ?: source //
    } // نهاية ensureSoftwareBitmap
} // نهاية FaceLandmarkerBridge
