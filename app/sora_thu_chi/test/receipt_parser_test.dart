import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/category/category_source.dart';
import 'package:sora_thu_chi/core/scan/receipt_parser.dart';
import 'package:sora_thu_chi/core/scan/scan_result.dart';

/// Dựng dòng OCR từ trên xuống: mỗi dòng cao 0.05, cách nhau 0.06 (dòng đầu
/// cao hơn — dùng cho luật "cửa hàng = chữ lớn nhất 30% đầu").
List<ScanTextLine> lines(List<String> texts, {Set<int> bigLines = const {0}}) {
  return [
    for (var i = 0; i < texts.length; i++)
      ScanTextLine(
        text: texts[i],
        rect: ScanRect(
          left: 0.1,
          top: 0.05 + i * 0.06,
          right: 0.9,
          bottom: 0.05 + i * 0.06 + (bigLines.contains(i) ? 0.05 : 0.03),
        ),
      ),
  ];
}

/// Hóa đơn Circle K theo mockup `scan-02`: có dòng mặt hàng 25.000/20.000/10.000
/// và dòng TỔNG CỘNG 55.000.
final circleK = lines([
  'CIRCLE K VIỆT NAM',
  'CN Trần Duy Hưng',
  'Cà phê sữa đá            25.000',
  'Bánh mì trứng            20.000',
  'Nước suối                10.000',
  'TỔNG CỘNG                55.000',
  '12/09/2026  08:24',
  'ĐT: 0909123456',
  'MST: 0123456789',
]);

final expenseCategories = CategorySource.all
    .where((c) => c.type == CategoryType.expense && !c.isHidden)
    .toList();

