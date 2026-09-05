import 'package:get/get.dart';

import '../core/transaction/transaction_controller.dart';
import 'wallet_deps.dart';

/// Đăng ký [TransactionController] bền vững — bám [ensureWalletController]:
/// màn Giao dịch gọi khi build; đã có (màn khác/test bơm fake) thì dùng lại.
/// Controller dùng chung 1 [WalletRepository] drift singleton (research R7).
/// Không nạp DB ở đây — nạp do AppShell khi chọn tab Giao dịch (R6/FR-011).
TransactionController ensureTransactionController() {
  if (Get.isRegistered<TransactionController>()) {
    return Get.find<TransactionController>();
  }
  final controller = TransactionController(ensureWalletRepository());
  Get.put(controller);
  return controller;
}
