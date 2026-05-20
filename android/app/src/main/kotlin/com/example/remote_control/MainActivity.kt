package com.yourapp.universalremote

import android.content.Context
import android.hardware.ConsumerIrManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.yourapp/ir_blaster"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val irManager = getSystemService(Context.CONSUMER_IR_SERVICE) as? ConsumerIrManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasIrEmitter" -> {
                        result.success(irManager?.hasIrEmitter() ?: false)
                    }
                    "transmit" -> {
                        val freq = call.argument<Int>("frequency") ?: 38000
                        val pattern = call.argument<List<Int>>("pattern")

                        if (irManager == null) {
                            result.error("NO_IR", "No IR hardware found", null)
                            return@setMethodCallHandler
                        }
                        if (pattern == null) {
                            result.error("BAD_ARGS", "Pattern is required", null)
                            return@setMethodCallHandler
                        }

                        try {
                            irManager.transmit(freq, pattern.toIntArray())
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("TRANSMIT_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}