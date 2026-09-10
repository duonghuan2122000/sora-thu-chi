import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/locale/locale_controller.dart';
import '../core/locale/locale_prefs.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';

/// Màn con "Ngôn ngữ" (mockup `docs/tool/03-ngon-ngu.svg`, PBI 19) — màn con
/// shell: app bar "Ngôn ngữ" + back, không bottom nav (FR-001). Thân liệt kê
/// **2 lựa chọn** đúng thứ tự Tiếng Việt – English: vòng tròn mã `VI`/`EN`, tên
/// ngôn ngữ đậm + dòng phụ là tên ngôn ngữ kia, radio tự dựng cuối hàng (bám
/// màn `02`, không dùng `RadioListTile`). 4 chuỗi tên/dòng phụ là **hằng số**
/// (R8 — tên riêng của ngôn ngữ, không dịch); chỉ tiêu đề app bar và ghi chú
/// chân màn đi qua `.tr`.
///
/// Chạm một hàng → [LocaleController.setLocale] → `Rx<Locale>` đổi + reassemble
/// toàn app (FR-005), nên nhãn màn đang mở, chrome và mọi màn khác đổi ngay
/// không cần khởi động lại. Trạng thái chọn đọc qua `Obx`; lựa chọn được ghi
/// xuống `AppSettings` nên mở lại app vẫn đúng (FR-006).
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key, this.controller});

  /// Seam test: mặc định lấy controller đã đăng ký ở gốc app.
  final LocaleController? controller;

  LocaleController get _controller => controller ?? Get.find<LocaleController>();

  @override
  Widget build(BuildContext context) {
    return SubPageScaffold(
      title: 'Ngôn ngữ'.tr,
      child: SafeArea(
        top: false,
        child: Obx(() {
          final selected = _controller.locale.value;
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              for (final option in kLanguageOptions) ...[
                _optionCard(context, option, selected: selected == option.locale),
                if (option != kLanguageOptions.last) const SizedBox(height: 12),
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
    LanguageOption option, {
    required bool selected,
  }) {
    final colors = SoraColors.of(context);
    return InkWell(
      key: ValueKey('language-option-${option.locale.languageCode}'),
      borderRadius: BorderRadius.circular(10),
      onTap: () => _controller.setLocale(option.locale),
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
                color: selected ? AppColors.teal : colors.softCardBg,
              ),
              child: Text(
                option.code,
                style: TextStyle(
                  color: selected ? AppColors.white : colors.tealOnNeutral,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.endonym,
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
                    option.otherName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

  /// Radio tự dựng: chấm teal + tích trắng khi chọn, vòng viền mờ khi chưa.
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
      'Áp dụng ngay cho toàn bộ giao diện, nhãn danh mục mặc định và định dạng ngày/số vẫn giữ theo cài đặt Định dạng & Tiền tệ.'.tr,
      style: TextStyle(color: SoraColors.of(context).textSecondary, fontSize: 11),
    );
  }
}
