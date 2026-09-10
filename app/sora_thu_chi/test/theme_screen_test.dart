import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/theme/theme_controller.dart';
import 'package:sora_thu_chi/screens/theme_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_theme_store.dart';

/// Pump màn 02 trong một app mini **giống `SoraApp`**: MaterialApp đọc
/// `themeMode` từ controller qua Obx → đổi Rx là theme đổi ngay (FR-005).
/// Màn được **đẩy qua route** (không làm `home`) để có nút back như màn con thật.
Future<FakeThemeStore> pumpThemeScreen(
  WidgetTester tester, {
  ThemeMode? initialMode,
  bool loadTheme = true,
}) async {
  Get.reset();
  final fake = FakeThemeStore(initialMode: initialMode);
  final controller = Get.put<ThemeController>(ThemeController(fake));
  addTearDown(Get.reset);
  if (loadTheme) await controller.load();

  await tester.binding.setSurfaceSize(const Size(390, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    Obx(
      () => MaterialApp(
        theme: AppTheme.themeData,
        darkTheme: AppTheme.darkThemeData,
        themeMode: controller.mode.value,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ThemeScreen(controller: controller),
                  ),
                ),
                child: const Text('mở'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('mở'));
  await tester.pumpAndSettle();
  return fake;
}

/// Hàng ứng với [storageKey] đang được chọn hay không — dấu tích nằm trong card.
bool isSelected(WidgetTester tester, String storageKey) {
  final check = find.byIcon(Icons.check);
  if (check.evaluate().isEmpty) return false;
  final rect = tester.getRect(find.byKey(ValueKey('theme-option-$storageKey')));
  return rect.contains(tester.getCenter(check));
}

void main() {
  testWidgets('Bố cục mockup 02: app bar + back, không bottom nav, 3 lựa chọn đúng thứ tự',
      (tester) async {
    await pumpThemeScreen(tester);

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('Giao diện'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);

    // 3 hàng đúng thứ tự Sáng → Tối → Theo hệ thống.
    const names = ['Sáng', 'Tối', 'Theo hệ thống'];
    double prev = -1;
    for (final name in names) {
      final y = tester.getTopLeft(find.text(name)).dy;
      expect(y, greaterThan(prev), reason: '$name phải nằm dưới hàng trước');
      prev = y;
    }

    // Icon minh họa + dòng phụ đúng mockup.
    expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    expect(find.byIcon(Icons.devices), findsOneWidget);
    expect(find.text('Nền trắng, chữ tối'), findsOneWidget);
    expect(find.text('Nền tối, chữ sáng, đỡ mỏi mắt ban đêm'), findsOneWidget);
    expect(find.text('Tự đổi theo cài đặt điện thoại'), findsOneWidget);

    // Ghi chú chân màn (nguyên văn svg).
    expect(
      find.text('Thay đổi được áp dụng ngay lập tức, không cần khởi động lại ứng dụng.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Radio mặc định: "Theo hệ thống" chọn sẵn, không hàng nào khác chọn (FR-004)',
      (tester) async {
    await pumpThemeScreen(tester);

    expect(isSelected(tester, 'system'), isTrue);
    expect(isSelected(tester, 'light'), isFalse);
    expect(isSelected(tester, 'dark'), isFalse);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('Chọn "Tối" → radio đổi + controller Rx + store ghi (FR-005)',
      (tester) async {
    final fake = await pumpThemeScreen(tester);

    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();

    expect(isSelected(tester, 'dark'), isTrue);
    expect(isSelected(tester, 'light'), isFalse);
    expect(isSelected(tester, 'system'), isFalse);
    expect(Get.find<ThemeController>().mode.value, ThemeMode.dark);
    expect(fake.storedMode, ThemeMode.dark);
  });

  testWidgets('Áp ngay toàn app: sau khi chọn Tối, theme hiện hành là dark', (tester) async {
    await pumpThemeScreen(tester);

    expect(Theme.of(tester.element(find.byType(ThemeScreen))).brightness,
        Brightness.light);

    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();

    expect(Theme.of(tester.element(find.byType(ThemeScreen))).brightness,
        Brightness.dark);
  });

  testWidgets('Mở lại app với lựa chọn đã lưu → radio đúng hàng (FR-006)', (tester) async {
    await pumpThemeScreen(tester, initialMode: ThemeMode.dark);

    expect(isSelected(tester, 'dark'), isTrue);
    expect(isSelected(tester, 'system'), isFalse);
  });

  testWidgets('Chạm nhanh liên tiếp → hàng cuối = lần chạm cuối', (tester) async {
    final fake = await pumpThemeScreen(tester);

    await tester.tap(find.text('Sáng'));
    await tester.pump();
    await tester.tap(find.text('Tối'));
    await tester.pump();
    await tester.tap(find.text('Theo hệ thống'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(isSelected(tester, 'system'), isTrue);
    expect(Get.find<ThemeController>().mode.value, ThemeMode.system);
    expect(fake.storedMode, ThemeMode.system);
  });

  testWidgets('Cỡ chữ lớn + màn nhỏ: cuộn tới ghi chú cuối, không overflow (FR-010)',
      (tester) async {
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.binding.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpThemeScreen(tester);
    await tester.binding.setSurfaceSize(const Size(360, 640));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Thay đổi được áp dụng ngay lập tức, không cần khởi động lại ứng dụng.'),
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'Không được có FlutterError (RenderFlex overflow) khi cỡ chữ lớn');
  });
}
