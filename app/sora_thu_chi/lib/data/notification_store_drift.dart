import '../core/notification/notification_prefs.dart';
import '../core/notification/notification_store.dart';
import 'db/app_database.dart';

/// Impl thật (drift) của [NotificationStore] — map bảng key-value `AppSettings`
/// ↔ [NotificationPrefs]. Cả 16 trường nằm trong **1 row JSON** nên `save` chỉ
/// upsert đúng 1 row (không xoá khoá `hideBalance`/`scanEnabled`… của PBI
/// 17/24). Dùng lại `AppSettingsCompanion` đã sinh ở schema v8 — không
/// `build_runner`, không migration.
class DriftNotificationStore implements NotificationStore {
  DriftNotificationStore(this._db);

  final AppDatabase _db;

  @override
  Future<NotificationPrefs> load() async {
    final rows = await _db.select(_db.appSettings).get();
    return NotificationPrefs.fromSettings({
      for (final r in rows) r.key: r.value,
    });
  }

  @override
  Future<void> save(NotificationPrefs prefs) async {
    for (final entry in prefs.toSettings().entries) {
      await _db.into(_db.appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: entry.key, value: entry.value),
      );
    }
  }

  @override
  Future<bool> permissionAsked() async {
    final row = await (_db.select(_db.appSettings)
          ..where((r) => r.key.equals(kKeyNotificationPermissionAsked)))
        .getSingleOrNull();
    return row?.value == 'true';
  }

  @override
  Future<void> markPermissionAsked() async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(
        key: kKeyNotificationPermissionAsked,
        value: 'true',
      ),
    );
  }
}
