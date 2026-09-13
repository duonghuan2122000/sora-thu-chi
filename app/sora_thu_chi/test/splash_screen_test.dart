import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/app.dart';
import 'package:sora_thu_chi/core/boot_gate.dart';
import 'package:sora_thu_chi/core/security/pin_store.dart';
import 'package:sora_thu_chi/core/widgets/app_bottom_nav_bar.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/pin/pin_setup_screen.dart';
import 'package:sora_thu_chi/theme/app_colors.dart';

import 'fakes/fake_locale_store.dart';
import 'fakes/fake_theme_store.dart';
import 'fakes/fake_wallet_repository.dart';
import 'fakes/pin_store_fake.dart';

/// Logo splash — dùng để khẳng định splash còn/đã biến mất.
final splashLogo = find.image(const AssetImage('assets/brand/coin_flow_logo.png'));

/// Store PIN không bao giờ trả lời → mô phỏng máy yếu / store treo.
class _HangingStore implements PinStore {
  @override
  Future<bool> get isPinSet => Completer<bool>().future;

  @override
  Future<void> savePin(String pin) async {}

  @override
  Future<bool> verifyPin(String pin) async => false;

  @override
  Future<PinLockState> readLockState() async => const PinLockState();

  @override
  Future<void> saveLockState(PinLockState state) async {}

  @override
  Future<BiometricState> readBiometricState() async => const BiometricState();

  @override
  Future<void> saveBiometricState(BiometricState state) async {}
}

Future<void> pumpApp(
  WidgetTester tester,
  PinStore store, {
  ThemeMode? themeMode,
  bool settle = true,
}) async {
  Get.reset();
  Get.put<WalletRepository>(FakeWalletRepository());
  addTearDown(Get.reset);
  await tester.pumpWidget(
    SoraApp(
      store: store,
      themeStore: FakeThemeStore(initialMode: themeMode),
      localeStore: FakeLocaleStore(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Nền + chữ của splash ở frame đang dựng.
({Color? background, Color? text}) splashSkin(WidgetTester tester) => (
      background: tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
      text: tester.widget<Text>(find.text('Sora Thu Chi')).style?.color,
    );

void main() {
  group('Splash — nội dung & hình thức (FR-004/007/008/016)', () {
    testWidgets('là màn đầu tiên khi cold start, có logo + tên app trên nền teal',
        (tester) async {
      await pumpApp(tester, PinStoreFake(), settle: false);

      expect(find.byType(PinGate), findsOneWidget);
      expect(splashLogo, findsOneWidget);
      expect(find.text('Sora Thu Chi'), findsOneWidget);

      final skin = splashSkin(tester);
      expect(skin.background, AppColors.teal);
      expect(skin.text, AppColors.white);
    });

    testWidgets('không có app bar, bottom nav, nút bấm hay chỉ báo tải (FR-007)',
        (tester) async {
      await pumpApp(tester, PinStoreFake(), settle: false);

      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(AppBottomNavBar), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      for (final t in [ElevatedButton, TextButton, IconButton, OutlinedButton]) {
        expect(find.byWidgetPredicate((w) => w.runtimeType == t), findsNothing);
      }
    });

    testWidgets('giống hệt nhau ở giao diện Sáng và Tối (FR-004/008/SC-006)',
        (tester) async {
      await pumpApp(tester, PinStoreFake(), themeMode: ThemeMode.light, settle: false);
      final light = splashSkin(tester);

      // Gỡ hẳn cây cũ — pump cùng loại widget sẽ *cập nhật* chứ không dựng lại
      // `SoraApp`, mà `Get.reset()` đã xoá đăng ký controller.
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpApp(tester, PinStoreFake(), themeMode: ThemeMode.dark, settle: false);
      final dark = splashSkin(tester);

      expect(dark.background, light.background);
      expect(dark.text, light.text);
      expect(splashLogo, findsOneWidget);
    });

    testWidgets('tên app không tràn khi cỡ chữ hệ thống ở mức lớn nhất', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpApp(tester, PinStoreFake(), settle: false);

      expect(splashLogo, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Splash — kết thúc & điều hướng (FR-006/012/013)', () {
    testWidgets('tự biến mất khi app sẵn sàng, không cần chạm — có PIN → màn khóa',
        (tester) async {
      await pumpApp(tester, PinStoreFake.withPin('1234'));

      expect(splashLogo, findsNothing);
      expect(find.text('Nhập mã PIN'), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsNothing);
    });

    testWidgets('không có PIN → màn thiết lập PIN (khóa app bắt buộc lần đầu)',
        (tester) async {
      await pumpApp(tester, PinStoreFake());

      expect(splashLogo, findsNothing);
      expect(find.byType(PinSetupScreen), findsOneWidget);
    });

    testWidgets('store không bao giờ trả lời → splash vẫn kết thúc trong 5 giây',
        (tester) async {
      await pumpApp(tester, _HangingStore(), settle: false);
      expect(splashLogo, findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      expect(splashLogo, findsOneWidget, reason: 'chưa quá trần 5 giây');

      await tester.pump(const Duration(seconds: 1, milliseconds: 100));
      await tester.pumpAndSettle();
      expect(splashLogo, findsNothing);
      expect(find.byType(PinSetupScreen), findsOneWidget);
    });
  });

  group('Splash — không hiện lại (FR-005/SC-005)', () {
    testWidgets('vào app rồi quay lại từ nền → không thấy splash', (tester) async {
      await pumpApp(tester, PinStoreFake.withPin('1234'));

      // Mở khóa để vào nội dung.
      for (final ch in '1234'.split('')) {
        await tester.tap(find.text(ch));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNavBar), findsOneWidget);
      // `PinGate` bị gỡ khỏi stack ⇒ không thể dựng lại splash.
      expect(find.byType(PinGate), findsNothing);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(splashLogo, findsNothing);
      expect(find.text('Nhập mã PIN'), findsOneWidget); // khóa lại, không phải splash
    });
  });
}
