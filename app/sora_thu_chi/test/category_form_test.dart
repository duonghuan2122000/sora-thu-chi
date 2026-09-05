import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/category/category_form.dart';

/// Category dựng tay cho test thuần (không sqlite — R5).
Category _cat(
  int id,
  String name, {
  CategoryType type = CategoryType.expense,
  int? parentId,
  int sortOrder = 0,
  bool isHidden = false,
}) {
  return Category(
    id: id,
    name: name,
    type: type,
    icon: 'category',
    color: 0xFF0F6E56,
    parentId: parentId,
    sortOrder: sortOrder,
    isHidden: isHidden,
  );
}

const _errEmpty = 'Tên danh mục không được để trống';
const _errTrung = 'Tên danh mục đã tồn tại trong nhóm này';

void main() {
  group('categoryNameError', () {
    test('rỗng / toàn khoảng trắng → lỗi trống (acceptance 12)', () {
      expect(categoryNameError(raw: '', siblings: []), _errEmpty);
      expect(categoryNameError(raw: '   ', siblings: []), _errEmpty);
      expect(categoryNameError(raw: '\t  ', siblings: []), _errEmpty);
    });

    test('trim hai đầu khi so trùng — "  Ăn uống " trùng "Ăn uống"', () {
      final group = [_cat(1, 'Ăn uống')];
      expect(categoryNameError(raw: '  Ăn uống ', siblings: group), _errTrung);
    });

    test('trùng tên cùng nhóm (type + cha) gồm bản đang ẩn → lỗi (acceptance 4)', () {
      final group = [
        _cat(1, 'Ăn uống'),
        _cat(2, 'Di chuyển', isHidden: true),
      ];
      // Trùng bản ẩn "Di chuyển".
      expect(categoryNameError(raw: 'Di chuyển', siblings: group), _errTrung);
    });

    test('sửa bỏ chính nó (excludeId) → không báo trùng (edge "giữ nguyên tên")', () {
      final group = [_cat(3, 'Giải trí', isHidden: true)];
      expect(
        categoryNameError(raw: 'Giải trí', siblings: group, excludeId: 3),
        isNull,
      );
      // Nhưng vẫn còn bản khác cùng tên trong nhóm → vẫn lỗi.
      final two = [_cat(3, 'Giải trí'), _cat(9, 'Giải trí')];
      expect(
        categoryNameError(raw: 'Giải trí', siblings: two, excludeId: 3),
        _errTrung,
      );
    });

    test('cùng tên khác nhóm (khác cha / khác loại) → hợp lệ', () {
      // Tên "Cà phê" đang ở nhóm con cha 1 — thêm vào nhóm con cha 2 (có con
      // "Trà sữa") cùng loại không bị tính trùng: khác parentId.
      final parent2ChildGroup = [_cat(20, 'Trà sữa', parentId: 2)];
      expect(
        categoryNameError(raw: 'Cà phê', siblings: parent2ChildGroup),
        isNull,
      );
      // Tên "Lương" là danh mục thu — thêm danh mục chi cùng tên không trùng
      // (khác loại); siblings là nhóm gốc chi có "Ăn vặt".
      final expenseRootGroup = [_cat(21, 'Ăn vặt')];
      expect(
        categoryNameError(raw: 'Lương', siblings: expenseRootGroup),
        isNull,
      );
    });

    test('tên hợp lệ (không trùng, không rỗng) → null', () {
      final group = [_cat(1, 'Ăn uống')];
      expect(categoryNameError(raw: 'Ăn vặt', siblings: group), isNull);
    });
  });

  group('endOfGroupSortOrder', () {
    test('nhóm rỗng → 0 (FR-009)', () {
      expect(endOfGroupSortOrder([]), 0);
    });

    test('có phần tử → max(sortOrder) + 1', () {
      final group = [
        _cat(1, 'A', sortOrder: 3),
        _cat(2, 'B', sortOrder: 1),
        _cat(3, 'C', sortOrder: 7),
      ];
      expect(endOfGroupSortOrder(group), 8);
    });
  });

  group('canChangeType (FR-002/008)', () {
    test('đã gắn giao dịch → không đổi', () {
      expect(
        canChangeType(hasTransactions: true, hasChildren: false, isParent: true),
        isFalse,
      );
    });

    test('có danh mục con → không đổi', () {
      expect(
        canChangeType(hasTransactions: false, hasChildren: true, isParent: true),
        isFalse,
      );
    });

    test('đang là danh mục con (isParent=false) → không đổi (cùng loại cha)', () {
      expect(
        canChangeType(hasTransactions: false, hasChildren: false, isParent: false),
        isFalse,
      );
    });

    test('gốc sạch (chưa gd, không con) → đổi được', () {
      expect(
        canChangeType(hasTransactions: false, hasChildren: false, isParent: true),
        isTrue,
      );
    });
  });

  group('parentsOfType (danh sách cha)', () {
    test('chỉ cấp 1, sort sortOrder tăng, gồm cha ẩn; loại bỏ con', () {
      final list = [
        _cat(13, 'Cà phê', parentId: 1, sortOrder: 0), // con — bỏ
        _cat(1, 'Ăn uống', sortOrder: 0),
        _cat(6, 'Giải trí', sortOrder: 1, isHidden: true), // cha ẩn — giữ
        _cat(4, 'Di chuyển', sortOrder: 2),
      ];
      final parents = parentsOfType(list);
      expect(parents.map((c) => c.id).toList(), [1, 6, 4]);
    });
  });
}
