package com.codecore.player

import io.flutter.plugin.common.MethodChannel

/** Lets broadcast receivers (notification buttons) reach the Dart side. */
object ShareBridge {
    @Volatile
    var channel: MethodChannel? = null
}
