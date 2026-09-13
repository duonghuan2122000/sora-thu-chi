import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/date_range.dart';
import '../core/money_format.dart';
import '../core/report/report_view.dart';
import '../core/transaction/transaction_filter.dart';
import '../core/widgets/category_icon.dart';
import '../core/widgets/screen_header.dart';
import '../data/report_deps.dart';
import '../data/transaction_deps.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';
import 'budget_overview_screen.dart';
import 'report_category_detail_screen.dart';
import 'report_comparison_screen.dart';
import 'report_export_screen.dart';

/// Màn Tổng quan tab Báo cáo (mockup `01`, PBI 22): khu đầu màn teal
/// (tiêu đề + segmented control 4 kỳ + 2 số tổng) rồi các thẻ số liệu.
/// Màn sống trong `IndexedStack` của `AppShell` — việc nạp do shell gọi khi
/// chọn tab (FR-016), không nạp ở đây. [onSelectTab] do `AppShell` bơm xuống
/// cho drill-down sang tab Giao dịch và cho màn Ngân sách đẩy từ đây.
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key, this.onSelectTab});

  final ValueChanged<int>? onSelectTab;

  /// Chạm một danh mục ở thẻ phân bổ → mở tab Giao dịch với bộ lọc Chi + khoảng
  /// ngày của kỳ + danh mục cha (bộ lọc PBI 12 tự mở rộng cha → con — R7).
  /// Màn Báo cáo **là** tab nên chỉ đổi tab, không `popUntil`.
  void _drillDown(DateTime now, DateRange range, int categoryId) {
    ensureTransactionController().setFilter(
      TxnSearchFilter(
        now: now,
        type: TxnTypeFilter.expense,
        datePreset: DatePreset.custom,
        dateStart: range.start,
        dateEnd: range.end.subtract(const Duration(days: 1)),
        categoryIds: {categoryId},
        sort: SortOption.dateNewest,
      ),
    );
    onSelectTab?.call(1);
  }

  Future<void> _openBudget(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BudgetOverviewScreen(onSelectTab: onSelectTab),
      ),
    );
  }

  /// "Xem tất cả" ở thẻ Top → màn Chi tiết theo danh mục (màn `02`, FR-001).
  Future<void> _openCategoryDetail(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportCategoryDetailScreen(onSelectTab: onSelectTab),
      ),
    );
  }

  /// Biểu tượng xuất trên vùng tiêu đề → màn `04` Xuất báo cáo (FR-001). Nút
  /// này **luôn** bấm được (kể cả kỳ rỗng) — khác nút so sánh (FR-018).
  Future<void> _openExport(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ReportExportScreen()),
    );
  }

  /// Biểu tượng so sánh trên vùng tiêu đề (FR-001). Người dùng **chưa từng** có
  /// giao dịch Thu/Chi nào trước kỳ đang xem ⇒ không mở màn, chỉ giải thích
  /// (FR-017); màn 03 vì thế luôn có ít nhất một kỳ có dữ liệu.
  Future<void> _openComparison(BuildContext context) async {
    final controller = ensureReportController();
    final range =
        controller.data.value?.range ??
        reportPeriodRange(controller.period.value, controller.now);
    if (!controller.hasAnyTxnBefore(range.start)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Chưa có dữ liệu để so sánh'.tr)));
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ReportComparisonScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ensureReportController();
    final colors = SoraColors.of(context);
    return Obx(() {
      final view = controller.data.value;
      final error = controller.error.value;
      return Column(
        children: [
          ScreenHeader(
            title: 'Báo cáo'.tr,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CompareButton(
                  enabled: controller.hasAnyTxnBefore(
                    (view?.range ??
                            reportPeriodRange(
                              controller.period.value,
                              controller.now,
                            ))
                        .start,
                  ),
                  onTap: () => _openComparison(context),
                ),
                _ExportButton(onTap: () => _openExport(context)),
              ],
            ),
            bottom: _HeaderSummary(
              period: controller.period.value,
              onPeriodChanged: controller.setPeriod,
              income: view?.income ?? 0,
              expense: view?.expense ?? 0,
            ),
          ),
          Expanded(
            child: error != null
                ? _ErrorView(message: error, onRetry: controller.load)
                : view != null
                ? ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 96),
                    children: [
                      _EntryRow(
                        icon: Icons.savings_outlined,
                        title: 'Ngân sách'.tr,
                        subtitle: 'Giới hạn chi tiêu theo danh mục'.tr,
                        colors: colors,
                        onTap: () => _openBudget(context),
                      ),
                      _FlowChartCard(view: view, colors: colors),
                      _BreakdownCard(
                        view: view,
                        colors: colors,
                        onCategoryTap: (categoryId) =>
                            _drillDown(controller.now, view.range, categoryId),
                      ),
                      _TopCategoriesCard(
                        view: view,
                        colors: colors,
                        onSeeAll: () => _openCategoryDetail(context),
                      ),
                    ],
                  )
                // Màn build sẵn offstage từ boot: chỉ quay spinner khi thật sự
                // đang nạp, tránh vòng lặp animation vô hạn ngoài màn hình.
                : controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(),
          ),
        ],
      );
    });
  }
}

