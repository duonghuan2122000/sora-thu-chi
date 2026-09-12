import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// FAB tròn teal 52px "thêm giao dịch" — khối tách từ `app_shell` (PBI 20) để
/// vỏ app và màn Tổng quan Ngân sách dùng chung đúng một định nghĩa. Chỉ là
/// hình dáng + hành động; vị trí (`FloatingActionButtonLocation`) do màn quyết.
class AddTransactionFab extends StatelessWidget {
  const AddTransactionFab({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.teal,
      shape: const CircleBorder(),
      elevation: 6,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 52,
          height: 52,
          child: Icon(Icons.add, color: AppColors.white, size: 28),
        ),
      ),
    );
  }
}
