import 'package:flutter/material.dart';

/// Khung màn phụ dùng chung: app bar teal + nút back, không có bottom nav.
/// Dùng cho "Thêm giao dịch", form ví…; Cài đặt (sub-page) tái dùng sau.
/// [bottomNavigationBar] cho phép đặt thanh hành động cố định chân màn (SC-007);
/// [actions] đặt widget bên phải app bar (VD icon 3 chấm màn chi tiết — FR-001);
/// [floatingActionButton] cho phép màn phụ có FAB (VD "+" màn danh mục — PBI 13).
/// [subtitle] (PBI 21) là **tùy chọn**: có thì app bar cao 68 vẽ 2 dòng (tiêu
/// đề + dòng phụ), không thì giữ nguyên hành vi cũ.
/// [titleWidget] (PBI 44) ghi đè hẳn nội dung `AppBar.title` khi cần tiêu đề
/// tùy biến (VD chạm được) — vẫn qua chung app bar teal + back của khung này.
class SubPageScaffold extends StatelessWidget {
  const SubPageScaffold({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.child,
    this.bottomNavigationBar,
    this.actions,
    this.floatingActionButton,
  }) : assert(title != null || titleWidget != null);

  final String? title;
  final String? subtitle;
  final Widget? titleWidget;
  final Widget? child;
  final Widget? bottomNavigationBar;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: sub == null ? null : 68,
        title: titleWidget ??
            (sub == null
                ? Text(title!)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  )),
        actions: actions,
      ),
      body: child ?? const SizedBox.expand(),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
