import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/budget/budget.dart';
import 'package:sora_thu_chi/core/budget/budget_rules.dart';
import 'package:sora_thu_chi/core/category/category.dart';

Budget _budget({
  int id = 0,
  int categoryId = 1,
  int amount = 3000000,
  BudgetPeriod period = BudgetPeriod.monthly,
  bool isRecurring = true,
  DateTime? startDate,
}) => Budget(
  id: id,
  categoryId: categoryId,
  amount: amount,
  period: period,
  isRecurring: isRecurring,
  startDate: startDate ?? DateTime(2026, 9, 1),
);

const _category = Category(
  id: 1,
  name: 'Ăn uống',
  type: CategoryType.expense,
  icon: 'restaurant',
  color: 0xFF0F6E56,
);

void main() {
  group('budgetOverlaps — cùng danh mục + cùng chu kỳ (FR-016, R10)', () {
    test('hai ngân sách lặp lại cùng danh mục + chu kỳ → chồng', () {
      expect(
        budgetOverlaps(
          _budget(id: 1, startDate: DateTime(2026, 9, 1)),
          _budget(id: 2, startDate: DateTime(2026, 12, 1)),
        ),
        isTrue,
      );
    });

    test('khác chu kỳ cùng danh mục → song song, không chồng', () {
      expect(
        budgetOverlaps(
          _budget(id: 1),
          _budget(id: 2, period: BudgetPeriod.yearly),
        ),
        isFalse,
      );
    });

    test('khác danh mục → không chồng', () {
      expect(
        budgetOverlaps(_budget(id: 1), _budget(id: 2, categoryId: 4)),
        isFalse,
      );
    });

    test('không lặp lại, kỳ đã qua không chồng với ngân sách kỳ sau', () {
      final julyOnly = _budget(
        id: 1,
        isRecurring: false,
        startDate: DateTime(2026, 7, 5),
      );
      final september = _budget(id: 2, startDate: DateTime(2026, 9, 1));
      expect(budgetOverlaps(julyOnly, september), isFalse);
      expect(budgetOverlaps(september, julyOnly), isFalse);
    });

    test('không lặp lại hai kỳ liền nhau (Tháng 8 và Tháng 9) → không chồng', () {
      expect(
        budgetOverlaps(
          _budget(id: 1, isRecurring: false, startDate: DateTime(2026, 8, 10)),
          _budget(id: 2, isRecurring: false, startDate: DateTime(2026, 9, 2)),
        ),
        isFalse,
      );
    });

    test('một lặp lại + một không lặp lại cùng kỳ → chồng', () {
      expect(
        budgetOverlaps(
          _budget(id: 1, startDate: DateTime(2026, 9, 1)),
          _budget(id: 2, isRecurring: false, startDate: DateTime(2026, 9, 20)),
        ),
        isTrue,
      );
    });

    test('Tuần không lặp lại chồng Tuần kế tiếp cùng danh mục → không', () {
      expect(
        budgetOverlaps(
          _budget(
            id: 1,
            period: BudgetPeriod.weekly,
            isRecurring: false,
            startDate: DateTime(2026, 9, 7),
          ),
          _budget(
            id: 2,
            period: BudgetPeriod.weekly,
            isRecurring: false,
            startDate: DateTime(2026, 9, 14),
          ),
        ),
        isFalse,
      );
    });
  });

  group('findOverlappingBudget — bỏ qua chính nó khi sửa', () {
    test('tìm thấy ngân sách khác chồng lấn', () {
      final found = findOverlappingBudget(
        candidate: _budget(id: 0, startDate: DateTime(2026, 9, 20)),
        existing: [_budget(id: 7, startDate: DateTime(2026, 9, 1))],
      );
      expect(found?.id, 7);
    });

    test('sửa chính nó (cùng id) → không tự chặn', () {
      final found = findOverlappingBudget(
        candidate: _budget(id: 7, amount: 5000000),
        existing: [_budget(id: 7, amount: 3000000)],
      );
      expect(found, isNull);
    });

    test('không vướng ai → null', () {
      final found = findOverlappingBudget(
        candidate: _budget(id: 0, categoryId: 9),
        existing: [_budget(id: 7, categoryId: 1)],
      );
      expect(found, isNull);
    });
  });

  group('validateBudgetForm — thông báo lỗi (FR-015)', () {
    test('thiếu danh mục → khoá lỗi danh mục', () {
      expect(
        validateBudgetForm(category: null, amount: 3000000),
        'Vui lòng chọn danh mục.',
      );
    });

    test('tiền 0 hoặc âm → khoá lỗi số tiền', () {
      expect(
        validateBudgetForm(category: _category, amount: 0),
        'Vui lòng nhập số tiền lớn hơn 0.',
      );
      expect(
        validateBudgetForm(category: _category, amount: -1),
        'Vui lòng nhập số tiền lớn hơn 0.',
      );
    });

    test('hợp lệ → null', () {
      expect(validateBudgetForm(category: _category, amount: 1), isNull);
    });

    test('khoá lỗi chồng lấn khớp chuỗi hiển thị cho người dùng', () {
      expect(
        budgetOverlapMessage,
        'Đã có ngân sách cho danh mục này trong kỳ. Hãy sửa ngân sách đang có.',
      );
    });
  });
}
