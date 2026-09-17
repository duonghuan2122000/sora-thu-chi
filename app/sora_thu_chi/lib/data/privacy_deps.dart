import 'package:get/get.dart';

import '../core/privacy/privacy_controller.dart';
import 'utilities_deps.dart';

/// Đăng ký [PrivacyController] bền vững (Get singleton) — dùng chung
/// [ensureUtilitiesStore] để cùng 1 kết nối drift cho bảng `AppSettings`.
/// Test đăng ký fake (Get.put) trước → hàm trả về fake đó (bám
/// `ensureUtilitiesStore`).
PrivacyController ensurePrivacyController() {
  if (Get.isRegistered<PrivacyController>()) {
    return Get.find<PrivacyController>();
  }
  final controller = PrivacyController(ensureUtilitiesStore());
  Get.put<PrivacyController>(controller);
  return controller;
}
