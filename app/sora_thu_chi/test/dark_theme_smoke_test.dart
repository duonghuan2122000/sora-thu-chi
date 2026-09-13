import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/locale/locale_controller.dart';
import 'package:sora_thu_chi/core/scan/scan_controller.dart';
import 'package:sora_thu_chi/core/scan/scan_result.dart';
import 'package:sora_thu_chi/core/security/pin_controller.dart';
import 'package:sora_thu_chi/core/theme/theme_controller.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/wallet/wallet_controller.dart';
import 'package:sora_thu_chi/data/report_deps.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/notification_settings_screen.dart';
import 'package:sora_thu_chi/screens/pin/pin_lock_screen.dart';
import 'package:sora_thu_chi/screens/report_category_detail_screen.dart';
import 'package:sora_thu_chi/screens/report_comparison_screen.dart';
import 'package:sora_thu_chi/screens/report_export_screen.dart';
import 'package:sora_thu_chi/screens/report_screen.dart';
import 'package:sora_thu_chi/screens/scan/device_check_screen.dart';
import 'package:sora_thu_chi/screens/scan/scan_confirm_screen.dart';
import 'package:sora_thu_chi/screens/theme_screen.dart';
import 'package:sora_thu_chi/screens/utilities_screen.dart';
import 'package:sora_thu_chi/screens/wallet_list_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';
import 'package:sora_thu_chi/theme/sora_colors.dart';

import 'fakes/fake_device_probe.dart';
import 'fakes/fake_locale_store.dart';
import 'fakes/fake_notification_store.dart';
import 'fakes/fake_scan_image_store.dart';
import 'fakes/fake_scan_settings_store.dart';
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
  // Hàng "Ngôn ngữ" màn Tiện ích đọc [LocaleController] qua Obx (PBI 19).
  Get.put<LocaleController>(LocaleController(FakeLocaleStore()));
  addTearDown(Get.reset);
}

