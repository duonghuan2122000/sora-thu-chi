import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/money_format.dart';
import '../core/report/report_view.dart';
import '../core/transaction/transaction_filter.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/report_deps.dart';
import '../data/transaction_deps.dart';
import '../theme/sora_colors.dart';

/// Màn **Chi tiêu theo danh mục** (mockup `02`, PBI 23) — màn con đè shell:
/// app bar teal + nút back, **không** bottom nav. Mở từ liên kết "Xem tất cả" ở
/// thẻ Top màn Tổng quan (FR-001).
///
/// Không đọc DB: số liệu dựng lại mỗi lần build từ bản chụp RAM của
/// `ReportController` (research R1) ⇒ hai màn không thể lệch số (FR-015).
/// Kỳ hiển thị là kỳ **đang xem ở màn 01** — màn này không có trạng thái kỳ
/// riêng (FR-017).
class ReportCategoryDetailScreen extends StatelessWidget {
  const ReportCategoryDetailScreen({super.key, this.onSelectTab});

  /// Đổi tab ở shell sau khi drill-down (null = chỉ `popUntil`).
  final ValueChanged<int>? onSelectTab;

  /// Chạm một dòng danh mục (hoặc lát cắt) → màn **Giao dịch** đã lọc sẵn theo
  /// đúng danh mục đó (gồm danh mục con) trong đúng khoảng ngày của kỳ đang xem
  /// (FR-011/SC-006). Màn 02 là route đè shell nên phải `popUntil` trước khi
  /// đổi tab (khác màn 01 — research R5).
  void _drillDown(
    BuildContext context,
    DateTime now,
    ReportCategoryDetail detail,
    int categoryId,
  ) {
    ensureTransactionController().setFilter(
      TxnSearchFilter(
        now: now,
        type: TxnTypeFilter.expense,
        datePreset: DatePreset.custom,
        dateStart: detail.range.start,
        // Bộ lọc hiểu [dateEnd] là **hết ngày** → lùi 1 ngày từ mốc cuối nửa mở.
        dateEnd: detail.range.end.subtract(const Duration(days: 1)),
        categoryIds: {categoryId},
        sort: SortOption.dateNewest,
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
    onSelectTab?.call(1);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ensureReportController();
    final colors = SoraColors.of(context);
    return Obx(() {
      final detail = controller.categoryDetail();
      return SubPageScaffold(
        title: 'Chi tiêu theo danh mục'.tr,
        // Chỉ xảy ra ở test (màn chỉ mở được từ Tổng quan đã có dữ liệu).
        child: detail == null
            ? const SizedBox.shrink()
            : _body(context, controller.now, detail, colors),
      );
    });
  }

  Widget _body(
    BuildContext context,
    DateTime now,
    ReportCategoryDetail detail,
    SoraColors colors,
  ) {
    if (detail.total == 0) {
      return Center(
        key: const ValueKey('report-detail-empty'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            detail.hasAnyTxn
                ? 'Chưa có chi tiêu nào trong kỳ này'.tr
                : 'Chưa có giao dịch nào trong kỳ này'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _PeriodChip(detail: detail, colors: colors),
        const SizedBox(height: 16),
        _Donut(
          detail: detail,
          colors: colors,
          onSliceTap: (categoryId) =>
              _drillDown(context, now, detail, categoryId),
        ),
        const SizedBox(height: 20),
        Divider(color: colors.listDivider, height: 1),
        const SizedBox(height: 12),
        Text(
          'DANH MỤC (@n)'.trParams({'n': '${detail.rows.length}'}),
          style: TextStyle(
            color: colors.tabInactive,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < detail.rows.length; i++) ...[
          if (i > 0) Divider(color: colors.listDivider, height: 1),
          _CategoryRow(
            row: detail.rows[i],
            colors: colors,
            onTap: detail.rows[i].categoryId == null
                ? null
                : () => _drillDown(
                    context,
                    now,
                    detail,
                    detail.rows[i].categoryId!,
                  ),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'Chạm vào một danh mục để xem các giao dịch'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.tabInactive, fontSize: 12),
        ),
      ],
    );
  }
}

/// Chip kỳ — **nhãn tĩnh** kế thừa kỳ đang xem ở màn Tổng quan: không bấm được,
/// không mũi tên, không menu chọn kỳ (FR-003, khác biệt cố ý với mockup `02`).
class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.detail, required this.colors});

  final ReportCategoryDetail detail;
  final SoraColors colors;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const ValueKey('report-detail-chip'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: colors.softCardBg,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          reportPeriodChipLabel(detail.period, detail.range),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Vòng tròn phân bổ **toàn bộ** danh mục chi của kỳ (màu theo thứ hạng, lặp
/// chu kỳ 5 màu + xám cho "Khác") kèm nhãn giữa là tổng chi (FR-004/FR-007).
class _Donut extends StatelessWidget {
  const _Donut({
    required this.detail,
    required this.colors,
    required this.onSliceTap,
  });

  final ReportCategoryDetail detail;
  final SoraColors colors;

  /// Chạm một lát cắt = chạm dòng tương ứng (FR-011).
  final ValueChanged<int> onSliceTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              key: const ValueKey('report-detail-donut'),
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 52,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    final section = response?.touchedSection;
                    if (event is! FlTapUpEvent || section == null) return;
                    final index = section.touchedSectionIndex;
                    if (index < 0 || index >= detail.rows.length) return;
                    final categoryId = detail.rows[index].categoryId;
                    if (categoryId == null) return; // "Khác" không có đích
                    onSliceTap(categoryId);
                  },
                ),
                sections: [
                  for (final row in detail.rows)
                    PieChartSectionData(
                      value: row.amount.toDouble(),
                      color: rowColor(colors, row.rank),
                      radius: 30,
                      showTitle: false,
                    ),
                ],
              ),
            ),
            // fl_chart không vẽ chữ ở tâm ⇒ phủ `Stack` (Rủi ro 3 plan.md).
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reportExpenseCenterLabel(detail.period),
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: 96,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatMoney(detail.total),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Màu **định tính** theo thứ hạng: 5 màu lặp chu kỳ, "Khác" (`rank == -1`) là
/// màu xám thứ 6 (data-model luật 13) — không dùng coral, không dùng màu danh mục.
Color rowColor(SoraColors colors, int rank) =>
    colors.chartPalette[rank < 0 ? 5 : rank % 5];

/// Một dòng danh mục: chấm màu theo hạng, tên, số tiền, %, thanh tiến độ **cùng
/// màu chấm** (SC-007). Dòng "Khác" không chạm được (FR-012).
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.row, required this.colors, this.onTap});

  final ReportCategoryRow row;
  final SoraColors colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = rowColor(colors, row.rank);
    return InkWell(
      key: ValueKey('report-detail-row-${row.categoryId ?? 'other'}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatMoney(row.amount),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${row.percent}%',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: row.percent / 100,
                      minHeight: 4,
                      backgroundColor: colors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
