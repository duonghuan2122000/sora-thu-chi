import 'category.dart';

/// Luật trình bày danh sách danh mục (màn quản lý) — module **thuần**: chỉ
/// nhận [List] đầu vào, không đọc DB/state (data-model §Bất biến). Màn danh
/// sách `01` (PBI 13) tách cấp 1 + đếm con; màn danh sách con `03` (PBI sau)
/// tái dùng [childrenOf].
///
/// Bất biến: không lọc danh mục đang ẩn khỏi màn quản lý (FR-006); con đang ẩn
/// vẫn đếm vào "N danh mục con" (FR-005). Sắp [Category.sortOrder] tăng,
/// **ổn định** (trùng sortOrder giữ thứ tự danh sách gốc — FR-004).

/// Danh mục **cấp 1** ([Category.isParent]) của [list], sắp sortOrder tăng.
List<Category> topLevelParents(List<Category> list) =>
    _sortedByOrder(list.where((c) => c.isParent).toList());

/// Con trực tiếp của cha [parentId] trong [list] — **gồm cả con đang ẩn**.
List<Category> childrenOf(List<Category> list, int parentId) =>
    _sortedByOrder(list.where((c) => c.parentId == parentId).toList());

/// Sắp [Category.sortOrder] tăng, ổn định với thứ tự danh sách gốc
/// ([List.sort] của Dart không đảm bảo stable nên phân hạng bằng chỉ số gốc).
List<Category> _sortedByOrder(List<Category> list) {
  final indexed = <(int, Category)>[];
  for (var i = 0; i < list.length; i++) {
    indexed.add((i, list[i]));
  }
  indexed.sort((a, b) {
    final byOrder = a.$2.sortOrder.compareTo(b.$2.sortOrder);
    return byOrder != 0 ? byOrder : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}
