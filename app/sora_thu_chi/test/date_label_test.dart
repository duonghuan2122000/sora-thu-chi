import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/date_label.dart';

void main() {
  final now = DateTime(2026, 9, 4, 15, 30);

  group('relativeDayLabel — nhãn ngày thân thiện', () {
    test('cùng ngày lịch với now → "Hôm nay"', () {
      expect(relativeDayLabel(DateTime(2026, 9, 4, 0, 0), now: now), 'Hôm nay');
      expect(
        relativeDayLabel(DateTime(2026, 9, 4, 23, 59), now: now),
        'Hôm nay',
      );
    });

    test('hôm qua → "Hôm qua"', () {
      expect(relativeDayLabel(DateTime(2026, 9, 3), now: now), 'Hôm qua');
    });

    test('cách 2 ngày → dd/MM đúng hai chữ số', () {
      expect(relativeDayLabel(DateTime(2026, 9, 2), now: now), '02/09');
    });

    test('khác tháng → dd/MM', () {
      expect(relativeDayLabel(DateTime(2026, 8, 20), now: now), '20/08');
    });

    test('ngày một chữ số → thêm số 0 đứng trước', () {
      expect(
        relativeDayLabel(DateTime(2026, 9, 4), now: DateTime(2026, 9, 1)),
        '04/09',
      );
    });

    test('đổi mốc now sang ngày khác vẫn phân loại đúng', () {
      // 04/09 so với mốc 06/09 → "Hôm qua"; 04/09 so với mốc 10/09 → dd/MM.
      expect(
        relativeDayLabel(DateTime(2026, 9, 5), now: DateTime(2026, 9, 6)),
        'Hôm qua',
      );
      expect(
        relativeDayLabel(DateTime(2026, 9, 4), now: DateTime(2026, 9, 10)),
        '04/09',
      );
    });
  });

  group('formatDateTimeLabel — dd/MM/yyyy HH:mm đủ 2 chữ số (FR-006)', () {
    test('ngày giờ có số 0 đứng trước', () {
      expect(formatDateTimeLabel(DateTime(2026, 9, 5, 9, 5)), '05/09/2026 09:05');
      expect(formatDateTimeLabel(DateTime(2026, 3, 2, 7, 1)), '02/03/2026 07:01');
    });

    test('ngày/giờ hai chữ số sẵn', () {
      expect(
        formatDateTimeLabel(DateTime(2026, 12, 31, 23, 59)),
        '31/12/2026 23:59',
      );
    });

    test('deterministic với DateTime cụ thể (không phụ thuộc giờ hệ thống)', () {
      expect(
        formatDateTimeLabel(DateTime(2026, 8, 20, 14, 30)),
        '20/08/2026 14:30',
      );
    });
  });

  group('formatDateTimeDetailLabel — dd/MM/yyyy · HH:mm (PBI 10, R8)', () {
    test('bổ sung số 0: "05/09/2026 · 09:05"', () {
      expect(
        formatDateTimeDetailLabel(DateTime(2026, 9, 5, 9, 5)),
        '05/09/2026 · 09:05',
      );
      expect(
        formatDateTimeDetailLabel(DateTime(2026, 3, 2, 7, 1)),
        '02/03/2026 · 07:01',
      );
    });

    test('ngày/giờ hai chữ số sẵn + dấu · phân cách', () {
      expect(
        formatDateTimeDetailLabel(DateTime(2026, 12, 31, 23, 59)),
        '31/12/2026 · 23:59',
      );
    });

    test('deterministic với DateTime cụ thể, không đổi formatDateTimeLabel', () {
      final d = DateTime(2026, 8, 20, 14, 30);
      expect(formatDateTimeDetailLabel(d), '20/08/2026 · 14:30');
      // Hàm PBI 8 giữ nguyên hành vi (khoảng trắng, không dấu ·).
      expect(formatDateTimeLabel(d), '20/08/2026 14:30');
    });
  });

  group('dayLabel — nhãn ngày ISO (1 = Thứ Hai)', () {
    test('1→T2 … 7→CN', () {
      const expected = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      for (var d = 1; d <= 7; d++) {
        expect(dayLabel(d), expected[d - 1]);
      }
    });

    test('ngoài miền 1…7 → chuỗi rỗng', () {
      expect(dayLabel(0), '');
      expect(dayLabel(8), '');
      expect(dayLabel(-1), '');
    });
  });

  group('daysLabel — nén dải liên tiếp ≥3 (FR-011)', () {
    test('đủ 7 ngày → "T2–T7, CN" (dải 6 ngày + ngày rời)', () {
      expect(daysLabel([1, 2, 3, 4, 5, 6, 7]), 'T2–T7, CN');
    });

    test('[1..6] → "T2–T7"', () {
      expect(daysLabel([1, 2, 3, 4, 5, 6]), 'T2–T7');
    });

    test('[1,2,3,5] → "T2–T4, T6" (dải 3 + ngày rời)', () {
      expect(daysLabel([1, 2, 3, 5]), 'T2–T4, T6');
    });

    test('2 ngày rời không nén: [1,7] → "T2, CN"', () {
      expect(daysLabel([1, 7]), 'T2, CN');
    });

    test('[3] → "T4"; rỗng → ""', () {
      expect(daysLabel([3]), 'T4');
      expect(daysLabel(const []), '');
    });

    test('Chủ Nhật luôn liệt kê riêng, không gộp vào dải', () {
      expect(daysLabel([5, 6, 7]), 'T6, T7, CN');
      expect(daysLabel([1, 2, 3, 4, 5, 6, 7]), 'T2–T7, CN');
    });

    test('đầu vào lộn xộn/trùng vẫn cho kết quả chuẩn', () {
      expect(daysLabel([5, 7, 6, 5]), 'T6, T7, CN');
      expect(daysLabel([7, 1, 2, 3]), 'T2–T4, CN');
    });
  });

  group('formatDayGroupHeader — tiêu đề nhóm ngày (FR-005)', () {
    test('cùng ngày lịch → "HÔM NAY - dd/MM/yyyy"', () {
      expect(
        formatDayGroupHeader(DateTime(2026, 9, 4, 8, 0), now: now),
        'HÔM NAY - 04/09/2026',
      );
    });

    test('hôm trước → "HÔM QUA - dd/MM/yyyy"', () {
      expect(
        formatDayGroupHeader(DateTime(2026, 9, 3, 23, 0), now: now),
        'HÔM QUA - 03/09/2026',
      );
    });

    test('ngày khác → "dd/MM/yyyy"', () {
      expect(
        formatDayGroupHeader(DateTime(2026, 8, 30), now: now),
        '30/08/2026',
      );
    });

    test('ngày tương lai (đặt lịch) → "dd/MM/yyyy", không nhãn tương đối', () {
      expect(
        formatDayGroupHeader(DateTime(2026, 9, 10), now: now),
        '10/09/2026',
      );
    });
  });
}
