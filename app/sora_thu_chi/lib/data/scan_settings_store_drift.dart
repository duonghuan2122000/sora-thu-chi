import '../core/scan/scan_settings.dart';
import '../core/scan/scan_settings_store.dart';
import 'db/app_database.dart';

/// Impl thật (drift) của [ScanSettingsStore] — map bảng key-value `AppSettings`
/// ↔ [ScanSettings]. Upsert **chỉ 4 key của mình**, không xoá row khác (bám
/// `DriftUtilitiesStore`).
class DriftScanSettingsStore implements ScanSettingsStore {
  DriftScanSettingsStore(this._db);

  final AppDatabase _db;

  @override
  Future<ScanSettings> load() async {
    final rows = await _db.select(_db.appSettings).get();
    return ScanSettings.fromSettings({for (final r in rows) r.key: r.value});
  }

  @override
  Future<void> save(ScanSettings settings) async {
    for (final entry in settings.toSettings().entries) {
      await _db.into(_db.appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: entry.key, value: entry.value),
      );
    }
  }
}
