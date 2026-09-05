import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/category/category_source.dart';
import 'package:sora_thu_chi/core/widgets/category_icon.dart';

/// Khóa icon hợp lệ — khớp map [categoryIcon] (data-model §Map icon). Mọi key
/// seed phải nằm trong đây (không rơi fallback).
const _validIconKeys = <String>{
  'restaurant', 'directions_car', 'home', 'receipt', 'shopping_bag',
  'sports_esports', 'medical_services', 'school', 'payments', 'redeem',
  'show_chart', 'category', 'local_cafe', 'restaurant_menu', 'shopping_cart',
};

void main() {
  group('CategorySource — seed danh mục mặc định hợp lệ (data-model §Seed)', () {
    test('đủ 8 cha chi + 4 cha thu + 3 con Ăn uống, đúng type', () {
      final all = CategorySource.all;
      expect(all.length, 15);
      final parents = all.where((c) => c.isParent).toList();
      expect(parents.length, 12);
      expect(parents.where((c) => c.type == CategoryType.expense).length, 8);
      expect(parents.where((c) => c.type == CategoryType.income).length, 4);
      expect(parents.map((c) => c.name), contains('Khác')); // thu — acceptance 4.
      final children = all.where((c) => !c.isParent).toList();
      expect(children.length, 3);
      expect(children.every((c) => c.type == CategoryType.expense), isTrue);
    });

    test('tên duy nhất trong phạm vi cha + type', () {
      for (final type in CategoryType.values) {
        final names = CategorySource.all
            .where((c) => c.isParent && c.type == type)
            .map((c) => c.name)
            .toList();
        expect(names.toSet().length, names.length, reason: 'trùng tên cha type $type');
      }
    });

    test('≤ 2 cấp: con trỏ đúng cha cùng type, không có con của con', () {
      final parents = CategorySource.all.where((c) => c.isParent).toList();
      final parentIds = parents.map((c) => c.id).toSet();
      for (final c in CategorySource.all.where((c) => !c.isParent)) {
        expect(parentIds, contains(c.parentId), reason: '${c.name} trỏ cha không tồn tại');
        final parent = parents.firstWhere((p) => p.id == c.parentId);
        expect(parent.type, c.type, reason: '${c.name} khác type cha ${parent.name}');
      }
      final childIds = CategorySource.all
          .where((c) => !c.isParent)
          .map((c) => c.id)
          .toSet();
      expect(
        CategorySource.all.any((c) => c.parentId != null && childIds.contains(c.parentId)),
        isFalse,
        reason: 'không có cấp 3 (con của con)',
      );
    });

    test('màu ARGB hợp lệ (opaque) & icon key đủ, không rơi fallback', () {
      for (final c in CategorySource.all) {
        expect(c.color, inInclusiveRange(0xFF000000, 0xFFFFFFFF),
            reason: '${c.name} màu ngoài dải ARGB');
        expect(c.color >> 24, 0xFF, reason: '${c.name} màu không opaque');
        expect(_validIconKeys, contains(c.icon),
            reason: '${c.name} icon key lạ — không có entry trong categoryIcon');
      }
    });

    test('con thừa hưởng đúng type cha', () {
      final food = CategorySource.all.firstWhere((c) => c.name == 'Ăn uống');
      for (final c in CategorySource.childrenOf(food)) {
        expect(c.type, food.type);
        expect(c.color, food.color); // thừa hưởng màu cha (data-model §Seed).
        expect(c.parentId, food.id);
      }
    });

    test('sortOrder tuần tự 0..n trong từng nhóm (cha theo type, con theo cha)', () {
      for (final type in CategoryType.values) {
        final parents = CategorySource.parentsOf(type);
        for (var i = 0; i < parents.length; i++) {
          expect(parents[i].sortOrder, i, reason: 'cha ${parents[i].name} lệch sort');
        }
      }
      for (final parent in CategorySource.parentsOf(CategoryType.expense)) {
        final children = CategorySource.childrenOf(parent);
        for (var i = 0; i < children.length; i++) {
          expect(children[i].sortOrder, i,
              reason: 'con ${children[i].name} của ${parent.name} lệch sort');
        }
      }
    });
  });
}
