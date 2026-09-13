import '../category/category.dart';
import 'receipt_parser.dart';
import 'scan_result.dart';

/// Seam trích xuất: chặng 1 chỉ có [RuleBasedExtractor]; chặng 2 cắm thêm
/// `LlmExtractor` (Tier A/B) **cùng định dạng kết quả** ⇒ màn xác nhận dùng
/// chung, và fallback AI→bộ luật chỉ là `try/catch` trong cùng seam (R7/FR-011).
abstract class ReceiptExtractor {
  Future<ScanExtraction> extract({
    required List<ScanTextLine> lines,
    required DateTime now,
    required List<Category> expenseCategories,
    required List<Category> incomeCategories,
    ScanEngine engine,
  });
}

/// Bộ luật cơ bản (Chế độ cơ bản) — gọi thẳng [parseReceipt].
class RuleBasedExtractor implements ReceiptExtractor {
  const RuleBasedExtractor();

  @override
  Future<ScanExtraction> extract({
    required List<ScanTextLine> lines,
    required DateTime now,
    required List<Category> expenseCategories,
    required List<Category> incomeCategories,
    ScanEngine engine = ScanEngine.ruleBased,
  }) async => parseReceipt(
    lines: lines,
    now: now,
    expenseCategories: expenseCategories,
    incomeCategories: incomeCategories,
  ).copyWith(engine: engine);
}
