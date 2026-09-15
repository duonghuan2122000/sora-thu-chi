import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/scan/receipt_extractor.dart';
import 'package:sora_thu_chi/core/scan/scan_result.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';

List<ScanTextLine> lines(List<String> texts) => [
  for (var i = 0; i < texts.length; i++)
    ScanTextLine(
      text: texts[i],
      rect: ScanRect(left: 0.1, top: 0.05 + i * 0.06, right: 0.9, bottom: 0.1 + i * 0.06),
    ),
];

void main() {
  group('RuleBasedExtractor — dispatcher theo loại ảnh (R1, PBI 36)', () {
    const extractor = RuleBasedExtractor();

    test('text ngân hàng ⇒ gọi nhánh parseBankNotification', () async {
      final input = lines([
        'Ghi no: -40.000',
        'Tai khoan: 1900',
        'Ma giao dich: GD123',
      ]);
      final result = await extractor.extract(
        lines: input,
        now: DateTime(2026, 9, 13),
        expenseCategories: const [],
        incomeCategories: const [],
      );

      expect(result.type, TxnType.expense);
      expect(result.amount.value, 40000);
    });

    test('text hóa đơn ⇒ gọi nhánh parseReceipt, typeNeedsReview = false (hành vi PBI 24)', () async {
      final input = lines([
        'CIRCLE K VIỆT NAM',
        'Cà phê sữa đá  25.000',
        'TỔNG CỘNG      55.000',
      ]);
      final result = await extractor.extract(
        lines: input,
        now: DateTime(2026, 9, 13),
        expenseCategories: const [],
        incomeCategories: const [],
      );

      expect(result.type, TxnType.expense);
      expect(result.amount.value, 55000);
      expect(result.typeNeedsReview, isFalse);
    });
  });
}
