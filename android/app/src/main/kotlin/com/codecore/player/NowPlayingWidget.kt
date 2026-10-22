package com.codecore.player

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/** «Now playing» widget: cover, title, artist and the three buttons. */
abstract class NowPlayingWidget(private val layout: Int, private val compact: Boolean) :
    AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val views = build(context)
        for (id in ids) manager.updateAppWidget(id, views)
    }

    private fun action(ctx: Context, action: String, code: Int): PendingIntent =
        PendingIntent.getBroadcast(
            ctx, code,
            Intent(ctx, WidgetActionReceiver::class.java).setAction(action),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

    private fun build(ctx: Context): RemoteViews {
        val s = WidgetStore.snapshot(ctx)
        val v = RemoteViews(ctx.packageName, layout)
        val cover = WidgetStore.cover(s.cover)
        if (cover != null) v.setImageViewBitmap(R.id.cover, cover)
        else v.setImageViewResource(R.id.cover, R.drawable.ic_widget_cover)
        v.setTextViewText(R.id.title, s.title ?: ctx.getString(R.string.widget_nothing))
        v.setTextViewText(R.id.artist, s.artist ?: "")
        v.setImageViewResource(
            R.id.play_pause,
            if (s.playing) R.drawable.ic_widget_pause else R.drawable.ic_widget_play,
        )
        v.setContentDescription(
            R.id.play_pause,
            ctx.getString(if (s.playing) R.string.widget_pause else R.string.widget_play),
        )
        v.setOnClickPendingIntent(R.id.play_pause, action(ctx, WidgetActionReceiver.ACTION_PLAY_PAUSE, 2))
        if (compact) {
            v.setOnClickPendingIntent(R.id.previous, action(ctx, WidgetActionReceiver.ACTION_PREVIOUS, 1))
            v.setOnClickPendingIntent(R.id.next, action(ctx, WidgetActionReceiver.ACTION_NEXT, 3))
        }
        // Explicit component: the launcher alias in use changes with the icon theme.
        val open = Intent(ctx, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        v.setOnClickPendingIntent(
            R.id.cover,
            PendingIntent.getActivity(ctx, 4, open, PendingIntent.FLAG_IMMUTABLE),
        )
        return v
    }

    protected fun refreshWith(ctx: Context, provider: Class<*>) {
        val manager = AppWidgetManager.getInstance(ctx)
        val ids = manager.getAppWidgetIds(ComponentName(ctx, provider))
        if (ids.isNotEmpty()) onUpdate(ctx, manager, ids)
    }
}

class NowPlayingWidget4x1 : NowPlayingWidget(R.layout.widget_now_playing_4x1, true) {
    companion object {
        fun refresh(ctx: Context) =
            NowPlayingWidget4x1().refreshWith(ctx, NowPlayingWidget4x1::class.java)
    }
}

class NowPlayingWidget2x2 : NowPlayingWidget(R.layout.widget_now_playing_2x2, false) {
    companion object {
        fun refresh(ctx: Context) =
            NowPlayingWidget2x2().refreshWith(ctx, NowPlayingWidget2x2::class.java)
    }
}
