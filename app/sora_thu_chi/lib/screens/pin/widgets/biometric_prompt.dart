import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/sora_colors.dart';

/// Màn mời xác thực sinh trắc học (mockup `03-sinh-trac-hoc.svg`): icon vân
/// tay vẽ tay (không icon Material) + text + nút "Dùng mã PIN thay thế" (teal)
/// + nút "Hủy" (viền). Widget thuần — không tự gọi `local_auth`, do
/// `PinLockScreen` điều khiển qua callback (R3/R6).
class BiometricPrompt extends StatelessWidget {
  const BiometricPrompt({
    super.key,
    required this.onRetry,
    required this.onUsePin,
    required this.onCancel,
  });

  /// Chạm icon vân tay → thử xác thực lại.
  final VoidCallback onRetry;

  /// "Dùng mã PIN thay thế" → chuyển ngay bàn phím PIN.
  final VoidCallback onUsePin;

  /// "Hủy" → chỉ huỷ lượt xác thực hiện tại, ở lại màn này (R6).
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onRetry,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.tealLightBg,
                      ),
                      child: CustomPaint(
                        painter: _FingerprintPainter(color: colors.tealOnNeutral),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Chạm để xác thực'.tr,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Sử dụng vân tay hoặc Face ID để mở khóa ứng dụng'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onUsePin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.tealOnNeutral,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Dùng mã PIN thay thế'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Hủy'.tr),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon vân tay vẽ tay theo mockup `03-sinh-trac-hoc.svg` — 3 nét cong lồng
/// nhau, không dùng `Icons.fingerprint` (đúng chủ đích thiết kế trong plan.md).
class _FingerprintPainter extends CustomPainter {
  const _FingerprintPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.22;

    final outer = Path()
      ..moveTo(cx, cy + r)
      ..quadraticBezierTo(cx - r, cy + r, cx - r, cy - r * 0.1)
      ..arcToPoint(
        Offset(cx + r, cy - r * 0.1),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..quadraticBezierTo(cx + r, cy + r * 0.55, cx + r * 0.55, cy + r * 0.85);
    canvas.drawPath(outer, paint);

    final middle = Path()
      ..moveTo(cx, cy - r * 0.5)
      ..arcToPoint(
        Offset(cx + r * 0.7, cy - r * 0.5),
        radius: Radius.circular(r * 0.7),
        clockwise: true,
      )
      ..quadraticBezierTo(cx + r * 0.7, cy + r * 0.2, cx + r * 0.3, cy + r * 0.55);
    canvas.drawPath(middle, paint);

    final inner = Path()
      ..moveTo(cx - r * 0.5, cy - r * 0.1)
      ..arcToPoint(
        Offset(cx + r * 0.5, cy - r * 0.1),
        radius: Radius.circular(r * 0.5),
        clockwise: true,
      );
    canvas.drawPath(inner, paint);
  }

  @override
  bool shouldRepaint(covariant _FingerprintPainter oldDelegate) =>
      oldDelegate.color != color;
}
