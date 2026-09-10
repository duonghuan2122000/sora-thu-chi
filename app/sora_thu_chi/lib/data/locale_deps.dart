import 'package:get/get.dart';

import '../core/locale/locale_controller.dart';
import '../core/locale/locale_store.dart';
import 'db/app_database.dart';
import 'locale_store_drift.dart';

/// Đăng ký [LocaleStore] bền vững (Get singleton): tạo đúng **1**
/// `DriftLocaleStore(AppDatabase())` cho cả app. Test đăng ký fake (Get.put)
/// trước → hàm trả về fake đó, không tạo drift.
LocaleStore ensureLocaleStore() {
  if (Get.isRegistered<LocaleStore>()) {
    return Get.find<LocaleStore>();
  }
  final store = DriftLocaleStore(AppDatabase());
  Get.put<LocaleStore>(store);
  return store;
}

/// Đăng ký [LocaleController] (Get singleton) với store hiện hành.
LocaleController ensureLocaleController() {
  if (Get.isRegistered<LocaleController>()) {
    return Get.find<LocaleController>();
  }
  final controller = LocaleController(ensureLocaleStore());
  Get.put<LocaleController>(controller);
  return controller;
}
