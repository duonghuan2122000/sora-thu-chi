/// Kết quả đo cấu hình máy (data-model §2.5) — đại lượng **thuần**, đo ở
/// `DeviceProbe`, lưu 1 row JSON `scanDeviceCheck`, hết hạn sau 30 ngày.
class DeviceCapability {
  const DeviceCapability({
    required this.ramGb,
    required this.freeStorageGb,
    required this.supportsOnDeviceAi,
    required this.supportsGpuDelegate,
    required this.osVersion,
    required this.checkedAt,
  });

  final int ramGb;
  final double freeStorageGb;

  /// Có AICore / Gemini Nano của hệ thống (Android) — điều kiện Tier A.
  final bool supportsOnDeviceAi;

  /// Chip có đường tăng tốc (NNAPI / Neural Engine) — điều kiện Tier B.
  final bool supportsGpuDelegate;

  final String osVersion;
  final DateTime checkedAt;

  Map<String, dynamic> toJson() => {
    'ramGb': ramGb,
    'freeStorageGb': freeStorageGb,
    'supportsOnDeviceAi': supportsOnDeviceAi,
    'supportsGpuDelegate': supportsGpuDelegate,
    'osVersion': osVersion,
    'checkedAt': checkedAt.toIso8601String(),
  };

  /// JSON hỏng/rỗng/thiếu trường bắt buộc → `null` (coi như chưa kiểm tra),
  /// **không ném** (data-model §2.5 bất biến).
  static DeviceCapability? fromJson(Object? json) {
    if (json is! Map) return null;
    final ram = json['ramGb'];
    final free = json['freeStorageGb'];
    final ai = json['supportsOnDeviceAi'];
    final gpu = json['supportsGpuDelegate'];
    final os = json['osVersion'];
    final checkedAt = DateTime.tryParse('${json['checkedAt']}');
    if (ram is! int || free is! num || ai is! bool || gpu is! bool) return null;
    if (os is! String || checkedAt == null) return null;
    return DeviceCapability(
      ramGb: ram,
      freeStorageGb: free.toDouble(),
      supportsOnDeviceAi: ai,
      supportsGpuDelegate: gpu,
      osVersion: os,
      checkedAt: checkedAt,
    );
  }
}

/// Phân loại thiết bị theo doc §11.2: A = dùng được AI hệ thống ngay; B = phải
/// tải model; C = Chế độ cơ bản. Kết quả **chỉ để chọn chế độ**, không cam kết
/// chất lượng; Tier C không bao giờ chặn luồng (SC-008).
enum AiTier { a, b, c }

/// Ngưỡng đóng theo doc §11.2: RAM ≥ 4GB **và** dung lượng trống ≥ 2GB **và**
/// có đường tăng tốc chip. Hàm thuần — chỉ phụ thuộc tham số.
AiTier classifyTier(DeviceCapability c) {
  if (c.supportsOnDeviceAi) return AiTier.a;
  if (c.ramGb >= 4 && c.freeStorageGb >= 2.0 && c.supportsGpuDelegate) {
    return AiTier.b;
  }
  return AiTier.c;
}

/// Kết quả kiểm tra đã cũ chưa (quá [days] ngày) → cần đo lại (FR-008).
bool isStale(DeviceCapability c, DateTime now, {int days = 30}) =>
    now.difference(c.checkedAt).inDays >= days;
