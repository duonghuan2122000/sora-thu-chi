import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/category/category.dart';
import '../core/widgets/category_icon.dart';
import '../data/wallet_deps.dart';
import '../data/wallet_repository.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';

/// Màn chọn danh mục (mockup `03`, R5) — lưới 4 cột danh mục **cha** đang hoạt
/// động của [type]; chạm cha có con → bật vùng "DANH MỤC CON: TÊN_CHA" ngay dưới
/// lưới (cùng màn, không route con); chạm cha không con / con → chọn và
/// `pop(Category)`. Ô cuối lưới "Thêm mới" là điểm vào module Danh mục — no-op.
/// Màn con đè shell: [Scaffold] riêng, không bottom nav.
class CategoryPickerScreen extends StatefulWidget {
  const CategoryPickerScreen({
    super.key,
    required this.type,
    this.repository,
  });

  final CategoryType type;

  /// Seam test: mặc định null → [ensureWalletRepository] khi vào (R11).
  final WalletRepository? repository;

  @override
  State<CategoryPickerScreen> createState() => _CategoryPickerScreenState();
}

class _CategoryPickerScreenState extends State<CategoryPickerScreen> {
  late final WalletRepository _repository;
  bool _loading = true;
  String? _error;
  List<Category> _categories = const [];

  /// Cha đang khoan xuống con (có con). null = chưa chọn cha có con.
  Category? _selectedParent;

  CategoryType get _type => widget.type;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ensureWalletRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedParent = null;
    });
    try {
      final list = await _repository.categories(type: _type);
      if (!mounted) return;
      setState(() {
        _categories = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không đọc được danh mục.'.tr;
        _loading = false;
      });
    }
  }

  List<Category> get _parents =>
      _categories.where((c) => c.isParent).toList();

  List<Category> _childrenOf(Category parent) =>
      _categories.where((c) => c.parentId == parent.id).toList();

  void _onTapCategory(Category category) {
    // Cha có con → khoan xuống (không chọn); cha không con / con → chọn luôn.
    if (category.isParent && _childrenOf(category).isNotEmpty) {
      setState(() {
        _selectedParent =
            _selectedParent?.id == category.id ? null : category;
      });
      return;
    }
    Navigator.of(context).pop(category);
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Chọn danh mục'.tr)),
      body: SafeArea(
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
            OutlinedButton(onPressed: _load, child: Text('Thử lại'.tr)),
          ],
        ),
      );
    }
    final parents = _parents;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        if (parents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              [
                'Chưa có danh mục cho loại này.'.tr,
                'Bạn có thể thêm mới từ màn danh mục.'.tr,
              ].join('\n'),
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          )
        else
          _grid(colors, parents),
        if (_selectedParent case final parent?)
          _childSection(colors, parent),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Lưới danh mục cha 4 cột (Wrap — không cắt ô khi cỡ chữ lớn) + ô "Thêm mới".
  Widget _grid(SoraColors colors, List<Category> parents) {
    const spacing = 8.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - spacing * 3) / 4;
        return Wrap(
          spacing: spacing,
          runSpacing: 16,
          children: [
            for (final c in parents)
              _gridCell(
                colors,
                width: cellWidth,
                onTap: () => _onTapCategory(c),
                icon: categoryIcon(c.icon),
                color: Color(c.color),
                label: c.name.tr,
              ),
            _gridCell(
              colors,
              width: cellWidth,
              onTap: () {}, // "Thêm mới" — module Danh mục sau, no-op (R5).
              addNew: true,
            ),
          ],
        );
      },
    );
  }

  Widget _gridCell(
    SoraColors colors, {
    required double width,
    required VoidCallback onTap,
    IconData? icon,
    Color? color,
    String? label,
    bool addNew = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: addNew
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.dotEmpty,
                        width: 1.5,
                      ),
                    )
                  : BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
              child: addNew
                  ? Icon(Icons.add, color: colors.tealOnNeutral, size: 24)
                  : Icon(icon, color: AppColors.white, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label ?? 'Thêm mới'.tr,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: addNew ? FontWeight.w600 : FontWeight.w400,
                color: addNew ? colors.listLabel : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Vùng "DANH MỤC CON: TÊN_CHA" (mockup `03`) — các con chọn được ngay dưới.
  Widget _childSection(SoraColors colors, Category parent) {
    final children = _childrenOf(parent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Divider(color: colors.listDivider, height: 1),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'DANH MỤC CON: @tên'.trParams({
              'tên': parent.name.tr.toUpperCase(),
            }),
            style: TextStyle(
              color: colors.tabInactive,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (final child in children)
          InkWell(
            key: ValueKey('category-child-${child.name}'),
            onTap: () => Navigator.of(context).pop(child),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color(child.color),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      categoryIcon(child.icon),
                      color: AppColors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    child.name.tr,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
