import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'sora_colors.dart';

/// Theme tập trung của app — widget không nhúng màu/hex cứng.
/// Bộ 2 theme (sáng/tối) đăng ký [SoraColors] tương ứng làm `ThemeExtension`.
abstract final class AppTheme {
  /// App bar giữ fill teal thương hiệu + chữ/icon trắng ở **cả 2** theme
  /// (nhận diện — FR-009).
  static const _appBarTheme = AppBarTheme(
    backgroundColor: AppColors.teal,
    foregroundColor: AppColors.white,
    titleTextStyle: TextStyle(
      color: AppColors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    centerTitle: false,
  );

  static ThemeData get themeData {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.teal);
    return ThemeData(
      scaffoldBackgroundColor: SoraColors.light.background,
      colorScheme: colorScheme,
      appBarTheme: _appBarTheme,
      extensions: const [SoraColors.light],
    );
  }

  static ThemeData get darkThemeData {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: Brightness.dark,
    );
    return ThemeData(
      scaffoldBackgroundColor: SoraColors.dark.background,
      colorScheme: colorScheme,
      appBarTheme: _appBarTheme,
      extensions: const [SoraColors.dark],
    );
  }
}