void main() {
  testWidgets('Màn con "Giao diện": card đọc token tối, không overflow', (
    tester,
  ) async {
    registerTheme();
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(darkApp(const ThemeScreen()));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(ThemeScreen));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(SoraColors.of(context).background, SoraColors.dark.background);

    // Card "Tối" (chưa chọn) tô nền surface tối — không còn trắng.
    final box =
        tester
                .widget<Container>(
                  find
                      .descendant(
                        of: find.byKey(const ValueKey('theme-option-dark')),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(box.color, SoraColors.dark.surface);

    for (final label in ['Sáng', 'Tối', 'Theo hệ thống']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Màn "Tiện ích & Cá nhân hóa": hàng + trailing đọc được ở tối', (
    tester,
  ) async {
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

  testWidgets('Màn danh sách ví ở tối: cuộn hết danh sách, không overflow', (
    tester,
  ) async {
    Get.reset();
    final controller = WalletController(FakeWalletRepository());
    Get.put(controller);
    await controller.init();
    addTearDown(Get.reset);

    tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
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

  testWidgets(
    'Màn Tổng quan Báo cáo ở tối: thẻ + vòng tròn đọc bảng màu tối, không overflow',
    (tester) async {
      registerTheme();
      Get.put<WalletRepository>(
        FakeWalletRepository.withCategories(
          transactions: [
            Transaction(
              id: 1,
              walletId: 1,
              type: TxnType.expense,
              category: 'Ăn uống',
              amount: -4200000,
              date: DateTime(2026, 3, 10),
              categoryId: 1,
            ),
          ],
          categoriesSeed: [
            Category(
              id: 1,
              name: 'Ăn uống',
              type: CategoryType.expense,
              icon: 'restaurant',
              color: 0xFF0F6E56,
            ),
          ],
        ),
      );
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = ensureReportController();
      await tester.pumpWidget(darkApp(const Scaffold(body: ReportScreen())));
      await controller.load(now: DateTime(2026, 3, 15));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ReportScreen));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(SoraColors.of(context).background, SoraColors.dark.background);

      // Lát cắt lấy đúng bảng màu **tối** (R4/SC-011), không phải bảng sáng.
      final donut = tester.widget<PieChart>(
        find.byKey(const ValueKey('report-donut')),
      );
      expect(donut.data.sections.first.color, SoraColors.dark.chartPalette[0]);

      // Cuộn hết nội dung — không nhánh nào tràn khung.
      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Màn Chi tiêu theo danh mục ở tối: đọc bảng màu tối, không overflow',
    (tester) async {
      registerTheme();
      Get.put<WalletRepository>(
        FakeWalletRepository.withCategories(
          transactions: [
            for (var i = 1; i <= 6; i++)
              Transaction(
                id: i,
                walletId: 1,
                type: TxnType.expense,
                category: 'Danh mục $i',
                amount: -100000 * i,
                date: DateTime(2026, 3, 10),
                categoryId: i,
              ),
          ],
          categoriesSeed: [
            for (var i = 1; i <= 6; i++)
              Category(
                id: i,
                name: 'Danh mục $i',
                type: CategoryType.expense,
                icon: 'restaurant',
                color: 0xFF0F6E56,
              ),
          ],
        ),
      );
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = ensureReportController();
      await controller.load(now: DateTime(2026, 3, 15));
      await tester.pumpWidget(darkApp(const ReportCategoryDetailScreen()));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ReportCategoryDetailScreen));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(SoraColors.of(context).background, SoraColors.dark.background);

      // Lát cắt lấy bảng màu **tối**, và hạng 5 (danh mục thứ 6) lặp lại màu hạng 0.
      final donut = tester.widget<PieChart>(
        find.byKey(const ValueKey('report-detail-donut')),
      );
      expect(donut.data.sections, hasLength(6));
      expect(donut.data.sections[0].color, SoraColors.dark.chartPalette[0]);
      expect(donut.data.sections[5].color, SoraColors.dark.chartPalette[0]);

      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Màn So sánh kỳ ở tối: hai đường + thẻ Nhận xét đọc token tối, không overflow',
    (tester) async {
      registerTheme();
      Get.put<WalletRepository>(
        FakeWalletRepository.withCategories(
          transactions: [
            Transaction(
              id: 1,
              walletId: 1,
              type: TxnType.expense,
              category: 'Ăn uống',
              amount: -12300000,
              date: DateTime(2026, 3, 10),
              categoryId: 1,
            ),
            Transaction(
              id: 2,
              walletId: 1,
              type: TxnType.expense,
              category: 'Ăn uống',
              amount: -9000000,
              date: DateTime(2025, 3, 10),
              categoryId: 1,
            ),
          ],
          categoriesSeed: [
            Category(
              id: 1,
              name: 'Ăn uống',
              type: CategoryType.expense,
              icon: 'restaurant',
              color: 0xFF0F6E56,
            ),
          ],
        ),
      );
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = ensureReportController();
      await controller.load(now: DateTime(2026, 3, 15));
      await tester.pumpWidget(darkApp(const ReportComparisonScreen()));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ReportComparisonScreen));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(SoraColors.of(context).background, SoraColors.dark.background);

      // Hai đường lấy **đúng** token tối — kể cả nét đứt `tabInactive` (SC-014).
      final chart = tester.widget<LineChart>(
        find.byKey(const ValueKey('report-compare-trend')),
      );
      expect(chart.data.lineBarsData[0].color, SoraColors.dark.tealOnNeutral);
      expect(chart.data.lineBarsData[1].color, SoraColors.dark.tabInactive);
      expect(chart.data.lineBarsData[1].dashArray, [4, 3]);

      // Thẻ Nhận xét dùng nền cam **tối**.
      final card =
          tester
                  .widget<Container>(
                    find.byKey(const ValueKey('report-compare-insight')),
                  )
                  .decoration
              as BoxDecoration;
      expect(card.color, SoraColors.dark.coralLightBg);

      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Màn xác nhận hóa đơn ở tối: 6 trường + nút lưu đọc bảng màu tối, không overflow',
    (tester) async {
      registerTheme();
      Get.put<WalletRepository>(FakeWalletRepository());
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        darkApp(
          ScanConfirmScreen(
            extraction: ScanExtraction(
              amount: const ScanField(
                value: 55000,
                confidence: FieldConfidence.high,
              ),
              date: ScanField(
                value: DateTime(2026, 9, 12, 8, 24),
                confidence: FieldConfidence.high,
              ),
              merchant: const ScanField(
                value: 'CIRCLE K',
                confidence: FieldConfidence.low,
              ),
              category: const ScanField(
                value: null,
                confidence: FieldConfidence.low,
              ),
              engine: ScanEngine.ruleBased,
            ),
            imagePath: '/tmp/hoa-don.jpg',
            repository: FakeWalletRepository(),
            imageStore: FakeScanImageStore(),
            readBytes: (_) async => Uint8List.fromList([1, 2, 3]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(
        find.byKey(const ValueKey('scan-confirm-screen')),
      );
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(SoraColors.of(context).background, SoraColors.dark.background);

      // Nhãn độ tin cậy `low` dùng coral — đọc đúng sắc độ của bảng màu **tối**.
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('scan-confidence-amount')))
            .style
            ?.color,
        SoraColors.dark.tealOnNeutral,
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('scan-confidence-merchant')),
            )
            .style
            ?.color,
        SoraColors.dark.coralOnNeutral,
      );

      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Màn kiểm tra cấu hình máy ở tối: 3 thẻ kết quả đọc token tối, không overflow',
    (tester) async {
      registerTheme();
      Get.put<ScanController>(
        ScanController(FakeScanSettingsStore(), FakeDeviceProbe()),
      );
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(darkApp(const DeviceCheckScreen()));
      await tester.pumpAndSettle();

      final context = tester.element(
        find.byKey(const ValueKey('device-check-tier-c')),
      );
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(SoraColors.of(context).background, SoraColors.dark.background);
      expect(find.text('Chưa đủ điều kiện dùng AI nâng cao'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('device-check-use-basic')),
        findsOneWidget,
      );

      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Màn Xuất báo cáo (PBI 27) ở tối: chip/thẻ định dạng/hộp tóm tắt/cảnh báo '
    'đọc token tối, không overflow',
    (tester) async {
      registerTheme();
      Get.put<WalletRepository>(
        FakeWalletRepository.withCategories(
          transactions: [
            Transaction(
              id: 1,
              walletId: 1,
              type: TxnType.expense,
              category: 'Ăn uống',
              amount: -300000,
              date: DateTime(2026, 3, 10),
              categoryId: 1,
            ),
          ],
          categoriesSeed: [
            Category(
              id: 1,
              name: 'Ăn uống',
              type: CategoryType.expense,
              icon: 'restaurant',
              color: 0xFF0F6E56,
            ),
          ],
        ),
      );
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = ensureReportController();
      await controller.load(now: DateTime(2026, 3, 15));
      await tester.pumpWidget(darkApp(const ReportExportScreen()));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ReportExportScreen));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(SoraColors.of(context).background, SoraColors.dark.background);

      /// Container đầu tiên bên trong widget mang [key] — nơi đặt nền/viền.
      Color? surfaceColorOf(Key key) {
        final container = tester.widget<Container>(
          find
              .descendant(of: find.byKey(key), matching: find.byType(Container))
              .first,
        );
        return (container.decoration as BoxDecoration?)?.color;
      }

      /// Nền của Container mang [key] (hộp tóm tắt, dòng cảnh báo…).
      Color? decorationColorOf(Key key) {
        final container = tester.widget<Container>(find.byKey(key));
        return (container.decoration as BoxDecoration?)?.color;
      }

      // Chip chưa chọn + thẻ định dạng + hộp tóm tắt + dòng cảnh báo lấy token tối.
      // (Chip "Tất cả" đang chọn nên nền teal — kiểm chip ví chưa chọn.)
      expect(
        surfaceColorOf(const ValueKey('export-wallet-1')),
        SoraColors.dark.softCardBg,
      );
      expect(
        surfaceColorOf(const ValueKey('export-format-pdf')),
        SoraColors.dark.surface,
      );
      expect(
        decorationColorOf(const ValueKey('export-summary')),
        SoraColors.dark.softCardBg,
      );
      expect(
        decorationColorOf(const ValueKey('export-privacy-warning')),
        SoraColors.dark.coralLightBg,
      );

      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Màn Thông báo & nhắc nhở (PBI 28) ở tối: nền/nhãn nhóm/vòng tròn icon '
    '(teal + coral)/công tắc đọc token tối, không overflow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        darkApp(NotificationSettingsScreen(store: FakeNotificationStore())),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(NotificationSettingsScreen));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(SoraColors.of(context).background, SoraColors.dark.background);

      /// Vòng tròn icon của hàng [label] (Container đầu tiên trong hàng).
      Color? circleColorOf(String label) {
        final row = find
            .ancestor(of: find.text(label), matching: find.byType(Row))
            .first;
        final container = tester.widget<Container>(
          find.descendant(of: row, matching: find.byType(Container)).first,
        );
        return (container.decoration as BoxDecoration?)?.color;
      }

      Color? glyphColorOf(String label) {
        final row = find
            .ancestor(of: find.text(label), matching: find.byType(Row))
            .first;
        return tester
            .widget<Icon>(
              find.descendant(of: row, matching: find.byType(Icon)).first,
            )
            .color;
      }

      // Nhãn nhóm lấy token tối.
      expect(
        tester
            .widget<Text>(find.text('NHẮC NHỞ HÀNG NGÀY'))
            .style
            ?.color,
        SoraColors.dark.tabInactive,
      );
      // Cả 2 sắc icon (teal + coral) lấy đúng bảng màu tối.
      expect(
        circleColorOf('Nhắc nhập giao dịch hằng ngày'),
        SoraColors.dark.tealLightBg,
      );
      expect(
        glyphColorOf('Nhắc nhập giao dịch hằng ngày'),
        SoraColors.dark.tealOnNeutral,
      );
      expect(
        circleColorOf('Cảnh báo vượt ngân sách'),
        SoraColors.dark.coralLightBg,
      );
      expect(
        glyphColorOf('Cảnh báo vượt ngân sách'),
        SoraColors.dark.coralOnNeutral,
      );
      // 6 công tắc dựng ra ở tối, đều có nhãn bật/tắt rõ (không mất chấm).
      expect(find.byType(Switch), findsNWidgets(6));

      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
}
