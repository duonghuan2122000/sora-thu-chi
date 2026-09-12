import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/budget/budget.dart';
import 'package:sora_thu_chi/core/budget/budget_view.dart';
import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/category/category_source.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';

/// Giao dịch Chi gọn cho test (amount âm như trong DB).
Transaction _expense(int categoryId, int amount, DateTime date) => Transaction(
  id: categoryId * 1000 + amount,
  walletId: 1,
  type: TxnType.expense,
  amount: -amount,
  date: date,
  categoryId: categoryId,
);

Transaction _income(int categoryId, int amount, DateTime date) => Transaction(
  id: categoryId * 1000 + amount,
  walletId: 1,
  type: TxnType.income,
  amount: amount,
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

  group('budgetScopeCategoryIds — bản thân + con trực tiếp (FR-006)', () {
    test('danh mục cha gồm chính nó + con, không lấy cháu', () {
      const threeLevels = [
        Category(id: 100, name: 'Cha', type: CategoryType.expense, icon: '', color: 0),
        Category(
          id: 101,
          name: 'Con',
          type: CategoryType.expense,
          icon: '',
          color: 0,
          parentId: 100,
        ),
        Category(
          id: 102,
          name: 'Cháu',
          type: CategoryType.expense,
          icon: '',
          color: 0,
          parentId: 101,
        ),
        Category(id: 200, name: 'Lạ', type: CategoryType.expense, icon: '', color: 0),
      ];
      final scope = budgetScopeCategoryIds(100, threeLevels);
      expect(scope, {100, 101});
      expect(scope.contains(102), isFalse);
      expect(scope.contains(200), isFalse);
    });

    test('danh mục con chỉ gồm chính nó', () {
      expect(budgetScopeCategoryIds(13, categories), {13});
    });

    test('danh mục cha seed "Ăn uống" (1) gồm 3 con 13/14/15', () {
      expect(budgetScopeCategoryIds(1, categories), {1, 13, 14, 15});
    });
  });

  group('budgetSpent — chỉ Chi, đúng phạm vi & khoảng ngày (FR-006/FR-007)', () {
    final range = DateRange(
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 10, 1),
    );

    test('cộng Chi của bản thân + con, bỏ Thu và chuyển khoản', () {
      final txs = [
        _expense(1, 300000, DateTime(2026, 9, 5)),
        _expense(13, 50000, DateTime(2026, 9, 20)), // con của 1
        _income(1, 900000, DateTime(2026, 9, 6)),
        Transaction(
          id: 900,
          walletId: 1,
          type: TxnType.transfer,
          amount: -400000,
          date: DateTime(2026, 9, 7),
          categoryId: 1,
        ),
        _expense(2, 70000, DateTime(2026, 9, 8)), // danh mục khác
      ];
      final spent = budgetSpent(
        categoryIds: budgetScopeCategoryIds(1, categories),
        transactions: txs,
        range: range,
      );
      expect(spent, 350000);
    });

    test('bỏ giao dịch ngoài khoảng ngày (end độc quyền)', () {
      final txs = [
        _expense(1, 100000, DateTime(2026, 8, 31, 23, 59)),
        _expense(1, 200000, DateTime(2026, 9, 1)),
        _expense(1, 400000, DateTime(2026, 10, 1)),
      ];
      final spent = budgetSpent(
        categoryIds: {1},
        transactions: txs,
        range: range,
      );
      expect(spent, 200000);
    });

    test('dòng cũ categoryId null không tính (không suy đoán theo tên)', () {
      final txs = [
        Transaction(
          id: 1,
          walletId: 1,
          type: TxnType.expense,
          category: 'Ăn uống',
          amount: -120000,
          date: DateTime(2026, 9, 3),
        ),
      ];
      expect(
        budgetSpent(categoryIds: {1}, transactions: txs, range: range),
        0,
      );
    });
  });

  group('budgetPeriodTransactions — danh sách Chi trong kỳ (PBI 21, FR-011)', () {
    final range = DateRange(
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 10, 1),
    );

    test('chỉ Chi, gồm danh mục con, đúng khoảng [start, end), mới nhất trước',
        () {
      final txs = [
        _expense(1, 100000, DateTime(2026, 9, 5, 9)),
        _expense(13, 50000, DateTime(2026, 9, 20, 18, 30)), // con của 1 — mới nhất
        _income(1, 900000, DateTime(2026, 9, 6)),
        Transaction(
          id: 901,
          walletId: 1,
          type: TxnType.transfer,
          amount: -400000,
          date: DateTime(2026, 9, 7),
          categoryId: 1,
        ),
        _expense(2, 70000, DateTime(2026, 9, 8)), // danh mục khác
        _expense(1, 300000, DateTime(2026, 9, 1)), // đúng start → có
        _expense(1, 300000, DateTime(2026, 10, 1)), // đúng end → không (nửa mở)
      ];
      final list = budgetPeriodTransactions(
        categoryIds: budgetScopeCategoryIds(1, categories),
        transactions: txs,
        range: range,
      );

      expect(list.map((t) => t.date).toList(), [
        DateTime(2026, 9, 20, 18, 30),
        DateTime(2026, 9, 5, 9),
        DateTime(2026, 9, 1),
      ]);
      expect(list.map((t) => -t.amount).reduce((a, b) => a + b), 450000);
    });

    test('budgetSpent khớp đúng tổng danh sách (SC-005 — một phép lọc)', () {
      final txs = [
        _expense(1, 100000, DateTime(2026, 9, 5)),
        _expense(13, 50000, DateTime(2026, 9, 20)),
        _expense(14, 25000, DateTime(2026, 9, 21)),
        _income(1, 900000, DateTime(2026, 9, 6)),
      ];
      final ids = budgetScopeCategoryIds(1, categories);
      final list = budgetPeriodTransactions(
        categoryIds: ids,
        transactions: txs,
        range: range,
      );
      expect(
        budgetSpent(categoryIds: ids, transactions: txs, range: range),
        list.fold<int>(0, (sum, t) => sum - t.amount),
      );
      expect(list.length, 3);
    });
  });

  group('budgetProgressLevel — 3 dải màu (FR-005)', () {
    test('45/84/96/107 rơi đúng dải', () {
      expect(budgetProgressLevel(45), ProgressLevel.normal);
      expect(budgetProgressLevel(84), ProgressLevel.near);
      expect(budgetProgressLevel(96), ProgressLevel.near);
      expect(budgetProgressLevel(107), ProgressLevel.over);
    });

    test('đúng 2 biên 80 và 100', () {
      expect(budgetProgressLevel(79.9), ProgressLevel.normal);
      expect(budgetProgressLevel(80), ProgressLevel.near);
      expect(budgetProgressLevel(99.9), ProgressLevel.near);
      expect(budgetProgressLevel(100), ProgressLevel.over);
    });
  });

  group('buildBudgetOverview — dòng, thẻ tổng, sắp xếp', () {
    final now = DateTime(2026, 9, 12, 10);
    final viewedMonth = DateTime(2026, 9, 1);

    test('tổng chỉ gồm dòng active; dòng ended/invalid bị loại', () {
      final budgets = [
        _budget(id: 1, categoryId: 1, amount: 3000000, startDate: DateTime(2026, 9, 1)),
        // Kết thúc: không lặp lại, kỳ chứa startDate đã qua (tháng 8).
        _budget(
          id: 2,
          categoryId: 2,
          amount: 1000000,
          isRecurring: false,
          startDate: DateTime(2026, 8, 10),
        ),
        // Không hợp lệ: danh mục không còn trong bảng.
        _budget(id: 3, categoryId: 999, amount: 500000, startDate: DateTime(2026, 9, 1)),
      ];
      final txs = [
        _expense(1, 600000, DateTime(2026, 9, 4)),
        _expense(2, 900000, DateTime(2026, 8, 20)), // kỳ của ngân sách ended
      ];

      final view = buildBudgetOverview(
        budgets: budgets,
        transactions: txs,
        categories: categories,
        now: now,
        viewedMonth: viewedMonth,
      );

      expect(view.rows.length, 3);
      expect(view.totalLimit, 3000000);
      expect(view.totalSpent, 600000);
      expect(view.totalPercent, 20);

      final byId = {for (final r in view.rows) r.budget.id: r};
      expect(byId[1]!.status, BudgetStatus.active);
      expect(byId[1]!.percent, 20);
      expect(byId[2]!.status, BudgetStatus.ended);
      expect(byId[2]!.spent, 900000);
      expect(byId[2]!.range.start, DateTime(2026, 8, 1));
      expect(byId[3]!.status, BudgetStatus.invalid);
    });

    test('sắp giảm dần theo %; ended/invalid xuống cuối', () {
      final budgets = [
        _budget(id: 1, categoryId: 5, amount: 1000000, startDate: DateTime(2026, 9, 1)), // 45%
        _budget(id: 2, categoryId: 1, amount: 3000000, startDate: DateTime(2026, 9, 1)), // 107%
        _budget(id: 3, categoryId: 6, amount: 1200000, startDate: DateTime(2026, 9, 1)), // 96%
        _budget(id: 4, categoryId: 4, amount: 2500000, startDate: DateTime(2026, 9, 1)), // 84%
        _budget(
          id: 5,
          categoryId: 2,
          amount: 1500000,
          isRecurring: false,
          startDate: DateTime(2026, 7, 1),
        ),
        _budget(id: 6, categoryId: 777, amount: 100000, startDate: DateTime(2026, 9, 1)),
      ];
      final txs = [
        _expense(5, 450000, DateTime(2026, 9, 2)),
        _expense(1, 3210000, DateTime(2026, 9, 2)),
        _expense(6, 1150000, DateTime(2026, 9, 2)),
        _expense(4, 2100000, DateTime(2026, 9, 2)),
      ];

      final view = buildBudgetOverview(
        budgets: budgets,
        transactions: txs,
        categories: categories,
        now: now,
        viewedMonth: viewedMonth,
      );

      expect(
        view.rows.map((r) => r.budget.id).toList(),
        [2, 3, 4, 1, 5, 6],
      );
      expect(view.rows.first.level, ProgressLevel.over);
      expect(view.rows[1].level, ProgressLevel.near);
    });

    test('daysLeft = số ngày còn lại của tháng đang xem (sàn 0)', () {
      final view = buildBudgetOverview(
        budgets: [
          _budget(id: 1, categoryId: 1, amount: 1000000, startDate: DateTime(2026, 9, 1)),
        ],
        transactions: const [],
        categories: categories,
        now: DateTime(2026, 9, 12),
        viewedMonth: viewedMonth,
      );
      expect(view.daysLeft, 19);

      final past = buildBudgetOverview(
        budgets: [
          _budget(id: 1, categoryId: 1, amount: 1000000, startDate: DateTime(2026, 9, 1)),
        ],
        transactions: const [],
        categories: categories,
        now: DateTime(2026, 9, 12),
        viewedMonth: DateTime(2026, 6, 1),
      );
      expect(past.daysLeft, 0);
    });

    test('ngân sách Tuần giữ kỳ của now khi đổi tháng đang xem (FR-002)', () {
      final weekly = _budget(
        id: 1,
        categoryId: 13,
        amount: 500000,
        period: BudgetPeriod.weekly,
        startDate: DateTime(2026, 9, 7),
      );
      final txs = [
        _expense(13, 120000, DateTime(2026, 9, 9)), // trong tuần 07–14/09
        _expense(13, 80000, DateTime(2026, 9, 2)), // tuần trước
      ];

      BudgetRow weeklyRow(DateTime view) => buildBudgetOverview(
        budgets: [weekly],
        transactions: txs,
        categories: categories,
        now: now,
        viewedMonth: view,
      ).rows.single;

      final sept = weeklyRow(DateTime(2026, 9, 1));
      final june = weeklyRow(DateTime(2026, 6, 1));

      expect(sept.range.start, DateTime(2026, 9, 7));
      expect(sept.spent, 120000);
      expect(june.range.start, sept.range.start);
      expect(june.spent, sept.spent);
    });

    test('ngân sách Tháng tính lại theo tháng đang xem (FR-002)', () {
      final monthly = _budget(
        id: 1,
        categoryId: 1,
        amount: 1000000,
        startDate: DateTime(2026, 6, 1),
      );
      final txs = [
        _expense(1, 300000, DateTime(2026, 9, 9)),
        _expense(1, 100000, DateTime(2026, 6, 9)),
      ];

      int spentFor(DateTime view) => buildBudgetOverview(
        budgets: [monthly],
        transactions: txs,
        categories: categories,
        now: now,
        viewedMonth: view,
      ).rows.single.spent;

      expect(spentFor(DateTime(2026, 9, 1)), 300000);
      expect(spentFor(DateTime(2026, 6, 1)), 100000);
    });

    test('tạo ngân sách giữa kỳ → đã chi tính từ đầu kỳ, không phải 0 (FR-007)', () {
      final view = buildBudgetOverview(
        budgets: [
          _budget(id: 1, categoryId: 1, amount: 3000000, startDate: DateTime(2026, 9, 12)),
        ],
        transactions: [_expense(1, 450000, DateTime(2026, 9, 3))],
        categories: categories,
        now: now,
        viewedMonth: viewedMonth,
      );
      expect(view.rows.single.spent, 450000);
      expect(view.rows.single.percent, 15);
    });

    test('ngân sách đã lưu trữ bị loại khỏi danh sách VÀ thẻ tổng (FR-016)',
        () {
      final view = buildBudgetOverview(
        budgets: [
          _budget(id: 1, categoryId: 1, amount: 3000000, startDate: DateTime(2026, 9, 1)),
          Budget(
            id: 2,
            categoryId: 5,
            amount: 2000000,
            period: BudgetPeriod.monthly,
            isRecurring: true,
            startDate: DateTime(2026, 9, 1),
            isArchived: true,
          ),
        ],
        transactions: [
          _expense(1, 600000, DateTime(2026, 9, 4)),
          _expense(5, 1900000, DateTime(2026, 9, 4)),
        ],
        categories: categories,
        now: now,
        viewedMonth: viewedMonth,
      );

      expect(view.rows.map((r) => r.budget.id).toList(), [1]);
      expect(view.totalLimit, 3000000);
      expect(view.totalSpent, 600000);
    });

    test('không có ngân sách → rỗng', () {
      final view = buildBudgetOverview(
        budgets: const [],
        transactions: const [],
        categories: categories,
        now: now,
        viewedMonth: viewedMonth,
      );
      expect(view.isEmpty, isTrue);
      expect(view.totalLimit, 0);
      expect(view.totalPercent, 0);
    });
  });
}
