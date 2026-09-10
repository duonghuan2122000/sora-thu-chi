import 'package:flutter/material.dart';

import '../core/locale/locale_prefs.dart';
import '../core/locale/locale_store.dart';
import 'db/app_database.dart';

/// Impl thật (drift) của [LocaleStore] — 1 row `locale` trong bảng key-value
/// `AppSettings` (schema v5, không migration). Upsert chỉ key này, không xoá
/// row cài đặt khác (`themeMode`, `hideBalance`, …) — FR-012.
class DriftLocaleStore implements LocaleStore {
  DriftLocaleStore(this._db);

  final AppDatabase _db;

  @override
  Future<Locale?> load() async {
    final row = await (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(kKeyLocale)))
        .getSingleOrNull();
    // Row vắng = chưa từng đổi → null (controller giữ mặc định `vi`).
    if (row == null) return null;
    return localeFromStorage(row.value);
  }

  @override
  Future<void> save(Locale locale) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(
        key: kKeyLocale,
        value: localeToStorage(locale),
      ),
    );
  }
}
