import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/budget/budget.dart';
import '../core/budget/budget_view.dart';
import '../core/category/category.dart';
import '../core/money_format.dart';
import '../core/transaction/transaction.dart';
import '../core/widgets/add_transaction_fab.dart';
import '../core/widgets/app_bottom_nav_bar.dart';
import '../core/widgets/category_icon.dart';
import '../core/widgets/screen_header.dart';
import '../data/wallet_deps.dart';
import '../data/wallet_repository.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';
import 'add_transaction_screen.dart';
import 'budget_form_screen.dart';

/// Màn Tổng quan Ngân sách (mockup `01`, PBI 20) — màn **cấp tab** đẩy từ tab
/// Báo cáo (FR-001): `ScreenHeader` teal (tiêu đề + nút `+`) + bộ chọn kỳ ở
/// giữa, bottom nav thật với tab Báo cáo sáng sẵn. Không có nút back: chạm tab
/// khác thì `pop()` rồi gọi [onSelectTab] do `AppShell` bơm xuống (research R1).
///
/// StatefulWidget nạp 1 lần trong `initState` (`budgets()` + `allTransactions()`
/// + `categoriesIncludingHidden(expense)`); [now] bơm được để test
/// deterministic. "Đã chi"/% tính lại mỗi lần nạp — không snapshot (R3).
class BudgetOverviewScreen extends StatefulWidget {
  const BudgetOverviewScreen({
    super.key,
    this.repository,
    this.onSelectTab,
    this.now,
  });

  /// Seam test: mặc định null → [ensureWalletRepository] khi vào.
  final WalletRepository? repository;

  /// Chạm tab khác ở bottom nav → đổi tab thật ở shell (null = chỉ `pop()`).
  final ValueChanged<int>? onSelectTab;

  /// Mốc "hôm nay" — test bơm cố định, chạy thật lấy giờ hệ thống.
  final DateTime? now;

  @override
  State<BudgetOverviewScreen> createState() => _BudgetOverviewScreenState();
}

class _BudgetOverviewScreenState extends State<BudgetOverviewScreen> {
  static const int _reportTabIndex = 2;

  late final WalletRepository _repository;
  late final DateTime _now;

  bool _loading = true;
  String? _error;

  List<Budget> _budgets = const [];
  List<Transaction> _transactions = const [];
  List<Category> _categories = const [];

  /// Mốc trong **tháng đang xem** — mặc định tháng hiện tại (FR-002).
  late DateTime _viewedMonth;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ensureWalletRepository();
    _now = widget.now ?? DateTime.now();
    _viewedMonth = DateTime(_now.year, _now.month, 1);
    _load();
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

  /// Nạp lại không spinner — dùng khi quay về từ màn Thêm/Sửa (FR-015/FR-017).
  Future<void> _reloadSilent() async {
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
      });
    } catch (_) {
      // Giữ dữ liệu cũ — lỗi đọc nền không đáng ngắt màn.
    }
  }

  void _shiftMonth(int delta) {
    setState(() {
      _viewedMonth = DateTime(_viewedMonth.year, _viewedMonth.month + delta, 1);
    });
  }

  Future<void> _openForm({Budget? budget}) async {
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
    await _reloadSilent();
  }

  /// FAB của shell trên màn này: ghi giao dịch rồi quay lại ⇒ phải nạp lại để
  /// "đã chi" khớp (SC-009).
  Future<void> _openAddTransaction() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    if (!mounted || saved != true) return;
    await _reloadSilent();
  }

  void _onTabSelected(int index) {
    if (index == _reportTabIndex) return;
    Navigator.of(context).pop();
    widget.onSelectTab?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: 'Ngân sách'.tr,
            trailing: _AddButton(onTap: () => _openForm()),
            bottom: _MonthPicker(
              label: 'Tháng @tháng, @năm'.trParams({
                'tháng': '${_viewedMonth.month}',
                'năm': '${_viewedMonth.year}',
              }),
              onPrev: () => _shiftMonth(-1),
              onNext: () => _shiftMonth(1),
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: AddTransactionFab(onTap: _openAddTransaction),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _reportTabIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }

  Widget _body() {
    final colors = SoraColors.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: colors.textPrimary)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: Text('Thử lại'.tr)),
          ],
        ),
      );
    }
    final view = buildBudgetOverview(
      budgets: _budgets,
      transactions: _transactions,
      categories: _categories,
      now: _now,
      viewedMonth: _viewedMonth,
    );
    if (view.isEmpty) return _EmptyState(onAdd: () => _openForm());
    return _content(view, colors);
  }

  Widget _content(BudgetOverview view, SoraColors colors) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _TotalCard(view: view),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'DANH MỤC'.tr,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {}, // chưa có hiệu lực đợt này (FR-014).
                child: Text('Sao chép tháng trước'.tr),
              ),
            ],
          ),
        ),
        for (final row in view.rows) ...[
          _BudgetRowTile(row: row, onTap: () => _openForm(budget: row.budget)),
          Divider(color: colors.listDivider, height: 1),
        ],
      ],
    );
  }
}

