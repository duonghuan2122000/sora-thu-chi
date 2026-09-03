import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/boot_gate.dart';
import 'core/security/pin_controller.dart';
import 'core/security/pin_store.dart';
import 'core/security/pin_store_secure.dart';
import 'screens/pin/pin_lock_screen.dart';
import 'theme/app_theme.dart';

/// Gốc app. `home` = BootGate nền trung tính; PIN controller được khởi tạo ở
/// đây (qua PinGate) rồi dùng lại cho khóa khi resume (US2).
class SoraApp extends StatefulWidget {
  const SoraApp({super.key, this.store});

  /// Bơm store để test; mặc định dùng secure storage thật.
  final PinStore? store;

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
    return GetMaterialApp(
      title: 'Sora Thu Chi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      navigatorKey: _navigatorKey,
      home: PinGate(store: _store),
    );
  }
}
