package com.codecore.player

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * `codecore/net`: `isMetered` answers `{metered, online}` for the active
 * network (`online: false`, `metered: false` with none), and `changed` is
 * pushed to Dart whenever the active network or its metered flag changes.
 * Shuffle+ uses it to stay off mobile data.
 */
object NetworkBridge {
    private var callback: ConnectivityManager.NetworkCallback? = null
    private var cm: ConnectivityManager? = null
    private var lastState: Pair<Boolean, Boolean>? = null

    fun register(messenger: BinaryMessenger, context: Context) {
        val channel = MethodChannel(messenger, "codecore/net")
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        channel.setMethodCallHandler { call, result ->
            if (call.method != "isMetered") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val network = cm.activeNetwork
            val online = network != null &&
                cm.getNetworkCapabilities(network)
                    ?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
            result.success(mapOf("metered" to (online && cm.isActiveNetworkMetered), "online" to online))
        }
        // One callback per registration: a new engine drops the previous one.
        unregister()
        val main = Handler(Looper.getMainLooper())
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) = push()
            override fun onLost(network: Network) = push()
            override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) = push()

            private fun push() {
                main.post {
                    // Never talk to a detached engine; only report real changes.
                    if (this@NetworkBridge.callback !== this) return@post
                    val state = stateOf(cm)
                    if (state == lastState) return@post
                    lastState = state
                    channel.invokeMethod("changed", null)
                }
            }
        }
        this.callback = callback
        this.cm = cm
        lastState = stateOf(cm)
        try {
            cm.registerDefaultNetworkCallback(callback)
        } catch (e: SecurityException) {
            // No ACCESS_NETWORK_STATE: the answer to isMetered still works.
            this.callback = null
        }
    }

    /** Called when the engine goes away: stop listening, stop sending. */
    fun unregister() {
        val cb = callback ?: return
        callback = null
        try {
            cm?.unregisterNetworkCallback(cb)
        } catch (e: IllegalArgumentException) {
            // Already unregistered.
        }
        cm = null
    }

    private fun stateOf(cm: ConnectivityManager): Pair<Boolean, Boolean> {
        val network = cm.activeNetwork
        val online = network != null &&
            cm.getNetworkCapabilities(network)
                ?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
        return Pair(online && cm.isActiveNetworkMetered, online)
    }
}
