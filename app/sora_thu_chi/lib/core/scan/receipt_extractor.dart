import 'dart:typed_data';

import '../category/category.dart';
import 'bank_notif_parser.dart';
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
    /// Ảnh đã tiền xử lý (PBI 37) — chỉ [LlmExtractor] dùng khi model đang
    /// dùng đọc trực tiếp ảnh (Tier A); [RuleBasedExtractor] bỏ qua.
    Uint8List? image,
  });
}

/// Bộ luật cơ bản (Chế độ cơ bản) — phân nhánh theo loại ảnh (R1, PBI 36):
/// ảnh thông báo ngân hàng → [parseBankNotification]; còn lại → [parseReceipt]
/// (hành vi hóa đơn hiện có, không đổi).
class RuleBasedExtractor implements ReceiptExtractor {
  const RuleBasedExtractor();

  @override
  Future<ScanExtraction> extract({
    required List<ScanTextLine> lines,
    required DateTime now,
    required List<Category> expenseCategories,
    required List<Category> incomeCategories,
    ScanEngine engine = ScanEngine.ruleBased,
    Uint8List? image,
  }) async {
    final result = looksLikeBankNotification(lines)
        ? parseBankNotification(
            lines: lines,
            now: now,
            expenseCategories: expenseCategories,
            incomeCategories: incomeCategories,
          )
        : parseReceipt(
            lines: lines,
            now: now,
            expenseCategories: expenseCategories,
            incomeCategories: incomeCategories,
          );
    return result.copyWith(engine: engine);
  }
}
