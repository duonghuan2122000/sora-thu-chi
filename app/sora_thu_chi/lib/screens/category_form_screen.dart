import 'package:flutter/material.dart';

import '../core/category/category.dart';
import '../core/category/category_form.dart';
import '../core/category/category_list.dart';
import '../core/category/category_presets.dart';
import '../core/widgets/category_icon.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/wallet_deps.dart';
import '../data/wallet_repository.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';

/// Màn thêm/sửa danh mục (mockup `02`, PBI 14) — màn con: app bar teal tiêu đề
/// theo chế độ + nút "Lưu" góc phải, nút chính "Lưu danh mục" cố định chân màn,
/// **không** bottom nav. [category] == null → chế độ Thêm (loại mặc định theo
/// [initialType] — tab màn danh sách lúc chạm FAB); != null → chế độ Sửa
/// (prefill 100% + luật khóa — đổi loại chỉ khi gốc sạch không con chưa gd,
/// đổi cha không áp dụng khi có con; FR-002/008).
///
/// Route độc quyền (offline) nên snapshot cache nạp 1 lần lúc mở là trạng thái
/// đúng lúc lưu (R8); cờ [_saving] chặn lưu trùng khi chạm nhanh (FR-011).
class CategoryFormScreen extends StatefulWidget {
  const CategoryFormScreen({
    super.key,
    this.initialType,
    this.initialParentId,
    this.category,
    this.repository,
  });

  /// Loại mặc định chế độ Thêm (lấy từ tab màn danh sách lúc chạm FAB).
  final CategoryType? initialType;

  /// Cha preset chế độ Thêm (PBI 15 — thêm nhanh danh mục con từ màn `03`):
  /// khởi tạo ô cha bằng id cha đang xem. Chỉ là giá trị khởi tạo — người dùng
  /// vẫn đổi cha/loại theo ràng buộc form (đổi loại → cha về "Không có").
  final int? initialParentId;

  /// Khác null = chế độ Sửa danh mục này.
  final Category? category;

  /// Seam test: mặc định null → [ensureWalletRepository] khi vào.
  final WalletRepository? repository;

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  /// Sentinel sheet cha cho mục "Không có — là danh mục gốc" (id cha > 0); pop
  /// null = đóng/backdrop → giữ nguyên, không phân biệt được "bỏ cha".
  static const int _clearParent = -1;

  late final WalletRepository _repository;
  late final TextEditingController _nameCtrl;

  bool _loading = true;
  String? _error;
  bool _saving = false;

  List<Category> _expenseCats = const [];
  List<Category> _incomeCats = const [];

  late CategoryType _type;
  late String _icon;
  late int _colorValue;
  int? _parentId;
  bool _isHidden = false;
  bool _hasTransactions = false;

  Category? get _existing => widget.category;
  bool get _isEdit => _existing != null;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ensureWalletRepository();
    _type = widget.category?.type ?? widget.initialType ?? CategoryType.expense;
    _nameCtrl = TextEditingController(text: widget.category?.name ?? '');
    _icon = widget.category?.icon ?? defaultIconFor(_type);
    _colorValue = widget.category?.color ?? defaultColorFor(_type);
    // Sửa (`category.parentId`) thắng preset; Thêm dùng initialParentId (PBI 15);
    // không truyền → null = danh mục gốc (hành vi cũ PBI 14).
    _parentId = widget.category?.parentId ?? widget.initialParentId;
    _isHidden = widget.category?.isHidden ?? false;
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  List<Category> _listOf(CategoryType type) =>
      type == CategoryType.expense ? _expenseCats : _incomeCats;

