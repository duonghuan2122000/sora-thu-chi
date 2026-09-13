import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sora_thu_chi/core/budget/budget.dart';
import 'package:sora_thu_chi/core/locale/sora_translations.dart';
import 'package:sora_thu_chi/core/notification/notification_content.dart';

/// Câu chữ thông báo (PBI 31) — module thuần; test cả `vi` (mặc định) và `en`.
void main() {
  group('dailyReminderContent (FR-008)', () {
    test('chưa ghi hôm nay ⇒ câu khẳng định đúng thực tế', () {
      final c = dailyReminderContent(hasTxnToday: false);
      expect(c.title, 'Nhắc ghi chép giao dịch');
      expect(c.body, 'Bạn chưa ghi giao dịch nào hôm nay.');
    });

    test('đã ghi hôm nay (cờ tắt) ⇒ KHÔNG khẳng định "chưa ghi" (AC#3)', () {
      final c = dailyReminderContent(hasTxnToday: true);
      expect(c.title, 'Nhắc ghi chép giao dịch');
      expect(c.body, isNot(contains('chưa ghi')));
      expect(c.body, isNotEmpty);
    });
  });

  group('budgetAlertContent (FR-007/AC#5)', () {
    test('ngưỡng sớm vs vượt mức phân biệt được BẰNG CHỮ', () {
      final early = budgetAlertContent(
        categoryName: 'Ăn uống',
        percent: 82,
        over: false,
        periodLabel: 'tháng 9',
      );
      final over = budgetAlertContent(
        categoryName: 'Ăn uống',
        percent: 104,
        over: true,
        periodLabel: 'tháng 9',
      );
      expect(early.title, 'Sắp vượt ngân sách Ăn uống');
      expect(over.title, 'Đã vượt ngân sách Ăn uống');
      expect(early.title, isNot(over.title));
      // Từ khoá phân biệt nằm ở TIÊU ĐỀ (không chỉ con số).
      expect(early.title, contains('Sắp vượt'));
      expect(over.title, contains('Đã vượt'));
    });

    test('mô tả nêu tên danh mục + % + kỳ (đúng mockup 04)', () {
      final c = budgetAlertContent(
        categoryName: 'Ăn uống',
        percent: 82,
        over: false,
        periodLabel: 'tháng 9',
      );
      expect(
        c.body,
        'Bạn đã dùng 82% ngân sách tháng 9 cho danh mục Ăn uống.',
      );
    });

    test('nhãn kỳ theo chu kỳ ngân sách', () {
      expect(
        budgetPeriodLabel(BudgetPeriod.monthly, DateTime(2026, 9, 1)),
        'tháng 9',
      );
      expect(
        budgetPeriodLabel(BudgetPeriod.yearly, DateTime(2026, 1, 1)),
        'năm 2026',
      );
      expect(
        budgetPeriodLabel(BudgetPeriod.weekly, DateTime(2026, 9, 7)),
        'tuần 07/09',
      );
    });
  });

  group('summaryContent (FR-009/AC#19/#20)', () {
    test('tuần vs tháng: tiêu đề khác nhau', () {
      expect(
        summaryContent(weekly: true, comparisonSentence: 'x').title,
        'Tổng kết tuần',
      );
      expect(
        summaryContent(weekly: false, comparisonSentence: 'x').title,
        'Tổng kết tháng',
      );
    });

    test('có câu so sánh ⇒ câu so sánh đứng trước dòng mời xem báo cáo', () {
      final c = summaryContent(
        weekly: true,
        comparisonSentence: 'Bạn đã chi nhiều hơn tuần trước 15%.',
      );
      expect(
        c.body,
        'Bạn đã chi nhiều hơn tuần trước 15%.\nXem chi tiết báo cáo.',
      );
    });

    test('kỳ trước rỗng ⇒ KHÔNG có câu so sánh, vẫn có dòng mời (AC#19/#20)', () {
      final c = summaryContent(weekly: false, comparisonSentence: '');
      expect(c.body, 'Xem chi tiết báo cáo.');
      expect(c.body, isNot(contains('∞')));
      expect(c.body, isNot(contains('null')));
    });

    test('câu so sánh chỉ có khoảng trắng cũng coi như rỗng', () {
      expect(
        summaryContent(weekly: false, comparisonSentence: '   ').body,
        'Xem chi tiết báo cáo.',
      );
    });
  });

  group('bản tiếng Anh (R12/FR-027)', () {
    setUp(() {
      Get.addTranslations(SoraTranslations().keys);
      Get.locale = const Locale('en');
    });
    tearDown(() => Get.locale = null);

    test('tiêu đề + mô tả 3 loại đều dịch được', () {
      final daily = dailyReminderContent(hasTxnToday: false);
      expect(daily.title, 'Log your transactions');
      expect(daily.body, "You haven't logged any transaction today.");

      final alert = budgetAlertContent(
        categoryName: 'Ăn uống',
        percent: 82,
        over: true,
        periodLabel: 'tháng 9',
      );
      expect(alert.title, 'Ăn uống budget exceeded');
      expect(alert.body, contains('82%'));

      final summary = summaryContent(weekly: true, comparisonSentence: '');
      expect(summary.title, 'Weekly summary');
      expect(summary.body, 'See the full report.');
    });

    test('số liệu không bị dịch: 82% và nhãn kỳ giữ nguyên số', () {
      final label = budgetPeriodLabel(BudgetPeriod.monthly, DateTime(2026, 9, 1));
      expect(label, 'month 9');
      expect(
        budgetAlertContent(
          categoryName: 'Food',
          percent: 82,
          over: false,
          periodLabel: label,
        ).body,
        contains('82%'),
      );
    });
  });
}
