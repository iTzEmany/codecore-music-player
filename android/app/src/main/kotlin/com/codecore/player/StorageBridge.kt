package com.codecore.player

import android.os.StatFs
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * `codecore/storage`: `diskSpace({path})` answers `{total, free}` in bytes for
 * the volume the path is on (the nearest existing parent when the folder is
 * gone), for the «Memoria» tab.
 */
object StorageBridge {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "codecore/storage").setMethodCallHandler { call, result ->
            if (call.method != "diskSpace") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val path = call.argument<String>("path")
            if (path == null) {
                result.error("bad_args", "path is required", null)
                return@setMethodCallHandler
            }
            try {
                var dir: File? = File(path)
                while (dir != null && !dir.exists()) dir = dir.parentFile
                val stat = StatFs((dir ?: File("/")).path)
                result.success(mapOf("total" to stat.totalBytes, "free" to stat.availableBytes))
            } catch (e: Exception) {
                result.error("stat_failed", e.message, null)
            }
        }
    }
}
