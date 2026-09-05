import 'package:flutter/material.dart';

/// Khung màn phụ dùng chung: app bar teal + nút back, không có bottom nav.
/// Dùng cho "Thêm giao dịch", form ví…; Cài đặt (sub-page) tái dùng sau.
/// [bottomNavigationBar] cho phép đặt thanh hành động cố định chân màn (SC-007);
/// [actions] đặt widget bên phải app bar (VD icon 3 chấm màn chi tiết — FR-001);
/// [floatingActionButton] cho phép màn phụ có FAB (VD "+" màn danh mục — PBI 13).
class SubPageScaffold extends StatelessWidget {
  const SubPageScaffold({
    super.key,
    required this.title,
    this.child,
    this.bottomNavigationBar,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget? child;
  final Widget? bottomNavigationBar;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: child ?? const SizedBox.expand(),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
