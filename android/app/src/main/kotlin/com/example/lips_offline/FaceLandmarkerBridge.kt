package com.example.lips_offline

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarkerResult
import java.io.ByteArrayInputStream

/// Native MediaPipe Face Landmarker — extracts mouth blendshapes and bounding box from JPEG frames.
class FaceLandmarkerBridge(private val context: Context) {
    private var faceLandmarker: FaceLandmarker? = null
    private val processLock = Any()

    fun isInitialized(): Boolean = synchronized(processLock) { faceLandmarker != null }

    /// Loads the model from assets. Must run on the main thread to avoid Android 15/16 crashes.
    fun initialize(modelAssetPath: String = "face_landmarker.task") {
        synchronized(processLock) {
            if (faceLandmarker != null) return

            // Pre-load MediaPipe vision API on this thread before any background work.
            Class.forName("com.google.mediapipe.tasks.vision.core.BaseVisionTaskApi")

            context.assets.open(modelAssetPath).use { }

            val baseOptions = BaseOptions.builder()
                .setModelAssetPath(modelAssetPath)
                .build()

            val options = FaceLandmarker.FaceLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setRunningMode(RunningMode.IMAGE)
                .setNumFaces(1)
                .setMinFaceDetectionConfidence(0.5f)
                .setMinFacePresenceConfidence(0.5f)
                .setMinTrackingConfidence(0.5f)
                .setOutputFaceBlendshapes(true)
                .build()
            faceLandmarker = FaceLandmarker.createFromOptions(context, options)
        }
    }

    /// Decodes a JPEG frame, runs face detection, and returns mouth metrics for Flutter.
    fun processFrame(frameBytes: ByteArray): Map<String, Any> {
        if (frameBytes.isEmpty()) {
            return emptyFaceResult()
        }

        synchronized(processLock) {
            val landmarker = faceLandmarker ?: return emptyFaceResult()

            var bitmap: Bitmap? = null
            try {
                val decodeOptions = BitmapFactory.Options().apply {
                    inPreferredConfig = Bitmap.Config.ARGB_8888
                }
                bitmap = BitmapFactory.decodeStream(ByteArrayInputStream(frameBytes), null, decodeOptions)
                    ?: return emptyFaceResult()
                if (bitmap.width <= 0 || bitmap.height <= 0) return emptyFaceResult()

                val softwareBitmap = ensureSoftwareBitmap(bitmap)
                if (softwareBitmap !== bitmap) {
                    bitmap.recycle()
                    bitmap = softwareBitmap
                }

                val mpImage = BitmapImageBuilder(softwareBitmap).build()
                val result: FaceLandmarkerResult = landmarker.detect(mpImage)
                if (result.faceLandmarks().isEmpty()) {
                    return emptyFaceResult()
                }

                val blendshapes = extractBlendshapes(result)
                val mouthOpen = blendshapes["jawOpen"] ?: 0.0
                val mouthPucker = blendshapes["mouthPucker"] ?: 0.0
                val smileLeft = blendshapes["mouthSmileLeft"] ?: 0.0
                val smileRight = blendshapes["mouthSmileRight"] ?: 0.0
                val smile = (smileLeft + smileRight) / 2.0
                val mouthClose = blendshapes["mouthClose"] ?: 0.0
                val mouthFunnel = blendshapes["mouthFunnel"] ?: 0.0
                val stretchLeft = blendshapes["mouthStretchLeft"] ?: 0.0
                val stretchRight = blendshapes["mouthStretchRight"] ?: 0.0
                val mouthStretch = (stretchLeft + stretchRight) / 2.0

                val mouthBox = mouthBoundingBox(result)

                return mapOf(
                    "faceDetected" to true,
                    "mouthOpen" to mouthOpen,
                    "mouthPucker" to mouthPucker,
                    "smile" to smile,
                    "mouthClose" to mouthClose,
                    "mouthFunnel" to mouthFunnel,
                    "mouthStretch" to mouthStretch,
                    "mouthMinX" to mouthBox[0],
                    "mouthMinY" to mouthBox[1],
                    "mouthMaxX" to mouthBox[2],
                    "mouthMaxY" to mouthBox[3],
                    "ts" to System.currentTimeMillis()
                )
            } catch (_: Exception) {
                return emptyFaceResult()
            } finally {
                bitmap?.recycle()
            }
        }
    }

    fun close() {
        synchronized(processLock) {
            faceLandmarker?.close()
            faceLandmarker = null
        }
    }

    private fun extractBlendshapes(result: FaceLandmarkerResult): Map<String, Double> {
        val out = HashMap<String, Double>()
        val optional = result.faceBlendshapes()
        if (!optional.isPresent) return out
        val faces = optional.get()
        if (faces.isEmpty()) return out
        for (category in faces[0]) {
            val name = category.categoryName() ?: continue
            out[name] = category.score().toDouble()
        }
        return out
    }

    /// Outer-lip bounding box from corner and mid-lip landmark indices.
    private fun mouthBoundingBox(result: FaceLandmarkerResult): DoubleArray {
        val landmarks = result.faceLandmarks().firstOrNull() ?: return doubleArrayOf(0.0, 0.0, 0.0, 0.0)
        val lipIndices = intArrayOf(61, 291, 0, 17, 13, 14)
        var minX = 1.0
        var minY = 1.0
        var maxX = 0.0
        var maxY = 0.0
        var any = false
        for (idx in lipIndices) {
            if (idx < 0 || idx >= landmarks.size) continue
            val lm = landmarks[idx]
            val x = lm.x().toDouble()
            val y = lm.y().toDouble()
            if (x < minX) minX = x
            if (y < minY) minY = y
            if (x > maxX) maxX = x
            if (y > maxY) maxY = y
            any = true
        }
        return if (any) doubleArrayOf(minX, minY, maxX, maxY) else doubleArrayOf(0.0, 0.0, 0.0, 0.0)
    }

    private fun emptyFaceResult(): Map<String, Any> = mapOf(
        "faceDetected" to false,
        "mouthOpen" to 0.0,
        "mouthPucker" to 0.0,
        "smile" to 0.0,
        "mouthClose" to 0.0,
        "mouthFunnel" to 0.0,
        "mouthStretch" to 0.0,
        "mouthMinX" to 0.0,
        "mouthMinY" to 0.0,
        "mouthMaxX" to 0.0,
        "mouthMaxY" to 0.0,
        "ts" to System.currentTimeMillis()
    )

    private fun ensureSoftwareBitmap(source: Bitmap): Bitmap {
        if (source.config == Bitmap.Config.ARGB_8888 && !source.isRecycled) {
            return source
        }
        return source.copy(Bitmap.Config.ARGB_8888, false) ?: source
    }
}
