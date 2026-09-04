/// Hồ sơ thiết bị — duy nhất 1 hồ sơ / 1 bản cài đặt app / 1 thiết bị.
/// Đợt này chỉ hiển thị từ [initial], chưa bền hoá (không luồng ghi).
/// Khi PBI sửa hồ sơ/đổi tiền tệ đến → thêm store nạp/lưu.
class DeviceProfile {
  const DeviceProfile({
    this.displayName,
    this.currencyCode = defaultCurrencyCode,
  });

  static const String defaultDisplayName = 'Người dùng';
  static const String defaultCurrencyCode = 'VND';
  static const DeviceProfile initial = DeviceProfile();

  /// null = chưa đặt tên → vùng hiển thị dùng [resolvedDisplayName].
  final String? displayName;
  final String currencyCode;

  /// Tên đang hiển thị — không bao giờ rỗng (FR-002).
  String get resolvedDisplayName => displayName ?? defaultDisplayName;
}

/// Chữ cái đầu của tối đa 2 từ (tách theo khoảng trắng), in hoa.
/// "Người dùng" → "ND", "Lan" → "L", "Huân Anh" → "HA"; rỗng → ''.
String initialsOf(String name) {
  final words = name.split(' ').where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '';
  return words.take(2).map((w) => w[0].toUpperCase()).join();
}
