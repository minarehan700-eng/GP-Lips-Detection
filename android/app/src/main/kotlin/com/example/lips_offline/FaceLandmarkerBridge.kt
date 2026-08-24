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

/**
 * Runs Google's MediaPipe Face Landmarker on Android.
 *
 * Why this class is needed:
 * MediaPipe is a native library with no Dart version, so the actual face
 * detection has to happen here in Kotlin. Flutter sends a JPEG frame across a
 * method channel, this class analyses it, and sends back a plain map of
 * numbers describing the mouth.
 *
 * The model file `face_landmarker.task` is bundled in the app's assets, which
 * is what makes the app work completely offline.
 */
class FaceLandmarkerBridge(private val context: Context) {
    private var faceLandmarker: FaceLandmarker? = null

    /**
     * Guards the landmarker. Frames are analysed on a background thread while
     * initialize/close can be called from the main thread, and MediaPipe does
     * not allow two threads to use one landmarker at the same time.
     */
    private val processLock = Any()

    fun isInitialized(): Boolean = synchronized(processLock) { faceLandmarker != null }

    /**
     * Loads the model from the app's assets.
     *
     * Must run on the main thread: on Android 15/16 loading MediaPipe from a
     * background thread crashed the app, so [MainActivity] posts this call to
     * the main thread on purpose.
     *
     * Calling it twice is safe — the second call returns immediately.
     */
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
                // IMAGE mode: each frame is treated on its own. The app does
                // its own smoothing across frames in the Dart detectors.
                .setRunningMode(RunningMode.IMAGE)
                // One user practising in front of the phone, so one face.
                .setNumFaces(1)
                // 0.5 is MediaPipe's balanced default: lower would report
                // faces that are not there, higher would miss real ones.
                .setMinFaceDetectionConfidence(0.5f)
                .setMinFacePresenceConfidence(0.5f)
                .setMinTrackingConfidence(0.5f)
                // Blendshapes are the whole point — they are the mouth
                // numbers the app turns into lipsing and letters.
                .setOutputFaceBlendshapes(true)
                .build()
            faceLandmarker = FaceLandmarker.createFromOptions(context, options)
        }
    }

    /**
     * Analyses one JPEG frame and returns the mouth numbers for Flutter.
     *
     * Input:  frameBytes — one camera frame encoded as JPEG.
     * Output: a map with `faceDetected`, the six mouth blendshapes, the four
     *         mouth-box values and a timestamp. When no face is found, or
     *         anything fails, the same map shape is returned with
     *         `faceDetected = false` — never an exception, so one bad frame
     *         cannot break the live camera.
     *
     * Steps:
     *   1. Decode the JPEG into a bitmap.
     *   2. Make sure it is a software bitmap MediaPipe can read.
     *   3. Run face detection.
     *   4. Pull out the mouth blendshapes and the mouth bounding box.
     */
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

                // MediaPipe returns ~52 blendshapes for the whole face. Only
                // the mouth ones are needed, and each is a score from 0.0
                // (not at all) to 1.0 (fully).
                val blendshapes = extractBlendshapes(result)
                val mouthOpen = blendshapes["jawOpen"] ?: 0.0
                val mouthPucker = blendshapes["mouthPucker"] ?: 0.0
                val mouthClose = blendshapes["mouthClose"] ?: 0.0
                val mouthFunnel = blendshapes["mouthFunnel"] ?: 0.0

                // Smile and stretch are reported separately for each side of
                // the face. They are averaged into one value because the app
                // asks "is the mouth smiling?", not "which side smiles more?" —
                // and averaging also steadies a slightly crooked smile.
                val smileLeft = blendshapes["mouthSmileLeft"] ?: 0.0
                val smileRight = blendshapes["mouthSmileRight"] ?: 0.0
                val smile = (smileLeft + smileRight) / 2.0
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

    /** Releases the model. Called when the activity is destroyed. */
    fun close() {
        synchronized(processLock) {
            faceLandmarker?.close()
            faceLandmarker = null
        }
    }

    /**
     * Copies the detected face's blendshapes into a name-to-score map,
     * so the caller can look values up by name instead of by position.
     * Returns an empty map when the model reported no blendshapes.
     */
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

    /**
     * Works out a rectangle around the lips.
     *
     * Output: [minX, minY, maxX, maxY] as fractions of the frame (0.0 – 1.0),
     * or four zeros when no landmarks were available. Flutter draws this as
     * the box on the camera preview.
     *
     * MediaPipe returns 478 face points. Only six lip points are needed, and
     * the smallest and largest X and Y among them give the box.
     */
    private fun mouthBoundingBox(result: FaceLandmarkerResult): DoubleArray {
        val landmarks = result.faceLandmarks().firstOrNull() ?: return doubleArrayOf(0.0, 0.0, 0.0, 0.0)

        // Fixed point numbers from MediaPipe's face mesh:
        //  61  = left mouth corner      291 = right mouth corner
        //  0   = top of the upper lip   17  = bottom of the lower lip
        //  13  = inner upper lip        14  = inner lower lip
        // Together they cover the full width and height of the lips.
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

    /**
     * The reply used whenever no face could be measured.
     *
     * It has exactly the same keys as a successful reply, so the Dart side can
     * read every field without checking whether a face was found first.
     */
    fun emptyFaceResult(): Map<String, Any> = mapOf(
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

    /**
     * Returns a bitmap MediaPipe can read.
     *
     * MediaPipe needs plain ARGB_8888 pixels in normal memory. A bitmap in
     * another format (for example a hardware bitmap held by the GPU) has to be
     * copied first, or detection fails.
     */
    private fun ensureSoftwareBitmap(source: Bitmap): Bitmap {
        if (source.config == Bitmap.Config.ARGB_8888 && !source.isRecycled) {
            return source
        }
        return source.copy(Bitmap.Config.ARGB_8888, false) ?: source
    }
}
