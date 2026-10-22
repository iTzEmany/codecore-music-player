package com.codecore.player

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Hosts yt-dlp (embedded Python + QuickJS) for the YouTube feature. No backend:
 * everything runs inside the app process tree. Only in the `full` flavor.
 */
class YtDlpChannel(private val applicationContext: Context) {
    private val executor = Executors.newCachedThreadPool()
    private val main = Handler(Looper.getMainLooper())
    private lateinit var channel: MethodChannel
    private var initialized = false
    private var updateTried = false

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, "codecore/ytdlp")
        channel.setMethodCallHandler { call, result -> handle(call, result) }
    }

    @Synchronized
    private fun ensureInit() {
        if (initialized) return
        YoutubeDL.getInstance().init(applicationContext)
        FFmpeg.getInstance().init(applicationContext)
        initialized = true
    }

    /** Best effort: YouTube changes often, so pull the latest stable yt-dlp once per run. */
    @Synchronized
    private fun updateOnce() {
        if (updateTried) return
        updateTried = true
        try {
            YoutubeDL.getInstance().updateYoutubeDL(
                applicationContext, YoutubeDL.UpdateChannel.STABLE
            )
        } catch (e: Exception) {
            android.util.Log.w("codecore", "yt-dlp update failed: ${e.message}")
        }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "search" -> run(result) {
                ensureInit()
                updateOnce()
                val query = call.argument<String>("query")!!
                val isUrl = call.argument<Boolean>("isUrl") ?: false
                // `items` = a search page with full metadata for the first N results.
                val items = call.argument<Int>("items")
                val req = YoutubeDLRequest(if (isUrl) query else "ytsearch10:$query")
                req.addOption("-J")
                req.addOption("--no-warnings")
                val flat = call.argument<Boolean>("flat") ?: false
                if (items != null) {
                    req.addOption("--playlist-items", "1-$items")
                    if (flat) req.addOption("--flat-playlist")
                } else {
                    req.addOption(if (isUrl) "--no-playlist" else "--flat-playlist")
                }
                val processId = call.argument<String>("processId")
                if (processId != null) YoutubeDL.getInstance().execute(req, processId).out
                else YoutubeDL.getInstance().execute(req).out
            }
            // The direct address of a result's audio, for listening without
            // downloading (`yt-dlp -g`).
            "streamUrl" -> run(result) {
                ensureInit()
                val req = YoutubeDLRequest(call.argument<String>("url")!!)
                req.addOption("-g")
                req.addOption("--no-warnings")
                req.addOption("--no-playlist")
                // android_vr: direct audio URLs without the JS challenge or a PO token.
                if (call.argument<Boolean>("fast") == true) {
                    req.addOption("--extractor-args", "youtube:player_client=android_vr")
                }
                req.addOption("-f", call.argument<String>("format") ?: "bestaudio/best")
                val processId = call.argument<String>("processId")
                if (processId != null) YoutubeDL.getInstance().execute(req, processId).out
                else YoutubeDL.getInstance().execute(req).out
            }
            "download" -> run(result) {
                ensureInit()
                val id = call.argument<String>("id")!!
                val stem = call.argument<String>("stem")!!
                val processId = call.argument<String>("processId")!!
                // `url` is sent by every caller; the id alone stays for older ones.
                val url = call.argument<String>("url") ?: "https://www.youtube.com/watch?v=$id"
                val req = YoutubeDLRequest(url)
                req.addOption("--no-playlist")
                req.addOption("--no-warnings")
                req.addOption("--no-part")
                // Stream and conversion are chosen on the Dart side (downloadChoice);
                // no audioFormat = the codec as served, only taken out of the video container.
                req.addOption("-f", call.argument<String>("selector") ?: "bestaudio[ext=m4a]/bestaudio/best")
                req.addOption("-x")
                val audioFormat = call.argument<String>("audioFormat")
                if (audioFormat != null) {
                    req.addOption("--audio-format", audioFormat)
                    req.addOption("--audio-quality", call.argument<String>("audioQuality") ?: "192K")
                }
                val rate = call.argument<Int>("rateLimit")
                if (rate != null && rate > 0) {
                    req.addOption("--limit-rate", "${rate}K")
                    // yt-dlp hands plain `m3u8` streams to ffmpeg, which ignores --limit-rate:
                    // force the native HLS downloader so the limit really applies.
                    req.addOption("--downloader", "m3u8:native")
                }
                req.addOption("-o", "$stem.%(ext)s")
                YoutubeDL.getInstance().execute(req, processId) { progress, _, line ->
                    main.post {
                        channel.invokeMethod(
                            "progress",
                            mapOf("processId" to processId, "percent" to progress.toDouble(), "line" to line)
                        )
                    }
                }
                val dir = File(stem).parentFile
                val base = File(stem).name
                dir?.listFiles()
                    ?.firstOrNull { it.name.startsWith("$base.") && !it.name.endsWith(".part") }
                    ?.absolutePath
                    ?: throw IllegalStateException("output file not found")
            }
            "version" -> run(result) {
                ensureInit()
                YoutubeDL.getInstance().version(applicationContext)
            }
            "cancel" -> {
                val processId = call.argument<String>("processId")
                if (processId != null) YoutubeDL.getInstance().destroyProcessById(processId)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun run(result: MethodChannel.Result, block: () -> Any?) {
        executor.execute {
            try {
                val value = block()
                main.post { result.success(value) }
            } catch (e: Throwable) {
                main.post { result.error("YTDLP", e.message ?: e.toString(), null) }
            }
        }
    }
}
