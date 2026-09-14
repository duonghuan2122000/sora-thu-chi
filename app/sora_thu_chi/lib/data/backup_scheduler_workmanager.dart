import 'package:workmanager/workmanager.dart';

import '../core/backup/backup_prefs.dart';
import '../core/backup/backup_scheduler.dart';
import '../core/backup/backup_writer.dart';
import '../core/backup/local_backup_store.dart';
import 'backup_crypto_cryptography.dart';
import 'backup_prefs_store_drift.dart';
import 'backup_snapshot_drift.dart';
import 'db/app_database.dart';
import 'local_backup_store_file_system.dart';

/// Tên duy nhất của task định kỳ — 1 task cho cả app (đổi tần suất = đăng ký
/// lại đè, không cộng dồn task).
const String kAutoBackupTaskName = 'sora_thu_chi_auto_backup';

/// Impl thật [BackupScheduler] — Android WorkManager thật; iOS best-effort qua
/// BGTaskScheduler (cùng plugin, research R7 — không cam kết đúng tần suất).
class WorkmanagerBackupScheduler implements BackupScheduler {
  @override
  Future<void> schedule(BackupFrequency frequency) async {
    await Workmanager().cancelByUniqueName(kAutoBackupTaskName);
    await Workmanager().registerPeriodicTask(
      kAutoBackupTaskName,
      kAutoBackupTaskName,
      frequency: _interval(frequency),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  @override
  Future<void> cancel() => Workmanager().cancelByUniqueName(kAutoBackupTaskName);

  /// `workmanager` yêu cầu chu kỳ ≥ 15 phút trên Android — hàng ngày/tuần/tháng
  /// đều xa hơn nhiều nên không chạm giới hạn.
  Duration _interval(BackupFrequency frequency) => switch (frequency) {
    BackupFrequency.daily => const Duration(days: 1),
    BackupFrequency.weekly => const Duration(days: 7),
    BackupFrequency.monthly => const Duration(days: 30),
  };
}

/// Callback chạy trong **isolate nền riêng** (đăng ký ở `main.dart` qua
/// `Workmanager().initialize`) — tự dựng lại mọi phụ thuộc bằng tay (không qua
/// GetX/`ensure...()`, isolate này không có state của isolate UI).
@pragma('vm:entry-point')
void backupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await _runAutoBackup();
    } catch (_) {
      // Best-effort (R7) — lỗi nền không có nơi hiển thị, bỏ qua để lần chạy
      // sau thử lại; không làm hỏng lịch của WorkManager.
    }
    return true;
  });
}

Future<void> _runAutoBackup() async {
  final db = AppDatabase();
  final prefsStore = DriftBackupPrefsStore(db);
  final localStore = FileSystemLocalBackupStore();

  final data = await loadBackupData(db);
  final result = await buildBackupFile(
    data: data,
    crypto: CryptographyBackupCrypto(),
  );
  final entry = await localStore.write(
    bytes: result.bytes,
    extension: result.extension,
    destination: BackupDestination.auto,
  );

  final prefs = await prefsStore.load();
  // Giữ tối đa `maxKeepLocal` bản tự động — cũ nhất xóa trước (FIFO, spec §4.2).
  final autoEntries = (await localStore.list()).where((e) => e.isAuto).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  for (final old in autoEntries.skip(prefs.maxKeepLocal)) {
    await localStore.delete(old.path);
  }

  await prefsStore.save(
    prefs.copyWith(
      lastBackupAt: entry.createdAt,
      lastBackupCounts: data.counts,
      lastBackupSizeBytes: entry.sizeBytes,
    ),
  );
  // ponytail: chưa bắn thông báo "Đã tự động sao lưu..." (doc §4.2) — engine
  // thông báo hiện tại được dựng qua GetX ở isolate UI, isolate nền này không
  // có state đó. Nâng cấp khi cần: gọi thẳng `FlutterLocalNotificationsPlugin`
  // mới, tự init lại kênh trong isolate này (không qua `ensureNotificationEngine`).
}
