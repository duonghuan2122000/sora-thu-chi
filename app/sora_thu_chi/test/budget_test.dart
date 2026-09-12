import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/budget/budget.dart';
import 'package:sora_thu_chi/core/budget/budget_view.dart';

void main() {
  group('Budget — nhãn chu kỳ (PBI 20)', () {
    test('label 3 chu kỳ trả tiếng Việt (Get.locale null → giữ khoá)', () {
      expect(BudgetPeriod.weekly.label, 'Tuần');
      expect(BudgetPeriod.monthly.label, 'Tháng');
      expect(BudgetPeriod.yearly.label, 'Năm');
    });
  });

  group('budgetPeriodRange — mốc kỳ (research R5)', () {
    test('Tuần bắt đầu Thứ Hai: 2026-01-01 (Thứ Năm) → 2025-12-29', () {
      final range = budgetPeriodRange(BudgetPeriod.weekly, DateTime(2026, 1, 1));
      expect(range.start, DateTime(2025, 12, 29));
      expect(range.start.weekday, DateTime.monday);
      expect(range.end, DateTime(2026, 1, 5));
      expect(range.end.difference(range.start).inDays, 7);
    });

    test('Tuần: mốc đúng Thứ Hai giữ nguyên đầu kỳ', () {
      final range = budgetPeriodRange(BudgetPeriod.weekly, DateTime(2026, 9, 7));
      expect(range.start, DateTime(2026, 9, 7));
      expect(range.end, DateTime(2026, 9, 14));
    });

    test('Tháng dương lịch: 2026-09-12 → 01/09 đến 01/10', () {
      final range = budgetPeriodRange(
        BudgetPeriod.monthly,
        DateTime(2026, 9, 12, 23, 59),
      );
      expect(range.start, DateTime(2026, 9, 1));
      expect(range.end, DateTime(2026, 10, 1));
    });

    test('Tháng 12 không nhảy năm sai', () {
      final range = budgetPeriodRange(
        BudgetPeriod.monthly,
        DateTime(2026, 12, 31),
      );
      expect(range.start, DateTime(2026, 12, 1));
      expect(range.end, DateTime(2027, 1, 1));
    });

    test('Năm dương lịch: 2026-09-12 → 2026-01-01 đến 2027-01-01', () {
      final range = budgetPeriodRange(
        BudgetPeriod.yearly,
        DateTime(2026, 9, 12),
      );
      expect(range.start, DateTime(2026, 1, 1));
      expect(range.end, DateTime(2027, 1, 1));
    });

    test('end ĐỘC QUYỀN — mốc đúng end không thuộc kỳ', () {
      final range = budgetPeriodRange(BudgetPeriod.monthly, DateTime(2026, 9, 12));
      expect(range.contains(DateTime(2026, 9, 1)), isTrue);
      expect(range.contains(DateTime(2026, 9, 30, 23, 59)), isTrue);
      expect(range.contains(range.end), isFalse);
      expect(range.contains(DateTime(2026, 8, 31, 23, 59)), isFalse);
    });
  });
}
