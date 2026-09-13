import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/date_label.dart';
import 'package:sora_thu_chi/core/notification/app_notification.dart';

void main() {
  // 2026-09-13 là Chủ Nhật; 2026-09-10 là Thứ Năm; 2026-08-24 là Thứ Hai.
  final now = DateTime(2026, 9, 13, 9, 0);

  group('notificationGroup — ngày lịch, không theo số giờ (luật 18)', () {
    test('cùng ngày lịch → today (kể cả sớm/muộn trong ngày)', () {
      expect(
        notificationGroup(DateTime(2026, 9, 13, 0, 1), now),
        NotificationGroup.today,
      );
      expect(
        notificationGroup(DateTime(2026, 9, 13, 23, 59), now),
        NotificationGroup.today,
      );
    });

    test('23:59 hôm qua với now 00:01 → thisWeek (1 ngày lịch)', () {
      expect(
        notificationGroup(
          DateTime(2026, 9, 12, 23, 59),
          DateTime(2026, 9, 13, 0, 1),
        ),
        NotificationGroup.thisWeek,
      );
    });

    test('1 và 7 ngày trước → thisWeek; 8 ngày → earlier', () {
      expect(
        notificationGroup(DateTime(2026, 9, 12), now),
        NotificationGroup.thisWeek,
      );
      expect(
        notificationGroup(DateTime(2026, 9, 6), now),
        NotificationGroup.thisWeek,
      );
      expect(
        notificationGroup(DateTime(2026, 9, 5), now),
        NotificationGroup.earlier,
      );
    });

    test('khác tháng/năm vẫn tính đúng theo ngày lịch', () {
      expect(
        notificationGroup(DateTime(2026, 8, 31), now),
        NotificationGroup.earlier,
      );
      expect(
        notificationGroup(DateTime(2025, 9, 13), now),
        NotificationGroup.earlier,
      );
      expect(
        notificationGroup(DateTime(2026, 9, 12), now),
        NotificationGroup.thisWeek,
      );
    });

    test('mục ở tương lai (đồng hồ lệch) → today, không âm', () {
      expect(
        notificationGroup(DateTime(2026, 9, 14), now),
        NotificationGroup.today,
      );
    });

    test('nhãn nhóm đúng 3 chuỗi', () {
      expect(NotificationGroup.today.label, 'HÔM NAY');
      expect(NotificationGroup.thisWeek.label, 'TUẦN NÀY');
      expect(NotificationGroup.earlier.label, 'TRƯỚC ĐÓ');
    });
  });

  group('notificationTimeLabel — 3 dạng (luật 19)', () {
    test('cùng ngày → HH:mm', () {
      expect(
        notificationTimeLabel(DateTime(2026, 9, 13, 20, 30), now),
        '20:30',
      );
      expect(notificationTimeLabel(DateTime(2026, 9, 13, 7, 5), now), '07:05');
    });

    test('1…7 ngày → tên thứ đầy đủ', () {
      expect(
        notificationTimeLabel(DateTime(2026, 9, 10, 20, 30), now),
        'Thứ Năm',
      );
      expect(notificationTimeLabel(DateTime(2026, 9, 12), now), 'Thứ Bảy');
    });

    test('hơn 7 ngày → dd/MM', () {
      expect(notificationTimeLabel(DateTime(2026, 8, 24), now), '24/08');
      expect(notificationTimeLabel(DateTime(2026, 9, 5), now), '05/09');
    });
  });

  group('weekdayName (R9/R14)', () {
    test('7 giá trị ISO 1…7', () {
      expect(weekdayName(1), 'Thứ Hai');
      expect(weekdayName(2), 'Thứ Ba');
      expect(weekdayName(3), 'Thứ Tư');
      expect(weekdayName(4), 'Thứ Năm');
      expect(weekdayName(5), 'Thứ Sáu');
      expect(weekdayName(6), 'Thứ Bảy');
      expect(weekdayName(7), 'Chủ Nhật');
    });

    test('ngoài miền → chuỗi rỗng', () {
      expect(weekdayName(0), '');
      expect(weekdayName(8), '');
      expect(weekdayName(-1), '');
    });
  });

  group('AppNotification — trần, cờ đọc, giá trị', () {
    test('kMaxNotifications == 200 (hằng, không cấu hình)', () {
      expect(kMaxNotifications, 200);
    });

    test('isRead ⟺ readAt != null', () {
      final base = AppNotification(
        kind: NotificationKind.dailyReminder,
        title: 'Nhắc ghi chép',
        createdAt: now,
      );
      expect(base.isRead, isFalse);
      expect(base.copyWith(readAt: now).isRead, isTrue);
    });

    test('copyWith(readAt) đổi đúng 1 trường', () {
      final base = AppNotification(
        id: 7,
        kind: NotificationKind.budgetAlert,
        title: 'Sắp vượt ngân sách',
        body: 'Đã dùng 82%',
        createdAt: DateTime(2026, 8, 24, 10, 0),
        relatedId: 3,
      );
      final read = base.copyWith(readAt: now);
      expect(read.id, 7);
      expect(read.kind, NotificationKind.budgetAlert);
      expect(read.title, 'Sắp vượt ngân sách');
      expect(read.body, 'Đã dùng 82%');
      expect(read.createdAt, DateTime(2026, 8, 24, 10, 0));
      expect(read.readAt, now);
      expect(read.relatedId, 3);
      expect(base.readAt, isNull, reason: 'bản gốc không đổi');
    });

    test('==/hashCode theo giá trị', () {
      final a = AppNotification(
        id: 1,
        kind: NotificationKind.periodSummary,
        title: 'Tổng kết tuần',
        createdAt: now,
      );
      final b = AppNotification(
        id: 1,
        kind: NotificationKind.periodSummary,
        title: 'Tổng kết tuần',
        createdAt: now,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(
          AppNotification(
            id: 1,
            kind: NotificationKind.periodSummary,
            title: 'Tổng kết tháng',
            createdAt: now,
          ),
        ),
      );
      expect(a, isNot(a.copyWith(readAt: now)));
    });
  });
}
