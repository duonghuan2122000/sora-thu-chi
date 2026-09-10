import 'package:get/get.dart';

import '../money_format.dart';

/// Loại ví / tài khoản.
enum WalletType { cash, bank, credit, eWallet, savings }

extension WalletTypeLabelX on WalletType {
  /// Tên loại tiếng Việt hiển thị ở dòng phụ hàng ví.
  String get label => switch (this) {
        WalletType.cash => 'Tiền mặt'.tr,
        WalletType.bank => 'Tài khoản ngân hàng'.tr,
        WalletType.credit => 'Thẻ tín dụng'.tr,
        WalletType.eWallet => 'Ví điện tử'.tr,
        WalletType.savings => 'Sổ tiết kiệm'.tr,
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
    this.initialBalance,
    required this.balance,
    this.currency = 'VND',
    this.color,
    this.isDefault = false,
    this.isHidden = false,
    this.sortOrder = 0,
    this.creditLimit,
    this.creditUsed,
    this.statementDate,
    this.dueDate,
    this.termMonths,
    this.maturityDate,
    this.institutionName,
    this.lastDigits,
  });

  final int id;
  final String name;
  final WalletType type;
  final String icon;

  /// Số dư ban đầu khi tạo ví. Trước khi có giao dịch thì bằng [balance].
  /// null (ví khởi tạo tay) → coi như [balance] ([initialBalanceValue]).
  final int? initialBalance;

  /// Balance là số dư hiện tại (đại lượng suy ra ở đời thật, đợt này cấp thẳng).
  final int balance;

  /// Tiền tệ của ví (đợt này cố định 'VND' — đa tiền tệ PBI riêng).
  final String currency;

  /// Màu nhận diện (ARGB int) — chọn từ preset; null → dùng mặc định theo loại.
  final int? color;

  final bool isDefault;
  final bool isHidden;
  final int sortOrder;

  /// Chỉ thẻ tín dụng: hạn mức & số đã dùng.
  final int? creditLimit;
  final int? creditUsed;

  /// Chỉ thẻ tín dụng: ngày sao kê & ngày đến hạn thanh toán (tùy chọn).
  final DateTime? statementDate;
  final DateTime? dueDate;

  /// Chỉ sổ tiết kiệm: kỳ hạn (tháng) & ngày đáo hạn (tùy chọn).
  final int? termMonths;
  final DateTime? maturityDate;

  /// Ngân hàng / tổ chức (eWallet) & số cuối tài khoản — chỉ hiển thị.
  final String? institutionName;
  final String? lastDigits;

  /// Số dư ban đầu hiệu dụng: lưu rõ thì dùng, không thì bằng [balance].
  int get initialBalanceValue => initialBalance ?? balance;

  /// Tỷ lệ sử dụng thẻ (chia nguyên để khớp mockup 6.500.000/20.000.000 → 32%).
  /// Hạn mức ≤ 0 → 0%.
  int get creditUsedPercent {
    final limit = creditLimit ?? 0;
    if (limit <= 0) return 0;
    return (creditUsed ?? 0) * 100 ~/ limit;
  }

  /// `Đã dùng {đã dùng} / {hạn mức} đ` — dòng phụ thẻ tín dụng (FR-007).
  String get creditUsageLabel => 'Đã dùng @used / @limit đ'.trParams({
        'used': formatAmount(creditUsed ?? 0),
        'limit': formatAmount(creditLimit ?? 0),
      });

  /// Tên hiển thị khi ví đã ẩn — hậu tố dịch, tên ví là dữ liệu giữ nguyên.
  String get hiddenName => '$name ${'(đã ẩn)'.tr}';

  String get typeLabel => type.label;

  /// Bản sao ví với các trường thay đổi. Bỏ qua [id]/[isHidden] — định danh & cờ
  /// ẩn bất biến trong luồng sửa này (FR-012). [isDefault] do controller/rules
  /// truyền (bất biến đúng-1-mặc-định), form không tự đặt qua copyWith.
  Wallet copyWith({
    String? name,
    WalletType? type,
    String? icon,
    int? initialBalance,
    int? balance,
    String? currency,
    int? color,
    int? sortOrder,
    int? creditLimit,
    int? creditUsed,
    DateTime? statementDate,
    DateTime? dueDate,
    int? termMonths,
    DateTime? maturityDate,
    String? institutionName,
    String? lastDigits,
    bool? isDefault,
  }) => Wallet(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    icon: icon ?? this.icon,
    initialBalance: initialBalance ?? initialBalanceValue,
    balance: balance ?? this.balance,
    currency: currency ?? this.currency,
    color: color ?? this.color,
    isDefault: isDefault ?? this.isDefault,
    isHidden: isHidden,
    sortOrder: sortOrder ?? this.sortOrder,
    creditLimit: creditLimit ?? this.creditLimit,
    creditUsed: creditUsed ?? this.creditUsed,
    statementDate: statementDate ?? this.statementDate,
    dueDate: dueDate ?? this.dueDate,
    termMonths: termMonths ?? this.termMonths,
    maturityDate: maturityDate ?? this.maturityDate,
    institutionName: institutionName ?? this.institutionName,
    lastDigits: lastDigits ?? this.lastDigits,
  );
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
