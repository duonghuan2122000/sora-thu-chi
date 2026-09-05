import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/category/category_presets.dart';
import 'package:sora_thu_chi/core/category/category_source.dart';
import 'package:sora_thu_chi/core/widgets/category_icon.dart';

void main() {
  group('categoryIconChoices — bộ icon form', () {
    test('đủ 15 khóa, distinct; mỗi khóa render được qua categoryIcon', () {
      expect(categoryIconChoices.length, 15);
      expect(categoryIconChoices.toSet().length, 15);
      for (final key in categoryIconChoices) {
        // Gọi không crash → map có entry (khóa dữ liệu hợp lệ).
        expect(categoryIcon(key), isNotNull);
      }
    });

    test('bất biến R2: mọi Category seed có icon ∈ choices (không rơi fallback)', () {
      for (final c in CategorySource.all) {
        expect(
          categoryIconChoices.contains(c.icon),
          isTrue,
          reason: 'Seed "${c.name}" dùng icon "${c.icon}" ngoài danh sách chọn',
        );
      }
    });
  });

  group('categoryPresetColors — bảng màu 13 ô', () {
    test('đủ 13 phần tử ARGB, distinct', () {
      expect(categoryPresetColors.length, 13);
      expect(categoryPresetColors.toSet().length, 13);
    });

    test('bất biến R2: mọi Category seed có color ∈ categoryPresetColors', () {
      for (final c in CategorySource.all) {
        expect(
          categoryPresetColors.contains(c.color),
          isTrue,
          reason: 'Seed "${c.name}" dùng màu ${c.color.toRadixString(16)} '
              'ngoài bảng màu chọn',
        );
      }
    });
  });

  group('default cho từng loại', () {
    test('khác null và thuộc danh sách lựa chọn tương ứng', () {
      for (final type in CategoryType.values) {
        final icon = defaultIconFor(type);
        expect(icon, isNotEmpty);
        expect(categoryIconChoices.contains(icon), isTrue);
        final color = defaultColorFor(type);
        expect(categoryPresetColors.contains(color), isTrue);
      }
    });
  });
}
