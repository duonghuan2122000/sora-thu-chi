import 'package:flutter/material.dart';

import '../core/category/category.dart';
import '../core/category/category_list.dart';
import '../core/category/category_sort.dart';
import '../core/widgets/category_row.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/wallet_deps.dart';
import '../data/wallet_repository.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';

/// Màn "Sắp xếp danh mục" (mockup `04`, PBI 16) — màn con từ màn danh sách danh
/// mục `01` khi chạm icon Sắp xếp (no-op PBI 13 → kích hoạt): app bar teal back
/// (trái) + tiêu đề "Sắp xếp danh mục" + nút "Xong" (phải); body
/// `ReorderableListView` liệt kê **danh mục cha cấp 1 của đúng loại**
/// [initialType] theo `sortOrder` hiện tại. Mỗi dòng [CategoryRow] + tay cầm
/// kéo–thả trái (kéo chỉ từ tay cầm — [ReorderableDragStartListener], không
/// drag long-press cả dòng), không chevron; danh mục ẩn/hệ thống vẫn hiện +
/// sắp được (FR-004). Thả → hoán vị local + ghi **ngay** qua `reorderCategories`
/// (FR-006); "Xong"/back chỉ pop — đã ghi khi thả nên không xác nhận (FR-008).
/// Không tab riêng, không bottom nav, không số tiền, không danh mục con.
///
/// Nạp **1 loại** một lần khi mở (SC-001); [repository] seam test (mặc định
/// [ensureWalletRepository]) — bơm fake để assert thứ tự store sau kéo (R7).
class CategorySortScreen extends StatefulWidget {
  const CategorySortScreen({
    super.key,
    required this.initialType,
    this.repository,
  });

  /// Loại danh mục đang mở ở màn `01` khi vào — chỉ sắp nhóm cha của loại này.
  final CategoryType initialType;

  final WalletRepository? repository;

  @override
  State<CategorySortScreen> createState() => _CategorySortScreenState();
}

class _CategorySortScreenState extends State<CategorySortScreen> {
  late final WalletRepository _repository;

  bool _loading = true;
  String? _error;

  /// Cha cấp 1 của [widget.initialType] theo thứ tự hiển thị — nguồn kéo–thả.
  List<Category> _rows = const [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ensureWalletRepository();
    _load();
  }

  String get _typeNoun =>
      widget.initialType == CategoryType.expense ? 'chi tiêu' : 'thu nhập';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repository.categoriesIncludingHidden(
        type: widget.initialType,
      );
      if (!mounted) return;
      setState(() {
        _rows = topLevelParents(list);
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

  /// Ghi thứ tự mới **ngay khi thả** (FR-006); lỗi ghi hiếm (DB local) → nạp
  /// lại về thứ tự DB cho đồng bộ (R7) — không dialog phức tạp.
  Future<void> _persist() async {
    try {
      await _repository.reorderCategories(
        orderedIds: [for (final c in _rows) c.id],
      );
    } catch (_) {
      if (!mounted) return;
      await _load();
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    final moved = moveCategoryAt(_rows, oldIndex, newIndex);
    if (identical(moved, _rows)) return; // thả đúng vị trí cũ — không ghi thừa.
    setState(() => _rows = moved);
    _persist();
  }

  void _done() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return SubPageScaffold(
      title: 'Sắp xếp danh mục',
      actions: [
        TextButton(
          key: const ValueKey('sort-done'),
          onPressed: _done,
          style: TextButton.styleFrom(foregroundColor: AppColors.white),
          child: const Text('Xong'),
        ),
      ],
      child: SafeArea(top: false, child: _body(colors)),
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
    if (_rows.isEmpty) {
      // Empty phòng thủ (dữ liệu bất thường) — seed danh mục hệ thống đảm bảo
      // mỗi loại luôn có ≥ 1 cha (spec Giả định).
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Text(
            'Không có danh mục $_typeNoun nào để sắp xếp.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: _rows.length,
      itemBuilder: (context, index) {
        final c = _rows[index];
        // Dòng + vạch chia là MỘT item (Column) — Reorderable di cả khối, giữ
        // index-math đúng; kéo chỉ từ tay cầm qua ReorderableDragStartListener.
        return Column(
          key: ValueKey('sort-row-${c.id}'),
          children: [
            CategoryRow(
              category: c,
              leading: ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Icon(
                    Icons.drag_handle,
                    color: colors.tabInactive,
                    size: 20,
                  ),
                ),
              ),
              showChevron: false,
              onTap: () {},
            ),
            Divider(color: colors.listDivider, height: 1),
          ],
        );
      },
      proxyDecorator: (child, index, animation) => Material(
        color: Colors.transparent,
        elevation: 6,
        borderRadius: BorderRadius.circular(10),
        child: child,
      ),
      // onReorderItem (SDK mới): framework đã trừ newIndex khi kéo xuống.
      onReorderItem: _onReorder,
    );
  }
}
