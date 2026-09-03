import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/pin/pin_lock_screen.dart';
import '../screens/pin/pin_setup_screen.dart';
import '../theme/app_colors.dart';
import 'app_shell.dart';
import 'security/pin_controller.dart';
import 'security/pin_store.dart';

/// Màn gốc trung tính giữ cả phiên làm `home`: nền trắng, không nội dung tài
/// chính (SC-002). Đọc store → điều hướng sang thiết lập PIN hoặc mở khóa
/// trước khi hiển thị bất kỳ nội dung nào.
class PinGate extends StatefulWidget {
  const PinGate({super.key, required this.store});

  final PinStore store;

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
    await controller.init();
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

  void _enterApp(NavigatorState navigator) {
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: AppColors.white, body: SizedBox.expand());
  }
}
