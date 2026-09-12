/// Khoảng thời gian nửa mở `[start, end)` — [end] **độc quyền**.
///
/// Kiểu dùng chung cho module Ngân sách (PBI 20) và Báo cáo (PBI 22);
/// `budget_view.dart` re-export để import cũ không phải sửa.
class DateRange {
  const DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool contains(DateTime moment) =>
      !moment.isBefore(start) && moment.isBefore(end);
}
