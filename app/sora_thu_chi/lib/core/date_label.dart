/// Nhãn ngày thân thiện cho dòng giao dịch — không thêm thư viện.
/// Cùng ngày lịch với [now] → `'Hôm nay'`; hôm qua → `'Hôm qua'`;
/// khác → `'dd/MM'`. [now] truyền vào để test deterministic (mặc định giờ thật).
String relativeDayLabel(DateTime date, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  final day = DateTime(date.year, date.month, date.day);
  final daysAgo = today.difference(day).inDays;
  if (daysAgo == 0) return 'Hôm nay';
  if (daysAgo == 1) return 'Hôm qua';
  return '${_two(date.day)}/${_two(date.month)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
