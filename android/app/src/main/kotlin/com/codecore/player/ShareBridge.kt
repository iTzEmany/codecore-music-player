package com.codecore.player

import io.flutter.plugin.common.MethodChannel

/** Lets broadcast receivers (notification buttons) reach the Dart side. */
object ShareBridge {
    @Volatile
    var channel: MethodChannel? = null

    /** True while the activity is resumed (the lifecycle seen by Flutter is unreliable with a cached engine). */
    @Volatile
    var foreground: Boolean = false
}
