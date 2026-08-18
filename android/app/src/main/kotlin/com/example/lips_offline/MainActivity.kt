package com.example.lips_offline

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/// Main activity — wires Flutter MethodChannel calls to [FaceLandmarkerBridge].
class MainActivity : FlutterActivity() {
    private val faceChannelName = "lips/offline/face"
    private lateinit var faceBridge: FaceLandmarkerBridge
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
                        if (!faceBridge.isInitialized()) {
                            result.success(emptyFacePayload())
                            return@setMethodCallHandler
                        }

                        val bytes = call.argument<ByteArray>("bytes")
                        if (bytes == null) {
                            result.error("bad_args", "Missing frame bytes", null)
                            return@setMethodCallHandler
                        }

                        faceFrameExecutor.execute {
                            val payload = try {
                                faceBridge.processFrame(bytes)
                            } catch (_: Exception) {
                                emptyFacePayload()
                            }
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

    private fun emptyFacePayload(): Map<String, Any> = mapOf(
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
}
