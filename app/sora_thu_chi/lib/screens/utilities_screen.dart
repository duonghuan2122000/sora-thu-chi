import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/locale/locale_controller.dart';
import '../core/locale/locale_prefs.dart';
import '../core/privacy/privacy_controller.dart';
import '../core/theme/theme_controller.dart';
import '../core/theme/theme_mode.dart';
import '../core/utilities/utilities_store.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/privacy_deps.dart';
import '../theme/sora_colors.dart';
import 'language_screen.dart';
import 'theme_screen.dart';

/// Màn "Tiện ích & Cá nhân hóa" (mockup `01`, PBI 17) — màn con từ Cài đặt: app
/// bar "Tiện ích & Cá nhân hóa" + back, không bottom nav (FR-001). Thân liệt kê
/// **2 nhóm / 5 hàng**: HIỂN THỊ (Giao diện, Ngôn ngữ) / TRẢI NGHIỆM (Widget
/// màn hình chính, Ẩn số dư, Máy tính) — 3 hàng chưa có tính năng thật (Định
/// dạng & Tiền tệ, Tìm kiếm toàn cục, Quản lý Tag) đã bị ẩn khỏi UI (PBI 45)
/// cho tới khi implement xong. Mỗi hàng vòng nền nhạt + icon teal + tên + dòng
/// phụ + phần cuối. Hàng Widget màn hình chính hiển thị switch "bật" câm, chạm
/// toàn hàng mở hướng dẫn ghim widget theo nền tảng (R5); **2 công tắc thật**
/// (Ẩn số dư tắt / Máy tính bật — FR-006) bật/tắt + nhớ qua [PrivacyController]
/// (ghi-through) — "Ẩn số dư" nay có tác dụng thật ở màn Tổng quan (PBI 48).
///
/// Hàng "Giao diện" **đã kích hoạt** (PBI 18) và hàng "Ngôn ngữ" **đã kích
/// hoạt** (PBI 19): phần cuối đọc reactive [ThemeController]/[LocaleController]
/// (Obx) nên hiện đúng lựa chọn hiện hành — kể cả khi người dùng vừa đổi ở màn
/// 02/03 rồi quay lại (màn này vẫn mounted dưới route, FR-007); chạm hàng →
/// push `ThemeScreen`/`LanguageScreen` (FR-001). Màu màn đọc theo theme qua
/// [SoraColors] nên giao diện tối không còn vùng trắng chói.
///
/// StatefulWidget (R6) đọc controller 1 lần khi mở; seam [store] để test bơm
/// fake (R7) — khi truyền, dựng [PrivacyController] cục bộ riêng cho màn thay
/// vì singleton Get, giữ test cô lập như trước (PBI 48). Không truyền → dùng
/// chung [ensurePrivacyController] với Tổng quan (nguồn chân lý duy nhất của
/// "Ẩn số dư"/"Máy tính" — PBI 48 research R2), nên bật/tắt ở màn này hay ở
/// icon mắt Tổng quan luôn khớp nhau ngay.
class UtilitiesScreen extends StatefulWidget {
  const UtilitiesScreen({super.key, this.store});

  /// Seam test: mặc định null → [ensurePrivacyController] khi vào.
  final UtilitiesStore? store;

  @override
  State<UtilitiesScreen> createState() => _UtilitiesScreenState();
}

