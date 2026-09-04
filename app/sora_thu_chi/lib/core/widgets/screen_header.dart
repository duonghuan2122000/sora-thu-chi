import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Vùng tiêu đề teal cho màn chính trong app shell.
/// Nội dung màn được đặt phía dưới header, nền trắng.
/// [bottom] là widget thô (do caller dựng) hiển thị phía dưới tiêu đề
/// trong cùng vùng teal — 3 màn chính còn lại không truyền, giữ layout cũ.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.bottom});

  final String title;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final titleText = Text(
      title,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
    return Container(
      width: double.infinity,
      color: AppColors.teal,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: bottom == null
              ? titleText
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleText,
                    const SizedBox(height: 16),
                    bottom!,
                  ],
                ),
        ),
      ),
    );
  }
}
