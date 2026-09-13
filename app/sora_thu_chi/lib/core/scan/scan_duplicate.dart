import '../transaction/transaction.dart';

/// Cảnh báo trùng **nhẹ** (FR-035): tìm giao dịch đã có cùng số tiền trong
/// khoảng [window] quanh [date] (mặc định ±24h). Bỏ qua chuyển khoản/điều chỉnh
/// số dư (không phải thu/chi). Không chặn lưu — chỉ để hiện banner.
/// Trùng nhiều → trả giao dịch **gần ngày nhất**. Thuần, không đọc DB.
Transaction? findRecentDuplicate(
  List<Transaction> existing, {
  required int amount,
  required DateTime date,
  Duration window = const Duration(hours: 24),
}) {
  Transaction? best;
  Duration? bestDistance;
  for (final t in existing) {
    if (t.type != TxnType.income && t.type != TxnType.expense) continue;
    if (t.amount.abs() != amount) continue;
    final distance = t.date.difference(date).abs();
    if (distance > window) continue;
    if (bestDistance == null || distance < bestDistance) {
      best = t;
      bestDistance = distance;
    }
  }
  return best;
}