class _UtilitiesScreenState extends State<UtilitiesScreen> {
  late final PrivacyController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = widget.store != null
        ? PrivacyController(widget.store!)
        : ensurePrivacyController();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _controller.load();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không đọc được cài đặt.';
        _loading = false;
      });
    }
  }

  /// Hướng dẫn ghim widget — việc ghim do hệ điều hành quản lý (R5/FR-008).
  /// Ghép từng dòng đã dịch (không nối chuỗi thủ công) để mỗi dòng là một khóa
  /// dịch riêng.
  void _showWidgetHelp() {
    final android = defaultTargetPlatform == TargetPlatform.android;
    final steps = android
        ? const [
            'Cách ghim trên Android:',
            '• Chạm-giữ màn hình chính',
            '• Chọn "Widgets"',
            '• Kéo widget của app ra màn hình chính',
          ]
        : const [
            'Cách ghim trên iPhone/iPad:',
            '• Chạm-giữ màn hình chính',
            '• Chạm nút "+" phía trên',
            '• Chọn app rồi thêm widget',
          ];
    final body = [
      'App không tự ghim widget lên màn hình chính được.',
      '',
      ...steps,
    ].map((line) => line.isEmpty ? '' : line.tr).join('\n');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hướng dẫn ghim widget'.tr),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Đóng'.tr),
          ),
        ],
      ),
    );
  }

  /// Mở màn con "Giao diện" (màn 02) — điểm vào no-op của PBI 17 nay kích hoạt.
  void _openThemeScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ThemeScreen()),
    );
  }

  /// Mở màn con "Ngôn ngữ" (màn 03) — điểm vào no-op của PBI 17 nay kích hoạt.
  void _openLanguageScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LanguageScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SubPageScaffold(
      title: 'Tiện ích & Cá nhân hóa'.tr,
      child: SafeArea(
        top: false,
        child: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final colors = SoraColors.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!.tr, style: TextStyle(color: colors.textPrimary)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: Text('Thử lại'.tr)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 48),
      children: [
        _SectionLabel('HIỂN THỊ'.tr),
        ..._rows(colors, [
          _navRow(
            colors: colors,
            icon: Icons.wb_sunny_outlined,
            name: 'Giao diện'.tr,
            subtitle: 'Sáng / Tối / Theo hệ thống'.tr,
            trailing: Obx(
              () => _trailingValue(
                colors,
                themeModeLabel(Get.find<ThemeController>().mode.value),
              ),
            ),
            onTap: _openThemeScreen,
          ),
          _navRow(
            colors: colors,
            icon: Icons.language,
            name: 'Ngôn ngữ'.tr,
            subtitle: 'Ngôn ngữ hiển thị trong ứng dụng'.tr,
            trailing: Obx(
              () => _trailingValue(
                colors,
                localeEndonym(Get.find<LocaleController>().locale.value),
              ),
            ),
            onTap: _openLanguageScreen,
          ),
        ]),
        _SectionLabel('TRẢI NGHIỆM'.tr),
        ..._rows(colors, [
          _helpRow(
            colors: colors,
            icon: Icons.widgets_outlined,
            name: 'Widget màn hình chính'.tr,
            subtitle: 'Hiện số dư & chi tiêu hôm nay'.tr,
            trailing: const Switch(value: true, onChanged: null),
          ),
          Obx(
            () => _switchRow(
              colors: colors,
              icon: Icons.visibility_off_outlined,
              name: 'Ẩn số dư (Privacy mode)'.tr,
              subtitle: 'Che số tiền trên màn hình chính'.tr,
              value: _controller.hideBalance.value,
              onChanged: _controller.setHideBalance,
            ),
          ),
          Obx(
            () => _switchRow(
              colors: colors,
              icon: Icons.calculate_outlined,
              name: 'Máy tính khi nhập số tiền'.tr,
              subtitle: 'Cho phép +, -, x, / khi nhập'.tr,
              value: _controller.amountCalculatorEnabled.value,
              onChanged: _controller.setAmountCalculatorEnabled,
            ),
          ),
        ]),
      ],
    );
  }

  /// Chèn [Divider] giữa các hàng trong nhóm (không sau hàng cuối — mockup 01).
  List<Widget> _rows(SoraColors colors, List<Widget> rows) {
    final out = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      out.add(rows[i]);
      if (i < rows.length - 1) {
        out.add(Divider(color: colors.listDivider, height: 1));
      }
    }
    return out;
  }

  /// Hàng điều hướng (mặc định no-op — R3/FR-005): phản hồi chạm nhưng không mở
  /// màn; hàng "Giao diện" truyền [onTap] để mở màn 02.
  Widget _navRow({
    required SoraColors colors,
    required IconData icon,
    required String name,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return _itemRow(
      colors: colors,
      icon: icon,
      name: name,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap ?? () {},
    );
  }

  /// Hàng Widget màn hình chính (R5): chạm toàn hàng kể cả vùng switch → dialog
  /// hướng dẫn ghim; switch "bật" câm không đảo (onChanged null).
  Widget _helpRow({
    required SoraColors colors,
    required IconData icon,
    required String name,
    required String subtitle,
    required Widget trailing,
  }) {
    return _itemRow(
      colors: colors,
      icon: icon,
      name: name,
      subtitle: subtitle,
      trailing: trailing,
      onTap: _showWidgetHelp,
    );
  }

  /// Hàng công tắc thật — toggle ghi-through store (write-through).
  Widget _switchRow({
    required SoraColors colors,
    required IconData icon,
    required String name,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _itemRow(
      colors: colors,
      icon: icon,
      name: name,
      subtitle: subtitle,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _itemRow({
    required SoraColors colors,
    required IconData icon,
    required String name,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final inner = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.tealLightBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colors.tealOnNeutral, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
    final handler = onTap;
    if (handler == null) return inner;
    return InkWell(onTap: handler, child: inner);
  }

  /// Giá trị hiện hành + chevron (hàng Giao diện/Ngôn ngữ — FR-004). Text giá
  /// trị giới hạn width (chống tràn ngang cỡ chữ lớn — FR-010), tự cắt ellipsis.
  Widget _trailingValue(SoraColors colors, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.tabInactive, fontSize: 12),
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right, color: colors.tabInactive, size: 20),
      ],
    );
  }
}

/// Tiêu đề nhóm viết hoa (HIỂN THỊ / TRẢI NGHIỆM / DỮ LIỆU & TÌM KIẾM) — màu mờ.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        text,
        style: TextStyle(
          color: SoraColors.of(context).tabInactive,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
