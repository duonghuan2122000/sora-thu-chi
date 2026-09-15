import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/category/category_source.dart';
import 'package:sora_thu_chi/core/scan/llm_extractor.dart';
import 'package:sora_thu_chi/core/scan/scan_result.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';

/// Model giả: trả [response] (hoặc ném [error], hoặc treo nếu [hang]).
class FakeLlm implements ScanLlm {
  FakeLlm(this.response, {this.error, this.hang = false, ScanEngine? engine})
    : _engine = engine ?? ScanEngine.gemma3nE2b;

  final String response;
  final Object? error;
  final bool hang;
  final ScanEngine _engine;

  String? lastPrompt;

  @override
  ScanEngine get engine => _engine;

  @override
  Future<String> generate(String prompt) {
    lastPrompt = prompt;
    if (error != null) return Future.error(error!);
    if (hang) return Completer<String>().future;
    return Future.value(response);
  }
}

List<ScanTextLine> lines(List<String> texts) => [
  for (var i = 0; i < texts.length; i++)
    ScanTextLine(
      text: texts[i],
      rect: ScanRect(left: 0.1, top: 0.1 + i * 0.05, right: 0.9, bottom: 0.15 + i * 0.05),
    ),
];

final receipt = lines([
  'CIRCLE K VIỆT NAM',
  'Cà phê sữa đá  25.000',
  'TỔNG CỘNG      55.000',
]);

final expenseCategories = CategorySource.all
    .where((c) => c.type == CategoryType.expense && !c.isHidden)
    .toList();
final incomeCategories = CategorySource.all
    .where((c) => c.type == CategoryType.income && !c.isHidden)
    .toList();

/// Extractor có timeout ngắn để ca "treo" không làm test chậm 10 giây.
LlmExtractor extractorFor(ScanLlm llm) =>
    LlmExtractor(llm, timeout: const Duration(milliseconds: 20));

Future<ScanExtraction> extract(
  ScanLlm llm, {
  List<ScanTextLine>? input,
  DateTime? now,
}) => extractorFor(llm).extract(
  lines: input ?? receipt,
  now: now ?? DateTime(2026, 9, 13, 10),
  expenseCategories: expenseCategories,
  incomeCategories: const [],
);

