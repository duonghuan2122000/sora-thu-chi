import 'package:flutter/material.dart';

import '../core/theme/theme_mode.dart';
import '../core/theme/theme_store.dart';
import 'db/app_database.dart';

/// Impl thật (drift) của [ThemeStore] — 1 row `themeMode` trong bảng key-value
/// `AppSettings` (schema v5, không migration). Upsert chỉ key này, không xoá
/// row cài đặt khác.
class DriftThemeStore implements ThemeStore {
  DriftThemeStore(this._db);

  final AppDatabase _db;

  @override
  Future<ThemeMode?> load() async {
    final row = await (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(kKeyThemeMode)))
        .getSingleOrNull();
    // Row vắng = chưa từng đổi → null (controller giữ mặc định `system`).
    if (row == null) return null;
    return themeModeFromStorage(row.value);
  }

  @override
  Future<void> save(ThemeMode mode) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(
        key: kKeyThemeMode,
        value: themeModeToStorage(mode),
      ),
    );
  }
}
