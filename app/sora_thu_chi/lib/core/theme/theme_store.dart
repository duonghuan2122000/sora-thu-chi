import 'package:flutter/material.dart';

/// Seam đọc/ghi lựa chọn giao diện — controller chỉ phụ thuộc interface này để
/// test bơm fake (không cần sqlite native). Impl thật: `DriftThemeStore` (1 row
/// `themeMode` trong bảng `AppSettings`).
abstract class ThemeStore {
  /// Đọc lựa chọn đã lưu; row vắng/key lạ → `null` (chưa từng đổi — tầng
  /// controller quyết định mặc định `system`).
  Future<ThemeMode?> load();

  /// Ghi write-through khi người dùng chọn (upsert 1 key, không xoá row khác).
  Future<void> save(ThemeMode mode);
}
