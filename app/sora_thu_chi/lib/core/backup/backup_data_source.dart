import 'backup_data.dart';

/// Seam nối [BackupController] với tầng DB — tách khỏi `AppDatabase`/`drift`
/// (core giữ thuần) để test bơm fake, không cần sqlite native. Impl thật:
/// `DriftBackupDataSource` (gói `loadBackupData` + `BackupRestorer`).
abstract class BackupDataSource {
  /// Toàn bộ dữ liệu hiện có, dựng thành [BackupData] (dùng cho cả tạo backup
  /// thủ công/tự động/safety-snapshot).
  Future<BackupData> loadCurrent();

  /// Ghi đè toàn phần bằng [data] trong 1 transaction (FR-015).
  Future<void> restore(BackupData data);
}
