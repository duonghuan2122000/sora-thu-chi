import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/budget/budget.dart';
import '../core/budget/budget_detail.dart';
import '../core/budget/budget_view.dart';
import '../core/category/category.dart';
import '../core/date_label.dart';
import '../core/money_format.dart';
import '../core/transaction/transaction.dart';
import '../core/transaction/transaction_filter.dart';
import '../core/widgets/category_icon.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/transaction_deps.dart';
import '../data/wallet_deps.dart';
import '../data/wallet_repository.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';
import 'budget_form_screen.dart';

/// Số giao dịch gần nhất liệt kê ở nhóm "Giao dịch trong kỳ" (FR-012).
const int _previewRows = 5;

/// Màn **Chi tiết Ngân sách** (mockup `03`, PBI 21) — màn con đè shell: app bar
/// teal 2 dòng (tên danh mục + "chu kỳ • kỳ đang xem"), không bottom nav.
///
/// Nạp một lần trong `initState` (`budgets()` + `allTransactions()` +
/// `categoriesIncludingHidden(expense)`); [now] bơm được để test deterministic.
/// Mọi số liệu tính lại mỗi lần nạp qua module thuần [buildBudgetDetail].
class BudgetDetailScreen extends StatefulWidget {
  const BudgetDetailScreen({
    super.key,
    required this.budgetId,
    this.repository,
    this.now,
    this.onSelectTab,
  });

  /// Ngân sách cần xem — màn Tổng quan truyền id dòng vừa chạm.
  final int budgetId;

  /// Seam test: mặc định null → [ensureWalletRepository] khi vào.
  final WalletRepository? repository;

  /// Mốc "hôm nay" — test bơm cố định, chạy thật lấy giờ hệ thống.
  final DateTime? now;

  /// "Xem tất cả" → đổi tab Giao dịch ở shell (null = chỉ `popUntil`).
  final ValueChanged<int>? onSelectTab;

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  late final WalletRepository _repository;
  late final DateTime _now;

  bool _loading = true;
  String? _error;

  List<Budget> _budgets = const [];
  List<Transaction> _transactions = const [];
  List<Category> _categories = const [];

