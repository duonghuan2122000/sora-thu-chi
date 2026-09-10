import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/security/pin_controller.dart';
import '../../theme/sora_colors.dart';
import 'widgets/pin_dots.dart';
import 'widgets/pin_keypad.dart';

/// Màn khóa toàn màn hình (mockup `02-khoa-pin.svg`): hiện trước mọi nội dung
/// khi vào app / quay lại từ nền (FR-005). Nhập đúng → `onUnlocked` (nơi đẩy
/// màn quyết định về đúng màn cũ — FR-007); sai → lỗi chung + chống dò
/// (FR-008/009). Bị chặn → keypad tắt + đếm ngược, hết chặn chỉ mở lại nhập.
class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  static const _maxLength = PinDots.length;

  PinController get _controller => Get.find<PinController>();

  String _buffer = '';
  String _error = '';
  bool _blocked = false;
  int _blockSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_controller.isBlocked) _startBlocking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startBlocking() {
    _updateBlock();
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _updateBlock());
  }

  void _updateBlock() {
    if (!mounted) return;
    if (!_controller.isBlocked) {
      _timer?.cancel();
      _timer = null;
      setState(() {
        _blocked = false;
        _blockSeconds = 0;
        _error = '';
        _buffer = '';
      });
      return;
    }
    setState(() {
      _blocked = true;
      _blockSeconds = _controller.remainingLockSeconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 6,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLockIcon(colors),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Text(
                              'Nhập mã PIN'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _blocked
                                  ? 'Nhiều lần nhập sai. Thử lại sau @giây giây.'
                                      .trParams({'giây': '$_blockSeconds'})
                                  : _error.isNotEmpty
                                      ? _error.tr
                                      : 'Mở khóa Sora Thu Chi'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: (_blocked || _error.isNotEmpty)
                                    ? colors.coralOnNeutral
                                    : colors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      PinDots(filledCount: _buffer.length),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 44),
                  child: PinKeypad(
                    onDigit: _onDigit,
                    onBackspace: _onBackspace,
                    enabled: !_blocked,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockIcon(SoraColors colors) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.tealLightBg,
      ),
      child: Icon(Icons.lock_outline, color: colors.tealOnNeutral, size: 30),
    );
  }

  void _onDigit(int digit) {
    if (_blocked || _buffer.length >= _maxLength) return;
    setState(() {
      _error = '';
      _buffer = '$_buffer$digit';
      if (_buffer.length == _maxLength) _submit();
    });
  }

  void _onBackspace() {
    if (_blocked) return;
    setState(() {
      if (_buffer.isNotEmpty) _buffer = _buffer.substring(0, _buffer.length - 1);
    });
  }

  Future<void> _submit() async {
    final pin = _buffer;
    _buffer = '';
    final result = await _controller.verify(pin);
    if (!mounted) return;
    switch (result) {
      case VerifyResult.success:
        widget.onUnlocked();
      case VerifyResult.wrong:
        if (_controller.isBlocked) {
          _startBlocking();
        } else {
          setState(() => _error = 'Mã PIN không đúng');
        }
      case VerifyResult.blocked:
        _startBlocking();
    }
  }
}
