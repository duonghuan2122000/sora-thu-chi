import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../core/budget/budget.dart';
import '../core/budget/budget_rules.dart';
import '../core/category/category.dart';
import '../core/money_format.dart';
import '../core/widgets/category_icon.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/wallet_deps.dart';
import '../data/wallet_repository.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';
import 'category_picker_screen.dart';

/// Màn Thêm/Sửa ngân sách (mockup `02`, PBI 20) — màn con: app bar teal tiêu đề
/// theo chế độ + nút chính "Lưu ngân sách" cố định chân màn, **không** bottom
/// nav (FR-008). [budget] == null → chế độ Thêm (`startDate` = [now]); khác
/// null → chế độ Sửa (điền sẵn giá trị, giữ nguyên `startDate` — FR-017).
///
/// Các hàng "Tổng cộng"/"Ví áp dụng"/"Cộng dồn phần chưa dùng hết"/"Ngưỡng cảnh
/// báo" hiển thị đúng mockup nhưng **chưa có hiệu lực** đợt này (FR-009/FR-014).
class BudgetFormScreen extends StatefulWidget {
  const BudgetFormScreen({
    super.key,
    this.budget,
    this.repository,
    this.now,
  });

  /// Khác null = chế độ Sửa ngân sách này.
  final Budget? budget;

  /// Seam test: mặc định null → [ensureWalletRepository] khi vào.
  final WalletRepository? repository;

  /// Mốc "hôm nay" cho `startDate` khi thêm mới — test bơm cố định.
  final DateTime? now;

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  late final WalletRepository _repository;
  late final DateTime _now;
  late final TextEditingController _amountCtrl;

  bool _loading = true;
  bool _saving = false;

  List<Budget> _budgets = const [];

  Category? _category;
  BudgetPeriod _period = BudgetPeriod.monthly;
  bool _isRecurring = true;

