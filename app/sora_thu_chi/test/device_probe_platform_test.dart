import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/data/platform/device_probe_platform.dart';

/// `device_info_plus` trả RAM theo **MB** — quy đổi sai đơn vị từng làm màn
/// `scan-10` hiện "0 GB — Không đạt" trên mọi máy (kể cả máy thật 8GB).
void main() {
  group('gbFromMb', () {
    test('RAM máy thật (MB) → GB', () {
      expect(PlatformDeviceProbe.gbFromMb(8192), 8);
      expect(PlatformDeviceProbe.gbFromMb(6144), 6);
      expect(PlatformDeviceProbe.gbFromMb(4096), 4);
      expect(PlatformDeviceProbe.gbFromMb(2048), 2);
    });

    test('dưới 1 GB → 0 (vẫn "Không đạt" đúng nghĩa)', () {
      expect(PlatformDeviceProbe.gbFromMb(512), 0);
      expect(PlatformDeviceProbe.gbFromMb(0), 0);
    });

    test('lẻ MB làm tròn xuống, không vống lên ngưỡng 4GB', () {
      expect(PlatformDeviceProbe.gbFromMb(3999), 3);
    });
  });
}
