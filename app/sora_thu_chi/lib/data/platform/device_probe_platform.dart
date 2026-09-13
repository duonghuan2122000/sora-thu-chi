import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/scan/device_probe.dart';
import '../../core/scan/device_tier.dart';

/// Kênh native duy nhất của tính năng quét (R5) — đo cấu hình máy **và** gọi
/// Gemini Nano ở Tier A (`genAiGenerate`) dùng chung kênh này (R18).
const MethodChannel kDeviceProbeChannel = MethodChannel(
  'sora_thu_chi/device_probe',
);

/// Impl thật của [DeviceProbe]: `device_info_plus` cho RAM/phiên bản HĐH, kênh
/// native `sora_thu_chi/device_probe` cho dung lượng trống / AICore / GPU
/// delegate (R5). **Không ném**: mọi lỗi (kênh chưa đăng ký, plugin thiếu) →
/// giá trị mặc định an toàn — dung lượng 0 ⇒ Tier C, luồng quét vẫn chạy
/// (rủi ro 11).
class PlatformDeviceProbe implements DeviceProbe {
  PlatformDeviceProbe({DeviceInfoPlugin? deviceInfo, DateTime Function()? now})
    : _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
      _now = now ?? DateTime.now;

  final DeviceInfoPlugin _deviceInfo;
  final DateTime Function() _now;

  @override
  Future<DeviceCapability> measure() async {
    final native = await _probeNative();
    final info = await _deviceInfoSafe();
    return DeviceCapability(
      ramGb: info.ramGb,
      freeStorageGb: native.freeStorageGb,
      supportsOnDeviceAi: native.supportsOnDeviceAi,
      supportsGpuDelegate: native.supportsGpuDelegate,
      osVersion: info.osVersion,
      checkedAt: _now(),
    );
  }

  Future<({double freeStorageGb, bool supportsOnDeviceAi, bool supportsGpuDelegate})>
  _probeNative() async {
    try {
      final result = await kDeviceProbeChannel.invokeMapMethod<String, Object?>(
        'probe',
      );
      if (result == null) return _nativeFallback;
      return (
        freeStorageGb: (result['freeStorageGb'] as num?)?.toDouble() ?? 0,
        supportsOnDeviceAi: result['supportsOnDeviceAi'] as bool? ?? false,
        supportsGpuDelegate: result['supportsGpuDelegate'] as bool? ?? false,
      );
    } catch (_) {
      return _nativeFallback;
    }
  }

  static const _nativeFallback = (
    freeStorageGb: 0.0,
    supportsOnDeviceAi: false,
    supportsGpuDelegate: false,
  );

  Future<({int ramGb, String osVersion})> _deviceInfoSafe() async {
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final a = await _deviceInfo.androidInfo;
          return (
            ramGb: gbFromMb(a.physicalRamSize),
            osVersion: 'Android ${a.version.release}',
          );
        case TargetPlatform.iOS:
          final i = await _deviceInfo.iosInfo;
          return (
            ramGb: gbFromMb(i.physicalRamSize),
            osVersion: '${i.systemName} ${i.systemVersion}',
          );
        default:
          break;
      }
    } catch (_) {
      // Rơi xuống mặc định an toàn bên dưới.
    }
    // Chuỗi rỗng = "không đọc được" — màn `scan-10` hiển thị nhãn đã dịch
    // (giữ tầng dữ liệu không phụ thuộc ngôn ngữ).
    return (ramGb: 0, osVersion: '');
  }

  /// `device_info_plus` trả RAM theo **megabyte** (Android: `totalMem / 1048576`,
  /// iOS: cùng đơn vị) — **không phải** byte.
  static int gbFromMb(int megabytes) => megabytes ~/ 1024;
}
