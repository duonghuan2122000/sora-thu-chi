import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/app.dart';
import 'package:sora_thu_chi/core/security/biometric_gateway.dart';
import 'package:sora_thu_chi/core/security/pin_store.dart';
import 'package:sora_thu_chi/core/widgets/app_bottom_nav_bar.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/pin/pin_setup_screen.dart';
import 'package:sora_thu_chi/screens/pin/widgets/pin_dots.dart';
import 'package:sora_thu_chi/screens/pin/widgets/pin_keypad.dart';

import 'fakes/biometric_gateway_fake.dart';
import 'fakes/fake_locale_store.dart';
import 'fakes/fake_theme_store.dart';
import 'fakes/fake_wallet_repository.dart';
import 'fakes/pin_store_fake.dart';

/// Pump cả app với store bơm được + chờ boot/route ổn định.
/// Bơm luôn `FakeThemeStore` + `FakeLocaleStore` — `SoraApp.initState` tạo
/// `ThemeController`/`LocaleController` + gọi `load()`; thiếu fake sẽ khởi tạo
/// drift/sqlite native và vỡ test (R8/PBI 19).
Future<void> pumpApp(
  WidgetTester tester,
  PinStore store, {
  BiometricGateway? biometricGateway,
}) async {
  // Tab Báo cáo nạp dữ liệu khi được chọn (PBI 22) ⇒ cần repo giả như
  // `widget_test.pumpShell`; thiếu sẽ khởi tạo drift/sqlite native và treo test.
  Get.reset();
  Get.put<WalletRepository>(FakeWalletRepository());
  addTearDown(Get.reset);
  await tester.pumpWidget(
    SoraApp(
      store: store,
      themeStore: FakeThemeStore(),
      localeStore: FakeLocaleStore(),
      biometricGateway: biometricGateway,
    ),
  );
  await tester.pumpAndSettle();
}

/// Gõ lần lượt từng chữ số trên numpad.
Future<void> enterPin(WidgetTester tester, String pin) async {
  for (final ch in pin.split('')) {
    await tester.tap(find.text(ch));
    await tester.pump();
  }
}

int pinDotsFilled(WidgetTester tester) {
  return tester.widget<PinDots>(find.byType(PinDots)).filledCount;
}

