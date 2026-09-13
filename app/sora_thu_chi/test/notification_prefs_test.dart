import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/date_label.dart';
import 'package:sora_thu_chi/core/notification/notification_prefs.dart';

/// Luật data-model §2 (PBI 28) ở **tầng thuần** — 17 luật, không widget/binding.
Map<String, String> _row(String value) => {kKeyNotificationPrefs: value};

void main() {
  group('Luật 1 — mặc định (FR-008)', () {
    test('constructor mặc định = defaults, đủ 17 trường', () {
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
      expect(p.dailyWeekdays, const [1, 2, 3, 4, 5, 6, 7]);
      expect(p.toJson().length, 17);
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

  group('Luật 1–7 (PBI 29) — tập ngày: mặc định & parse chịu lỗi', () {
    test('mặc định cả 7 ngày, sắp tăng', () {
      expect(NotificationPrefs.defaults.dailyWeekdays, [1, 2, 3, 4, 5, 6, 7]);
      expect(NotificationPrefs.defaults.isEveryDay, isTrue);
    });

    test('row PBI 28 thiếu khoá → cả 7 ngày, các trường khác giữ nguyên', () {
      final p = NotificationPrefs.fromSettings(
        _row('{"dailyHour":8,"dailyMinute":5,"dailyOnlyIfNoTxnToday":false}'),
      );
      expect(p.dailyWeekdays, [1, 2, 3, 4, 5, 6, 7]);
      expect(p.dailyHour, 8);
      expect(p.dailyMinute, 5);
      expect(p.dailyOnlyIfNoTxnToday, isFalse);
    });

    test('sai kiểu (không phải List) → cả 7 ngày, không ném', () {
      for (final raw in ['null', '"T2"', '5', '{}', 'true']) {
        expect(
          NotificationPrefs.fromSettings(_row('{"dailyWeekdays":$raw}')).dailyWeekdays,
          [1, 2, 3, 4, 5, 6, 7],
          reason: 'raw = $raw',
        );
      }
    });

    test('list rỗng / toàn phần tử sai → cả 7 ngày (không có trạng thái 0 ngày)', () {
      for (final raw in ['[]', '[0,9]', '["T2","T3"]', '[null]', '[1.5,8.5]']) {
        expect(
          NotificationPrefs.fromSettings(_row('{"dailyWeekdays":$raw}')).dailyWeekdays,
          [1, 2, 3, 4, 5, 6, 7],
          reason: 'raw = $raw',
        );
      }
    });

    test('phần tử lạ bị lọc bỏ, phần còn lại giữ nguyên (không rơi về mặc định)', () {
      final p = NotificationPrefs.fromSettings(
        _row('{"dailyWeekdays":[3,null,0,"T2",8,1.5,5]}'),
      );
      expect(p.dailyWeekdays, [3, 5]);
    });

    test('trùng lặp bị bỏ + ghi ra luôn sắp tăng', () {
      final p = NotificationPrefs.fromSettings(
        _row('{"dailyWeekdays":[5,1,1,5]}'),
      );
      expect(p.dailyWeekdays, [1, 5]);
      expect(p.toJson()['dailyWeekdays'], [1, 5]);
    });

    test('tập 1 ngày đọc ra đúng 1 ngày (không bị coi là rỗng)', () {
      final p = NotificationPrefs.fromSettings(_row('{"dailyWeekdays":[4]}'));
      expect(p.dailyWeekdays, [4]);
      expect(p.isEveryDay, isFalse);
    });
  });

  group('Luật 8–9 (PBI 29) — round-trip tập ngày', () {
    test('fromSettings(toSettings(p)) == p với tập ngày đã đổi', () {
      const p = NotificationPrefs(
        dailyHour: 7,
        dailyMinute: 5,
        dailyOnlyIfNoTxnToday: false,
        dailyWeekdays: [2, 4, 6],
      );
      final back = NotificationPrefs.fromSettings(p.toSettings());
      expect(back, p);
      expect(back.dailyWeekdays, [2, 4, 6]);
      expect(back.hashCode, p.hashCode, reason: 'hashCode phải tính cả tập ngày');
    });
  });

  group('Luật 10–14 (PBI 29) — toggleDay / isEveryDay / isDayEnabled', () {
    const base = NotificationPrefs();

    test('ngày đang tắt → thêm vào, giữ thứ tự sắp tăng', () {
      final p = base.copyWith(dailyWeekdays: [1, 3]).toggleDay(2);
      expect(p.dailyWeekdays, [1, 2, 3]);
    });

    test('ngày đang bật, còn ≥2 ngày → bỏ ngày đó', () {
      final p = base.copyWith(dailyWeekdays: [1, 2, 3]).toggleDay(2);
      expect(p.dailyWeekdays, [1, 3]);
      expect(p.isDayEnabled(2), isFalse);
      expect(p.isDayEnabled(1), isTrue);
    });

    test('tắt ngày bật cuối cùng → trả CHÍNH object cũ (identical), không có 0 ngày', () {
      final p = base.copyWith(dailyWeekdays: [6]);
      expect(identical(p, p.toggleDay(6)), isTrue);
      expect(p.toggleDay(6).dailyWeekdays, [6]);
    });

    test('toggleDay chỉ chạm dailyWeekdays — 16 trường còn lại nguyên', () {
      final p = base.copyWith(dailyWeekdays: [1, 2, 3]).toggleDay(2);
      final diff = <String>[];
      final a = base.copyWith(dailyWeekdays: [1, 2, 3]).toJson();
      final b = p.toJson();
      for (final key in a.keys) {
        if (a[key].toString() != b[key].toString()) diff.add(key);
      }
      expect(diff, ['dailyWeekdays']);
    });

    test('ngoài miền 1…7 → không đổi gì', () {
      final p = base.copyWith(dailyWeekdays: [1, 2]);
      expect(identical(p, p.toggleDay(0)), isTrue);
      expect(identical(p, p.toggleDay(8)), isTrue);
    });

    test('isEveryDay chỉ đúng với tập đủ 7 ngày', () {
      expect(base.copyWith(dailyWeekdays: [1, 2, 3, 4, 5, 6, 7]).isEveryDay, isTrue);
      expect(base.copyWith(dailyWeekdays: [1, 2, 3, 4, 5, 6]).isEveryDay, isFalse);
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
