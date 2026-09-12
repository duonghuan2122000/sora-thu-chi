import '../category/category.dart';
import '../transaction/transaction.dart';
import 'budget.dart';

/// Module **thuần** tính toán màn Tổng quan Ngân sách (PBI 20) — không đọc
/// DB/state: nhận `budgets` + `transactions` + `categories` + mốc thời gian,
/// trả dòng hiển thị và thẻ tổng. "Đã chi"/"%"/trạng thái **tính lại mỗi lần
/// nạp màn** (research R3 — không bảng snapshot), nên sửa giao dịch hay ngân
/// sách là số liệu tự khớp, không hồi tố kỳ trước.

/// Khoảng thời gian nửa mở `[start, end)` — [end] **độc quyền**.
class DateRange {
  const DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool contains(DateTime moment) =>
      !moment.isBefore(start) && moment.isBefore(end);
}

/// Kỳ của [period] chứa mốc [anchor] (research R5): Tháng/Năm dương lịch,
/// **Tuần bắt đầu Thứ Hai** (quy ước sẵn có của app — `resolveDatePreset`).
DateRange budgetPeriodRange(BudgetPeriod period, DateTime anchor) {
  switch (period) {
    case BudgetPeriod.weekly:
      final day = DateTime(anchor.year, anchor.month, anchor.day);
      final monday = day.subtract(Duration(days: day.weekday - 1));
      return DateRange(start: monday, end: monday.add(const Duration(days: 7)));
    case BudgetPeriod.monthly:
      return DateRange(
        start: DateTime(anchor.year, anchor.month, 1),
        end: DateTime(anchor.year, anchor.month + 1, 1),
      );
    case BudgetPeriod.yearly:
      return DateRange(
        start: DateTime(anchor.year, 1, 1),
        end: DateTime(anchor.year + 1, 1, 1),
      );
  }
}

/// Danh mục nằm trong phạm vi ngân sách của [categoryId]: **bản thân + con
/// trực tiếp** (không lấy cháu — FR-006, cây danh mục 2 cấp).
Set<int> budgetScopeCategoryIds(int categoryId, List<Category> categories) {
  final ids = <int>{categoryId};
  for (final c in categories) {
    if (c.parentId == categoryId) ids.add(c.id);
  }
  return ids;
}

/// "Đã chi" của một ngân sách (FR-006): tổng `-amount` các giao dịch
/// **Chi** thuộc [categoryIds] và có `date` trong [range] — Thu/chuyển khoản
/// bị loại hoàn toàn (`amount` trong DB có dấu, chi = âm).
int budgetSpent({
  required Set<int> categoryIds,
  required List<Transaction> transactions,
  required DateRange range,
}) {
  var spent = 0;
  for (final t in transactions) {
    if (t.type != TxnType.expense) continue;
    final id = t.categoryId;
    if (id == null || !categoryIds.contains(id)) continue;
    if (!range.contains(t.date)) continue;
    spent += -t.amount;
  }
  return spent;
}

/// Trạng thái dòng ngân sách — **suy ra** mỗi lần nạp màn (không lưu cột).
enum BudgetStatus { active, ended, invalid }

/// Dải ngưỡng màu thanh tiến độ (FR-005).
enum ProgressLevel { normal, near, over }

/// Dải ngưỡng theo % đã dùng: `< 80` teal, `80–99` coral nhạt, `>= 100` coral đậm.
ProgressLevel budgetProgressLevel(double percent) {
  if (percent < 80) return ProgressLevel.normal;
  if (percent < 100) return ProgressLevel.near;
  return ProgressLevel.over;
}

/// Một dòng hiển thị màn Tổng quan (data-model §Thực thể 3).
class BudgetRow {
  const BudgetRow({
    required this.budget,
    required this.category,
    required this.range,
    required this.spent,
    required this.percent,
    required this.status,
    required this.level,
  });

  final Budget budget;

  /// null = danh mục không còn trong bảng `categories` ⇒ [status] `invalid`.
  final Category? category;

  /// Kỳ dùng để tính [spent] (xem [buildBudgetOverview]).
  final DateRange range;

  final int spent;

  /// `spent / amount * 100`, giữ nguyên để sắp xếp; hiển thị làm tròn.
  final double percent;

  final BudgetStatus status;

  /// Chỉ có nghĩa khi [status] `active`.
  final ProgressLevel level;
}

