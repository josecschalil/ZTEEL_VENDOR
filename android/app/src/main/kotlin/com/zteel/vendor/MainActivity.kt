package com.zteel.vendor

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val NOTIFICATION_CHANNEL = "vendor_new_orders"
        private const val NOTIFICATION_CHANNEL_NAME = "New orders"
        private const val NOTIFICATION_METHOD_CHANNEL = "zteel/vendor_notifications"
        private const val EXTRA_NOTIFICATION_PAYLOAD = "zteel_notification_payload"
    }

    private var notificationChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        notificationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_METHOD_CHANNEL,
        )
        notificationChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "showNewOrder" -> {
                    val notificationId = call.argument<Int>("id")
                    if (notificationId == null) {
                        result.error("missing_id", "A notification id is required.", null)
                        return@setMethodCallHandler
                    }
                    val title = call.argument<String>("title") ?: "New order"
                    val message = call.argument<String>("message") ?: "A new order is ready to review."
                    val payload = call.argument<String>("payload") ?: ""
                    showNewOrderNotification(notificationId, title, message, payload)
                    result.success(null)
                }
                "getLaunchOrder" -> {
                    result.success(intent?.getStringExtra(EXTRA_NOTIFICATION_PAYLOAD))
                    intent?.removeExtra(EXTRA_NOTIFICATION_PAYLOAD)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val payload = intent.getStringExtra(EXTRA_NOTIFICATION_PAYLOAD) ?: return
        notificationChannel?.invokeMethod("openOrder", payload)
        intent.removeExtra(EXTRA_NOTIFICATION_PAYLOAD)
    }

    private fun showNewOrderNotification(id: Int, title: String, message: String, payload: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL,
                NOTIFICATION_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Alerts when a customer places a new order."
                enableVibration(true)
            }
            manager.createNotificationChannel(channel)
        }

        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(EXTRA_NOTIFICATION_PAYLOAD, payload)
        }
        val pendingIntentFlags = PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        val pendingIntent = PendingIntent.getActivity(this, id, launchIntent, pendingIntentFlags)
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIFICATION_CHANNEL)
        } else {
            Notification.Builder(this)
        }
        manager.notify(
            id,
            builder
                .setSmallIcon(R.drawable.ic_stat_zteel)
                .setContentTitle(title)
                .setContentText(message)
                .setStyle(Notification.BigTextStyle().bigText(message))
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)
                .setPriority(Notification.PRIORITY_HIGH)
                .build(),
        )
    }
}
