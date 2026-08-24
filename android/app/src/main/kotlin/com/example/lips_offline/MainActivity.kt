package com.example.lips_offline

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * The Android entry point, and the switchboard between Flutter and MediaPipe.
 *
 * Why this class is needed:
 * Flutter code cannot call Kotlin directly. It sends a named message over a
 * *method channel*; this class listens on that channel and calls
 * [FaceLandmarkerBridge] for each message, then sends the answer back.
 *
 * Threading matters here:
 *  - the model is loaded on the MAIN thread (Android 15/16 crashed otherwise);
 *  - frames are analysed on a BACKGROUND thread, so the app stays smooth;
 *  - answers are posted back on the MAIN thread, which Flutter requires.
 */
class MainActivity : FlutterActivity() {
    /** Must match the channel name used in the Dart extractor. */
    private val faceChannelName = "lips/offline/face"

    private lateinit var faceBridge: FaceLandmarkerBridge

    /**
     * A single background thread for frame analysis. One thread — not a pool —
     * because MediaPipe handles one frame at a time anyway, and this keeps
     * frames in order.
     */
    private val faceFrameExecutor = Executors.newSingleThreadExecutor()

    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        faceBridge = FaceLandmarkerBridge(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, faceChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initializeFaceLandmarker" -> {
                        // MediaPipe init must run on the main thread (Android 15/16 crash fix).
                        mainHandler.post {
                            if (isFinishing) {
                                result.error("init_failed", "Activity is finishing", null)
                                return@post
                            }
                            try {
                                faceBridge.initialize()
                                result.success(null)
                            } catch (e: Exception) {
                                result.error(
                                    "init_failed",
                                    "Failed to initialize face landmarker. Ensure android/app/src/main/assets/face_landmarker.task exists. Root error: ${e.message}",
                                    null
                                )
                            }
                        }
                    }
                    "isFaceLandmarkerInitialized" -> {
                        result.success(faceBridge.isInitialized())
                    }
                    "processFaceFrame" -> {
                        // A frame can arrive before the model finished loading.
                        // That is normal at start-up, so answer "no face"
                        // rather than reporting an error.
                        if (!faceBridge.isInitialized()) {
                            result.success(emptyFacePayload())
                            return@setMethodCallHandler
                        }

                        val bytes = call.argument<ByteArray>("bytes")
                        if (bytes == null) {
                            result.error("bad_args", "Missing frame bytes", null)
                            return@setMethodCallHandler
                        }

                        // Detection is slow, so it runs off the main thread to
                        // keep the camera preview smooth. The answer is then
                        // posted back on the main thread, because Flutter only
                        // accepts channel replies from there.
                        faceFrameExecutor.execute {
                            val payload = try {
                                faceBridge.processFrame(bytes)
                            } catch (_: Exception) {
                                emptyFacePayload()
                            }
                            // Skip the reply if the user has already closed
                            // the app; Flutter would no longer be listening.
                            if (!isFinishing) {
                                mainHandler.post { result.success(payload) }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        faceFrameExecutor.shutdown()
        if (::faceBridge.isInitialized) {
            faceBridge.close()
        }
        super.onDestroy()
    }

    /**
     * The "no face" reply. It is built by [FaceLandmarkerBridge] so the empty
     * reply and the real reply always have exactly the same keys.
     */
    private fun emptyFacePayload(): Map<String, Any> = faceBridge.emptyFaceResult()
}
