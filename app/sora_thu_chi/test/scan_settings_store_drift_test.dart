import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/scan/scan_result.dart';
import 'package:sora_thu_chi/core/scan/scan_settings.dart';
import 'package:sora_thu_chi/data/db/app_database.dart';
import 'package:sora_thu_chi/data/scan_settings_store_drift.dart';

/// Mở DB drift trong bộ nhớ — host thiếu sqlite native → skip-guard (bám
/// `utilities_store_drift_test`).
Future<AppDatabase?> _tryMemoryDb() async {
  try {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    return db;
  } catch (_) {
    return null;
  }
}

const _skip = 'Host thiếu sqlite native — bỏ qua DAO drift tích hợp.';

void main() {
  test('bảng rỗng → mặc định; schemaVersion 10 (PBI 31)', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    expect(db.schemaVersion, 10);
    final settings = await DriftScanSettingsStore(db).load();
    expect(settings.enabled, isFalse);
    expect(settings.mode, ScanEngine.ruleBased);
    expect(settings.modelBytes, 0);
    expect(settings.deviceCheck, isNull);
  });

  test('round-trip save → load đúng giá trị vừa lưu', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    final store = DriftScanSettingsStore(db);
    await store.save(
      const ScanSettings(
        enabled: true,
        mode: ScanEngine.gemma3nE2b,
        modelBytes: 1800000000,
      ),
    );
    final settings = await store.load();
    expect(settings.enabled, isTrue);
    expect(settings.mode, ScanEngine.gemma3nE2b);
    expect(settings.modelBytes, 1800000000);
  });

  test('save chỉ ghi 4 key của mình, không xoá key khác', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    await db.into(db.appSettings).insert(
      AppSettingsCompanion.insert(key: 'hideBalance', value: 'true'),
    );
    await DriftScanSettingsStore(db).save(const ScanSettings(enabled: true));

    final keys = (await db.select(db.appSettings).get()).map((r) => r.key);
    expect(keys, contains('hideBalance'));
    expect(keys, contains(kKeyScanEnabled));
    expect(keys, contains(kKeyScanEngineMode));
    expect(keys, contains(kKeyScanModelBytes));
    expect(keys.length, 4);
  });
}
