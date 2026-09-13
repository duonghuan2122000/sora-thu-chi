import 'dart:convert';

import '../category/category.dart';
import 'merchant_dictionary.dart';
import 'receipt_extractor.dart';
import 'scan_result.dart';

/// Seam gọi model AI **trên máy** (Tier A: Gemini Nano qua kênh native; Tier B:
/// Gemma 3n qua `flutter_gemma`). Impl thật **ném** khi model chưa sẵn sàng hoặc
/// người dùng chưa tải — [LlmExtractor] bắt và rơi về bộ luật (FR-011).
abstract class ScanLlm {
  /// Engine tương ứng — ghi vào phiên quét khi chính nhánh này chạy thành công.
  ScanEngine get engine;

  /// Gọi model **một lần** cho mỗi lần quét (FR-010), trả văn bản thô.
  Future<String> generate(String prompt);
}

/// Trích xuất bằng model trên máy, fallback về bộ luật trong **cùng seam**
/// (R7/FR-011): timeout 10 giây hoặc bất kỳ lỗi nào (model treo, chưa tải, trả
/// JSON hỏng) ⇒ kết quả của [fallback] + `engine = ruleBased` (SC-009). Nhờ vậy
/// người dùng **luôn** ra được màn xác nhận, không bao giờ kẹt ở màn xử lý.
class LlmExtractor implements ReceiptExtractor {
  const LlmExtractor(
    this._llm, {
    this.fallback = const RuleBasedExtractor(),
    this.timeout = const Duration(seconds: 10),
  });

  final ScanLlm _llm;
  final ReceiptExtractor fallback;
  final Duration timeout;

  @override
  Future<ScanExtraction> extract({
    required List<ScanTextLine> lines,
    required DateTime now,
    required List<Category> expenseCategories,
    required List<Category> incomeCategories,
    ScanEngine engine = ScanEngine.ruleBased,
  }) async {
    try {
      final raw = await _llm
          .generate(buildReceiptPrompt(lines, expenseCategories))
          .timeout(timeout);
      final parsed = parseLlmReceipt(
        raw,
        now: now,
        expenseCategories: expenseCategories,
      );
      // Model trả về nhưng không đọc ra JSON ⇒ coi như thất bại, không đoán.
      if (parsed == null) throw const FormatException('LLM trả về không đọc được');
      return parsed.copyWith(engine: _llm.engine);
    } catch (_) {
      return fallback.extract(
        lines: lines,
        now: now,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
        engine: ScanEngine.ruleBased,
      );
    }
  }
}

/// Prompt dùng chung cho cả 2 tier — chỉ hỏi đúng 4 trường và bắt trả JSON,
/// kèm danh sách tên danh mục hợp lệ để model chọn thay vì bịa tên mới.
String buildReceiptPrompt(
  List<ScanTextLine> lines,
  List<Category> expenseCategories,
) {
  final names = expenseCategories.map((c) => c.name).join(', ');
  final text = lines.map((l) => l.text).join('\n');
  return 'Bạn trích xuất dữ liệu từ hóa đơn tiếng Việt. '
      'Chỉ trả về DUY NHẤT một đối tượng JSON, không giải thích, không thêm chữ:\n'
      '{"amount": <tổng tiền phải trả, đơn vị đồng, chỉ chữ số>, '
      '"date": "<yyyy-mm-dd hoặc null>", '
      '"merchant": "<tên cửa hàng hoặc null>", '
      '"category": "<một trong: $names — hoặc null>"}\n'
      'Nội dung hóa đơn:\n$text';
}

/// Đọc JSON do model trả về → [ScanExtraction]; `null` khi không có đối tượng
/// JSON nào đọc được (⇒ caller rơi về bộ luật).
///
/// Model **không** trả vùng chữ ⇒ mọi `rect` để `null` (màn xác nhận không
/// khoanh vùng — nhánh hợp lệ của FR-029). Độ tin cậy: có giá trị ⇒ `medium`,
/// thiếu ⇒ rỗng/`low`; ngày thiếu ⇒ `now` + `low` (nhất quán FR-022).
ScanExtraction? parseLlmReceipt(
  String raw, {
  required DateTime now,
  required List<Category> expenseCategories,
}) {
  final json = _extractJsonObject(raw);
  if (json == null) return null;

  final amount = _asAmount(json['amount']);
  final date = _asDate(json['date']);
  final merchant = _asText(json['merchant']);
  final category = resolveCategory(_asText(json['category']), expenseCategories);

  return ScanExtraction(
    amount: amount == null
        ? const ScanField<int>()
        : ScanField<int>(value: amount, confidence: FieldConfidence.medium),
    date: date == null
        ? ScanField<DateTime>(value: now)
        : ScanField<DateTime>(
            value: date,
            confidence: FieldConfidence.medium,
          ),
    merchant: merchant == null
        ? const ScanField<String>()
        : ScanField<String>(
            value: merchant,
            confidence: FieldConfidence.medium,
          ),
    category: category == null
        ? const ScanField<Category>()
        : ScanField<Category>(
            value: category,
            confidence: FieldConfidence.medium,
          ),
  );
}

/// Lấy đối tượng JSON đầu tiên trong [raw] — chịu được rào ```json của model.
Map<String, dynamic>? _extractJsonObject(String raw) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  try {
    final decoded = jsonDecode(raw.substring(start, end + 1));
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

/// Số tiền: chấp nhận số hoặc chuỗi số; loại giá trị ≤ 0 và < 1000 (ngưỡng
/// giống bộ luật — dưới 1000 gần như chắc chắn là số khác trên hóa đơn).
int? _asAmount(Object? value) {
  final parsed = switch (value) {
    final num n => n.toInt(),
    final String s => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')),
    _ => null,
  };
  if (parsed == null || parsed < 1000) return null;
  return parsed;
}

DateTime? _asDate(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value.trim());
}

String? _asText(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return null;
  return trimmed;
}
