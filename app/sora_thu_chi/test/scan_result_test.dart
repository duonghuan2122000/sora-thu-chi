import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/scan/scan_result.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';

void main() {
  group('ScanExtraction.typeNeedsReview (PBI 36, R8)', () {
    test('mặc định false', () {
      const extraction = ScanExtraction();
      expect(extraction.typeNeedsReview, isFalse);
    });

    test('copyWith giữ nguyên khi không truyền', () {
      const extraction = ScanExtraction(typeNeedsReview: true);
      final copy = extraction.copyWith(type: TxnType.income);
      expect(copy.typeNeedsReview, isTrue);
    });

    test('copyWith đổi đúng khi truyền', () {
      const extraction = ScanExtraction(typeNeedsReview: true);
      final copy = extraction.copyWith(typeNeedsReview: false);
      expect(copy.typeNeedsReview, isFalse);
    });

    test('toJson có khoá typeNeedsReview', () {
      const extraction = ScanExtraction(typeNeedsReview: true);
      expect(extraction.toJson()['typeNeedsReview'], isTrue);

      const other = ScanExtraction();
      expect(other.toJson()['typeNeedsReview'], isFalse);
    });
  });
}
