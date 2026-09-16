import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/locale/locale_controller.dart';
import 'package:sora_thu_chi/core/notification/notification_store.dart';
import 'package:sora_thu_chi/core/profile/device_profile.dart';
import 'package:sora_thu_chi/core/security/pin_controller.dart';
import 'package:sora_thu_chi/core/security/pin_store.dart';
import 'package:sora_thu_chi/core/theme/theme_controller.dart';
import 'package:sora_thu_chi/core/scan/device_tier.dart';
import 'package:sora_thu_chi/core/scan/model_manager.dart';
import 'package:sora_thu_chi/core/scan/scan_controller.dart';
import 'package:sora_thu_chi/core/scan/scan_result.dart';
import 'package:sora_thu_chi/core/scan/scan_settings.dart';
import 'package:sora_thu_chi/core/utilities/utilities_store.dart';
import 'package:sora_thu_chi/core/wallet/wallet_controller.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/category_list_screen.dart';
import 'package:sora_thu_chi/screens/notification_settings_screen.dart';
import 'package:sora_thu_chi/screens/scan/device_check_screen.dart';
import 'package:sora_thu_chi/screens/settings_screen.dart';
import 'package:sora_thu_chi/screens/utilities_screen.dart';
import 'package:sora_thu_chi/screens/wallet_list_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/biometric_gateway_fake.dart';
import 'fakes/fake_locale_store.dart';
import 'fakes/fake_notification_store.dart';
import 'fakes/fake_theme_store.dart';
import 'fakes/fake_device_probe.dart';
import 'fakes/fake_scan_model_manager.dart';
import 'fakes/fake_scan_settings_store.dart';
import 'fakes/fake_utilities_store.dart';
import 'fakes/fake_wallet_repository.dart';
import 'fakes/pin_store_fake.dart';

/// Danh sách ví giờ đọc [WalletController] — đăng ký controller fake để list
/// không khởi tạo drift (sqlite native) trong widget test.
Future<void> _registerWalletController() async {
  Get.reset();
  final controller = WalletController(FakeWalletRepository());
  Get.put(controller);
  await controller.init();
  addTearDown(Get.reset);
}

/// [CategoryListScreen] đọc repository qua [ensureWalletRepository] — đăng ký
/// repo fake (không sqlite native) trước khi đẩy màn.
void _registerRepository() {
  Get.reset();
  Get.put<WalletRepository>(FakeWalletRepository());
  addTearDown(Get.reset);
}

/// [UtilitiesScreen] mở qua SettingsScreen (store null) tự ensure store — đăng
/// ký store fake để không khởi tạo drift (sqlite native) trong widget test.
/// Hàng "Giao diện" (PBI 18) đọc [ThemeController] và hàng "Ngôn ngữ" (PBI 19)
/// đọc [LocaleController] qua Obx → đăng ký kèm.
void _registerUtilitiesStore() {
  Get.reset();
  Get.put<UtilitiesStore>(FakeUtilitiesStore());
  Get.put<ThemeController>(ThemeController(FakeThemeStore()));
  Get.put<LocaleController>(LocaleController(FakeLocaleStore()));
  addTearDown(Get.reset);
}

/// [NotificationSettingsScreen] mở qua SettingsScreen (store null) tự ensure
/// store — đăng ký store fake để không khởi tạo drift (sqlite native).
void _registerNotificationStore() {
  Get.reset();
  Get.put<NotificationStore>(FakeNotificationStore());
  addTearDown(Get.reset);
}

/// Hàng "Mở khóa sinh trắc học" (PBI 34) đọc [PinController] — đăng ký
/// controller + gateway fake để test bơm kết quả hỗ trợ/xác thực.
Future<PinController> _registerPinController({
  PinStoreFake? store,
  BiometricGatewayFake? gateway,
}) async {
  Get.reset();
  final controller = PinController(
    store: store ?? PinStoreFake(),
    gateway: gateway ?? BiometricGatewayFake(),
  );
  await controller.init();
  Get.put(controller);
  addTearDown(Get.reset);
  return controller;
}

