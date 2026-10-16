package com.codecore.player

import android.os.Handler
import android.os.Looper
import com.ryanheise.audioservice.AudioServiceActivity
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Hosts yt-dlp (embedded Python + QuickJS) for the YouTube feature. No backend:
 * everything runs inside the app process tree.
 */
class MainActivity : AudioServiceActivity() {
    private val executor = Executors.newCachedThreadPool()
    private val main = Handler(Looper.getMainLooper())
    private lateinit var channel: MethodChannel
    private var initialized = false
    private var updateTried = false

    override fun onResume() {
        super.onResume()
        ShareBridge.foreground = true
        ShareBridge.channel?.invokeMethod("appResumed", null)
    }

    override fun onPause() {
        ShareBridge.foreground = false
        super.onPause()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "codecore/ytdlp")
        channel.setMethodCallHandler { call, result -> handle(call, result) }

        val share = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "codecore/share")
        ShareBridge.channel = share
        share.setMethodCallHandler { call, result ->
            val ctx = applicationContext
            when (call.method) {
                "startService" -> {
                    ReceiveService.start(
                        ctx,
                        call.argument<String>("title") ?: "Codecore",
                        call.argument<String>("text") ?: "",
                        call.argument<String>("disable") ?: "Stop",
                    )
                    result.success(null)
                }
                "stopService" -> {
                    ReceiveService.stop(ctx)
                    result.success(null)
                }
                "showOffer" -> {
                    ShareNotifications.showOffer(
                        ctx,
                        call.argument<String>("offerId")!!,
                        call.argument<String>("title") ?: "",
                        call.argument<String>("body") ?: "",
                        call.argument<String>("accept") ?: "OK",
                        call.argument<String>("decline") ?: "No",
                    )
                    result.success(null)
                }
                "isForeground" -> result.success(ShareBridge.foreground)
                "deviceName" -> {
                    // The user-visible device name, falling back to the model.
                    val name = try {
                        android.provider.Settings.Global.getString(
                            ctx.contentResolver, "device_name")
                    } catch (e: Exception) {
                        null
                    }
                    result.success(if (name.isNullOrBlank()) android.os.Build.MODEL else name)
                }
                "clearOffer" -> {
                    ShareNotifications.clearOffer(ctx, call.argument<String>("offerId")!!)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
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
            "download" -> run(result) {
                ensureInit()
                val id = call.argument<String>("id")!!
                val stem = call.argument<String>("stem")!!
                val convert = call.argument<Boolean>("convert") ?: true
                val processId = call.argument<String>("processId")!!
                val req = YoutubeDLRequest("https://www.youtube.com/watch?v=$id")
                req.addOption("--no-playlist")
                req.addOption("--no-warnings")
                req.addOption("--no-part")
                req.addOption("-f", if (convert) "bestaudio/best" else "bestaudio[ext=m4a]/bestaudio/best")
                if (convert) {
                    req.addOption("-x")
                    req.addOption("--audio-format", "mp3")
                    req.addOption("--audio-quality", "256K")
                }
                val rate = call.argument<Int>("rateLimit")
                if (rate != null && rate > 0) req.addOption("--limit-rate", "${rate}K")
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
