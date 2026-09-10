import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'theme_store.dart';

/// Nguồn chân lý giao diện trong phiên (bám `PinController`): `Rx<ThemeMode>`
/// cho `MaterialApp.themeMode`, radio màn 02 và giá trị hàng "Giao diện" màn 01.
/// Mặc định `system` trước khi [load] xong (R3 — chấp nhận nháy khung boot).
class ThemeController extends GetxController {
  ThemeController(this._store);

  final ThemeStore _store;

  final Rx<ThemeMode> mode = ThemeMode.system.obs;

  /// Nối đuôi các lần ghi — chọn nhanh liên tiếp thì lần chạm cuối là trạng
  /// thái cuối (save cũ không đè save mới).
  Future<void> _saveTail = Future<void>.value();

  Future<void> load() async {
    final stored = await _store.load();
    if (stored != null) mode.value = stored;
  }

  void setMode(ThemeMode m) {
    if (m == mode.value) return;
    mode.value = m;
    _saveTail = _saveTail.then((_) async {
      try {
        await _store.save(m);
      } catch (_) {
        // Ghi lỗi bỏ qua — lần chạm sau ghi lại trạng thái mới nhất.
      }
    });
  }
}