Future<void> pumpSettings(
  WidgetTester tester, {
  DeviceProfile profile = DeviceProfile.initial,
  VoidCallback? onManageWalletTap,
  VoidCallback? onManageCategoryTap,
  VoidCallback? onManageUtilitiesTap,
  VoidCallback? onManageNotificationsTap,
  VoidCallback? onManageBackupTap,
  ScanSettings? scanSettings,
  FakeDeviceProbe? probe,
}) async {
  // Nhóm "QUÉT HÓA ĐƠN AI" (PBI 24) đọc [ScanController] — đăng ký fake nếu
  // test chưa đăng ký (không mở drift sqlite native).
  if (!Get.isRegistered<ScanController>()) {
    final controller = ScanController(
      FakeScanSettingsStore(stored: scanSettings),
      probe ?? FakeDeviceProbe(),
    );
    controller.settings.value = scanSettings ?? const ScanSettings();
    Get.put(controller);
    addTearDown(Get.reset);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: Scaffold(
        body: SettingsScreen(
          profile: profile,
          onManageWalletTap: onManageWalletTap,
          onManageCategoryTap: onManageCategoryTap,
          onManageUtilitiesTap: onManageUtilitiesTap,
          onManageNotificationsTap: onManageNotificationsTap,
          onManageBackupTap: onManageBackupTap,
        ),
      ),
    ),
  );
}

