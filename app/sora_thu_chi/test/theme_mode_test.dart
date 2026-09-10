import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/theme/theme_mode.dart';

void main() {
  test('kKeyThemeMode theo convention PBI 17', () {
    expect(kKeyThemeMode, 'themeMode');
  });

  test('themeModeToStorage khớp tên enum, viết thường', () {
    expect(themeModeToStorage(ThemeMode.light), 'light');
    expect(themeModeToStorage(ThemeMode.dark), 'dark');
    expect(themeModeToStorage(ThemeMode.system), 'system');
  });

  test('themeModeFromStorage: null/rỗng/giá trị lạ → system (không ném)', () {
    expect(themeModeFromStorage(null), ThemeMode.system);
    expect(themeModeFromStorage(''), ThemeMode.system);
    expect(themeModeFromStorage('LIGHT'), ThemeMode.system);
    expect(themeModeFromStorage('auto'), ThemeMode.system);
    expect(themeModeFromStorage('light'), ThemeMode.light);
    expect(themeModeFromStorage('dark'), ThemeMode.dark);
    expect(themeModeFromStorage('system'), ThemeMode.system);
  });

  test('round-trip ThemeMode → chuỗi → ThemeMode', () {
    for (final mode in ThemeMode.values) {
      expect(themeModeFromStorage(themeModeToStorage(mode)), mode);
    }
  });

  test('themeModeLabel: tên đầy đủ thống nhất (R10)', () {
    expect(themeModeLabel(ThemeMode.light), 'Sáng');
    expect(themeModeLabel(ThemeMode.dark), 'Tối');
    expect(themeModeLabel(ThemeMode.system), 'Theo hệ thống');
  });
}
