import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'scan_log.dart';
import 'scan_log_store.dart';

/// Seam chia sẻ file xuất nhật ký (khuôn `ShareBackupFile`, `backup_share.dart`)
/// — test bơm bản giả, không đụng bảng chia sẻ hệ thống thật trong `flutter test`.
typedef ShareScanLogExport = Future<void> Function(String path);

Future<void> defaultShareScanLogExport(String path) => SharePlus.instance.share(
  ShareParams(files: [XFile(path, mimeType: 'application/json')]),
);

/// Ghi toàn bộ [logs] ra 1 file JSON tạm, trả đường dẫn đã ghi (FR-010).
/// [tempDir] là seam test (mặc định `getTemporaryDirectory()`) — test widget
/// không chạy được kênh native `path_provider`.
Future<String> writeScanLogExportFile(
  List<ScanExtractionLog> logs, {
  Future<Directory> Function()? tempDir,
}) async {
  final dir = await (tempDir ?? getTemporaryDirectory)();
  final file = File(
    p.join(
      dir.path,
      'nhat-ky-trich-xuat-ai-${DateTime.now().millisecondsSinceEpoch}.json',
    ),
  );
  await file.writeAsString(jsonEncode(logs.map((l) => l.toJson()).toList()));
  return file.path;
}

/// Đọc toàn bộ nhật ký từ [store], ghi ra file rồi mở bảng chia sẻ hệ thống
/// (FR-010) — dùng ở màn danh sách.
Future<void> exportScanLogs(
  ScanLogStore store, {
  ShareScanLogExport? share,
  Future<Directory> Function()? tempDir,
}) async {
  final logs = await store.loadAll();
  final path = await writeScanLogExportFile(logs, tempDir: tempDir);
  await (share ?? defaultShareScanLogExport)(path);
}
