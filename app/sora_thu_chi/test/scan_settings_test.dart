import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/scan/device_tier.dart';
import 'package:sora_thu_chi/core/scan/scan_result.dart';
import 'package:sora_thu_chi/core/scan/scan_settings.dart';

void main() {
  group('fromSettings', () {
    test('bảng rỗng → mặc định an toàn (tắt, Chế độ cơ bản, chưa kiểm tra)', () {
      final s = ScanSettings.fromSettings(const {});
      expect(s.enabled, isFalse);
      expect(s.mode, ScanEngine.ruleBased);
      expect(s.modelBytes, 0);
      expect(s.deviceCheck, isNull);
    });

    test('chuỗi lạ / thiếu key → mặc định, không ném', () {
      final s = ScanSettings.fromSettings(const {
        kKeyScanEnabled: 'có',
        kKeyScanEngineMode: 'engine-bí-ẩn',
        kKeyScanModelBytes: 'không-phải-số',
        kKeyScanDeviceCheck: '{ hỏng json',
      });
      expect(s.enabled, isFalse);
      expect(s.mode, ScanEngine.ruleBased);
      expect(s.modelBytes, 0);
      expect(s.deviceCheck, isNull);
    });

    test('modelBytes âm → 0', () {
      final s = ScanSettings.fromSettings(const {kKeyScanModelBytes: '-5'});
      expect(s.modelBytes, 0);
    });

    test('đọc đúng 3 chế độ engine', () {
      expect(
        ScanSettings.fromSettings(const {kKeyScanEngineMode: 'gemini_nano'}).mode,
        ScanEngine.geminiNano,
      );
      expect(
        ScanSettings.fromSettings(
          const {kKeyScanEngineMode: 'gemma_3n_e2b'},
        ).mode,
        ScanEngine.gemma3nE2b,
      );
    });
  });

  group('toSettings', () {
    test('ghi đủ 4 key, đúng định dạng chuỗi', () {
      final cap = DeviceCapability(
        ramGb: 6,
        freeStorageGb: 10,
        supportsOnDeviceAi: true,
        supportsGpuDelegate: true,
        osVersion: 'Android 14',
        checkedAt: DateTime(2026, 9, 1),
      );
      final rows = ScanSettings(
        enabled: true,
        mode: ScanEngine.geminiNano,
        modelBytes: 1800000000,
        deviceCheck: cap,
      ).toSettings();

      expect(rows[kKeyScanEnabled], 'true');
      expect(rows[kKeyScanEngineMode], 'gemini_nano');
      expect(rows[kKeyScanModelBytes], '1800000000');
      expect(rows.containsKey(kKeyScanDeviceCheck), isTrue);
      expect(rows.length, 4);
    });

    test('chưa kiểm tra cấu hình → không ghi key deviceCheck', () {
      final rows = const ScanSettings().toSettings();
      expect(rows.containsKey(kKeyScanDeviceCheck), isFalse);
      expect(rows.length, 3);
    });

    test('round-trip qua bảng key-value giữ nguyên trạng thái', () {
      final cap = DeviceCapability(
        ramGb: 8,
        freeStorageGb: 30,
        supportsOnDeviceAi: false,
        supportsGpuDelegate: true,
        osVersion: 'Android 15',
        checkedAt: DateTime(2026, 9, 1, 10, 30),
      );
      final original = ScanSettings(
        enabled: true,
        mode: ScanEngine.gemma3nE2b,
        modelBytes: 1900000000,
        deviceCheck: cap,
      );
      final back = ScanSettings.fromSettings(original.toSettings());
      expect(back.enabled, isTrue);
      expect(back.mode, ScanEngine.gemma3nE2b);
      expect(back.modelBytes, 1900000000);
      expect(back.deviceCheck!.ramGb, 8);
      expect(back.deviceCheck!.checkedAt, DateTime(2026, 9, 1, 10, 30));
    });

    test('JSON deviceCheck hỏng trong bảng → null (coi như chưa kiểm tra)', () {
      final s = ScanSettings.fromSettings({
        kKeyScanDeviceCheck: jsonEncode({'ramGb': 4}),
      });
      expect(s.deviceCheck, isNull);
    });
  });

  group('effectiveEngine (T057/FR-012)', () {
    test('Tier A dùng Gemini Nano ngay, không cần model', () {
      expect(
        const ScanSettings(mode: ScanEngine.geminiNano).effectiveEngine,
        ScanEngine.geminiNano,
      );
    });

    test('Tier B đã tải model → dùng Gemma 3n', () {
      expect(
        const ScanSettings(
          mode: ScanEngine.gemma3nE2b,
          modelBytes: 1800000000,
        ).effectiveEngine,
        ScanEngine.gemma3nE2b,
      );
    });

    test('Tier B chưa tải model → rơi về Chế độ cơ bản', () {
      expect(
        const ScanSettings(mode: ScanEngine.gemma3nE2b).effectiveEngine,
        ScanEngine.ruleBased,
      );
    });

    test('chế độ cơ bản giữ nguyên', () {
      expect(const ScanSettings().effectiveEngine, ScanEngine.ruleBased);
    });
  });

  group('needsDeviceCheck (FR-008)', () {
    test('chưa từng kiểm tra → cần', () {
      expect(const ScanSettings().needsDeviceCheck(DateTime(2026, 9, 12)), isTrue);
    });

    test('mới kiểm tra 10 ngày trước → không cần', () {
      final s = ScanSettings(
        deviceCheck: DeviceCapability(
          ramGb: 6,
          freeStorageGb: 10,
          supportsOnDeviceAi: false,
          supportsGpuDelegate: true,
          osVersion: 'Android 14',
          checkedAt: DateTime(2026, 9, 2),
        ),
      );
      expect(s.needsDeviceCheck(DateTime(2026, 9, 12)), isFalse);
    });

    test('kiểm tra quá 30 ngày → cần lại', () {
      final s = ScanSettings(
        deviceCheck: DeviceCapability(
          ramGb: 6,
          freeStorageGb: 10,
          supportsOnDeviceAi: false,
          supportsGpuDelegate: true,
          osVersion: 'Android 14',
          checkedAt: DateTime(2026, 8, 1),
        ),
      );
      expect(s.needsDeviceCheck(DateTime(2026, 9, 12)), isTrue);
    });
  });
}
