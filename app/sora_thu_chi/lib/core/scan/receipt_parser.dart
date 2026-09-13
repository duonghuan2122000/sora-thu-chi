import '../category/category.dart';
import '../transaction/transaction.dart';
import 'merchant_dictionary.dart';
import 'scan_result.dart';

/// Đọc một **token** số tiền tiếng Việt → VND, `null` nếu không phải số tiền.
/// Hiểu `55.000` / `55,000` / `55 000` / `55000` / `55.000đ`; **loại** `12.5`
/// (phần thập phân) và số **< 1000 không nhóm nghìn** (`550` — không phải tiền)
/// (FR-021, data-model §3).
int? parseVietnameseAmount(String raw) {
  // Bỏ ký hiệu tiền tệ + mọi khoảng trắng (dấu cách cũng dùng làm nhóm nghìn).
  var text = raw.trim().toLowerCase().replaceAll('vnđ', '').replaceAll('vnd', '');
  if (text.endsWith('đ')) text = text.substring(0, text.length - 1);
  text = text.replaceAll(RegExp(r'\s+'), '');
  if (text.isEmpty) return null;

  if (RegExp(r'^\d{1,3}(?:[.,]\d{3})+$').hasMatch(text)) {
    return int.tryParse(text.replaceAll(RegExp(r'[.,]'), ''));
  }
  if (RegExp(r'^\d+$').hasMatch(text)) {
    final value = int.tryParse(text);
    // Số không nhóm nghìn mà < 1000 (giờ, số lượng, mã) không phải số tiền.
    if (value == null || value < 1000) return null;
    return value;
  }
  return null;
}

/// Token số tiền trong một dòng: nhóm nghìn (`55.000`, `55,000`) hoặc chuỗi
/// ≥ 4 chữ số liền (`55000`). `12.5` không khớp ⇒ không bao giờ thành số tiền.
final RegExp _amountToken = RegExp(r'\d{1,3}(?:[.,]\d{3})+(?!\d)|\d{4,}');

/// Nối `55 000` → `55000` để token hoá được (dấu cách làm nhóm nghìn).
final RegExp _spaceGrouped = RegExp(r'(\d) +(?=\d{3}(?:\D|$))');

/// Từ khoá dòng tổng (đã bỏ dấu) — ưu tiên cao nhất khi tìm số tiền (FR-021).
const List<String> _totalKeywords = [
  'tong cong',
  'tong tien',
  'thanh toan',
  't.tien',
  'phai tra',
  'total',
  'tong',
  'cong',
];

/// Từ khoá dòng tên cửa hàng (FR-024) — chỉ nhận nhãn rõ ràng, không nhận "CN"
/// (dòng "CN Trần Duy Hưng" là chi nhánh, không phải tên cửa hàng).
const List<String> _merchantKeywords = [
  'cua hang',
  'chi nhanh',
  'store',
  'branch',
  'nha hang',
];

/// Bộ luật trích xuất hóa đơn (FR-021…FR-026) — thuần Dart trên văn bản OCR,
/// không đọc DB/mạng/BuildContext. Thứ tự: số tiền → ngày → cửa hàng → danh mục.
ScanExtraction parseReceipt({
  required List<ScanTextLine> lines,
  required DateTime now,
  List<Category> expenseCategories = const [],
  List<Category> incomeCategories = const [],
}) {
  final amount = _parseAmount(lines);
  final date = _parseDate(lines, now);
  final merchant = _parseMerchant(lines);
  return ScanExtraction(
    // Hóa đơn luôn khởi tạo là khoản chi (FR-025); người dùng đổi ở màn xác nhận.
    type: TxnType.expense,
    amount: amount,
    date: date,
    merchant: merchant,
    category: _parseCategory(merchant, expenseCategories, incomeCategories),
    engine: ScanEngine.ruleBased,
  );
}

ScanField<int> _parseAmount(List<ScanTextLine> lines) {
  // (1) Ưu tiên dòng có từ khoá tổng — lấy số lớn nhất trong các dòng đó.
  final fromTotal = _largestAmount(
    lines.where((l) => _hasTotalKeyword(_norm(l.text)) && !_isNonAmountLine(_norm(l.text))),
  );
  if (fromTotal != null) return fromTotal;

  // (2) Không có dòng tổng → số lớn nhất còn lại (bỏ dòng ngày/ĐT/MST).
  final fallback = _largestAmount(
    lines.where((l) => !_isNonAmountLine(_norm(l.text))),
  );
  if (fallback != null) {
    return ScanField(
      value: fallback.value,
      confidence: FieldConfidence.medium,
      rect: fallback.rect,
    );
  }
  return const ScanField<int>();
}

