import 'package:get/get.dart';

import '../core/utilities/utilities_store.dart';
import 'db/app_database.dart';
import 'utilities_store_drift.dart';

/// Đăng ký [UtilitiesStore] bền vững (Get singleton): tạo đúng **1**
/// `DriftUtilitiesStore(AppDatabase())` cho cả app — tránh 2 connection drift
/// trên cùng file sqlite (bám `ensureWalletRepository`). Test đăng ký fake
/// (Get.put) trước → hàm trả về fake đó, không tạo drift (research R7).
UtilitiesStore ensureUtilitiesStore() {
  if (Get.isRegistered<UtilitiesStore>()) {
    return Get.find<UtilitiesStore>();
  }
  final store = DriftUtilitiesStore(AppDatabase());
  Get.put<UtilitiesStore>(store);
  return store;
}
