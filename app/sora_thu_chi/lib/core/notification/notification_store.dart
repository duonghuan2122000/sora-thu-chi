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

  /// Đã từng hiện **lời giải thích trong app** (soft-ask) ở màn `01` chưa —
  /// `true` ⇒ **không** hỏi lại, bất kể người dùng đã đồng ý hay từ chối
  /// (FR-017/AC#27/SC-018). Row vắng = chưa từng hỏi.
  ///
  /// Đặt ở **cùng seam** với [load]/[save] (khác plan.md: thêm 2 hàm vào
  /// `NotificationStore` thay vì seam mới) để cấu hình thông báo chỉ có **một**
  /// chỗ sở hữu — không nở thêm một seam + impl + fake chỉ vì 1 cờ boolean.
  Future<bool> permissionAsked();

  /// Đánh dấu đã hỏi — gọi **sau** khi hộp thoại giải thích đã hiện, dù người
  /// dùng chọn đồng ý hay không (FR-017).
  Future<void> markPermissionAsked();
}
