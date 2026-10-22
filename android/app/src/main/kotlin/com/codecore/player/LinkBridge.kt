package com.codecore.player

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * `codecore/link`: `openUrl` shows an https address in the browser (ACTION_VIEW)
 * and answers whether something could handle it; `deviceInfo` gives the model,
 * Android release and the app's build number for «Segnala un problema».
 */
object LinkBridge {
    fun register(messenger: BinaryMessenger, context: Context) {
        MethodChannel(messenger, "codecore/link").setMethodCallHandler { call, result ->
            when (call.method) {
                "openUrl" -> result.success(openUrl(context, call.argument<String>("url") ?: ""))
                "deviceInfo" -> result.success(deviceInfo(context))
                else -> result.notImplemented()
            }
        }
    }

    private fun openUrl(ctx: Context, url: String): Boolean {
        val uri = Uri.parse(url)
        if (uri.scheme != "https") return false
        return try {
            ctx.startActivity(
                Intent(Intent.ACTION_VIEW, uri).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            true
        } catch (e: Exception) {
            false
        }
    }

    @Suppress("DEPRECATION")
    private fun deviceInfo(ctx: Context): Map<String, String> {
        val build = try {
            val info = ctx.packageManager.getPackageInfo(ctx.packageName, 0)
            info.versionCode.toString()
        } catch (e: Exception) {
            "?"
        }
        return mapOf(
            "model" to "${Build.MANUFACTURER} ${Build.MODEL}",
            "os" to "${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})",
            "build" to build,
        )
    }
}