/// Nút tròn 48 px trên vùng tiêu đề mở màn So sánh kỳ (FR-001). Mờ đi khi lối
/// vào bị vô hiệu hoá (FR-017) — vẫn bấm được để hiện giải thích.
class _CompareButton extends StatelessWidget {
  const _CompareButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Tooltip(
      message: 'So sánh'.tr,
      child: InkWell(
        key: const ValueKey('report-compare-entry'),
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            Icons.compare_arrows,
            size: 24,
            color: enabled ? AppColors.white : colors.tealLightText,
          ),
        ),
      ),
    );
  }
}

/// Nút tròn 48 px trên vùng tiêu đề mở màn Xuất báo cáo (màn `04`, FR-001).
/// **Luôn** bấm được — kỳ rỗng vẫn xuất được tệp (danh sách rỗng ⇒ nút xuất
/// trong màn 04 tự vô hiệu hoá), khác nút so sánh.
class _ExportButton extends StatelessWidget {
  const _ExportButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Xuất'.tr,
      child: InkWell(
        key: const ValueKey('report-export-entry'),
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.ios_share, size: 22, color: AppColors.white),
        ),
      ),
    );
  }
}

/// Vùng teal dưới tiêu đề: segmented control 4 kỳ + 2 số tổng thu/chi của kỳ
/// đang chọn (đã loại transfer/adjustment — FR-004). Không có nút lịch (FR-002).
class _HeaderSummary extends StatelessWidget {
  const _HeaderSummary({
    required this.period,
    required this.onPeriodChanged,
    required this.income,
    required this.expense,
  });

