import 'package:flutter/material.dart';

import 'core/app_shell.dart';
import 'theme/app_theme.dart';

/// Gốc app. Đổi `MaterialApp` → `GetMaterialApp` khi module đầu cần controller.
class SoraApp extends StatelessWidget {
  const SoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sora Thu Chi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const AppShell(),
    );
  }
}
