import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/category/category_sort.dart';

/// Danh mục tưởng tượng (id tuần tự 1..n) — chỉ cần [Category.isParent] để
/// chạy helper thuần, không đụng DB/fake/widget (R7).
Category _c(int id) => Category(
  id: id,
  name: 'C$id',
  type: CategoryType.expense,
  icon: 'category',
  color: 0xFF0F6E56,
  sortOrder: id - 1,
);

/// Tên theo thứ tự list hiện tại — assert index-math gọn.
List<String> _names(List<Category> list) => [for (final c in list) c.name];

/// Danh sách seed ban đầu "C1..Cn".
List<Category> _seed(int n) => [for (var i = 1; i <= n; i++) _c(i)];

void main() {
  // newIndex truyền vào helper là vị trí trong list ĐÃ bỏ item cũ —
  // `ReorderableListView.onReorderItem` (SDK mới) tự trừ 1 khi kéo xuống,
  // khác `onReorder` cũ phải trừ thủ công (bám research R7, cập nhật theo API).
  group('moveCategoryAt — index-math ReorderableListView.onReorderItem', () {
    test('kéo lên: old 3 → new 0 — phần tử về đầu, các phần tử dạt xuống', () {
      final moved = moveCategoryAt(_seed(5), 3, 0);
      expect(_names(moved), ['C4', 'C1', 'C2', 'C3', 'C5']);
    });

    test('kéo xuống: old 0 → new 3 — framework trừ về 2, chèn sau 2 phần tử', () {
      final moved = moveCategoryAt(_seed(5), 0, 2);
      expect(_names(moved), ['C2', 'C3', 'C1', 'C4', 'C5']);
    });

    test('kéo qua nhiều dòng cách xa — hoán vị đúng', () {
      final moved = moveCategoryAt(_seed(6), 1, 4);
      expect(_names(moved), ['C1', 'C3', 'C4', 'C5', 'C2', 'C6']);
    });

    test('thả cuối danh sách: old 1 → new == length trừ về 5 — về cuối', () {
      final moved = moveCategoryAt(_seed(6), 1, 5);
      expect(_names(moved), ['C1', 'C3', 'C4', 'C5', 'C6', 'C2']);
    });

    test('oldIndex == newIndex — list giữ nguyên (guard phòng thủ)', () {
      final list = _seed(4);
      final moved = moveCategoryAt(list, 2, 2);
      expect(identical(moved, list), isTrue);
      expect(_names(list), ['C1', 'C2', 'C3', 'C4']);
    });

    test('không mutate list gốc khi có hoán vị', () {
      final list = _seed(5);
      final original = List<Category>.of(list);
      final moved = moveCategoryAt(list, 0, 2);
      expect(identical(moved, list), isFalse);
      expect(_names(list), _names(original));
      expect(_names(moved), isNot(_names(original)));
    });

    test('danh sách 1 phần tử kéo không lỗi (edge)', () {
      final moved = moveCategoryAt(_seed(1), 0, 0);
      expect(_names(moved), ['C1']);
    });
  });
}
