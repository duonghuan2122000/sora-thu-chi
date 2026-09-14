import 'package:flutter/foundation.dart';

/// 1 dòng trong danh sách "Các bản sao lưu" (data-model.md §4) — đọc trực tiếp
/// từ hệ thống file, không đồng bộ qua DB (R1).
@immutable
class LocalBackupEntry {
  const LocalBackupEntry({
    required this.path,
    required this.fileName,
    required this.sizeBytes,
    required this.createdAt,
    required this.isAuto,
    required this.hasAttachments,
  });

  final String path;
  final String fileName;
  final int sizeBytes;
  final DateTime createdAt;

  /// Suy từ thư mục con (`backups/auto/` vs `backups/manual/`).
  final bool isAuto;

  /// Đuôi `.zip` (có ảnh đính kèm).
  final bool hasAttachments;
}

/// Nơi ghi/liệt kê/dọn file backup lưu trong `app_documents/backups/` — nguồn
/// sự thật là filesystem (R1). Impl thật: `FileSystemLocalBackupStore`.
abstract class LocalBackupStore {
  /// Liệt kê bản **thủ công + tự động** (không gồm `_safety/` — người dùng
  /// không cần thấy bản an toàn nội bộ), mới nhất trước.
  Future<List<LocalBackupEntry>> list();

  /// Ghi [bytes] vào thư mục con theo [destination] — ghi tạm rồi `rename`
  /// (R6): lỗi giữa chừng không để lại file dở.
  Future<LocalBackupEntry> write({
    required Uint8List bytes,
    required String extension,
    required BackupDestination destination,
  });

  Future<void> delete(String path);

  /// Dọn file trong `_safety/` cũ hơn [maxAge] (R10).
  Future<void> cleanupOldSafetySnapshots({
    Duration maxAge = const Duration(hours: 24),
  });
}

/// Thư mục con lưu file backup — quyết định `isAuto` khi liệt kê và việc file
/// có hiện trong danh sách "Các bản sao lưu" hay không ([safety] bị loại).
enum BackupDestination { manual, auto, safety }
