import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Seam chia sẻ của màn Xuất báo cáo (R12) — **một** typedef để test bơm bản
/// giả, không đụng plugin trong `flutter test`.
typedef ShareExport =
    Future<void> Function({
      required String fileName,
      required Uint8List bytes,
      required String mimeType,
    });

/// Mở **bảng chia sẻ của hệ điều hành** với tệp dựng sẵn trong RAM (FR-011):
/// không ghi tệp tạm bằng `path_provider` — plugin tự đệm khi nền tảng yêu cầu,
/// và app không giữ tệp nào sau khi chia sẻ.
///
/// `fileNameOverrides` là chỗ **duy nhất** giữ đúng tên tệp: trên Android/iOS
/// `XFile.fromData` **bỏ qua** tham số `name` (`cross_file` chỉ suy `name` từ
/// `path`, mà đường này không có path) ⇒ không truyền override thì tên tệp chia
/// sẻ là tên ngẫu nhiên (rủi ro 2 của plan).
Future<void> defaultShareExport({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: mimeType)],
      fileNameOverrides: [fileName],
    ),
  );
}
