import 'package:get/get.dart';

import '../category/category.dart';
import '../date_range.dart';
import '../transaction/transaction.dart';
import '../transaction/transaction_filter.dart' show normalizeSearch;

/// Module **thuần** tính số liệu màn Tổng quan Báo cáo (PBI 22) — không đọc
/// DB/state: nhận giao dịch + danh mục + kỳ, trả dữ liệu hiển thị. Mọi con số
/// tính lại mỗi lần nạp màn (không bảng tổng hợp/cache — research R9).

/// Kỳ báo cáo trên segmented control (FR-002) — mốc **dương lịch** (FR-021).
enum ReportPeriod { day, week, month, year }

extension ReportPeriodLabelX on ReportPeriod {
  String get label => switch (this) {
    ReportPeriod.day => 'Ngày'.tr,
    ReportPeriod.week => 'Tuần'.tr,
    ReportPeriod.month => 'Tháng'.tr,
    ReportPeriod.year => 'Năm'.tr,
  };
}

/// Kỳ của [period] chứa mốc [anchor] — khoảng **nửa mở** `[start, end)`:
/// Ngày `[d, d+1)`, Tuần `[Thứ Hai, +7 ngày)`, Tháng `[mùng 1, mùng 1 sau)`,
/// Năm `[1/1, 1/1 năm sau)`. Tháng/Năm giải bằng **số học ngày**, không cộng
/// `Duration` (data-model luật 5).
DateRange reportPeriodRange(ReportPeriod period, DateTime anchor) {
  switch (period) {
    case ReportPeriod.day:
      final day = DateTime(anchor.year, anchor.month, anchor.day);
      return DateRange(start: day, end: DateTime(anchor.year, anchor.month, anchor.day + 1));
    case ReportPeriod.week:
      final day = DateTime(anchor.year, anchor.month, anchor.day);
      final monday = DateTime(
        anchor.year,
        anchor.month,
        anchor.day - (day.weekday - 1),
      );
      return DateRange(
        start: monday,
        end: DateTime(monday.year, monday.month, monday.day + 7),
      );
    case ReportPeriod.month:
      return DateRange(
        start: DateTime(anchor.year, anchor.month, 1),
        end: DateTime(anchor.year, anchor.month + 1, 1),
      );
    case ReportPeriod.year:
      return DateRange(
        start: DateTime(anchor.year, 1, 1),
        end: DateTime(anchor.year + 1, 1, 1),
      );
  }
}

/// Đầu kỳ liền trước — lùi đúng **1 đơn vị lịch** (data-model luật 5).
DateTime _previousStart(ReportPeriod period, DateTime start) {
  switch (period) {
    case ReportPeriod.day:
      return DateTime(start.year, start.month, start.day - 1);
    case ReportPeriod.week:
      return DateTime(start.year, start.month, start.day - 7);
    case ReportPeriod.month:
      return DateTime(start.year, start.month - 1, 1);
    case ReportPeriod.year:
      return DateTime(start.year - 1, 1, 1);
  }
}

/// [count] kỳ liên tiếp kết thúc ở kỳ chứa [anchor] — phần tử **cuối** là kỳ
/// đang chọn, đủ [count] phần tử kể cả khi chưa có dữ liệu (FR-006).
List<DateRange> reportPeriodSeries(
  ReportPeriod period,
  DateTime anchor, {
  int count = 6,
}) {
  final ranges = <DateRange>[reportPeriodRange(period, anchor)];
  while (ranges.length < count) {
    ranges.insert(
      0,
      reportPeriodRange(period, _previousStart(period, ranges.first.start)),
    );
  }
  return ranges;
}

/// **Phép lọc duy nhất** của màn Báo cáo: bỏ `transfer` + `adjustment`, chỉ
/// lấy giao dịch có `date` trong [range]; `income` cộng `+amount`, `expense`
/// cộng `−amount` (amount trong DB có dấu — data-model luật 6–10).
({int income, int expense}) reportTotals(
  List<Transaction> transactions,
  DateRange range,
) {
  var income = 0;
  var expense = 0;
  for (final t in transactions) {
    if (t.type != TxnType.income && t.type != TxnType.expense) continue;
    if (!range.contains(t.date)) continue;
    if (t.type == TxnType.income) {
      income += t.amount;
    } else {
      expense += -t.amount;
    }
  }
  return (income: income, expense: expense);
}

