import 'package:flutter/material.dart';

import '../core/widgets/screen_header.dart';

/// Màn Cài đặt — khung; nội dung nghiệp vụ gắn sau (PBI module).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ScreenHeader(title: 'Cài đặt'),
        Expanded(child: SizedBox()),
      ],
    );
  }
}