  final ReportPeriod period;
  final ValueChanged<ReportPeriod> onPeriodChanged;
  final int income;
  final int expense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PeriodSelector(selected: period, onChanged: onPeriodChanged),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _HeaderTotal(
                label: 'Tổng thu'.tr,
                amount: income,
                icon: Icons.arrow_upward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HeaderTotal(
                label: 'Tổng chi'.tr,
                amount: expense,
                icon: Icons.arrow_downward,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Segmented control 4 kỳ trên nền teal — lựa chọn đang chọn là pill trắng.
class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final period in ReportPeriod.values)
            Expanded(
              child: GestureDetector(
                key: ValueKey('report-period-${period.name}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(period),
                child: Container(
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: period == selected ? AppColors.white : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    period.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: period == selected
                          ? AppColors.teal
                          : AppColors.white,
                      fontSize: 12,
                      fontWeight: period == selected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Một số tổng trên nền teal: nhãn + mũi tên, số tiền chữ trắng thu nhỏ khi dài.
class _HeaderTotal extends StatelessWidget {
  const _HeaderTotal({
    required this.label,
    required this.amount,
    required this.icon,
  });

  final String label;
  final int amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: SoraColors.light.tealLightText),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFCDE9DF), fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatMoney(amount),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Thẻ "Phân bổ chi tiêu theo danh mục" — vòng tròn (top 5 danh mục cha +
/// nhóm "Khác") kèm nhãn **"Tổng chi"** giữa vòng tròn và danh sách chú giải
/// (chấm màu, tên, %) sắp giảm dần; chạm một danh mục → mở tab Giao dịch đã lọc
/// (FR-008/FR-009/FR-011/FR-012). Nhóm "Khác" không có đích nên không chạm được.
class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.view,
    required this.colors,
    required this.onCategoryTap,
  });

  final ReportView view;
  final SoraColors colors;
  final ValueChanged<int> onCategoryTap;

  Color _sliceColor(ReportSlice slice) =>
      colors.chartPalette[slice.rank < 0 ? 5 : slice.rank];

  void _openSlice(int index) {
    if (index < 0 || index >= view.slices.length) return;
    final categoryId = view.slices[index].categoryId;
    if (categoryId == null) return;
    onCategoryTap(categoryId);
  }

  @override
  Widget build(BuildContext context) {
    // Kỳ chỉ có Thu → thẻ chi tiêu rỗng (biểu đồ vẫn vẽ đủ 6 đơn vị — FR-015).
    if (!view.hasExpense) {
      return _EmptyCard(
        message: view.hasAnyTxn
            ? 'Chưa có chi tiêu nào trong kỳ này'.tr
            : 'Chưa có giao dịch nào trong kỳ này'.tr,
      );
    }
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân bổ chi tiêu theo danh mục'.tr,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 132,
                height: 132,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      key: const ValueKey('report-donut'),
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 34,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            final section = response?.touchedSection;
                            if (event is FlTapUpEvent && section != null) {
                              _openSlice(section.touchedSectionIndex);
                            }
                          },
                        ),
                        sections: [
                          for (final slice in view.slices)
                            PieChartSectionData(
                              value: slice.amount.toDouble(),
                              color: _sliceColor(slice),
                              radius: 26,
                              showTitle: false,
                            ),
                        ],
                      ),
                    ),
                    // fl_chart không vẽ chữ ở tâm vòng tròn ⇒ phủ `Stack` (Rủi ro 2).
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tổng chi'.tr,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatMoney(view.expense),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final slice in view.slices)
                      KeyedSubtree(
                        key: ValueKey(
                          'report-slice-${slice.categoryId ?? 'other'}',
                        ),
                        child: InkWell(
                          key: ValueKey(
                            'report-legend-${slice.categoryId ?? 'other'}',
                          ),
                          onTap: slice.categoryId == null
                              ? null
                              : () => onCategoryTap(slice.categoryId!),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _sliceColor(slice),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    slice.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${slice.percent}%',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Thẻ "Top danh mục chi tiêu" — tối đa **5** danh mục chi nhiều nhất trong kỳ,
/// mỗi dòng có bubble icon danh mục, tên, số tiền và thanh tiến độ theo tỉ lệ
/// trên tổng chi; **không** có dòng "Khác" (FR-013).
class _TopCategoriesCard extends StatelessWidget {
  const _TopCategoriesCard({
    required this.view,
    required this.colors,
    required this.onSeeAll,
  });

  final ReportView view;
  final SoraColors colors;

  /// Mở màn 02 (Chi tiết theo danh mục) — chỉ hiện khi thẻ có nội dung (R6).
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (!view.hasExpense) {
      return _EmptyCard(
        message: view.hasAnyTxn
            ? 'Chưa có chi tiêu nào trong kỳ này'.tr
            : 'Chưa có giao dịch nào trong kỳ này'.tr,
      );
    }
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Top danh mục chi tiêu'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              InkWell(
                key: const ValueKey('report-see-all'),
                onTap: onSeeAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Text(
                    'Xem tất cả'.tr,
                    style: TextStyle(
                      color: colors.tealOnNeutral,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in view.top)
            Padding(
              key: ValueKey('report-top-${item.categoryId}'),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color(item.color),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      categoryIcon(item.icon),
                      size: 16,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (item.percent / 100).clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor: colors.divider,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.tealOnNeutral,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    formatMoney(item.amount),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Thẻ rỗng — thay nội dung biểu đồ/thẻ số liệu khi kỳ không có dữ liệu, để
/// không hiện biểu đồ trống gây hiểu lầm là lỗi (FR-014/FR-015).
class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return _Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          message,
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
      ),
    );
  }
}

/// Khung thẻ nội dung dùng chung 3 thẻ số liệu (bo góc 10px, nền beige).
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SoraColors.of(context).softCardBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: child,
      ),
    );
  }
}

