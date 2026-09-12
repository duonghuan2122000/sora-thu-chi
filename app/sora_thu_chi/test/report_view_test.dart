import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/report/report_view.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';

/// Test module thuần màn Tổng quan Báo cáo (PBI 22) — không DB, không widget.
/// Mọi mốc thời gian bơm tham số (không dùng giờ thật).

Transaction _txn({
  required int id,
  required TxnType type,
  required int amount,
  required DateTime date,
  int? categoryId,
  String category = '',
}) => Transaction(
  id: id,
  walletId: 1,
  type: type,
  category: category,
  amount: amount,
  date: date,
  categoryId: categoryId,
);

Transaction _income(int id, int amount, DateTime date, {int? categoryId}) =>
    _txn(
      id: id,
      type: TxnType.income,
      amount: amount,
      date: date,
      categoryId: categoryId,
    );

Transaction _expense(int id, int amount, DateTime date, {int? categoryId}) =>
    _txn(
      id: id,
      type: TxnType.expense,
      amount: -amount,
      date: date,
      categoryId: categoryId,
    );

Category _cat(
  int id,
  String name, {
  CategoryType type = CategoryType.expense,
  int? parentId,
  bool isHidden = false,
  String icon = 'category',
  int color = 0xFF0F6E56,
}) => Category(
  id: id,
  name: name,
  type: type,
  icon: icon,
  color: color,
  parentId: parentId,
  isHidden: isHidden,
);