/// Kết quả dựng màn: danh sách đã sắp + thẻ tổng (chỉ gồm dòng `active`).
class BudgetOverview {
  const BudgetOverview({
    required this.rows,
    required this.totalSpent,
    required this.totalLimit,
    required this.daysLeft,
  });

  final List<BudgetRow> rows;
  final int totalSpent;
  final int totalLimit;

  /// Số ngày còn lại của **tháng đang xem** (FR-003) — sàn 0.
  final int daysLeft;

  double get totalPercent => totalLimit <= 0 ? 0 : totalSpent / totalLimit * 100;

  bool get isEmpty => rows.isEmpty;
}

/// Dựng toàn bộ dòng + thẻ tổng cho màn Tổng quan.
///
/// [viewedMonth] = mốc trong tháng đang xem (điều khiển ngân sách chu kỳ
/// **Tháng**); chu kỳ **Tuần/Năm** luôn lấy kỳ hiện tại của [now] (FR-002).
/// Dòng `ended` (không lặp lại, đã qua kỳ chứa `startDate`) và `invalid`
/// (danh mục không còn) **không** vào thẻ tổng (FR-020/FR-021) và xếp cuối
/// danh sách; dòng `active` sắp **giảm dần theo %** (FR-022).
BudgetOverview buildBudgetOverview({
  required List<Budget> budgets,
  required List<Transaction> transactions,
  required List<Category> categories,
  required DateTime now,
  required DateTime viewedMonth,
}) {
  final categoryById = {for (final c in categories) c.id: c};
  final monthRange = budgetPeriodRange(BudgetPeriod.monthly, viewedMonth);
  final rows = <BudgetRow>[];

  for (final budget in budgets) {
    final category = categoryById[budget.categoryId];
    final startRange = budgetPeriodRange(budget.period, budget.startDate);
    final running = budget.isRecurring || startRange.contains(now);

    final status = category == null
        ? BudgetStatus.invalid
        : running
        ? BudgetStatus.active
        : BudgetStatus.ended;

    // Kỳ tính "đã chi": ngân sách đang chạy theo chu kỳ Tháng bám tháng đang
    // xem; Tuần/Năm giữ kỳ chứa `now`; dòng đã kết thúc cố định ở kỳ `startDate`.
    final DateRange range;
    if (status == BudgetStatus.ended) {
      range = startRange;
    } else if (budget.period == BudgetPeriod.monthly) {
      range = monthRange;
    } else {
      range = budgetPeriodRange(budget.period, now);
    }

    final spent = budgetSpent(
      categoryIds: budgetScopeCategoryIds(budget.categoryId, categories),
      transactions: transactions,
      range: range,
    );
    final percent = budget.amount <= 0 ? 0.0 : spent / budget.amount * 100;
    rows.add(
      BudgetRow(
        budget: budget,
        category: category,
        range: range,
        spent: spent,
        percent: percent,
        status: status,
        level: budgetProgressLevel(percent),
      ),
    );
  }

  rows.sort(_byDisplayOrder);

  var totalSpent = 0;
  var totalLimit = 0;
  for (final r in rows) {
    if (r.status != BudgetStatus.active) continue;
    totalSpent += r.spent;
    totalLimit += r.budget.amount;
  }

  final today = DateTime(now.year, now.month, now.day);
  final days = monthRange.end.difference(today).inDays;

  return BudgetOverview(
    rows: rows,
    totalSpent: totalSpent,
    totalLimit: totalLimit,
    daysLeft: days < 0 ? 0 : days,
  );
}

/// Thứ tự dòng hiển thị: `active` giảm dần theo % (bằng nhau → tên tăng dần),
/// rồi `ended`, rồi `invalid` (mỗi nhóm sắp theo tên — data-model §Thứ tự).
int _byDisplayOrder(BudgetRow a, BudgetRow b) {
  final byStatus = _statusRank(a.status).compareTo(_statusRank(b.status));
  if (byStatus != 0) return byStatus;
  if (a.status == BudgetStatus.active) {
    final byPercent = b.percent.compareTo(a.percent);
    if (byPercent != 0) return byPercent;
  }
  return _nameOf(a).compareTo(_nameOf(b));
}

int _statusRank(BudgetStatus status) => switch (status) {
  BudgetStatus.active => 0,
  BudgetStatus.ended => 1,
  BudgetStatus.invalid => 2,
};

String _nameOf(BudgetRow row) => row.category?.name ?? '';
