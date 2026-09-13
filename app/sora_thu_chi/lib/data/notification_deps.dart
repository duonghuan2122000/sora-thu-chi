import 'package:get/get.dart';

import '../core/notification/notification_store.dart';
import 'db/app_database.dart';
import 'notification_store_drift.dart';

/// Đăng ký [NotificationStore] bền vững (Get singleton): tạo đúng **1**
/// `DriftNotificationStore(AppDatabase())` cho cả app — tránh 2 connection drift
/// trên cùng file sqlite (bám `ensureUtilitiesStore`). Test đăng ký fake
/// (`Get.put`) trước → hàm trả về fake đó, không tạo drift.
NotificationStore ensureNotificationStore() {
  if (Get.isRegistered<NotificationStore>()) {
    return Get.find<NotificationStore>();
  }
  final store = DriftNotificationStore(AppDatabase());
  Get.put<NotificationStore>(store);
  return store;
}
