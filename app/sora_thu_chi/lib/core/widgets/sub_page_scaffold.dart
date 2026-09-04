import 'package:flutter/material.dart';

/// Khung màn phụ dùng chung: app bar teal + nút back, không có bottom nav.
/// Dùng cho "Thêm giao dịch", form ví…; Cài đặt (sub-page) tái dùng sau.
/// [bottomNavigationBar] cho phép đặt thanh hành động cố định chân màn (SC-007).
class SubPageScaffold extends StatelessWidget {
  const SubPageScaffold({
    super.key,
    required this.title,
    this.child,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget? child;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: child ?? const SizedBox.expand(),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
