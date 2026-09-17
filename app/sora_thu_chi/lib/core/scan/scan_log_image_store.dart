import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Seam lưu ảnh của nhật ký trích xuất AI (PBI 47) — kho **riêng** với
/// [ScanImageStore]: [ScanImageStore] chỉ ghi khi tạo giao dịch thành công,
/// còn nhật ký cần ảnh cả khi phiên bị hủy/lỗi (research.md Quyết định 3).
abstract class ScanLogImageStore {
  /// Copy ảnh tại [tempPath] vào kho, trả đường dẫn tuyệt đối đã lưu.
  Future<String> save(String tempPath);

  /// Xoá file tại [path] — dùng khi trim trần hoặc xóa bản ghi.
  Future<void> delete(String path);
}

/// Impl thật: copy vào `<appDocuments>/scan_logs/` (tên file = millis).
class LocalScanLogImageStore implements ScanLogImageStore {
  @override
  Future<String> save(String tempPath) async {
    final dir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'scan_logs'),
    );
    await dir.create(recursive: true);
    final dest = File(
      p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg'),
    );
    await File(tempPath).copy(dest.path);
    return dest.path;
  }

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }
}
