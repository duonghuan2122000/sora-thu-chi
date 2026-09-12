import '../category/category.dart';
import '../transaction/transaction.dart';
import 'budget.dart';
import 'budget_view.dart';

/// Module **thuần** tính toán màn Chi tiết Ngân sách (PBI 21, mockup `03`) —
/// không đọc DB/state: nhận ngân sách + giao dịch + danh mục + mốc thời gian và
/// kỳ đang xem, trả toàn bộ số liệu. Mọi số **tính lại mỗi lần nạp màn** (kế
/// thừa cách làm PBI 20 — không bảng snapshot), nên sửa/xóa giao dịch sau đó
/// là số liệu tự khớp, không hồi tố kỳ trước (FR-018).

/// Số ngày còn lại của [range], tính **cả hôm nay** (research R6):
/// `total = end − start`, `elapsed = clamp(today − start + 1, 0, total)`,
/// `left = total − elapsed` (sàn 0). Tháng 9 ngày 12 → 18 ngày còn lại.
int budgetDaysLeft(DateRange range, DateTime now) {
  final total = _totalDays(range);
  return total - _elapsedDays(range, now, total);
}

/// % số ngày đã trôi qua của [range] (gồm hôm nay — R6); kỳ rỗng → 0.
double budgetElapsedPercent(DateRange range, DateTime now) {
  final total = _totalDays(range);
  if (total <= 0) return 0;
  return _elapsedDays(range, now, total) / total * 100;
}

/// Cảnh báo tốc độ chi tiêu (FR-007): chi nhanh hơn nhịp thời gian **và** kỳ
/// chưa kết thúc. Kỳ đã kết thúc thì cảnh báo nhịp vô nghĩa ⇒ luôn `false`.
bool budgetPaceWarning({
  required double usedPercent,
  required double elapsedPercent,
  required bool ended,
}) => !ended && usedPercent > elapsedPercent;

/// Kỳ mặc định của [budget]: kỳ chứa [now]; ngân sách **không lặp lại** thì
/// kỳ chứa `startDate` (kỳ duy nhất ngân sách còn hiệu lực — FR-020/FR-023).
DateRange budgetDefaultRange(Budget budget, DateTime now) => budgetPeriodRange(
  budget.period,
  budget.isRecurring ? now : budget.startDate,
);

/// Một kỳ trong khối so sánh Dự kiến • Thực tế (data-model §Thực thể 2).
class BudgetPeriodSummary {
  const BudgetPeriodSummary({
    required this.range,
    required this.spent,
    required this.limit,
    required this.percent,
    required this.level,
    required this.ended,
  });

  final DateRange range;
  final int spent;

  /// Giới hạn **hiện tại** của ngân sách — dùng cho mọi kỳ (giả định spec:
  /// không lưu giới hạn theo thời điểm, sửa giới hạn là mốc "Dự kiến" đổi theo).
  final int limit;

  final double percent;
  final ProgressLevel level;
  final bool ended;
}

/// [maxPeriods] kỳ gần nhất **tính đến** [viewedRange] (kỳ đang xem là phần tử
/// **cuối**), đi lùi theo đúng bước chu kỳ và **không** vượt quá kỳ chứa
/// `startDate` — ngân sách mới có 1–2 kỳ thì trả đúng 1–2 phần tử (FR-008/
/// FR-010, data-model luật 6–7).
List<BudgetPeriodSummary> budgetComparisonSeries({
  required Budget budget,
  required List<Transaction> transactions,
  required List<Category> categories,
  required DateTime now,
  required DateRange viewedRange,
  int maxPeriods = 3,
}) {
  final scope = budgetScopeCategoryIds(budget.categoryId, categories);
  final first = budgetPeriodRange(budget.period, budget.startDate);
  final series = <BudgetPeriodSummary>[];

  var range = viewedRange;
  while (series.length < maxPeriods && !range.start.isBefore(first.start)) {
    final spent = budgetSpent(
      categoryIds: scope,
      transactions: transactions,
      range: range,
    );
    final percent = budget.amount <= 0 ? 0.0 : spent / budget.amount * 100;
    series.add(
      BudgetPeriodSummary(
        range: range,
        spent: spent,
        limit: budget.amount,
        percent: percent,
        level: budgetProgressLevel(percent),
        ended: !now.isBefore(range.end),
      ),
    );
    range = budgetPeriodRange(
      budget.period,
      range.start.subtract(const Duration(days: 1)),
    );
  }
  return series.reversed.toList();
}

/// Các kỳ chọn được ở bộ chọn kỳ (FR-023), **tăng dần**: từ kỳ chứa `startDate`
/// đến kỳ hiện tại — không có kỳ nào trước khi ngân sách bắt đầu (kịch bản 3).
/// Ngân sách **không lặp lại** chỉ có đúng **một** lựa chọn là kỳ `startDate`
/// (ngân sách đã hết hiệu lực — FR-020).
List<DateRange> budgetPeriodOptions(Budget budget, DateTime now) {
  final first = budgetPeriodRange(budget.period, budget.startDate);
  final candidate = budget.isRecurring
      ? budgetPeriodRange(budget.period, now)
      : first;
  final upper = candidate.start.isBefore(first.start) ? first : candidate;

  final options = <DateRange>[];
  var range = first;
  while (!range.start.isAfter(upper.start)) {
    options.add(range);
    range = budgetPeriodRange(budget.period, range.end);
  }
  return options;
}