void main() {
  setUp(() => Get.reset());
  tearDown(() {
    Get.reset();
  });

  group('reportPeriodRange — kỳ dương lịch nửa mở', () {
    test('Ngày: [00:00 anchor, +1 ngày)', () {
      final r = reportPeriodRange(ReportPeriod.day, DateTime(2026, 3, 15, 14, 30));
      expect(r.start, DateTime(2026, 3, 15));
      expect(r.end, DateTime(2026, 3, 16));
    });

    test('Tuần bắt đầu Thứ Hai; Chủ Nhật thuộc tuần đó', () {
      // 2026-03-15 là Chủ Nhật.
      expect(DateTime(2026, 3, 15).weekday, DateTime.sunday);
      final r = reportPeriodRange(ReportPeriod.week, DateTime(2026, 3, 15));
      expect(r.start, DateTime(2026, 3, 9));
      expect(r.end, DateTime(2026, 3, 16));
    });

    test('Tuần giữa tuần: Thứ Tư → Thứ Hai đầu tuần', () {
      final r = reportPeriodRange(ReportPeriod.week, DateTime(2026, 3, 18));
      expect(r.start, DateTime(2026, 3, 16));
      expect(r.end, DateTime(2026, 3, 23));
    });

    test('Tháng: mùng 1 → mùng 1 tháng sau', () {
      final r = reportPeriodRange(ReportPeriod.month, DateTime(2026, 3, 15));
      expect(r.start, DateTime(2026, 3, 1));
      expect(r.end, DateTime(2026, 4, 1));
    });

    test('Tháng 12: end sang 1/1 năm sau', () {
      final r = reportPeriodRange(ReportPeriod.month, DateTime(2026, 12, 20));
      expect(r.start, DateTime(2026, 12, 1));
      expect(r.end, DateTime(2027, 1, 1));
    });

    test('Năm: 1/1 → 1/1 năm sau', () {
      final r = reportPeriodRange(ReportPeriod.year, DateTime(2026, 7, 4));
      expect(r.start, DateTime(2026, 1, 1));
      expect(r.end, DateTime(2027, 1, 1));
    });

    test('biên nửa mở: mốc đúng end KHÔNG thuộc kỳ', () {
      final r = reportPeriodRange(ReportPeriod.day, DateTime(2026, 3, 15));
      expect(r.contains(DateTime(2026, 3, 15, 0, 0)), isTrue);
      expect(r.contains(DateTime(2026, 3, 15, 23, 59)), isTrue);
      expect(r.contains(DateTime(2026, 3, 16)), isFalse);
      expect(r.contains(DateTime(2026, 3, 14, 23, 59)), isFalse);
    });
  });

  group('reportPeriodSeries — 6 kỳ liên tiếp, kỳ đang chọn ở cuối', () {
    test('Tháng: 15/1/2026 → T8…T1 (lùi qua mốc năm)', () {
      final series = reportPeriodSeries(
        ReportPeriod.month,
        DateTime(2026, 1, 15),
      );
      expect(series, hasLength(6));
      expect(series.first.start, DateTime(2025, 8, 1));
      expect(series.last.start, DateTime(2026, 1, 1));
      expect(series.last.end, DateTime(2026, 2, 1));
    });

    test('Ngày: 6 ngày liền trước, kỳ đang chọn ở cuối', () {
      final series = reportPeriodSeries(ReportPeriod.day, DateTime(2026, 3, 15));
      expect(series, hasLength(6));
      expect(series.first.start, DateTime(2026, 3, 10));
      expect(series.last.start, DateTime(2026, 3, 15));
    });

    test('Năm: 6 năm liên tiếp', () {
      final series = reportPeriodSeries(
        ReportPeriod.year,
        DateTime(2026, 5, 1),
      );
      expect(series.first.start, DateTime(2021, 1, 1));
      expect(series.last.start, DateTime(2026, 1, 1));
    });

    test('Tuần: lùi 7 ngày, không lệch qua tháng 30/31 ngày', () {
      final series = reportPeriodSeries(
        ReportPeriod.week,
        DateTime(2026, 3, 15), // Chủ Nhật
      );
      expect(series.last.start, DateTime(2026, 3, 9));
      expect(series.first.start, DateTime(2026, 2, 2));
    });

    test('kỳ đang chọn luôn là phần tử cuối, các kỳ liền kề không chồng', () {
      final series = reportPeriodSeries(
        ReportPeriod.month,
        DateTime(2026, 3, 31),
      );
      for (var i = 0; i < series.length - 1; i++) {
        expect(series[i].end, series[i + 1].start);
      }
      expect(series.last.start, DateTime(2026, 3, 1));
      expect(
        reportPeriodRange(ReportPeriod.month, DateTime(2026, 3, 31)).start,
        series.last.start,
      );
    });
  });

  group('reportTotals — một phép lọc duy nhất', () {
    final range = reportPeriodRange(ReportPeriod.month, DateTime(2026, 3, 15));

    test('cộng đúng thu/chi trong kỳ', () {
      final result = reportTotals([
        _income(1, 500000, DateTime(2026, 3, 2)),
        _expense(2, 200000, DateTime(2026, 3, 10)),
        _expense(3, 100000, DateTime(2026, 3, 20)),
      ], range);
      expect(result.income, 500000);
      expect(result.expense, 300000);
    });

    test('loại transfer + adjustment', () {
      final result = reportTotals([
        _income(1, 500000, DateTime(2026, 3, 2)),
        _txn(
          id: 2,
          type: TxnType.transfer,
          amount: -900000,
          date: DateTime(2026, 3, 5),
        ),
        _txn(
          id: 3,
          type: TxnType.transfer,
          amount: 900000,
          date: DateTime(2026, 3, 5),
        ),
        _txn(
          id: 4,
          type: TxnType.adjustment,
          amount: 50000,
          date: DateTime(2026, 3, 6),
        ),
      ], range);
      expect(result.income, 500000);
      expect(result.expense, 0);
    });

    test('ngoài kỳ không tính, ngày tương lai trong kỳ vẫn tính', () {
      final result = reportTotals([
        _income(1, 100000, DateTime(2026, 2, 28)),
        _income(2, 100000, DateTime(2026, 4, 1)),
        _expense(3, 70000, DateTime(2026, 3, 31, 23, 59)),
      ], range);
      expect(result.income, 0);
      expect(result.expense, 70000);
    });
  });

  group('reportBarSeries', () {
    test('kỳ rỗng → 6 cột giá trị 0 nhưng vẫn có nhãn', () {
      final bars = reportBarSeries(
        transactions: const [],
        period: ReportPeriod.month,
        anchor: DateTime(2026, 3, 15),
      );
      expect(bars, hasLength(6));
      for (final b in bars) {
        expect(b.income, 0);
        expect(b.expense, 0);
        expect(b.label, isNotEmpty);
      }
      expect(bars.last.isCurrent, isTrue);
      expect(bars.first.isCurrent, isFalse);
    });

    test('cột cuối là kỳ đang chọn và cộng đúng số của kỳ đó', () {
      final bars = reportBarSeries(
        transactions: [
          _income(1, 300000, DateTime(2026, 3, 3)),
          _expense(2, 120000, DateTime(2026, 3, 4)),
          _income(3, 900000, DateTime(2026, 2, 3)),
        ],
        period: ReportPeriod.month,
        anchor: DateTime(2026, 3, 15),
      );
      expect(bars.last.income, 300000);
      expect(bars.last.expense, 120000);
      expect(bars[4].income, 900000); // T2
      expect(bars.map((b) => b.range.start).toList(), [
        DateTime(2025, 10, 1),
        DateTime(2025, 11, 1),
        DateTime(2025, 12, 1),
        DateTime(2026, 1, 1),
        DateTime(2026, 2, 1),
        DateTime(2026, 3, 1),
      ]);
    });

    test('nhãn theo đơn vị kỳ', () {
      final monthBars = reportBarSeries(
        transactions: const [],
        period: ReportPeriod.month,
        anchor: DateTime(2026, 3, 15),
      );
      expect(monthBars.last.label, contains('3'));
      final yearBars = reportBarSeries(
        transactions: const [],
        period: ReportPeriod.year,
        anchor: DateTime(2026, 3, 15),
      );
      expect(yearBars.last.label, contains('2026'));
      final dayBars = reportBarSeries(
        transactions: const [],
        period: ReportPeriod.day,
        anchor: DateTime(2026, 3, 15),
      );
      expect(dayBars.last.label, contains('15'));
    });
  });

  group('percentSplit — chia theo phần dư lớn nhất', () {
    test('[1,1,1] → [34,33,33], tổng 100', () {
      expect(percentSplit([1, 1, 1], 3), [34, 33, 33]);
    });

    test('[1,2] → [33,67], tổng 100', () {
      expect(percentSplit([1, 2], 3), [33, 67]);
    });

    test('tổng luôn = 100 với 5–6 phần tử', () {
      final five = percentSplit([10, 20, 30, 25, 15], 100);
      expect(five.reduce((a, b) => a + b), 100);
      final six = percentSplit([1, 1, 1, 1, 1, 1], 6);
      expect(six.reduce((a, b) => a + b), 100);
    });

    test('total <= 0 → toàn 0', () {
      expect(percentSplit([0, 0], 0), [0, 0]);
    });
  });

  group('reportBreakdown — gộp danh mục cha + nhóm "Khác"', () {
    final range = reportPeriodRange(ReportPeriod.month, DateTime(2026, 3, 15));
    final categories = [
      _cat(1, 'Ăn uống'),
      _cat(2, 'Cà phê', parentId: 1),
      _cat(3, 'Đi lại'),
      _cat(4, 'Nhà cửa'),
      _cat(5, 'Sức khỏe'),
      _cat(6, 'Học tập'),
      _cat(7, 'Giải trí'),
      _cat(8, 'Mua sắm', isHidden: true),
    ];

    test('gộp con vào cha (tên/icon/màu lấy từ cha)', () {
      final slices = reportBreakdown(
        transactions: [
          _expense(1, 200000, DateTime(2026, 3, 2), categoryId: 1),
          _expense(2, 80000, DateTime(2026, 3, 3), categoryId: 2),
          _expense(3, 100000, DateTime(2026, 3, 4), categoryId: 3),
        ],
        categories: categories,
        range: range,
      );
      expect(slices, hasLength(2));
      expect(slices.first.categoryId, 1);
      expect(slices.first.amount, 280000);
      expect(slices.first.name, 'Ăn uống');
      expect(slices.first.rank, 0);
    });

    test('≤ 5 danh mục ⇒ KHÔNG có "Khác" và Σ% = 100', () {
      final slices = reportBreakdown(
        transactions: [
          _expense(1, 100000, DateTime(2026, 3, 2), categoryId: 1),
          _expense(2, 100000, DateTime(2026, 3, 3), categoryId: 3),
        ],
        categories: categories,
        range: range,
      );
      expect(slices.map((s) => s.categoryId), isNot(contains(null)));
      expect(slices.map((s) => s.percent).reduce((a, b) => a + b), 100);
    });

    test('6 danh mục ⇒ top 5 + "Khác" xếp cuối', () {
      final slices = reportBreakdown(
        transactions: [
          _expense(1, 600000, DateTime(2026, 3, 2), categoryId: 1),
          _expense(2, 500000, DateTime(2026, 3, 2), categoryId: 3),
          _expense(3, 400000, DateTime(2026, 3, 2), categoryId: 4),
          _expense(4, 300000, DateTime(2026, 3, 2), categoryId: 5),
          _expense(5, 200000, DateTime(2026, 3, 2), categoryId: 6),
          _expense(6, 100000, DateTime(2026, 3, 2), categoryId: 7),
        ],
        categories: categories,
        range: range,
      );
      expect(slices, hasLength(6));
      final other = slices.last;
      expect(other.categoryId, isNull);
      expect(other.rank, -1);
      expect(other.amount, 100000);
      expect(slices.first.amount, 600000);
      expect(slices.map((s) => s.amount).reduce((a, b) => a + b), 2100000);
      expect(slices.map((s) => s.percent).reduce((a, b) => a + b), 100);
    });

    test('tiền chi không gắn danh mục ⇒ vào "Khác" (kể cả khi ≤ 5 danh mục)', () {
      final slices = reportBreakdown(
        transactions: [
          _expense(1, 100000, DateTime(2026, 3, 2), categoryId: 1),
          _expense(2, 50000, DateTime(2026, 3, 3)),
        ],
        categories: categories,
        range: range,
      );
      expect(slices, hasLength(2));
      expect(slices.last.categoryId, isNull);
      expect(slices.last.amount, 50000);
    });

    test('danh mục ẨN vẫn được tính', () {
      final slices = reportBreakdown(
        transactions: [
          _expense(1, 100000, DateTime(2026, 3, 2), categoryId: 8),
        ],
        categories: categories,
        range: range,
      );
      expect(slices, hasLength(1));
      expect(slices.first.name, 'Mua sắm');
    });

    test('đồng hạng ⇒ tên tăng dần', () {
      final slices = reportBreakdown(
        transactions: [
          _expense(1, 100000, DateTime(2026, 3, 2), categoryId: 1), // Ăn uống
          _expense(2, 100000, DateTime(2026, 3, 3), categoryId: 4), // Nhà cửa
        ],
        categories: categories,
        range: range,
      );
      expect(slices.map((s) => s.name).toList(), ['Ăn uống', 'Nhà cửa']);
    });

    test('Thu/transfer không vào; Σ tiền lát = tổng chi', () {
      final txns = [
        _expense(1, 100000, DateTime(2026, 3, 2), categoryId: 1),
        _income(2, 900000, DateTime(2026, 3, 2), categoryId: 1),
        _txn(
          id: 3,
          type: TxnType.transfer,
          amount: -500000,
          date: DateTime(2026, 3, 2),
        ),
      ];
      final slices = reportBreakdown(
        transactions: txns,
        categories: categories,
        range: range,
      );
      final total = reportTotals(txns, range);
      expect(slices.map((s) => s.amount).reduce((a, b) => a + b), total.expense);
      expect(total.expense, 100000);
    });

    test('con trỏ tới cha không còn tồn tại ⇒ nhóm theo chính nó', () {
      final slices = reportBreakdown(
        transactions: [
          _expense(1, 100000, DateTime(2026, 3, 2), categoryId: 99),
        ],
        categories: categories,
        range: range,
      );
      expect(slices, hasLength(1));
      expect(slices.first.categoryId, 99);
    });

    test('kỳ không có chi ⇒ rỗng', () {
      final slices = reportBreakdown(
        transactions: [
          _income(1, 100000, DateTime(2026, 3, 2), categoryId: 1),
        ],
        categories: categories,
        range: range,
      );
      expect(slices, isEmpty);
    });
  });

  group('reportTopCategories', () {
    final range = reportPeriodRange(ReportPeriod.month, DateTime(2026, 3, 15));
    final categories = [
      _cat(1, 'Ăn uống'),
      _cat(3, 'Đi lại'),
      _cat(4, 'Nhà cửa'),
      _cat(5, 'Sức khỏe'),
      _cat(6, 'Học tập'),
      _cat(7, 'Giải trí'),
    ];

    test('> 5 danh mục ⇒ đúng 5 dòng, KHÔNG có "Khác", giảm dần', () {
      final top = reportTopCategories(
        transactions: [
          _expense(1, 600000, DateTime(2026, 3, 2), categoryId: 1),
          _expense(2, 500000, DateTime(2026, 3, 2), categoryId: 3),
          _expense(3, 400000, DateTime(2026, 3, 2), categoryId: 4),
          _expense(4, 300000, DateTime(2026, 3, 2), categoryId: 5),
          _expense(5, 200000, DateTime(2026, 3, 2), categoryId: 6),
          _expense(6, 100000, DateTime(2026, 3, 2), categoryId: 7),
        ],
        categories: categories,
        range: range,
      );
      expect(top, hasLength(5));
      expect(top.map((t) => t.categoryId), isNot(contains(null)));
      expect(top.first.amount, 600000);
      expect(top.last.amount, 200000);
      expect(top.first.percent, closeTo(600000 / 2100000 * 100, 0.001));
    });

    test('số tiền top khớp lát cắt cùng danh mục', () {
      final txns = [
        _expense(1, 600000, DateTime(2026, 3, 2), categoryId: 1),
        _expense(2, 500000, DateTime(2026, 3, 2), categoryId: 3),
      ];
      final top = reportTopCategories(
        transactions: txns,
        categories: categories,
        range: range,
      );
      final slices = reportBreakdown(
        transactions: txns,
        categories: categories,
        range: range,
      );
      for (final t in top) {
        final slice = slices.firstWhere((s) => s.categoryId == t.categoryId);
        expect(t.amount, slice.amount);
      }
    });
  });

  group('buildReportView — cờ trạng thái rỗng', () {
    final categories = [_cat(1, 'Ăn uống')];

    ReportView build(List<Transaction> txns) => buildReportView(
      transactions: txns,
      categories: categories,
      period: ReportPeriod.month,
      now: DateTime(2026, 3, 15),
    );

    test('rỗng: không giao dịch ⇒ cả 2 cờ false', () {
      final view = build(const []);
      expect(view.income, 0);
      expect(view.expense, 0);
      expect(view.hasAnyTxn, isFalse);
      expect(view.hasExpense, isFalse);
      expect(view.bars, hasLength(6));
      expect(view.slices, isEmpty);
      expect(view.top, isEmpty);
    });

    test('chỉ Thu ⇒ hasAnyTxn true, hasExpense false', () {
      final view = build([_income(1, 500000, DateTime(2026, 3, 2))]);
      expect(view.hasAnyTxn, isTrue);
      expect(view.hasExpense, isFalse);
      expect(view.slices, isEmpty);
    });

    test('chỉ Chi ⇒ cả 2 cờ true', () {
      final view = build([
        _expense(1, 100000, DateTime(2026, 3, 2), categoryId: 1),
      ]);
      expect(view.hasAnyTxn, isTrue);
      expect(view.hasExpense, isTrue);
      expect(view.slices, hasLength(1));
      expect(view.top, hasLength(1));
    });

    test('chỉ transfer ⇒ như rỗng', () {
      final view = build([
        _txn(
          id: 1,
          type: TxnType.transfer,
          amount: -500000,
          date: DateTime(2026, 3, 2),
        ),
        _txn(
          id: 2,
          type: TxnType.transfer,
          amount: 500000,
          date: DateTime(2026, 3, 2),
        ),
      ]);
      expect(view.hasAnyTxn, isFalse);
      expect(view.hasExpense, isFalse);
    });

    test('kỳ đang chọn + range khớp reportPeriodRange', () {
      final view = build(const []);
      expect(view.period, ReportPeriod.month);
      expect(view.range.start, DateTime(2026, 3, 1));
      expect(view.range.end, DateTime(2026, 4, 1));
    });
  });

  group('reportCategoryDetail — màn Chi tiết theo danh mục (PBI 23)', () {
    ReportCategoryDetail build(
      List<Transaction> transactions,
      List<Category> categories, {
      ReportPeriod period = ReportPeriod.month,
      DateTime? now,
    }) => reportCategoryDetail(
      transactions: transactions,
      categories: categories,
      period: period,
      now: now ?? DateTime(2026, 3, 15),
    );

    test('7 danh mục ⇒ đủ 7 dòng (không cắt ở 5), Σ tiền = total, Σ % = 100', () {
      final categories = [for (var i = 1; i <= 7; i++) _cat(i, 'Danh mục $i')];
      final detail = build([
        for (var i = 1; i <= 7; i++)
          _expense(i, 100000 * (8 - i), DateTime(2026, 3, 5), categoryId: i),
      ], categories);

      expect(detail.rows, hasLength(7));
      expect(detail.total, 100000 * 28);
      var sum = 0;
      var percents = 0;
      for (final row in detail.rows) {
        sum += row.amount;
        percents += row.percent;
      }
      expect(sum, detail.total);
      expect(percents, 100);
      expect(detail.hasAnyTxn, isTrue);
      expect(detail.isEmpty, isFalse);
    });

    test('dòng "Khác" xếp cuối và CHỈ có khi có tiền chi không gắn danh mục', () {
      final withOther = build([
        _expense(1, 100000, DateTime(2026, 3, 5), categoryId: 1),
        _expense(2, 50000, DateTime(2026, 3, 6)),
      ], [_cat(1, 'Ăn uống')]);
      expect(withOther.rows, hasLength(2));
      expect(withOther.rows.last.categoryId, isNull);
      expect(withOther.rows.last.amount, 50000);
      expect(withOther.rows.last.rank, -1);

      final withoutOther = build([
        _expense(1, 100000, DateTime(2026, 3, 5), categoryId: 1),
      ], [_cat(1, 'Ăn uống')]);
      expect(withoutOther.rows, hasLength(1));
      expect(withoutOther.rows.single.categoryId, 1);

      // "Khác" lớn hơn mọi danh mục thật vẫn nằm cuối (luật 9).
      final bigOther = build([
        _expense(1, 10000, DateTime(2026, 3, 5), categoryId: 1),
        _expense(2, 90000, DateTime(2026, 3, 6)),
      ], [_cat(1, 'Ăn uống')]);
      expect(bigOther.rows.first.categoryId, 1);
      expect(bigOther.rows.last.categoryId, isNull);
    });

    test('gộp con → cha; danh mục ẩn vẫn tính; con mồ côi nhóm theo chính nó', () {
      final categories = [
        _cat(1, 'Ăn uống'),
        _cat(2, 'Cà phê', parentId: 1),
        _cat(3, 'Ẩn', isHidden: true),
        _cat(9, 'Mồ côi', parentId: 99),
      ];
      final detail = build([
        _expense(1, 100000, DateTime(2026, 3, 5), categoryId: 1),
        _expense(2, 50000, DateTime(2026, 3, 6), categoryId: 2),
        _expense(3, 30000, DateTime(2026, 3, 7), categoryId: 3),
        _txn(
          id: 4,
          type: TxnType.expense,
          amount: -20000,
          date: DateTime(2026, 3, 8),
          categoryId: 9,
          category: 'Mồ côi',
        ),
      ], categories);

      final byId = {for (final r in detail.rows) r.categoryId: r};
      expect(byId[1]!.amount, 150000); // con gộp vào cha
      expect(byId[3]!.amount, 30000); // danh mục ẩn vẫn tính
      expect(byId[9]!.amount, 20000); // mồ côi nhóm theo chính nó
      expect(byId.containsKey(null), isFalse);
      expect(detail.total, 200000);
    });

    test('đồng hạng → tên tăng dần theo thứ tự chữ Việt; rank = chỉ số', () {
      final detail = build([
        _expense(1, 50000, DateTime(2026, 3, 5), categoryId: 1),
        _expense(2, 50000, DateTime(2026, 3, 6), categoryId: 2),
      ], [_cat(1, 'Nhà cửa'), _cat(2, 'Ăn uống')]);

      expect(detail.rows.map((r) => r.name).toList(), ['Ăn uống', 'Nhà cửa']);
      expect(detail.rows[0].rank, 0);
      expect(detail.rows[1].rank, 1);
    });

    test('1 danh mục ⇒ 1 dòng 100%', () {
      final detail = build([
        _expense(1, 4200000, DateTime(2026, 3, 5), categoryId: 1),
      ], [_cat(1, 'Ăn uống')]);

      expect(detail.rows, hasLength(1));
      expect(detail.rows.single.percent, 100);
      expect(detail.rows.single.amount, detail.total);
    });

    test('kỳ rỗng ⇒ rows rỗng, total 0, hasAnyTxn false', () {
      final detail = build(const [], [_cat(1, 'Ăn uống')]);
      expect(detail.rows, isEmpty);
      expect(detail.total, 0);
      expect(detail.hasAnyTxn, isFalse);
      expect(detail.isEmpty, isTrue);
    });

    test('kỳ chỉ Thu ⇒ total 0 nhưng hasAnyTxn true', () {
      final detail = build([
        _income(1, 500000, DateTime(2026, 3, 5)),
      ], [_cat(1, 'Ăn uống')]);
      expect(detail.total, 0);
      expect(detail.rows, isEmpty);
      expect(detail.hasAnyTxn, isTrue);
    });

    test('kỳ chỉ transfer ⇒ total 0 và hasAnyTxn false', () {
      final detail = build([
        _txn(
          id: 1,
          type: TxnType.transfer,
          amount: -500000,
          date: DateTime(2026, 3, 5),
        ),
      ], const []);
      expect(detail.total, 0);
      expect(detail.hasAnyTxn, isFalse);
    });

    test('kỳ giữ nguyên loại kỳ + range của kỳ đang xem', () {
      final detail = build(
        const [],
        const [],
        period: ReportPeriod.week,
        now: DateTime(2026, 3, 18),
      );
      expect(detail.period, ReportPeriod.week);
      expect(detail.range.start, DateTime(2026, 3, 16));
      expect(detail.range.end, DateTime(2026, 3, 23));
    });
  });

  group('reportPeriodChipLabel / reportExpenseCenterLabel (PBI 23)', () {
    String chip(ReportPeriod period, DateTime anchor) =>
        reportPeriodChipLabel(period, reportPeriodRange(period, anchor));

    test('4 kỳ: Ngày / Tuần / Tháng / Năm', () {
      final anchor = DateTime(2026, 9, 12); // Thứ Bảy
      expect(chip(ReportPeriod.day, anchor), 'Ngày 12/09/2026');
      expect(chip(ReportPeriod.week, anchor), 'Tuần 07/09–13/09/2026');
      expect(chip(ReportPeriod.month, anchor), 'Tháng 9/2026');
      expect(chip(ReportPeriod.year, anchor), 'Năm 2026');
    });

    test('tuần vắt qua tháng: năm lấy theo ngày cuối kỳ', () {
      expect(
        chip(ReportPeriod.week, DateTime(2026, 3, 31)),
        'Tuần 30/03–05/04/2026',
      );
    });

    test('tuần vắt qua năm: năm lấy theo ngày cuối kỳ', () {
      expect(
        chip(ReportPeriod.week, DateTime(2026, 12, 31)),
        'Tuần 28/12–03/01/2027',
      );
    });

    test('nhãn giữa vòng tròn theo 4 kỳ', () {
      expect(reportExpenseCenterLabel(ReportPeriod.day), 'Tổng chi ngày');
      expect(reportExpenseCenterLabel(ReportPeriod.week), 'Tổng chi tuần');
      expect(reportExpenseCenterLabel(ReportPeriod.month), 'Tổng chi tháng');
      expect(reportExpenseCenterLabel(ReportPeriod.year), 'Tổng chi năm');
    });
  });
}