  /// Kỳ người dùng đã chọn ở bộ chọn kỳ; null = kỳ mặc định của ngân sách.
  DateRange? _viewedRange;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ensureWalletRepository();
    _now = widget.now ?? DateTime.now();
    _load();
  }

  Budget? get _budget {
    for (final b in _budgets) {
      if (b.id == widget.budgetId) return b;
    }
    return null;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.budgets(),
        _repository.allTransactions(),
        _repository.categoriesIncludingHidden(type: CategoryType.expense),
      ]);
      if (!mounted) return;
      setState(() {
        _budgets = results[0] as List<Budget>;
        _transactions = results[1] as List<Transaction>;
        _categories = results[2] as List<Category>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không đọc được ngân sách.'.tr;
        _loading = false;
      });
    }
  }

  /// "Xem tất cả" — đặt bộ lọc Chi + khoảng kỳ đang xem + phạm vi danh mục
  /// (gồm con) lên màn Giao dịch rồi về shell đổi tab (FR-014, research R10).
  void _seeAll(BudgetDetail detail) {
    final filter = TxnSearchFilter(
      now: _now,
      type: TxnTypeFilter.expense,
      datePreset: DatePreset.custom,
      dateStart: detail.range.start,
      // Bộ lọc hiểu [dateEnd] là **hết ngày** → lùi 1 ngày từ mốc cuối nửa mở.
      dateEnd: detail.range.end.subtract(const Duration(days: 1)),
      categoryIds: budgetScopeCategoryIds(
        detail.budget.categoryId,
        _categories,
      ),
      sort: SortOption.dateNewest,
    );
    ensureTransactionController().setFilter(filter);
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onSelectTab?.call(1);
  }

  /// "Chỉnh sửa" (FR-015/FR-024) — mở form Sửa điền sẵn; lưu xong nạp lại và
  /// **giữ kỳ đang xem** (khớp theo `range.start`; đổi chu kỳ làm kỳ đó không
  /// còn tồn tại → về kỳ mặc định mới — Rủi ro 4).
  Future<void> _edit(Budget budget) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BudgetFormScreen(
          budget: budget,
          repository: _repository,
          now: _now,
        ),
      ),
    );
    if (!mounted || saved != true) return;
    final current = _viewedRange;
    await _load();
    if (!mounted || current == null) return;
    final updated = _budget;
    if (updated == null) return;
    DateRange? match;
    for (final option in budgetPeriodOptions(updated, _now)) {
      if (option.start == current.start) {
        match = option;
        break;
      }
    }
    setState(() => _viewedRange = match);
  }

  /// "Lưu trữ ngân sách" (FR-016/FR-017/FR-024) — hỏi xác nhận rồi ghi cờ
  /// `isArchived` và đóng màn; **không** đụng tới giao dịch nào.
  Future<void> _archive(Budget budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Lưu trữ ngân sách?'.tr),
        content: Text(
          'Ngân sách sẽ ngừng theo dõi. Các giao dịch đã ghi vẫn còn nguyên.'.tr,
        ),
        actions: [
          TextButton(
            key: const ValueKey('budget-detail-cancel-archive'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Hủy'.tr),
          ),
          TextButton(
            key: const ValueKey('budget-detail-confirm-archive'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Lưu trữ'.tr),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      await _repository.updateBudget(budget.copyWith(isArchived: true));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không lưu được ngân sách. Vui lòng thử lại.'.tr),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  /// Hai nút cuối màn — hiện ở **mọi kỳ** đang xem và cả khi danh mục đã bị xóa
  /// (FR-024, data-model luật 10: còn đường gán lại danh mục).
  Widget _actions(Budget budget) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  key: const ValueKey('budget-detail-edit'),
                  onPressed: () => _edit(budget),
                  child: Text('Chỉnh sửa'.tr),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 44,
                child: FilledButton(
                  key: const ValueKey('budget-detail-archive'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _archive(budget),
                  child: Text(
                    'Lưu trữ ngân sách'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bộ chọn kỳ (FR-023): bottom sheet liệt kê các kỳ của **chính ngân sách
  /// này**, mới nhất trên cùng, kỳ đang xem đánh dấu teal.
  Future<void> _pickPeriod(Budget budget, DateRange current) async {
    final colors = SoraColors.of(context);
    final options = budgetPeriodOptions(budget, _now).reversed.toList();
    final picked = await showModalBottomSheet<DateRange>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Chọn kỳ'.tr,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final option in options)
              ListTile(
                key: ValueKey(
                  'budget-detail-period-${option.start.toIso8601String()}',
                ),
                title: Text(
                  _periodLabel(budget.period, option),
                  style: TextStyle(
                    color: option.start == current.start
                        ? colors.tealOnNeutral
                        : colors.textPrimary,
                    fontSize: 14,
                    fontWeight: option.start == current.start
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                trailing: option.start == current.start
                    ? Icon(Icons.check, color: colors.tealOnNeutral, size: 18)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
          ],
        ),
      ),
    );
    if (!mounted || picked == null) return;
    setState(() => _viewedRange = picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final budget = _budget;
    final range = budget == null
        ? null
        : (_viewedRange ?? budgetDefaultRange(budget, _now));
    final category = budget == null ? null : _categoryOf(budget.categoryId);
    if (budget == null || range == null) {
      return SubPageScaffold(
        title: category?.name.tr ?? 'Danh mục đã bị xóa'.tr,
        child: _body(colors),
      );
    }
    return SubPageScaffold(
      title: category?.name.tr ?? 'Danh mục đã bị xóa'.tr,
      subtitle: _subtitle(budget, range),
      actions: [
        IconButton(
          key: const ValueKey('budget-detail-period-picker'),
          icon: const Icon(Icons.calendar_month_outlined),
          color: AppColors.white,
          onPressed: () => _pickPeriod(budget, range),
        ),
      ],
      bottomNavigationBar: _actions(budget),
      child: _body(colors),
    );
  }

  Category? _categoryOf(int id) {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Dòng phụ app bar: chu kỳ của ngân sách + kỳ đang xem (FR-002).
  String _subtitle(Budget budget, DateRange range) {
    final period = switch (budget.period) {
      BudgetPeriod.monthly => 'Ngân sách tháng • @kỳ'.trParams({
        'kỳ': _periodLabel(budget.period, range),
      }),
      BudgetPeriod.weekly => 'Ngân sách tuần • @kỳ'.trParams({
        'kỳ': _periodLabel(budget.period, range),
      }),
      BudgetPeriod.yearly => 'Ngân sách năm • @kỳ'.trParams({
        'kỳ': _periodLabel(budget.period, range),
      }),
    };
    return period;
  }

  Widget _body(SoraColors colors) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorState(message: _error!, onRetry: _load);
    final budget = _budget;
    if (budget == null) {
      return _ErrorState(
        message: 'Không đọc được ngân sách.'.tr,
        onRetry: _load,
      );
    }

    final detail = buildBudgetDetail(
      budget: budget,
      categories: _categories,
      transactions: _transactions,
      now: _now,
      viewedRange: _viewedRange ?? budgetDefaultRange(budget, _now),
    );
    if (detail.category == null) return const _InvalidState();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _ProgressCard(detail: detail),
        if (detail.showPaceWarning) ...[
          const SizedBox(height: 12),
          _PaceWarning(detail: detail),
        ],
        const SizedBox(height: 18),
        _ComparisonSection(detail: detail),
        const SizedBox(height: 18),
        _TransactionsSection(
          detail: detail,
          categories: _categories,
          now: _now,
          onSeeAll: () => _seeAll(detail),
        ),
      ],
    );
  }
}

/// Nhãn kỳ đang xem theo chu kỳ (FR-002) — "Tháng 9, 2026" / "Tuần 7/9 – 13/9"
/// / "Năm 2026".
String _periodLabel(BudgetPeriod period, DateRange range) {
  switch (period) {
    case BudgetPeriod.weekly:
      final lastDay = range.end.subtract(const Duration(days: 1));
      return 'Tuần @từ – @đến'.trParams({
        'từ': '${range.start.day}/${range.start.month}',
        'đến': '${lastDay.day}/${lastDay.month}',
      });
    case BudgetPeriod.monthly:
      return 'Tháng @tháng, @năm'.trParams({
        'tháng': '${range.start.month}',
        'năm': '${range.start.year}',
      });
    case BudgetPeriod.yearly:
      return 'Năm @năm'.trParams({'năm': '${range.start.year}'});
  }
}

/// Lỗi đọc ngân sách (FR-019) — thông báo + nút thử lại.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
            Icon(Icons.error_outline, color: colors.coralOnNeutral, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text('Thử lại'.tr)),
          ],
        ),
      ),
    );
  }
}

