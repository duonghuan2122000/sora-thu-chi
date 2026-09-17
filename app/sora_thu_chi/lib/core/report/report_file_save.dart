import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Seam lưu file của màn Xuất báo cáo (PBI 41) — test bơm bản giả, không đụng
/// kênh native/plugin quyền trong `flutter test`.
typedef SaveReportFile =
    Future<SavedReportFile> Function({
      required String fileName,
      required Uint8List bytes,
      required String mimeType,
    });

/// Kết quả lưu — `fileName`/`path` là giá trị **thực tế** sau khi hệ thống
/// (MediaStore hoặc kênh native) tự dò trùng tên, có thể khác `fileName` đầu
/// vào (FR-004).
class SavedReportFile {
  const SavedReportFile({required this.path, required this.fileName});

  final String path;
  final String fileName;
}

/// Ném khi quyền lưu trữ bị từ chối — chỉ xảy ra trên Android 8–9 (API 26–28);
/// Android 10+ ghi qua MediaStore không cần quyền này (FR-005).
class ReportStoragePermissionDeniedException implements Exception {
  const ReportStoragePermissionDeniedException();
}

const _channel = MethodChannel('sora_thu_chi/report_downloads');

/// Ghi [bytes] vào thư mục Tải xuống công khai của thiết bị qua kênh native
/// `sora_thu_chi/report_downloads` (không dependency Flutter nào đã cài đặt
/// làm đúng việc này tự động — xem `research.md` PBI 41 Quyết định 1).
Future<SavedReportFile> defaultSaveReportFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final first = await _invoke(fileName, bytes, mimeType);
  if (first != null) return first;

  // Kênh native chỉ trả `null` (mã lỗi `permission_denied`) trên Android 8–9
  // khi chưa có quyền `WRITE_EXTERNAL_STORAGE` — Android 10+ dùng MediaStore,
  // không rơi vào nhánh này.
  if (!Platform.isAndroid) throw const ReportStoragePermissionDeniedException();
  final status = await Permission.storage.request();
  if (!status.isGranted) throw const ReportStoragePermissionDeniedException();

  final retried = await _invoke(fileName, bytes, mimeType);
  if (retried == null) throw const ReportStoragePermissionDeniedException();
  return retried;
}

Future<SavedReportFile?> _invoke(
  String fileName,
  Uint8List bytes,
  String mimeType,
) async {
  try {
    final map = await _channel.invokeMapMethod<String, dynamic>(
      'saveToDownloads',
      {'name': fileName, 'bytes': bytes, 'mimeType': mimeType},
    );
    return SavedReportFile(
      path: map!['path'] as String,
      fileName: map['fileName'] as String,
    );
  } on PlatformException catch (e) {
    if (e.code == 'permission_denied') return null;
    rethrow;
  }
}
