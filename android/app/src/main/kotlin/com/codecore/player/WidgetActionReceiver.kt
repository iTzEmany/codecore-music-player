package com.codecore.player

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.view.KeyEvent

/** Buttons of the widget: previous, play/pause, next. */
class WidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val key = when (intent.action) {
            ACTION_PREVIOUS -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
            ACTION_PLAY_PAUSE -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
            ACTION_NEXT -> KeyEvent.KEYCODE_MEDIA_NEXT
            else -> return
        }
        val pending = goAsync()
        MediaKeys.pressSurely(context, key) { pending.finish() }
    }

    companion object {
        const val ACTION_PREVIOUS = "com.codecore.player.widget.PREVIOUS"
        const val ACTION_PLAY_PAUSE = "com.codecore.player.widget.PLAY_PAUSE"
        const val ACTION_NEXT = "com.codecore.player.widget.NEXT"
    }
}
