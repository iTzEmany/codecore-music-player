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
        val main = Handler(Looper.getMainLooper())
        val push = { main.post { channel.invokeMethod("changed", null) }; Unit }
        try {
            cm.registerDefaultNetworkCallback(object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) = push()
                override fun onLost(network: Network) = push()
                override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) = push()
            })
        } catch (e: SecurityException) {
            // No ACCESS_NETWORK_STATE: the answer to isMetered still works.
        }
    }
}
