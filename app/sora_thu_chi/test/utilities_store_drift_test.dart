import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/utilities/utilities.dart';
import 'package:sora_thu_chi/data/db/app_database.dart';
import 'package:sora_thu_chi/data/utilities_store_drift.dart';

/// Mở DB drift trong bộ nhớ. Host Windows thiếu sqlite native → trả null
/// (test skip-guard, như wallets_dao_test — app thật dùng sqlite3_flutter_libs).
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
  test('load bảng rỗng → mặc định; schemaVersion 11 (PBI 47)', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    expect(db.schemaVersion, 11, reason: 'PBI 47 nâng schema v10 → v11');
    final store = DriftUtilitiesStore(db);
    final prefs = await store.load();
    expect(prefs.hideBalance, isFalse);
    expect(prefs.amountCalculatorEnabled, isTrue);
  });

  test('round-trip save → load đúng giá trị vừa lưu', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    final store = DriftUtilitiesStore(db);
    await store.save(
      const UtilitiesPrefs(hideBalance: true, amountCalculatorEnabled: false),
    );
    final prefs = await store.load();
    expect(prefs.hideBalance, isTrue);
    expect(prefs.amountCalculatorEnabled, isFalse);
  });

  test('save nhiều lần đè nhau → load ra lần cuối', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    final store = DriftUtilitiesStore(db);
    await store.save(const UtilitiesPrefs(hideBalance: true, amountCalculatorEnabled: true));
    await store.save(const UtilitiesPrefs(hideBalance: false, amountCalculatorEnabled: true));
    await store.save(const UtilitiesPrefs(hideBalance: false, amountCalculatorEnabled: false));

    final prefs = await store.load();
    expect(prefs.hideBalance, isFalse);
    expect(prefs.amountCalculatorEnabled, isFalse);
  });

  test('save không xoá key khác trong bảng (giữ cài đặt PBI sau)', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    // Chèn 1 row key lạ (PBI sau) trực tiếp vào bảng.
    await db.into(db.appSettings).insert(
      AppSettingsCompanion.insert(key: 'futureSetting', value: 'x'),
    );
    final store = DriftUtilitiesStore(db);
    await store.save(const UtilitiesPrefs(hideBalance: true, amountCalculatorEnabled: false));

    final rows = await db.select(db.appSettings).get();
    expect(rows.map((r) => r.key), contains('futureSetting'));
    expect(rows.map((r) => r.key), contains(kKeyHideBalance));
    expect(rows.map((r) => r.key), contains(kKeyAmountCalculatorEnabled));
    expect(rows.length, 3);
  });
}
