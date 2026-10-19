package com.codecore.player

import android.content.ComponentName
import android.content.Context
import android.content.Intent
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
    /** The broadcast must be finished by ~10 s; waiting for Dart may take longer (debug builds). */
    private const val FINISH_MS = 8000L
    private const val GIVE_UP_MS = 40000L
    private const val POLL_MS = 250L
    private const val SETTLE_MS = 500L

    /**
     * With no media session known to the system (after an install or after a
     * long time) `dispatchMediaKeyEvent` has nobody to deliver to. The
     * `audio_service` receiver is addressed directly: it starts the service,
     * which is where the Dart player comes up.
     */
    private fun pressViaReceiver(ctx: Context, keyCode: Int) {
        for (action in intArrayOf(KeyEvent.ACTION_DOWN, KeyEvent.ACTION_UP)) {
            ctx.sendBroadcast(
                Intent(Intent.ACTION_MEDIA_BUTTON)
                    .setComponent(ComponentName(ctx, "com.ryanheise.audioservice.MediaButtonReceiver"))
                    .putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(action, keyCode)),
            )
        }
    }

    fun press(ctx: Context, keyCode: Int) {
        val audio = ctx.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audio.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        audio.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, keyCode))
    }

    /** [done] runs once, when nothing is left to wait for. */
    fun pressSurely(ctx: Context, keyCode: Int, done: () -> Unit) {
        val app = ctx.applicationContext
        val wasReady = WidgetStore.playerReady(app)
        android.util.Log.i("codecore", "media key $keyCode, player ready: $wasReady")
        if (wasReady) press(app, keyCode) else pressViaReceiver(app, keyCode)
        if (wasReady) {
            done()
            return
        }
        val main = Handler(Looper.getMainLooper())
        val started = System.currentTimeMillis()
        var finished = false
        fun finish() {
            if (!finished) {
                finished = true
                done()
            }
        }
        fun poll() {
            val waited = System.currentTimeMillis() - started
            when {
                WidgetStore.playerReady(app) -> {
                    main.postDelayed({ press(app, keyCode); finish() }, SETTLE_MS)
                }
                waited > GIVE_UP_MS -> finish()
                else -> {
                    if (waited > FINISH_MS) finish() // the process lives on: keep waiting
                    main.postDelayed(::poll, POLL_MS)
                }
            }
        }
        main.postDelayed(::poll, POLL_MS)
    }
}
