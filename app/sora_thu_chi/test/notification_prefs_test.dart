import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/date_label.dart';
import 'package:sora_thu_chi/core/notification/notification_prefs.dart';

/// Luật data-model §2 (PBI 28) ở **tầng thuần** — 17 luật, không widget/binding.
Map<String, String> _row(String value) => {kKeyNotificationPrefs: value};

void main() {
  group('Luật 1 — mặc định (FR-008)', () {
    test('constructor mặc định = defaults, đủ 16 trường', () {
      const p = NotificationPrefs();
      expect(p, NotificationPrefs.defaults);
      expect(p.dailyEnabled, isTrue);
      expect(p.dailyHour, 20);
      expect(p.dailyMinute, 30);
      expect(p.dailyOnlyIfNoTxnToday, isTrue);
      expect(p.budgetEnabled, isTrue);
      expect(p.budgetEarlyPercent, 80);
      expect(p.budgetOverPercent, 100);
      expect(p.recurringEnabled, isTrue);
      expect(p.recurringDaysBefore, 3);
      expect(p.goalEnabled, isFalse, reason: 'công tắc duy nhất vẽ ở trạng thái tắt');
      expect(p.weeklyEnabled, isTrue);
      expect(p.weeklyHour, 20);
      expect(p.weeklyMinute, 0);
      expect(p.monthlyEnabled, isTrue);
      expect(p.monthlyHour, 20);
      expect(p.monthlyMinute, 0);
      expect(p.toJson().length, 16);
    });

    test('row vắng → cả bộ mặc định', () {
      expect(NotificationPrefs.fromSettings(const {}), NotificationPrefs.defaults);
    });
  });

  group('Luật 2 — value không parse được → cả bộ mặc định, không ném', () {
    for (final raw in ['', 'không phải json', 'null', '[1,2,3]', '"chuỗi"', '42']) {
      test('raw = ${raw.isEmpty ? '(rỗng)' : raw} → mặc định', () {
        expect(
          NotificationPrefs.fromSettings(_row(raw)),
          NotificationPrefs.defaults,
        );
      });
    }
  });

  group('Luật 3–5 — từng trường sai kiểu/ngoài miền → mặc định của riêng nó', () {
    test('JSON thiếu khoá → trường thiếu nhận mặc định, trường có mặt giữ nguyên', () {
      final p = NotificationPrefs.fromSettings(
        _row('{"dailyHour":8,"goalEnabled":true}'),
      );
      expect(p.dailyHour, 8);
      expect(p.goalEnabled, isTrue);
      expect(p.dailyMinute, 30, reason: 'thiếu khoá → mặc định của trường đó');
      expect(p.budgetEarlyPercent, 80);
      expect(p.weeklyMinute, 0);
    });

    test('bool ≠ bool và số ≠ số → mặc định của riêng trường đó', () {
      final p = NotificationPrefs.fromSettings(
        _row(
          '{"dailyEnabled":"true","dailyHour":"8",'
          '"budgetEnabled":1,"recurringDaysBefore":true,"weeklyEnabled":false}',
        ),
      );
      expect(p.dailyEnabled, isTrue, reason: 'chuỗi "true" không phải bool → mặc định');
      expect(p.dailyHour, 20, reason: 'chuỗi số không phải số');
      expect(p.budgetEnabled, isTrue, reason: '1 không phải bool');
      expect(p.recurringDaysBefore, 3, reason: 'true không phải số');
      expect(p.weeklyEnabled, isFalse, reason: 'bool hợp lệ phải giữ nguyên');
    });

    test('số thực không nhận vào trường int', () {
      final p = NotificationPrefs.fromSettings(_row('{"dailyHour":8.5}'));
      expect(p.dailyHour, 20);
    });

    test('ngoài miền → mặc định (giờ 24, phút 60, % 150, ngày âm/31)', () {
      final p = NotificationPrefs.fromSettings(
        _row(
          '{"dailyHour":24,"dailyMinute":60,"budgetEarlyPercent":150,'
          '"budgetOverPercent":-1,"recurringDaysBefore":-2,'
          '"weeklyHour":-1,"monthlyMinute":60,"monthlyHour":23}',
        ),
      );
      expect(p.dailyHour, 20);
      expect(p.dailyMinute, 30);
      expect(p.budgetEarlyPercent, 80);
      expect(p.budgetOverPercent, 100);
      expect(p.recurringDaysBefore, 3);
      expect(p.weeklyHour, 20);
      expect(p.monthlyMinute, 0);
      expect(p.monthlyHour, 23, reason: 'biên hợp lệ 23 phải giữ nguyên');
    });

    test('biên hợp lệ được giữ nguyên (0 và max)', () {
      final p = NotificationPrefs.fromSettings(
        _row(
          '{"dailyHour":0,"dailyMinute":0,"budgetEarlyPercent":0,'
          '"budgetOverPercent":100,"recurringDaysBefore":30,"monthlyHour":0}',
        ),
      );
      expect(p.dailyHour, 0);
      expect(p.dailyMinute, 0);
      expect(p.budgetEarlyPercent, 0);
      expect(p.budgetOverPercent, 100);
      expect(p.recurringDaysBefore, 30);
      expect(p.monthlyHour, 0);
    });

    test('luật 6 — parse không bao giờ ném với mọi đầu vào chuỗi', () {
      for (final raw in ['{', '{}', '{"dailyHour":}', '   ', '{"goalEnabled":null}']) {
        expect(() => NotificationPrefs.fromSettings(_row(raw)), returnsNormally);
      }
    });
  });

  group('Luật 7–8 — round-trip JSON', () {
    test('fromSettings(toSettings(p)) == p với prefs đã đổi', () {
      const p = NotificationPrefs(
        dailyEnabled: false,
        dailyHour: 7,
        dailyMinute: 5,
        dailyOnlyIfNoTxnToday: false,
        budgetEnabled: false,
        budgetEarlyPercent: 50,
        budgetOverPercent: 90,
        recurringEnabled: false,
        recurringDaysBefore: 7,
        goalEnabled: true,
        weeklyEnabled: false,
        weeklyHour: 9,
        weeklyMinute: 15,
        monthlyEnabled: false,
        monthlyHour: 18,
        monthlyMinute: 45,
      );
      expect(NotificationPrefs.fromSettings(p.toSettings()), p);
    });

    test('round-trip prefs mặc định', () {
      expect(
        NotificationPrefs.fromSettings(NotificationPrefs.defaults.toSettings()),
        NotificationPrefs.defaults,
      );
    });

    test('toSettings chỉ 1 row đúng khoá', () {
      final settings = NotificationPrefs.defaults.toSettings();
      expect(settings.keys, [kKeyNotificationPrefs]);
    });
  });

  group('Luật 11–13 — bất biến khi bật/tắt (FR-006/FR-010)', () {
    test('copyWith(xEnabled:) chỉ đổi trường của loại đó', () {
      const base = NotificationPrefs();
      final cases = <String, NotificationPrefs>{
        'daily': base.copyWith(dailyEnabled: false),
        'budget': base.copyWith(budgetEnabled: false),
        'recurring': base.copyWith(recurringEnabled: false),
        'goal': base.copyWith(goalEnabled: true),
        'weekly': base.copyWith(weeklyEnabled: false),
        'monthly': base.copyWith(monthlyEnabled: false),
      };
      for (final entry in cases.entries) {
        final diff = <String>[];
        final a = base.toJson();
        final b = entry.value.toJson();
        for (final key in a.keys) {
          if (a[key] != b[key]) diff.add(key);
        }
        expect(diff, hasLength(1), reason: '${entry.key} chỉ được đổi 1 trường');
      }
    });

    test('tắt một loại không chạm tham số của loại đó; bật lại đọc ra tham số cũ', () {
      const start = NotificationPrefs();
      final off = start
          .copyWith(dailyEnabled: false)
          .copyWith(budgetEnabled: false)
          .copyWith(weeklyEnabled: false);
      expect(off.dailyHour, 20);
      expect(off.dailyMinute, 30);
      expect(off.dailyOnlyIfNoTxnToday, isTrue);
      expect(off.budgetEarlyPercent, 80);
      expect(off.budgetOverPercent, 100);
      expect(off.weeklyHour, 20);
      expect(off.weeklyMinute, 0);

      final back = off.copyWith(dailyEnabled: true).copyWith(weeklyEnabled: true);
      expect(back.dailyHour, 20);
      expect(back.dailyMinute, 30);
      expect(back.dailyOnlyIfNoTxnToday, isTrue);
      expect(back.weeklyHour, 20);
      expect(back.weeklyMinute, 0);
    });

    test('tắt cả 6 công tắc vẫn là prefs hợp lệ (không tự bật lại)', () {
      final allOff = NotificationPrefs.defaults
          .copyWith(dailyEnabled: false)
          .copyWith(budgetEnabled: false)
          .copyWith(recurringEnabled: false)
          .copyWith(goalEnabled: false)
          .copyWith(weeklyEnabled: false)
          .copyWith(monthlyEnabled: false);
      expect(allOff.dailyEnabled, isFalse);
      expect(allOff.budgetEnabled, isFalse);
      expect(allOff.recurringEnabled, isFalse);
      expect(allOff.goalEnabled, isFalse);
      expect(allOff.weeklyEnabled, isFalse);
      expect(allOff.monthlyEnabled, isFalse);
      // Ghi ra rồi đọc lại vẫn tắt hết — không có giá trị đặc biệt nào bật lại.
      expect(
        NotificationPrefs.fromSettings(allOff.toSettings()),
        allOff,
      );
    });
  });

  group('Luật 15 — formatClock', () {
    test('pad 2 chữ số, 24h', () {
      expect(formatClock(20, 5), '20:05');
      expect(formatClock(0, 0), '00:00');
      expect(formatClock(20, 30), '20:30');
      expect(formatClock(23, 59), '23:59');
    });

    test('formatTimeLabel giữ nguyên hành vi (gọi lại formatClock)', () {
      expect(formatTimeLabel(DateTime(2026, 3, 10, 12, 30)), '12:30');
      expect(formatTimeLabel(DateTime(2026, 3, 10, 7, 5)), '07:05');
    });
  });
}
