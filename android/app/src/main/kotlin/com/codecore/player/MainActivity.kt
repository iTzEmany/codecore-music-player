package com.codecore.player

import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** The single activity: hosts the platform channels the Dart side uses. */
class MainActivity : AudioServiceActivity() {
    private val main = Handler(Looper.getMainLooper())

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
        // yt-dlp lives in the `full` flavor only (see YtDlpChannel).
        YtDlpChannel(applicationContext).register(flutterEngine.dartExecutor.binaryMessenger)
        ImportBridge.register(flutterEngine.dartExecutor.binaryMessenger, applicationContext)
        MediaDeleteBridge.register(flutterEngine.dartExecutor.binaryMessenger, this)
        StorageBridge.register(flutterEngine.dartExecutor.binaryMessenger)

        // Where the sound goes (headphones or speaker): the equalizer keeps a
        // curve for each.
        val audio = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "codecore/audio")
        audio.setMethodCallHandler { call, result ->
            if (call.method == "outputRoute") result.success(currentOutputRoute())
            else result.notImplemented()
        }
        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        audioManager.registerAudioDeviceCallback(object : AudioDeviceCallback() {
            override fun onAudioDevicesAdded(added: Array<out AudioDeviceInfo>) = pushRoute(audio)
            override fun onAudioDevicesRemoved(removed: Array<out AudioDeviceInfo>) = pushRoute(audio)
        }, main)

        // Car mode: keep the screen on while it is open.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "codecore/screen")
            .setMethodCallHandler { call, result ->
                if (call.method == "keepOn") {
                    val on = call.arguments as? Boolean ?: false
                    if (on) window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    else window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    result.success(null)
                } else result.notImplemented()
            }

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

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        if (MediaDeleteBridge.onActivityResult(requestCode, resultCode)) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun pushRoute(audio: MethodChannel) {
        audio.invokeMethod("outputRoute", currentOutputRoute())
    }

    /** `headphones` when wired, Bluetooth or USB headphones are connected, else `speaker`. */
    private fun currentOutputRoute(): String {
        val am = getSystemService(AUDIO_SERVICE) as AudioManager
        val types = mutableSetOf(
            AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
            AudioDeviceInfo.TYPE_WIRED_HEADSET,
            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
            AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
            AudioDeviceInfo.TYPE_USB_HEADSET,
        )
        if (Build.VERSION.SDK_INT >= 31) types.add(AudioDeviceInfo.TYPE_BLE_HEADSET)
        val headphones = am.getDevices(AudioManager.GET_DEVICES_OUTPUTS).any { it.type in types }
        return if (headphones) "headphones" else "speaker"
    }
}
