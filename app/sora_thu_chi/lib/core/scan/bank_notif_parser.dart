import '../category/category.dart';
import '../transaction/transaction.dart';
import 'merchant_dictionary.dart';
import 'receipt_parser.dart';
import 'scan_result.dart';

/// Từ khoá nhận diện ảnh thông báo ngân hàng (R2, PBI 36) — khớp trên chuỗi
/// đã chuẩn hoá (bỏ dấu + thường hoá). Tổng quát, không giới hạn ngân hàng cụ
/// thể (FR-009).
const List<String> _bankKeywords = [
  'so du',
  'tai khoan',
  'ghi no',
  'ghi co',
  'giao dich',
  'bien dong so du',
  '(debit)',
  '(credit)',
  'ma giao dich',
  'so tien',
];

/// `true` khi văn bản OCR khớp **≥ 2** từ khoá ngân hàng (R2) — một từ khoá
/// đơn lẻ có thể xuất hiện tình cờ trên hóa đơn (VD "Mã giao dịch" trên biên
/// lai POS).
bool looksLikeBankNotification(List<ScanTextLine> lines) {
  final text = _norm(lines.map((l) => l.text).join(' '));
  final matched = _bankKeywords.where(text.contains).length;
  return matched >= 2;
}

/// Từ khoá cùng dòng với số tiền giao dịch xác nhận đây là số cần lấy, ngay
/// cả khi không có dấu `+`/`-` liền trước (R3).
const List<String> _amountContextKeywords = [
  '(debit)',
  '(credit)',
  'ghi no',
  'ghi co',
  'so tien',
];

/// Nhãn ghi chú/nội dung/người nhận-gửi (R5) — theo thứ tự xuất hiện trong
/// ảnh, dòng khớp đầu tiên thắng.
const List<String> _noteLabels = ['gd:', 'noi dung', 'den:'];

// Chỉ nhận số **có phân cách nghìn** (`.`/`,`) ngay sau dấu +/- — số trần
// (VD "150926") thường là mảnh của mã tham chiếu/ngày dính trong dòng nội
// dung ("...KHOAN-150926-08:34:59"), không phải số tiền thật.
final RegExp _signedAmountToken = RegExp(r'([+\-])\s*(\d{1,3}(?:[.,]\d{3})+)(?!\d)');
final RegExp _amountToken = RegExp(r'\d{1,3}(?:[.,]\d{3})+(?!\d)|\d{4,}');

// Số tiền có **đơn vị đi kèm ngay sau** (`VND`/`đ`) — tín hiệu chắc chắn
// nhất, tránh nhầm với số tài khoản/mã trần trong banner thông báo hệ thống
// (VD "TK 750561(VND)..." không khớp vì đơn vị nằm trong ngoặc, không dính
// ngay sau số).
final RegExp _amountWithUnit = RegExp(
  r'(\d{1,3}(?:[.,]\d{3})+|\d{4,})\s*(vnd|đ)(?![a-zà-ỹ])',
  caseSensitive: false,
);

final RegExp _timePattern = RegExp(r'\d{1,2}:\d{2}');

/// Bộ luật trích xuất ảnh thông báo ngân hàng (R3–R6, PBI 36) — thuần Dart
/// trên văn bản OCR, chữ ký khớp [parseReceipt] để hoán đổi được trong
/// dispatcher của `ReceiptExtractor`.
ScanExtraction parseBankNotification({
  required List<ScanTextLine> lines,
  required DateTime now,
  List<Category> expenseCategories = const [],
  List<Category> incomeCategories = const [],
}) {
  // Loại hoàn toàn dòng "số dư" khỏi ứng viên số tiền (R3) — khác bộ luật hóa
  // đơn, vốn chỉ loại dòng ngày/ĐT/MST.
  final candidateLines = lines.where((l) => !_norm(l.text).contains('so du')).toList();
  final amountHit = _findAmount(candidateLines);
  final typeHit = _determineType(amountHit, _norm(lines.map((l) => l.text).join('\n')));
  final note = _parseNote(lines);

  return ScanExtraction(
    type: typeHit.type,
    typeNeedsReview: typeHit.needsReview,
    amount: amountHit == null
        ? const ScanField<int>()
        : ScanField(
            value: amountHit.value,
            confidence: amountHit.strong ? FieldConfidence.high : FieldConfidence.medium,
            rect: amountHit.rect,
          ),
    date: parseTxnDate(lines, now),
    merchant: note,
    category: const ScanField<Category>(),
    engine: ScanEngine.ruleBased,
  );
}

class _AmountHit {
  const _AmountHit(this.value, this.rect, this.line, this.sign, this.strong);

  final int value;
  final ScanRect rect;
  final ScanTextLine line;
  final String? sign;

  /// Tín hiệu rõ ràng (dấu +/- hoặc từ khoá cùng dòng) — khác fallback "số
  /// đầu tiên trong văn bản".
  final bool strong;
}

