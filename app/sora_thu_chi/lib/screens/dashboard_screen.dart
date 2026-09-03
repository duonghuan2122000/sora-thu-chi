import 'package:flutter/material.dart';

import '../core/widgets/screen_header.dart';

/// Màn Tổng quan — khung; nội dung nghiệp vụ gắn sau (PBI module).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ScreenHeader(title: 'Tổng quan'),
        Expanded(child: SizedBox()),
      ],
    );
  }
}
