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
}
