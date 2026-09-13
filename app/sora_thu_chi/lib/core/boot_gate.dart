import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/pin/pin_lock_screen.dart';
import '../screens/pin/pin_setup_screen.dart';
import '../theme/app_colors.dart';
import 'app_shell.dart';
import 'locale/locale_controller.dart';
import 'security/pin_controller.dart';
import 'security/pin_store.dart';
import 'theme/theme_controller.dart';

/// Màn gốc của phiên: hiển thị **splash** trong lúc app nạp (logo + tên thương
/// hiệu trên nền teal, không nội dung tài chính), rồi điều hướng sang thiết lập
/// PIN / màn khóa / Tổng quan.
class PinGate extends StatefulWidget {
  const PinGate({super.key, required this.store});

  final PinStore store;

  /// Trần chờ nạp: quá hạn thì vào app với cấu hình đang có (FR-006/SC-003).
  static const bootCap = Duration(seconds: 5);

  /// Cỡ logo trên splash — **phải khớp** `android:width/height` của
  /// `launch_background.xml` để không nhảy hình giữa hai tầng (FR-010).
  static const logoWidth = 140.0;

  @override
  State<PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<PinGate> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (Get.isRegistered<PinController>()) {
      Get.delete<PinController>(force: true);
    }
    final controller = Get.put<PinController>(
      PinController(store: widget.store, now: DateTime.now),
      permanent: true,
    );
    await _waitUntilReady(controller);
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (controller.configured) {
      // Cold start có PIN → màn khóa là root trước mọi nội dung (FR-005).
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => PinLockScreen(onUnlocked: () => _enterApp(navigator)),
        ),
        (_) => false,
      );
    } else {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => PinSetupScreen(onDone: () => _enterApp(navigator))),
        (_) => false,
      );
    }
  }

  /// Chờ song song nhóm nạp (PIN + giao diện + ngôn ngữ) với trần
  /// [PinGate.bootCap]. Timer **phải huỷ được**: để nó treo thì `flutter test`
  /// báo *"A Timer is still pending"* (R6).
  Future<void> _waitUntilReady(PinController controller) {
    final done = Completer<void>();
    final timer = Timer(PinGate.bootCap, () {
      if (!done.isCompleted) done.complete();
    });
    Future.wait<void>([
      controller.init(),
      Get.find<ThemeController>().load(),
      Get.find<LocaleController>().load(),
    ]).whenComplete(() {
      timer.cancel();
      if (!done.isCompleted) done.complete();
    }).ignore();
    return done.future;
  }

  void _enterApp(NavigatorState navigator) {
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Màu **bất biến** (không qua `SoraColors.of`) — splash giống hệt nhau ở
    // giao diện Sáng và Tối (FR-004/FR-008).
    return Scaffold(
      backgroundColor: AppColors.teal,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/brand/coin_flow_logo.png',
                width: PinGate.logoWidth,
                height: PinGate.logoWidth,
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    // Tên thương hiệu — không dịch theo ngôn ngữ (kế hoạch §5).
                    'Sora Thu Chi',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
