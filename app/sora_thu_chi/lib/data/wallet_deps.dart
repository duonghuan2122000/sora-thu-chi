import 'package:get/get.dart';

import '../core/wallet/wallet_controller.dart';
import 'db/app_database.dart';
import 'wallet_repository.dart';
import 'wallet_repository_drift.dart';

/// Đăng ký [WalletRepository] bền vững (Get singleton): tạo đúng **1**
/// `DriftWalletRepository(AppDatabase())` cho cả app — [WalletController] và
/// [TransactionController] dùng chung cùng DB/repo, tránh 2 connection drift
/// trên cùng file sqlite (research R7). Test đăng ký repo fake (Get.put) trước
/// → hàm trả về fake đó, không tạo drift (ưu tiên fake như PBI 7/8).
WalletRepository ensureWalletRepository() {
  if (Get.isRegistered<WalletRepository>()) {
    return Get.find<WalletRepository>();
  }
  final repository = DriftWalletRepository(AppDatabase());
  Get.put<WalletRepository>(repository);
  return repository;
}

/// Đăng ký [WalletController] bền vững: màn hình gọi [ensureWalletController()]
/// khi vào — nếu đã có controller (do màn khác tạo, hoặc test bơm fake) thì dùng
/// lại, không khởi tạo drift nhiều lần. Không đụng luồng PIN (research Q13).
WalletController ensureWalletController() {
  if (Get.isRegistered<WalletController>()) {
    return Get.find<WalletController>();
  }
  final controller = WalletController(ensureWalletRepository());
  Get.put(controller);
  controller.init(); // nạp nền — màn đọc trạng thái isLoading để hiện spinner.
  return controller;
}
