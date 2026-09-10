import 'package:flutter/material.dart';

/// Khóa row "Giao diện" trong bảng `AppSettings`.
const String kKeyThemeMode = 'themeMode';

/// Lựa chọn giao diện → chuỗi lưu trong bảng (viết thường, khớp tên enum).
String themeModeToStorage(ThemeMode mode) => switch (mode) {
  ThemeMode.light => 'light',
  ThemeMode.dark => 'dark',
  ThemeMode.system => 'system',
};

/// Chuỗi đọc từ bảng → [ThemeMode]. Thiếu row hoặc ngoài 3 chuỗi hợp lệ →
/// [ThemeMode.system] (an toàn, không ném — bám `UtilitiesPrefs.fromSettings`).
ThemeMode themeModeFromStorage(String? raw) => switch (raw) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};

/// Nhãn hiển thị thống nhất (màn 01 trailing + màn 02 card).
String themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.light => 'Sáng',
  ThemeMode.dark => 'Tối',
  ThemeMode.system => 'Theo hệ thống',
};
