import 'package:get/get.dart';

import '../core/notification/notification_engine.dart';
import '../core/notification/notification_ledger.dart';
import '../core/notification/notification_presenter.dart';
import '../core/notification/notification_presence.dart';
import '../core/notification/notification_store.dart';
import '../core/notification/notification_tap.dart';
import 'db/app_database.dart' hide NotificationLedger;
import 'notification_history_deps.dart';
import 'notification_ledger_drift.dart';
import 'notification_presenter_plugin.dart';
import 'notification_store_drift.dart';
import 'wallet_deps.dart';

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

/// Đăng ký **sổ thông báo** (PBI 31) — khuôn [ensureNotificationStore]: một
/// connection drift cho cả app; test `Get.put` fake trước ⇒ trả fake.
NotificationLedger ensureNotificationLedger() {
  if (Get.isRegistered<NotificationLedger>()) {
    return Get.find<NotificationLedger>();
  }
  final ledger = DriftNotificationLedger(AppDatabase());
  Get.put<NotificationLedger>(ledger);
  return ledger;
}

/// Đăng ký **cầu nối hệ điều hành** — test `Get.put` fake trước ⇒ không mở
/// plugin thật (không cần thiết bị).
NotificationPresenter ensureNotificationPresenter() {
  if (Get.isRegistered<NotificationPresenter>()) {
    return Get.find<NotificationPresenter>();
  }
  final presenter = PluginNotificationPresenter();
  Get.put<NotificationPresenter>(presenter);
  return presenter;
}

/// Dịch vụ **hiện diện** (Q3) — màn Chi tiết ngân sách / Báo cáo khai báo vào.
NotificationPresence ensureNotificationPresence() {
  if (Get.isRegistered<NotificationPresence>()) {
    return Get.find<NotificationPresence>();
  }
  final presence = NotificationPresence();
  Get.put<NotificationPresence>(presence);
  return presence;
}

/// **Hộp thư** payload chạm thông báo — sống qua màn mở khoá PIN (FR-019).
NotificationTapRouter ensureNotificationTapRouter() {
  if (Get.isRegistered<NotificationTapRouter>()) {
    return Get.find<NotificationTapRouter>();
  }
  final router = NotificationTapRouter();
  Get.put<NotificationTapRouter>(router);
  return router;
}

/// Đăng ký **engine** — gom 5 phụ thuộc qua các `ensure…` ở trên (dùng chung
/// connection drift với mọi màn khác).
NotificationEngine ensureNotificationEngine() {
  if (Get.isRegistered<NotificationEngine>()) {
    return Get.find<NotificationEngine>();
  }
  final engine = NotificationEngine(
    presenter: ensureNotificationPresenter(),
    ledger: ensureNotificationLedger(),
    history: ensureNotificationHistoryStore(),
    repository: ensureWalletRepository(),
    prefsStore: ensureNotificationStore(),
    presence: ensureNotificationPresence(),
  );
  Get.put<NotificationEngine>(engine);
  return engine;
}
