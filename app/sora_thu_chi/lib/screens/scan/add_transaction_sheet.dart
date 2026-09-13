import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/scan_deps.dart';
import '../../theme/app_colors.dart';
import '../../theme/sora_colors.dart';

/// Lựa chọn ở bottom sheet "Thêm giao dịch" (mockup `scan-01`) — điểm vào duy
/// nhất của luồng quét đợt này (2 lối vào khác của doc §3.1 chưa có UI).
enum AddSheetChoice { income, expense, transfer, scan }

/// Mở sheet và trả lựa chọn người dùng; `null` = đóng không chọn gì.
Future<AddSheetChoice?> showAddTransactionSheet(BuildContext context) {
  return showModalBottomSheet<AddSheetChoice>(
    context: context,
    builder: (_) => const AddTransactionSheet(),
  );
}

/// Sheet 4 hàng: Khoản Thu / Khoản Chi / Chuyển khoản / Quét hóa đơn (AI).
/// Hàng quét **chỉ hiện khi** công tắc trong Cài đặt đang bật (FR-001/FR-003) —
/// đọc `ScanController` qua `Obx` nên đổi công tắc ở Cài đặt phản ánh ngay.
class AddTransactionSheet extends StatelessWidget {
  const AddTransactionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Text(
              'Thêm giao dịch'.tr,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _SheetRow(
            key: const ValueKey('add-sheet-income'),
            icon: Icons.south_west,
            title: 'Khoản Thu'.tr,
            subtitle: 'Lương, thưởng, thu nhập khác'.tr,
            onTap: () => Navigator.of(context).pop(AddSheetChoice.income),
          ),
          _SheetRow(
            key: const ValueKey('add-sheet-expense'),
            icon: Icons.north_east,
            title: 'Khoản Chi'.tr,
            subtitle: 'Ăn uống, mua sắm, hóa đơn...'.tr,
            onTap: () => Navigator.of(context).pop(AddSheetChoice.expense),
          ),
          _SheetRow(
            key: const ValueKey('add-sheet-transfer'),
            icon: Icons.swap_horiz,
            title: 'Chuyển khoản'.tr,
            subtitle: 'Giữa các ví/tài khoản'.tr,
            onTap: () => Navigator.of(context).pop(AddSheetChoice.transfer),
          ),
          // Hàng chỉ có khi tính năng đang bật — tắt là biến mất (FR-003).
          Obx(() {
            if (!ensureScanController().settings.value.enabled) {
              return const SizedBox.shrink();
            }
            return _SheetRow(
              key: const ValueKey('add-sheet-scan'),
              icon: Icons.photo_camera_outlined,
              title: 'Quét hóa đơn (AI)'.tr,
              subtitle: 'Tự động đọc số tiền, ngày, cửa hàng'.tr,
              badge: 'MỚI'.tr,
              onTap: () => Navigator.of(context).pop(AddSheetChoice.scan),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Một hàng của sheet: icon tròn teal nhạt + tiêu đề (+ nhãn "MỚI") + mô tả.
class _SheetRow extends StatelessWidget {
  const _SheetRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.tealLightBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colors.tealOnNeutral, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
