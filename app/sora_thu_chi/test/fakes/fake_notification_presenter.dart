import 'package:sora_thu_chi/core/notification/app_notification.dart';
import 'package:sora_thu_chi/core/notification/notification_presenter.dart';

/// Bản bộ nhớ của [NotificationPresenter] — ghi lại mọi lời gọi để test assert
/// "đúng 1 thông báo" / "đã huỷ mốc X" mà không cần plugin hay thiết bị (R15).
class FakeNotificationPresenter implements NotificationPresenter {
  /// Các mốc đã `schedule` (giữ nguyên thứ tự gọi).
  final List<OsNotification> scheduled = [];

  /// Các mốc đã `show` (bắn ngay — cảnh báo ngân sách).
  final List<OsNotification> shown = [];

  /// Id đã huỷ lẻ.
  final List<int> cancelled = [];

  /// Loại đã huỷ theo lô.
  final List<NotificationKind> cancelledKinds = [];

  int initCount = 0;
  int openSettingsCount = 0;
  int requestPermissionCount = 0;

  /// Quyền thông báo hiện có — test đổi để kiểm dòng trạng thái (FR-032).
  bool enabled = true;

  /// Kết quả `requestPermission()` — `false` mô phỏng người dùng từ chối.
  bool permissionResult = true;

  /// Payload của lần chạm đã mở app; `null` = mở bình thường.
  String? launchPayload_;

  bool failSchedule = false;

  @override
  Future<void> init() async => initCount++;

  @override
  Future<String?> launchPayload() async => launchPayload_;

  @override
  Future<bool> areEnabled() async => enabled;

  @override
  Future<bool> requestPermission() async {
    requestPermissionCount++;
    return permissionResult;
  }

  @override
  Future<void> openSettings() async => openSettingsCount++;

  @override
  Future<void> schedule(OsNotification notification) async {
    if (failSchedule) throw StateError('schedule failed');
    scheduled.add(notification);
  }

  @override
  Future<void> show(OsNotification notification) async => shown.add(notification);

  @override
  Future<void> cancel(int id) async => cancelled.add(id);

  @override
  Future<void> cancelKind(NotificationKind kind) async =>
      cancelledKinds.add(kind);

  /// Mốc đang chờ **thuộc** [kind] sau khi đã trừ các lần huỷ — tiện cho assert.
  List<OsNotification> pendingOf(NotificationKind kind) => scheduled
      .where(
        (n) =>
            n.kind == kind &&
            !cancelled.contains(n.id) &&
            !cancelledKinds.contains(kind),
      )
      .toList();
}
