import 'dart:convert';

import 'device_tier.dart';
import 'scan_result.dart';

/// Khóa row trong bảng key-value `AppSettings` (data-model §1.4) — không
/// migration, chỉ thêm row khi người dùng đổi (write-through).
const String kKeyScanEnabled = 'scanEnabled';
const String kKeyScanEngineMode = 'scanEngineMode';
const String kKeyScanModelBytes = 'scanModelBytes';
const String kKeyScanDeviceCheck = 'scanDeviceCheck';

/// Trạng thái cài đặt quét hóa đơn — view của 4 key trên. Mọi giá trị lạ/thiếu
/// key → mặc định an toàn, **không ném** (data-model §2.6).
class ScanSettings {
  const ScanSettings({
    this.enabled = false,
    this.mode = ScanEngine.ruleBased,
    this.modelBytes = 0,
    this.deviceCheck,
  });

  /// Công tắc bật/tắt tính năng (FR-003). Vắng key = tắt.
  final bool enabled;

  /// Chế độ AI đang dùng (FR-004). Vắng key = Chế độ cơ bản.
  final ScanEngine mode;

  /// Dung lượng model đang chiếm; 0 = chưa tải (FR-004, chặng 2).
  final int modelBytes;

  /// Kết quả kiểm tra cấu hình gần nhất; null = chưa từng kiểm tra (FR-008).
  final DeviceCapability? deviceCheck;

  /// Engine **thực sự dùng được** theo cài đặt hiện tại (T057/FR-012): Tier B
  /// chỉ chạy khi model đã tải xong ([modelBytes] > 0); chưa tải thì rơi về
  /// Chế độ cơ bản thay vì gọi model không tồn tại. Tier A (Gemini Nano) do
  /// AICore hệ thống quản lý — không cần tải.
  ScanEngine get effectiveEngine =>
      mode == ScanEngine.gemma3nE2b && modelBytes <= 0
      ? ScanEngine.ruleBased
      : mode;

  /// Chưa từng kiểm tra, hoặc kết quả cũ quá 30 ngày → cần đo lại (FR-008).
  bool needsDeviceCheck(DateTime now) {
    final check = deviceCheck;
    return check == null || isStale(check, now);
  }

  /// Đủ 4 row `(key, value)` — chỉ 4 key của mình, không xoá key khác.
  Map<String, String> toSettings() => {
    kKeyScanEnabled: enabled ? 'true' : 'false',
    kKeyScanEngineMode: _engineToStored(mode),
    kKeyScanModelBytes: '${modelBytes < 0 ? 0 : modelBytes}',
    if (deviceCheck != null) kKeyScanDeviceCheck: jsonEncode(deviceCheck!.toJson()),
  };

  factory ScanSettings.fromSettings(Map<String, String> rows) {
    return ScanSettings(
      enabled: rows[kKeyScanEnabled] == 'true',
      mode: _engineFromStored(rows[kKeyScanEngineMode]),
      modelBytes: _parseBytes(rows[kKeyScanModelBytes]),
      deviceCheck: _parseDeviceCheck(rows[kKeyScanDeviceCheck]),
    );
  }

  ScanSettings copyWith({
    bool? enabled,
    ScanEngine? mode,
    int? modelBytes,
    DeviceCapability? deviceCheck,
  }) => ScanSettings(
    enabled: enabled ?? this.enabled,
    mode: mode ?? this.mode,
    modelBytes: modelBytes ?? this.modelBytes,
    deviceCheck: deviceCheck ?? this.deviceCheck,
  );

  static int _parseBytes(String? raw) {
    final parsed = int.tryParse(raw ?? '');
    if (parsed == null || parsed < 0) return 0;
    return parsed;
  }

  static String _engineToStored(ScanEngine e) => switch (e) {
    ScanEngine.ruleBased => 'rule_based',
    ScanEngine.geminiNano => 'gemini_nano',
    ScanEngine.gemma3nE2b => 'gemma_3n_e2b',
  };

  static ScanEngine _engineFromStored(String? raw) => switch (raw) {
    'gemini_nano' => ScanEngine.geminiNano,
    'gemma_3n_e2b' => ScanEngine.gemma3nE2b,
    _ => ScanEngine.ruleBased,
  };

  static DeviceCapability? _parseDeviceCheck(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DeviceCapability.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }
}
