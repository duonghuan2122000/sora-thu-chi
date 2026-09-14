import 'package:get/get.dart';

import '../core/backup/backup_controller.dart';
import '../core/backup/backup_crypto.dart';
import '../core/backup/backup_data_source.dart';
import '../core/backup/backup_prefs_store.dart';
import '../core/backup/backup_scheduler.dart';
import '../core/backup/local_backup_store.dart';
import 'backup_crypto_cryptography.dart';
import 'backup_data_source_drift.dart';
import 'backup_prefs_store_drift.dart';
import 'backup_scheduler_workmanager.dart';
import 'db/app_database.dart';
import 'local_backup_store_file_system.dart';

/// Đăng ký [BackupPrefsStore] bền vững (Get singleton, khuôn `ensureNotificationStore`).
BackupPrefsStore ensureBackupPrefsStore() {
  if (Get.isRegistered<BackupPrefsStore>()) {
    return Get.find<BackupPrefsStore>();
  }
  final store = DriftBackupPrefsStore(AppDatabase());
  Get.put<BackupPrefsStore>(store);
  return store;
}

/// Đăng ký [LocalBackupStore] — test `Get.put` fake trước ⇒ không đụng đĩa thật.
LocalBackupStore ensureLocalBackupStore() {
  if (Get.isRegistered<LocalBackupStore>()) {
    return Get.find<LocalBackupStore>();
  }
  final store = FileSystemLocalBackupStore();
  Get.put<LocalBackupStore>(store);
  return store;
}

/// Đăng ký [BackupCrypto] — test `Get.put` fake trước ⇒ không chạy PBKDF2 thật.
BackupCrypto ensureBackupCrypto() {
  if (Get.isRegistered<BackupCrypto>()) {
    return Get.find<BackupCrypto>();
  }
  final crypto = CryptographyBackupCrypto();
  Get.put<BackupCrypto>(crypto);
  return crypto;
}

/// Đăng ký [BackupDataSource] — test `Get.put` fake trước ⇒ không đụng drift.
BackupDataSource ensureBackupDataSource() {
  if (Get.isRegistered<BackupDataSource>()) {
    return Get.find<BackupDataSource>();
  }
  final source = DriftBackupDataSource(AppDatabase());
  Get.put<BackupDataSource>(source);
  return source;
}

/// Đăng ký [BackupScheduler] — test `Get.put` fake trước ⇒ không đụng WorkManager.
BackupScheduler ensureBackupScheduler() {
  if (Get.isRegistered<BackupScheduler>()) {
    return Get.find<BackupScheduler>();
  }
  final scheduler = WorkmanagerBackupScheduler();
  Get.put<BackupScheduler>(scheduler);
  return scheduler;
}

/// Đăng ký [BackupController] bền vững (khuôn `ensureScanController`) — màn
/// `01`/2 bottom sheet dùng chung một controller.
BackupController ensureBackupController() {
  if (Get.isRegistered<BackupController>()) {
    return Get.find<BackupController>();
  }
  final controller = BackupController(
    prefsStore: ensureBackupPrefsStore(),
    localStore: ensureLocalBackupStore(),
    crypto: ensureBackupCrypto(),
    dataSource: ensureBackupDataSource(),
    scheduler: ensureBackupScheduler(),
  );
  Get.put<BackupController>(controller);
  return controller;
}
