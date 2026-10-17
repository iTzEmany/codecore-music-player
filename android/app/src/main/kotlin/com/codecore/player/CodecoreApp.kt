package com.codecore.player

import android.content.SharedPreferences
import android.app.Application

/**
 * Lives as long as the process, with or without the activity: it redraws the
 * widget and the tile whenever Dart writes a new snapshot.
 */
class CodecoreApp : Application() {
    // Held in a field: the preferences keep only a weak reference.
    private val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        if (key == "flutter.widget.stamp") WidgetStore.refresh(this)
    }

    override fun onCreate() {
        super.onCreate()
        WidgetStore.processStartMs = System.currentTimeMillis()
        getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            .registerOnSharedPreferenceChangeListener(listener)
    }
}
