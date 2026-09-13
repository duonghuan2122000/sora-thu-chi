import 'notification_prefs.dart';

/// Seam đọc/ghi cấu hình thông báo — màn chỉ phụ thuộc interface này để test bơm
/// fake (không cần sqlite native). Impl thật: `DriftNotificationStore`. Engine
/// thông báo (PBI sau) đọc cùng store qua GetX singleton.
abstract class NotificationStore {
  /// Đọc cấu hình hiện hành — row vắng hoặc JSON hỏng → bộ mặc định
  /// ([NotificationPrefs.fromSettings]).
  Future<NotificationPrefs> load();

  /// Upsert **1 row** `notificationPrefs`; không xoá row `AppSettings` nào khác.
  Future<void> save(NotificationPrefs prefs);
}
