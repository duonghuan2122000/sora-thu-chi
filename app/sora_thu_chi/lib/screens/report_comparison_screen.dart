import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/date_range.dart';
import '../core/money_format.dart';
import '../core/report/report_view.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/report_deps.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';

/// Màn **So sánh kỳ** (mockup `03`, PBI 26) — màn con đè shell: app bar teal +
/// nút back, **không** bottom nav, **không** FAB. Mở từ biểu tượng so sánh trên
/// vùng tiêu đề màn Tổng quan (FR-001).
///
/// Không đọc DB: số liệu dựng lại mỗi lần build từ bản chụp RAM của
/// `ReportController` (research R1) ⇒ ba màn Báo cáo không thể lệch số. Cặp kỳ
/// là **state cục bộ** sống trong phiên mở màn (R2) — đóng màn là mất.
class ReportComparisonScreen extends StatefulWidget {
  const ReportComparisonScreen({super.key});

  @override
  State<ReportComparisonScreen> createState() => _ReportComparisonScreenState();
}

class _ReportComparisonScreenState extends State<ReportComparisonScreen> {
  /// Mốc kỳ **chính** (bên trái) — kế thừa kỳ đang xem của màn Tổng quan.
  late DateTime _left;

  /// Mốc kỳ **đối chiếu** (bên phải).
  late DateTime _right;

  /// Chế độ chọn kỳ đối chiếu — nút hoán đổi **không** đổi giá trị này (FR-006);
  /// chạm chip kỳ đối chiếu thì đảo (FR-005).
  CompareMode _mode = CompareMode.previous;

  @override
  void initState() {
    super.initState();
    final controller = ensureReportController();
    _left = controller.now;
    _right = _rightFor(_mode);
  }

  /// Kỳ đối chiếu suy từ **kỳ chính đang ở bên trái** + chế độ đang chọn.
  DateTime _rightFor(CompareMode mode) {
    final period = ensureReportController().period.value;
    return reportRefRange(period, reportPeriodRange(period, _left), mode).start;
  }

  void _swap() {
    setState(() {
      final previous = _left;
      _left = _right;
      _right = previous;
    });
  }

  /// Chạm chip kỳ đối chiếu: kỳ liền trước ⇄ cùng kỳ năm trước (FR-005).
  void _toggleRefMode() {
    setState(() {
      _mode = _mode == CompareMode.previous
          ? CompareMode.lastYear
          : CompareMode.previous;
      _right = _rightFor(_mode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ensureReportController();
    final colors = SoraColors.of(context);
    return Obx(() {
      final period = controller.period.value;
      final comparison = controller.comparison(
        leftAnchor: _left,
        rightAnchor: _right,
      );
      return SubPageScaffold(
        title: 'So sánh kỳ'.tr,
        child: comparison == null
            // Chỉ xảy ra ở test (màn chỉ mở được từ Tổng quan đã có dữ liệu).
            ? const SizedBox.shrink()
            : _body(period, comparison, colors),
      );
    });
  }

  Widget _body(
    ReportPeriod period,
    ReportComparison comparison,
    SoraColors colors,
  ) {
    final chips = _PeriodChips(
      period: period,
      left: comparison.left.range,
      right: comparison.right.range,
      colors: colors,
      onSwap: _swap,
      onRefTap: _toggleRefMode,
    );
    // Cả hai kỳ rỗng ⇒ chỉ giữ cặp chip (để còn đường đổi chế độ đối chiếu).
    if (comparison.isEmpty) {
      return ListView(
        key: const ValueKey('report-comparison-screen'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          chips,
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Chưa có giao dịch nào trong hai kỳ này'.tr,
              key: const ValueKey('report-compare-empty'),
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      );
    }
    return ListView(
      key: const ValueKey('report-comparison-screen'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        chips,
        const SizedBox(height: 16),
        _CompareStatCard(
          title: 'Thu nhập'.tr,
          badgeKey: 'income',
          period: period,
          left: comparison.left,
          right: comparison.right,
          delta: comparison.incomeDelta,
          barColor: colors.tealOnNeutral,
          colors: colors,
          valueOf: (side) => side.income,
        ),
        const SizedBox(height: 12),
        _CompareStatCard(
          title: 'Chi tiêu'.tr,
          badgeKey: 'expense',
          period: period,
          left: comparison.left,
          right: comparison.right,
          delta: comparison.expenseDelta,
          barColor: colors.coralOnNeutral,
          colors: colors,
          valueOf: (side) => side.expense,
        ),
        const SizedBox(height: 12),
        _TrendCard(period: period, comparison: comparison, colors: colors),
        const SizedBox(height: 12),
        _InsightCard(insight: comparison.insight, colors: colors),
      ],
    );
  }
}

/// Cặp chip kỳ + nút hoán đổi ở giữa (FR-003/FR-004/FR-006). Chip **trái** =
/// kỳ chính, nền thương hiệu chữ trắng, **nhãn tĩnh** — không bấm được; chip
/// **phải** = kỳ đối chiếu, **bấm được** để đổi chế độ (FR-005, khác biệt cố ý
/// so với mockup `03` nên có thêm mũi tên chỉ báo).
class _PeriodChips extends StatelessWidget {
  const _PeriodChips({
    required this.period,
    required this.left,
    required this.right,
    required this.colors,
    required this.onSwap,
    required this.onRefTap,
  });

  final ReportPeriod period;
  final DateRange left;
  final DateRange right;
  final SoraColors colors;
  final VoidCallback onSwap;
  final VoidCallback onRefTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Chip(
            key: const ValueKey('report-compare-chip-left'),
            label: reportPeriodChipLabel(period, left),
            background: AppColors.teal,
            foreground: AppColors.white,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          key: const ValueKey('report-compare-swap'),
          customBorder: const CircleBorder(),
          onTap: onSwap,
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(Icons.swap_horiz, size: 20, color: colors.tabInactive),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            key: const ValueKey('report-compare-chip-right'),
            borderRadius: BorderRadius.circular(15),
            onTap: onRefTap,
            child: _Chip(
              label: reportPeriodChipLabel(period, right),
              background: colors.softCardBg,
              foreground: colors.listLabel,
              weight: FontWeight.w500,
              trailing: Icon(
                Icons.expand_more,
                size: 14,
                color: colors.tabInactive,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Chip nhãn kỳ — chữ co lại bằng `FittedBox` để không cắt ở cỡ chữ lớn (FR-023).
class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    required this.weight,
    this.trailing,
  });

  final String label;
  final Color background;
  final Color foreground;
  final FontWeight weight;

  /// Chỉ báo thị giác "bấm được" của chip kỳ đối chiếu (FR-005).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: weight,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 4), trailing!],
          ],
        ),
      ),
    );
  }
}