void main() {
  group('US1 — Thiết lập mã PIN lần đầu (P1)', () {
    testWidgets('Boot store rỗng → màn thiết lập, không lộ nội dung', (tester) async {
      await pumpApp(tester, PinStoreFake());

      expect(find.text('Thiết lập mã PIN'), findsOneWidget);
      expect(find.byType(PinSetupScreen), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsNothing);
      expect(find.text('Tổng quan'), findsNothing);
    });

    testWidgets('Chấm đặc theo ký tự, không lộ chữ số thật', (tester) async {
      await pumpApp(tester, PinStoreFake());

      await tester.tap(find.text('1'));
      await tester.pump();
      expect(pinDotsFilled(tester), 1);
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      expect(pinDotsFilled(tester), 3);
      // Chưa hiện số thật vừa gõ.
      expect(find.text('123'), findsNothing);
    });

    testWidgets('Hai lần khớp → vào AppShell, không hỏi lại ngay', (tester) async {
      final store = PinStoreFake();
      await pumpApp(tester, store);

      await enterPin(tester, '1234');
      await tester.pumpAndSettle();
      expect(find.text('Nhập lại mã PIN'), findsOneWidget);
      expect(pinDotsFilled(tester), 0);

      await enterPin(tester, '1234');
      await tester.pumpAndSettle();
      // 1234 là dãy dễ đoán → dialog cảnh báo (giả định spec), Tiếp tục → lưu.
      expect(find.text('Mã PIN này dễ đoán. Vẫn dùng mã PIN này?'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(find.text('Tổng quan'), findsNWidgets(2)); // header + tab
      expect(await store.isPinSet, isTrue);
      // Không hỏi lại PIN ngay trong phiên vừa thiết lập.
      expect(find.byType(PinSetupScreen), findsNothing);
    });

    testWidgets('Hai lần lệch → báo lỗi, nhập lại từ đầu, chưa ghi PIN', (tester) async {
      final store = PinStoreFake();
      await pumpApp(tester, store);

      await enterPin(tester, '1234');
      await tester.pumpAndSettle();
      await enterPin(tester, '5678');
      await tester.pumpAndSettle();

      expect(find.text('Mã PIN không khớp. Vui lòng thử lại.'), findsOneWidget);
      expect(await store.isPinSet, isFalse);
      // Quay lại bước 1, buffer rỗng.
      expect(find.text('Thiết lập mã PIN'), findsOneWidget);
      expect(pinDotsFilled(tester), 0);
    });

    testWidgets('PIN yếu 1111 → dialog, chọn Tiếp tục → lưu được', (tester) async {
      final store = PinStoreFake();
      await pumpApp(tester, store);

      await enterPin(tester, '1111');
      await tester.pumpAndSettle();
      await enterPin(tester, '1111');
      await tester.pumpAndSettle();

      expect(find.text('Mã PIN này dễ đoán. Vẫn dùng mã PIN này?'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(await store.isPinSet, isTrue);
      expect(find.byType(AppBottomNavBar), findsOneWidget);
    });

    testWidgets('Back khi đang thiết lập → không rời được màn', (tester) async {
      final store = PinStoreFake();
      await pumpApp(tester, store);

      await enterPin(tester, '12');
      await tester.pumpAndSettle();
      await Navigator.of(tester.element(find.byType(PinSetupScreen))).maybePop();
      await tester.pumpAndSettle();

      expect(find.byType(PinSetupScreen), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsNothing);
      expect(await store.isPinSet, isFalse);
    });
  });

  group('US2 — Khóa & mở khóa khi vào/quay lại app (P2)', () {
    testWidgets('Boot đã có PIN → màn khóa trước, không lộ nội dung', (tester) async {
      await pumpApp(tester, PinStoreFake.withPin('1234'));

      expect(find.text('Nhập mã PIN'), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsNothing);
      expect(find.text('Tổng quan'), findsNothing);
    });

    testWidgets('Nhập đúng → vào AppShell', (tester) async {
      await pumpApp(tester, PinStoreFake.withPin('1234'));

      await enterPin(tester, '1234');
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(find.text('Tổng quan'), findsNWidgets(2));
    });

    testWidgets('Nhập sai → lỗi chung + xóa ký tự, nhập lại được', (tester) async {
      await pumpApp(tester, PinStoreFake.withPin('1234'));

      await enterPin(tester, '9999');
      await tester.pumpAndSettle();

      expect(find.text('Mã PIN không đúng'), findsOneWidget);
      expect(pinDotsFilled(tester), 0);

      // Nhập đúng ngay sau đó → mở khóa (streak chưa đủ 5 nên không chặn).
      await enterPin(tester, '1234');
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNavBar), findsOneWidget);
    });

    testWidgets('Seed chặn (streak>=5 + lockUntil tương lai) → keypad tắt, không bấm được',
        (tester) async {
      final store = PinStoreFake.withPin(
        '1234',
        lockState: PinLockState(
          streak: 5,
          lockUntil: DateTime.now().add(const Duration(minutes: 1)),
        ),
      );
      await pumpApp(tester, store);

      expect(find.textContaining('Thử lại sau'), findsOneWidget);
      final keypad = tester.widget<PinKeypad>(find.byType(PinKeypad));
      expect(keypad.enabled, isFalse);

      await tester.tap(find.text('1'), warnIfMissed: false);
      await tester.pump();
      expect(pinDotsFilled(tester), 0);
    });

    testWidgets('Resume giữa phiên đang ở nội dung → khóa phủ lên, mở đúng màn cũ',
        (tester) async {
      await pumpApp(tester, PinStoreFake.withPin('1234'));

      // Mở khóa, sang tab Báo cáo rồi mới đưa app xuống nền.
      await enterPin(tester, '1234');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Báo cáo'));
      await tester.pumpAndSettle();
      expect(find.text('Báo cáo'), findsNWidgets(2));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Màn khóa phủ lên đỉnh stack.
      expect(find.text('Nhập mã PIN'), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsNothing);

      // Mở khóa → về đúng tab Báo cáo đang đứng trước khi khóa.
      await enterPin(tester, '1234');
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(find.text('Báo cáo'), findsNWidgets(2));
    });
  });

  group('US2b — Mời sinh trắc học tự động + fallback PIN (PBI 34)', () {
    Future<PinStoreFake> storeWithBiometricEnabled() async {
      final store = PinStoreFake.withPin('1234');
      await store.saveBiometricState(
        const BiometricState(enabled: true, enrolledTypes: ['fingerprint']),
      );
      return store;
    }

    testWidgets(
        'Công tắc bật + khả dụng → màn khóa khởi tạo mời sinh trắc học trước PIN',
        (tester) async {
      final gateway = BiometricGatewayFake()..pendingAuthenticate = Completer();
      await pumpApp(
        tester,
        await storeWithBiometricEnabled(),
        biometricGateway: gateway,
      );

      expect(find.text('Chạm để xác thực'), findsOneWidget);
      expect(find.text('Nhập mã PIN'), findsNothing);
      expect(find.byType(AppBottomNavBar), findsNothing);
    });

    testWidgets('Xác thực thành công → vào thẳng AppShell (FR-006)',
        (tester) async {
      await pumpApp(
        tester,
        await storeWithBiometricEnabled(),
        biometricGateway: BiometricGatewayFake(),
      );

      expect(find.byType(AppBottomNavBar), findsOneWidget);
    });

    testWidgets(
        'Xác thực thất bại → tự chuyển bàn phím PIN, PIN vẫn mở khóa được (FR-005)',
        (tester) async {
      final gateway = BiometricGatewayFake()..authenticateResult = false;
      await pumpApp(
        tester,
        await storeWithBiometricEnabled(),
        biometricGateway: gateway,
      );

      expect(find.text('Nhập mã PIN'), findsOneWidget);
      await enterPin(tester, '1234');
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNavBar), findsOneWidget);
    });

    testWidgets('Bấm "Dùng mã PIN thay thế" → chuyển ngay bàn phím PIN',
        (tester) async {
      final gateway = BiometricGatewayFake()..pendingAuthenticate = Completer();
      await pumpApp(
        tester,
        await storeWithBiometricEnabled(),
        biometricGateway: gateway,
      );

      await tester.tap(find.text('Dùng mã PIN thay thế'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập mã PIN'), findsOneWidget);
    });

    testWidgets('Bấm "Hủy" → vẫn ở màn biometric, chỉ huỷ lượt xác thực (R6)',
        (tester) async {
      final gateway = BiometricGatewayFake()..pendingAuthenticate = Completer();
      await pumpApp(
        tester,
        await storeWithBiometricEnabled(),
        biometricGateway: gateway,
      );

      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Chạm để xác thực'), findsOneWidget);
      expect(gateway.stopAuthenticationCallCount, 1);
    });

    testWidgets('Công tắc tắt → khởi tạo thẳng bàn phím PIN, không gọi gateway',
        (tester) async {
      final gateway = BiometricGatewayFake();
      await pumpApp(
        tester,
        PinStoreFake.withPin('1234'),
        biometricGateway: gateway,
      );

      expect(find.text('Nhập mã PIN'), findsOneWidget);
      expect(gateway.authenticateCallCount, 0);
    });

    testWidgets(
        'Quyền/đăng ký đã đổi (canOfferBiometric=false) → khởi tạo thẳng PIN, không gọi authenticate',
        (tester) async {
      final gateway = BiometricGatewayFake()..canUseResult = false;
      await pumpApp(
        tester,
        await storeWithBiometricEnabled(),
        biometricGateway: gateway,
      );

      expect(find.text('Nhập mã PIN'), findsOneWidget);
      expect(gateway.authenticateCallCount, 0);
    });
  });
}
