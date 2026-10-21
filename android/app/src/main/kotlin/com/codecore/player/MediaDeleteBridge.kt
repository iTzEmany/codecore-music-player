package com.codecore.player

import android.app.Activity
import android.content.ContentUris
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.os.Build
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

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
    private const val TAG = "MediaDeleteBridge"
    private val main = Handler(Looper.getMainLooper())
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
            Log.i(TAG, "deleteFiles: ${paths.size} path(s): $paths")
            pending = result
            pendingPaths = paths
            // The lookups block (queries, media scanner): off the main thread.
            Thread {
                try {
                    val uris = findUris(activity, paths)
                    main.post {
                        try {
                            if (uris.isEmpty()) {
                                // Unknown to MediaStore: nothing the system can delete.
                                Log.i(TAG, "no URI found: nothing to ask the system")
                                finish()
                            } else {
                                val sender = MediaStore.createDeleteRequest(
                                    activity.contentResolver, uris).intentSender
                                Log.i(TAG, "launching the delete request for ${uris.size} URI(s)")
                                activity.startIntentSenderForResult(sender, REQUEST_CODE, null, 0, 0, 0)
                            }
                        } catch (e: Exception) {
                            Log.w(TAG, "launch failed", e)
                            fail(e)
                        }
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "lookup failed", e)
                    main.post { fail(e) }
                }
            }.start()
        }
    }

    private fun finish() {
        val result = pending
        val paths = pendingPaths
        pending = null
        pendingPaths = emptyList()
        // Refused or accepted, the truth is what is left on disk.
        result?.success(gone(paths))
    }

    private fun fail(e: Exception) {
        val result = pending
        pending = null
        pendingPaths = emptyList()
        result?.error("failed", e.message, null)
    }

    /** Returns true when the result was ours. */
    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode != REQUEST_CODE) return false
        Log.i(TAG, "onActivityResult: request=$requestCode result=$resultCode")
        finish()
        return true
    }

    private fun gone(paths: List<String>) = paths.filter { !File(it).exists() }

    /**
     * MediaStore content URIs of [paths]: `_data` queries on the audio and
     * file collections (one IN query, then path by path), then the media
     * scanner, which answers with the URI of a file it indexes.
     */
    private fun findUris(activity: Activity, paths: List<String>): List<Uri> {
        val found = LinkedHashMap<String, Uri>()
        val sources = listOf(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY),
            MediaStore.Files.getContentUri("external"),
        )
        val columns = arrayOf(MediaStore.MediaColumns._ID, MediaStore.MediaColumns.DATA)
        for (source in sources) {
            val before = found.size
            val missing = paths.filter { it !in found }
            if (missing.isEmpty()) break
            try {
                for (chunk in missing.chunked(400)) {
                    val marks = chunk.joinToString(",") { "?" }
                    queryInto(activity, source, columns,
                        "${MediaStore.MediaColumns.DATA} IN ($marks)", chunk.toTypedArray(), found)
                }
                for (path in missing.filter { it !in found }) {
                    queryInto(activity, source, columns,
                        "${MediaStore.MediaColumns.DATA} = ?", arrayOf(path), found)
                }
            } catch (e: Exception) {
                Log.w(TAG, "query on $source failed", e)
            }
            Log.i(TAG, "source $source: ${found.size - before} URI(s) found")
        }
        val unknown = paths.filter { it !in found && File(it).exists() }
        if (unknown.isNotEmpty()) {
            val latch = CountDownLatch(unknown.size)
            MediaScannerConnection.scanFile(activity, unknown.toTypedArray(), null) { path, uri ->
                Log.i(TAG, "scanner: $path -> $uri")
                if (uri != null) synchronized(found) { found[path] = uri }
                latch.countDown()
            }
            latch.await(5, TimeUnit.SECONDS)
        }
        Log.i(TAG, "URIs: ${found.size} of ${paths.size} path(s)")
        return found.values.toList()
    }

    private fun queryInto(
        activity: Activity, source: Uri, columns: Array<String>,
        selection: String, args: Array<String>, into: MutableMap<String, Uri>,
    ) {
        activity.contentResolver.query(source, columns, selection, args, null)?.use { c ->
            while (c.moveToNext()) {
                into[c.getString(1)] = ContentUris.withAppendedId(source, c.getLong(0))
            }
        }
    }
}