/// Chia [amounts] thành % nguyên sao cho **tổng = 100** (phần dư lớn nhất —
/// research R5); [total] là mẫu số (tổng tiền). `total <= 0` ⇒ toàn 0.
List<int> percentSplit(List<int> amounts, int total) {
  if (amounts.isEmpty) return const [];
  final floors = List<int>.filled(amounts.length, 0);
  if (total <= 0) return floors;
  final rest = <int, double>{};
  var sum = 0;
  for (var i = 0; i < amounts.length; i++) {
    final exact = amounts[i] * 100 / total;
    floors[i] = exact.floor();
    sum += floors[i];
    rest[i] = exact - floors[i];
  }
  final order = rest.keys.toList()
    ..sort((a, b) {
      final byRest = rest[b]!.compareTo(rest[a]!);
      return byRest != 0 ? byRest : a.compareTo(b);
    });
  var leftover = 100 - sum;
  for (var i = 0; leftover > 0 && i < order.length; i++, leftover--) {
    floors[order[i]]++;
  }
  return floors;
}

/// Một cột của biểu đồ dòng tiền (data-model §2).
class ReportBar {
  const ReportBar({
    required this.range,
    required this.label,
    required this.income,
    required this.expense,
    required this.isCurrent,
  });

  final DateRange range;
  final String label;
  final int income;
  final int expense;

  /// Kỳ **đang chọn** (phần tử cuối) — nhãn đậm hơn.
  final bool isCurrent;
}

String _two(int value) => value.toString().padLeft(2, '0');

/// Nhãn trục theo đơn vị kỳ: `dd/MM` (Ngày/Tuần), `T@tháng` (Tháng), `@năm` (Năm).
String reportBarLabel(ReportPeriod period, DateTime start) => switch (period) {
  ReportPeriod.day || ReportPeriod.week => '@ngày/@tháng'.trParams({
    'ngày': _two(start.day),
    'tháng': _two(start.month),
  }),
  ReportPeriod.month => 'T@tháng'.trParams({'tháng': '${start.month}'}),
  ReportPeriod.year => '@năm'.trParams({'năm': '${start.year}'}),
};

/// 6 cột dòng tiền kết thúc ở kỳ đang chọn — kỳ không có giao dịch vẫn có mặt
/// với 2 cột 0 (FR-006). Không nhận `categories`: cột chỉ cần thu/chi.
List<ReportBar> reportBarSeries({
  required List<Transaction> transactions,
  required ReportPeriod period,
  required DateTime anchor,
  int count = 6,
}) {
  final series = reportPeriodSeries(period, anchor, count: count);
  return [
    for (var i = 0; i < series.length; i++)
      () {
        final totals = reportTotals(transactions, series[i]);
        return ReportBar(
          range: series[i],
          label: reportBarLabel(period, series[i].start),
          income: totals.income,
          expense: totals.expense,
          isCurrent: i == series.length - 1,
        );
      }(),
  ];
}

/// Một lát cắt / dòng chú giải thẻ "Phân bổ chi tiêu theo danh mục".
class ReportSlice {
  const ReportSlice({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
    required this.rank,
    required this.amount,
    required this.percent,
  });

  /// id danh mục **cha**; `null` = nhóm gộp **"Khác"**.
  final int? categoryId;
  final String name;
  final String icon;
  final int color;

  /// `0…4` = hạng (chọn `chartPalette[rank]`); `-1` = "Khác" (chỉ số 5).
  final int rank;

  final int amount;

  /// % trên tổng chi, **đã chia để tổng = 100**.
  final int percent;
}

