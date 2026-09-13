import 'package:flutter/material.dart';

import 'app.dart';
import 'data/notification_deps.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Thông báo đẩy (PBI 31, R13): dựng kênh + nạp múi giờ địa phương **trước**
  // `runApp` để lịch đăng ký ngay ở lần hoà giải đầu tiên đã đúng giờ.
  // Lỗi ở đây **không** được chặn khởi động app (FR-024) — bỏ qua.
  try {
    await ensureNotificationPresenter().init();
  } catch (_) {}
  runApp(const SoraApp());
}
