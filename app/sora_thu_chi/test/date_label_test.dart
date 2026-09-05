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