/// Thẻ "Dòng tiền 6 <đơn vị> gần đây" — biểu đồ cột ghép đôi Thu (teal) /
/// Chi (coral) cho 6 đơn vị liên tiếp kết thúc ở kỳ đang chọn (FR-005/FR-006);
/// chạm một cột → tooltip số tiền chính xác, không điều hướng (FR-007).
class _FlowChartCard extends StatelessWidget {
  const _FlowChartCard({required this.view, required this.colors});

  final ReportView view;
  final SoraColors colors;

  String get _title => switch (view.period) {
    ReportPeriod.day => 'Dòng tiền 6 ngày gần đây'.tr,
    ReportPeriod.week => 'Dòng tiền 6 tuần gần đây'.tr,
    ReportPeriod.month => 'Dòng tiền 6 tháng gần đây'.tr,
    ReportPeriod.year => 'Dòng tiền 6 năm gần đây'.tr,
  };

  @override
  Widget build(BuildContext context) {
    // Kỳ không có Thu/Chi nào (transfer không tính) → cả 3 thẻ rỗng (FR-014).
    if (!view.hasAnyTxn) {
      return _EmptyCard(message: 'Chưa có giao dịch nào trong kỳ này'.tr);
    }
    var maxValue = 0;
    for (final bar in view.bars) {
      if (bar.income > maxValue) maxValue = bar.income;
      if (bar.expense > maxValue) maxValue = bar.expense;
    }
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _LegendDot(label: 'Thu'.tr, color: colors.tealOnNeutral),
              const SizedBox(width: 16),
              _LegendDot(label: 'Chi'.tr, color: colors.coralOnNeutral),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.6,
            child: BarChart(
              key: const ValueKey('report-flow-chart'),
              BarChartData(
                minY: 0,
                maxY: maxValue <= 0 ? 1 : maxValue * 1.15,
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: _barTitle,
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                          formatMoney(rod.toY.round()),
                          const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < view.bars.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 3,
                      barRods: [
                        BarChartRodData(
                          toY: view.bars[i].income.toDouble(),
                          color: colors.tealOnNeutral,
                          width: 7,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        BarChartRodData(
                          toY: view.bars[i].expense.toDouble(),
                          color: colors.coralOnNeutral,
                          width: 7,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Nhãn đơn vị dưới trục — kỳ **đang chọn** (phần tử cuối) đậm hơn (FR-006).
  Widget _barTitle(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= view.bars.length) return const SizedBox.shrink();
    final bar = view.bars[index];
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        bar.label,
        style: TextStyle(
          color: bar.isCurrent ? colors.textPrimary : colors.tabInactive,
          fontSize: 10,
          fontWeight: bar.isCurrent ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

/// Chấm màu + nhãn chú giải biểu đồ.
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: SoraColors.of(context).textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Nhánh lỗi đọc dữ liệu — thông báo + nút thử lại (FR-016).
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: Text('Thử lại'.tr)),
          ],
        ),
      ),
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
