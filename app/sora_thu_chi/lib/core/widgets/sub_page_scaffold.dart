import 'package:flutter/material.dart';

/// Khung màn phụ dùng chung: app bar teal + nút back, không có bottom nav.
/// Dùng cho "Thêm giao dịch" đợt này; Cài đặt (sub-page) tái dùng sau.
class SubPageScaffold extends StatelessWidget {
  const SubPageScaffold({super.key, required this.title, this.child});

  final String title;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: child ?? const SizedBox.expand(),
    );
  }
}
