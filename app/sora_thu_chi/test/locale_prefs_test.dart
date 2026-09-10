import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/locale/locale_prefs.dart';

void main() {
  group('localeToStorage', () {
    test('map 2 ngôn ngữ hợp lệ sang chuỗi viết thường', () {
      expect(localeToStorage(const Locale('vi')), 'vi');
      expect(localeToStorage(const Locale('en')), 'en');
    });
  });

  group('localeFromStorage', () {
    test('đọc đúng 2 giá trị hợp lệ', () {
      expect(localeFromStorage('vi'), const Locale('vi'));
      expect(localeFromStorage('en'), const Locale('en'));
    });

    test('null / rỗng / giá trị lạ → mặc định vi (không ném)', () {
      for (final raw in [null, '', 'fr', 'VI', 'EN ', 'vietnamese']) {
        expect(localeFromStorage(raw), kFallbackLocale, reason: 'raw=$raw');
      }
    });

    test('round-trip giữ nguyên giá trị', () {
      for (final option in kLanguageOptions) {
        expect(localeFromStorage(localeToStorage(option.locale)), option.locale);
      }
    });
  });

  group('kLanguageOptions — hằng số màn 03', () {
    test('đúng 2 phần tử, thứ tự Tiếng Việt → English', () {
      expect(kLanguageOptions.length, 2);
      expect(kLanguageOptions[0].locale, const Locale('vi'));
      expect(kLanguageOptions[1].locale, const Locale('en'));
    });

    test('mã, tên và dòng phụ đúng mockup 03', () {
      expect(kLanguageOptions[0].code, 'VI');
      expect(kLanguageOptions[0].endonym, 'Tiếng Việt');
      expect(kLanguageOptions[0].otherName, 'Vietnamese');

      expect(kLanguageOptions[1].code, 'EN');
      expect(kLanguageOptions[1].endonym, 'English');
      expect(kLanguageOptions[1].otherName, 'Tiếng Anh');
    });

    test('localeEndonym trả tên ngôn ngữ hiện hành', () {
      expect(localeEndonym(const Locale('vi')), 'Tiếng Việt');
      expect(localeEndonym(const Locale('en')), 'English');
    });
  });
}
