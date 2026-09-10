import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/theme/theme_controller.dart';

import 'fakes/fake_theme_store.dart';

void main() {
  test('mặc định system khi store chưa từng lưu', () async {
    final controller = ThemeController(FakeThemeStore());
    await controller.load();
    expect(controller.mode.value, ThemeMode.system);
  });

  test('load đọc lựa chọn đã lưu từ store', () async {
    final controller = ThemeController(FakeThemeStore(initialMode: ThemeMode.light));
    await controller.load();
    expect(controller.mode.value, ThemeMode.light);
  });

  test('setMode đổi Rx và ghi store', () async {
    final fake = FakeThemeStore();
    final controller = ThemeController(fake);

    controller.setMode(ThemeMode.dark);
    expect(controller.mode.value, ThemeMode.dark);
    await pumpEventQueue();
    expect(fake.storedMode, ThemeMode.dark);
  });

  test('setMode cùng giá trị hiện hành → không ghi thừa store', () async {
    final fake = FakeThemeStore();
    final controller = ThemeController(fake);

    controller.setMode(ThemeMode.system); // đang là system
    await pumpEventQueue();
    expect(fake.storedMode, isNull, reason: 'không ghi khi giá trị không đổi');
  });

  test('chọn nhanh liên tiếp → trạng thái cuối là lần chạm cuối', () async {
    final fake = FakeThemeStore();
    final controller = ThemeController(fake);

    controller.setMode(ThemeMode.dark);
    controller.setMode(ThemeMode.light);
    controller.setMode(ThemeMode.dark);
    await pumpEventQueue();

    expect(controller.mode.value, ThemeMode.dark);
    expect(fake.storedMode, ThemeMode.dark);
  });
}
