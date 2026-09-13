package com.sorathuchi.sora_thu_chi

import android.content.Context
import android.os.Build
import android.os.Environment
import android.os.StatFs
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Kênh native `sora_thu_chi/device_probe` — 3 chỉ số thiết bị mà Flutter không
 * đọc được: dung lượng trống, có AICore (Gemini Nano) hay không, và chip có
 * đường tăng tốc (NNAPI) hay không. Chặng 2 cắm tiếp phần gọi Gemini Nano vào
 * chính kênh này (R5). Mọi lỗi trả `null` — tầng Dart bọc try/catch với mặc
 * định an toàn (dung lượng 0 ⇒ Tier C, luồng quét vẫn chạy).
 */
class DeviceProbeChannel(
    private val context: Context,
    private val genAi: GenAiChannel,
) {
    companion object {
        const val CHANNEL = "sora_thu_chi/device_probe"

        fun register(messenger: BinaryMessenger, context: Context) {
            MethodChannel(messenger, CHANNEL).setMethodCallHandler(
                DeviceProbeChannel(context, GenAiChannel.create())::onCall,
            )
        }
    }

    private fun onCall(call: MethodCall, result: MethodChannel.Result) {
        // Tier A dùng chung kênh này (R5/R18) — nhường trước khi tới "probe".
        if (genAi.handle(call, result)) return
        when (call.method) {
            "probe" -> result.success(
                mapOf(
                    "freeStorageGb" to freeStorageGb(),
                    "supportsOnDeviceAi" to hasAiCore(),
                    "supportsGpuDelegate" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1),
                ),
            )
            else -> result.notImplemented()
        }
    }

    /** Dung lượng trống của phân vùng dữ liệu, GB (1 GB = 10^9 byte). */
    private fun freeStorageGb(): Double {
        val stat = StatFs(Environment.getDataDirectory().path)
        return stat.availableBytes / 1_000_000_000.0
    }

    /** Có module AICore của hệ thống (điều kiện Tier A) hay không. */
    private fun hasAiCore(): Boolean = try {
        context.packageManager.getPackageInfo("com.google.android.aicore", 0)
        true
    } catch (_: Exception) {
        false
    }
}
