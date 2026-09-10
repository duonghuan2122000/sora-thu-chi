import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/security/pin_controller.dart';
import 'package:sora_thu_chi/core/theme/theme_controller.dart';
import 'package:sora_thu_chi/core/wallet/wallet_controller.dart';
import 'package:sora_thu_chi/screens/pin/pin_lock_screen.dart';
import 'package:sora_thu_chi/screens/theme_screen.dart';
import 'package:sora_thu_chi/screens/utilities_screen.dart';
import 'package:sora_thu_chi/screens/wallet_list_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';
import 'package:sora_thu_chi/theme/sora_colors.dart';

import 'fakes/fake_theme_store.dart';
import 'fakes/fake_utilities_store.dart';
import 'fakes/fake_wallet_repository.dart';
import 'fakes/pin_store_fake.dart';

/// Smoke **theme tối** (R5/SC-007): các nhóm màn đại diện pump ở giao diện tối
/// — không overflow, không ném lỗi, token dark thật sự được áp (không phải nền
/// trắng). Đây là smoke đại diện, KHÔNG phủ mọi nhánh logic — case dark chi tiết
/// nằm ở test của từng module khi cần.
Widget darkApp(Widget home) => MaterialApp(
  theme: AppTheme.themeData,
  darkTheme: AppTheme.darkThemeData,
  themeMode: ThemeMode.dark,
  home: home,
);

void registerTheme() {
  Get.reset();
  Get.put<ThemeController>(ThemeController(FakeThemeStore()));
  addTearDown(Get.reset);
}

void main() {
  testWidgets('Màn con "Giao diện": card đọc token tối, không overflow', (tester) async {
    registerTheme();
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(darkApp(const ThemeScreen()));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(ThemeScreen));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(SoraColors.of(context).background, SoraColors.dark.background);

    // Card "Tối" (chưa chọn) tô nền surface tối — không còn trắng.
    final box = tester
        .widget<Container>(
          find
              .descendant(
                of: find.byKey(const ValueKey('theme-option-dark')),
                matching: find.byType(Container),
              )
              .first,
        )
        .decoration as BoxDecoration;
    expect(box.color, SoraColors.dark.surface);

    for (final label in ['Sáng', 'Tối', 'Theo hệ thống']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Màn "Tiện ích & Cá nhân hóa": hàng + trailing đọc được ở tối', (tester) async {
    registerTheme();
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      darkApp(UtilitiesScreen(store: FakeUtilitiesStore())),
    );
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byType(UtilitiesScreen))).brightness,
      Brightness.dark,
    );
    expect(find.text('Giao diện'), findsOneWidget);
    expect(find.text('Theo hệ thống'), findsOneWidget);
    expect(find.text('Quản lý Tag'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Màn khóa PIN: nền tối, chữ + keypad đọc được', (tester) async {
    Get.reset();
    final controller = Get.put<PinController>(
      PinController(store: PinStoreFake.withPin('1234'), now: DateTime.now),
      permanent: true,
    );
    await controller.init();
    addTearDown(Get.reset);

    await tester.pumpWidget(darkApp(PinLockScreen(onUnlocked: () {})));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(PinLockScreen));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(find.text('Nhập mã PIN'), findsOneWidget);
    expect(find.text('Mở khóa Sora Thu Chi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Màn danh sách ví ở tối: cuộn hết danh sách, không overflow', (tester) async {
    Get.reset();
    final controller = WalletController(FakeWalletRepository());
    Get.put(controller);
    await controller.init();
    addTearDown(Get.reset);

    tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.binding.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(darkApp(const WalletListScreen()));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byType(WalletListScreen))).brightness,
      Brightness.dark,
    );
    // Cuộn hết danh sách — mọi hàng dựng ra ở tối đều phải vừa khung.
    for (var i = 0; i < 5; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
