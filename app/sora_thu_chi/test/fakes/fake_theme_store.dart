import 'package:flutter/material.dart';

import 'package:sora_thu_chi/core/theme/theme_store.dart';

/// Bản bộ nhớ của [ThemeStore] — dùng cho mọi widget/controller test (không
/// cần sqlite native). `null` = chưa từng đổi (mặc định `system`).
class FakeThemeStore implements ThemeStore {
  FakeThemeStore({ThemeMode? initialMode}) : _mode = initialMode;

  ThemeMode? _mode;

  /// Lựa chọn đã ghi (chỉ đọc) — test assert sau khi chạm màn 02.
  ThemeMode? get storedMode => _mode;

  @override
  Future<ThemeMode?> load() async => _mode;

  @override
  Future<void> save(ThemeMode mode) async {
    _mode = mode;
  }
}
