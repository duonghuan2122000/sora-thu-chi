import '../core/backup/backup_prefs.dart';
import '../core/backup/backup_prefs_store.dart';
import 'db/app_database.dart';

/// Impl thật (drift) của [BackupPrefsStore] — map bảng key-value `AppSettings`
/// ↔ [BackupPrefs] (khuôn `DriftNotificationStore`). Không thêm bảng, schema
/// giữ v10.
class DriftBackupPrefsStore implements BackupPrefsStore {
  DriftBackupPrefsStore(this._db);

  final AppDatabase _db;

  @override
  Future<BackupPrefs> load() async {
    final rows = await _db.select(_db.appSettings).get();
    return BackupPrefs.fromSettings({for (final r in rows) r.key: r.value});
  }

  @override
  Future<void> save(BackupPrefs prefs) async {
    for (final entry in prefs.toSettings().entries) {
      await _db.into(_db.appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: entry.key, value: entry.value),
      );
    }
  }
}
