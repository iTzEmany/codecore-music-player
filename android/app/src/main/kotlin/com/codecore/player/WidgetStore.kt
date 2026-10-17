package com.codecore.player

import android.content.ComponentName
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.service.quicksettings.TileService

/**
 * What Dart last wrote for the widget and the tile (see `widget_bridge.dart`):
 * plain preferences, because a custom channel does not exist in the engine
 * `audio_service` starts without the activity.
 */
object WidgetStore {
    private const val FILE = "FlutterSharedPreferences"
    private const val PREFIX = "flutter."

    /** Set when this process starts; Dart's `readyAt` newer than this = player up. */
    @Volatile var processStartMs = System.currentTimeMillis()

    class Snapshot(val title: String?, val artist: String?, val cover: String?, val playing: Boolean)

    private fun prefs(ctx: Context) = ctx.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    fun snapshot(ctx: Context): Snapshot {
        val p = prefs(ctx)
        return Snapshot(
            p.getString(PREFIX + "widget.title", null),
            p.getString(PREFIX + "widget.artist", null),
            p.getString(PREFIX + "widget.cover", null),
            p.getBoolean(PREFIX + "widget.playing", false),
        )
    }

    /** The Dart player is up in this process and its queue restored. */
    fun playerReady(ctx: Context): Boolean =
        prefs(ctx).getLong(PREFIX + "widget.readyAt", 0L) >= processStartMs

    /** Cover decoded to at most [max] px a side, or null. */
    fun cover(path: String?, max: Int = 256): Bitmap? {
        if (path == null) return null
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            var sample = 1
            while (bounds.outWidth / sample > max || bounds.outHeight / sample > max) sample *= 2
            BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
        } catch (e: Exception) {
            null
        }
    }

    /** Called when Dart writes a new snapshot. */
    fun refresh(ctx: Context) {
        NowPlayingWidget4x1.refresh(ctx)
        NowPlayingWidget2x2.refresh(ctx)
        TileService.requestListeningState(ctx, ComponentName(ctx, PlayTileService::class.java))
    }
}
