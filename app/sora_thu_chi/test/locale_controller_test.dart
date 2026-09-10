import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/locale/locale_controller.dart';
import 'package:sora_thu_chi/core/locale/locale_prefs.dart';

import 'fakes/fake_locale_store.dart';

/// `Get.locale` là biến toàn cục của GetX — rò rỉ sang test sau trong cùng file
/// nếu không khôi phục.
void _resetGet() {
  Get.reset();
  Get.locale = null;
}

void main() {
  tearDown(_resetGet);

  test('mặc định vi khi chưa từng đổi', () {
    final ctl = LocaleController(FakeLocaleStore());
    expect(ctl.locale.value, kFallbackLocale);
  });

  test('load() đọc lựa chọn đã lưu và áp vào Get.locale', () async {
    final ctl = LocaleController(FakeLocaleStore(initialLocale: const Locale('en')));
    await ctl.load();

    expect(ctl.locale.value, const Locale('en'));
    expect(Get.locale?.languageCode, 'en');
  });

  test('load() khi chưa có row → giữ mặc định vi', () async {
    final ctl = LocaleController(FakeLocaleStore());
    await ctl.load();

    expect(ctl.locale.value, kFallbackLocale);
  });

  // LƯU Ý: KHÔNG `await` kết quả `Get.updateLocale` — trong flutter_test nó
  // không bao giờ hoàn tất (fake async) và làm test treo.
  test('setLocale đổi Rx + Get.locale + ghi xuống store', () async {
    final store = FakeLocaleStore();
    final ctl = LocaleController(store);

    ctl.setLocale(const Locale('en'));

    expect(ctl.locale.value, const Locale('en'));
    expect(Get.locale?.languageCode, 'en');
    // Ghi nối đuôi — chờ microtask/queue hoàn tất.
    await Future<void>.delayed(Duration.zero);
    expect(store.storedLocale, const Locale('en'));
  });

  test('setLocale cùng giá trị → no-op, không ghi thêm', () async {
    final store = FakeLocaleStore();
    final ctl = LocaleController(store);

    ctl.setLocale(kFallbackLocale);
    await Future<void>.delayed(Duration.zero);

    expect(ctl.locale.value, kFallbackLocale);
    expect(store.storedLocale, isNull);
  });

  test('chạm nhanh liên tiếp en → vi → en: lần cuối thắng', () async {
    final store = FakeLocaleStore();
    final ctl = LocaleController(store);

    ctl.setLocale(const Locale('en'));
    ctl.setLocale(const Locale('vi'));
    ctl.setLocale(const Locale('en'));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(ctl.locale.value, const Locale('en'));
    expect(store.storedLocale, const Locale('en'));
  });
}
