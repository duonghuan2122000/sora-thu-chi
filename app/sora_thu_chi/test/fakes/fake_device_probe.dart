import 'package:sora_thu_chi/core/scan/device_probe.dart';
import 'package:sora_thu_chi/core/scan/device_tier.dart';

/// Fake [DeviceProbe] — trả [capability] dựng sẵn (mặc định Tier C như emulator)
/// và đếm số lần đo để assert "không chạy lại kiểm tra".
class FakeDeviceProbe implements DeviceProbe {
  FakeDeviceProbe([DeviceCapability? capability])
    : capability = capability ?? tierC();

  DeviceCapability capability;
  int measureCount = 0;

  @override
  Future<DeviceCapability> measure() async {
    measureCount++;
    return capability;
  }

  static DeviceCapability tierA({DateTime? at}) => DeviceCapability(
    ramGb: 8,
    freeStorageGb: 30,
    supportsOnDeviceAi: true,
    supportsGpuDelegate: true,
    osVersion: 'Android 15',
    checkedAt: at ?? DateTime(2026, 9, 12),
  );

  static DeviceCapability tierB({DateTime? at}) => DeviceCapability(
    ramGb: 6,
    freeStorageGb: 14,
    supportsOnDeviceAi: false,
    supportsGpuDelegate: true,
    osVersion: 'Android 14',
    checkedAt: at ?? DateTime(2026, 9, 12),
  );

  static DeviceCapability tierC({DateTime? at}) => DeviceCapability(
    ramGb: 3,
    freeStorageGb: 1.2,
    supportsOnDeviceAi: false,
    supportsGpuDelegate: false,
    osVersion: 'Android 14',
    checkedAt: at ?? DateTime(2026, 9, 12),
  );
}
