/// Module **thuần** (không Widget, không I/O) tính mốc thời gian, khoá nghiệp vụ
/// và id hệ điều hành của engine thông báo (PBI 31, R2/R3/R7).
///
/// Hai quyết định định hình cả file:
///
/// * **Nhắc hàng ngày dùng lịch MỘT-LẦN cho từng mốc** trong cửa sổ [kDailyWindowDays]
///   ngày, cuốn lại mỗi lần app chạy — lặp theo `dayOfWeekAndTime` **không huỷ
///   được một mốc** (cờ "chỉ nhắc nếu chưa ghi" cần đúng khả năng đó — R2/R5).
/// * **Khoá nghiệp vụ mang kỳ** (`daily:2026-09-13`, `budget:over:3:2026-09-01`…)
///   ⇒ chống trùng **gắn với kỳ** thay vì vĩnh viễn: sang kỳ mới tự do báo lại.
library;

/// Số ngày đăng ký trước cho nhắc hàng ngày (R2) — cái giá bắt buộc để huỷ được
/// đúng một mốc; người dùng không mở app > 30 ngày thì hết nhắc (quickstart §5).
const int kDailyWindowDays = 30;

String _two(int value) => value.toString().padLeft(2, '0');

String _dayKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// Các mốc bắn của nhắc hàng ngày: mọi ngày trong [windowDays] ngày kể từ hôm
/// nay **thuộc** [weekdays] (ISO: 1 = Thứ Hai … 7 = Chủ Nhật), tại [hour]:[minute],
/// **bỏ** mốc đã trôi qua so với [now] (FR-028 — không bắn bù).
///
/// Không bao giờ ném: `hour`/`minute` ngoài miền được kẹp vào miền hợp lệ
/// (dữ liệu DB là dữ liệu người dùng); [weekdays] rỗng ⇒ danh sách rỗng.
List<DateTime> dailyFireMoments({
  required DateTime now,
  required int hour,
  required int minute,
  required List<int> weekdays,
  int windowDays = kDailyWindowDays,
}) {
  if (weekdays.isEmpty || windowDays <= 0) return const [];
  final h = hour.clamp(0, 23);
  final m = minute.clamp(0, 59);
  final today = DateTime(now.year, now.month, now.day);
  final out = <DateTime>[];
  for (var i = 0; i < windowDays; i++) {
    final day = DateTime(today.year, today.month, today.day + i);
    if (!weekdays.contains(day.weekday)) continue;
    final moment = DateTime(day.year, day.month, day.day, h, m);
    if (!moment.isAfter(now)) continue;
    out.add(moment);
  }
  return out;
}

/// Mốc tổng kết tuần **kế tiếp**: Chủ Nhật gần nhất tại [hour]:[minute] — hôm
/// nay là Chủ Nhật và giờ chưa qua ⇒ **hôm nay**. Mốc này tổng kết tuần vừa kết
/// thúc (thứ Hai…Chủ Nhật), nên nó luôn rơi vào **cuối** tuần đang chạy (R3).
DateTime nextWeeklySummaryMoment(DateTime now, int hour, int minute) {
  final h = hour.clamp(0, 23);
  final m = minute.clamp(0, 59);
  var daysAhead = (DateTime.sunday - now.weekday + 7) % 7;
  var moment = DateTime(now.year, now.month, now.day + daysAhead, h, m);
  if (!moment.isAfter(now)) {
    daysAhead += 7;
    moment = DateTime(now.year, now.month, now.day + daysAhead, h, m);
  }
  return moment;
}

/// Mốc tổng kết tháng **kế tiếp**: ngày **cuối tháng** gần nhất tại [hour]:[minute]
/// (đúng 28/29/30/31 — `DateTime(y, m + 1, 0)`), hôm nay đã qua giờ ⇒ tháng sau.
/// `dayOfMonthAndTime` của plugin không diễn tả được "ngày cuối tháng" (R3).
DateTime nextMonthlySummaryMoment(DateTime now, int hour, int minute) {
  final h = hour.clamp(0, 23);
  final m = minute.clamp(0, 59);
  var moment = DateTime(
    now.year,
    now.month + 1,
    0,
    h,
    m,
  );
  if (!moment.isAfter(now)) {
    moment = DateTime(now.year, now.month + 2, 0, h, m);
  }
  return moment;
}

/// Khoá sổ của mốc nhắc hàng ngày — `daily:<yyyy-MM-dd>`.
String dailyEntryKey(DateTime day) => 'daily:${_dayKey(day)}';

/// Khoá sổ của mốc tổng kết tuần — `summary:week:<Thứ Hai đầu kỳ vừa kết thúc>`.
String summaryWeekEntryKey(DateTime mondayStart) =>
    'summary:week:${_dayKey(mondayStart)}';

/// Khoá sổ của mốc tổng kết tháng — `summary:month:<yyyy-MM>`.
String summaryMonthEntryKey(DateTime month) =>
    'summary:month:${month.year}-${_two(month.month)}';

/// Khoá sổ của cảnh báo ngân sách — `budget:early|over:<budgetId>:<đầu kỳ>`.
/// Mang **kỳ** trong khoá ⇒ cùng ngưỡng ở kỳ mới báo lại bình thường (luật 5).
String budgetEntryKey({
  required int budgetId,
  required bool over,
  required DateTime periodStart,
}) => 'budget:${over ? 'over' : 'early'}:$budgetId:${_dayKey(periodStart)}';

/// Id thông báo hệ điều hành của một khoá sổ — **FNV-1a 32-bit** tự viết.
///
/// Không dùng `String.hashCode`: giá trị của nó **không được bảo đảm ổn định**
/// giữa các bản SDK/Dart, trong khi id này phải tra lại đúng lịch đã đăng ký
/// sau khi app khởi động lại (R7). Trả về số **luôn dương** (bỏ bit dấu) — id
/// âm không hợp lệ với `AndroidFlutterLocalNotificationsPlugin`.
int notificationIdFor(String entryKey) {
  var hash = 0x811c9dc5;
  for (final byte in entryKey.codeUnits) {
    hash ^= byte & 0xFF;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}
