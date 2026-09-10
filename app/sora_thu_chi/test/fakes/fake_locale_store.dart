import 'package:flutter/material.dart';

import 'package:sora_thu_chi/core/locale/locale_store.dart';

/// Bản bộ nhớ của [LocaleStore] — dùng cho mọi widget/controller test (không
/// cần sqlite native). `null` = chưa từng đổi (mặc định `vi`).
class FakeLocaleStore implements LocaleStore {
  FakeLocaleStore({Locale? initialLocale}) : _locale = initialLocale;

  Locale? _locale;

  /// Lựa chọn đã ghi (chỉ đọc) — test assert sau khi chạm màn 03.
  Locale? get storedLocale => _locale;

  @override
  Future<Locale?> load() async => _locale;

  @override
  Future<void> save(Locale locale) async {
    _locale = locale;
  }
}
