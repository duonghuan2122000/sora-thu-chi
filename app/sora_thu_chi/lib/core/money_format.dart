/// Định dạng số tiền VND theo design system — dấu chấm phân tách nghìn,
/// không kèm đơn vị; số âm có dấu trừ đứng trước.
String formatAmount(int value) {
  final sign = value < 0 ? '-' : '';
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '$sign$buffer';
}

/// [formatAmount] kèm đơn vị `đ` (cách một khoảng trắng), VD `42.500.000 đ`.
String formatMoney(int value) => '${formatAmount(value)} đ';

/// [formatMoney] kèm dấu `+`/`-` tường minh — số tiền trên dòng giao dịch
/// (thu `+`, chi `-`). `0` → `'0 đ'`; VD `+18.000.000 đ`, `-450.000 đ`.
String formatSignedMoney(int value) {
  final sign = value > 0 ? '+' : '';
  return '$sign${formatMoney(value)}';
}
