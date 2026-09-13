import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/scan/device_tier.dart';

DeviceCapability _cap({
  int ramGb = 4,
  double freeStorageGb = 2.0,
  bool ai = false,
  bool gpu = true,
  DateTime? checkedAt,
}) => DeviceCapability(
  ramGb: ramGb,
  freeStorageGb: freeStorageGb,
  supportsOnDeviceAi: ai,
  supportsGpuDelegate: gpu,
  osVersion: 'Android 14',
  checkedAt: checkedAt ?? DateTime(2026, 9, 1),
);

void main() {
  group('classifyTier — biên đóng (doc §11.2)', () {
    test('có AICore → Tier A bất kể chỉ số khác', () {
      expect(
        classifyTier(_cap(ai: true, ramGb: 2, freeStorageGb: 0.5, gpu: false)),
        AiTier.a,
      );
    });

    test('RAM 4.0 + trống 2.0 + GPU delegate → Tier B (đúng biên là ĐẠT)', () {
      expect(classifyTier(_cap()), AiTier.b);
    });

    test('RAM 3.9 → Tier C', () {
      expect(classifyTier(_cap(ramGb: 3)), AiTier.c);
    });

    test('dung lượng 1.9 → Tier C; 2.5 → Tier B', () {
      expect(classifyTier(_cap(freeStorageGb: 1.9)), AiTier.c);
      expect(classifyTier(_cap(freeStorageGb: 2.5)), AiTier.b);
    });

    test('thiếu GPU delegate → Tier C', () {
      expect(classifyTier(_cap(gpu: false)), AiTier.c);
    });

    test('Tier C không bao giờ chặn luồng — luôn trả về một tier', () {
      expect(
        classifyTier(_cap(ramGb: 0, freeStorageGb: 0, gpu: false)),
        AiTier.c,
      );
    });
  });

  group('isStale — hết hạn 30 ngày (FR-008)', () {
    final checkedAt = DateTime(2026, 9, 1);
    test('29 ngày → còn dùng được', () {
      expect(isStale(_cap(checkedAt: checkedAt), DateTime(2026, 9, 30)), isFalse);
    });

    test('đúng 30 ngày → hết hạn', () {
      expect(isStale(_cap(checkedAt: checkedAt), DateTime(2026, 10, 1)), isTrue);
    });

    test('31 ngày → hết hạn', () {
      expect(isStale(_cap(checkedAt: checkedAt), DateTime(2026, 10, 2)), isTrue);
    });
  });

  group('DeviceCapability JSON', () {
    test('round-trip giữ nguyên giá trị', () {
      final cap = _cap(ramGb: 6, freeStorageGb: 12.5, ai: true, gpu: false);
      final back = DeviceCapability.fromJson(cap.toJson());
      expect(back, isNotNull);
      expect(back!.ramGb, 6);
      expect(back.freeStorageGb, 12.5);
      expect(back.supportsOnDeviceAi, isTrue);
      expect(back.supportsGpuDelegate, isFalse);
      expect(back.osVersion, 'Android 14');
      expect(back.checkedAt, cap.checkedAt);
    });

    test('JSON hỏng/rỗng/thiếu trường → null, không ném', () {
      expect(DeviceCapability.fromJson(null), isNull);
      expect(DeviceCapability.fromJson('không phải map'), isNull);
      expect(DeviceCapability.fromJson(<String, dynamic>{}), isNull);
      expect(DeviceCapability.fromJson({'ramGb': 4}), isNull);
      expect(
        DeviceCapability.fromJson({
          'ramGb': 'bốn',
          'freeStorageGb': 2,
          'supportsOnDeviceAi': false,
          'supportsGpuDelegate': true,
          'osVersion': 'x',
          'checkedAt': 'không phải ngày',
        }),
        isNull,
      );
    });
  });
}
