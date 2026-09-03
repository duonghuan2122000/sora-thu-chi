import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Numpad 3×4 tự dựng theo mockup `02-khoa-pin.svg`: nút tròn viền `divider`,
/// chữ số `textPrimary`. Hàng cuối: trái = ô trống (vị trí vân tay, chưa có
/// sinh trắc), giữa `0`, phải = backspace. Widget thuần stateless — kích thước
/// phân phối theo không gian có sẵn (SC-007), không chiều cao cứng.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Cạnh nút tròn = kích thước ô lưới; min để giữ hình tròn.
        final side = math.min(constraints.maxWidth / 3, constraints.maxHeight / 4);
        final rows = <List<int?>>[
          const [1, 2, 3],
          const [4, 5, 6],
          const [7, 8, 9],
          const [null, 0, null],
        ];
        return Column(
          children: [
            for (final row in rows)
              Expanded(
                child: Row(
                  children: [
                    for (final cell in row)
                      Expanded(
                        child: _buildCell(
                          side,
                          // Ô cuối hàng 4 bên phải = backspace.
                          back: row == rows.last && cell == null && row.indexOf(cell) == 2,
                          digit: cell,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCell(double side, {required int? digit, required bool back}) {
    if (digit == null && !back) return const SizedBox();
    final VoidCallback? onTap;
    Widget child;
    if (back) {
      onTap = enabled ? onBackspace : null;
      child = Icon(
        Icons.backspace_outlined,
        color: enabled ? AppColors.textSecondary : AppColors.divider,
        size: math.min(side * 0.42, 26),
      );
    } else {
      onTap = enabled ? () => onDigit(digit!) : null;
      child = Text(
        '$digit',
        style: TextStyle(
          color: enabled ? AppColors.textPrimary : AppColors.divider,
          fontSize: 22,
        ),
      );
    }
    return Center(
      child: SizedBox(
        width: side,
        height: side,
        child: Material(
          color: AppColors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
