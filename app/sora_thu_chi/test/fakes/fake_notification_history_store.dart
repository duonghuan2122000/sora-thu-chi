import 'package:sora_thu_chi/core/notification/app_notification.dart';
import 'package:sora_thu_chi/core/notification/notification_history_store.dart';

/// Bản bộ nhớ của [NotificationHistoryStore] — dùng cho mọi widget test (không
/// cần sqlite native). [stored] cho phép test khởi tạo lịch sử có sẵn và assert
/// trạng thái sau khi chạm mục. [failLoad]/[failMarkRead] mô phỏng nhánh lỗi;
/// đổi được để test nút "Thử lại" thành công ở lần đọc thứ hai.
class FakeNotificationHistoryStore implements NotificationHistoryStore {
  FakeNotificationHistoryStore({List<AppNotification>? stored})
    : stored = List<AppNotification>.of(stored ?? const []);

  /// Lịch sử hiện tại (mới nhất trước) — test assert sau khi đọc mục.
  final List<AppNotification> stored;

  bool failLoad = false;
  bool failMarkRead = false;

  /// Số lần [append] đã gọi — assert chèn đúng 1 dòng khi cần.
  int appendCount = 0;

  @override
  Future<List<AppNotification>> loadRecent() async {
    if (failLoad) throw StateError('load failed');
    return List<AppNotification>.of(stored);
  }

  @override
  Future<void> append(AppNotification notification) async {
    appendCount++;
    stored.insert(
      0,
      AppNotification(
        id: stored.length + 1,
        kind: notification.kind,
        title: notification.title,
        body: notification.body,
        createdAt: notification.createdAt,
        readAt: notification.readAt,
        relatedId: notification.relatedId,
      ),
    );
  }

  @override
  Future<void> markRead(int id, DateTime readAt) async {
    if (failMarkRead) throw StateError('markRead failed');
    final index = stored.indexWhere((n) => n.id == id);
    if (index < 0 || stored[index].isRead) return;
    stored[index] = stored[index].copyWith(readAt: readAt);
  }
}
