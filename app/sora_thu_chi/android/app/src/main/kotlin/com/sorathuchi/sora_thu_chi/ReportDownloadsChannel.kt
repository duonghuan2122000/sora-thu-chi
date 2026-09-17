package com.sorathuchi.sora_thu_chi

import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Kênh native `sora_thu_chi/report_downloads` (PBI 41) — ghi tệp báo cáo vào
 * thư mục Tải xuống **công khai** của thiết bị, việc mà không dependency Flutter
 * nào đã cài đặt làm đúng tự động (đã thử `file_saver`: chỉ ghi thư mục riêng
 * app, xem `research.md` PBI 41 Quyết định 1).
 *
 * Android 10+ (API 29+): `MediaStore.Downloads`, không cần xin quyền runtime,
 * và hệ thống **tự đổi tên tránh trùng** khi `DISPLAY_NAME` đã tồn tại (FR-004).
 * Android 8–9 (API 26–28): ghi thẳng `Environment.DIRECTORY_DOWNLOADS`, cần
 * quyền `WRITE_EXTERNAL_STORAGE` đã xin từ phía Dart (`permission_handler`)
 * trước khi gọi kênh này — thiếu quyền trả lỗi `permission_denied`, và tự dò
 * trùng tên bằng vòng lặp `File.exists()` (MediaStore không áp dụng ở nhánh này).
 */
class ReportDownloadsChannel(private val context: Context) {
    companion object {
        const val CHANNEL = "sora_thu_chi/report_downloads"

        fun register(messenger: BinaryMessenger, context: Context) {
            MethodChannel(messenger, CHANNEL).setMethodCallHandler(
                ReportDownloadsChannel(context)::onCall,
            )
        }
    }

    private fun onCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "saveToDownloads" -> {
                val name = call.argument<String>("name")
                val bytes = call.argument<ByteArray>("bytes")
                val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                if (name == null || bytes == null) {
                    result.error("invalid_args", "Thiếu name hoặc bytes", null)
                    return
                }
                try {
                    val saved = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        saveViaMediaStore(name, bytes, mimeType)
                    } else {
                        saveLegacy(name, bytes)
                    }
                    if (saved == null) {
                        result.error("permission_denied", "Chưa có quyền lưu trữ", null)
                    } else {
                        result.success(mapOf("path" to saved.first, "fileName" to saved.second))
                    }
                } catch (e: Exception) {
                    result.error("save_failed", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    /** Android 10+ — trả `path`/`fileName` thật sự sau khi hệ thống tự dò trùng tên. */
    private fun saveViaMediaStore(name: String, bytes: ByteArray, mimeType: String): Pair<String, String> {
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
        }
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("Không tạo được entry MediaStore")
        resolver.openOutputStream(uri)?.use { it.write(bytes) }
            ?: throw IllegalStateException("Không mở được luồng ghi MediaStore")
        val actualName = resolver.query(uri, arrayOf(MediaStore.MediaColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME))
                } else null
            } ?: name
        // `RELATIVE_PATH` chỉ để **ghi** qua MediaStore — `share_plus` cần path
        // TUYỆT ĐỐI thật trên đĩa (nó tự mở `File(path)` để copy vào cache chia
        // sẻ), nên phải quy về đường dẫn công khai thay vì trả path tương đối
        // "Download/<tên>" (gây `NoSuchFileException` khi chia sẻ).
        val absolutePath = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
            actualName,
        ).absolutePath
        return absolutePath to actualName
    }

    /** Android 8–9 — `null` nếu thiếu quyền `WRITE_EXTERNAL_STORAGE`. */
    private fun saveLegacy(name: String, bytes: ByteArray): Pair<String, String>? {
        if (ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.WRITE_EXTERNAL_STORAGE,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return null
        }
        val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!dir.exists()) dir.mkdirs()
        val file = uniqueFile(dir, name)
        file.writeBytes(bytes)
        return file.absolutePath to file.name
    }

    /** Thêm hậu tố ` (2)`, ` (3)`... nếu tên đã tồn tại — giữ nguyên phần mở rộng (FR-004). */
    private fun uniqueFile(dir: File, name: String): File {
        var candidate = File(dir, name)
        if (!candidate.exists()) return candidate
        val dot = name.lastIndexOf('.')
        val base = if (dot > 0) name.substring(0, dot) else name
        val ext = if (dot > 0) name.substring(dot) else ""
        var n = 2
        do {
            candidate = File(dir, "$base ($n)$ext")
            n++
        } while (candidate.exists())
        return candidate
    }
}
