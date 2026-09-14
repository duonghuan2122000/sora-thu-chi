import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'data/backup_scheduler_workmanager.dart';
import 'data/notification_deps.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Thông báo đẩy (PBI 31, R13): dựng kênh + nạp múi giờ địa phương **trước**
  // `runApp` để lịch đăng ký ngay ở lần hoà giải đầu tiên đã đúng giờ.
  // Lỗi ở đây **không** được chặn khởi động app (FR-024) — bỏ qua.
  try {
    await ensureNotificationPresenter().init();
  } catch (_) {}
  // Tự động sao lưu nền (PBI 35, R7) — đăng ký callback dispatcher trước khi
  // `WorkmanagerBackupScheduler.schedule` có thể được gọi; lỗi nền tảng không
  // hỗ trợ (VD chạy `flutter test`) bỏ qua, không chặn khởi động app.
  try {
    await Workmanager().initialize(backupCallbackDispatcher);
  } catch (_) {}
  runApp(const SoraApp());
}
