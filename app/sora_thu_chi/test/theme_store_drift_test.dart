import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/theme/theme_mode.dart';
import 'package:sora_thu_chi/core/utilities/utilities.dart';
import 'package:sora_thu_chi/data/db/app_database.dart';
import 'package:sora_thu_chi/data/theme_store_drift.dart';

/// Mở DB drift trong bộ nhớ. Host Windows thiếu sqlite native → trả null
/// (skip-guard, như utilities_store_drift_test).
Future<AppDatabase?> _tryMemoryDb() async {
  try {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get(); // buộc mở connection
    return db;
  } catch (_) {
    return null;
  }
}

void main() {
  test('chưa có row themeMode → load trả null (mặc định system)', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    expect(await DriftThemeStore(db).load(), isNull);
  });

  test('round-trip save → load đúng giá trị', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    final store = DriftThemeStore(db);
    for (final mode in ThemeMode.values) {
      await store.save(mode);
      expect(await store.load(), mode);
    }
  });

  test('save nhiều lần đè nhau → load ra lần cuối', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    final store = DriftThemeStore(db);
    await store.save(ThemeMode.dark);
    await store.save(ThemeMode.light);
    await store.save(ThemeMode.dark);
    expect(await store.load(), ThemeMode.dark);
  });

  test('save không xoá key khác trong bảng AppSettings', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    await db.into(db.appSettings).insert(
      AppSettingsCompanion.insert(key: kKeyHideBalance, value: 'true'),
    );
    await DriftThemeStore(db).save(ThemeMode.dark);

    final rows = await db.select(db.appSettings).get();
    expect(rows.map((r) => r.key), contains(kKeyHideBalance));
    expect(rows.map((r) => r.key), contains(kKeyThemeMode));
    expect(rows.length, 2);
  });
}
