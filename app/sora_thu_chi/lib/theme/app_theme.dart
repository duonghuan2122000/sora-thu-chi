import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme tập trung của app — widget không nhúng màu/hex cứng.
abstract final class AppTheme {
  static ThemeData get themeData {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.teal);
    return ThemeData(
      scaffoldBackgroundColor: AppColors.white,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.teal,
        foregroundColor: AppColors.white,
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        centerTitle: false,
      ),
    );
  }
}
