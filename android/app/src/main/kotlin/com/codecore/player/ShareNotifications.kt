package com.codecore.player

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

/** Notifications of the local-network sharing feature. */
object ShareNotifications {
    const val CHANNEL_SERVICE = "share_service"
    const val CHANNEL_OFFERS = "share_offers"
    const val ACTION_ACCEPT = "com.codecore.player.OFFER_ACCEPT"
    const val ACTION_DECLINE = "com.codecore.player.OFFER_DECLINE"
    const val ACTION_DISABLE = "com.codecore.player.RECEIVE_DISABLE"
    const val EXTRA_OFFER_ID = "offerId"
    const val SERVICE_ID = 4101

    fun ensureChannels(ctx: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = ctx.getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_SERVICE, "Condivisione in rete locale",
                NotificationManager.IMPORTANCE_LOW)
        )
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_OFFERS, "Richieste di invio",
                NotificationManager.IMPORTANCE_HIGH)
        )
    }

    private fun builder(ctx: Context, channel: String): Notification.Builder =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            Notification.Builder(ctx, channel)
        else
            @Suppress("DEPRECATION") Notification.Builder(ctx)

    private fun openApp(ctx: Context): PendingIntent {
        val i = Intent(ctx, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        return PendingIntent.getActivity(ctx, 0, i,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    }

    private fun broadcast(ctx: Context, action: String, offerId: String?, code: Int):
        PendingIntent {
        val i = Intent(ctx, ShareActionReceiver::class.java).setAction(action)
        if (offerId != null) i.putExtra(EXTRA_OFFER_ID, offerId)
        return PendingIntent.getBroadcast(ctx, code, i,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    }

    private fun action(ctx: Context, label: String, pi: PendingIntent): Notification.Action =
        Notification.Action.Builder(
            android.graphics.drawable.Icon.createWithResource(ctx, R.drawable.ic_stat_codecore),
            label, pi).build()

    fun serviceNotification(ctx: Context, title: String, text: String, disableLabel: String):
        Notification {
        ensureChannels(ctx)
        return builder(ctx, CHANNEL_SERVICE)
            .setSmallIcon(R.drawable.ic_stat_codecore)
            .setContentTitle(title)
            .setContentText(text)
            .setOngoing(true)
            .setContentIntent(openApp(ctx))
            .addAction(action(ctx, disableLabel, broadcast(ctx, ACTION_DISABLE, null, 1)))
            .build()
    }

    fun showOffer(ctx: Context, offerId: String, title: String, body: String,
                  acceptLabel: String, declineLabel: String) {
        ensureChannels(ctx)
        val code = offerId.hashCode()
        val n = builder(ctx, CHANNEL_OFFERS)
            .setSmallIcon(R.drawable.ic_stat_codecore)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setContentIntent(openApp(ctx))
            .addAction(action(ctx, acceptLabel, broadcast(ctx, ACTION_ACCEPT, offerId, code)))
            .addAction(action(ctx, declineLabel, broadcast(ctx, ACTION_DECLINE, offerId, code + 1)))
            .build()
        ctx.getSystemService(NotificationManager::class.java).notify(code, n)
    }

    fun clearOffer(ctx: Context, offerId: String) {
        ctx.getSystemService(NotificationManager::class.java).cancel(offerId.hashCode())
    }
}
