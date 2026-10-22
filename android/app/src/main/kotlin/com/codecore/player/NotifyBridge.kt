package com.codecore.player

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * `codecore/notify`: `showReleases` posts the «Nuove uscite» notification (answers
 * whether the system lets it through), `takeLaunchTarget` returns the extra of the
 * intent that opened the app once and clears it, and `launchTarget` is pushed to
 * Dart when a tap arrives while the app is already running.
 */
object NotifyBridge {
    private const val CHANNEL_ID = "new_releases"
    private const val EXTRA_TARGET = "codecore.target"
    private const val NOTIFICATION_ID = 4201
    private var channel: MethodChannel? = null

    @Volatile
    private var pendingTarget: String? = null

    fun register(messenger: BinaryMessenger, context: Context) {
        val ch = MethodChannel(messenger, "codecore/notify")
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "showReleases" -> result.success(
                    showReleases(
                        context,
                        call.argument<String>("title") ?: "",
                        call.argument<String>("body") ?: "",
                        call.argument<String>("channelName") ?: "Releases",
                        call.argument<String>("actionLabel") ?: "Show",
                    )
                )
                "takeLaunchTarget" -> {
                    result.success(pendingTarget)
                    pendingTarget = null
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Remembers the target of a notification tap and tells Dart if it listens. */
    fun handleIntent(intent: Intent?) {
        val target = intent?.getStringExtra(EXTRA_TARGET) ?: return
        intent.removeExtra(EXTRA_TARGET)
        pendingTarget = target
        channel?.invokeMethod("launchTarget", null)
    }

    private fun showReleases(
        ctx: Context, title: String, body: String, channelName: String, actionLabel: String,
    ): Boolean {
        val nm = ctx.getSystemService(NotificationManager::class.java)
        if (!nm.areNotificationsEnabled()) return false
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, channelName, NotificationManager.IMPORTANCE_DEFAULT)
            )
            android.app.Notification.Builder(ctx, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION") android.app.Notification.Builder(ctx)
        }
        val open = PendingIntent.getActivity(
            ctx, NOTIFICATION_ID,
            Intent(ctx, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                .putExtra(EXTRA_TARGET, "releases"),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val action = android.app.Notification.Action.Builder(
            android.graphics.drawable.Icon.createWithResource(ctx, R.drawable.ic_stat_codecore),
            actionLabel, open,
        ).build()
        nm.notify(
            NOTIFICATION_ID,
            builder.setSmallIcon(R.drawable.ic_stat_codecore)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(android.app.Notification.BigTextStyle().bigText(body))
                .setAutoCancel(true)
                .setContentIntent(open)
                .addAction(action)
                .build(),
        )
        return true
    }
}
