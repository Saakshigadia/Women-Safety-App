package com.example.women_safety_app

import android.os.Build
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.women_safety_app/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendSms") {
                val phone = call.argument<String>("phone")
                val message = call.argument<String>("message")

                if (phone == null || message == null) {
                    result.error("INVALID_ARGS", "Phone or message is null", null)
                    return@setMethodCallHandler
                }

                try {
                    val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        applicationContext.getSystemService(SmsManager::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        SmsManager.getDefault()
                    }

                    val parts = smsManager.divideMessage(message)

                    // Request delivery confirmation for each part —
                    // this also tends to make Android treat the SMS as
                    // higher priority / more visible in notification stacks
                    val sentIntents = ArrayList<android.app.PendingIntent>()
                    val deliveredIntents = ArrayList<android.app.PendingIntent>()
                    for (i in parts.indices) {
                        sentIntents.add(
                            android.app.PendingIntent.getBroadcast(
                                this, 0, android.content.Intent("SMS_SENT_$i"),
                                android.app.PendingIntent.FLAG_IMMUTABLE
                            )
                        )
                        deliveredIntents.add(
                            android.app.PendingIntent.getBroadcast(
                                this, 0, android.content.Intent("SMS_DELIVERED_$i"),
                                android.app.PendingIntent.FLAG_IMMUTABLE
                            )
                        )
                    }

                    smsManager.sendMultipartTextMessage(
                        phone, null, parts, sentIntents, deliveredIntents
                    )

                    result.success("SMS sent to $phone")
                } catch (e: Exception) {
                    result.error("SMS_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}