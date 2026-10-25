package com.codecore.player

import android.app.Activity
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.FileInputStream

/**
 * `codecore/save`: `saveFile({path, name, mime})` lets the user pick a target
 * (system "create document" dialog) and streams the file there, so a big file
 * never goes through the channel nor the heap. Answers true when saved, false
 * when cancelled. One request at a time.
 */
object SaveFileBridge {
    private const val REQUEST_CODE = 6028
    private const val TAG = "SaveFileBridge"
    private val main = Handler(Looper.getMainLooper())
    private var pending: MethodChannel.Result? = null
    private var pendingPath: String = ""

    /** The engine is gone: its pending reply can no longer be delivered. */
    fun detach() {
        pending = null
        pendingPath = ""
    }

    fun register(messenger: BinaryMessenger, activity: Activity) {
        MethodChannel(messenger, "codecore/save").setMethodCallHandler { call, result ->
            if (call.method != "saveFile") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val path = call.argument<String>("path")
            val name = call.argument<String>("name")
            if (path == null || name == null) {
                result.error("args", "path and name are required", null)
                return@setMethodCallHandler
            }
            if (pending != null) {
                result.error("busy", "A save request is already open", null)
                return@setMethodCallHandler
            }
            pending = result
            pendingPath = path
            try {
                val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = call.argument<String>("mime") ?: "application/octet-stream"
                    putExtra(Intent.EXTRA_TITLE, name)
                }
                @Suppress("DEPRECATION")
                activity.startActivityForResult(intent, REQUEST_CODE)
            } catch (e: Exception) {
                Log.w(TAG, "launch failed", e)
                fail(e)
            }
        }
    }

    private fun fail(e: Exception) {
        val result = pending
        pending = null
        pendingPath = ""
        result?.error("failed", e.message, null)
    }

    /** Returns true when the result was ours. */
    fun onActivityResult(activity: Activity, requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pending
        val path = pendingPath
        pending = null
        pendingPath = ""
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result?.success(false)
            return true
        }
        // The copy blocks: off the main thread.
        Thread {
            try {
                FileInputStream(path).use { input ->
                    activity.contentResolver.openOutputStream(uri)!!.use { input.copyTo(it, 1 shl 16) }
                }
                main.post { result?.success(true) }
            } catch (e: Exception) {
                Log.w(TAG, "copy failed", e)
                main.post { result?.error("failed", e.message, null) }
            }
        }.start()
        return true
    }
}
