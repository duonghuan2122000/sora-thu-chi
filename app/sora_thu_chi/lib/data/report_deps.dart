import 'package:get/get.dart';

import '../core/report/report_controller.dart';
import 'wallet_deps.dart';

/// Đăng ký [ReportController] bền vững — bám [ensureTransactionController]:
/// màn Báo cáo gọi khi build; đã có (màn khác/test bơm fake) thì dùng lại.
///
/// Controller được tạo **ngay lúc boot** (màn Báo cáo nằm trong `IndexedStack`),
/// nên nơi dựng shell/test phải đăng ký `WalletRepository` trước; việc nạp dữ
/// liệu thì `AppShell` gọi khi chọn tab Báo cáo (không nạp trong `initState`).
ReportController ensureReportController() {
  if (Get.isRegistered<ReportController>()) {
    return Get.find<ReportController>();
  }
  final controller = ReportController(ensureWalletRepository());
  Get.put(controller);
  return controller;
}
