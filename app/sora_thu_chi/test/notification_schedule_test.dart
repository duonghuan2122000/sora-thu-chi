import 'package:flutter_test/flutter_test.dart';
import 'package:sora_thu_chi/core/notification/notification_schedule.dart';

/// Tầng thuần của engine (PBI 31) — thuần Dart, không cần drift/plugin/thiết bị.
void main() {
  group('dailyFireMoments', () {
    test('cửa sổ 30 ngày chỉ chứa ngày được chọn (AC#4/SC-003)', () {
      // now = Chủ Nhật 13/09/2026; chỉ chọn Thứ Hai (ISO 1).
      final moments = dailyFireMoments(
        now: DateTime(2026, 9, 13, 10),
        hour: 20,
        minute: 30,
        weekdays: const [1],
      );
      expect(moments, hasLength(5));
      for (final m in moments) {
        expect(m.weekday, DateTime.monday);
        expect(m.hour, 20);
        expect(m.minute, 30);
      }
      expect(moments.first, DateTime(2026, 9, 14, 20, 30));
      expect(moments.last, DateTime(2026, 10, 12, 20, 30));
    });

    test('cả 7 ngày → 30 mốc, đúng cửa sổ [hôm nay, hôm nay + 29]', () {
      final moments = dailyFireMoments(
        now: DateTime(2026, 9, 13, 10),
        hour: 20,
        minute: 0,
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
      );
      expect(moments, hasLength(30));
      expect(moments.first, DateTime(2026, 9, 13, 20, 0));
      expect(moments.last, DateTime(2026, 10, 12, 20, 0));
    });

    test('bỏ mốc đã trôi qua trong hôm nay (FR-028 — không bắn bù)', () {
      // Hôm nay 13/09 21:00, giờ nhắc 20:30 ⇒ mốc hôm nay đã qua.
      final moments = dailyFireMoments(
        now: DateTime(2026, 9, 13, 21),
        hour: 20,
        minute: 30,
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
      );
      expect(moments, hasLength(29));
      expect(moments.first, DateTime(2026, 9, 14, 20, 30));
    });

    test('đúng phút đang diễn ra ⇒ coi như đã qua (không lên lịch tức thì)', () {
      final moments = dailyFireMoments(
        now: DateTime(2026, 9, 13, 20, 30),
        hour: 20,
        minute: 30,
        weekdays: const [7],
      );
      expect(moments, hasLength(4)); // 20/09, 27/09, 04/10, 11/10
      expect(moments.first, DateTime(2026, 9, 20, 20, 30));
    });

    test('tập ngày rỗng ⇒ rỗng; giờ/phút ngoài miền được kẹp', () {
      expect(
        dailyFireMoments(
          now: DateTime(2026, 9, 13),
          hour: 20,
          minute: 0,
          weekdays: const [],
        ),
        isEmpty,
      );
      final clamped = dailyFireMoments(
        now: DateTime(2026, 9, 13, 10),
        hour: 99,
        minute: 99,
        weekdays: const [7],
      );
      expect(clamped.first, DateTime(2026, 9, 13, 23, 59));
    });
  });

  group('nextWeeklySummaryMoment', () {
    test('hôm nay là Chủ Nhật & giờ chưa qua ⇒ hôm nay', () {
      expect(
        nextWeeklySummaryMoment(DateTime(2026, 9, 13, 10), 20, 0),
        DateTime(2026, 9, 13, 20, 0),
      );
    });

    test('hôm nay là Chủ Nhật & giờ đã qua ⇒ Chủ Nhật sau', () {
      expect(
        nextWeeklySummaryMoment(DateTime(2026, 9, 13, 21), 20, 0),
        DateTime(2026, 9, 20, 20, 0),
      );
    });

    test('giữa tuần ⇒ Chủ Nhật gần nhất', () {
      // Thứ Tư 16/09/2026.
      expect(
        nextWeeklySummaryMoment(DateTime(2026, 9, 16, 8), 20, 0),
        DateTime(2026, 9, 20, 20, 0),
      );
    });
  });

  group('nextMonthlySummaryMoment — ngày cuối tháng (AC#18/G3)', () {
    test('tháng 31 ngày', () {
      expect(
        nextMonthlySummaryMoment(DateTime(2026, 1, 10), 20, 0),
        DateTime(2026, 1, 31, 20, 0),
      );
    });

    test('tháng 30 ngày', () {
      expect(
        nextMonthlySummaryMoment(DateTime(2026, 4, 10), 20, 0),
        DateTime(2026, 4, 30, 20, 0),
      );
    });

    test('tháng 2 thường → 28', () {
      expect(
        nextMonthlySummaryMoment(DateTime(2027, 2, 10), 20, 0),
        DateTime(2027, 2, 28, 20, 0),
      );
    });

    test('tháng 2 nhuận → 29', () {
      expect(
        nextMonthlySummaryMoment(DateTime(2028, 2, 10), 20, 0),
        DateTime(2028, 2, 29, 20, 0),
      );
    });

    test('đã qua giờ của ngày cuối tháng ⇒ tháng sau', () {
      expect(
        nextMonthlySummaryMoment(DateTime(2026, 9, 30, 21), 20, 0),
        DateTime(2026, 10, 31, 20, 0),
      );
    });

    test('qua năm mới vẫn đúng (tháng 12 → tháng 1 năm sau)', () {
      expect(
        nextMonthlySummaryMoment(DateTime(2026, 12, 31, 21), 20, 0),
        DateTime(2027, 1, 31, 20, 0),
      );
    });
  });

  group('khoá nghiệp vụ (R7)', () {
    test('đúng định dạng từng loại', () {
      expect(dailyEntryKey(DateTime(2026, 9, 13)), 'daily:2026-09-13');
      expect(
        summaryWeekEntryKey(DateTime(2026, 9, 7)),
        'summary:week:2026-09-07',
      );
      expect(summaryMonthEntryKey(DateTime(2026, 9, 13)), 'summary:month:2026-09');
      expect(
        budgetEntryKey(
          budgetId: 3,
          over: true,
          periodStart: DateTime(2026, 9, 1),
        ),
        'budget:over:3:2026-09-01',
      );
      expect(
        budgetEntryKey(
          budgetId: 3,
          over: false,
          periodStart: DateTime(2026, 9, 1),
        ),
        'budget:early:3:2026-09-01',
      );
    });

    test('khoá mang kỳ ⇒ kỳ mới là khoá mới (chống trùng không vĩnh viễn)', () {
      expect(
        dailyEntryKey(DateTime(2026, 9, 13)),
        isNot(dailyEntryKey(DateTime(2026, 9, 14))),
      );
      expect(
        budgetEntryKey(
          budgetId: 3,
          over: true,
          periodStart: DateTime(2026, 9, 1),
        ),
        isNot(
          budgetEntryKey(
            budgetId: 3,
            over: true,
            periodStart: DateTime(2026, 10, 1),
          ),
        ),
      );
    });
  });

  group('notificationIdFor (R7 — FNV-1a 32-bit)', () {
    test('cùng chuỗi ⇒ cùng số, luôn ≥ 0', () {
      const key = 'daily:2026-09-13';
      final a = notificationIdFor(key);
      final b = notificationIdFor(key);
      expect(a, b);
      expect(a, greaterThanOrEqualTo(0));
    });

    test('khoá khác ⇒ số khác (bộ khoá thật của engine)', () {
      final keys = [
        'daily:2026-09-13',
        'daily:2026-09-14',
        'summary:week:2026-09-07',
        'summary:month:2026-09',
        'budget:early:3:2026-09-01',
        'budget:over:3:2026-09-01',
      ];
      final ids = keys.map(notificationIdFor).toSet();
      expect(ids, hasLength(keys.length));
    });

    test('khoá rỗng vẫn là số hợp lệ (không ném)', () {
      expect(notificationIdFor(''), greaterThanOrEqualTo(0));
    });
  });
}
