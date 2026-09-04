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
}
