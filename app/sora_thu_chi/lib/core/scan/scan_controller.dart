import 'package:get/get.dart';

import 'device_probe.dart';
import 'device_tier.dart';
import 'scan_result.dart';
import 'scan_settings.dart';
import 'scan_settings_store.dart';

/// Trạng thái quét hóa đơn trong phiên (bám `ThemeController`, R15): sheet FAB
/// và màn Cài đặt cùng đọc một `Rx` ⇒ đổi công tắc ở Cài đặt phản ánh ngay vào
/// sheet. Mặc định an toàn (tắt) trước khi [load] xong.
class ScanController extends GetxController {
  ScanController(this._store, this._probe);

  final ScanSettingsStore _store;
  final DeviceProbe _probe;

  final Rx<ScanSettings> settings = const ScanSettings().obs;

  /// Nối đuôi các lần ghi — chạm nhanh liên tiếp thì lần cuối là trạng thái cuối.
  Future<void> _saveTail = Future<void>.value();

  Future<void> load() async {
    settings.value = await _store.load();
  }

  void setEnabled(bool value) {
    if (value == settings.value.enabled) return;
    _write(settings.value.copyWith(enabled: value));
  }

  void setMode(ScanEngine mode) {
    if (mode == settings.value.mode) return;
    _write(settings.value.copyWith(mode: mode));
  }

  /// Dung lượng model Tier B đang chiếm (0 = chưa tải). [ScanSettings.effectiveEngine]
  /// dựa vào giá trị này ⇒ tải bị ngắt thì luồng quét vẫn ở Chế độ cơ bản (FR-012).
  void setModelBytes(int bytes) {
    if (bytes == settings.value.modelBytes) return;
    _write(settings.value.copyWith(modelBytes: bytes));
  }

  /// Đo cấu hình máy → phân loại tier → lưu kết quả (FR-006/FR-008). Người dùng
  /// chọn chế độ ở màn `scan-10` qua [setMode]; Tier C luôn dùng Chế độ cơ bản.
  Future<DeviceCapability> checkDevice() async {
    final capability = await _probe.measure();
    _write(settings.value.copyWith(deviceCheck: capability));
    return capability;
  }

  /// Ghi qua store **và** cập nhật `Rx` ngay — UI không chờ IO.
  void _write(ScanSettings next) {
    settings.value = next;
    _saveTail = _saveTail.then((_) async {
      try {
        await _store.save(next);
      } catch (_) {
        // Ghi lỗi bỏ qua — lần đổi sau ghi lại trạng thái mới nhất.
      }
    });
  }
}
