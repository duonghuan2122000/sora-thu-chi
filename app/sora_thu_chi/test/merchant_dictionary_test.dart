import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/category/category_source.dart';
import 'package:sora_thu_chi/core/scan/merchant_dictionary.dart';

void main() {
  group('suggestCategoryName', () {
    test('khớp có dấu và không dấu, mọi kiểu hoa/thường', () {
      expect(suggestCategoryName('Circle K'), 'Ăn uống');
      expect(suggestCategoryName('CIRCLE K'), 'Ăn uống');
      expect(suggestCategoryName('circle k'), 'Ăn uống');
    });

    test('khớp chuỗi con trong tên cửa hàng dài', () {
      expect(suggestCategoryName('CIRCLE K VIỆT NAM - CN Trần Duy Hưng'), 'Ăn uống');
      expect(suggestCategoryName('Cửa hàng Petrolimex số 12'), 'Di chuyển');
    });

    test('từ khoá riêng của danh mục con thắng từ khoá cha', () {
      expect(suggestCategoryName('Highlands Coffee'), 'Cà phê');
    });

    test('không khớp → null', () {
      expect(suggestCategoryName('Tiệm vàng Kim Long'), isNull);
      expect(suggestCategoryName(''), isNull);
      expect(suggestCategoryName(null), isNull);
    });
  });

  group('resolveCategory', () {
    final active = CategorySource.all
        .where((c) => c.type == CategoryType.expense && !c.isHidden)
        .toList();

    test('tên có trong danh sách đang hoạt động → trả đúng Category', () {
      expect(resolveCategory('Ăn uống', active)?.name, 'Ăn uống');
    });

    test('danh mục đang ẩn không được gợi ý', () {
      final hidden = [
        Category(
          id: 99,
          name: 'Ăn uống',
          type: CategoryType.expense,
          icon: 'restaurant',
          color: 0xFF000000,
          isHidden: true,
        ),
      ];
      expect(resolveCategory('Ăn uống', hidden)?.isHidden, isTrue);
      // Danh sách "đang hoạt động" thực tế không chứa nó ⇒ null.
      expect(resolveCategory('Ăn uống', const []), isNull);
    });

    test('tên không có trong danh sách → null (không tự tạo)', () {
      expect(resolveCategory('Danh mục bịa', active), isNull);
      expect(resolveCategory(null, active), isNull);
    });
  });

  test('mọi tên đích trong từ điển đều tồn tại trong CategorySource', () {
    final seedNames = CategorySource.all.map((c) => c.name).toSet();
    final missing = merchantKeywords.values
        .where((name) => !seedNames.contains(name))
        .toSet();
    expect(missing, isEmpty, reason: 'Tên danh mục lạ: ${missing.join(', ')}');
  });
}
