/// Khóa row "Ẩn số dư (Privacy mode)" trong bảng `AppSettings`.
const String kKeyHideBalance = 'hideBalance';

/// Khóa row "Máy tính khi nhập số tiền" trong bảng `AppSettings`.
const String kKeyAmountCalculatorEnabled = 'amountCalculatorEnabled';

/// Trạng thái 2 công tắc màn Tiện ích & Cá nhân hóa — nạp từ [UtilitiesStore].
/// Mặc định theo mockup `01`: Ẩn số dư TẮT, Máy tính BẬT. Row trong bảng
/// `AppSettings` chỉ được ghi khi người dùng bật/tắt (write-through); key vắng
/// mặt = chưa từng đổi → tầng này giữ mặc định domain.
class UtilitiesPrefs {
  const UtilitiesPrefs({
    this.hideBalance = false,
    this.amountCalculatorEnabled = true,
  });

  /// "Ẩn số dư (Privacy mode)" — mặc định tắt (mockup).
  final bool hideBalance;

  /// "Máy tính khi nhập số tiền" — mặc định bật (mockup).
  final bool amountCalculatorEnabled;

  /// Đủ 2 row `(key, 'true'/'false')` — mọi bool lưu chuỗi 'true'/'false'.
  Map<String, String> toSettings() => {
    kKeyHideBalance: hideBalance ? 'true' : 'false',
    kKeyAmountCalculatorEnabled: amountCalculatorEnabled ? 'true' : 'false',
  };

  /// Từ các row đọc từ bảng: key vắng mặt → giữ mặc định; chuỗi ngoài
  /// 'true'/'false' → mặc định (an toàn, không ném).
  factory UtilitiesPrefs.fromSettings(Map<String, String> rows) {
    return UtilitiesPrefs(
      hideBalance: _parseBool(rows[kKeyHideBalance], false),
      amountCalculatorEnabled: _parseBool(rows[kKeyAmountCalculatorEnabled], true),
    );
  }

  static bool _parseBool(String? raw, bool domainDefault) {
    if (raw == 'true') return true;
    if (raw == 'false') return false;
    return domainDefault;
  }

  /// Bản sao với các trường thay đổi — dùng cho toggle.
  UtilitiesPrefs copyWith({bool? hideBalance, bool? amountCalculatorEnabled}) =>
      UtilitiesPrefs(
        hideBalance: hideBalance ?? this.hideBalance,
        amountCalculatorEnabled: amountCalculatorEnabled ?? this.amountCalculatorEnabled,
      );
}
