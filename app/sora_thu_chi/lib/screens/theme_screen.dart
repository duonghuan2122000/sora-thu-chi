import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme/theme_controller.dart';
import '../core/theme/theme_mode.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';

/// Màn con "Giao diện" (mockup `02-giao-dien.svg`, PBI 18) — màn con shell: app
/// bar "Giao diện" + back, không bottom nav (FR-001). Thân liệt kê **3 lựa
/// chọn** đúng thứ tự Sáng – Tối – Theo hệ thống: vòng nền nhạt + icon minh
/// họa, tên đậm + dòng phụ mô tả, radio tự dựng cuối hàng (R6 — không dùng
/// `RadioListTile`). Hàng đang chọn tô nền nhạt + vòng icon viền teal; chân màn
/// ghi chú lấy nguyên văn svg.
///
/// Chạm một hàng → [ThemeController.setMode] → `Rx<ThemeMode>` đổi → `SoraApp`
/// dựng lại theme **ngay** cho toàn app (FR-005), card đang chọn tự đọc lại
/// token theo theme mới. Trạng thái chọn đọc qua `Obx` nên lần đầu chưa đổi =
/// "Theo hệ thống" chọn sẵn (FR-004) và mở lại app đọc đúng giá trị đã lưu
/// (FR-006).
class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key, this.controller});

  /// Seam test: mặc định lấy controller đã đăng ký ở gốc app.
  final ThemeController? controller;

  static const _options = <({ThemeMode mode, IconData icon, String name, String subtitle})>[
    (
      mode: ThemeMode.light,
      icon: Icons.wb_sunny,
      name: 'Sáng',
      subtitle: 'Nền trắng, chữ tối',
    ),
    (
      mode: ThemeMode.dark,
      icon: Icons.dark_mode,
      name: 'Tối',
      subtitle: 'Nền tối, chữ sáng, đỡ mỏi mắt ban đêm',
    ),
    (
      mode: ThemeMode.system,
      icon: Icons.devices,
      name: 'Theo hệ thống',
      subtitle: 'Tự đổi theo cài đặt điện thoại',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = controller ?? Get.find<ThemeController>();
    return SubPageScaffold(
      title: 'Giao diện',
      child: SafeArea(
        top: false,
        child: Obx(() {
          final selected = theme.mode.value;
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              for (final option in _options) ...[
                _optionCard(context, option, selected: selected == option.mode),
                if (option != _options.last) const SizedBox(height: 12),
              ],
              const SizedBox(height: 24),
              _note(context),
            ],
          );
        }),
      ),
    );
  }

  Widget _optionCard(
    BuildContext context,
    ({ThemeMode mode, IconData icon, String name, String subtitle}) option, {
    required bool selected,
  }) {
    final colors = SoraColors.of(context);
    return InkWell(
      key: ValueKey('theme-option-${themeModeToStorage(option.mode)}'),
      borderRadius: BorderRadius.circular(10),
      onTap: () => (controller ?? Get.find<ThemeController>()).setMode(option.mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? colors.softCardBg : colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: selected ? null : Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? colors.surface : colors.softCardBg,
                border: selected
                    ? Border.all(color: AppColors.teal, width: 1.5)
                    : null,
              ),
              child: Icon(option.icon, color: colors.tealOnNeutral, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _radio(colors, selected: selected),
          ],
        ),
      ),
    );
  }

  /// Radio tự dựng (R6): chấm teal + tích trắng khi chọn, vòng viền mờ khi chưa.
  Widget _radio(SoraColors colors, {required bool selected}) {
    if (!selected) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.dotEmpty, width: 1.5),
        ),
      );
    }
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.teal,
      ),
      child: const Icon(Icons.check, color: AppColors.white, size: 13),
    );
  }

  Widget _note(BuildContext context) {
    return Text(
      'Thay đổi được áp dụng ngay lập tức, không cần khởi động lại ứng dụng.',
      style: TextStyle(color: SoraColors.of(context).textSecondary, fontSize: 11),
    );
  }
}
