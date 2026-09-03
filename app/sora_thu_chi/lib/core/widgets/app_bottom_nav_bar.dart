import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Thanh điều hướng đáy 5 vị trí: Tổng quan | Giao dịch | (ô trống) | Báo cáo | Cài đặt.
/// Ô giữa trống dành FAB của Scaffold. Widget thuần — nhận trạng thái, không tự quản.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  /// Chỉ số màn chính đang chọn (0..3) — ô giữa FAB không nằm trong chỉ số này.
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 56,
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            _item(context, index: 0, label: 'Tổng quan', icon: Icons.home_outlined),
            _item(context, index: 1, label: 'Giao dịch', icon: Icons.list_alt_outlined),
            const Expanded(child: SizedBox()),
            _item(context, index: 2, label: 'Báo cáo', icon: Icons.pie_chart_outline),
            _item(context, index: 3, label: 'Cài đặt', icon: Icons.settings_outlined),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required int index,
    required String label,
    required IconData icon,
  }) {
    final selected = index == selectedIndex;
    final color = selected ? AppColors.teal : AppColors.tabInactive;
    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 2),
            SizedBox(
              height: 15,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
