import '../category/category.dart';
import '../wallet/wallet.dart';
import 'transaction.dart';

/// Các hàm thuần cho màn thêm giao dịch — tách khỏi widget để unit test
/// (data-model §View, R6/R9). Không đọc DB/state.

/// Nối [digit] (0..9) vào sau [current]. Bỏ số 0 đứng đầu (`0` + `5` → `5`),
/// chặn tràn quá [maxDigits] chữ số (giữ nguyên khi đạt trần — tránh tràn int).
int appendAmountDigit(int current, int digit, {int maxDigits = 12}) {
  if (digit < 0 || digit > 9) return current;
  if (current == 0) return digit;
  if (current.toString().length >= maxDigits) return current;
  return current * 10 + digit;
}

/// Xóa một chữ số cuối; `0` (hoặc 1 chữ số) → `0`.
int backspaceAmount(int current) => current ~/ 10;

/// Tên trường bắt buộc còn thiếu để lưu giao dịch thu/chi. Rỗng = đủ dữ liệu.
/// Thứ tự cố định amount → category → wallet → date cho caption hiển thị ổn định.
List<String> missingRequiredFields({
  required int amount,
  Category? category,
  Wallet? wallet,
  DateTime? date,
}) {
  final missing = <String>[];
  if (amount <= 0) missing.add('amount');
  if (category == null) missing.add('category');
  if (wallet == null) missing.add('wallet');
  if (date == null) missing.add('date');
  return missing;
}

/// Người dùng đã thay đổi gì đó so với trạng thái ban đầu chưa — quyết định có
/// cần dialog xác nhận khi rời màn (FR-014/R9). So sánh ngày theo phút (không
/// theo micro-giây) để form mở nguyên vẹn không bị coi là "dirty".
bool isDirty({
  required int amount,
  required Category? category,
  required String note,
  required DateTime date,
  required TxnType type,
  DateTime? now,
  bool hasTags = false,
  bool hasReceiptImage = false,
}) {
  final ref = now ?? DateTime.now();
  final sameMinute =
      date.year == ref.year &&
      date.month == ref.month &&
      date.day == ref.day &&
      date.hour == ref.hour &&
      date.minute == ref.minute;
  return amount > 0 ||
      category != null ||
      note.trim().isNotEmpty ||
      !sameMinute ||
      type != TxnType.expense ||
      hasTags ||
      hasReceiptImage;
}
