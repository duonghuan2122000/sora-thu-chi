import 'package:flutter/material.dart';

/// Khóa row "Ngôn ngữ" trong bảng `AppSettings` (bảng key-value v5, không
/// migration — chỉ thêm row lúc runtime).
const String kKeyLocale = 'locale';

/// Ngôn ngữ mặc định khi chưa từng đổi (FR-004).
const Locale kFallbackLocale = Locale('vi');

/// Lựa chọn ngôn ngữ → chuỗi lưu trong bảng (viết thường, khớp
/// `Locale.languageCode`).
String localeToStorage(Locale locale) => locale.languageCode;

/// Chuỗi đọc từ bảng → [Locale]. Thiếu row hoặc giá trị ngoài `'vi'`/`'en'` →
/// [kFallbackLocale] (an toàn, không ném — bám `themeModeFromStorage`).
Locale localeFromStorage(String? raw) => switch (raw) {
  'en' => const Locale('en'),
  _ => kFallbackLocale,
};

/// Một hàng của màn `03` — 4 chuỗi **cố định** theo mockup
/// `docs/tool/03-ngon-ngu.svg` (R8): tên ngôn ngữ luôn ghi bằng chính ngôn ngữ
/// đó, dòng phụ là tên ngôn ngữ kia. KHÔNG đi qua `.tr`.
class LanguageOption {
  const LanguageOption({
    required this.locale,
    required this.code,
    required this.endonym,
    required this.otherName,
  });

  final Locale locale;

  /// Mã hiển thị trong vòng tròn (`VI`/`EN`).
  final String code;

  /// Tên ngôn ngữ bằng chính nó (`Tiếng Việt`/`English`).
  final String endonym;

  /// Dòng phụ — tên ngôn ngữ còn lại (`Vietnamese`/`Tiếng Anh`).
  final String otherName;
}

/// Hai lựa chọn màn `03`, đúng thứ tự Tiếng Việt → English (FR-002).
const List<LanguageOption> kLanguageOptions = [
  LanguageOption(
    locale: Locale('vi'),
    code: 'VI',
    endonym: 'Tiếng Việt',
    otherName: 'Vietnamese',
  ),
  LanguageOption(
    locale: Locale('en'),
    code: 'EN',
    endonym: 'English',
    otherName: 'Tiếng Anh',
  ),
];

/// Tên ngôn ngữ hiển thị ở phần cuối hàng "Ngôn ngữ" màn `01`.
String localeEndonym(Locale locale) => kLanguageOptions
    .firstWhere((o) => o.locale.languageCode == locale.languageCode,
        orElse: () => kLanguageOptions.first)
    .endonym;
