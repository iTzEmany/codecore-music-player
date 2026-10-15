package com.codecore.player

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper

/** Buttons on the notifications: accept / decline an offer, turn receiving off. */
class ShareActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val ch = ShareBridge.channel
        val offerId = intent.getStringExtra(ShareNotifications.EXTRA_OFFER_ID)
        Handler(Looper.getMainLooper()).post {
            when (intent.action) {
                ShareNotifications.ACTION_ACCEPT, ShareNotifications.ACTION_DECLINE -> {
                    if (offerId != null) {
                        ShareNotifications.clearOffer(context, offerId)
                        val kind = if (intent.action == ShareNotifications.ACTION_ACCEPT)
                            "accept" else "decline"
                        ch?.invokeMethod("offerAction",
                            mapOf("offerId" to offerId, "action" to kind))
                    }
                }
                ShareNotifications.ACTION_DISABLE -> {
                    ReceiveService.stop(context)
                    ch?.invokeMethod("disableReceive", null)
                }
            }
        }
    }
}
