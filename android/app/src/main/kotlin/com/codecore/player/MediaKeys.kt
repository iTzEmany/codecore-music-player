package com.codecore.player

import android.content.Context
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent

/**
 * Presses a media key the way a headset would. `audio_service` drops a key
 * that arrives before the Dart player is attached (R63), so when the app was
 * dead the key is pressed once to start it and again when it reports ready.
 */
object MediaKeys {
    private const val GIVE_UP_MS = 9000L
    private const val POLL_MS = 250L
    private const val SETTLE_MS = 500L

    fun press(ctx: Context, keyCode: Int) {
        val audio = ctx.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audio.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        audio.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, keyCode))
    }

    /** [done] runs once, when nothing is left to wait for. */
    fun pressSurely(ctx: Context, keyCode: Int, done: () -> Unit) {
        val app = ctx.applicationContext
        val wasReady = WidgetStore.playerReady(app)
        press(app, keyCode)
        if (wasReady) {
            done()
            return
        }
        val main = Handler(Looper.getMainLooper())
        val started = System.currentTimeMillis()
        fun poll() {
            when {
                WidgetStore.playerReady(app) ->
                    main.postDelayed({ press(app, keyCode); done() }, SETTLE_MS)
                System.currentTimeMillis() - started > GIVE_UP_MS -> done()
                else -> main.postDelayed(::poll, POLL_MS)
            }
        }
        main.postDelayed(::poll, POLL_MS)
    }
}