/// Thẻ so sánh một chỉ số (Thu nhập / Chi tiêu) — FR-007/FR-008: badge % chênh
/// lệch + cặp cột tỉ lệ + hai dòng số tiền.
class _CompareStatCard extends StatelessWidget {
  const _CompareStatCard({
    required this.title,
    required this.badgeKey,
    required this.period,
    required this.left,
    required this.right,
    required this.delta,
    required this.barColor,
    required this.colors,
    required this.valueOf,
  });

  final String title;

  /// `income` | `expense` — hậu tố `ValueKey` của badge.
  final String badgeKey;
  final ReportPeriod period;
  final CompareSide left;
  final CompareSide right;
  final CompareDelta delta;
  final Color barColor;
  final SoraColors colors;
  final int Function(CompareSide side) valueOf;

  @override
  Widget build(BuildContext context) {
    final leftValue = valueOf(left);
    final rightValue = valueOf(right);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.softCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _badge(),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _Side(
                  period: period,
                  range: left.range,
                  value: leftValue,
                  barHeight: _barHeight(leftValue, rightValue),
                  barColor: barColor,
                  colors: colors,
                  emphasized: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Side(
                  period: period,
                  range: right.range,
                  value: rightValue,
                  barHeight: _barHeight(rightValue, leftValue),
                  barColor: colors.dotEmpty.withValues(alpha: 0.5),
                  colors: colors,
                  emphasized: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Chiều cao cột theo **tỉ lệ thật**: cột lớn hơn chiếm trọn 64 (R13);
  /// cả hai 0 ⇒ không vẽ cột.
  double _barHeight(int value, int other) {
    final max = value > other ? value : other;
    if (max <= 0) return 0;
    return 64 * value / max;
  }

  /// Badge `%` tô màu theo **ý nghĩa** (FR-010); `ref == 0` ⇒ ghi chú thay badge
  /// (FR-011); `0%` ⇒ không mũi tên, không tô màu.
  Widget _badge() {
    final percent = delta.percent;
    if (percent == null) {
      return Flexible(
        child: Text(
          'Kỳ đối chiếu không có dữ liệu để so sánh'.tr,
          key: ValueKey('report-compare-badge-$badgeKey'),
          textAlign: TextAlign.right,
          style: TextStyle(color: colors.textSecondary, fontSize: 11),
        ),
      );
    }
    final isGood = delta.isGood;
    final color = switch (isGood) {
      true => colors.tealOnNeutral,
      false => colors.coralOnNeutral,
      null => colors.textSecondary,
    };
    final arrow = switch (delta.direction) {
      1 => '▲ ',
      -1 => '▼ ',
      _ => '',
    };
    return Text(
      '$arrow${percent.abs()}%',
      key: ValueKey('report-compare-badge-$badgeKey'),
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
    );
  }
}

/// Một vế của thẻ số liệu: cột tỉ lệ + nhãn kỳ + số tiền (dòng kỳ chính đậm hơn).
class _Side extends StatelessWidget {
  const _Side({
    required this.period,
    required this.range,
    required this.value,
    required this.barHeight,
    required this.barColor,
    required this.colors,
    required this.emphasized,
  });

  final ReportPeriod period;
  final DateRange range;
  final int value;
  final double barHeight;
  final Color barColor;
  final SoraColors colors;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 64,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Container(width: 36, height: barHeight, color: barColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          reportBarLabel(period, range.start),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: colors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatMoney(value),
            maxLines: 1,
            style: TextStyle(
              color: emphasized ? colors.textPrimary : colors.textSecondary,
              fontSize: 12,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Thẻ **Xu hướng chi tiêu theo ngày** (FR-012) — hai đường: kỳ **trái** nét
/// liền teal, kỳ **phải** nét đứt xám; trục hoành là **ngày trong kỳ**
/// (`1 … dayCount`), mỗi điểm là tổng chi **của riêng ngày đó** (không luỹ kế)
/// nên kỳ ngắn hơn **tự dừng** ở ngày cuối kỳ đó.
class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.period,
    required this.comparison,
    required this.colors,
  });

  final ReportPeriod period;
  final ReportComparison comparison;
  final SoraColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.softCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xu hướng chi tiêu theo ngày'.tr,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          // Cả hai vế không có chi tiêu ⇒ ghi chú thay hai đường phẳng 0.
          if (!comparison.hasExpense)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Chưa có chi tiêu nào trong kỳ này'.tr,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            )
          else ...[
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _LegendDot(
                  label: reportPeriodChipLabel(period, comparison.left.range),
                  color: colors.tealOnNeutral,
                  colors: colors,
                ),
                _LegendDot(
                  label: reportPeriodChipLabel(period, comparison.right.range),
                  color: colors.tabInactive,
                  colors: colors,
                ),
              ],
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.6,
              child: LineChart(
                key: const ValueKey('report-compare-trend'),
                _chartData(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  LineChartData _chartData() {
    final dayCount = comparison.dayCount;
    final middle = ((1 + dayCount) / 2).round();
    // Nhãn chỉ ở 3 mốc (đầu / giữa / cuối) — bám mockup `03`.
    Widget bottomTitle(double value, TitleMeta meta) {
      final day = value.round();
      if (day != 1 && day != middle && day != dayCount) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '$day',
          style: TextStyle(color: colors.tabInactive, fontSize: 10),
        ),
      );
    }

    List<FlSpot> spots(List<int> daily) => [
      for (var i = 0; i < daily.length; i++)
        FlSpot((i + 1).toDouble(), daily[i].toDouble()),
    ];

    return LineChartData(
      minX: 1,
      maxX: dayCount > 1 ? dayCount.toDouble() : 2,
      minY: 0,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(
        show: true,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      lineTouchData: const LineTouchData(enabled: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        leftTitles: const AxisTitles(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 22,
            getTitlesWidget: bottomTitle,
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots(comparison.left.dailyExpense),
          color: colors.tealOnNeutral,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: spots(comparison.right.dailyExpense),
          color: colors.tabInactive,
          barWidth: 2,
          dashArray: const [4, 3],
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }
}

/// Thẻ **Nhận xét** (FR-013) — nền cam rất nhạt + icon cảnh báo coral; câu đã
/// dựng sẵn ở tầng thuần (`ReportComparison.insight`) ⇒ widget **không** tính lại.
class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight, required this.colors});

  final String insight;
  final SoraColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('report-compare-insight'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.coralLightBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, size: 18, color: colors.coralOnNeutral),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Nhận xét'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chấm màu + nhãn chú giải hai đường của thẻ xu hướng.
class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.label,
    required this.color,
    required this.colors,
  });

  final String label;
  final Color color;
  final SoraColors colors;

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
          style: TextStyle(color: colors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}
