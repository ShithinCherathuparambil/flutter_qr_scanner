package com.flutter.qr

import android.app.Activity
import com.google.mlkit.common.MlKitException
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.codescanner.GmsBarcodeScannerOptions
import com.google.mlkit.vision.codescanner.GmsBarcodeScanning
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * FlutterQrScannerPlugin
 *
 * Implements Google Play Services Code Scanner on Android with:
 * - ActivityAware lifecycle binding
 * - Barcode.FORMAT_ALL_FORMATS
 * - enableAutoZoom()
 * - Clean cancellation (returns null to Dart)
 * - Typed error mapping for permissions, availability, and concurrency
 */
class FlutterQrScannerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private var channel: MethodChannel? = null
    private var activity: Activity? = null
    private var isScanning = false

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_qr_scanner")
        channel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startScan" -> startScan(result)
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            else -> result.notImplemented()
        }
    }

    private fun startScan(result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error(
                "NO_ACTIVITY",
                "Cannot start scan without an active foreground Activity.",
                null
            )
            return
        }

        if (isScanning) {
            result.error(
                "ALREADY_SCANNING",
                "A scan is already in progress.",
                null
            )
            return
        }

        isScanning = true
        var isResultSubmitted = false

        fun safeSuccess(value: Any?) {
            if (!isResultSubmitted) {
                isResultSubmitted = true
                isScanning = false
                result.success(value)
            }
        }

        fun safeError(code: String, message: String?, details: Any? = null) {
            if (!isResultSubmitted) {
                isResultSubmitted = true
                isScanning = false
                result.error(code, message, details)
            }
        }

        try {
            val options = GmsBarcodeScannerOptions.Builder()
                .setBarcodeFormats(Barcode.FORMAT_ALL_FORMATS)
                .enableAutoZoom()
                .build()

            val scanner = GmsBarcodeScanning.getClient(currentActivity, options)

            scanner.startScan()
                .addOnSuccessListener { barcode ->
                    val rawValue = barcode.rawValue ?: barcode.displayValue
                    if (!rawValue.isNullOrBlank()) {
                        safeSuccess(rawValue.trim())
                    } else {
                        safeSuccess(null)
                    }
                }
                .addOnCanceledListener {
                    safeSuccess(null)
                }
                .addOnFailureListener { e ->
                    val errorCode = if (e is MlKitException) {
                        when (e.errorCode) {
                            MlKitException.CODE_SCANNER_CAMERA_PERMISSION_NOT_GRANTED -> "PERMISSION_DENIED"
                            MlKitException.CODE_SCANNER_TASK_IN_PROGRESS -> "ALREADY_SCANNING"
                            MlKitException.CODE_SCANNER_UNAVAILABLE -> "CAMERA_UNAVAILABLE"
                            else -> "SCAN_FAILED"
                        }
                    } else {
                        "SCAN_FAILED"
                    }
                    safeError(errorCode, e.localizedMessage ?: "Barcode scanning failed", null)
                }
        } catch (e: Exception) {
            safeError("LAUNCH_ERROR", e.localizedMessage ?: "Failed to launch barcode scanner", null)
        }
    }
}
