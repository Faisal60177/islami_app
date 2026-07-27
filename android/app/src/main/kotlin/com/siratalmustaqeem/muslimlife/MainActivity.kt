package com.siratalmustaqeem.muslimlife

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity(){
    private val CHANNEL = "muslim_life/ringer_mode"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getRingerMode") {
                val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                // 0 = silent, 1 = vibrate, 2 = normal (Android-এর নিজস্ব constant)
                result.success(audioManager.ringerMode)
            } else {
                result.notImplemented()
            }
        }
    }
}