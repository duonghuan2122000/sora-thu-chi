import 'package:flutter/material.dart';

import '../core/category/category.dart';
import '../core/category/category_list.dart';
import '../core/widgets/category_icon.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/wallet_deps.dart';
import '../data/wallet_repository.dart';
import '../theme/app_colors.dart';

/// Màn quản lý danh mục (mockup `01`, PBI 13) — màn con từ Cài đặt: app bar
/// "Danh mục" + back + icon sắp xếp (no-op); tab tự dựng Chi tiêu / Thu nhập
/// (mặc định Chi tiêu); thân liệt kê danh mục **cấp 1** của tab (mỗi dòng
/// bubble nhạt + icon màu `category.color`, tên, dòng phụ "N danh mục con",
/// chevron); danh mục ẩn vẫn hiện đúng vị trí + nhãn "Đã ẩn"/mờ. Các điểm vào
/// (dòng / FAB "+" / icon sắp xếp) là no-op có ripple — màn đích (thêm/sửa `02`,
/// danh mục con `03`, sắp xếp `04`) ở PBI sau (FR-002/007, SC-008).
///
/// StatefulWidget nạp **cả 2 loại một lần** khi mở (FR-004/SC-003 — chuyển tab
/// lọc local, không đọc DB lại); mỗi lần vào từ Cài đặt đẩy route mới → reload
/// (FR-008). Không controller (R2); seam [repository] để test bơm fake.
class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key, this.repository});

  /// Seam test: mặc định null → [ensureWalletRepository] khi vào (R2/R11).
  final WalletRepository? repository;

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  late final WalletRepository _repository;

  bool _loading = true;
  String? _error;

  /// Cache toàn bộ danh mục 2 loại (cha + con, gồm ẩn) — nạp 1 lần (R3).
  List<Category> _expense = const [];
  List<Category> _income = const [];

  /// Tab đang chọn — mặc định Chi tiêu (expense, mockup).
  CategoryType _tab = CategoryType.expense;

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
    });
    try {
      final results = await Future.wait([
        _repository.categoriesIncludingHidden(type: CategoryType.expense),
        _repository.categoriesIncludingHidden(type: CategoryType.income),
      ]);
      if (!mounted) return;
      setState(() {
        _expense = results[0];
        _income = results[1];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không đọc được danh mục.';
        _loading = false;
      });
    }
  }

  List<Category> get _current => _tab == CategoryType.expense ? _expense : _income;

  String get _typeNoun => _tab == CategoryType.expense ? 'chi tiêu' : 'thu nhập';

  void _switchTab(CategoryType type) {
    if (_tab == type) return;
    setState(() => _tab = type);
  }

  @override
  Widget build(BuildContext context) {
    return SubPageScaffold(
      title: 'Danh mục',
      actions: [
        IconButton(
          tooltip: 'Sắp xếp',
          icon: const Icon(Icons.sort, color: AppColors.white),
          onPressed: () {}, // điểm vào màn sắp xếp `04` — PBI sau (no-op R8).
        ),
      ],
      floatingActionButton: FloatingActionButton(
        tooltip: 'Thêm danh mục',
        onPressed: () {}, // điểm vào màn thêm `02` — PBI sau (no-op R8).
        backgroundColor: AppColors.teal,
        elevation: 6,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      child: SafeArea(
        top: false,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tabRow(),
        const Divider(color: AppColors.listDivider, height: 1),
        Expanded(child: _list()),
      ],
    );
  }

  /// Hàng tab tự dựng (R6): 2 nhãn xếp trái từ lề — tab chọn teal + gạch chân,
  /// tab kia xám; vạch chia nằm dưới hàng tab (render ngoài [build]).
  /// Bọc [FittedBox] scaleDown để cỡ chữ lớn không tràn ngang (FR-011).
  Widget _tabRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _tabLabel('Chi tiêu', CategoryType.expense),
            const SizedBox(width: 48),
            _tabLabel('Thu nhập', CategoryType.income),
          ],
        ),
      ),
    );
  }

  Widget _tabLabel(String label, CategoryType type) {
    final selected = _tab == type;
    return InkWell(
      key: ValueKey('tab-$type'),
      onTap: () => _switchTab(type),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.teal : AppColors.tabInactive,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          // Gạch chân teal dưới tab đang chọn (mockup 01).
          Container(
            width: selected ? 60 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Danh sách cấp 1 của tab — danh mục ẩn vẫn hiện (FR-006); rỗng thật →
  /// empty hướng dẫn (FR-009). Không nhầm "ẩn-toàn-bộ" thành rỗng (topLevel
  /// gồm cha ẩn nên không empty giả).
  Widget _list() {
    final parents = topLevelParents(_current);
    if (parents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Text(
            'Chưa có danh mục $_typeNoun nào.\n'
            'Bạn có thể thêm mới bằng nút "+" góc dưới.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        for (final c in parents) ...[
          _row(c),
          const Divider(color: AppColors.listDivider, height: 1),
        ],
      ],
    );
  }

  Widget _row(Category c) {
    final children = childrenOf(_current, c.id);
    final hidden = c.isHidden;
    final labelColor = hidden ? AppColors.tabInactive : AppColors.textPrimary;
    final iconColor = hidden ? AppColors.tabInactive : Color(c.color);
    return InkWell(
      key: ValueKey('category-row-${c.id}'),
      onTap: () {}, // điểm vào con `03`/sửa `02` — PBI sau (no-op R8).
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            // Bubble nền nhạt phái sinh màu danh mục + icon màu đầy đủ (R5).
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color(c.color).withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(categoryIcon(c.icon), color: iconColor, size: 20),
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
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (hidden) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Đã ẩn',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (children.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${children.length} danh mục con',
                      style: const TextStyle(
                        color: AppColors.tabInactive,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.tabInactive, size: 20),
          ],
        ),
      ),
    );
  }
}
