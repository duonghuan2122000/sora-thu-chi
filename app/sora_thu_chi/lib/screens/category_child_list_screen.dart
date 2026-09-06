import 'package:flutter/material.dart';

import '../core/category/category.dart';
import '../core/category/category_list.dart';
import '../core/widgets/category_row.dart';
import '../data/wallet_deps.dart';
import '../data/wallet_repository.dart';
import '../theme/app_colors.dart';
import 'category_form_screen.dart';

/// Màn "Danh mục con" (mockup `03`, PBI 15) — liệt kê danh mục **con trực tiếp
/// cùng loại** của cha đang xem theo [Category.sortOrder]; entry từ màn danh
/// sách `01` khi chạm một danh mục **có con** (R1).
///
/// Tự dựng [Scaffold] + [AppBar] (theme teal) thay vì `SubPageScaffold` — cần
/// tiêu đề 2 dòng chạm được (R3): back trái, khối **tên cha + dòng phụ "Danh
/// mục con"** (bọc `FittedBox` + `InkWell` giữa back và "+") → chạm mở form Sửa
/// cha (cha có con nên form tự khóa loại + không mở sheet cha — màn `02` dựng
/// đủ PBI 14); "+" phải mở form Thêm con preset (R5). Body [ListView]: từng con
/// là [CategoryRow] (subtitle null — con cấp 2 không có con) + hàng cuối
/// "Thêm danh mục con". Chạm con → form Sửa con (R7).
///
/// Nạp **1 loại** `categoriesIncludingHidden(type: cha)` khi mở (SC-001 — con
/// cùng loại cha, không lẫn); cha hiển thị **derive** từ list theo id (tiêu đề
/// tươi sau đổi tên — FR-009). Sau mỗi pop form reload lặng 1 loại + derive lại
/// cha (R8): thêm/sửa/ẩn phản ánh ngay, con đổi cha rời nhóm cũ (FR-010).
/// Empty phòng thủ khi cha hết con — vẫn giữ "+"/hàng Thêm (R9). Không bottom
/// nav, không số tiền.
class CategoryChildListScreen extends StatefulWidget {
  const CategoryChildListScreen({
    super.key,
    required this.parent,
    this.repository,
  });

  /// Cha đang xem (danh mục gốc có con — entry từ màn `01`).
  final Category parent;

  /// Seam test: mặc định null → [ensureWalletRepository] khi vào.
  final WalletRepository? repository;

  @override
  State<CategoryChildListScreen> createState() =>
      _CategoryChildListScreenState();
}

class _CategoryChildListScreenState extends State<CategoryChildListScreen> {
  late final WalletRepository _repository;

  bool _loading = true;
  String? _error;

  /// Cache danh mục **1 loại** (cha + con của loại cha, gồm ẩn) — nạp 1 lần.
  List<Category> _list = const [];

  /// Cha hiển thị — derive từ [_list] theo id để tiêu đề tươi (FR-009).
  late Category _parent;

  List<Category> get _children => childrenOf(_list, _parent.id);

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ensureWalletRepository();
    _parent = widget.parent;
    _load();
  }

  Category _deriveParent(List<Category> list) {
    for (final c in list) {
      if (c.id == widget.parent.id) return c;
    }
    return widget.parent; // Không xóa danh mục — cha luôn tồn tại (phòng thủ).
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repository.categoriesIncludingHidden(
        type: widget.parent.type,
      );
      if (!mounted) return;
      setState(() {
        _list = list;
        _parent = _deriveParent(list);
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

  /// Reload lặng sau mỗi pop form — dữ liệu phản ánh ngay (R8/FR-009/010),
  /// không spinner (pattern `_reloadSilent` màn `01`).
  Future<void> _reloadSilent() async {
    try {
      final list = await _repository.categoriesIncludingHidden(
        type: widget.parent.type,
      );
      if (!mounted) return;
      setState(() {
        _list = list;
        _parent = _deriveParent(list);
      });
    } catch (_) {
      // Giữ dữ liệu cũ — lỗi đọc nền không đáng ngắt màn.
    }
  }

  /// Push form (Thêm preset / Sửa con / Sửa cha) rồi reload lặng khi về.
  Future<void> _openForm({
    CategoryType? initialType,
    int? initialParentId,
    Category? category,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryFormScreen(
          initialType: initialType,
          initialParentId: initialParentId,
          category: category,
          repository: _repository,
        ),
      ),
    );
    if (!mounted) return;
    await _reloadSilent();
  }

  void _editChild(Category child) => _openForm(category: child);

  void _editParent() => _openForm(category: _parent);

  void _addChild() => _openForm(
    initialType: widget.parent.type,
    initialParentId: widget.parent.id,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Khối tiêu đề = điểm sửa danh mục cha (R3): nằm giữa back và "+",
        // không đè 2 nút — AppBar bố trí leading/actions riêng.
        title: InkWell(
          key: const ValueKey('parent-title'),
          onTap: _editParent,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _parent.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Danh mục con',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            key: const ValueKey('add-child'),
            tooltip: 'Thêm danh mục con',
            onPressed: _addChild,
            icon: const Icon(Icons.add, color: AppColors.white),
          ),
        ],
      ),
      body: SafeArea(top: false, child: _body()),
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
    final children = _children;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (children.isEmpty)
          // Empty phòng thủ (cha hết con — toàn bộ chuyển cha) — vẫn giữ "+"
          // (app bar) và hàng Thêm bên dưới (R9, không lỗi).
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 8),
            child: Text(
              'Chưa có danh mục con nào.\n'
              'Thêm bằng nút "+" góc phải hoặc hàng bên dưới.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          )
        else
          for (final c in children) ...[
            CategoryRow(category: c, onTap: () => _editChild(c)),
            const Divider(color: AppColors.listDivider, height: 1),
          ],
        _addChildRow(),
      ],
    );
  }

  /// Hàng cuối "Thêm danh mục con" (FR-008/acceptance 6) — điểm thêm trong list.
  Widget _addChildRow() {
    return InkWell(
      key: const ValueKey('add-child-row'),
      onTap: _addChild,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.teal, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Thêm danh mục con',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.teal,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