/// Danh mục của ngân sách đã bị xóa (FR-019): nói rõ trạng thái + nhắc gán lại,
/// **ẩn** thẻ tiến độ/biểu đồ/danh sách giao dịch; ngân sách không bị tự xóa.
class _InvalidState extends StatelessWidget {
  const _InvalidState();

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off, color: colors.tabInactive, size: 44),
            const SizedBox(height: 12),
            Text(
              'Danh mục của ngân sách đã bị xóa.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chạm "Chỉnh sửa" để gán lại danh mục khác.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.tabInactive, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ tiến độ (FR-003…FR-006): đã dùng / giới hạn / huy hiệu trạng thái /
/// thanh tiến độ / vượt–còn lại + ngày còn lại.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.detail});

  final BudgetDetail detail;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final amountColor = switch (detail.level) {
      ProgressLevel.normal => colors.tealOnNeutral,
      ProgressLevel.near || ProgressLevel.over => colors.coralOnNeutral,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.listDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đã dùng'.tr,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatMoney(detail.spent),
                        style: TextStyle(
                          color: amountColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'trên @số đ giới hạn'.trParams({
                        'số': formatAmount(detail.budget.amount),
                      }),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.tabInactive,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Trạng thái'.tr,
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  _StatusBadge(detail: detail),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ProgressBar(level: detail.level, percent: detail.percent),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  detail.level == ProgressLevel.over
                      ? 'Vượt @số đ'.trParams({
                          'số': formatAmount(detail.overAmount),
                        })
                      : 'Còn lại @số đ'.trParams({
                          'số': formatAmount(detail.remainingAmount),
                        }),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                detail.ended
                    ? 'Đã kết thúc'.tr
                    : '@n ngày còn lại'.trParams({'n': '${detail.daysLeft}'}),
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Huy hiệu mức sử dụng (FR-005, R8): "Bình thường/Sắp đạt/Vượt {p}%" — nền
/// coral nhạt từ dải 80% trở lên.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.detail});

  final BudgetDetail detail;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final percent = '${detail.percent.round()}';
    final (text, accent) = switch (detail.level) {
      ProgressLevel.normal => (
        'Bình thường @p%'.trParams({'p': percent}),
        colors.tealOnNeutral,
      ),
      ProgressLevel.near => (
        'Sắp đạt @p%'.trParams({'p': percent}),
        colors.coralOnNeutral,
      ),
      ProgressLevel.over => (
        'Vượt @p%'.trParams({'p': percent}),
        colors.coralOnNeutral,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: detail.level == ProgressLevel.normal
            ? colors.softCardBg
            : colors.coralLightBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Thanh tiến độ bo 3px, màu theo đúng 3 dải của màn Tổng quan (FR-004).
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.level, required this.percent});

  final ProgressLevel level;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final fill = switch (level) {
      ProgressLevel.normal => colors.tealOnNeutral,
      ProgressLevel.near => AppColors.coral.withValues(alpha: 0.6),
      ProgressLevel.over => AppColors.coral,
    };
    final fraction = (percent / 100).clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Stack(
        children: [
          Container(height: 8, color: colors.softCardBg),
          FractionallySizedBox(
            widthFactor: fraction,
            child: Container(height: 8, color: fill),
          ),
        ],
      ),
    );
  }
}

