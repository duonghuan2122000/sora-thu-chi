import 'scan_settings.dart';

/// Seam đọc/ghi cài đặt quét hóa đơn (4 key bảng `AppSettings`). Impl thật:
/// `DriftScanSettingsStore` (bám `DriftUtilitiesStore`).
abstract class ScanSettingsStore {
  /// Đọc trạng thái hiện hành — key vắng trong bảng → mặc định domain.
  Future<ScanSettings> load();

  /// Ghi write-through 4 key của mình (upsert row, **không** xoá row khác).
  Future<void> save(ScanSettings settings);
}
