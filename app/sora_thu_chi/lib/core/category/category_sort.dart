import 'category.dart';

/// Helper thuần index-math của kéo–thả (màn sắp xếp `04`, PBI 16) — đúng ngữ
/// nghĩa `ReorderableListView.onReorderItem` (SDK mới thay `onReorder`): bỏ
/// item ở [oldIndex] rồi chèn vào [newIndex] — là vị trí trong list **đã ngắn
/// đi một** (framework tự trừ 1 khi kéo xuống, không cần xử lý ở đây). Không
/// đọc DB; trả list mới, **không** mutate list gốc (dữ liệu bất biến — tránh
/// setState cùng tham chiếu). `oldIndex == newIndex` → trả về chính [list]
/// (framework không gọi khi thả đúng vị trí cũ; giữ guard phòng thủ).
List<Category> moveCategoryAt(
  List<Category> list,
  int oldIndex,
  int newIndex,
) {
  if (oldIndex == newIndex) return list;
  final moved = List<Category>.of(list);
  final item = moved.removeAt(oldIndex);
  moved.insert(newIndex, item);
  return moved;
}
