import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/locale/locale_prefs.dart';
import 'package:sora_thu_chi/core/theme/theme_mode.dart';
import 'package:sora_thu_chi/core/utilities/utilities.dart';
import 'package:sora_thu_chi/data/db/app_database.dart';
import 'package:sora_thu_chi/data/locale_store_drift.dart';

/// Mở DB drift trong bộ nhớ. Host Windows thiếu sqlite native → trả null
/// (skip-guard, như theme_store_drift_test).
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
  test('chưa có row locale → load trả null (mặc định vi)', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    expect(await DriftLocaleStore(db).load(), isNull);
  });

  test('round-trip save → load đúng giá trị', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    final store = DriftLocaleStore(db);
    await store.save(const Locale('en'));
    expect(await store.load(), const Locale('en'));
    await store.save(const Locale('vi'));
    expect(await store.load(), const Locale('vi'));
  });

  test('save nhiều lần đè nhau → load ra lần cuối', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    final store = DriftLocaleStore(db);
    await store.save(const Locale('en'));
    await store.save(const Locale('vi'));
    await store.save(const Locale('en'));
    expect(await store.load(), const Locale('en'));
  });

  test('FR-012: save không xoá row cài đặt khác', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    await db.into(db.appSettings).insert(
      AppSettingsCompanion.insert(key: kKeyThemeMode, value: 'dark'),
    );
    await db.into(db.appSettings).insert(
      AppSettingsCompanion.insert(key: kKeyHideBalance, value: 'true'),
    );
    await DriftLocaleStore(db).save(const Locale('en'));

    final rows = await db.select(db.appSettings).get();
    expect(rows.map((r) => r.key), contains(kKeyThemeMode));
    expect(rows.map((r) => r.key), contains(kKeyHideBalance));
    expect(rows.map((r) => r.key), contains(kKeyLocale));
    expect(rows.length, 3);
  });

  test('giá trị rác trong DB → load trả mặc định vi', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    await db.into(db.appSettings).insert(
      AppSettingsCompanion.insert(key: kKeyLocale, value: 'fr'),
    );
    expect(await DriftLocaleStore(db).load(), kFallbackLocale);
  });
}
