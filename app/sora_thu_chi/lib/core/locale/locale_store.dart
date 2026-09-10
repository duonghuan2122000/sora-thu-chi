import 'package:flutter/material.dart';

/// Seam đọc/ghi lựa chọn ngôn ngữ — controller chỉ phụ thuộc interface này để
/// test bơm fake (không cần sqlite native). Impl thật: `DriftLocaleStore` (1 row
/// `locale` trong bảng `AppSettings`, schema v5 — chỉ thêm row, không migration).
abstract class LocaleStore {
  /// Đọc lựa chọn đã lưu; row vắng/giá trị lạ → `null` (chưa từng đổi — tầng
  /// controller quyết định mặc định `vi`, FR-004).
  Future<Locale?> load();

  /// Ghi write-through khi người dùng chọn (upsert 1 key `locale`, không xoá
  /// row cài đặt khác — FR-012).
  Future<void> save(Locale locale);
}