/// Nút `+` tròn 48px trên nền teal (mockup `01`) — mở màn Thêm ngân sách (FR-008).
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('budget-add'),
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: const SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.add, color: AppColors.white, size: 24),
      ),
    );
  }
}

/// Bộ chọn kỳ "Tháng 9, 2026" + 2 mũi tên (FR-002).
class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _arrow('budget-month-prev', Icons.chevron_left, onPrev),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        _arrow('budget-month-next', Icons.chevron_right, onNext),
      ],
    );
  }

  Widget _arrow(String key, IconData icon, VoidCallback onTap) {
    return InkWell(
      key: ValueKey(key),
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, color: AppColors.white, size: 24),
      ),
    );
  }
}

/// Thẻ tổng (FR-003): tổng đã chi / tổng giới hạn + thanh tiến độ + còn lại +
/// số ngày còn lại của tháng đang xem.
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.view});

  final BudgetOverview view;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final remaining = view.totalLimit - view.totalSpent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.softCardBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng ngân sách tháng này'.tr,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: formatMoney(view.totalSpent),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${formatMoney(view.totalLimit)}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            _RowProgressBar(
              level: budgetProgressLevel(view.totalPercent),
              percent: view.totalPercent,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Còn lại @số đ'.trParams({'số': formatAmount(remaining)}),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '@n ngày còn lại'.trParams({'n': '${view.daysLeft}'}),
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Một dòng ngân sách (FR-004): bubble icon danh mục → tên + "đã chi / giới hạn"
/// (+ nhãn chu kỳ cho Tuần/Năm) → **%** cuối dòng → thanh tiến độ bên dưới.
/// Dòng `ended` hiện "Đã kết thúc", dòng `invalid` hiện "Danh mục đã bị xóa"
/// thay cho % (FR-020/FR-021); **không** hiện số tiền vượt (FR-005).
class _BudgetRowTile extends StatelessWidget {
  const _BudgetRowTile({required this.row, required this.onTap});

  final BudgetRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final category = row.category;
    final accent = switch (row.level) {
      ProgressLevel.normal => colors.tealOnNeutral,
      ProgressLevel.near || ProgressLevel.over => colors.coralOnNeutral,
    };
    return InkWell(
      key: ValueKey('budget-row-${row.budget.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: category == null
                        ? colors.softCardBg
                        : Color(category.color).withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category == null
                        ? categoryIcon('category')
                        : categoryIcon(category.icon),
                    size: 20,
                    color: category == null
                        ? colors.tabInactive
                        : Color(category.color),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              category?.name.tr ?? 'Danh mục đã bị xóa'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (row.status == BudgetStatus.active &&
                              row.budget.period != BudgetPeriod.monthly) ...[
                            const SizedBox(width: 8),
                            Text(
                              row.budget.period.label,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatMoney(row.spent)} / ${formatMoney(row.budget.amount)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _trailing(colors, accent),
              ],
            ),
            const SizedBox(height: 8),
            _RowProgressBar(level: row.level, percent: row.percent),
          ],
        ),
      ),
    );
  }

  /// Cột phải: % đã dùng (active) hoặc nhãn trạng thái (ended/invalid).
  Widget _trailing(SoraColors colors, Color accent) {
    final String text;
    final Color color;
    switch (row.status) {
      case BudgetStatus.active:
        text = '${row.percent.round()}%';
        color = accent;
      case BudgetStatus.ended:
        text = 'Đã kết thúc'.tr;
        color = colors.textSecondary;
      case BudgetStatus.invalid:
        text = 'Danh mục đã bị xóa'.tr;
        color = colors.coralOnNeutral;
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Thanh tiến độ của dòng — đầy theo % đã dùng (kẹp 1.0), màu theo 3 dải.
class _RowProgressBar extends StatelessWidget {
  const _RowProgressBar({required this.level, required this.percent});

  final ProgressLevel level;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final Color fill = switch (level) {
      ProgressLevel.normal => colors.tealOnNeutral,
      ProgressLevel.near => AppColors.coral.withValues(alpha: 0.6),
      ProgressLevel.over => AppColors.coral,
    };
    final fraction = (percent / 100).clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Stack(
        children: [
          Container(height: 6, color: colors.divider),
          FractionallySizedBox(
            widthFactor: fraction,
            child: Container(height: 6, color: fill),
          ),
        ],
      ),
    );
  }
}

/// Trạng thái rỗng (FR-019): lời nhắc + nút "Thêm ngân sách", không hiện thẻ
/// tổng hay danh sách trơ.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.savings_outlined, color: colors.tabInactive, size: 44),
            const SizedBox(height: 12),
            Text(
              'Chưa có ngân sách nào.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Đặt giới hạn chi tiêu cho một danh mục để theo dõi tiến độ.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.tabInactive, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const ValueKey('budget-empty-add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onAdd,
              child: Text('Thêm ngân sách'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
