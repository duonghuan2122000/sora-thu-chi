import 'package:flutter/material.dart';

/// Token màu **bất biến** — không đổi theo giao diện: fill thương hiệu teal,
/// trắng on-brand (đặt trên nền teal/FAB), fill coral cho chi/cảnh báo, cùng
/// bảng màu nhận diện danh mục/ví và avatar.
///
/// Token **đổi theo theme** (nền, chữ, kẻ ngang, vòng nền nhạt, glyph teal/coral
/// trên nền trung tính…) nay sống ở `SoraColors.light`/`SoraColors.dark` và đọc
/// qua `SoraColors.of(context)` — xem `theme/sora_colors.dart`.
abstract final class AppColors {
  static const Color teal = Color(0xFF0F6E56);
  static const Color white = Color(0xFFFFFFFF);
  static const Color coral = Color(0xFFD85A30);
  static const Color avatarBg = Color(0xFF3D8C77);

  // Bảng màu danh mục (palette mockup `02` — R2). Chỉ token; dữ liệu bảng màu
  // preset tập trung ở `category_presets.categoryPresetColors` (màu seed đã là
  // token teal/avatarBg/coral + 2 token sáng của `SoraColors.light`).
  static const Color categoryOrange = Color(0xFFF2994A);
  static const Color categoryBlue = Color(0xFF2F80ED);
  static const Color categoryPurple = Color(0xFF9B59B6);
  static const Color categoryYellow = Color(0xFFF2C94C);
  static const Color categoryRed = Color(0xFFEB5757);
  static const Color categoryCyan = Color(0xFF56CCF2);
  static const Color categoryGreen = Color(0xFF27AE60);
  static const Color categoryViolet = Color(0xFFBB6BD9);

  // Bảng màu ví (form thêm/sửa — preset chọn màu). Không dùng coral (dành cho
  // chi tiêu/cảnh báo); đủ tương phản với chữ trắng khi hiển thị trên nền màu.
  static const Color walletGreen = Color(0xFF0F6E56); // thương hiệu
  static const Color walletSea = Color(0xFF2A9D8F);
  static const Color walletBlue = Color(0xFF3E7CB1);
  static const Color walletNavy = Color(0xFF355070);
  static const Color walletIndigo = Color(0xFF4A56A6);
  static const Color walletViolet = Color(0xFF7A5CA8);
  static const Color walletPink = Color(0xFFC75A82);
  static const Color walletAmber = Color(0xFFC98A2D);
  static const Color walletSlate = Color(0xFF5C6B73);
}
