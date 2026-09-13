import 'package:get/get.dart';

import '../core/notification/notification_history_store.dart';
import 'db/app_database.dart';
import 'notification_history_store_drift.dart';

/// Đăng ký [NotificationHistoryStore] bền vững (Get singleton): tạo đúng **1**
/// `DriftNotificationHistoryStore(AppDatabase())` cho cả app — tránh 2 connection
/// drift trên cùng file sqlite (bám `ensureNotificationStore`). Test đăng ký fake
/// (`Get.put`) trước → hàm trả về fake đó, không mở drift.
NotificationHistoryStore ensureNotificationHistoryStore() {
  if (Get.isRegistered<NotificationHistoryStore>()) {
    return Get.find<NotificationHistoryStore>();
  }
  final store = DriftNotificationHistoryStore(AppDatabase());
  Get.put<NotificationHistoryStore>(store);
  return store;
}
