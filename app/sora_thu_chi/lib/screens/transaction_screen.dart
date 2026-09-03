import 'package:flutter/material.dart';

import '../core/widgets/screen_header.dart';

/// Màn Giao dịch — khung; nội dung nghiệp vụ gắn sau (PBI module).
class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ScreenHeader(title: 'Giao dịch'),
        Expanded(child: SizedBox()),
      ],
    );
  }
}
