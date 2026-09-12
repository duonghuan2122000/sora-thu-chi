import '../category/category.dart';
import 'budget.dart';
import 'budget_view.dart';

/// Luật hợp lệ & chồng lấn của ngân sách (PBI 20) — hàm **thuần**, không đọc
/// DB; màn Thêm/Sửa ngân sách gọi trước khi ghi (bám nếp `wallet_rules`).

/// Thông báo chặn chồng lấn (FR-016) — nút "Lưu ngân sách" hiện khi
/// [findOverlappingBudget] tìm thấy ngân sách trùng danh mục + chu kỳ.
const String budgetOverlapMessage =
    'Đã có ngân sách cho danh mục này trong kỳ. Hãy sửa ngân sách đang có.';

/// Khoảng **hiệu lực** của [budget] (research R10): lặp lại → `startDate` đến
/// vô cùng ([end] null); không lặp lại → đúng kỳ chứa `startDate`.
({DateTime start, DateTime? end}) budgetEffectiveRange(Budget budget) {
  if (budget.isRecurring) return (start: budget.startDate, end: null);
  final range = budgetPeriodRange(budget.period, budget.startDate);
  return (start: range.start, end: range.end);
}

/// Hai ngân sách **chồng lấn** khi cùng [Budget.categoryId] + cùng
/// [Budget.period] và khoảng hiệu lực giao nhau (FR-016); khác chu kỳ ⇒ song song.
bool budgetOverlaps(Budget a, Budget b) {
  if (a.categoryId != b.categoryId || a.period != b.period) return false;
  final ra = budgetEffectiveRange(a);
  final rb = budgetEffectiveRange(b);
  // Nửa mở: chạm đúng mốc kết thúc/kết thúc-kia thì KHÔNG giao nhau.
  if (ra.end != null && !ra.end!.isAfter(rb.start)) return false;
  if (rb.end != null && !rb.end!.isAfter(ra.start)) return false;
  return true;
}

/// Ngân sách đầu tiên trong [existing] chồng lấn [candidate]; **bỏ qua chính
/// nó** theo `id` (chế độ Sửa không tự chặn). null = không vướng.
Budget? findOverlappingBudget({
  required Budget candidate,
  required List<Budget> existing,
}) {
  for (final b in existing) {
    if (b.id == candidate.id) continue;
    if (budgetOverlaps(candidate, b)) return b;
  }
  return null;
}

/// Lỗi biểu mẫu đầu tiên (khóa thông báo hiển thị) — null = hợp lệ.
/// Chồng lấn kiểm tra riêng bằng [findOverlappingBudget] vì cần danh sách hiện có.
String? validateBudgetForm({required Category? category, required int amount}) {
  if (category == null) return 'Vui lòng chọn danh mục.';
  if (amount <= 0) return 'Vui lòng nhập số tiền lớn hơn 0.';
  return null;
}
