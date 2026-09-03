import 'package:flutter/material.dart';

import '../core/widgets/sub_page_scaffold.dart';

/// Màn phụ "Thêm giao dịch" — khung; biểu mẫu thật của module Giao dịch thay sau.
class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubPageScaffold(
      title: 'Thêm giao dịch',
    );
  }
}
