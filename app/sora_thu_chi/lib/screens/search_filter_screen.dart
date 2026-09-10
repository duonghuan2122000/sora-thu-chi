import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/category/category.dart';
import '../core/money_format.dart';
import '../core/transaction/add_form.dart';
import '../core/transaction/transaction.dart';
import '../core/transaction/transaction_filter.dart';
import '../core/transaction/transaction_list.dart';
import '../core/wallet/wallet.dart';
import '../core/widgets/amount_keypad.dart';
import '../core/widgets/category_icon.dart';
import '../data/wallet_deps.dart';
import '../data/wallet_repository.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';

/// Màn con "Tìm kiếm & Lọc" (mockup `05`, PBI 12) — đè shell, toàn màn hình:
/// app bar teal: back + ô tìm kiếm pill (bỏ dấu tiếng Việt); chip loại 4 nút;
/// nhãn "BỘ LỌC NÂNG CAO"; 5 dòng nâng cao mở bottom sheet; dòng tóm tắt
/// "N kết quả · Tổng: X đ" **live**; nút Đặt lại / Áp dụng cố định chân màn.
/// Làm việc trên **bản nháp** (R6): Áp dụng → `pop(filter)`; back → `pop(null)`
/// giữ tập cũ (FR-015). Stateful + [WalletRepository] inject (seam PBI 11).
class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({
    super.key,
    this.repository,
    this.initial,
    this.now,
  });

  /// Seam test: mặc định null → [ensureWalletRepository] khi vào (R11).
  final WalletRepository? repository;

  /// Bộ lọc đang áp dụng (mở lại hiển thị đúng — SC-007); null → mặc định
  /// Tháng này khi chưa áp dụng lần nào (FR-005/015).
  final TxnSearchFilter? initial;

  /// Anchor thời gian (test deterministic); mặc định giờ thật.
  final DateTime? now;

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  static const int _clearSentinel = -1;
  static const int _allWalletsSentinel = -2;

  late final WalletRepository _repository;
  late final DateTime _anchor = widget.now ?? DateTime.now();

  final TextEditingController _keywordCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;
  List<Transaction> _all = const [];
  Map<int, String> _names = const {};
  List<Wallet> _wallets = const [];
  List<Category> _categories = const [];

  late TxnSearchFilter _draft;
  late FilteredTxSummary _summary = const FilteredTxSummary(count: 0, signedTotal: 0);

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ensureWalletRepository();
    _draft = widget.initial ?? TxnSearchFilter.defaults(now: _anchor);
    _keywordCtrl.text = _draft.keyword;
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _keywordCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final transactions = await _repository.allTransactions();
      final wallets = await _repository.loadAll();
      final categories = [
        ...await _repository.categories(type: CategoryType.income),
        ...await _repository.categories(type: CategoryType.expense),
      ];
      if (!mounted) return;
      setState(() {
        _all = transactions;
        _names = {for (final w in wallets) w.id: w.name};
        _wallets = walletsByDisplayOrder(wallets);
        _categories = categories;
        _loading = false;
      });
      _refreshSummary();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không đọc được dữ liệu.'.tr;
        _loading = false;
      });
    }
  }

  bool get _amountInvalid =>
      _draft.amountMin != null &&
      _draft.amountMax != null &&
      _draft.amountMin! > _draft.amountMax!;

  /// Tổng/đếm live — lọc thuần trên cache raw đã nạp 1 lần (R1/R9).
  void _refreshSummary() {
    if (_amountInvalid) {
      _summary = const FilteredTxSummary(count: 0, signedTotal: 0);
      return;
    }
    final matched = filterTransactions(_all, _draft, _categories);
    final rows = buildDisplayRows(matched, _names);
    _summary = summarizeRows(rows);
  }

  void _setDraft(TxnSearchFilter next) {
    setState(() {
      _draft = next;
      _refreshSummary();
    });
  }

  void _onKeywordChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _setDraft(_draft.copyWith(keyword: value));
    });
  }

  void _setType(TxnTypeFilter type) {
    if (type == _draft.type) return;
    // Đổi loại → bỏ danh mục đã chọn cũ (nguồn danh mục đổi — R7/FR-006);
    // chip Chuyển khoản làm dòng Danh mục vô hiệu (transfer không danh mục).
    _setDraft(_draft.copyWith(type: type, categoryIds: const {}));
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _fmt(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

  String get _rangeLabel {
    if (_draft.datePreset == DatePreset.all) return 'Toàn bộ'.tr;
    final start = _draft.dateStart;
    final end = _draft.dateEnd;
    if (start == null && end == null) return 'Toàn bộ'.tr;
    return '${start == null ? '…' : _fmt(start)} - ${end == null ? '…' : _fmt(end)}';
  }

  String get _walletLabel {
    final id = _draft.walletId;
    if (id == null) return 'Tất cả các ví'.tr;
    final wallet = _wallets.where((w) => w.id == id).firstOrNull;
    return wallet == null
        ? 'Tất cả các ví'.tr
        : (wallet.isHidden ? wallet.hiddenName : wallet.name);
  }

  bool _categoryEnabled() => _draft.type != TxnTypeFilter.transfer;

  String get _summaryText {
    final count = _summary.count;
    return '@n kết quả · Tổng: @total'.trParams({
      'n': '$count',
      'total': formatMoney(_summary.signedTotal),
    });
  }

  // ---- Bottom sheets / pickers ----

  Future<void> _pickDatePreset() async {
    final chosen = await showModalBottomSheet<DatePreset>(
      context: context,
      builder: (_) => _DatePresetSheet(current: _draft.datePreset),
    );
    if (chosen == null || !mounted) return;
    if (chosen == DatePreset.custom) {
      await _pickCustomRange();
      return;
    }
    _setDraft(_draft.withDateRange(chosen));
  }

  Future<void> _pickCustomRange() async {
    final anchorDate = _draft.dateEnd ?? _draft.dateStart ?? _anchor;
    final start = await showDatePicker(
      context: context,
      initialDate: _draft.dateStart ?? anchorDate,
      firstDate: DateTime(2000),
      lastDate: _draft.dateEnd ?? DateTime(_anchor.year + 20),
    );
    if (start == null || !mounted) return;
    final end = await showDatePicker(
      context: context,
      initialDate: (_draft.dateEnd != null && !_draft.dateEnd!.isBefore(start))
          ? _draft.dateEnd!
          : start,
      firstDate: start, // chặn ngày bắt đầu sau ngày kết thúc (FR-008).
      lastDate: DateTime(_anchor.year + 20),
    );
    if (end == null || !mounted) return;
    _setDraft(
      _draft.withDateRange(DatePreset.custom, customStart: start, customEnd: end),
    );
  }

  Future<void> _pickCategory() async {
    final chosen = await showModalBottomSheet<Set<int>>(
      context: context,
      builder: (_) => _CategorySheet(
        categories: _categorySource(),
        selected: _draft.categoryIds,
      ),
    );
    if (chosen == null || !mounted) return;
    _setDraft(_draft.copyWith(categoryIds: chosen));
  }

  /// Nguồn danh mục theo chip loại đang chọn (FR-006/R7).
  List<Category> _categorySource() {
    final wanted = switch (_draft.type) {
      TxnTypeFilter.all => null,
      TxnTypeFilter.income => CategoryType.income,
      TxnTypeFilter.expense => CategoryType.expense,
      TxnTypeFilter.transfer => null, // vô hiệu — không gọi tới.
    };
    return wanted == null
        ? _categories
        : _categories.where((c) => c.type == wanted).toList();
  }

  Future<void> _removeCategory(int id) async {
    final next = {..._draft.categoryIds}..remove(id);
    _setDraft(_draft.copyWith(categoryIds: next));
  }

  Future<void> _pickWallet() async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => _WalletSheet(
        wallets: _wallets,
        selectedId: _draft.walletId,
      ),
    );
    if (chosen == null || !mounted) return; // đóng không chọn → giữ nguyên.
    _setDraft(
      _draft.withWalletId(chosen == _allWalletsSentinel ? null : chosen),
    );
  }

  Future<void> _pickAmount({required bool minSide}) async {
    final current = minSide ? _draft.amountMin : _draft.amountMax;
    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => _AmountSheet(minSide: minSide, initial: current),
    );
    if (result == null || !mounted) return; // cancel.
    final min = minSide
        ? (result == _clearSentinel ? null : result)
        : _draft.amountMin;
    final max = !minSide
        ? (result == _clearSentinel ? null : result)
        : _draft.amountMax;
    _setDraft(_draft.withAmountBounds(min, max));
  }

  Future<void> _pickSort() async {
    final chosen = await showModalBottomSheet<SortOption>(
      context: context,
      builder: (_) => _SortSheet(current: _draft.sort),
    );
    if (chosen == null || !mounted) return;
    _setDraft(_draft.copyWith(sort: chosen));
  }

  void _reset() {
    _debounce?.cancel();
    _keywordCtrl.clear();
    _setDraft(_draft.reset());
  }

  void _apply() {
    if (_amountInvalid) return;
    Navigator.of(context).pop(_draft);
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _searchPill(),
      ),
      body: _body(colors),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    key: const ValueKey('reset-filter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _reset,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Đặt lại'.tr),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    key: const ValueKey('apply-filter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      disabledBackgroundColor: AppColors.teal.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _amountInvalid ? null : _apply,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Áp dụng'.tr),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ô tìm kiếm pill trắng nằm ngay trên app bar (mockup `05`) — đảo sáng cố
  /// định trên nền teal thương hiệu, nên giữ token light ở cả 2 giao diện (đổi
  /// theo theme sẽ thành pill tối trên app bar teal, chữ mờ khó đọc).
  Widget _searchPill() {
    const light = SoraColors.light;
    return Container(
      height: 40,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: light.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: light.textSecondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const ValueKey('search-field'),
              controller: _keywordCtrl,
              onChanged: _onKeywordChanged,
              style: TextStyle(
                color: light.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Tìm kiếm giao dịch...'.tr,
                hintStyle: TextStyle(
                  color: light.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(SoraColors colors) {
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      key: const ValueKey('filter-body-list'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _typeChips(colors),
        const SizedBox(height: 20),
        _sectionLabel('BỘ LỌC NÂNG CAO'.tr, colors),
        const SizedBox(height: 4),
        _filterRow(
          key: const ValueKey('filter-period'),
          icon: Icons.calendar_today_outlined,
          label: 'Khoảng thời gian'.tr,
          value: _rangeLabel,
          valueKey: const ValueKey('filter-period-value'),
          onTap: _pickDatePreset,
          showChevron: true,
          colors: colors,
        ),
        _filterRow(
          key: const ValueKey('filter-category'),
          icon: Icons.category_outlined,
          label: 'Danh mục'.tr,
          enabled: _categoryEnabled(),
          onTap: _pickCategory,
          child: _categoryValue(colors),
          colors: colors,
        ),
        _filterRow(
          key: const ValueKey('filter-wallet'),
          icon: Icons.account_balance_wallet_outlined,
          label: 'Ví'.tr,
          value: _walletLabel,
          valueKey: const ValueKey('filter-wallet-value'),
          onTap: _pickWallet,
          showChevron: true,
          colors: colors,
        ),
        _amountSection(colors),
        _filterRow(
          key: const ValueKey('filter-sort'),
          icon: Icons.sort,
          label: 'Sắp xếp theo'.tr,
          value: _draft.sort.label,
          valueKey: const ValueKey('filter-sort-value'),
          onTap: _pickSort,
          showChevron: true,
          colors: colors,
        ),
        const SizedBox(height: 16),
        _summaryLine(colors),
      ],
    );
  }

  /// Hàng chip loại cuộn ngang — chọn teal, chưa chọn nền trắng viền (FR-004).
  Widget _typeChips(SoraColors colors) {
    final options = [
      TxnTypeFilter.all,
      TxnTypeFilter.income,
      TxnTypeFilter.expense,
      TxnTypeFilter.transfer,
    ];
    return SizedBox(
      height: 40,
      child: ListView(
        key: const ValueKey('type-chips'),
        scrollDirection: Axis.horizontal,
        children: [
          for (final type in options) ...[
            _typeChip(type, colors),
            if (type != options.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _typeChip(TxnTypeFilter type, SoraColors colors) {
    final selected = _draft.type == type;
    return GestureDetector(
      onTap: () => _setType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.teal : colors.divider,
          ),
        ),
        child: Text(
          type.label,
          style: TextStyle(
            color: selected ? AppColors.white : colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, SoraColors colors) {
    return Text(
      text,
      style: TextStyle(
        color: colors.tabInactive,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Dòng tóm tắt "N kết quả · Tổng: X đ" — cập nhật live (FR-003/011).
  Widget _summaryLine(SoraColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.softCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _summaryText,
        key: const ValueKey('summary-line'),
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _categoryValue(SoraColors colors) {
    if (!_categoryEnabled()) {
      return Text(
        'Không áp dụng cho Chuyển khoản'.tr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colors.tabInactive, fontSize: 14),
      );
    }
    final byId = {for (final c in _categories) c.id: c};
    final selected = _draft.categoryIds.toList();
    if (selected.isEmpty) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Chọn danh mục'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _amountInvalid
                    ? colors.coralOnNeutral
                    : colors.tabInactive,
                fontSize: 14,
              ),
            ),
          ),
          _addMoreButton(colors),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final id in selected)
                _categoryChip(id, category: byId[id], colors: colors),
              _addMoreButton(colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryChip(int id, {Category? category, required SoraColors colors}) {
    final name = category?.name ?? 'id $id';
    return InputChip(
      // Khoá test giữ nguyên tên gốc trong DB (R9) — chỉ nhãn hiển thị dịch.
      key: ValueKey('category-chip-$name'),
      label: Text(name.tr),
      visualDensity: VisualDensity.compact,
      backgroundColor: colors.tealLightBg,
      side: BorderSide.none,
      deleteIconColor: colors.tealOnNeutral,
      onDeleted: () => _removeCategory(id),
    );
  }

  Widget _addMoreButton(SoraColors colors) {
    return InkWell(
      key: const ValueKey('category-add-more'),
      onTap: _categoryEnabled() ? _pickCategory : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: colors.tealOnNeutral, size: 18),
            const SizedBox(width: 2),
            Text(
              'Thêm'.tr,
              style: TextStyle(
                color: colors.tealOnNeutral,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountSection(SoraColors colors) {
    return Column(
      children: [
        _filterRow(
          key: const ValueKey('filter-amount'),
          icon: Icons.payments_outlined,
          label: 'Khoảng số tiền'.tr,
          onTap: () => _pickAmount(minSide: true),
          child: Row(
            children: [
              Expanded(child: _amountPill(minSide: true, colors: colors)),
              const SizedBox(width: 8),
              Expanded(child: _amountPill(minSide: false, colors: colors)),
            ],
          ),
          colors: colors,
        ),
        if (_amountInvalid)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Số tiền tối thiểu không được lớn hơn tối đa'.tr,
              style: TextStyle(color: colors.coralOnNeutral, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _amountPill({required bool minSide, required SoraColors colors}) {
    final value = minSide ? _draft.amountMin : _draft.amountMax;
    final prefix = minSide ? 'Từ'.tr : 'Đến'.tr;
    return InkWell(
      key: ValueKey(minSide ? 'amount-min' : 'amount-max'),
      onTap: () => _pickAmount(minSide: minSide),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: colors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              prefix,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value == null ? '…' : formatMoney(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Một dòng bộ lọc nâng cao: icon tròn + nhãn (mờ khi vô hiệu) + [value]
  /// hoặc [child] tuỳ biến + chevron (mockup `05`).
  Widget _filterRow({
    required Key key,
    required IconData icon,
    required String label,
    String? value,
    Key? valueKey,
    Widget? child,
    required VoidCallback onTap,
    bool enabled = true,
    bool showChevron = false,
    required SoraColors colors,
  }) {
    return Column(
      children: [
        InkWell(
          key: key,
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: enabled ? colors.tealLightBg : colors.softCardBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: enabled ? colors.tealOnNeutral : colors.tabInactive,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: enabled
                              ? colors.listLabel
                              : colors.tabInactive,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (child != null)
                        child
                      else if (value != null)
                        Text(
                          value,
                          key: valueKey,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (showChevron)
                  Icon(
                    Icons.chevron_right,
                    color: colors.tabInactive,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
        Divider(color: colors.listDivider, height: 1),
      ],
    );
  }
}

// ---- Bottom sheets ----

/// Sheet chọn khoảng thời gian — preset + "Tùy chọn…" (R11).
class _DatePresetSheet extends StatelessWidget {
  const _DatePresetSheet({required this.current});

  final DatePreset current;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(
              'Khoảng thời gian'.tr,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final preset in DatePreset.values)
            _SheetOption(
              label: preset.label,
              selected: current == preset,
              onTap: () => Navigator.of(context).pop(preset),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Một dòng option trong sheet — có tick khi đang chọn.
class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.listDivider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check, color: colors.tealOnNeutral, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Sheet chọn danh mục nhiều — checkbox + icon tròn màu; chọn nhiều rồi Xong.
class _CategorySheet extends StatefulWidget {
  const _CategorySheet({required this.categories, required this.selected});

  final List<Category> categories;
  final Set<int> selected;

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  late final Set<int> _selected = {...widget.selected};
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return SafeArea(
      child: SizedBox(
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                'Chọn danh mục'.tr,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  for (final c in widget.categories)
                    _categoryRow(c, colors),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  key: const ValueKey('category-done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: Text('Xong'.tr),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryRow(Category c, SoraColors colors) {
    final checked = _selected.contains(c.id);
    final isParentWithChildren = c.isParent &&
        widget.categories.any((o) => o.parentId == c.id);
    return InkWell(
      key: ValueKey('category-option-${c.name}'),
      onTap: () {
        setState(() {
          if (!_selected.add(c.id)) _selected.remove(c.id);
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color(c.color),
                shape: BoxShape.circle,
              ),
              child: Icon(
                categoryIcon(c.icon),
                color: AppColors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isParentWithChildren
                    ? '@name (gồm con)'.trParams({'name': c.name.tr})
                    : c.name.tr,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              color: checked ? colors.tealOnNeutral : colors.tabInactive,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet chọn ví — "Tất cả các ví" + từng ví (kể cả ẩn, nhãn "(đã ẩn)").
class _WalletSheet extends StatelessWidget {
  const _WalletSheet({required this.wallets, required this.selectedId});

  final List<Wallet> wallets;
  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(
              'Chọn ví'.tr,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _SheetOption(
            label: 'Tất cả các ví'.tr,
            selected: selectedId == null,
            // Sentinel −2 = chọn "Tất cả" (null kết quả = đóng không chọn).
            onTap: () => Navigator.of(context).pop(-2),
          ),
          for (final w in wallets)
            _SheetOption(
              label: w.isHidden ? w.hiddenName : w.name,
              selected: selectedId == w.id,
              onTap: () => Navigator.of(context).pop(w.id),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Sheet chọn thứ tự sắp xếp (FR-009).
class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current});

  final SortOption current;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(
              'Sắp xếp theo'.tr,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final sort in SortOption.values)
            _SheetOption(
              label: sort.label,
              selected: current == sort,
              onTap: () => Navigator.of(context).pop(sort),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Sheet nhập một đầu khoảng tiền bằng [AmountKeypad] (R10). Kết quả: số tiền
/// (≥ 0) cho "Xong"; `_clearSentinel` (-1) cho "Xóa giới hạn"; null khi đóng.
class _AmountSheet extends StatefulWidget {
  const _AmountSheet({required this.minSide, required this.initial});

  final bool minSide;
  final int? initial;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  static const int _clear = -1;

  late int _amount = widget.initial ?? 0;

  String get _title =>
      widget.minSide ? 'Số tiền tối thiểu'.tr : 'Số tiền tối đa'.tr;

  void _append(int digit) => setState(() => _amount = appendAmountDigit(_amount, digit));

  void _backspace() => setState(() => _amount = backspaceAmount(_amount));

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _title,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatMoney(_amount),
                key: const ValueKey('amount-sheet-preview'),
                style: TextStyle(
                  color: colors.tealOnNeutral,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AmountKeypad(onDigit: _append, onBackspace: _backspace),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('amount-clear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(_clear),
                    child: Text('Xóa giới hạn'.tr),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    key: const ValueKey('amount-done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(_amount),
                    child: Text('Xong'.tr),
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
