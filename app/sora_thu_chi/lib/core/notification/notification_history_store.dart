import 'app_notification.dart';

/// Seam đọc/ghi **lịch sử** thông báo — tách rời [NotificationStore] (cấu hình,
/// PBI 28): màn Trung tâm chỉ phụ thuộc interface này để test bơm fake (không cần
/// sqlite native). Impl thật: `DriftNotificationHistoryStore`. Engine thông báo
/// (PBI sau) là nguồn ghi duy nhất qua [append].
///
/// Cố ý **không** có `unreadCount` (đếm bằng Dart ở chỗ gọi), `markAllRead` và
/// `delete` — spec cấm thao tác hàng loạt/xoá (FR-019, Q2=A).
abstract class NotificationHistoryStore {
  /// Toàn bộ lịch sử, **mới nhất trước** (`createdAt DESC, id DESC`); bảng rỗng
  /// → `[]` (không ném).
  Future<List<AppNotification>> loadRecent();

  /// Chèn 1 dòng (`id` của [notification] bị bỏ qua, DB tự sinh) rồi **dọn vượt
  /// trần** [kMaxNotifications] theo `(createdAt DESC, id DESC)`.
  Future<void> append(AppNotification notification);

  /// Đánh dấu đã đọc — chỉ dòng **đang chưa đọc** (một chiều, FR-009); gọi lại
  /// không đổi `readAt`; id không tồn tại → no-op, không ném.
  Future<void> markRead(int id, DateTime readAt);
}
