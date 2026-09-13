import 'package:sora_thu_chi/core/notification/notification_prefs.dart';
import 'package:sora_thu_chi/core/notification/notification_store.dart';

/// Bản bộ nhớ của [NotificationStore] — dùng cho mọi widget test (không cần
/// sqlite native). [storedPrefs] cho phép test khởi tạo trạng thái có sẵn (VD
/// mở lại màn sau khi đổi) và assert trạng thái store sau khi chạm công tắc.
class FakeNotificationStore implements NotificationStore {
  /// [asked] mặc định `true` = "đã hỏi quyền rồi" ⇒ **không** hộp thoại soft-ask
  /// bật lên (mọi test PBI 28/29 mở màn `01` giữ nguyên hành vi cũ). Test nào
  /// muốn kiểm lần mở ĐẦU TIÊN thì truyền `asked: false`.
  FakeNotificationStore({
    NotificationPrefs? storedPrefs,
    this.failLoad = false,
    this.asked = true,
  }) : _prefs = storedPrefs ?? NotificationPrefs.defaults;

  NotificationPrefs _prefs;

  /// Store hiện tại (chỉ đọc) — test assert sau khi bật/tắt công tắc.
  NotificationPrefs get storedPrefs => _prefs;

  /// Mô phỏng `load()` lỗi (nhánh "Không đọc được cài đặt."). Đổi được để test
  /// nút "Thử lại" đọc thành công ở lần thứ hai.
  bool failLoad;

  @override
  Future<NotificationPrefs> load() async {
    if (failLoad) throw StateError('load failed');
    return _prefs;
  }

  @override
  Future<void> save(NotificationPrefs prefs) async {
    _prefs = prefs;
  }

  /// Cờ soft-ask (PBI 31) — test khởi tạo `true` để mô phỏng "đã hỏi rồi".
  bool asked;

  @override
  Future<bool> permissionAsked() async => asked;

  @override
  Future<void> markPermissionAsked() async => asked = true;
}
