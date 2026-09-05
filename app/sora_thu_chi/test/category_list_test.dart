import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/category/category_list.dart';

/// Category helper — seed thủ công (không sqlite), id/type/color tùy biến.
Category _cat(
  int id, {
  String name = '',
  CategoryType type = CategoryType.expense,
  int? parentId,
  int sortOrder = 0,
  bool isHidden = false,
}) {
  return Category(
    id: id,
    name: name.isEmpty ? 'Danh mục $id' : name,
    type: type,
    icon: 'category',
    color: 0xFF0F6E56,
    parentId: parentId,
    sortOrder: sortOrder,
    isHidden: isHidden,
  );
}

void main() {
  group('topLevelParents', () {
    test('chỉ giữ cấp 1 (isParent), bỏ con', () {
      final list = [
        _cat(1, sortOrder: 0),
        _cat(2, parentId: 1, sortOrder: 0),
        _cat(3, parentId: 1, sortOrder: 1),
        _cat(4, sortOrder: 1),
      ];
      final result = topLevelParents(list);
      expect(result.map((c) => c.id), [1, 4]);
    });

    test('cha đang ẩn vẫn giữ — không lọc ẩn (SC-004)', () {
      final list = [_cat(5, isHidden: true), _cat(6, parentId: 5)];
      final result = topLevelParents(list);
      expect(result.map((c) => c.id), [5]);
    });

    test('sắp sortOrder tăng', () {
      final list = [
        _cat(9, sortOrder: 3),
        _cat(8, sortOrder: 1),
        _cat(7, sortOrder: 2),
      ];
      expect(topLevelParents(list).map((c) => c.id), [8, 7, 9]);
    });

    test('ổn định khi trùng sortOrder — giữ thứ tự danh sách gốc (FR-004)', () {
      final list = [_cat(1, sortOrder: 0), _cat(2, sortOrder: 0), _cat(3, sortOrder: 0)];
      expect(topLevelParents(list).map((c) => c.id), [1, 2, 3]);
    });

    test('rỗng → rỗng (không lỗi)', () {
      expect(topLevelParents(const []), isEmpty);
    });
  });

  group('childrenOf', () {
    test('trả đúng con của 1 cha, sắp sortOrder', () {
      final list = [
        _cat(1),
        _cat(2, parentId: 1, sortOrder: 1),
        _cat(3, parentId: 1, sortOrder: 0),
        _cat(4, parentId: 5),
      ];
      expect(childrenOf(list, 1).map((c) => c.id), [3, 2]);
    });

    test('đếm gồm con đang ẩn (FR-005 edge)', () {
      final list = [
        _cat(1),
        _cat(2, parentId: 1),
        _cat(3, parentId: 1, isHidden: true),
      ];
      expect(childrenOf(list, 1).map((c) => c.id), [2, 3]);
    });

    test('không con → rỗng (dòng phụ bỏ trống)', () {
      final list = [_cat(1), _cat(2, parentId: 99)];
      expect(childrenOf(list, 1), isEmpty);
    });

    test('con của cha A không lẫn con cha B', () {
      final list = [
        _cat(1),
        _cat(2, parentId: 1),
        _cat(3, parentId: 7),
        _cat(4, parentId: 7),
      ];
      expect(childrenOf(list, 7).map((c) => c.id), [3, 4]);
    });

    test('ổn định khi trùng sortOrder', () {
      final list = [
        _cat(1),
        _cat(2, parentId: 1),
        _cat(3, parentId: 1),
        _cat(4, parentId: 1),
      ];
      expect(childrenOf(list, 1).map((c) => c.id), [2, 3, 4]);
    });
  });

  group('cùng tên khác cha/type', () {
    test('xử lý độc lập — không gộp (data-model §Projection 4)', () {
      // 2 cha cùng tên khác type (không cùng list) → mỗi danh sách giữ đúng.
      final expense = [
        _cat(1, name: 'Khác'),
        _cat(2, parentId: 1, name: 'Con Khác'),
      ];
      final income = [
        _cat(9, name: 'Khác', type: CategoryType.income),
      ];
      expect(topLevelParents(expense).map((c) => c.id), [1]);
      expect(topLevelParents(income).map((c) => c.id), [9]);
      // Con của cha "Khác" chi không lẫn sang list thu.
      expect(childrenOf(income, 1), isEmpty);
    });
  });
}
