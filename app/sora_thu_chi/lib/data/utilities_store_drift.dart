import '../core/utilities/utilities.dart';
import '../core/utilities/utilities_store.dart';
import 'db/app_database.dart';

/// Impl thật (drift) của [UtilitiesStore] — map bảng key-value `AppSettings`
/// ↔ [UtilitiesPrefs]. Upsert **chỉ 2 key của prefs**, không xoá row khác
/// (giữ key cài đặt của PBI sau).
class DriftUtilitiesStore implements UtilitiesStore {
  DriftUtilitiesStore(this._db);

  final AppDatabase _db;

  @override
  Future<UtilitiesPrefs> load() async {
    final rows = await _db.select(_db.appSettings).get();
    return UtilitiesPrefs.fromSettings({for (final r in rows) r.key: r.value});
  }

  @override
  Future<void> save(UtilitiesPrefs prefs) async {
    for (final entry in prefs.toSettings().entries) {
      await _db.into(_db.appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: entry.key, value: entry.value),
      );
    }
  }
}
