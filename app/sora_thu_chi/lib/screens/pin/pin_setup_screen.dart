import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/security/pin_controller.dart';
import '../../theme/sora_colors.dart';
import 'widgets/pin_dots.dart';
import 'widgets/pin_keypad.dart';

/// Màn thiết lập mã PIN bắt buộc lần đầu (FR-001..004). Toàn màn hình, không
/// app bar/bottom nav. Hai pha: nhập PIN → xác nhận lại; chỉ ghi PIN 1 lần khi
/// khớp (SC-006). Chặn back/back-gesture bằng `PopScope` (FR-010).
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key, required this.onDone});

  /// Gọi sau khi PIN được lưu xong — nơi đẩy vào nội dung app.
  final VoidCallback onDone;

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  static const _maxLength = PinDots.length;

  PinController get _controller => Get.find<PinController>();

  bool _confirming = false;
  String _createdPin = '';
  String _buffer = '';
  String _error = '';

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
                              _confirming ? 'Nhập lại mã PIN' : 'Thiết lập mã PIN',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error.isNotEmpty
                                  ? _error
                                  : (_confirming
                                      ? 'Nhập lại mã PIN lần hai để xác nhận'
                                      : 'Tạo mã PIN 4 số để bảo vệ dữ liệu'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _error.isNotEmpty
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
    setState(() {
      if (_buffer.length >= _maxLength) return;
      _error = '';
      _buffer = '$_buffer$digit';
      if (_buffer.length == _maxLength) _onComplete();
    });
  }

  void _onBackspace() {
    setState(() {
      if (_buffer.isNotEmpty) _buffer = _buffer.substring(0, _buffer.length - 1);
    });
  }

  void _onComplete() {
    if (!_confirming) {
      _createdPin = _buffer;
      _confirming = true;
      _buffer = '';
      return;
    }
    if (_buffer != _createdPin) {
      // Lệch → báo lỗi, nhập lại từ đầu; chưa ghi gì (FR-004).
      _confirming = false;
      _createdPin = '';
      _buffer = '';
      _error = 'Mã PIN không khớp. Vui lòng thử lại.';
      return;
    }
    final pin = _buffer;
    _buffer = '';
    if (_controller.isWeakPin(pin)) {
      _confirmWeakPinThenSave(pin);
    } else {
      _saveAndDone(pin);
    }
  }

  Future<void> _confirmWeakPinThenSave(String pin) async {
    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: const Text('Mã PIN này dễ đoán. Vẫn dùng mã PIN này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Đặt lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (proceed == true) {
      await _saveAndDone(pin);
    } else {
      setState(() {
        _confirming = false;
        _createdPin = '';
        _error = '';
      });
    }
  }

  Future<void> _saveAndDone(String pin) async {
    await _controller.savePin(pin);
    if (mounted) widget.onDone();
  }
}
