import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/backup/backup_prefs.dart';

Map<String, String> _row(String value) => {kKeyBackupPrefs: value};

void main() {
  group('Mặc định', () {
    test('constructor mặc định = defaults', () {
      const p = BackupPrefs();
      expect(p, BackupPrefs.defaults);
      expect(p.autoEnabled, isFalse);
      expect(p.autoFrequency, BackupFrequency.weekly);
      expect(p.maxKeepLocal, 5);
      expect(p.lastBackupAt, isNull);
      expect(p.lastBackupCounts, isNull);
      expect(p.lastBackupSizeBytes, isNull);
    });

    test('row vắng → cả bộ mặc định', () {
      expect(BackupPrefs.fromSettings(const {}), BackupPrefs.defaults);
    });
  });

  group('JSON hỏng → cả bộ mặc định, không ném', () {
    for (final raw in ['', 'không phải json', 'null', '[1,2,3]', '"chuỗi"']) {
      test('raw = ${raw.isEmpty ? '(rỗng)' : raw}', () {
        expect(BackupPrefs.fromSettings(_row(raw)), BackupPrefs.defaults);
      });
    }
  });

  group('Từng trường sai kiểu/ngoài miền → mặc định của riêng nó', () {
    test('autoEnabled sai kiểu → mặc định false, trường khác giữ', () {
      final p = BackupPrefs.fromSettings(
        _row('{"autoEnabled":"yes","maxKeepLocal":10}'),
      );
      expect(p.autoEnabled, isFalse);
      expect(p.maxKeepLocal, 10);
    });

    test('autoFrequency lạ → mặc định weekly', () {
      final p = BackupPrefs.fromSettings(_row('{"autoFrequency":"hourly"}'));
      expect(p.autoFrequency, BackupFrequency.weekly);
    });

    test('autoFrequency hợp lệ đọc đúng', () {
      final p = BackupPrefs.fromSettings(_row('{"autoFrequency":"daily"}'));
      expect(p.autoFrequency, BackupFrequency.daily);
    });

    test('maxKeepLocal <= 0 → mặc định 5', () {
      final p = BackupPrefs.fromSettings(_row('{"maxKeepLocal":0}'));
      expect(p.maxKeepLocal, 5);
    });

    test('lastBackupAt sai định dạng → null', () {
      final p = BackupPrefs.fromSettings(_row('{"lastBackupAt":"abc"}'));
      expect(p.lastBackupAt, isNull);
    });

    test('lastBackupSizeBytes âm → null', () {
      final p = BackupPrefs.fromSettings(_row('{"lastBackupSizeBytes":-1}'));
      expect(p.lastBackupSizeBytes, isNull);
    });

    test('lastBackupCounts sai kiểu phần tử → bỏ phần tử sai', () {
      final p = BackupPrefs.fromSettings(
        _row('{"lastBackupCounts":{"wallets":3,"categories":"x"}}'),
      );
      expect(p.lastBackupCounts, {'wallets': 3});
    });
  });

  group('Roundtrip toSettings/fromSettings', () {
    test('mọi trường giữ nguyên qua vòng lặp', () {
      final now = DateTime(2026, 9, 14, 10, 30);
      const prefs = BackupPrefs(
        autoEnabled: true,
        autoFrequency: BackupFrequency.monthly,
        maxKeepLocal: 3,
        lastBackupSizeBytes: 12345,
      );
      final withDate = prefs.copyWith(
        lastBackupAt: now,
        lastBackupCounts: {'wallets': 2, 'transactions': 30},
      );
      final rows = withDate.toSettings();
      final restored = BackupPrefs.fromSettings(rows);
      expect(restored, withDate);
    });
  });

  group('copyWith', () {
    test('chỉ đổi trường truyền vào', () {
      const prefs = BackupPrefs(autoEnabled: true, maxKeepLocal: 7);
      final next = prefs.copyWith(autoEnabled: false);
      expect(next.autoEnabled, isFalse);
      expect(next.maxKeepLocal, 7);
    });
  });
}