void main() {
  group('parseVietnameseAmount', () {
    test('6 định dạng số tiền hợp lệ', () {
      expect(parseVietnameseAmount('55.000'), 55000);
      expect(parseVietnameseAmount('55,000'), 55000);
      expect(parseVietnameseAmount('55 000'), 55000);
      expect(parseVietnameseAmount('55000'), 55000);
      expect(parseVietnameseAmount('55.000đ'), 55000);
      expect(parseVietnameseAmount('1.234.567'), 1234567);
    });

    test('loại số thập phân 12.5', () {
      expect(parseVietnameseAmount('12.5'), isNull);
      expect(parseVietnameseAmount('1.234.56'), isNull);
    });

    test('loại số < 1000 khi không nhóm nghìn (không phải tiền)', () {
      expect(parseVietnameseAmount('550'), isNull);
      expect(parseVietnameseAmount('0'), isNull);
    });

    test('chuỗi không có chữ số → null', () {
      expect(parseVietnameseAmount(''), isNull);
      expect(parseVietnameseAmount('TỔNG CỘNG'), isNull);
    });
  });

  group('parseReceipt — số tiền (FR-021)', () {
    test('hóa đơn Circle K: lấy dòng TỔNG CỘNG, không lấy dòng mặt hàng', () {
      final r = parseReceipt(
        lines: circleK,
        now: DateTime(2026, 9, 12, 20),
        expenseCategories: expenseCategories,
      );
      expect(r.amount.value, 55000);
      expect(r.amount.confidence, FieldConfidence.high);
      // Vùng khoanh đúng dòng TỔNG CỘNG (dòng thứ 6).
      expect(r.amount.rect, circleK[5].rect);
    });

    test('không có dòng tổng → số lớn nhất còn lại, tin cậy trung bình', () {
      final r = parseReceipt(
        lines: lines(['Cà phê sữa đá 25.000', 'Bánh mì trứng 20.000', 'Nước suối 10.000']),
        now: DateTime(2026, 9, 12),
        expenseCategories: expenseCategories,
      );
      expect(r.amount.value, 25000);
      expect(r.amount.confidence, FieldConfidence.medium);
    });

    test('không có số tiền nào → rỗng + tin cậy thấp', () {
      final r = parseReceipt(
        lines: lines(['CIRCLE K', 'Cảm ơn quý khách']),
        now: DateTime(2026, 9, 12),
        expenseCategories: expenseCategories,
      );
      expect(r.amount.isEmpty, isTrue);
      expect(r.amount.needsReview, isTrue);
    });

    test('dòng chỉ có số điện thoại/MST không bị lấy làm tiền', () {
      final r = parseReceipt(
        lines: lines(['CIRCLE K', 'ĐT: 0909123456', 'MST: 0123456789']),
        now: DateTime(2026, 9, 12),
        expenseCategories: expenseCategories,
      );
      expect(r.amount.isEmpty, isTrue);
    });

    test('số năm trong dòng ngày không bị lấy làm tiền', () {
      final r = parseReceipt(
        lines: lines(['CIRCLE K', 'Ngày 12/09/2026']),
        now: DateTime(2026, 9, 12),
        expenseCategories: expenseCategories,
      );
      expect(r.amount.isEmpty, isTrue);
    });
  });

  group('parseReceipt — ngày giờ (FR-022)', () {
    test('định dạng dd/mm/yyyy kèm giờ', () {
      final r = parseReceipt(
        lines: lines(['CIRCLE K', '12/09/2026  08:24']),
        now: DateTime(2026, 1, 1),
        expenseCategories: expenseCategories,
      );
      expect(r.date.value, DateTime(2026, 9, 12, 8, 24));
      expect(r.date.confidence, FieldConfidence.high);
    });

    test('định dạng dd-mm-yyyy không giờ', () {
      final r = parseReceipt(
        lines: lines(['CIRCLE K', '05-03-2026']),
        now: DateTime(2026, 1, 1),
        expenseCategories: expenseCategories,
      );
      expect(r.date.value, DateTime(2026, 3, 5));
    });

    test('định dạng yyyy-mm-dd', () {
      final r = parseReceipt(
        lines: lines(['CIRCLE K', '2026-03-05 19:30']),
        now: DateTime(2026, 1, 1),
        expenseCategories: expenseCategories,
      );
      expect(r.date.value, DateTime(2026, 3, 5, 19, 30));
    });

    test('không có ngày → now + tin cậy thấp, không khoanh vùng', () {
      final now = DateTime(2026, 9, 12, 21);
      final r = parseReceipt(
        lines: lines(['CIRCLE K']),
        now: now,
        expenseCategories: expenseCategories,
      );
      expect(r.date.value, now);
      expect(r.date.confidence, FieldConfidence.low);
      expect(r.date.rect, isNull);
    });

    test('ngày sai (31/02) → bỏ qua, rơi về now + low', () {
      final now = DateTime(2026, 9, 12);
      final r = parseReceipt(
        lines: lines(['CIRCLE K', '31/02/2026']),
        now: now,
        expenseCategories: expenseCategories,
      );
      expect(r.date.value, now);
      expect(r.date.confidence, FieldConfidence.low);
    });
  });

  group('parseReceipt — cửa hàng & danh mục (FR-024)', () {
    test('theo từ khoá "Cửa hàng" → tin cậy trung bình', () {
      final r = parseReceipt(
        lines: lines(['Hóa đơn bán hàng', 'Cửa hàng: Highlands Coffee']),
        now: DateTime(2026, 9, 12),
        expenseCategories: expenseCategories,
      );
      expect(r.merchant.value, 'Cửa hàng: Highlands Coffee');
      expect(r.merchant.confidence, FieldConfidence.medium);
    });

    test('theo cỡ chữ 30% đầu → tin cậy thấp (cần kiểm tra lại)', () {
      final r = parseReceipt(
        lines: circleK,
        now: DateTime(2026, 9, 12),
        expenseCategories: expenseCategories,
      );
      expect(r.merchant.value, 'CIRCLE K VIỆT NAM');
      expect(r.merchant.confidence, FieldConfidence.low);
      expect(r.merchant.needsReview, isTrue);
    });

    test('Circle K → gợi ý danh mục "Ăn uống" trong danh mục đang hoạt động', () {
      final r = parseReceipt(
        lines: circleK,
        now: DateTime(2026, 9, 12),
        expenseCategories: expenseCategories,
      );
      expect(r.category.value?.name, 'Ăn uống');
      expect(r.category.value?.type, CategoryType.expense);
    });

    test('không khớp từ điển → danh mục rỗng (không tự tạo)', () {
      final r = parseReceipt(
        lines: lines(['Tiệm vàng Kim Long', 'TỔNG: 5.000.000']),
        now: DateTime(2026, 9, 12),
        expenseCategories: expenseCategories,
      );
      expect(r.category.isEmpty, isTrue);
    });

    test('danh mục gợi ý bị ẩn khỏi danh sách hoạt động → rỗng', () {
      final r = parseReceipt(
        lines: lines(['CIRCLE K', 'TỔNG: 55.000']),
        now: DateTime(2026, 9, 12),
        expenseCategories: const [],
      );
      expect(r.category.isEmpty, isTrue);
    });
  });

  test('mặc định là khoản chi + engine bộ luật (FR-025)', () {
    final r = parseReceipt(
      lines: circleK,
      now: DateTime(2026, 9, 12),
      expenseCategories: expenseCategories,
    );
    expect(r.type.name, 'expense');
    expect(r.engine, ScanEngine.ruleBased);
  });
}
