import 'backup_prefs.dart';

/// Seam lịch chạy tự động sao lưu nền (research R7) — controller chỉ phụ
/// thuộc interface này để test bơm fake. Impl thật: `WorkmanagerBackupScheduler`
/// (Android WorkManager thật; iOS best-effort qua BGTaskScheduler).
abstract class BackupScheduler {
  Future<void> schedule(BackupFrequency frequency);

  Future<void> cancel();
}
