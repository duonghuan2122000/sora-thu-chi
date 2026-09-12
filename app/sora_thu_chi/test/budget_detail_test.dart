import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/budget/budget.dart';
import 'package:sora_thu_chi/core/budget/budget_detail.dart';
import 'package:sora_thu_chi/core/budget/budget_view.dart';
import 'package:sora_thu_chi/core/category/category_source.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';

/// Giao dịch Chi gọn cho test (amount âm như trong DB).
Transaction _expense(
  int categoryId,
  int amount,
  DateTime date, {
  String note = '',
}) => Transaction(
  id: categoryId * 100000 + amount,
  walletId: 1,
  type: TxnType.expense,
  amount: -amount,
  note: note,
  date: date,
  categoryId: categoryId,
);

Budget _budget({
  int id = 1,
  required int categoryId,
  required int amount,
  BudgetPeriod period = BudgetPeriod.monthly,
  bool isRecurring = true,
  required DateTime startDate,
}) => Budget(
  id: id,
  categoryId: categoryId,
  amount: amount,
  period: period,
  isRecurring: isRecurring,
  startDate: startDate,
);

void main() {
  final categories = CategorySource.all;
  final sept = DateRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 10, 1));

  group('budgetDaysLeft / budgetElapsedPercent — tính cả hôm nay (R6)', () {
    test('12/09 trong tháng 9 → 18 ngày còn lại / 40% ngày đã qua', () {
      final now = DateTime(2026, 9, 12, 10);
      expect(budgetDaysLeft(sept, now), 18);
      expect(budgetElapsedPercent(sept, now), 40);
    });

    test('ngày đầu kỳ → cả kỳ còn lại, 1 ngày đã qua', () {
      final now = DateTime(2026, 9, 1, 0, 5);
      expect(budgetDaysLeft(sept, now), 29);
      expect(budgetElapsedPercent(sept, now), closeTo(100 / 30, 0.001));
    });

    test('ngày cuối kỳ → 0 ngày còn lại (không âm)', () {
      expect(budgetDaysLeft(sept, DateTime(2026, 9, 30, 23, 59)), 0);
      expect(budgetElapsedPercent(sept, DateTime(2026, 9, 30, 23, 59)), 100);
    });

    test('kỳ đã qua → 0 ngày, 100%', () {
      final now = DateTime(2026, 11, 5);
      expect(budgetDaysLeft(sept, now), 0);
      expect(budgetElapsedPercent(sept, now), 100);
    });

    test('kỳ tương lai → chưa trôi ngày nào', () {
      final now = DateTime(2026, 8, 20);
      expect(budgetDaysLeft(sept, now), 30);
      expect(budgetElapsedPercent(sept, now), 0);
    });
  });

  group('budgetPaceWarning — chi nhanh hơn nhịp (FR-007, SC-004)', () {
    test('107% ngân sách khi mới qua 40% ngày → true', () {
      expect(
        budgetPaceWarning(usedPercent: 107, elapsedPercent: 40, ended: false),
        isTrue,
      );
    });

    test('40% ngân sách khi đã qua 90% ngày → false', () {
      expect(
        budgetPaceWarning(usedPercent: 40, elapsedPercent: 90, ended: false),
        isFalse,
      );
    });

    test('kỳ đã kết thúc → luôn false dù % dùng cao', () {
      expect(
        budgetPaceWarning(usedPercent: 107, elapsedPercent: 100, ended: true),
        isFalse,
      );
    });
  });

  group('budgetDefaultRange — kỳ mặc định (FR-020/FR-023)', () {
    test('ngân sách lặp lại → kỳ chứa now', () {
      final b = _budget(categoryId: 1, amount: 3000000, startDate: DateTime(2026, 8, 1));
      final range = budgetDefaultRange(b, DateTime(2026, 9, 12));
      expect(range.start, DateTime(2026, 9, 1));
      expect(range.end, DateTime(2026, 10, 1));
    });

    test('không lặp lại → kỳ chứa startDate dù đã qua', () {
      final b = _budget(
        categoryId: 1,
        amount: 500000,
        isRecurring: false,
        startDate: DateTime(2026, 8, 10),
      );
      final range = budgetDefaultRange(b, DateTime(2026, 9, 12));
      expect(range.start, DateTime(2026, 8, 1));
      expect(range.end, DateTime(2026, 9, 1));
    });
  });

  group('budgetComparisonSeries — 3 kỳ gần nhất (FR-008/FR-010)', () {
    final now = DateTime(2026, 9, 12, 10);

    test('Tháng: 3 kỳ liên tiếp, kỳ đang xem là phần tử cuối', () {
      final budget = _budget(
        categoryId: 1,
        amount: 3000000,
        startDate: DateTime(2026, 7, 15),
      );
      final series = budgetComparisonSeries(
        budget: budget,
        categories: categories,
        transactions: [
          _expense(1, 1000000, DateTime(2026, 7, 20)),
          _expense(1, 3500000, DateTime(2026, 8, 20)),
          _expense(1, 3210000, DateTime(2026, 9, 5)),
          _expense(1, 900000, DateTime(2026, 6, 20)), // trước khi bắt đầu
        ],
        now: now,
        viewedRange: sept,
      );

      expect(series.length, 3);
      expect(series.map((p) => p.range.start).toList(), [
        DateTime(2026, 7, 1),
        DateTime(2026, 8, 1),
        DateTime(2026, 9, 1),
      ]);
      expect(series.map((p) => p.spent).toList(), [1000000, 3500000, 3210000]);
      expect(series.map((p) => p.limit).toList(), [3000000, 3000000, 3000000]);
      expect(series.map((p) => p.level).toList(), [
        ProgressLevel.normal,
        ProgressLevel.over,
        ProgressLevel.over,
      ]);
      expect(series.map((p) => p.ended).toList(), [true, true, false]);
      expect(series.last.range.start, sept.start);
    });

    test('kỳ đang xem ở quá khứ → 3 kỳ tính đến nó, không có kỳ sau', () {
      final budget = _budget(
        categoryId: 1,
        amount: 3000000,
        startDate: DateTime(2026, 1, 1),
      );
      final series = budgetComparisonSeries(
        budget: budget,
        categories: categories,
        transactions: const [],
        now: now,
        viewedRange: DateRange(
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 9, 1),
        ),
      );

      expect(series.map((p) => p.range.start).toList(), [
        DateTime(2026, 6, 1),
        DateTime(2026, 7, 1),
        DateTime(2026, 8, 1),
      ]);
    });

    test('ngân sách mới có 1 kỳ → đúng 1 phần tử (kịch bản 19)', () {
      final budget = _budget(
        categoryId: 1,
        amount: 3000000,
        startDate: DateTime(2026, 9, 5),
      );
      final series = budgetComparisonSeries(
        budget: budget,
        categories: categories,
        transactions: const [],
        now: now,
        viewedRange: sept,
      );
      expect(series, hasLength(1));
      expect(series.single.range.start, DateTime(2026, 9, 1));
    });

    test('ngân sách Tuần: lùi theo tuần, dừng ở tuần chứa startDate', () {
      final budget = _budget(
        categoryId: 1,
        amount: 500000,
        period: BudgetPeriod.weekly,
        startDate: DateTime(2026, 8, 24), // Thứ Hai
      );
      final series = budgetComparisonSeries(
        budget: budget,
        categories: categories,
        transactions: const [],
        now: now,
        viewedRange: DateRange(
          start: DateTime(2026, 9, 7),
          end: DateTime(2026, 9, 14),
        ),
      );
      expect(series.map((p) => p.range.start).toList(), [
        DateTime(2026, 8, 24),
        DateTime(2026, 8, 31),
        DateTime(2026, 9, 7),
      ]);
    });

    test('ngân sách Năm: 3 năm gần nhất tính đến kỳ đang xem', () {
      final budget = _budget(
        categoryId: 1,
        amount: 100000000,
        period: BudgetPeriod.yearly,
        startDate: DateTime(2024, 5, 1),
      );
      final series = budgetComparisonSeries(
        budget: budget,
        categories: categories,
        transactions: const [],
        now: now,
        viewedRange: DateRange(
          start: DateTime(2026, 1, 1),
          end: DateTime(2027, 1, 1),
        ),
      );
      expect(series.map((p) => p.range.start.year).toList(), [2024, 2025, 2026]);
    });

    test('sửa giới hạn → cột Dự kiến mọi kỳ đổi, số thực tế không hồi tố', () {
      final txs = [
        _expense(1, 2500000, DateTime(2026, 8, 20)),
        _expense(1, 1000000, DateTime(2026, 9, 5)),
      ];
      List<BudgetPeriodSummary> seriesOf(int amount) => budgetComparisonSeries(
        budget: _budget(
          categoryId: 1,
          amount: amount,
          startDate: DateTime(2026, 8, 1),
        ),
        categories: categories,
        transactions: txs,
        now: now,
        viewedRange: sept,
      );

      final before = seriesOf(3000000);
      final after = seriesOf(6000000);
      expect(before.map((p) => p.limit).toList(), [3000000, 3000000]);
      expect(after.map((p) => p.limit).toList(), [6000000, 6000000]);
      expect(after.map((p) => p.spent).toList(), [2500000, 1000000]);
      expect(before.first.level, ProgressLevel.near);
      expect(after.first.level, ProgressLevel.normal);
    });
  });

  group('budgetPeriodOptions — bộ chọn kỳ (FR-023, kịch bản 3)', () {
    final now = DateTime(2026, 9, 12, 10);

    test('Tháng: từ kỳ startDate đến kỳ hiện tại, tăng dần', () {
      final options = budgetPeriodOptions(
        _budget(categoryId: 1, amount: 3000000, startDate: DateTime(2026, 7, 15)),
        now,
      );
      expect(options.map((r) => r.start).toList(), [
        DateTime(2026, 7, 1),
        DateTime(2026, 8, 1),
        DateTime(2026, 9, 1),
      ]);
      expect(options.last.end, DateTime(2026, 10, 1));
    });

    test('Tuần: các tuần liên tiếp, bắt đầu Thứ Hai', () {
      final options = budgetPeriodOptions(
        _budget(
          categoryId: 1,
          amount: 500000,
          period: BudgetPeriod.weekly,
          startDate: DateTime(2026, 8, 26), // Thứ Tư → tuần bắt đầu 24/8
        ),
        now,
      );
      expect(options.map((r) => r.start).toList(), [
        DateTime(2026, 8, 24),
        DateTime(2026, 8, 31),
        DateTime(2026, 9, 7),
      ]);
      expect(options.every((r) => r.start.weekday == DateTime.monday), isTrue);
    });

    test('Năm: các năm từ startDate đến năm hiện tại', () {
      final options = budgetPeriodOptions(
        _budget(
          categoryId: 1,
          amount: 100000000,
          period: BudgetPeriod.yearly,
          startDate: DateTime(2024, 5, 1),
        ),
        now,
      );
      expect(options.map((r) => r.start.year).toList(), [2024, 2025, 2026]);
    });

    test('không lặp lại → đúng 1 lựa chọn, không có kỳ trước startDate', () {
      final options = budgetPeriodOptions(
        _budget(
          categoryId: 1,
          amount: 500000,
          isRecurring: false,
          startDate: DateTime(2026, 8, 10),
        ),
        now,
      );
      expect(options, hasLength(1));
      expect(options.single.start, DateTime(2026, 8, 1));
    });

    test('ngân sách mới bắt đầu trong kỳ hiện tại → 1 lựa chọn', () {
      final options = budgetPeriodOptions(
        _budget(categoryId: 1, amount: 3000000, startDate: DateTime(2026, 9, 5)),
        now,
      );
      expect(options, hasLength(1));
      expect(options.single.start, DateTime(2026, 9, 1));
    });
  });

  group('buildBudgetDetail — số liệu một kỳ (FR-003…FR-006, SC-005)', () {
    final now = DateTime(2026, 9, 12, 10);


    test('đã dùng gồm danh mục con, bỏ Thu & transfer; vượt/ngày khớp', () {
      final budget = _budget(categoryId: 1, amount: 3000000, startDate: DateTime(2026, 9, 1));
      final detail = buildBudgetDetail(
        budget: budget,
        categories: categories,
        transactions: [
          _expense(1, 2000000, DateTime(2026, 9, 3)),
          _expense(13, 1210000, DateTime(2026, 9, 4)), // con của "Ăn uống"
          _expense(2, 900000, DateTime(2026, 9, 5)), // danh mục khác
          Transaction(
            id: 900,
            walletId: 1,
            type: TxnType.income,
            amount: 5000000,
            date: DateTime(2026, 9, 6),
            categoryId: 1,
          ),
          Transaction(
            id: 901,
            walletId: 1,
            type: TxnType.transfer,
            amount: -400000,
            date: DateTime(2026, 9, 7),
            categoryId: 1,
          ),
        ],
        now: now,
      );

      expect(detail.spent, 3210000);
      expect(detail.percent, 107);
      expect(detail.level, ProgressLevel.over);
      expect(detail.overAmount, 210000);
      expect(detail.remainingAmount, 0);
      expect(detail.ended, isFalse);
      expect(detail.daysLeft, 18);
      expect(detail.elapsedPercent, 40);
      expect(detail.showPaceWarning, isTrue);
      expect(detail.transactions.length, 2);
      expect(
        detail.transactions.fold<int>(0, (s, t) => s - t.amount),
        detail.spent,
      );
    });

    test('chưa vượt → còn lại, không cảnh báo khi chi chậm hơn nhịp', () {
      final detail = buildBudgetDetail(
        budget: _budget(categoryId: 5, amount: 1000000, startDate: DateTime(2026, 9, 1)),
        categories: categories,
        transactions: [_expense(5, 400000, DateTime(2026, 9, 2))],
        now: now,
      );
      expect(detail.percent, 40);
      expect(detail.level, ProgressLevel.normal);
      expect(detail.overAmount, 0);
      expect(detail.remainingAmount, 600000);
      expect(detail.showPaceWarning, isFalse);
    });

    test('đúng 100% → vượt 100% với số tiền vượt 0', () {
      final detail = buildBudgetDetail(
        budget: _budget(categoryId: 5, amount: 1000000, startDate: DateTime(2026, 9, 1)),
        categories: categories,
        transactions: [_expense(5, 1000000, DateTime(2026, 9, 2))],
        now: now,
      );
      expect(detail.percent, 100);
      expect(detail.level, ProgressLevel.over);
      expect(detail.overAmount, 0);
      expect(detail.remainingAmount, 0);
    });

    test('kỳ đã qua → ended, 0 ngày, không cảnh báo nhịp', () {
      final detail = buildBudgetDetail(
        budget: _budget(
          categoryId: 5,
          amount: 1000000,
          isRecurring: false,
          startDate: DateTime(2026, 8, 10),
        ),
        categories: categories,
        transactions: [_expense(5, 300000, DateTime(2026, 8, 20))],
        now: now,
      );
      expect(detail.range.start, DateTime(2026, 8, 1));
      expect(detail.spent, 300000);
      expect(detail.ended, isTrue);
      expect(detail.daysLeft, 0);
      expect(detail.showPaceWarning, isFalse);
    });

    test('kỳ rỗng → đã dùng 0, danh sách rỗng, không cảnh báo', () {
      final detail = buildBudgetDetail(
        budget: _budget(categoryId: 1, amount: 3000000, startDate: DateTime(2026, 9, 1)),
        categories: categories,
        transactions: const [],
        now: now,
      );
      expect(detail.spent, 0);
      expect(detail.percent, 0);
      expect(detail.remainingAmount, 3000000);
      expect(detail.transactions, isEmpty);
      expect(detail.showPaceWarning, isFalse);
    });

    test('danh mục đã xóa → category null (trạng thái không hợp lệ — FR-019)', () {
      final detail = buildBudgetDetail(
        budget: _budget(categoryId: 999, amount: 1000000, startDate: DateTime(2026, 9, 1)),
        categories: categories,
        transactions: const [],
        now: now,
      );
      expect(detail.category, isNull);
    });

    test('viewedRange bơm vào → số liệu tính theo kỳ đó', () {
      final detail = buildBudgetDetail(
        budget: _budget(categoryId: 1, amount: 3000000, startDate: DateTime(2026, 8, 1)),
        categories: categories,
        transactions: [
          _expense(1, 1000000, DateTime(2026, 8, 5)),
          _expense(1, 3210000, DateTime(2026, 9, 5)),
        ],
        now: now,
        viewedRange: DateRange(start: DateTime(2026, 8, 1), end: DateTime(2026, 9, 1)),
      );
      expect(detail.spent, 1000000);
      expect(detail.ended, isTrue);
      expect(detail.transactions.length, 1);
    });

    test('số dư giới hạn 0 → percent 0, không chia cho 0', () {
      final detail = buildBudgetDetail(
        budget: _budget(categoryId: 1, amount: 0, startDate: DateTime(2026, 9, 1)),
        categories: categories,
        transactions: const [],
        now: now,
      );
      expect(detail.percent, 0);
      expect(detail.level, ProgressLevel.normal);
    });
  });
}
