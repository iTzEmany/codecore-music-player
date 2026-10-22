package com.codecore.player

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * `codecore/icon`: the launcher icon is one of 16 activity-aliases of
 * MainActivity (`.IconViolaDark`...). `setIcon("viola_dark")` only remembers
 * the wanted one; [apply] switches when the app goes to the background,
 * because changing the enabled alias while the user looks at it can make the
 * launcher kill the app. `current` answers the alias that is enabled now.
 */
object IconBridge {
    private const val TAG = "IconBridge"
    private const val DEFAULT = "viola_dark"
    private val variants = listOf("viola", "blu", "acqua", "verde", "ambra", "arancio", "rosa", "rosso")
        .flatMap { a -> listOf("dark", "light").map { g -> "${a}_$g" } }

    @Volatile private var wanted: String? = null

    fun register(messenger: BinaryMessenger, context: Context) {
        MethodChannel(messenger, "codecore/icon").setMethodCallHandler { call, result ->
            when (call.method) {
                "setIcon" -> {
                    val v = call.argument<String>("variant")
                    if (v in variants) {
                        wanted = v
                        result.success(null)
                    } else result.error("bad_variant", "unknown icon variant: $v", null)
                }
                "current" -> result.success(enabled(context))
                else -> result.notImplemented()
            }
        }
    }

    private fun alias(context: Context, variant: String): ComponentName {
        val (accent, ground) = variant.split('_')
        // Class names follow the namespace, not the applicationId (the perf build differs).
        return ComponentName(context, "com.codecore.player.Icon${accent.cap()}${ground.cap()}")
    }

    private fun String.cap() = replaceFirstChar { it.uppercase() }

    private fun enabled(context: Context): String = variants.firstOrNull { isEnabled(context, it) } ?: DEFAULT

    /** Called from MainActivity.onStop. Enables the new alias before disabling the others. */
    fun apply(context: Context) {
        val target = wanted ?: return
        try {
            val pm = context.packageManager
            if (!isEnabled(context, target)) setState(pm, context, target, PackageManager.COMPONENT_ENABLED_STATE_ENABLED)
            // No early return: a partial failure earlier may have left other aliases enabled.
            for (v in variants) {
                if (v != target && isEnabled(context, v)) {
                    setState(pm, context, v, PackageManager.COMPONENT_ENABLED_STATE_DISABLED)
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "could not switch the launcher icon to $target", e)
        }
    }

    private fun setState(pm: PackageManager, context: Context, variant: String, state: Int) =
        pm.setComponentEnabledSetting(alias(context, variant), state, PackageManager.DONT_KILL_APP)

    private fun isEnabled(context: Context, variant: String): Boolean {
        val s = context.packageManager.getComponentEnabledSetting(alias(context, variant))
        return s == PackageManager.COMPONENT_ENABLED_STATE_ENABLED ||
            (s == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT && variant == DEFAULT)
    }
}
