import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/widgets/screen_header.dart';

/// Màn Báo cáo — khung; nội dung nghiệp vụ gắn sau (PBI module).
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(title: 'Báo cáo'.tr),
        const Expanded(child: SizedBox()),
      ],
    );
  }
}
