import 'package:flutter/material.dart';

import '../core/category/category.dart';
import '../core/category/category_list.dart';
import '../core/widgets/category_row.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/wallet_deps.dart';
import '../data/wallet_repository.dart';
import '../theme/app_colors.dart';
import 'category_child_list_screen.dart';
import 'category_form_screen.dart';

/// Màn quản lý danh mục (mockup `01`, PBI 13/15) — màn con từ Cài đặt: app bar
/// "Danh mục" + back + icon sắp xếp (no-op — màn `04` PBI sau); tab tự dựng Chi
/// tiêu / Thu nhập (mặc định Chi tiêu); thân liệt kê danh mục **cấp 1** của tab
/// (dòng dùng chung [CategoryRow]: bubble nhạt + icon màu `category.color`, tên,
/// dòng phụ "N danh mục con" **chỉ khi có con**, chevron); danh mục ẩn vẫn hiện
/// đúng vị trí + nhãn "Đã ẩn"/mờ. Chạm dòng: **không con** → form thêm/sửa `02`
/// (PBI 14); **có con** → màn danh mục con `03` (PBI 15) rồi reload lặng khi về
/// (FR-001/011). FAB "+" thêm danh mục gốc; icon sắp xếp no-op (màn `04` sau).
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

  /// Mở form Thêm ([initialType]) / Sửa ([category]) rồi **refresh lặng** cả 2
  /// loại khi về — dữ liệu mới phản ánh ngay (FR-009/SC-003/006), không spinner
  /// (R1). FAB có thể đổi loại trước lưu → nạp lại cả 2 loại.
  Future<void> _openForm({CategoryType? initialType, Category? category}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryFormScreen(
          initialType: initialType,
          category: category,
          repository: _repository,
        ),
      ),
    );
    if (!mounted) return;
    await _reloadSilent();
  }

  Future<void> _reloadSilent() async {
    try {
      final results = await Future.wait([
        _repository.categoriesIncludingHidden(type: CategoryType.expense),
        _repository.categoriesIncludingHidden(type: CategoryType.income),
      ]);
      if (!mounted) return;
      setState(() {
        _expense = results[0];
        _income = results[1];
      });
    } catch (_) {
      // Giữ dữ liệu cũ — lỗi đọc nền không đáng ngắt màn.
    }
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
        onPressed: () => _openForm(initialType: _tab),
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
    final childCount = childrenOf(_current, c.id).length;
    return CategoryRow(
      category: c,
      // Dòng phụ đếm con chỉ khi cha **có** con (FR-005) — trích dùng chung R4.
      subtitle: childCount == 0 ? null : '$childCount danh mục con',
      onTap: () => _onRowTap(c),
    );
  }

  /// Chạm dòng cấp 1: **có con** → màn danh mục con `03` (R1/FR-001) rồi reload
  /// lặng khi về (số con/tên cha phản ánh — FR-011/acceptance 8); **không con**
  /// → form Sửa `02` (PBI 14, giữ).
  Future<void> _onRowTap(Category c) async {
    if (childrenOf(_current, c.id).isEmpty) {
      await _openForm(category: c);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryChildListScreen(parent: c, repository: _repository),
      ),
    );
    if (!mounted) return;
    await _reloadSilent();
  }
}
