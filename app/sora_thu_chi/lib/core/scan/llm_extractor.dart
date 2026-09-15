import 'dart:convert';
import 'dart:typed_data';

import '../category/category.dart';
import '../transaction/transaction.dart';
import 'bank_notif_parser.dart';
import 'merchant_dictionary.dart';
import 'receipt_extractor.dart';
import 'scan_result.dart';

/// Seam gọi model AI **trên máy** (Tier A: Gemini Nano qua kênh native; Tier B:
/// Gemma 3n qua `flutter_gemma`). Impl thật **ném** khi model chưa sẵn sàng hoặc
/// người dùng chưa tải — [LlmExtractor] bắt và rơi về bộ luật (FR-011).
abstract class ScanLlm {
  /// Engine tương ứng — ghi vào phiên quét khi chính nhánh này chạy thành công.
  ScanEngine get engine;

  /// `true` nếu model đọc trực tiếp ảnh (đa phương thức, Tier A, PBI 37) —
  /// khi đó [LlmExtractor] gửi ảnh kèm prompt thay vì nhét văn bản OCR vào
  /// prompt. Mặc định `false` (Tier B chỉ nhận văn bản, không đổi hành vi).
  bool get supportsImage => false;

  /// Gọi model **một lần** cho mỗi lần quét (FR-010), trả văn bản thô. [image]
  /// chỉ có tác dụng khi [supportsImage] là `true`.
  Future<String> generate(String prompt, {Uint8List? image});
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
    Uint8List? image,
  }) async {
    try {
      // Model đọc ảnh trực tiếp (Tier A, PBI 37) ⇒ bỏ văn bản OCR khỏi prompt,
      // để model tự đọc nội dung từ ảnh đính kèm thay vì từ [lines].
      final useImage = _llm.supportsImage && image != null;
      final prompt = buildScanPrompt(
        lines,
        expenseCategories,
        incomeCategories,
        includeText: !useImage,
      );
      final raw = await _llm
          .generate(prompt, image: useImage ? image : null)
          .timeout(timeout);
      final parsed = parseLlmReceipt(
        raw,
        now: now,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
      );
      // Model trả về nhưng không đọc ra JSON ⇒ coi như thất bại, không đoán.
      if (parsed == null) throw const FormatException('LLM trả về không đọc được');
      return parsed.copyWith(
        engine: _llm.engine,
        amount: _reconcileAmount(parsed.amount, lines, now),
      );
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

/// Đối chiếu số tiền AI đọc với tín hiệu `high` của bộ luật ảnh ngân hàng
/// (cỡ chữ nổi bật / đơn vị đi kèm số — [parseBankNotification]). AI chỉ thấy
/// văn bản thuần, không thấy cỡ chữ nên dễ nhầm số tiền với số tài khoản/mã
/// giao dịch đứng gần đó; bộ luật thấy cỡ chữ nên đáng tin hơn khi có tín
/// hiệu mạnh và hai bên lệch nhau.
ScanField<int> _reconcileAmount(ScanField<int> llmAmount, List<ScanTextLine> lines, DateTime now) {
  if (!looksLikeBankNotification(lines)) return llmAmount;
  final ruleAmount = parseBankNotification(lines: lines, now: now).amount;
  if (ruleAmount.confidence == FieldConfidence.high && ruleAmount.value != llmAmount.value) {
    return ruleAmount;
  }
  return llmAmount;
}

/// Prompt dùng chung cho cả 2 tier, cả hóa đơn lẫn ảnh thông báo ngân hàng
/// (R7, PBI 36) — model tự đọc ngữ cảnh để suy `type`, không cần bước phát
/// hiện loại ảnh riêng cho nhánh AI. Đưa **cả 2** danh sách danh mục, gắn
/// nhãn rõ chi/thu, để model chọn đúng danh sách theo `type` nó suy ra.
String buildScanPrompt(
  List<ScanTextLine> lines,
  List<Category> expenseCategories,
  List<Category> incomeCategories, {
  bool includeText = true,
}) {
  final expenseNames = expenseCategories.map((c) => c.name).join(', ');
  final incomeNames = incomeCategories.map((c) => c.name).join(', ');
  // Tier A đọc ảnh trực tiếp (PBI 37) ⇒ không nhét văn bản OCR vào prompt,
  // chỉ dẫn model tự đọc nội dung từ ảnh đính kèm trong cùng yêu cầu.
  final contentSection = includeText
      ? 'Nội dung:\n${lines.map((l) => l.text).join('\n')}'
      : 'Nội dung cần đọc nằm trong ảnh đính kèm theo yêu cầu này.';
  return '''
Bạn trích xuất dữ liệu giao dịch tài chính bằng tiếng Việt. Nội dung có thể là:
(a) hóa đơn cửa hàng, hoặc
(b) thông báo giao dịch ngân hàng (SMS biến động số dư, thông báo app, hoặc email) — loại này thường chứa NHIỀU số dễ gây nhầm lẫn: số tiền giao dịch, số dư trước/sau giao dịch, số tài khoản, mã giao dịch/mã tham chiếu, hạn mức, phí.

Chỉ trả về DUY NHẤT một đối tượng JSON, không giải thích, không thêm chữ, đúng 5 khoá sau:
{
"type": "chi" nếu tiền RA khỏi tài khoản (ghi nợ/debit/mua hàng/dấu trừ "-"), hoặc "thu" nếu tiền VÀO tài khoản (ghi có/credit/dấu cộng "+"). Không chắc chắn ⇒ mặc định "chi".
"amount": số tiền GIAO DỊCH THỰC TẾ phát sinh (đơn vị đồng, chỉ chữ số, không dấu chấm/phẩy/đơn vị tiền). Đọc kỹ để không nhầm với:
  - số dư / số dư mới / số dư khả dụng (dù đứng gần số tiền giao dịch hoặc lớn hơn nó — số dư KHÔNG BAO GIỜ là số tiền giao dịch);
  - số tài khoản (VD "TK 750561");
  - mã giao dịch / mã tham chiếu / mã lệnh (VD "GD123456", "6258ASCB02UK171D", hoặc số ngày-giờ dính liền trong mã như "-150926-08:34:59" — đây là mã, KHÔNG phải số tiền âm 150926);
  - hạn mức, phí giao dịch.
  Ưu tiên số có đơn vị "VND"/"đ" đi kèm ngay sau nó. Số có thể viết với dấu chấm HOẶC dấu phẩy làm phân cách nghìn (VD "29.896.000" và "29,896,000" đều là 29 triệu 896 nghìn); nếu số có phần thập phân ".00"/",00" ở cuối thì bỏ phần đó (tiền VND không có số lẻ).
"date": ngày giờ giao dịch thực tế, định dạng "yyyy-mm-dd", hoặc null nếu không đọc được rõ. Ưu tiên ngày/giờ đứng cạnh số tiền giao dịch hoặc ở đầu thông báo; KHÔNG dùng ngày "tính đến" của số dư nếu có ngày giao dịch khác rõ ràng hơn.
"merchant": với hóa đơn — tên cửa hàng; với thông báo ngân hàng — nội dung giao dịch hoặc tên người nhận/gửi (thường theo sau nhãn "GD:", "Nội dung", "Đến:"). null nếu không đọc được.
"category": nếu type="chi", chọn một trong danh sách chi: $expenseNames; nếu type="thu", chọn một trong danh sách thu: $incomeNames. null nếu không đủ căn cứ.
}

$contentSection
''';
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
  List<Category> incomeCategories = const [],
}) {
  final json = _extractJsonObject(raw);
  if (json == null) return null;

  final typeHit = _asType(json['type']);
  final amount = _asAmount(json['amount']);
  final date = _asDate(json['date']);
  final merchant = _asText(json['merchant']);
  final category = resolveCategory(
    _asText(json['category']),
    typeHit.type == TxnType.income ? incomeCategories : expenseCategories,
  );

  return ScanExtraction(
    type: typeHit.type,
    typeNeedsReview: typeHit.needsReview,
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

class _TypeHit {
  const _TypeHit(this.type, this.needsReview);

  final TxnType type;
  final bool needsReview;
}

/// Loại giao dịch model trả (R7, PBI 36): `"thu"` ⇒ income, `"chi"` ⇒
/// expense; thiếu/giá trị lạ ⇒ expense mặc định + `typeNeedsReview = true`
/// (không đoán bừa, giống bộ luật).
_TypeHit _asType(Object? value) {
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'thu') return const _TypeHit(TxnType.income, false);
    if (normalized == 'chi') return const _TypeHit(TxnType.expense, false);
  }
  return const _TypeHit(TxnType.expense, true);
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
