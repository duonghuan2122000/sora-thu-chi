import 'app_notification.dart';

/// Một mốc thông báo dưới góc nhìn **hệ điều hành** (PBI 31, data-model §2) —
/// không lưu DB. `id` = [notificationIdFor] của khoá sổ, nên cùng một khoá luôn
/// là cùng một id ⇒ thông báo **thay thế**, không xếp chồng (FR-026).
class OsNotification {
  const OsNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.at,
    required this.payload,
  });

  final int id;
  final NotificationKind kind;
  final String title;
  final String body;

  /// Mốc bắn (giờ địa phương) — với [NotificationPresenter.show] là "ngay bây giờ".
  final DateTime at;

  /// Dữ liệu kèm theo khi người dùng chạm — **chính là `entryKey`**, để engine
  /// tra ngược sổ (R7/R8).
  final String payload;
}

/// Seam bọc hệ điều hành (PBI 31, R15) — engine phụ thuộc interface này nên
/// **toàn bộ luật nghiệp vụ test được** mà không cần plugin/thiết bị.
///
/// Impl thật: `PluginNotificationPresenter`.
abstract class NotificationPresenter {
  /// Dựng 3 kênh (`sora_daily`/`sora_budget`/`sora_summary`), nạp múi giờ địa
  /// phương (`flutter_timezone` — thiếu là `tz.local` mãi là UTC ⇒ bắn sai giờ)
  /// và đăng ký callback khi người dùng chạm thông báo. Gọi **một lần** trước
  /// `runApp` (R13).
  Future<void> init();

  /// Payload của lần chạm đã mở app này (nếu có) — đọc **một lần** lúc boot rồi
  /// chuyển cho `NotificationTapRouter`; `null` khi app được mở bình thường.
  Future<String?> launchPayload();

  /// Quyền thông báo hiện có được bật không (FR-032).
  Future<bool> areEnabled();

  /// Xin quyền — trả `false` nếu người dùng/hệ điều hành từ chối.
  Future<bool> requestPermission();

  /// Mở màn cài đặt thông báo của hệ điều hành (lối thoát khi quyền bị tắt).
  Future<void> openSettings();

  /// Lên lịch **một lần** cho đúng một mốc.
  Future<void> schedule(OsNotification notification);

  /// Bắn **ngay** — chỉ dùng cho cảnh báo ngân sách (R4).
  Future<void> show(OsNotification notification);

  /// Huỷ một mốc theo id.
  Future<void> cancel(int id);

  /// Huỷ mọi mốc đang chờ **thuộc đúng loại** [kind] — dùng khi người dùng tắt
  /// một công tắc (FR-021) hoặc khi cuốn lại lịch (R2/R3).
  Future<void> cancelKind(NotificationKind kind);
}
