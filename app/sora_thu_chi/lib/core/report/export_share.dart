import 'package:share_plus/share_plus.dart';

/// Seam chia sẻ của màn Xuất báo cáo (R12) — **một** typedef để test bơm bản
/// giả, không đụng plugin trong `flutter test`.
///
/// Từ PBI 41, `filePath` trỏ tới tệp **đã ghi ra Downloads công khai**
/// (`SaveReportFile`) — bảng chia sẻ dùng chính tệp này, không dựng lại bytes
/// riêng (FR-007), nên tên tệp hiện đúng như đã thông báo mà không cần override.
typedef ShareExport =
    Future<void> Function({
      required String fileName,
      required String filePath,
      required String mimeType,
    });

/// Mở **bảng chia sẻ của hệ điều hành** với tệp đã lưu (FR-007).
Future<void> defaultShareExport({
  required String fileName,
  required String filePath,
  required String mimeType,
}) async {
  await SharePlus.instance.share(
    ShareParams(files: [XFile(filePath, mimeType: mimeType, name: fileName)]),
  );
}
