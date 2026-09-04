import 'package:flutter/material.dart';

/// Token màu tập trung — nguồn duy nhất cho màu trong widget.
/// Chỉ kê màu đang tiêu thụ; bổ sung khi module cần.
abstract final class AppColors {
  static const Color teal = Color(0xFF0F6E56);
  static const Color white = Color(0xFFFFFFFF);
  static const Color tealLightText = Color(0xFFCDE9DF);
  static const Color tabInactive = Color(0xFF9B9B9B);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color dotEmpty = Color(0xFFB4B2A9);
  static const Color coral = Color(0xFFD85A30);
  static const Color avatarBg = Color(0xFF3D8C77);
  static const Color listLabel = Color(0xFF5F5E5A);
  static const Color listDivider = Color(0xFFEFEFEF);
  static const Color coralLightBg = Color(0xFFFAECE7);
  static const Color tealLightBg = Color(0xFFE1F5EE);
  static const Color softCardBg = Color(0xFFF1EFE8);

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
