import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/notification/notification_prefs.dart';
import 'package:sora_thu_chi/core/utilities/utilities.dart';
import 'package:sora_thu_chi/data/db/app_database.dart';
import 'package:sora_thu_chi/data/notification_store_drift.dart';

/// Mở DB drift trong bộ nhớ. Host Windows thiếu sqlite native → trả null
/// (test skip-guard, như `utilities_store_drift_test`).
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
  test('schema v9 (PBI 30 thêm bảng notifications)', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    expect(db.schemaVersion, 11);
  });

  test('row notificationPrefs vắng → cả bộ mặc định (không seed)', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    final store = DriftNotificationStore(db);
    expect(await store.load(), NotificationPrefs.defaults);
    final rows = await db.select(db.appSettings).get();
    expect(
      rows.where((r) => r.key == kKeyNotificationPrefs),
      isEmpty,
      reason: 'chưa mở màn thì chưa có row — màn mới là nơi ghi lần đầu',
    );
  });

  test('round-trip save → load đúng 16 trường', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    const prefs = NotificationPrefs(
      dailyEnabled: false,
      dailyHour: 6,
      dailyMinute: 45,
      dailyOnlyIfNoTxnToday: false,
      budgetEnabled: false,
      budgetEarlyPercent: 60,
      budgetOverPercent: 95,
      recurringEnabled: false,
      recurringDaysBefore: 5,
      goalEnabled: true,
      weeklyEnabled: false,
      weeklyHour: 8,
      weeklyMinute: 10,
      monthlyEnabled: false,
      monthlyHour: 21,
      monthlyMinute: 15,
    );
    final store = DriftNotificationStore(db);
    await store.save(prefs);
    expect(await store.load(), prefs);
  });

  test('save không xoá row AppSettings khác (PBI 17/24 còn nguyên)', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    await db.into(db.appSettings).insert(
      AppSettingsCompanion.insert(key: kKeyHideBalance, value: 'true'),
    );
    await db.into(db.appSettings).insert(
      AppSettingsCompanion.insert(
        key: kKeyAmountCalculatorEnabled,
        value: 'true',
      ),
    );
    await db.into(db.appSettings).insert(
      AppSettingsCompanion.insert(key: 'scanEnabled', value: 'false'),
    );

    final store = DriftNotificationStore(db);
    await store.save(const NotificationPrefs(goalEnabled: true));

    final rows = await db.select(db.appSettings).get();
    final keys = rows.map((r) => r.key).toList();
    expect(keys, contains(kKeyHideBalance));
    expect(keys, contains(kKeyAmountCalculatorEnabled));
    expect(keys, contains('scanEnabled'));
    expect(keys, contains(kKeyNotificationPrefs));
    expect(rows.length, 4, reason: 'upsert 1 row, không xoá row nào khác');
  });

  test('save nhiều lần đè nhau → load ra lần cuối', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    final store = DriftNotificationStore(db);
    await store.save(const NotificationPrefs(dailyHour: 6));
    await store.save(const NotificationPrefs(dailyHour: 7));
    await store.save(const NotificationPrefs(dailyHour: 8));

    final prefs = await store.load();
    expect(prefs.dailyHour, 8);
    expect(prefs.dailyMinute, 30, reason: 'các trường khác vẫn mặc định');
    final rows = await db.select(db.appSettings).get();
    expect(rows.length, 1, reason: 'vẫn đúng 1 row');
  });
}
