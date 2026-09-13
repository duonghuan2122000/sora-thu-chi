import 'package:get/get.dart';

import '../date_label.dart';

/// Trần lịch sử thông báo được lưu (FR-010) — hằng số, **không** phải cấu hình
/// người dùng. Cưỡng chế ở tầng ghi ([append] của `NotificationHistoryStore`).
const int kMaxNotifications = 200;

/// 5 loại thông báo (doc §2) — lưu `.name` trong DB qua `textEnum`, đích điều
/// hướng khi chạm do **loại** quyết định (FR-008), không lưu riêng.
enum NotificationKind {
  dailyReminder,
  budgetAlert,
  recurringDue,
  goalReminder,
  periodSummary,
}

/// Nhóm thời gian của một mục trên màn Trung tâm (FR-004) — tính theo **ngày
/// lịch**, "TUẦN NÀY" = 7 ngày gần nhất (không cắt theo tuần lịch — research R8).
enum NotificationGroup {
  today,
  thisWeek,
  earlier;

  String get label => switch (this) {
    NotificationGroup.today => 'HÔM NAY'.tr,
    NotificationGroup.thisWeek => 'TUẦN NÀY'.tr,
    NotificationGroup.earlier => 'TRƯỚC ĐÓ'.tr,
  };
}

/// Một thông báo **đã phát sinh** (doc §3.1 `NotificationLog`) — tầng nghiệp vụ
/// thuần, không `Widget`/màu/icon. `title`/`body` là **snapshot** do engine sinh
/// lúc bắn ⇒ hiển thị nguyên văn, không dịch lại (FR-014).
class AppNotification {
  const AppNotification({
    this.id = 0,
    required this.kind,
    required this.title,
    this.body = '',
    required this.createdAt,
    this.readAt,
    this.relatedId,
  });

  /// Khoá dòng trong DB; `0` = chưa ghi (dùng khi dựng đối tượng để `append`).
  final int id;

  final NotificationKind kind;

  /// Tiêu đề hiển thị nguyên văn (snapshot).
  final String title;

  /// Dòng mô tả kèm số liệu (snapshot); `''` hợp lệ — mục chỉ có tiêu đề.
  final String body;

  /// Thời điểm **phát sinh** (múi giờ thiết bị) — khoá sắp xếp + tính nhóm.
  final DateTime createdAt;

  /// `null` = chưa đọc; có giá trị = đã đọc **tại thời điểm đó** (một chiều).
  final DateTime? readAt;

  /// Id đối tượng nghiệp vụ liên quan (ngân sách/định kỳ/mục tiêu); không FK.
  final int? relatedId;

  bool get isRead => readAt != null;

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    createdAt: createdAt,
    readAt: readAt ?? this.readAt,
    relatedId: relatedId,
  );

  @override
  bool operator ==(Object other) =>
      other is AppNotification &&
      other.id == id &&
      other.kind == kind &&
      other.title == title &&
      other.body == body &&
      other.createdAt == createdAt &&
      other.readAt == readAt &&
      other.relatedId == relatedId;

  @override
  int get hashCode =>
      Object.hash(id, kind, title, body, createdAt, readAt, relatedId);
}

/// Nhóm thời gian của mục phát sinh lúc [at] so với mốc [now] (luật 18): cùng
/// **ngày lịch** → `today`; 1…7 ngày trước → `thisWeek`; hơn 7 ngày → `earlier`.
NotificationGroup notificationGroup(DateTime at, DateTime now) {
  final day = DateTime(at.year, at.month, at.day);
  final ref = DateTime(now.year, now.month, now.day);
  final daysAgo = ref.difference(day).inDays;
  if (daysAgo <= 0) return NotificationGroup.today;
  if (daysAgo <= 7) return NotificationGroup.thisWeek;
  return NotificationGroup.earlier;
}

/// Nhãn thời gian của mục (luật 19): cùng ngày → `HH:mm`; 1…7 ngày → tên thứ
/// đầy đủ; cũ hơn → `dd/MM`. Không đổi theo ngôn ngữ (trừ tên thứ — FR-014).
String notificationTimeLabel(DateTime at, DateTime now) {
  switch (notificationGroup(at, now)) {
    case NotificationGroup.today:
      return formatClock(at.hour, at.minute);
    case NotificationGroup.thisWeek:
      return weekdayName(at.weekday);
    case NotificationGroup.earlier:
      return '${_two(at.day)}/${_two(at.month)}';
  }
}

String _two(int value) => value.toString().padLeft(2, '0');
