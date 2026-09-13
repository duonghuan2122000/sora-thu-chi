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

/// Nhãn ngày viết tắt theo ISO (`1` = Thứ Hai … `7` = Chủ Nhật): `'T2'`…`'CN'`
/// (EN: `Mon`…`Sun`); ngoài miền → chuỗi rỗng. Viết literal ngay trước `.tr` để
/// test dịch còn ràng buộc được (R11).
String dayLabel(int weekday) => switch (weekday) {
  1 => 'T2'.tr,
  2 => 'T3'.tr,
  3 => 'T4'.tr,
  4 => 'T5'.tr,
  5 => 'T6'.tr,
  6 => 'T7'.tr,
  7 => 'CN'.tr,
  _ => '',
};

/// Tập ngày → chuỗi cho dòng phụ màn "Thông báo & nhắc nhở" (FR-011): dải liên
/// tiếp trong tuần (T2…T7) dài **≥3** nén thành `'T2–T7'`, ngày rời liệt kê
/// riêng, phân cách `', '` (`[1,2,3,5]` → `'T2–T4, T6'`). **Chủ Nhật luôn liệt
/// kê riêng** — tuần đọc là `T2…T7` + `CN` (`[1..7]` → `'T2–T7, CN'`). Rỗng →
/// chuỗi rỗng.
String daysLabel(List<int> weekdays) {
  final days = weekdays.toSet().toList()..sort();
  final week = days.where((d) => d != 7).toList();
  final parts = <String>[];
  var i = 0;
  while (i < week.length) {
    var j = i;
    while (j + 1 < week.length && week[j + 1] == week[j] + 1) {
      j++;
    }
    if (j - i + 1 >= 3) {
      parts.add('${dayLabel(week[i])}–${dayLabel(week[j])}');
    } else {
      for (var k = i; k <= j; k++) {
        parts.add(dayLabel(week[k]));
      }
    }
    i = j + 1;
  }
  if (days.contains(7)) parts.add(dayLabel(7));
  return parts.join(', ');
}

/// Giờ `'HH:mm'` 24h, mỗi số 2 chữ số — dùng chung cho mọi dòng hiển thị giờ.
/// Không đổi theo ngôn ngữ (FR-015).
String formatClock(int hour, int minute) => '${_two(hour)}:${_two(minute)}';

/// Giờ `'HH:mm'` — dòng phụ giao dịch trong kỳ ở màn Chi tiết Ngân sách
/// (PBI 21, mockup `03`: "Hôm nay, 12:30").
String formatTimeLabel(DateTime d) => formatClock(d.hour, d.minute);

/// Định dạng ngày giờ vùng chi tiết giao dịch `'dd/MM/yyyy · HH:mm'` (mỗi số
/// 2 chữ số, dấu `·`) — hàng "Ngày giờ" màn chi tiết (PBI 10, mockup 04).
/// Tách riêng [formatDateTimeLabel] (PBI 8 đang dùng) để không đổi hành vi.
String formatDateTimeDetailLabel(DateTime d) =>
    '${_two(d.day)}/${_two(d.month)}/${d.year} · ${_two(d.hour)}:${_two(d.minute)}';
