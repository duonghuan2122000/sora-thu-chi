import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'wallet.dart';

/// Preset biểu tượng & màu ví cho form thêm/sửa (spec §Giả định "biểu tượng &
/// màu sắc"). Màu tham chiếu token [AppColors] — không hex cứng trong widget.

/// Danh sách biểu tượng (emoji) cho ví người dùng chọn.
const List<String> walletIconChoices = [
  '💵',
  '🏦',
  '💳',
  '📱',
  '🏷️',
  '💰',
  '🪙',
  '🏧',
  '🧾',
  '🛍️',
];

/// Biểu tượng mặc định theo loại ví.
String defaultIconFor(WalletType type) => switch (type) {
  WalletType.cash => '💵',
  WalletType.bank => '🏦',
  WalletType.credit => '💳',
  WalletType.eWallet => '📱',
  WalletType.savings => '🏷️',
};

/// Bảng màu preset — dùng token [AppColors].
const List<Color> walletPresetColors = [
  AppColors.walletGreen,
  AppColors.walletSea,
  AppColors.walletBlue,
  AppColors.walletNavy,
  AppColors.walletIndigo,
  AppColors.walletViolet,
  AppColors.walletPink,
  AppColors.walletAmber,
  AppColors.walletSlate,
];

/// Màu mặc định theo loại ví — trả ARGB int (Wallet lưu số, không import Flutter).
int defaultColorValueFor(WalletType type) =>
    defaultColorFor(type).toARGB32();

Color defaultColorFor(WalletType type) => switch (type) {
  WalletType.cash => AppColors.walletGreen,
  WalletType.bank => AppColors.walletNavy,
  WalletType.credit => AppColors.walletAmber,
  WalletType.eWallet => AppColors.walletSea,
  WalletType.savings => AppColors.walletSlate,
};
