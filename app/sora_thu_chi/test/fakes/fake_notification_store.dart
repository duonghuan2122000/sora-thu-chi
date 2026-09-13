import 'package:sora_thu_chi/core/notification/notification_prefs.dart';
import 'package:sora_thu_chi/core/notification/notification_store.dart';

/// Bản bộ nhớ của [NotificationStore] — dùng cho mọi widget test (không cần
/// sqlite native). [storedPrefs] cho phép test khởi tạo trạng thái có sẵn (VD
/// mở lại màn sau khi đổi) và assert trạng thái store sau khi chạm công tắc.
class FakeNotificationStore implements NotificationStore {
  FakeNotificationStore({NotificationPrefs? storedPrefs, this.failLoad = false})
    : _prefs = storedPrefs ?? NotificationPrefs.defaults;

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
}
