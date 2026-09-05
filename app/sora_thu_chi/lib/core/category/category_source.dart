import 'category.dart';

/// Bộ danh mục mặc định của app (pattern [WalletSource]) — nguồn chân lý cho
/// picker giao dịch mới: drift seed `categories` lúc tạo/upgrade DB và fake
/// repository (R4). 8 cha chi + 4 cha thu (gồm "Khác" — acceptance 4) + 3 con
/// của "Ăn uống". Màu/icon bám mockup `03-chon-danh-muc.svg` (data-model §Seed);
/// con thừa hưởng màu cha, icon riêng.
///
/// [Category.id] mang id tạm ổn định (cha 1..12, con 13..15) đủ cho fake trả
/// trực tiếp và [Category.parentId] trỏ đúng cha cùng type; drift seed KHÔNG
/// dùng id này (để DB tự sinh, map cha-con theo tên). Toàn bộ `is_system =
/// true`, `is_hidden = false`.
class CategorySource {
  CategorySource._();

  static const List<Category> all = [
    // ---- Cha chi (8) — sortOrder 0..7.
    Category(
      id: 1,
      name: 'Ăn uống',
      type: CategoryType.expense,
      icon: 'restaurant',
      color: 0xFF3D8C77,
      sortOrder: 0,
      isSystem: true,
    ),
    Category(
      id: 2,
      name: 'Di chuyển',
      type: CategoryType.expense,
      icon: 'directions_car',
      color: 0xFF0F6E56,
      sortOrder: 1,
      isSystem: true,
    ),
    Category(
      id: 3,
      name: 'Nhà ở',
      type: CategoryType.expense,
      icon: 'home',
      color: 0xFF5F5E5A,
      sortOrder: 2,
      isSystem: true,
    ),
    Category(
      id: 4,
      name: 'Hóa đơn',
      type: CategoryType.expense,
      icon: 'receipt',
      color: 0xFFD85A30,
      sortOrder: 3,
      isSystem: true,
    ),
    Category(
      id: 5,
      name: 'Mua sắm',
      type: CategoryType.expense,
      icon: 'shopping_bag',
      color: 0xFF3D8C77,
      sortOrder: 4,
      isSystem: true,
    ),
    Category(
      id: 6,
      name: 'Giải trí',
      type: CategoryType.expense,
      icon: 'sports_esports',
      color: 0xFF0F6E56,
      sortOrder: 5,
      isSystem: true,
    ),
    Category(
      id: 7,
      name: 'Sức khỏe',
      type: CategoryType.expense,
      icon: 'medical_services',
      color: 0xFF5F5E5A,
      sortOrder: 6,
      isSystem: true,
    ),
    Category(
      id: 8,
      name: 'Giáo dục',
      type: CategoryType.expense,
      icon: 'school',
      color: 0xFFD85A30,
      sortOrder: 7,
      isSystem: true,
    ),
    // ---- Cha thu (4) — sortOrder 0..3.
    Category(
      id: 9,
      name: 'Lương',
      type: CategoryType.income,
      icon: 'payments',
      color: 0xFF0F6E56,
      sortOrder: 0,
      isSystem: true,
    ),
    Category(
      id: 10,
      name: 'Thưởng',
      type: CategoryType.income,
      icon: 'redeem',
      color: 0xFF3D8C77,
      sortOrder: 1,
      isSystem: true,
    ),
    Category(
      id: 11,
      name: 'Đầu tư',
      type: CategoryType.income,
      icon: 'show_chart',
      color: 0xFF5F5E5A,
      sortOrder: 2,
      isSystem: true,
    ),
    Category(
      id: 12,
      name: 'Khác',
      type: CategoryType.income,
      icon: 'category',
      color: 0xFF9B9B9B,
      sortOrder: 3,
      isSystem: true,
    ),
    // ---- Con của "Ăn uống" (id 1) — sortOrder 0..2, thừa hưởng màu cha.
    Category(
      id: 13,
      name: 'Cà phê',
      type: CategoryType.expense,
      icon: 'local_cafe',
      color: 0xFF3D8C77,
      parentId: 1,
      sortOrder: 0,
      isSystem: true,
    ),
    Category(
      id: 14,
      name: 'Ăn ngoài',
      type: CategoryType.expense,
      icon: 'restaurant_menu',
      color: 0xFF3D8C77,
      parentId: 1,
      sortOrder: 1,
      isSystem: true,
    ),
    Category(
      id: 15,
      name: 'Đi chợ',
      type: CategoryType.expense,
      icon: 'shopping_cart',
      color: 0xFF3D8C77,
      parentId: 1,
      sortOrder: 2,
      isSystem: true,
    ),
  ];

  /// Cha (parentId null) của [type], sắp theo sortOrder — lưới màn chọn danh mục.
  static List<Category> parentsOf(CategoryType type) {
    final list = all
        .where((c) => !c.isHidden && c.type == type && c.isParent)
        .toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  /// Con trực tiếp của cha [parent] (đang hoạt động), sắp theo sortOrder.
  static List<Category> childrenOf(Category parent) {
    final list = all
        .where((c) => !c.isHidden && c.parentId == parent.id)
        .toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }
}
