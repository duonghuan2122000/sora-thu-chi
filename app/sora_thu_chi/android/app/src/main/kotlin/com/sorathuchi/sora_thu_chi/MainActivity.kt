package com.sorathuchi.sora_thu_chi

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// local_auth cần Activity kế thừa FragmentActivity (BiometricPrompt bắt buộc) —
// FlutterActivity thường không đủ, canCheckBiometrics/authenticate() sẽ lỗi
// âm thầm hoặc luôn trả false.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        DeviceProbeChannel.register(flutterEngine.dartExecutor.binaryMessenger, applicationContext)
    }
}
