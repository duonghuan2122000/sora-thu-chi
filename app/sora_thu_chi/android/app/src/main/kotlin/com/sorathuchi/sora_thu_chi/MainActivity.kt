package com.sorathuchi.sora_thu_chi

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        DeviceProbeChannel.register(flutterEngine.dartExecutor.binaryMessenger, applicationContext)
    }
}
