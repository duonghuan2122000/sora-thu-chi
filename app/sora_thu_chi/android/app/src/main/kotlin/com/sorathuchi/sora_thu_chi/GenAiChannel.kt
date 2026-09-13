package com.sorathuchi.sora_thu_chi

import com.google.mlkit.genai.prompt.Generation
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Tier A — Gemini Nano qua ML Kit GenAI Prompt API (R18). Dùng lại chính kênh
 * `sora_thu_chi/device_probe` sẵn có (R5) thay vì dựng kênh thứ hai: chỉ thêm
 * method `genAiGenerate`.
 *
 * Model do AICore của hệ thống quản lý — **không** tải về app. Mọi lỗi (máy
 * không hỗ trợ, model chưa sẵn sàng, engine bận) trả `error` để tầng Dart rơi về
 * bộ luật (FR-011).
 */
class GenAiChannel(private val scope: CoroutineScope) {
    private val model by lazy { Generation.getClient() }

    /** Trả `true` nếu đã xử lý [call] — ngược lại để kênh cha xử lý tiếp. */
    fun handle(call: MethodCall, result: MethodChannel.Result): Boolean = when (call.method) {
        "genAiGenerate" -> {
            generate(call.argument<String>("prompt"), result)
            true
        }
        else -> false
    }

    private fun generate(prompt: String?, result: MethodChannel.Result) {
        if (prompt == null) {
            result.error("bad_args", "Thiếu prompt", null)
            return
        }
        scope.launch {
            try {
                val response = model.generateContent(prompt)
                result.success(response.candidates.firstOrNull()?.text)
            } catch (e: Exception) {
                result.error("genai_failed", e.message, null)
            }
        }
    }

    companion object {
        fun create(): GenAiChannel = GenAiChannel(CoroutineScope(Dispatchers.Main))
    }
}
