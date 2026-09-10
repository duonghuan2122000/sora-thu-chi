import 'package:get/get.dart';

/// Nhãn ngày thân thiện cho dòng giao dịch — không thêm thư viện.
/// Cùng ngày lịch với [now] → `'Hôm nay'`; hôm qua → `'Hôm qua'`;
/// khác → `'dd/MM'`. [now] truyền vào để test deterministic (mặc định giờ thật).
String relativeDayLabel(DateTime date, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  final day = DateTime(date.year, date.month, date.day);
  final daysAgo = today.difference(day).inDays;
  if (daysAgo == 0) return 'Hôm nay'.tr;
  if (daysAgo == 1) return 'Hôm qua'.tr;
  return '${_two(date.day)}/${_two(date.month)}';
}

String _two(int value) => value.toString().padLeft(2, '0');

/// Tiêu đề nhóm ngày trên màn danh sách giao dịch (FR-005): cùng ngày lịch với
/// [now] → `'HÔM NAY - dd/MM/yyyy'`, hôm trước → `'HÔM QUA - dd/MM/yyyy'`,
/// còn lại → `'dd/MM/yyyy'`. [now] truyền vào để test deterministic.
String formatDayGroupHeader(DateTime date, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  final day = DateTime(date.year, date.month, date.day);
  final full = '${_two(date.day)}/${_two(date.month)}/${date.year}';
  final daysAgo = today.difference(day).inDays;
  // Phần `dd/MM/yyyy` giữ nguyên định dạng (ngôn ngữ không đổi định dạng ngày).
  if (daysAgo == 0) return '${'HÔM NAY'.tr} - $full';
  if (daysAgo == 1) return '${'HÔM QUA'.tr} - $full';
  return full;
}

/// Định dạng ngày giờ đầy đủ `'dd/MM/yyyy HH:mm'` (mỗi số 2 chữ số) — dòng
/// hiển thị ngày giờ người dùng chọn trên màn chuyển tiền (FR-006).
String formatDateTimeLabel(DateTime d) =>
    '${_two(d.day)}/${_two(d.month)}/${d.year} ${_two(d.hour)}:${_two(d.minute)}';

/// Định dạng ngày giờ vùng chi tiết giao dịch `'dd/MM/yyyy · HH:mm'` (mỗi số
/// 2 chữ số, dấu `·`) — hàng "Ngày giờ" màn chi tiết (PBI 10, mockup 04).
/// Tách riêng [formatDateTimeLabel] (PBI 8 đang dùng) để không đổi hành vi.
String formatDateTimeDetailLabel(DateTime d) =>
    '${_two(d.day)}/${_two(d.month)}/${d.year} · ${_two(d.hour)}:${_two(d.minute)}';
