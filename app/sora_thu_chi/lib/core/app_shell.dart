import 'package:flutter/material.dart';

import '../screens/add_transaction_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/report_screen.dart';
import '../screens/scan/add_transaction_sheet.dart';
import '../screens/settings_screen.dart';
import '../screens/transaction_screen.dart';
import '../data/report_deps.dart';
import '../data/transaction_deps.dart';
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

  /// `late final` (không còn `static const`): tab Báo cáo cần bơm
  /// [_onTabSelected] xuống màn Tổng quan Ngân sách đẩy từ nó (PBI 20) — màn
  /// con tự dựng bottom nav nhưng không giữ state của shell.
  late final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionScreen(),
    ReportScreen(onSelectTab: _onTabSelected),
    const SettingsScreen(),
  ];


  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
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
      MaterialPageRoute(builder: (_) => AddTransactionScreen(initialType: type)),
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
