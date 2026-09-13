import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'core/boot_gate.dart';
import 'core/locale/locale_controller.dart';
import 'core/locale/locale_store.dart';
import 'core/locale/sora_translations.dart';
import 'core/security/pin_controller.dart';
import 'core/security/pin_store.dart';
import 'core/security/pin_store_secure.dart';
import 'core/theme/theme_controller.dart';
import 'core/theme/theme_store.dart';
import 'data/locale_deps.dart';
import 'data/notification_deps.dart';
import 'data/scan_deps.dart';
import 'data/theme_deps.dart';
import 'screens/pin/pin_lock_screen.dart';
import 'theme/app_theme.dart';

/// Gốc app. `home` = BootGate nền trung tính; PIN controller được khởi tạo ở
/// đây (qua PinGate) rồi dùng lại cho khóa khi resume (US2).
class SoraApp extends StatefulWidget {
  const SoraApp({super.key, this.store, this.themeStore, this.localeStore});

  /// Bơm store để test; mặc định dùng secure storage thật.
  final PinStore? store;

  /// Bơm store giao diện để test; mặc định dùng drift.
  final ThemeStore? themeStore;

  /// Bơm store ngôn ngữ để test; mặc định dùng drift.
  final LocaleStore? localeStore;

  @override
  State<SoraApp> createState() => _SoraAppState();
}

class _SoraAppState extends State<SoraApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final PinStore _store = widget.store ?? PinStoreSecure();

  /// Đã rời nền khi phiên đang mở nội dung → resume phải khóa (FR-005).
  bool _pendingLock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Giao diện: chỉ đăng ký controller ở gốc để `Obx`/`themeMode` có nguồn
    // ngay frame đầu — việc `load()` chuyển vào nhóm chờ của splash (PBI 25,
    // FR-013) để màn kế tiếp hiện ra đã đúng giao diện đã chọn.
    if (!Get.isRegistered<ThemeController>()) {
      Get.put(ThemeController(widget.themeStore ?? ensureThemeStore()));
    }
    // Ngôn ngữ: cùng khuôn (chỉ reassemble khi khác `vi`).
    if (!Get.isRegistered<LocaleController>()) {
      Get.put(LocaleController(widget.localeStore ?? ensureLocaleStore()));
    }
    // Quét hóa đơn (PBI 24): công tắc + chế độ + hồ sơ thiết bị dùng chung cho
    // sheet FAB và màn Cài đặt ⇒ nạp ở gốc app (R15).
    ensureScanController().load();
    // Thông báo đẩy (PBI 31): đọc payload của lần chạm đã mở app này rồi hoà
    // giải sổ. Cả hai **fire-and-forget** — không chặn splash/`PinGate` (FR-024).
    _bootstrapNotifications();
  }

  /// Nhặt payload chạm thông báo (nếu app được mở bằng cách chạm) và hoà giải
  /// sổ + cuốn lịch. Mọi lỗi đã bị nuốt bên trong engine.
  Future<void> _bootstrapNotifications() async {
    try {
      ensureNotificationTapRouter().put(
        await ensureNotificationPresenter().launchPayload(),
      );
    } catch (_) {
      // Không đọc được launch details ⇒ coi như mở app bình thường.
    }
    ensureNotificationEngine().reconcile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final controller =
        Get.isRegistered<PinController>() ? Get.find<PinController>() : null;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (controller != null && controller.configured && !controller.isLocked) {
          _pendingLock = true;
        }
      case AppLifecycleState.resumed:
        // Về tiền cảnh: cuốn lại lịch + ghi bù bản ghi của mốc đã bắn khi app
        // đóng (R6) — fire-and-forget, không chặn luồng mở khoá bên dưới.
        ensureNotificationEngine().reconcile();
        if (_pendingLock &&
            controller != null &&
            controller.configured &&
            !controller.isLocked) {
          // Đóng cờ trước khi đẩy để resume lặp không push chồng màn khóa.
          _pendingLock = false;
          controller.isLocked = true;
          // Route phủ lên đỉnh stack: che cả sub-page đang mở; pop về đúng màn cũ.
          _navigatorKey.currentState?.push(
            MaterialPageRoute<void>(
              builder: (_) => PinLockScreen(
                onUnlocked: () => _navigatorKey.currentState?.pop(),
              ),
            ),
          );
        }
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    final localeCtl = Get.find<LocaleController>();
    // Obx bọc cả MaterialApp: đổi Rx → themeMode mới → toàn cây rebuild ngay,
    // không cần khởi động lại (FR-005/SC-004).
    // Lưu ý: hạ `locale:` xuống đây **không** tự rebuild route đang mở — việc
    // "đổi ngay" do `LocaleController.setLocale` gọi `Get.updateLocale` (R2).
    return Obx(
      () => GetMaterialApp(
        title: 'Sora Thu Chi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData,
        darkTheme: AppTheme.darkThemeData,
        themeMode: theme.mode.value,
        translations: SoraTranslations(),
        locale: localeCtl.locale.value,
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        navigatorKey: _navigatorKey,
        home: PinGate(store: _store),
      ),
    );
  }
}
