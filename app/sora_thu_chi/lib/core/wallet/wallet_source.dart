import 'wallet.dart';

/// Nguồn ví đợt này = bộ mẫu cố định (spec SC-003) — chưa có luồng tạo ví/DB.
/// Khi PBI form ví đến → thay nguồn bằng đọc drift, giữ interface trả [List<Wallet>].
class WalletSource {
  WalletSource._();

  static const List<Wallet> _all = [
    Wallet(
      id: 1,
      name: 'Tiền mặt',
      type: WalletType.cash,
      icon: '💵',
      balance: 3200000,
      isDefault: true,
      sortOrder: 1,
    ),
    Wallet(
      id: 2,
      name: 'Vietcombank',
      type: WalletType.bank,
      icon: '🏦',
      initialBalance: 1200000, // gốc 1.200.000, đã có giao dịch → số dư 14.800.000
      balance: 14800000,
      sortOrder: 2,
    ),
    Wallet(
      id: 3,
      name: 'Thẻ tín dụng VIB',
      type: WalletType.credit,
      icon: '💳',
      balance: 0,
      sortOrder: 3,
      creditLimit: 20000000,
      creditUsed: 6500000,
    ),
    Wallet(
      id: 4,
      name: 'Momo',
      type: WalletType.eWallet,
      icon: '📱',
      balance: 1450000,
      sortOrder: 4,
    ),
    Wallet(
      id: 5,
      name: 'Sổ tiết kiệm',
      type: WalletType.savings,
      icon: '🏷️',
      balance: 9000000,
      isHidden: true,
      sortOrder: 5,
    ),
  ];

  static List<Wallet> all() => _all;
}
