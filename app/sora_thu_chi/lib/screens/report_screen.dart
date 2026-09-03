import 'package:flutter/material.dart';

import '../core/widgets/screen_header.dart';

/// Màn Báo cáo — khung; nội dung nghiệp vụ gắn sau (PBI module).
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ScreenHeader(title: 'Báo cáo'),
        Expanded(child: SizedBox()),
      ],
    );
  }
}
