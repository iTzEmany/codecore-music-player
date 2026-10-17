package com.codecore.player

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger

/** The `lite` flavor has no yt-dlp: the channel does not exist. */
@Suppress("UNUSED_PARAMETER")
class YtDlpChannel(applicationContext: Context) {
    fun register(messenger: BinaryMessenger) {}
}
