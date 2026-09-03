import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Indicator 4 chấm — đặc teal cho ký tự đã nhập, rỗng `dotEmpty` cho còn lại.
/// Widget thuần nhận `filledCount`, không tự quản state.
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.filledCount});

  static const int length = 4;
  final int filledCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(length, (i) {
        final filled = i < filledCount;
        return Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.teal : AppColors.white,
            border: filled
                ? null
                : Border.all(color: AppColors.dotEmpty, width: 1.5),
          ),
        );
      }),
    );
  }
}