/// Nhóm chi tiêu theo danh mục **cha** — dùng chung cho thẻ phân bổ và thẻ top
/// (data-model luật 12–21) nên số tiền hai nơi không lệch.
class _Group {
  _Group(this.categoryId, this.name, this.icon, this.color);

  final int? categoryId;
  final String name;
  final String icon;
  final int color;
  int amount = 0;
}

class _Breakdown {
  _Breakdown(this.groups, this.other, this.total);

  /// Nhóm theo danh mục cha (không gồm "Khác"), đã sắp **giảm dần**, đồng hạng
  /// theo tên tăng dần.
  final List<_Group> groups;

  /// Tiền chi không gắn danh mục (vào "Khác").
  final int other;

  /// Tổng chi của kỳ = Σ mọi nhóm + [other].
  final int total;
}

_Breakdown _breakdown({
  required List<Transaction> transactions,
  required List<Category> categories,
  required DateRange range,
}) {
  final byId = {for (final c in categories) c.id: c};
  final byParent = <int, _Group>{};
  var other = 0;
  var total = 0;

  void add(Category parent, int amount) {
    final group = byParent.putIfAbsent(
      parent.id,
      () => _Group(parent.id, parent.name, parent.icon, parent.color),
    );
    group.amount += amount;
  }

  for (final t in transactions) {
    if (t.type != TxnType.expense) continue;
    if (!range.contains(t.date)) continue;
    final amount = -t.amount;
    total += amount;
    final id = t.categoryId;
    if (id == null) {
      other += amount;
      continue;
    }
    final category = byId[id];
    if (category == null) {
      // Danh mục không còn trong bảng ⇒ nhóm theo chính id đó (luật 18).
      final orphan = byParent.putIfAbsent(
        id,
        () => _Group(id, t.category, 'category', 0),
      );
      orphan.amount += amount;
      continue;
    }
    final parentId = category.parentId;
    final parent = parentId == null ? category : byId[parentId] ?? category;
    add(parent, amount);
  }

  final groups = byParent.values.toList()
    ..sort((a, b) {
      final byAmount = b.amount.compareTo(a.amount);
      if (byAmount != 0) return byAmount;
      // Đồng hạng → tên **tăng dần** theo thứ tự chữ Việt (bỏ dấu, thường hoá)
      // như bộ lọc màn Giao dịch — so code-unit thuần sẽ xếp 'Nhà' trước 'Ăn'.
      final byName = normalizeSearch(a.name).compareTo(normalizeSearch(b.name));
      return byName != 0 ? byName : a.name.compareTo(b.name);
    });
  return _Breakdown(groups, other, total);
}

/// Lát cắt thẻ "Phân bổ chi tiêu theo danh mục" — top **5** danh mục cha + nhóm
/// **"Khác"** (phần ngoài top 5 + tiền chi không gắn danh mục) xếp **cuối**,
/// chỉ xuất hiện khi có phần dư (FR-008/FR-009/FR-010/FR-011).
List<ReportSlice> reportBreakdown({
  required List<Transaction> transactions,
  required List<Category> categories,
  required DateRange range,
}) {
  final data = _breakdown(
    transactions: transactions,
    categories: categories,
    range: range,
  );
  if (data.total <= 0) return const [];

  final top = data.groups.take(5).toList();
  var otherAmount = data.other;
  for (final dropped in data.groups.skip(5)) {
    otherAmount += dropped.amount;
  }

  final amounts = [
    for (final g in top) g.amount,
    if (otherAmount > 0) otherAmount,
  ];
  final percents = percentSplit(amounts, data.total);

  return [
    for (var i = 0; i < top.length; i++)
      ReportSlice(
        categoryId: top[i].categoryId,
        name: top[i].name,
        icon: top[i].icon,
        color: top[i].color,
        rank: i,
        amount: top[i].amount,
        percent: percents[i],
      ),
    if (otherAmount > 0)
      ReportSlice(
        categoryId: null,
        name: 'Khác'.tr,
        icon: 'category',
        color: 0,
        rank: -1,
        amount: otherAmount,
        percent: percents.last,
      ),
  ];
}