  /// Nhóm (type + parentId) — nguồn so trùng tên & tính sortOrder cuối nhóm.
  List<Category> _groupOf(CategoryType type, int? parentId) =>
      _listOf(type).where((c) => c.parentId == parentId).toList();

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _repository.categoriesIncludingHidden(type: CategoryType.expense),
        _repository.categoriesIncludingHidden(type: CategoryType.income),
      ]);
      final hasTxn = _isEdit
          ? await _repository.categoryHasTransactions(_existing!.id)
          : false;
      if (!mounted) return;
      setState(() {
        _expenseCats = results[0];
        _incomeCats = results[1];
        _hasTransactions = hasTxn;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không đọc được danh mục.';
        _loading = false;
      });
    }
  }

  /// Sửa mà đang sửa danh mục **có con** — nguồn khóa (có con phải luôn gốc).
  bool get _editHasChildren {
    if (!_isEdit) return false;
    return childrenOf(_listOf(_existing!.type), _existing!.id).isNotEmpty;
  }

  /// Đổi loại: Thêm luôn được; Sửa chỉ khi gốc sạch (chưa gd, không con, gốc).
  bool get _canSwitchType {
    if (!_isEdit) return true;
    return canChangeType(
      hasTransactions: _hasTransactions,
      hasChildren: _editHasChildren,
      isParent: _existing!.isParent,
    );
  }

  /// Chọn cha mới: chặn khi danh mục đang sửa **có con** (giữ cây 2 cấp).
  bool get _canPickParent => !_isEdit || !_editHasChildren;

  String get _typeNoun => _type == CategoryType.expense ? 'Chi tiêu' : 'Thu nhập';

  void _switchType(CategoryType next) {
    if (_type == next || !_canSwitchType) return;
    setState(() {
      _type = next;
      // Đổi loại → cha cũ (khác loại) không còn hợp lệ → về "Không có".
      _parentId = null;
    });
  }

  Future<void> _pickParent() async {
    if (!_canPickParent) return;
    final options = parentsOfType(_listOf(_type));
    final id = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final colors = SoraColors.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text(
                  'Chọn danh mục cha',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
                    _sheetParentRow(
                      sheetContext,
                      key: const ValueKey('parent-none'),
                      icon: null,
                      color: null,
                      label: 'Không có — là danh mục gốc',
                      value: _clearParent,
                    ),
                    for (final c in options)
                      if (!_isEdit || c.id != _existing!.id)
                        _sheetParentRow(
                          sheetContext,
                          key: ValueKey('parent-${c.id}'),
                          icon: categoryIcon(c.icon),
                          color: Color(c.color),
                          label: c.name,
                          value: c.id,
                        ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || id == null) return; // Đóng/backdrop → giữ nguyên lựa chọn.
    setState(() => _parentId = id == _clearParent ? null : id);
  }

  Widget _sheetParentRow(
    BuildContext sheetContext, {
    required Key key,
    required IconData? icon,
    required Color? color,
    required String label,
    required int? value,
  }) {
    final colors = SoraColors.of(sheetContext);
    return InkWell(
      key: key,
      onTap: () => Navigator.of(sheetContext).pop(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            if (icon != null)
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color!.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              )
            else
              Icon(Icons.block, color: colors.tabInactive, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value == null || value == _clearParent
                      ? colors.textSecondary
                      : colors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Category _buildCategory() {
    final existing = _existing;
    // Cùng nhóm (type + cha) → giữ sortOrder cũ; Thêm / đổi nhóm → cuối nhóm.
    final sameGroup =
        existing != null &&
        existing.type == _type &&
        existing.parentId == _parentId;
    final sortOrder = (existing != null && sameGroup)
        ? existing.sortOrder
        : endOfGroupSortOrder(_groupOf(_type, _parentId));
    return Category(
      id: existing?.id ?? 0,
      name: _nameCtrl.text.trim(),
      type: _type,
      icon: _icon,
      color: _colorValue,
      parentId: _parentId,
      sortOrder: sortOrder,
      isHidden: _isHidden,
      isSystem: existing?.isSystem ?? false,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final category = _buildCategory();
    try {
      final saved = _isEdit
          ? await _repository.updateCategory(category)
          : await _repository.insertCategory(category);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (_) {
      if (!mounted) return;
      // FR-011: báo lỗi, giữ nguyên dữ liệu đã nhập.
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không lưu được danh mục. Vui lòng thử lại.'),
          backgroundColor: AppColors.coral,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final title = _isEdit ? 'Sửa danh mục' : 'Thêm danh mục';
    return SubPageScaffold(
      title: title,
      actions: [
        TextButton(
          key: const ValueKey('save-appbar'),
          onPressed: _saving ? null : _save,
          child: const Text(
            'Lưu',
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: SizedBox(
            height: 44,
            width: double.infinity,
            child: ElevatedButton(
              key: const ValueKey('save-primary'),
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
              child: const Text('Lưu danh mục'),
            ),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: _body(colors),
      ),
    );
  }

  Widget _body(SoraColors colors) {
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
            OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _typeControl(colors),
          const SizedBox(height: 16),
          _fieldLabel(colors, 'Tên danh mục'),
          TextFormField(
            key: const ValueKey('field-name'),
            controller: _nameCtrl,
            maxLength: 30,
            decoration: InputDecoration(
              hintText: 'VD: Ăn sáng, Xăng xe…',
              counterText: '',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            textInputAction: TextInputAction.done,
            validator: (v) => categoryNameError(
              raw: v ?? '',
              siblings: _groupOf(_type, _parentId),
              excludeId: _existing?.id,
            ),
          ),
          const SizedBox(height: 16),
          _fieldLabel(colors, 'Biểu tượng'),
          _IconPicker(selected: _icon, onChanged: (v) => setState(() => _icon = v)),
          const SizedBox(height: 16),
          _fieldLabel(colors, 'Màu sắc'),
          _ColorPicker(
            selected: _colorValue,
            onChanged: (v) => setState(() => _colorValue = v),
          ),
          const SizedBox(height: 16),
          _parentField(colors),
          const SizedBox(height: 12),
          _HiddenSwitch(
            value: _isHidden,
            onChanged: (v) => setState(() => _isHidden = v),
          ),
        ],
      ),
    );
  }

  Widget _typeControl(SoraColors colors) {
    if (!_canSwitchType) {
      // Readonly box — loại không đổi được (khóa, FR-002/008), tỏ rõ không mồi.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fieldLabel(colors, 'Loại danh mục'),
          _ReadonlyBox(_typeNoun),
        ],
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 44,
        decoration: BoxDecoration(color: colors.softCardBg),
        child: Row(
          children: [
            _pillHalf('Chi tiêu', CategoryType.expense, colors),
            _pillHalf('Thu nhập', CategoryType.income, colors),
          ],
        ),
      ),
    );
  }

  Widget _pillHalf(String label, CategoryType type, SoraColors colors) {
    final selected = _type == type;
    return Expanded(
      child: InkWell(
        key: ValueKey('type-pill-${type.name}'),
        onTap: () => _switchType(type),
        child: Container(
          alignment: Alignment.center,
          color: selected ? AppColors.teal : Colors.transparent,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.white : colors.tabInactive,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _parentField(SoraColors colors) {
    String valueText = 'Không có — là danh mục gốc';
    Category? parent;
    if (_parentId != null) {
      for (final c in _listOf(_type)) {
        if (c.id == _parentId) {
          parent = c;
          break;
        }
      }
      if (parent != null) valueText = parent.name;
    }
    final color = _canPickParent ? colors.tealOnNeutral : colors.tabInactive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(colors, 'Danh mục cha (tùy chọn)'),
        InkWell(
          key: const ValueKey('parent-field'),
          onTap: _canPickParent ? _pickParent : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: colors.softCardBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    valueText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: parent == null
                          ? colors.textSecondary
                          : colors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(Icons.expand_more, color: color, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Nhãn mục nhỏ xám (bên trên từng trường) — pattern form ví.
Widget _fieldLabel(SoraColors colors, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(
    text,
    style: TextStyle(
      color: colors.listLabel,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  ),
);

class _ReadonlyBox extends StatelessWidget {
  const _ReadonlyBox(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colors.softCardBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: colors.textSecondary, fontSize: 15),
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final key in categoryIconChoices)
          InkWell(
            key: ValueKey('icon-opt-$key'),
            onTap: () => onChanged(key),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: key == selected
                    ? colors.tealLightBg
                    : colors.softCardBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: key == selected ? colors.tealOnNeutral : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(categoryIcon(key), size: 20, color: colors.textPrimary),
            ),
          ),
      ],
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < categoryPresetColors.length; i++)
          Builder(builder: (context) {
            final color = categoryPresetColors[i];
            final isSelected = color == selected;
            return InkWell(
              key: ValueKey('color-opt-$i'),
              onTap: () => onChanged(color),
              borderRadius: BorderRadius.circular(17),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Color(color),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colors.textPrimary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: AppColors.white)
                    : null,
              ),
            );
          }),
      ],
    );
  }
}

class _HiddenSwitch extends StatelessWidget {
  const _HiddenSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Material(
      color: colors.softCardBg,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        key: const ValueKey('switch-hidden'),
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.teal,
        title: Text(
          'Ẩn khỏi danh sách nhanh',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Vẫn giữ trên giao dịch lịch sử và màn danh mục.',
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
      ),
    );
  }
}
