package com.codecore.player

import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.view.KeyEvent

/** Quick-settings tile: play/pause, labelled with the track being played. */
class PlayTileService : TileService() {
    override fun onStartListening() = render()

    override fun onClick() {
        android.util.Log.i("codecore", "tile: click")
        MediaKeys.pressSurely(this, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE) {}
    }

    private fun render() {
        val tile = qsTile ?: return
        val s = WidgetStore.snapshot(this)
        tile.label = s.title ?: getString(R.string.tile_label)
        tile.state = if (s.playing) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.updateTile()
    }
}
