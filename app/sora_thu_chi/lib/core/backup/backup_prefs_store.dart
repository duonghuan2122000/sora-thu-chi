import 'backup_prefs.dart';

/// Seam đọc/ghi [BackupPrefs] — màn/controller chỉ phụ thuộc interface này để
/// test bơm fake (không cần sqlite native). Impl thật: `DriftBackupPrefsStore`.
abstract class BackupPrefsStore {
  Future<BackupPrefs> load();

  /// Upsert **1 row** `backupPrefs`; không xoá row `AppSettings` nào khác.
  Future<void> save(BackupPrefs prefs);
}