/// Số tiền lớn nhất trong [lines]; trùng số → lấy dòng **cuối** hóa đơn.
ScanField<int>? _largestAmount(Iterable<ScanTextLine> lines) {
  int? best;
  ScanRect? bestRect;
  for (final line in lines) {
    for (final token in _amountTokensOf(line.text)) {
      final value = parseVietnameseAmount(token);
      if (value == null) continue;
      if (best == null || value >= best) {
        best = value;
        bestRect = line.rect;
      }
    }
  }
  if (best == null) return null;
  return ScanField(value: best, confidence: FieldConfidence.high, rect: bestRect);
}

Iterable<String> _amountTokensOf(String text) =>
    _amountToken.allMatches(text.replaceAllMapped(_spaceGrouped, (m) => m[1]!))
        .map((m) => m.group(0)!);

bool _hasTotalKeyword(String normalized) =>
    _totalKeywords.any(normalized.contains);

/// Dòng ngày/giờ/điện thoại/MST — **không** được lấy số trong dòng này làm tiền
/// (bất biến 12, rủi ro 8).
bool _isNonAmountLine(String normalized) {
  if (RegExp(r'\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}').hasMatch(normalized)) return true;
  if (RegExp(r'\d{1,2}:\d{2}').hasMatch(normalized)) return true;
  final words = normalized.split(RegExp(r'[^a-z0-9]+'));
  for (final keyword in const ['dt', 'dien thoai', 'tel', 'hotline', 'fax', 'mst']) {
    if (words.contains(keyword)) return true;
  }
  for (final phrase in const ['ma so thue', 'so hoa don', 'www', 'http', '@']) {
    if (normalized.contains(phrase)) return true;
  }
  return false;
}

/// Ngày trên hóa đơn: `dd/mm/yyyy`, `dd-mm-yyyy`, `dd.mm.yyyy`, `yyyy-mm-dd`
/// (kèm giờ `hh:mm` tùy chọn). Không tìm thấy/ngày sai → `now` + `low` (FR-022).
ScanField<DateTime> _parseDate(List<ScanTextLine> lines, DateTime now) {
  final patterns = <RegExp>[
    RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})'),
    RegExp(r'(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})'),
  ];
  for (final line in lines) {
    final time = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(line.text);
    for (var i = 0; i < patterns.length; i++) {
      final m = patterns[i].firstMatch(line.text);
      if (m == null) continue;
      final date = i == 0
          ? _buildDate(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!))
          : _buildDate(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
      if (date == null) continue;
      final hasTime = time != null;
      return ScanField(
        value: hasTime
            ? DateTime(
                date.year,
                date.month,
                date.day,
                int.parse(time[1]!),
                int.parse(time[2]!),
              )
            : date,
        confidence: FieldConfidence.high,
        rect: line.rect,
      );
    }
  }
  return ScanField(value: now, confidence: FieldConfidence.low);
}

/// `null` khi ngày không tồn tại thật (VD 31/02) — bỏ qua, không bịa.
DateTime? _buildDate(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final date = DateTime(year, month, day);
  if (date.month != month || date.day != day) return null;
  return date;
}

/// Cửa hàng: dòng có nhãn ("Cửa hàng", "Chi nhánh"…) → tin cậy **trung bình**;
/// không có nhãn → dòng chữ **lớn nhất trong 30% đầu ảnh** (theo chiều cao
/// vùng chữ) → tin cậy **thấp** (người dùng phải kiểm tra lại, FR-024/FR-026).
ScanField<String> _parseMerchant(List<ScanTextLine> lines) {
  for (final line in lines) {
    if (_merchantKeywords.any(_norm(line.text).contains)) {
      return ScanField(
        value: line.text.trim(),
        confidence: FieldConfidence.medium,
        rect: line.rect,
      );
    }
  }
  ScanTextLine? biggest;
  for (final line in lines) {
    if (line.rect.centerY > 0.3) continue;
    if (line.text.trim().isEmpty) continue;
    if (biggest == null || line.rect.height > biggest.rect.height) biggest = line;
  }
  if (biggest == null) return const ScanField<String>();
  return ScanField(
    value: biggest.text.trim(),
    confidence: FieldConfidence.low,
    rect: biggest.rect,
  );
}

/// Danh mục gợi ý — chỉ tra từ điển rồi đối chiếu **danh mục đang hoạt động**;
/// không khớp → để trống, không tự tạo danh mục (FR-024).
ScanField<Category> _parseCategory(
  ScanField<String> merchant,
  List<Category> expenseCategories,
  List<Category> incomeCategories,
) {
  final suggested = suggestCategoryName(merchant.value);
  if (suggested == null) return const ScanField<Category>();
  final resolved =
      resolveCategory(suggested, expenseCategories) ??
      resolveCategory(suggested, incomeCategories);
  if (resolved == null) return const ScanField<Category>();
  return ScanField(
    value: resolved,
    confidence: FieldConfidence.medium,
  );
}

String _norm(String text) => normalizeForMatch(text);