void main() {
  group('LlmExtractor với model trả kết quả hợp lệ', () {
    test('đọc đủ 4 trường + ghi engine thật đã dùng', () async {
      final llm = FakeLlm(
        '{"amount": 55000, "date": "2026-09-12", "merchant": "Circle K", '
        '"category": "Cà phê"}',
      );
      final result = await extract(llm);

      expect(result.amount.value, 55000);
      expect(result.amount.confidence, FieldConfidence.medium);
      expect(result.date.value, DateTime(2026, 9, 12));
      expect(result.merchant.value, 'Circle K');
      expect(result.category.value?.name, 'Cà phê');
      expect(result.engine, ScanEngine.gemma3nE2b);
    });

    test('chịu được JSON bọc trong rào ```json của model', () async {
      final llm = FakeLlm(
        'Đây là kết quả:\n```json\n{"amount": "55.000", "merchant": null}\n```',
      );
      final result = await extract(llm);

      expect(result.amount.value, 55000);
      expect(result.merchant.isEmpty, isTrue);
      expect(result.engine, ScanEngine.gemma3nE2b);
    });

    test('model không trả vùng chữ ⇒ không khoanh vùng (FR-029)', () async {
      final llm = FakeLlm('{"amount": 55000}');
      final result = await extract(llm);

      expect(result.amount.rect, isNull);
      expect(result.merchant.rect, isNull);
    });

    test('thiếu ngày ⇒ now + low (nhất quán FR-022)', () async {
      final now = DateTime(2026, 9, 13, 10);
      final llm = FakeLlm('{"amount": 55000, "date": null}');
      final result = await extract(llm, now: now);

      expect(result.date.value, now);
      expect(result.date.confidence, FieldConfidence.low);
      expect(result.date.needsReview, isTrue);
    });

    test('danh mục model trả không có trong danh mục hoạt động ⇒ để trống', () async {
      final llm = FakeLlm('{"amount": 55000, "category": "Danh mục bịa"}');
      final result = await extract(llm);

      expect(result.category.isEmpty, isTrue);
    });

    test('số tiền < 1000 ⇒ coi như không đọc được, bắt nhập tay', () async {
      final llm = FakeLlm('{"amount": 550}');
      final result = await extract(llm);

      expect(result.amount.isEmpty, isTrue);
    });
  });

  group('LlmExtractor fallback về bộ luật (FR-011/SC-009)', () {
    test('model ném lỗi ⇒ kết quả bộ luật + engine ruleBased', () async {
      final llm = FakeLlm('', error: StateError('model chưa tải'));
      final result = await extract(llm);

      expect(result.engine, ScanEngine.ruleBased);
      // Bộ luật đọc được dòng TỔNG CỘNG 55.000 của fixture.
      expect(result.amount.value, 55000);
    });

    test('model treo quá timeout ⇒ như trên', () async {
      final llm = FakeLlm('', hang: true);
      final result = await extract(llm);

      expect(result.engine, ScanEngine.ruleBased);
      expect(result.amount.value, 55000);
    });

    test('model trả văn bản không có JSON ⇒ như trên', () async {
      final llm = FakeLlm('Xin lỗi, tôi không đọc được hóa đơn này.');
      final result = await extract(llm);

      expect(result.engine, ScanEngine.ruleBased);
      expect(result.amount.value, 55000);
    });

    test('danh mục rỗng ⇒ vẫn ra kết quả, không ném', () async {
      final llm = FakeLlm('', error: StateError('lỗi'));
      final result = await extract(llm, input: lines(const []));

      expect(result.engine, ScanEngine.ruleBased);
      expect(result.amount.isEmpty, isTrue);
    });
  });

  group('buildScanPrompt (PBI 36, R7)', () {
    test('chứa nội dung + cả 2 danh sách danh mục gắn nhãn + khoá "type"', () {
      final prompt = buildScanPrompt(receipt, expenseCategories, incomeCategories);

      expect(prompt, contains('CIRCLE K VIỆT NAM'));
      expect(prompt, contains('TỔNG CỘNG'));
      expect(prompt, contains('Cà phê'));
      expect(prompt, contains('Lương'));
      expect(prompt, contains('JSON'));
      expect(prompt, contains('"type"'));
    });
  });

  group('parseLlmReceipt — suy loại thu/chi (PBI 36, R7)', () {
    ScanExtraction? parse(String raw) => parseLlmReceipt(
      raw,
      now: DateTime(2026, 9, 13, 10),
      expenseCategories: expenseCategories,
      incomeCategories: incomeCategories,
    );

    test('"type":"thu" ⇒ TxnType.income + resolve theo incomeCategories', () {
      final result = parse(
        '{"amount": 10000000, "type": "thu", "category": "Lương"}',
      );

      expect(result!.type, TxnType.income);
      expect(result.typeNeedsReview, isFalse);
      expect(result.category.value?.name, 'Lương');
    });

    test('"type":"chi" ⇒ TxnType.expense + resolve theo expenseCategories', () {
      final result = parse(
        '{"amount": 55000, "type": "chi", "category": "Cà phê"}',
      );

      expect(result!.type, TxnType.expense);
      expect(result.typeNeedsReview, isFalse);
      expect(result.category.value?.name, 'Cà phê');
    });

    test('thiếu type ⇒ TxnType.expense + typeNeedsReview = true', () {
      final result = parse('{"amount": 55000}');

      expect(result!.type, TxnType.expense);
      expect(result.typeNeedsReview, isTrue);
    });

    test('type giá trị lạ ⇒ TxnType.expense + typeNeedsReview = true', () {
      final result = parse('{"amount": 55000, "type": "khong ro"}');

      expect(result!.type, TxnType.expense);
      expect(result.typeNeedsReview, isTrue);
    });
  });
}
