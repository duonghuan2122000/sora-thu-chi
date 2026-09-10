import 'package:get/get.dart';

import 'category.dart';
import 'category_list.dart';

/// Các hàm thuần cho màn thêm/sửa danh mục — tách khỏi widget để unit test
/// (data-model §Module thuần, R5). Chỉ nhận [List] đầu vào, không đọc DB/state.

/// Lỗi tên danh mục (FR-003/004, acceptance 4/12): trim thừa hai đầu; rỗng /
/// toàn khoảng trắng → lỗi trống; trùng tên một danh mục khác trong [siblings]
/// (danh sách cùng nhóm — cùng loại + cùng cha, gồm bản đang ẩn) → lỗi trùng;
/// bỏ qua [excludeId] (chính mình khi sửa — edge "giữ nguyên tên").
String? categoryNameError({
  required String raw,
  required List<Category> siblings,
  int? excludeId,
}) {
  final name = raw.trim();
  if (name.isEmpty) return 'Tên danh mục không được để trống'.tr;
  final trung = siblings.any((c) => c.id != excludeId && c.name == name);
  if (trung) return 'Tên danh mục đã tồn tại trong nhóm này'.tr;
  return null;
}

/// "Thêm vào cuối nhóm" (FR-009): `max(sortOrder) + 1`, `0` nếu [group] rỗng.
int endOfGroupSortOrder(List<Category> group) {
  if (group.isEmpty) return 0;
  var max = group.first.sortOrder;
  for (final c in group) {
    if (c.sortOrder > max) max = c.sortOrder;
  }
  return max + 1;
}

/// Điều kiện đổi loại khi Sửa (FR-002/008, chốt spec): chưa gắn giao dịch +
/// không có danh mục con + đang là danh mục gốc. Con (`isParent = false`) luôn
/// false — loại con phải cùng loại cha.
bool canChangeType({
  required bool hasTransactions,
  required bool hasChildren,
  required bool isParent,
}) =>
    !hasTransactions && !hasChildren && isParent;

/// Danh sách cha (cấp 1) cho ô "Danh mục cha" — sắp `sortOrder` tăng, **gồm
/// cả cha đang ẩn** (FR-006 không chặn; màn tự loại chính nó khi Sửa).
/// Bọc [topLevelParents] (category_list.dart) — không tách lại logic.
List<Category> parentsOfType(List<Category> list) => topLevelParents(list);
