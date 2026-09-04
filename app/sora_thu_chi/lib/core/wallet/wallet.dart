import '../money_format.dart';

/// Loại ví / tài khoản.
enum WalletType { cash, bank, credit, eWallet, savings }

extension WalletTypeLabelX on WalletType {
  /// Tên loại tiếng Việt hiển thị ở dòng phụ hàng ví.
  String get label => switch (this) {
        WalletType.cash => 'Tiền mặt',
        WalletType.bank => 'Tài khoản ngân hàng',
        WalletType.credit => 'Thẻ tín dụng',
        WalletType.eWallet => 'Ví điện tử',
        WalletType.savings => 'Sổ tiết kiệm',
      };
}

/// Ví / tài khoản — subset trường màn danh sách cần.
/// [balance] là số dư hiện tại (đại lượng suy ra ở đời thật, đợt này cấp thẳng).
class Wallet {
  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    this.icon = '',
    required this.balance,
    this.isDefault = false,
    this.isHidden = false,
    this.sortOrder = 0,
    this.creditLimit,
    this.creditUsed,
  });

  final int id;
  final String name;
  final WalletType type;
  final String icon;
  final int balance;
  final bool isDefault;
  final bool isHidden;
  final int sortOrder;

  /// Chỉ thẻ tín dụng: hạn mức & số đã dùng.
  final int? creditLimit;
  final int? creditUsed;

  /// Tỷ lệ sử dụng thẻ (chia nguyên để khớp mockup 6.500.000/20.000.000 → 32%).
  /// Hạn mức ≤ 0 → 0%.
  int get creditUsedPercent {
    final limit = creditLimit ?? 0;
    if (limit <= 0) return 0;
    return (creditUsed ?? 0) * 100 ~/ limit;
  }

  /// `Đã dùng {đã dùng} / {hạn mức} đ` — dòng phụ thẻ tín dụng (FR-007).
  String get creditUsageLabel =>
      'Đã dùng ${formatAmount(creditUsed ?? 0)} / ${formatAmount(creditLimit ?? 0)} đ';

  /// Tên hiển thị khi ví đã ẩn.
  String get hiddenName => '$name (đã ẩn)';

  String get typeLabel => type.label;
}

/// Thứ tự hiển thị: ví đang hoạt động theo [Wallet.sortOrder], ví ẩn xếp cuối.
List<Wallet> walletsByDisplayOrder(List<Wallet> wallets) {
  final visible = <Wallet>[];
  final hidden = <Wallet>[];
  for (final wallet in wallets) {
    (wallet.isHidden ? hidden : visible).add(wallet);
  }
  visible.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  hidden.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return [...visible, ...hidden];
}

/// Tổng số dư ví đang hoạt động — không ẩn, không phải thẻ tín dụng (Q3).
int activeTotal(List<Wallet> wallets) => wallets
    .where((w) => !w.isHidden && w.type != WalletType.credit)
    .fold(0, (sum, w) => sum + w.balance);

/// Số ví đang hoạt động — mọi ví không ẩn, gồm thẻ tín dụng.
int activeCount(List<Wallet> wallets) =>
    wallets.where((w) => !w.isHidden).length;
