import 'package:flutter/material.dart';

/// Map khóa icon (cột `categories.icon` / seed [CategorySource]) → [IconData]
/// Material — khóa là **dữ liệu** từ bảng, widget không biết trước danh mục.
/// Khóa lạ / chưa có entry → fallback [Icons.category] (không crash).
IconData categoryIcon(String key) {
  const map = <String, IconData>{
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'home': Icons.home,
    'receipt': Icons.receipt,
    'shopping_bag': Icons.shopping_bag,
    'sports_esports': Icons.sports_esports,
    'medical_services': Icons.medical_services,
    'school': Icons.school,
    'payments': Icons.payments,
    'redeem': Icons.redeem,
    'show_chart': Icons.show_chart,
    'category': Icons.category,
    'local_cafe': Icons.local_cafe,
    'restaurant_menu': Icons.restaurant_menu,
    'shopping_cart': Icons.shopping_cart,
  };
  return map[key] ?? Icons.category;
}