/// Kết quả dựng **một kỳ** của màn Chi tiết (data-model §Thực thể 3).
class BudgetDetail {
  const BudgetDetail({
    required this.budget,
    required this.category,
    required this.range,
    required this.spent,
    required this.percent,
    required this.level,
    required this.overAmount,
    required this.remainingAmount,
    required this.ended,
    required this.daysLeft,
    required this.elapsedPercent,
    required this.showPaceWarning,
    required this.transactions,
    required this.comparison,
    required this.periodOptions,
  });

  final Budget budget;

  /// null = danh mục không còn trong bảng ⇒ màn hiện trạng thái **không hợp lệ**
  /// (FR-019), ẩn thẻ tiến độ/biểu đồ/danh sách.
  final Category? category;

  /// Kỳ **đang xem** (mặc định [budgetDefaultRange], đổi được qua bộ chọn kỳ).
  final DateRange range;

  /// "Đã dùng" (FR-003) — tổng Chi trong kỳ thuộc phạm vi danh mục (gồm con).
  final int spent;

  /// `spent / amount × 100` — nguồn của huy hiệu + 3 dải màu (FR-004/FR-005).
  final double percent;

  final ProgressLevel level;

  /// Chỉ một trong hai khác 0: `>= 100%` → vượt, `< 100%` → còn lại (FR-006).
  final int overAmount;
  final int remainingAmount;

  /// Kỳ đang xem đã kết thúc (`range.end <= now`).
  final bool ended;

  /// Sàn 0; `ended` ⇒ màn hiện "Đã kết thúc" thay cho số ngày.
  final int daysLeft;

  final double elapsedPercent;

  final bool showPaceWarning;

  /// **Toàn bộ** giao dịch Chi trong kỳ, mới nhất trước (FR-011/FR-012) — màn
  /// chỉ vẽ 5 dòng đầu; tổng danh sách khớp [spent] (SC-005).
  final List<Transaction> transactions;

  /// Tối đa 3 kỳ gần nhất tính đến [range], kỳ đang xem là **phần tử cuối**
  /// (FR-008/FR-010). Không bao giờ rỗng.
  final List<BudgetPeriodSummary> comparison;

  /// Kỳ chọn được ở bộ chọn kỳ, **tăng dần** (FR-023) — xem
  /// [budgetPeriodOptions].
  final List<DateRange> periodOptions;
}

/// Gom toàn bộ số liệu của [viewedRange] (null ⇒ kỳ mặc định của ngân sách).
///
/// "Đã dùng" và danh sách giao dịch dùng **cùng một phép lọc**
/// ([budgetPeriodTransactions]) ⇒ không thể lệch số (research R11, SC-005).
BudgetDetail buildBudgetDetail({
  required Budget budget,
  required List<Category> categories,
  required List<Transaction> transactions,
  required DateTime now,
  DateRange? viewedRange,
}) {
  final categoryById = {for (final c in categories) c.id: c};
  final range = viewedRange ?? budgetDefaultRange(budget, now);
  final matched = budgetPeriodTransactions(
    categoryIds: budgetScopeCategoryIds(budget.categoryId, categories),
    transactions: transactions,
    range: range,
  );
  var spent = 0;
  for (final t in matched) {
    spent += -t.amount;
  }

  final percent = budget.amount <= 0 ? 0.0 : spent / budget.amount * 100;
  final ended = !now.isBefore(range.end);
  final elapsedPercent = budgetElapsedPercent(range, now);

  return BudgetDetail(
    budget: budget,
    category: categoryById[budget.categoryId],
    range: range,
    spent: spent,
    percent: percent,
    level: budgetProgressLevel(percent),
    overAmount: spent > budget.amount ? spent - budget.amount : 0,
    remainingAmount: spent < budget.amount ? budget.amount - spent : 0,
    ended: ended,
    daysLeft: budgetDaysLeft(range, now),
    elapsedPercent: elapsedPercent,
    showPaceWarning: budgetPaceWarning(
      usedPercent: percent,
      elapsedPercent: elapsedPercent,
      ended: ended,
    ),
    transactions: matched,
    comparison: budgetComparisonSeries(
      budget: budget,
      transactions: transactions,
      categories: categories,
      now: now,
      viewedRange: range,
    ),
    periodOptions: budgetPeriodOptions(budget, now),
  );
}

int _totalDays(DateRange range) => _daysBetween(range.end, range.start);

int _elapsedDays(DateRange range, DateTime now, int total) {
  final raw = _daysBetween(now, range.start) + 1;
  return raw.clamp(0, total);
}

/// Chênh lệch **ngày lịch** giữa [a] và [b] — chuẩn hóa qua UTC để miền có
/// quy ước giờ mùa hè không làm lệch 1 ngày.
int _daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(a.year, a.month, a.day)
        .difference(DateTime.utc(b.year, b.month, b.day))
        .inDays;