/// `ListView` của màn Cài đặt dựng lười — hàng cuối nhóm KHÁC (PBI 28) nằm
/// ngoài viewport mặc định 800×600, nên test chạm tới nó cần màn cao hơn.
Future<void> useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  group('SettingsScreen — hiển thị màn Cài đặt', () {
    testWidgets('Giá trị trailing căn sát mép phải hàng (không nằm giữa)', (
      tester,
    ) async {
      await pumpSettings(tester);
      final screenWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;

      // Hàng có trailing ngắn — mép phải phải bằng mép phải hàng (trừ padding 20).
      expect(
        tester.getTopRight(find.text('VND')).dx,
        closeTo(screenWidth - 20, 0.5),
      );
      expect(
        tester.getTopRight(find.byIcon(Icons.chevron_right).first).dx,
        closeTo(screenWidth - 20, 0.5),
      );
    });

    testWidgets('Profile mặc định → đủ khối hồ sơ + 2 nhóm/7 hàng đúng', (tester) async {
      await useTallSurface(tester);
      await pumpSettings(tester);

      // Header + khối hồ sơ.
      expect(find.text('Cài đặt'), findsOneWidget);
      expect(find.text('ND'), findsOneWidget); // avatar chữ viết tắt
      expect(find.text('Người dùng'), findsOneWidget);
      expect(find.text('Chạm để đổi ảnh đại diện'), findsOneWidget);

      // 2 nhóm + 8 hàng (KHÁC thêm hàng "Sao lưu & Khôi phục" — PBI 35).
      expect(find.text('TÀI KHOẢN'), findsOneWidget);
      expect(find.text('Tiền tệ mặc định'), findsOneWidget);
      expect(find.text('Đổi mã PIN'), findsOneWidget);
      expect(find.text('Mở khóa sinh trắc học'), findsOneWidget);
      expect(find.text('KHÁC'), findsOneWidget);
      expect(find.text('Quản lý ví'), findsOneWidget);
      expect(find.text('Danh mục'), findsOneWidget);
      expect(find.text('Tiện ích & Cá nhân hóa'), findsOneWidget);
      expect(find.text('Thông báo & nhắc nhở'), findsOneWidget);
      expect(find.text('Sao lưu & Khôi phục'), findsOneWidget);

      // Giá trị tiền tệ + công tắc sinh trắc học tắt. Công tắc của nhóm
      // "QUÉT HÓA ĐƠN AI" (PBI 24) nằm dưới đáy danh sách nên chưa được dựng.
      expect(find.text('VND'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
    });

    testWidgets('Hàng đúng thứ tự từ trên xuống', (tester) async {
      await useTallSurface(tester);
      await pumpSettings(tester);

      final ordered = [
        'Tiền tệ mặc định',
        'Đổi mã PIN',
        'Mở khóa sinh trắc học',
        'Quản lý ví',
        'Danh mục',
        'Tiện ích & Cá nhân hóa',
        'Thông báo & nhắc nhở',
        'Sao lưu & Khôi phục',
      ];
      double prev = -1;
      for (final label in ordered) {
        final y = tester.getTopLeft(find.text(label)).dy;
        expect(y, greaterThan(prev), reason: '$label phải nằm dưới hàng trước');
        prev = y;
      }
      // Nhóm KHÁC nằm sau 3 hàng nhóm TÀI KHOẢN (trước hàng Quản lý ví).
      final biometricY = tester.getTopLeft(find.text('Mở khóa sinh trắc học')).dy;
      final manageY = tester.getTopLeft(find.text('Quản lý ví')).dy;
      final otherY = tester.getTopLeft(find.text('KHÁC')).dy;
      expect(otherY, greaterThan(biometricY));
      expect(otherY, lessThan(manageY));
    });

    testWidgets('Profile tên dài + cỡ chữ lớn → không overflow, tên cắt ellipsis', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.binding.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const profile = DeviceProfile(
        displayName: 'Một cái tên cực kỳ dài để kiểm tra chống tràn layout của khối hồ sơ',
      );
      await pumpSettings(tester, profile: profile);

      // Quét toàn bộ nội dung xuống đáy — mọi hàng được build, không overflow.
      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();
      }
      expect(tester.takeException(), isNull,
          reason: 'Không được có FlutterError (RenderFlex overflow) khi cỡ chữ lớn');
      expect(find.text('Cài đặt'), findsOneWidget);
    });

    testWidgets('Tap hàng chưa kích hoạt & Switch → không mở màn, Switch giữ tắt', (tester) async {
      await pumpSettings(tester);

      for (final label in ['Tiền tệ mặc định', 'Đổi mã PIN']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      // Switch sinh trắc học: chạm nhiều lần (kể cả nhanh) không bật.
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(Switch).first);
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Không có route/màn mới: màn Cài đặt còn nguyên (không bị đẩy xuống offstage),
      // không có nút back, không lỗi.
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(WalletListScreen), findsNothing);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tap "Quản lý ví" → đẩy WalletListScreen, back trả về Cài đặt', (tester) async {
      await _registerWalletController();
      await pumpSettings(tester);

      await tester.tap(find.text('Quản lý ví'));
      await tester.pumpAndSettle();

      expect(find.byType(WalletListScreen), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.text('19.450.000 đ'), findsOneWidget); // 5 ví mẫu mặc định

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(WalletListScreen), findsNothing);
    });

    testWidgets('Bơm onManageWalletTap → gọi callback, không đẩy route', (tester) async {
      var tapped = false;
      await pumpSettings(tester, onManageWalletTap: () => tapped = true);

      await tester.tap(find.text('Quản lý ví'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(find.byType(WalletListScreen), findsNothing);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Tap "Danh mục" → đẩy CategoryListScreen, back trả về Cài đặt', (tester) async {
      _registerRepository();
      await pumpSettings(tester);

      await tester.tap(find.text('Danh mục'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryListScreen), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.text('Danh mục'), findsOneWidget); // app bar màn con
      expect(find.text('Chi tiêu'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(CategoryListScreen), findsNothing);
    });

    testWidgets('Bơm onManageCategoryTap → gọi callback, không đẩy route', (tester) async {
      var tapped = false;
      await pumpSettings(tester, onManageCategoryTap: () => tapped = true);

      await tester.tap(find.text('Danh mục'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(find.byType(CategoryListScreen), findsNothing);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Tap "Tiện ích & Cá nhân hóa" → đẩy UtilitiesScreen, back về', (tester) async {
      _registerUtilitiesStore();
      await pumpSettings(tester);

      await tester.tap(find.text('Tiện ích & Cá nhân hóa'));
      await tester.pumpAndSettle();

      expect(find.byType(UtilitiesScreen), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.text('Tiện ích & Cá nhân hóa'), findsOneWidget); // app bar màn con
      expect(find.text('Giao diện'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(UtilitiesScreen), findsNothing);
    });

    testWidgets('Bơm onManageUtilitiesTap → gọi callback, không đẩy route', (tester) async {
      var tapped = false;
      await pumpSettings(tester, onManageUtilitiesTap: () => tapped = true);

      await tester.tap(find.text('Tiện ích & Cá nhân hóa'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(find.byType(UtilitiesScreen), findsNothing);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Tap "Thông báo & nhắc nhở" → đẩy NotificationSettingsScreen, back về', (
      tester,
    ) async {
      await useTallSurface(tester);
      _registerNotificationStore();
      await pumpSettings(tester);

      await tester.tap(find.text('Thông báo & nhắc nhở'));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.text('NHẮC NHỞ HÀNG NGÀY'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(NotificationSettingsScreen), findsNothing);
    });

    testWidgets('Bơm onManageNotificationsTap → gọi callback, không đẩy route', (
      tester,
    ) async {
      var tapped = false;
      await useTallSurface(tester);
      await pumpSettings(tester, onManageNotificationsTap: () => tapped = true);

      await tester.tap(find.text('Thông báo & nhắc nhở'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(find.byType(NotificationSettingsScreen), findsNothing);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Bơm onManageBackupTap → gọi callback, không đẩy route', (
      tester,
    ) async {
      var tapped = false;
      await useTallSurface(tester);
      await pumpSettings(tester, onManageBackupTap: () => tapped = true);

      await tester.tap(find.text('Sao lưu & Khôi phục'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('SettingsScreen — nhóm QUÉT HÓA ĐƠN AI (PBI 24)', () {
    testWidgets('Có nhóm + công tắc + khối trạng thái; chưa kiểm tra → mặc định',
        (tester) async {
      await pumpSettings(tester);
      // Quét xuống cuối danh sách để nhóm mới được dựng.
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('QUÉT HÓA ĐƠN AI'), findsOneWidget);
      expect(find.text('Quét hóa đơn bằng AI'), findsOneWidget);
      expect(find.text('Trạng thái AI'), findsOneWidget);
      expect(find.text('Chế độ cơ bản'), findsOneWidget);
      expect(find.text('Lần kiểm tra gần nhất'), findsOneWidget);
      expect(find.text('Chưa kiểm tra'), findsOneWidget);
      expect(find.text('Kiểm tra lại cấu hình máy'), findsOneWidget);

      final switchFinder = find.byKey(const ValueKey('scan-enabled-switch'));
      expect(tester.widget<Switch>(switchFinder).value, isFalse);
    });

    testWidgets('Bật công tắc → ghi xuống store ngay (write-through)',
        (tester) async {
      final store = FakeScanSettingsStore();
      Get.reset();
      final controller = ScanController(store, FakeDeviceProbe());
      Get.put(controller);
      addTearDown(Get.reset);
      await pumpSettings(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('scan-enabled-switch')));
      await tester.pumpAndSettle();

      expect(controller.settings.value.enabled, isTrue);
      expect(store.storedSettings.enabled, isTrue);
      expect(
        tester
            .widget<Switch>(find.byKey(const ValueKey('scan-enabled-switch')))
            .value,
        isTrue,
      );
    });

    testWidgets('Đã kiểm tra cấu hình → hiện tier + mốc kiểm tra gần nhất',
        (tester) async {
      final checked = DeviceCapability(
        ramGb: 3,
        freeStorageGb: 1.2,
        supportsOnDeviceAi: false,
        supportsGpuDelegate: false,
        osVersion: 'Android 14',
        checkedAt: DateTime(2026, 9, 12, 8, 24),
      );
      await pumpSettings(
        tester,
        scanSettings: ScanSettings(enabled: true, deviceCheck: checked),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('Chế độ cơ bản (Tier C)'), findsOneWidget);
      expect(find.text('12/09/2026 08:24'), findsOneWidget);
    });

    testWidgets(
        'Máy đo Tier A nhưng đã chuyển Tier B → hiện đúng Gemma 4 E2B',
        (tester) async {
      final checked = DeviceCapability(
        ramGb: 8,
        freeStorageGb: 10,
        supportsOnDeviceAi: true,
        supportsGpuDelegate: true,
        osVersion: 'Android 15',
        checkedAt: DateTime(2026, 9, 16, 9, 0),
      );
      await pumpSettings(
        tester,
        scanSettings: ScanSettings(
          enabled: true,
          mode: ScanEngine.gemma3nE2b,
          modelBytes: 1800000000,
          deviceCheck: checked,
        ),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('Gemma 4 E2B (Tier B)'), findsOneWidget);
      expect(find.text('Gemini Nano (Tier A)'), findsNothing);
    });

    testWidgets('Đã tải model Tier B → hiện dung lượng + hàng Xoá model',
        (tester) async {
      await pumpSettings(
        tester,
        scanSettings: const ScanSettings(
          enabled: true,
          mode: ScanEngine.gemma3nE2b,
          modelBytes: 1800000000,
        ),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Dung lượng model'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('scan-model-size')))
            .data,
        '1.8 GB',
      );
      expect(find.text('Xoá model'), findsOneWidget);
      expect(find.text('Kiểm tra cập nhật model'), findsOneWidget);
    });

    testWidgets('Chưa tải model → không có hàng dung lượng/Xoá model',
        (tester) async {
      await pumpSettings(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Dung lượng model'), findsNothing);
      expect(find.text('Xoá model'), findsNothing);
      expect(find.text('Kiểm tra cập nhật model'), findsOneWidget);
    });

    testWidgets('Chạm "Xoá model" → gọi manager.delete + về Chế độ cơ bản',
        (tester) async {
      final store = FakeScanSettingsStore();
      Get.reset();
      final controller = ScanController(store, FakeDeviceProbe());
      controller.settings.value = const ScanSettings(
        enabled: true,
        mode: ScanEngine.gemma3nE2b,
        modelBytes: 1800000000,
      );
      Get.put(controller);
      final manager = FakeScanModelManager(installed: 1800000000);
      Get.put<ScanModelManager>(manager);
      addTearDown(Get.reset);

      await pumpSettings(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xoá model'));
      await tester.pumpAndSettle();

      expect(manager.deleteCount, 1);
      expect(controller.settings.value.modelBytes, 0);
      expect(controller.settings.value.mode, ScanEngine.ruleBased);
      expect(find.text('Dung lượng model'), findsNothing);
    });

    testWidgets('Hàng "Kiểm tra lại cấu hình máy" → đẩy màn scan-10',
        (tester) async {
      await pumpSettings(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiểm tra lại cấu hình máy'));
      await tester.pumpAndSettle();

      expect(find.byType(DeviceCheckScreen), findsOneWidget);
      expect(find.text('Kiểm tra cấu hình máy'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('SettingsScreen — hàng "Mở khóa sinh trắc học" (PBI 34)', () {
    testWidgets('Đã bật sẵn → công tắc hiện bật', (tester) async {
      final store = PinStoreFake.withPin('1234');
      await store.saveBiometricState(
        const BiometricState(enabled: true, enrolledTypes: ['fingerprint']),
      );
      await _registerPinController(store: store);
      await pumpSettings(tester);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    });

    testWidgets(
        'Thiết bị không hỗ trợ/chưa đăng ký → công tắc tắt, không bật được, hiện dòng giải thích (FR-001)',
        (tester) async {
      final gateway = BiometricGatewayFake()..availableTypesResult = [];
      await _registerPinController(gateway: gateway);
      await pumpSettings(tester);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
      expect(
        find.text('Thiết bị chưa hỗ trợ hoặc chưa đăng ký vân tay/khuôn mặt'),
        findsOneWidget,
      );

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
    });

    testWidgets('Chạm bật, xác thực thành công → công tắc bật (FR-002)',
        (tester) async {
      final controller = await _registerPinController();
      await pumpSettings(tester);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(controller.biometricEnabled, isTrue);
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    });

    testWidgets('Chạm bật, xác thực huỷ/thất bại → công tắc vẫn tắt',
        (tester) async {
      final gateway = BiometricGatewayFake()..authenticateResult = false;
      final controller = await _registerPinController(gateway: gateway);
      await pumpSettings(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(controller.biometricEnabled, isFalse);
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
    });

    testWidgets('Tắt công tắc đang bật → tắt ngay, không xác thực gì (FR-009)',
        (tester) async {
      final store = PinStoreFake.withPin('1234');
      await store.saveBiometricState(
        const BiometricState(enabled: true, enrolledTypes: ['fingerprint']),
      );
      final gateway = BiometricGatewayFake();
      final controller = await _registerPinController(
        store: store,
        gateway: gateway,
      );
      await pumpSettings(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(controller.biometricEnabled, isFalse);
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
      expect(gateway.authenticateCallCount, 0);
    });
  });
}
