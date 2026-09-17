import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/add_transaction_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/report_screen.dart';
import '../screens/scan/add_transaction_sheet.dart';
import '../screens/settings_screen.dart';
import '../screens/transaction_screen.dart';
import '../data/notification_deps.dart';
import '../data/privacy_deps.dart';
import '../data/report_deps.dart';
import '../data/transaction_deps.dart';
import 'notification/notification_presence.dart';
import 'notification/notification_tap.dart';
import 'scan/scan_flow.dart';
import 'transaction/transaction.dart';
import 'widgets/add_transaction_fab.dart';
import 'widgets/app_bottom_nav_bar.dart';

/// Vỏ app: giữ 4 màn chính sống (IndexedStack) + bottom nav đổi tab.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Shell đã dựng ⇒ đã qua `PinGate`/mở khoá (FR-019): giờ mới tiêu thụ payload
    // chạm thông báo, nếu không màn đích sẽ nằm **dưới** màn khoá (AC#13).
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumePendingTap());
  }

  /// Tiêu thụ payload **một lần**: hoà giải + đánh dấu đã đọc rồi điều hướng.
  /// Chỉ `take()` sau khi xử lý xong — lỗi giữa chừng để lần mở sau thử lại.
  Future<void> _consumePendingTap() async {
    final router = ensureNotificationTapRouter();
    final entryKey = router.peek();
    if (entryKey == null) return;
    NotificationTapResult result;
    try {
      result = await ensureNotificationEngine().handleTap(entryKey);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    router.take();
    await openNotificationTarget(
      target: result.target,
      relatedId: result.relatedId,
      period: result.period,
      onSelectTab: _onTabSelected,
      context: context,
    );
  }

  /// `late final` (không còn `static const`): tab Báo cáo cần bơm
  /// [_onTabSelected] xuống màn Tổng quan Ngân sách đẩy từ nó (PBI 20) — màn
  /// con tự dựng bottom nav nhưng không giữ state của shell.
  late final List<Widget> _screens = [
    DashboardScreen(onSelectTab: _onTabSelected),
    const TransactionScreen(),
    ReportScreen(onSelectTab: _onTabSelected),
    const SettingsScreen(),
  ];


  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    // Tab Tổng quan cũng build sẵn offstage từ boot — nạp lại mỗi lần quay
    // lại để số dư/thẻ thu-chi/giao dịch gần đây phản ánh dữ liệu mới (FR-007).
    if (index == 0) {
      ensureTransactionController().load();
    } else {
      // Rời tab Tổng quan → tắt "xem tạm thời" Privacy mode (PBI 48 FR-005) —
      // IndexedStack giữ DashboardScreen sống nên không thể dựa vào initState.
      ensurePrivacyController().revealed.value = false;
    }
    // Màn Giao dịch đã build sẵn (IndexedStack) từ boot — nạp dữ liệu ngay lúc
    // chọn tab: lần đầu cũng là lần nạp đầu, mỗi lần quay lại tự làm mới
    // (FR-011). Fire-and-forget — không chặn đổi tab (R6).
    if (index == 1) {
      ensureTransactionController().load();
    }
    // Tab Báo cáo cũng build sẵn offstage từ boot — nạp lại mỗi lần mở để số
    // liệu phản ánh dữ liệu mới (FR-016/kịch bản 12).
    if (index == 2) {
      ensureReportController().load();
    }
    _syncReportPresence(index == 2);
  }

  /// Q3 (PBI 31, R9/FR-016): "đang mở màn Báo cáo" = **tab Báo cáo đang được
  /// chọn**. Không thể suy từ vòng đời widget: `IndexedStack` giữ **mọi** tab
  /// sống từ lúc boot nên `initState` của màn Báo cáo không phản ánh việc người
  /// dùng đang nhìn nó. Vào tab ⇒ huỷ mốc tổng kết đang chờ (không bắn, không
  /// ghi — AC#10/H3); rời tab ⇒ cuốn lịch lại, mốc đã trôi qua **không** ghi bù
  /// (H4/FR-028).
  void _syncReportPresence(bool onReport) {
    final presence = ensureNotificationPresence();
    final engine = ensureNotificationEngine();
    if (onReport) {
      presence.enterReport();
      unawaited(engine.onEnterRelatedScreen(NotificationScreens.report));
      return;
    }
    if (presence.screen.value == NotificationScreens.report) {
      presence.leave();
      unawaited(engine.onLeaveRelatedScreen());
    }
  }

  /// FAB → bottom sheet "Thêm giao dịch" (mockup `scan-01`, PBI 24 FR-001) rồi
  /// điều phối theo lựa chọn. Cờ "đã lưu" giữ nguyên khối làm mới sẵn có.
  Future<void> _openAddSheet(BuildContext context) async {
    final choice = await showAddTransactionSheet(context);
    if (choice == null || !context.mounted) return;

    bool? saved;
    switch (choice) {
      case AddSheetChoice.income:
        saved = await _pushAddForm(TxnType.income);
      case AddSheetChoice.expense:
        saved = await _pushAddForm(TxnType.expense);
      case AddSheetChoice.transfer:
        saved = await _pushAddForm(TxnType.transfer);
      case AddSheetChoice.scan:
        saved = await startScanFlow(context);
    }

    // Lưu thu/chi thành công, xong chuyển khoản, hoặc lưu giao dịch quét đều
    // pop/trả `true` → làm mới ngay danh sách + card "Thu/Chi tháng này"
    // (FR-013/SC-006, R10; PBI 24 SC-015).
    if (saved == true && mounted) {
      ensureTransactionController().load();
      // FAB hiện trên mọi tab: đứng ở tab Báo cáo mà ghi giao dịch thì số liệu
      // phải mới ngay trước mắt, không chờ lần chọn tab sau (R11/SC-008).
      if (_selectedIndex == 2) {
        ensureReportController().load();
      }
    }
  }

  Future<bool?> _pushAddForm(TxnType type) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => AddTransactionScreen(initialType: type)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: AddTransactionFab(
        onTap: () => _openAddSheet(context),
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _selectedIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