/// Số tiền giao dịch, theo thứ tự ưu tiên (R3):
/// 0. Số nằm trên dòng chữ **cỡ lớn nổi bật** (cao hơn hẳn mặt bằng chung) —
///    app ngân hàng luôn hiển thị số tiền to nhất màn hình; tín hiệu chắc
///    chắn nhất, không phụ thuộc từ khoá/định dạng OCR tách dòng thế nào.
/// 1. Số có đơn vị `VND`/`đ` dính ngay sau (SMS/email không có cỡ chữ khác biệt).
/// 2. Số có dấu `+`/`-` liền trước, dòng xuất hiện sớm nhất.
/// 3. Số trên dòng chứa từ khoá `(debit)`/`(credit)`/`ghi no`/`ghi co`/`so tien`.
/// 4. Số tiền đầu tiên xuất hiện trong văn bản (không phải "lớn nhất").
_AmountHit? _findAmount(List<ScanTextLine> candidateLines) {
  final prominent = _findProminentAmount(candidateLines);
  if (prominent != null) return prominent;
  for (final line in candidateLines) {
    final m = _amountWithUnit.firstMatch(line.text);
    if (m == null) continue;
    final value = parseVietnameseAmount(m.group(1)!);
    if (value != null) return _AmountHit(value, line.rect, line, null, true);
  }
  for (final line in candidateLines) {
    final m = _signedAmountToken.firstMatch(line.text);
    if (m == null) continue;
    final value = parseVietnameseAmount(m.group(2)!);
    if (value != null) return _AmountHit(value, line.rect, line, m.group(1), true);
  }
  for (final line in candidateLines) {
    if (!_amountContextKeywords.any(_norm(line.text).contains)) continue;
    final value = _firstAmountIn(line.text);
    if (value != null) return _AmountHit(value, line.rect, line, null, true);
  }
  // Fallback yếu nhất: bỏ qua dòng có dấu vết giờ:phút — đặc trưng của mã
  // tham chiếu/mã giao dịch dính trong "Nội dung" (VD "CHUYEN KHOAN-150926-
  // 08:34:59"), không phải số tiền. Dòng tiền hợp lệ đi kèm giờ (VD SMS ưu
  // tiên 1 "+29.896.000 lúc 13:49...") đã được nhận ở bước 1 trước đó rồi.
  for (final line in candidateLines) {
    if (_timePattern.hasMatch(line.text)) continue;
    final value = _firstAmountIn(line.text);
    if (value != null) return _AmountHit(value, line.rect, line, null, false);
  }
  return null;
}

/// Dòng chữ **cao hơn ≥1.3 lần** chiều cao trung bình các dòng ứng viên —
/// ngưỡng loại các ảnh có cỡ chữ đồng đều (VD SMS thuần văn bản, nơi tín
/// hiệu này không đáng tin) mà vẫn bắt được số tiền cỡ lớn trên app/email.
_AmountHit? _findProminentAmount(List<ScanTextLine> candidateLines) {
  if (candidateLines.length < 2) return null;
  final avgHeight =
      candidateLines.map((l) => l.rect.height).reduce((a, b) => a + b) /
      candidateLines.length;
  ScanTextLine? biggest;
  int? biggestValue;
  for (final line in candidateLines) {
    if (line.rect.height < avgHeight * 1.3) continue;
    final value = _firstAmountIn(line.text);
    if (value == null) continue;
    if (biggest == null || line.rect.height > biggest.rect.height) {
      biggest = line;
      biggestValue = value;
    }
  }
  if (biggest == null || biggestValue == null) return null;
  return _AmountHit(biggestValue, biggest.rect, biggest, null, true);
}

int? _firstAmountIn(String text) {
  for (final m in _amountToken.allMatches(text)) {
    final value = parseVietnameseAmount(m.group(0)!);
    if (value != null) return value;
  }
  return null;
}

class _TypeHit {
  const _TypeHit(this.type, this.needsReview);

  final TxnType type;
  final bool needsReview;
}

/// Suy loại thu/chi (R4): ưu tiên tín hiệu ngay trên dòng chứa số tiền đã
/// chọn, rồi mới tới toàn văn bản; không khớp gì ⇒ chi mặc định + cờ xem lại.
_TypeHit _determineType(_AmountHit? amountHit, String wholeText) {
  final lineText = amountHit == null ? '' : _norm(amountHit.line.text);
  if (_looksLikeDebit(lineText) || amountHit?.sign == '-') {
    return const _TypeHit(TxnType.expense, false);
  }
  if (_looksLikeCredit(lineText) || amountHit?.sign == '+') {
    return const _TypeHit(TxnType.income, false);
  }
  if (_looksLikeDebit(wholeText)) return const _TypeHit(TxnType.expense, false);
  if (_looksLikeCredit(wholeText)) return const _TypeHit(TxnType.income, false);
  // Xác nhận chuyển tiền không rõ ghi nợ/có ⇒ luôn là chi (tiền rời tài
  // khoản nguồn), độ tin cậy trung bình nhưng không cần người dùng xem lại.
  if (wholeText.contains('chuyen tien thanh cong')) {
    return const _TypeHit(TxnType.expense, false);
  }
  return const _TypeHit(TxnType.expense, true);
}

bool _looksLikeDebit(String normalized) =>
    normalized.contains('ghi no') || normalized.contains('debit');

bool _looksLikeCredit(String normalized) =>
    normalized.contains('ghi co') || normalized.contains('credit');

/// Nội dung/người nhận-gửi (R5) — dòng khớp nhãn đầu tiên (theo thứ tự xuất
/// hiện trong ảnh) thắng; đổ vào field `merchant` tái dùng (ô "Cửa hàng / Ghi
/// chú" ở màn xác nhận).
ScanField<String> _parseNote(List<ScanTextLine> lines) {
  for (final line in lines) {
    final norm = _norm(line.text);
    if (!_noteLabels.any(norm.contains)) continue;
    final idx = line.text.indexOf(':');
    if (idx < 0) continue;
    final value = line.text.substring(idx + 1).trim();
    if (value.isEmpty) continue;
    return ScanField(value: value, confidence: FieldConfidence.medium, rect: line.rect);
  }
  return const ScanField<String>();
}

String _norm(String text) => normalizeForMatch(text);
