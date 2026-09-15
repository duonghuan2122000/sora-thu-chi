import '../category/category.dart';
import '../transaction/transaction.dart';

/// Vùng chữ trên ảnh, **chuẩn hoá 0..1** theo kích thước ảnh (gốc trên-trái).
/// Chuẩn hoá ngay ở tầng OCR ⇒ mọi màn hiển thị (thu nhỏ hay ảnh gốc full) vẽ
/// khoanh vùng bằng cùng một phép nhân tỉ lệ (FR-018/FR-029).
class ScanRect {
  const ScanRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;
  double get centerY => (top + bottom) / 2;
}

/// Một dòng chữ OCR đọc được — đầu vào duy nhất của bộ luật trích xuất.
class ScanTextLine {
  const ScanTextLine({required this.text, required this.rect});

  final String text;
  final ScanRect rect;
}

/// Mức độ tin cậy của một trường trích xuất (FR-026) — quyết định nhãn hiển thị:
/// `high` teal, `medium` xám, `low` (hoặc rỗng) coral + "Kiểm tra lại".
enum FieldConfidence { high, medium, low }

/// Một trường trích xuất: giá trị (null = không đọc được) + độ tin cậy + vùng
/// chữ tương ứng để khoanh trên ảnh gốc (null = không xác định vùng).
class ScanField<T> {
  const ScanField({this.value, this.confidence = FieldConfidence.low, this.rect});

  final T? value;
  final FieldConfidence confidence;
  final ScanRect? rect;

  bool get isEmpty => value == null;

  /// Cần người dùng kiểm tra lại: rỗng hoặc độ tin cậy thấp.
  bool get needsReview => value == null || confidence == FieldConfidence.low;
}

/// Engine trích xuất **đã dùng** cho một lần quét (data-model §2.3). AI lỗi/
/// timeout → phiên quét ghi `ruleBased` (FR-011).
enum ScanEngine { ruleBased, geminiNano, gemma3nE2b }

/// Kết quả trích xuất một lần quét — **đại lượng tạm**, chỉ sống trong luồng
/// chụp → xử lý → xác nhận; chỉ `parsedJson` của nó được ghi vào `scan_sessions`.
class ScanExtraction {
  const ScanExtraction({
    this.type = TxnType.expense,
    this.typeNeedsReview = false,
    this.amount = const ScanField<int>(),
    this.date = const ScanField<DateTime>(),
    this.merchant = const ScanField<String>(),
    this.category = const ScanField<Category>(),
    this.engine = ScanEngine.ruleBased,
  });

  /// `expense` khi hóa đơn (FR-025); ảnh ngân hàng có thể là `income` ngay từ
  /// khi trích xuất (PBI 36). Người dùng vẫn đổi được ở màn xác nhận.
  final TxnType type;

  /// `true` khi bộ luật/AI không đủ căn cứ suy loại thu/chi (PBI 36, R8) — màn
  /// xác nhận hiển thị "Kiểm tra lại" dưới ô Loại giao dịch. Không áp dụng cho
  /// hóa đơn cửa hàng (luôn `false`).
  final bool typeNeedsReview;

  /// Rỗng ⇒ bắt buộc nhập tay trước khi lưu (FR-021/FR-032).
  final ScanField<int> amount;

  /// Không tìm thấy ⇒ `now` + `low` (FR-022).
  final ScanField<DateTime> date;

  /// Đổ vào **ghi chú** của giao dịch khi lưu (FR-031).
  final ScanField<String> merchant;

  /// Gợi ý theo từ điển; rỗng ⇒ để trống, **không** tự tạo danh mục (FR-024).
  final ScanField<Category> category;

  final ScanEngine engine;

  ScanExtraction copyWith({
    TxnType? type,
    bool? typeNeedsReview,
    ScanField<int>? amount,
    ScanField<DateTime>? date,
    ScanField<String>? merchant,
    ScanField<Category>? category,
    ScanEngine? engine,
  }) => ScanExtraction(
    type: type ?? this.type,
    typeNeedsReview: typeNeedsReview ?? this.typeNeedsReview,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    merchant: merchant ?? this.merchant,
    category: category ?? this.category,
    engine: engine ?? this.engine,
  );

  /// JSON ghi vào `scan_sessions.parsed_json`. Chỉ **ghi** — đọc lại thuộc PBI
  /// Scan History (data-model §2.4).
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'typeNeedsReview': typeNeedsReview,
    'engine': engine.name,
    'amount': amount.value,
    'amountConfidence': amount.confidence.name,
    'date': date.value?.toIso8601String(),
    'dateConfidence': date.confidence.name,
    'merchant': merchant.value,
    'merchantConfidence': merchant.confidence.name,
    'categoryId': category.value?.id,
    'categoryConfidence': category.confidence.name,
  };
}

/// Một dòng `scan_sessions` — vết của lần quét đã lưu (FR-034).
class ScanRecord {
  const ScanRecord({
    required this.imagePath,
    required this.rawText,
    required this.parsedJson,
    required this.engine,
    required this.createdAt,
    this.transactionId,
  });

  final String imagePath;
  final String rawText;
  final String parsedJson;
  final ScanEngine engine;
  final DateTime createdAt;
  final int? transactionId;
}