/// Băng cảnh báo tốc độ chi tiêu (FR-007, SC-004) — chỉ hiện khi chi nhanh hơn
/// nhịp thời gian và kỳ chưa kết thúc.
class _PaceWarning extends StatelessWidget {
  const _PaceWarning({required this.detail});

  final BudgetDetail detail;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: colors.coralLightBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.coral,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '!',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tốc độ chi tiêu nhanh hơn dự kiến'.tr,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Đã dùng @p% ngày nhưng chi @q% ngân sách'.trParams({
                    'p': '${detail.elapsedPercent.round()}',
                    'q': '${detail.percent.round()}',
                  }),
                  style: TextStyle(color: colors.listLabel, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Khối "SO SÁNH DỰ KIẾN • THỰC TẾ" (FR-008/FR-009/FR-010): chú giải 2 ô màu +
/// biểu đồ cột đôi của tối đa 3 kỳ gần nhất, kỳ đang xem là cột cuối.
class _ComparisonSection extends StatelessWidget {
  const _ComparisonSection({required this.detail});

  final BudgetDetail detail;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'SO SÁNH DỰ KIẾN • THỰC TẾ'.tr,
          style: TextStyle(
            color: colors.tabInactive,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
          decoration: BoxDecoration(
            color: colors.softCardBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Legend(colors: colors),
              const SizedBox(height: 10),
              SizedBox(
                height: 140,
                child: _ComparisonChart(
                  comparison: detail.comparison,
                  period: detail.budget.period,
                  budgetAmount: detail.budget.amount,
                  colors: colors,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Chú giải 2 ô màu: Dự kiến (trung tính) / Thực tế (coral — mockup `03`).
class _Legend extends StatelessWidget {
  const _Legend({required this.colors});

  final SoraColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _swatch(colors.dotEmpty),
        const SizedBox(width: 6),
        Text(
          'Dự kiến'.tr,
          style: TextStyle(fontSize: 10, color: colors.textSecondary),
        ),
        const SizedBox(width: 16),
        _swatch(colors.coralOnNeutral),
        const SizedBox(width: 6),
        Text(
          'Thực tế'.tr,
          style: TextStyle(fontSize: 10, color: colors.textSecondary),
        ),
      ],
    );
  }

  Widget _swatch(Color color) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
  );
}

/// Biểu đồ cột đôi Dự kiến • Thực tế của các kỳ đang so sánh (FR-009/FR-010).
/// Cột "Dự kiến" một màu trung tính cho mọi kỳ; cột "Thực tế" teal khi kỳ đó
/// không vượt và coral khi vượt; đường mốc giới hạn vẽ nét đứt.
class _ComparisonChart extends StatelessWidget {
  const _ComparisonChart({
    required this.comparison,
    required this.period,
    required this.budgetAmount,
    required this.colors,
  });

  final List<BudgetPeriodSummary> comparison;
  final BudgetPeriod period;
  final int budgetAmount;
  final SoraColors colors;

  @override
  Widget build(BuildContext context) {
    var maxValue = budgetAmount.toDouble();
    for (final p in comparison) {
      if (p.spent > maxValue) maxValue = p.spent.toDouble();
    }
    final neutral = colors.dotEmpty;
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxValue <= 0 ? 1 : maxValue * 1.15,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: false),
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
              getTitlesWidget: _periodTitle,
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: budgetAmount.toDouble(),
              color: neutral,
              strokeWidth: 1,
              dashArray: const [3, 3],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(fontSize: 9, color: colors.textSecondary),
                labelResolver: (_) => 'Dự kiến @số đ'.trParams({
                  'số': formatAmount(budgetAmount),
                }),
              ),
            ),
          ],
        ),
        barGroups: [
          for (var i = 0; i < comparison.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: comparison[i].limit.toDouble(),
                  color: neutral.withValues(alpha: 0.5),
                  width: 8,
                  borderRadius: BorderRadius.circular(3),
                ),
                BarChartRodData(
                  toY: comparison[i].spent.toDouble(),
                  color: comparison[i].level == ProgressLevel.over
                      ? colors.coralOnNeutral
                      : colors.tealOnNeutral,
                  width: 8,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Nhãn kỳ dưới trục — kỳ **đang xem** (phần tử cuối) đậm hơn (FR-009).
  Widget _periodTitle(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= comparison.length) return const SizedBox.shrink();
    final current = index == comparison.length - 1;
    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Text(
        _axisLabel(comparison[index].range),
        style: TextStyle(
          color: current ? colors.textPrimary : colors.textSecondary,
          fontSize: 9,
          fontWeight: current ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }

  /// Nhãn trục theo chu kỳ: `T9` (Tháng) / `7/9` (Tuần) / `2026` (Năm).
  String _axisLabel(DateRange range) {
    switch (period) {
      case BudgetPeriod.weekly:
        return '@ngày/@tháng'.trParams({
          'ngày': '${range.start.day}',
          'tháng': '${range.start.month}',
        });
      case BudgetPeriod.monthly:
        return 'T@tháng'.trParams({'tháng': '${range.start.month}'});
      case BudgetPeriod.yearly:
        return '@năm'.trParams({'năm': '${range.start.year}'});
    }
  }
}

/// Nhóm "GIAO DỊCH TRONG KỲ" + liên kết "Xem tất cả" (FR-011/FR-012/FR-013).
class _TransactionsSection extends StatelessWidget {
  const _TransactionsSection({
    required this.detail,
    required this.categories,
    required this.now,
    required this.onSeeAll,
  });

  final BudgetDetail detail;
  final List<Category> categories;
  final DateTime now;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final rows = detail.transactions.take(_previewRows).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'GIAO DỊCH TRONG KỲ'.tr,
                style: TextStyle(
                  color: colors.tabInactive,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            TextButton(
              key: const ValueKey('budget-detail-see-all'),
              onPressed: onSeeAll,
              child: Text('Xem tất cả'.tr),
            ),
          ],
        ),
        if (rows.isEmpty)
          _EmptyTransactions()
        else
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(color: colors.listDivider, height: 1),
            _TransactionRow(
              transaction: rows[i],
              category: _categoryOf(rows[i].categoryId),
              fallback: detail.category,
              now: now,
            ),
          ],
      ],
    );
  }

  Category? _categoryOf(int? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// Một dòng giao dịch Chi trong kỳ (FR-012): icon danh mục, tên (ghi chú, rỗng
/// → tên danh mục), thời gian, số tiền Chi màu coral.
class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.category,
    required this.fallback,
    required this.now,
  });

  final Transaction transaction;
  final Category? category;
  final Category? fallback;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final shown = category ?? fallback;
    final accent = shown == null
        ? colors.coralOnNeutral
        : Color(shown.color);
    final title = transaction.note.isEmpty
        ? (shown?.name.tr ?? 'Danh mục đã bị xóa'.tr)
        : transaction.note;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              categoryIcon(shown?.icon ?? 'category'),
              size: 17,
              color: accent,
            ),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${relativeDayLabel(transaction.date, now: now)}, '
                  '${formatTimeLabel(transaction.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                formatSignedMoney(transaction.amount),
                style: TextStyle(
                  color: colors.coralOnNeutral,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kỳ chưa có giao dịch Chi nào (FR-013) — trạng thái rỗng, không danh sách trơ.
class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: colors.tabInactive, size: 34),
          const SizedBox(height: 8),
          Text(
            'Chưa có giao dịch Chi nào trong kỳ.'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Chi tiêu thuộc danh mục này sẽ hiện tại đây.'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.tabInactive, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
