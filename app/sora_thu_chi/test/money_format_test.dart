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

  group('maskMoney — che số tiền cho Privacy mode (PBI 48)', () {
    test('0 → 1 dấu chấm + " đ"', () {
      expect(maskMoney(0), '• đ');
    });

    test('số dương → số dấu chấm bằng số chữ số', () {
      expect(maskMoney(5), '• đ');
      expect(maskMoney(19450000), '•••••••• đ');
      expect(maskMoney(2455000), '••••••• đ');
    });

    test('số âm → không lộ dấu trừ, số dấu chấm theo giá trị tuyệt đối', () {
      expect(maskMoney(-450000), '•••••• đ');
    });
  });

  group('parseAmount — đọc-xuôi-ngược formatAmount (spec FR-005, research R9)', () {
    test('bỏ dấu chấm phân tách nghìn', () {
      expect(parseAmount('2.000.000'), 2000000);
      expect(parseAmount('1.234.567'), 1234567);
    });

    test('rỗng / không chứa chữ số → 0', () {
      expect(parseAmount(''), 0);
      expect(parseAmount('   '), 0);
      expect(parseAmount('abc'), 0);
      expect(parseAmount('đ'), 0);
    });

    test('dấu trừ đứng trước → giá trị âm (Unicode − và ASCII -)', () {
      expect(parseAmount('−500.000'), -500000);
      expect(parseAmount('-500.000'), -500000);
    });

    test('đối nghịch đúng formatAmount — không mất số khi đi-về', () {
      expect(parseAmount(formatAmount(2000000)), 2000000);
      expect(parseAmount(formatAmount(-500000)), -500000);
    });

    test('số rất lớn không tràn / không lỗi', () {
      expect(parseAmount('1000000000000'), 1000000000000);
      expect(parseAmount(formatAmount(999999999999)), 999999999999);
    });
  });
}
