package com.codecore.player

import android.app.Activity
import android.content.ContentUris
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * `codecore/media`: deletes audio files the app did not create. Since Android
 * 11 a plain `File.delete` is refused for them; the one way is a MediaStore
 * delete request, which shows ONE system dialog for the whole batch.
 *
 * `deleteFiles({paths})` answers with the paths that no longer exist. Android
 * 10 and older: an empty list (no fallback). One request at a time.
 */
object MediaDeleteBridge {
    private const val REQUEST_CODE = 6027
    private var pending: MethodChannel.Result? = null
    private var pendingPaths: List<String> = emptyList()

    fun register(messenger: BinaryMessenger, activity: Activity) {
        MethodChannel(messenger, "codecore/media").setMethodCallHandler { call, result ->
            if (call.method != "deleteFiles") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val paths = call.argument<List<String>>("paths") ?: emptyList()
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R || paths.isEmpty()) {
                result.success(emptyList<String>())
                return@setMethodCallHandler
            }
            if (pending != null) {
                result.error("busy", "A delete request is already open", null)
                return@setMethodCallHandler
            }
            try {
                val uris = findUris(activity, paths)
                if (uris.isEmpty()) {
                    // Unknown to MediaStore: nothing the system can delete.
                    result.success(gone(paths))
                    return@setMethodCallHandler
                }
                val sender = MediaStore.createDeleteRequest(activity.contentResolver, uris).intentSender
                pending = result
                pendingPaths = paths
                activity.startIntentSenderForResult(sender, REQUEST_CODE, null, 0, 0, 0)
            } catch (e: Exception) {
                pending = null
                result.error("failed", e.message, null)
            }
        }
    }

    /** Returns true when the result was ours. */
    fun onActivityResult(requestCode: Int): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pending
        val paths = pendingPaths
        pending = null
        pendingPaths = emptyList()
        // Refused or accepted, the truth is what is left on disk.
        result?.success(gone(paths))
        return true
    }

    private fun gone(paths: List<String>) = paths.filter { !File(it).exists() }

    /** MediaStore content URIs of [paths]: audio first, any file as a second try. */
    private fun findUris(activity: Activity, paths: List<String>): List<Uri> {
        val found = LinkedHashMap<String, Uri>()
        val sources = listOf(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            MediaStore.Files.getContentUri("external"),
        )
        for (source in sources) {
            val missing = paths.filter { it !in found }
            if (missing.isEmpty()) break
            for (chunk in missing.chunked(400)) {
                val marks = chunk.joinToString(",") { "?" }
                activity.contentResolver.query(
                    source,
                    arrayOf(MediaStore.MediaColumns._ID, MediaStore.MediaColumns.DATA),
                    "${MediaStore.MediaColumns.DATA} IN ($marks)",
                    chunk.toTypedArray(),
                    null,
                )?.use { c ->
                    while (c.moveToNext()) {
                        found[c.getString(1)] = ContentUris.withAppendedId(source, c.getLong(0))
                    }
                }
            }
        }
        return found.values.toList()
    }
}
