import 'device_tier.dart';

/// Seam đo cấu hình máy — màn kiểm tra cấu hình phụ thuộc interface này để test
/// bơm fake 3 ca A/B/C. Impl thật: `PlatformDeviceProbe` (`device_info_plus` +
/// kênh native `sora_thu_chi/device_probe`, R5).
abstract class DeviceProbe {
  /// Đo RAM / dung lượng trống / khả năng AI / phiên bản hệ điều hành.
  /// Impl thật **không ném**: lỗi kênh native → giá trị mặc định an toàn
  /// (dung lượng 0 ⇒ Tier C, luồng quét vẫn chạy — rủi ro 11).
  Future<DeviceCapability> measure();
}
