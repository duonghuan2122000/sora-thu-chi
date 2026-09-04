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
}