/// Một dòng thẻ "Top danh mục chi tiêu" (data-model §4).
class ReportTopCategory {
  const ReportTopCategory({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
    required this.percent,
  });

  final int categoryId;
  final String name;
  final String icon;
  final int color;
  final int amount;

  /// `amount / tổng chi × 100` — bề rộng thanh tiến độ (không cần cộng = 100).
  final double percent;
}

/// Tối đa **5** danh mục chi nhiều nhất trong kỳ — **không** có dòng "Khác"
/// (FR-013); cùng nguồn nhóm với [reportBreakdown] ⇒ số tiền khớp lát cắt.
List<ReportTopCategory> reportTopCategories({
  required List<Transaction> transactions,
  required List<Category> categories,
  required DateRange range,
}) {
  final data = _breakdown(
    transactions: transactions,
    categories: categories,
    range: range,
  );
  if (data.total <= 0) return const [];
  return [
    for (final g in data.groups.take(5))
      ReportTopCategory(
        categoryId: g.categoryId!,
        name: g.name,
        icon: g.icon,
        color: g.color,
        amount: g.amount,
        percent: g.amount / data.total * 100,
      ),
  ];
}

/// Một dòng danh mục (và một lát cắt) màn **Chi tiết theo danh mục** (màn `02`,
/// PBI 23) — data-model §1.1. Không mang `icon`/`color` của danh mục: màn 02 cố
/// ý dùng **màu theo thứ hạng** (FR-007).
class ReportCategoryRow {
  const ReportCategoryRow({
    required this.categoryId,
    required this.name,
    required this.amount,
    required this.percent,
    required this.rank,
  });

  /// id danh mục **cha**; `null` = dòng gộp **"Khác"**.
  final int? categoryId;
  final String name;
  final int amount;

  /// % trên tổng chi, **đã chia để tổng mọi dòng = 100**.
  final int percent;

  /// `0…n-1` = hạng (chọn `chartPalette[rank % 5]`); `-1` = "Khác" (chỉ số 5).
  final int rank;
}

/// Kết quả dựng màn **Chi tiết theo danh mục** (data-model §1.2) — bất biến.
class ReportCategoryDetail {
  const ReportCategoryDetail({
    required this.period,
    required this.range,
    required this.total,
    required this.hasAnyTxn,
    required this.rows,
  });

  final ReportPeriod period;
  final DateRange range;

  /// Tổng **chi** của kỳ = Σ `rows[i].amount` (0 = không có chi tiêu).
  final int total;

  /// Kỳ có ít nhất 1 giao dịch **Thu/Chi** (transfer/adjustment không tính).
  final bool hasAnyTxn;

  /// **Toàn bộ** danh mục chi của kỳ, sắp giảm dần, + "Khác" cuối; rỗng khi
  /// `total == 0`.
  final List<ReportCategoryRow> rows;

  bool get isEmpty => total == 0;
}

/// Số liệu màn **Chi tiết theo danh mục** (FR-006…FR-010) — cùng nguồn nhóm
/// `_breakdown` với màn 01, chỉ khác là lấy **toàn bộ** danh mục thay vì top 5.
ReportCategoryDetail reportCategoryDetail({
  required List<Transaction> transactions,
  required List<Category> categories,
  required ReportPeriod period,
  required DateTime now,
}) {
  final range = reportPeriodRange(period, now);
  final totals = reportTotals(transactions, range);
  final hasAnyTxn = totals.income > 0 || totals.expense > 0;
  final data = _breakdown(
    transactions: transactions,
    categories: categories,
    range: range,
  );
  if (data.total <= 0) {
    return ReportCategoryDetail(
      period: period,
      range: range,
      total: 0,
      hasAnyTxn: hasAnyTxn,
      rows: const [],
    );
  }

  final amounts = [
    for (final g in data.groups) g.amount,
    if (data.other > 0) data.other,
  ];
  final percents = percentSplit(amounts, data.total);
  return ReportCategoryDetail(
    period: period,
    range: range,
    total: data.total,
    hasAnyTxn: hasAnyTxn,
    rows: [
      for (var i = 0; i < data.groups.length; i++)
        ReportCategoryRow(
          categoryId: data.groups[i].categoryId,
          name: data.groups[i].name,
          amount: data.groups[i].amount,
          percent: percents[i],
          rank: i,
        ),
      if (data.other > 0)
        ReportCategoryRow(
          categoryId: null,
          name: 'Khác'.tr,
          amount: data.other,
          percent: percents.last,
          rank: -1,
        ),
    ],
  );
}

