import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/money_format.dart';

void main() {
  group('formatAmount — phân tách nghìn bằng dấu chấm, không kèm đơn vị', () {
    test('0 và giá trị nhỏ không thêm dấu phân tách', () {
      expect(formatAmount(0), '0');
      expect(formatAmount(5), '5');
      expect(formatAmount(999), '999');
    });

    test('phân tách nghìn đúng cho giá trị trung bình', () {
      expect(formatAmount(1000), '1.000');
      expect(formatAmount(1234567), '1.234.567');
      expect(formatAmount(19450000), '19.450.000');
    });

    test('số âm có dấu trừ đứng trước', () {
      expect(formatAmount(-500000), '-500.000');
      expect(formatAmount(-1000), '-1.000');
    });

    test('giá trị lớn không vỡ định dạng', () {
      expect(formatAmount(1000000000000), '1.000.000.000.000');
    });
  });

  group('formatMoney — formatAmount + đơn vị đ', () {
    test('0 → "0 đ"', () {
      expect(formatMoney(0), '0 đ');
    });

    test('dương → phân tách nghìn + " đ"', () {
      expect(formatMoney(1234567), '1.234.567 đ');
    });

    test('âm → giữ dấu trừ trước số', () {
      expect(formatMoney(-500000), '-500.000 đ');
    });
  });

  group('formatSignedMoney — formatMoney + dấu +/-, cho dòng giao dịch', () {
    test('0 → "0 đ" (không dấu)', () {
      expect(formatSignedMoney(0), '0 đ');
    });

    test('dương → dấu "+" + phân tách nghìn + " đ"', () {
      expect(formatSignedMoney(1234567), '+1.234.567 đ');
    });

    test('âm → dấu trừ ASCII + phân tách nghìn + " đ"', () {
      expect(formatSignedMoney(-500000), '-500.000 đ');
    });

    test('giá trị lớn không thừa số lẻ', () {
      expect(formatSignedMoney(18000000), '+18.000.000 đ');
      expect(formatSignedMoney(-450000), '-450.000 đ');
    });
  });
}