  Budget? get _existing => widget.budget;
  bool get _isEdit => _existing != null;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ensureWalletRepository();
    _now = widget.now ?? DateTime.now();
    _period = _existing?.period ?? BudgetPeriod.monthly;
    _isRecurring = _existing?.isRecurring ?? true;
    _amountCtrl = TextEditingController(
      text: _existing == null ? '' : formatAmount(_existing!.amount),
    );
    _load();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _repository.categoriesIncludingHidden(type: CategoryType.expense),
        _repository.budgets(),
      ]);
      final categories = results[0] as List<Category>;
      if (!mounted) return;
      setState(() {
        _budgets = results[1] as List<Budget>;
        _category = _existing == null
            ? null
            : _findCategory(categories, _existing!.categoryId);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  static Category? _findCategory(List<Category> list, int id) {
    for (final c in list) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> _pickCategory() async {
    final picked = await Navigator.of(context).push<Category>(
      MaterialPageRoute(
        builder: (_) => CategoryPickerScreen(
          type: CategoryType.expense,
          repository: _repository,
        ),
      ),
    );
    if (!mounted || picked == null) return;
    setState(() => _category = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    final amount = parseAmount(_amountCtrl.text);
    final error = validateBudgetForm(category: _category, amount: amount);
    if (error != null) {
      _showError(error.tr);
      return;
    }

    final candidate = Budget(
      id: _existing?.id ?? 0,
      categoryId: _category!.id,
      amount: amount,
      period: _period,
      isRecurring: _isRecurring,
      startDate: _existing?.startDate ?? _now,
    );
    // Chồng lấn (FR-016): cùng danh mục + cùng chu kỳ, khoảng hiệu lực giao nhau
    // — bỏ qua chính nó khi đang sửa.
    if (findOverlappingBudget(candidate: candidate, existing: _budgets) != null) {
      _showError(budgetOverlapMessage.tr);
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await _repository.updateBudget(candidate);
      } else {
        await _repository.insertBudget(candidate);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError('Không lưu được ngân sách. Vui lòng thử lại.'.tr);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.coral),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return SubPageScaffold(
      title: (_isEdit ? 'Sửa ngân sách' : 'Thêm ngân sách').tr,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: SizedBox(
            height: 44,
            width: double.infinity,
            child: ElevatedButton(
              key: const ValueKey('budget-save'),
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
              onPressed: _saving ? null : _save,
              child: Text('Lưu ngân sách'.tr),
            ),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _form(colors),
      ),
    );
  }

  Widget _form(SoraColors colors) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _label(colors, 'PHẠM VI NGÂN SÁCH'.tr),
        _scopeControl(colors),
        const SizedBox(height: 18),
        _label(colors, 'DANH MỤC'.tr),
        _categoryRow(colors),
        const SizedBox(height: 18),
        _label(colors, 'SỐ TIỀN GIỚI HẠN'.tr),
        _amountField(colors),
        const SizedBox(height: 18),
        _label(colors, 'CHU KỲ'.tr),
        _periodControl(colors),
        const SizedBox(height: 18),
        _valueRow(colors, 'Ví áp dụng'.tr, 'Tất cả ví'.tr),
        const SizedBox(height: 12),
        _switchTile(
          key: 'budget-recurring-switch',
          colors: colors,
          title: 'Lặp lại tự động mỗi kỳ'.tr,
          value: _isRecurring,
          onChanged: (v) => setState(() => _isRecurring = v),
        ),
        const SizedBox(height: 8),
        _switchTile(
          key: 'budget-rollover-switch',
          colors: colors,
          title: 'Cộng dồn phần chưa dùng hết'.tr,
          value: false,
          onChanged: null, // chưa có hiệu lực đợt này (FR-014).
        ),
        const SizedBox(height: 12),
        _valueRow(colors, 'Ngưỡng cảnh báo'.tr, '80% và 100%'.tr),
      ],
    );
  }

  Widget _label(SoraColors colors, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        color: colors.listLabel,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  /// 2 lựa chọn phạm vi — "Theo danh mục" chọn sẵn, "Tổng cộng" chưa hiệu lực.
  Widget _scopeControl(SoraColors colors) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 44,
        decoration: BoxDecoration(color: colors.softCardBg),
        child: Row(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.center,
                color: AppColors.teal,
                child: Text(
                  'Theo danh mục'.tr,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                key: const ValueKey('budget-scope-total'),
                onTap: () {}, // chưa có hiệu lực đợt này (FR-009).
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    'Tổng cộng'.tr,
                    style: TextStyle(
                      color: colors.tabInactive,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryRow(SoraColors colors) {
    final category = _category;
    return InkWell(
      key: const ValueKey('budget-category-row'),
      onTap: _pickCategory,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: colors.softCardBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (category != null) ...[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(category.color).withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  categoryIcon(category.icon),
                  size: 18,
                  color: Color(category.color),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                category?.name.tr ?? 'Chọn danh mục'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: category == null
                      ? colors.textSecondary
                      : colors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(Icons.expand_more, color: colors.tabInactive, size: 20),
          ],
        ),
      ),
    );
  }

  /// Ô số tiền: chỉ nhận số, định dạng phân tách nghìn ngay khi gõ, hậu tố `đ`.
  Widget _amountField(SoraColors colors) {
    return TextField(
      key: const ValueKey('budget-amount'),
      controller: _amountCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _ThousandsFormatter(),
      ],
      style: TextStyle(
        color: colors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: '0',
        suffixText: 'đ',
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _periodControl(SoraColors colors) {
    return Row(
      children: [
        for (final period in BudgetPeriod.values) ...[
          if (period != BudgetPeriod.values.first) const SizedBox(width: 10),
          Expanded(child: _periodChip(period, colors)),
        ],
      ],
    );
  }

  Widget _periodChip(BudgetPeriod period, SoraColors colors) {
    final selected = _period == period;
    return InkWell(
      key: ValueKey('budget-period-${period.name}'),
      onTap: () => setState(() => _period = period),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : colors.softCardBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          period.label,
          style: TextStyle(
            color: selected ? AppColors.white : colors.tabInactive,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Hàng chỉ đọc "nhãn — giá trị" (Ví áp dụng / Ngưỡng cảnh báo — FR-014).
  Widget _valueRow(SoraColors colors, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colors.softCardBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required String key,
    required SoraColors colors,
    required String title,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Material(
      color: colors.softCardBg,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        key: ValueKey(key),
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.teal,
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: onChanged == null
                ? colors.textSecondary
                : colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Định dạng lại nội dung ô tiền thành `3.000.000` sau mỗi lần gõ, con trỏ về
/// cuối (research R12) — dùng chung [formatAmount] với tầng hiển thị.
class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    // ponytail: chặn chuỗi dài bất thường (int64) — số tiền thật ngắn hơn nhiều.
    if (digits.length > 15) return oldValue;
    final formatted = formatAmount(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
