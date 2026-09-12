import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/widgets/screen_header.dart';
import '../theme/sora_colors.dart';
import 'budget_overview_screen.dart';

/// Màn Báo cáo — khung tab; điểm vào **"Ngân sách"** đẩy màn Tổng quan Ngân
/// sách (FR-001, PBI 20). [onSelectTab] do `AppShell` bơm xuống để bottom nav
/// của màn Ngân sách đổi tab thật (research R1).
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key, this.onSelectTab});

  final ValueChanged<int>? onSelectTab;

  Future<void> _openBudget(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BudgetOverviewScreen(onSelectTab: onSelectTab),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Column(
      children: [
        ScreenHeader(title: 'Báo cáo'.tr),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 8),
            children: [
              _EntryRow(
                icon: Icons.savings_outlined,
                title: 'Ngân sách'.tr,
                subtitle: 'Giới hạn chi tiêu theo danh mục'.tr,
                colors: colors,
                onTap: () => _openBudget(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Hàng điểm vào module con của tab Báo cáo (icon bubble + tên + dòng phụ +
/// mũi tên) — bám nếp hàng điều hướng trong Cài đặt.
class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final SoraColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('report-entry-budget'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.tealLightBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: colors.tealOnNeutral),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.tabInactive, size: 20),
          ],
        ),
      ),
    );
  }
}