/// Nhãn **tĩnh** chip kỳ màn 02 (FR-003): `Ngày 12/09/2026` ·
/// `Tuần 07/09–13/09/2026` (năm theo **ngày cuối kỳ**) · `Tháng 9/2026` ·
/// `Năm 2026`. Ghép danh từ kỳ **đã có bản dịch** với chuỗi ngày không phụ
/// thuộc ngôn ngữ.
String reportPeriodChipLabel(ReportPeriod period, DateRange range) {
  final last = range.end.subtract(const Duration(days: 1));
  final start = range.start;
  return switch (period) {
    ReportPeriod.day =>
      '${'Ngày'.tr} ${_two(start.day)}/${_two(start.month)}/${start.year}',
    ReportPeriod.week =>
      '${'Tuần'.tr} ${_two(start.day)}/${_two(start.month)}'
          '–${_two(last.day)}/${_two(last.month)}/${last.year}',
    ReportPeriod.month => '${'Tháng'.tr} ${start.month}/${start.year}',
    ReportPeriod.year => '${'Năm'.tr} ${start.year}',
  };
}

/// Nhãn giữa vòng tròn màn 02 (FR-004): `Tổng chi ngày/tuần/tháng/năm`.
String reportExpenseCenterLabel(ReportPeriod period) => switch (period) {
  ReportPeriod.day => 'Tổng chi ngày'.tr,
  ReportPeriod.week => 'Tổng chi tuần'.tr,
  ReportPeriod.month => 'Tổng chi tháng'.tr,
  ReportPeriod.year => 'Tổng chi năm'.tr,
};

/// Kết quả dựng màn Tổng quan Báo cáo (data-model §5) — bất biến.
class ReportView {
  const ReportView({
    required this.period,
    required this.range,
    required this.income,
    required this.expense,
    required this.bars,
    required this.slices,
    required this.top,
  });

  final ReportPeriod period;
  final DateRange range;
  final int income;
  final int expense;

  /// Đúng 6 phần tử.
  final List<ReportBar> bars;

  /// 0…6 phần tử.
  final List<ReportSlice> slices;

  /// 0…5 phần tử.
  final List<ReportTopCategory> top;

  /// Kỳ đang chọn **không có** thu/chi nào (transfer không tính) ⇒ cả 3 thẻ
  /// hiện trạng thái rỗng (FR-014/SC-009, data-model luật 23–25).
  bool get hasAnyTxn => income > 0 || expense > 0;

  /// Kỳ chỉ có Thu ⇒ biểu đồ vẫn vẽ, thẻ phân bổ + thẻ top rỗng (FR-015).
  bool get hasExpense => expense > 0;
}

/// Dựng toàn bộ số liệu màn Tổng quan cho [period] tại mốc [now].
ReportView buildReportView({
  required List<Transaction> transactions,
  required List<Category> categories,
  required ReportPeriod period,
  required DateTime now,
}) {
  final range = reportPeriodRange(period, now);
  final totals = reportTotals(transactions, range);
  return ReportView(
    period: period,
    range: range,
    income: totals.income,
    expense: totals.expense,
    bars: reportBarSeries(
      transactions: transactions,
      period: period,
      anchor: now,
    ),
    slices: reportBreakdown(
      transactions: transactions,
      categories: categories,
      range: range,
    ),
    top: reportTopCategories(
      transactions: transactions,
      categories: categories,
      range: range,
    ),
  );
}
