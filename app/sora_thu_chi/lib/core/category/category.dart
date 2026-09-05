/// Loại danh mục — thu/chi (giao dịch không gắn danh mục cho transfer/adjustment).
enum CategoryType { income, expense }

/// Danh mục thu/chi — map 1-1 từ bảng `categories` (data-model §Domain Category).
/// [id] là id thật trong DB; seed [CategorySource] mang id tạm ổn định 1..N
/// (drift gán id theo thứ tự chèn — không đụng tới id này khi seed).
/// [color] bắt buộc (ARGB) — nền icon tròn trong picker; là **dữ liệu** từ bảng,
/// không phải styling cứng của widget.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.parentId,
    this.sortOrder = 0,
    this.isHidden = false,
    this.isSystem = false,
  });

  final int id;
  final String name;
  final CategoryType type;

  /// Khóa icon → [IconData] qua map [categoryIcon] (tầng UI), không lưu IconData.
  final String icon;

  /// Màu ARGB (bắt buộc) — nền icon.
  final int color;

  /// null = cha; khác null = id cha (2 cấp, seed/UI đảm bảo).
  final int? parentId;

  final int sortOrder;

  /// Ẩn giữ lịch sử — danh mục ẩn không hiện trong picker giao dịch mới.
  final bool isHidden;

  /// Danh mục hệ thống (seed mặc định) — module Danh mục sau chặn xóa.
  final bool isSystem;

  bool get isParent => parentId == null;
}
