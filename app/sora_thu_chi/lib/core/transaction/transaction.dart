/// Loại giao dịch — quyết định màu/dấu/dòng phụ trên màn chi tiết ví.
enum TxnType { income, expense, transfer, adjustment }

extension TxnTypeLabelX on TxnType {
  /// Tên loại tiếng Việt — tiêu đề fallback & dòng phụ khi không có danh mục.
  String get label => switch (this) {
    TxnType.income => 'Thu',
    TxnType.expense => 'Chi',
    TxnType.transfer => 'Chuyển khoản',
    TxnType.adjustment => 'Điều chỉnh số dư',
  };
}

/// Giao dịch — subset màn chi tiết ví cần (đợt này chỉ đọc từ bộ mẫu).
/// [amount] **signed** (VND) = tác động ròng lên ví chứa dòng: thu/`+` tăng số
/// dư, chi/`-` giảm; chuyển khoản là 2 dòng thuộc 2 ví (nguồn `< 0`, đích `> 0`).
class Transaction {
  const Transaction({
    required this.id,
    required this.walletId,
    required this.type,
    this.category = '',
    this.note = '',
    required this.amount,
    required this.date,
    this.transferGroupId,
  });

  final int id;
  final int walletId;
  final TxnType type;

  /// Tên danh mục (thu/chi); transfer & adjustment để rỗng → fallback [TxnType.label].
  final String category;

  /// Ghi chú — tiêu đề dòng khi có; không có → dùng [category].
  final String note;

  final int amount;
  final DateTime date;

  /// id nhóm 2 vế của một khoản chuyển khoản (map từ `transfer_group_id`).
  /// null = giao dịch thường hoặc vế chưa nối; dùng để gộp 2 vế transfer
  /// thành 1 dòng trên màn danh sách (FR-007). Additive — màn ví không dùng.
  final int? transferGroupId;

  String get typeLabel => type.label;
}

/// Lọc giao dịch đúng ví [walletId] (FR-008).
List<Transaction> transactionsForWallet(
  List<Transaction> transactions,
  int walletId,
) => transactions.where((t) => t.walletId == walletId).toList();

/// Sắp giao dịch theo ngày mới nhất lên đầu; trùng ngày ổn định theo [Transaction.id]
/// tăng dần. Thuần — không đổi list đầu vào.
List<Transaction> sortNewestFirst(List<Transaction> transactions) {
  final sorted = [...transactions];
  sorted.sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;
    return a.id.compareTo(b.id);
  });
  return sorted;
}
