import 'transaction.dart';

/// Nguồn giao dịch đợt này = bộ mẫu cố định (spec SC-003) — chưa có luồng ghi
/// giao dịch/DB. Ngày dùng tương đối `DateTime.now()` để màn có đủ nhãn
/// "Hôm nay / Hôm qua / dd/MM". Khi PBI Giao dịch (drift) đến → thay nguồn bằng
/// đọc bảng `transactions`, giữ interface trả [List<Transaction>].
class TransactionSource {
  TransactionSource._();

  /// Bộ mẫu: Vietcombank (id 2) = 3 thu + 2 chi + 1 chuyển khoản đi, dàn
  /// `nền 1.200.000 + Σ signed = 14.800.000` (khớp [WalletSource] PBI 5);
  /// Tiền mặt/VIB vài chi; Momo 1 dòng chuyển khoản đến; Sổ tiết kiệm rỗng.
  static List<Transaction> all() {
    final now = DateTime.now();
    Transaction txn(
      int id,
      int walletId,
      TxnType type,
      String note,
      String category,
      int amount,
      int daysAgo,
    ) => Transaction(
      id: id,
      walletId: walletId,
      type: type,
      note: note,
      category: category,
      amount: amount,
      date: now.subtract(Duration(days: daysAgo)),
    );

    return [
      // Tiền mặt (id 1).
      txn(1, 1, TxnType.expense, 'Ăn trưa văn phòng', 'Ăn uống', -85000, 0),
      txn(2, 1, TxnType.expense, '', 'Di chuyển', -120000, 1),
      // Vietcombank (id 2): 3 thu + 2 chi + 1 chuyển đi.
      txn(3, 2, TxnType.income, 'Lương tháng 8', 'Lương', 12000000, 1),
      txn(4, 2, TxnType.income, '', 'Bán đồ cũ', 2500000, 5),
      txn(5, 2, TxnType.income, '', 'Thu nhập khác', 500000, 2),
      txn(6, 2, TxnType.expense, 'Siêu thị Coopmart', 'Ăn uống', -450000, 0),
      txn(7, 2, TxnType.expense, '', 'Xăng xe', -250000, 1),
      txn(8, 2, TxnType.transfer, 'Chuyển sang Momo', '', -700000, 3),
      // Thẻ tín dụng VIB (id 3): vài chi.
      txn(9, 3, TxnType.expense, 'Mua sắm online', 'Mua sắm', -1200000, 1),
      txn(10, 3, TxnType.expense, '', 'Ăn uống', -350000, 0),
      // Momo (id 4): vế đích của chuyển khoản Vietcombank → Momo.
      txn(11, 4, TxnType.transfer, 'Chuyển sang Momo', '', 700000, 3),
    ];
  }

  /// Giao dịch đúng ví [walletId], sắp mới nhất lên đầu (FR-008).
  static List<Transaction> forWallet(int walletId) =>
      sortNewestFirst(transactionsForWallet(all(), walletId));
}
