import 'package:flutter/material.dart';

import '../screens/add_transaction_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/report_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/transaction_screen.dart';
import '../data/transaction_deps.dart';
import '../theme/app_colors.dart';
import 'widgets/app_bottom_nav_bar.dart';

/// Vỏ app: giữ 4 màn chính sống (IndexedStack) + bottom nav đổi tab.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    TransactionScreen(),
    ReportScreen(),
    SettingsScreen(),
  ];

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    // Màn Giao dịch đã build sẵn (IndexedStack) từ boot — nạp dữ liệu ngay lúc
    // chọn tab: lần đầu cũng là lần nạp đầu, mỗi lần quay lại tự làm mới
    // (FR-011). Fire-and-forget — không chặn đổi tab (R6).
    if (index == 1) {
      ensureTransactionController().load();
    }
  }

  Future<void> _openAddTransaction(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    // Lưu thu/chi thành công hoặc xong chuyển khoản (qua tab) đều pop `true` →
    // làm mới ngay danh sách + card "Thu/Chi tháng này" (FR-013/SC-006, R10).
    if (saved == true && mounted) {
      ensureTransactionController().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Material(
        color: AppColors.teal,
        shape: const CircleBorder(),
        elevation: 6,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _openAddTransaction(context),
          child: const SizedBox(
            width: 52,
            height: 52,
            child: Icon(Icons.add, color: AppColors.white, size: 28),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _selectedIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
