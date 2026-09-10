import 'package:get/get.dart';

import '../core/theme/theme_controller.dart';
import '../core/theme/theme_store.dart';
import 'db/app_database.dart';
import 'theme_store_drift.dart';

/// Đăng ký [ThemeStore] bền vững (Get singleton): tạo đúng **1**
/// `DriftThemeStore(AppDatabase())` cho cả app. Test đăng ký fake (Get.put)
/// trước → hàm trả về fake đó, không tạo drift.
ThemeStore ensureThemeStore() {
  if (Get.isRegistered<ThemeStore>()) {
    return Get.find<ThemeStore>();
  }
  final store = DriftThemeStore(AppDatabase());
  Get.put<ThemeStore>(store);
  return store;
}

/// Đăng ký [ThemeController] (Get singleton) với store hiện hành.
ThemeController ensureThemeController() {
  if (Get.isRegistered<ThemeController>()) {
    return Get.find<ThemeController>();
  }
  final controller = ThemeController(ensureThemeStore());
  Get.put<ThemeController>(controller);
  return controller;
}
