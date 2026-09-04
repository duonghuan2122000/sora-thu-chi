import 'package:get/get.dart';

import '../core/wallet/wallet_controller.dart';
import 'db/app_database.dart';
import 'wallet_repository_drift.dart';

/// Đăng ký [WalletController] bền vững: màn hình gọi [ensureWalletController()]
/// khi vào — nếu đã có controller (do màn khác tạo, hoặc test bơm fake) thì dùng
/// lại, không khởi tạo drift nhiều lần. Không đụng luồng PIN (research Q13).
WalletController ensureWalletController() {
  if (Get.isRegistered<WalletController>()) {
    return Get.find<WalletController>();
  }
  final controller = WalletController(
    DriftWalletRepository(AppDatabase()),
  );
  Get.put(controller);
  controller.init(); // nạp nền — màn đọc trạng thái isLoading để hiện spinner.
  return controller;
}
