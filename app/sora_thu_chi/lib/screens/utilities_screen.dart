import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/locale/locale_controller.dart';
import '../core/locale/locale_prefs.dart';
import '../core/theme/theme_controller.dart';
import '../core/theme/theme_mode.dart';
import '../core/utilities/utilities.dart';
import '../core/utilities/utilities_store.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/utilities_deps.dart';
import '../theme/sora_colors.dart';
import 'language_screen.dart';
import 'theme_screen.dart';

/// Màn "Tiện ích & Cá nhân hóa" (mockup `01`, PBI 17) — màn con từ Cài đặt: app
/// bar "Tiện ích & Cá nhân hóa" + back, không bottom nav (FR-001). Thân liệt kê
/// **3 nhóm / 8 hàng** đúng mockup: HIỂN THỊ / TRẢI NGHIỆM / DỮ LIỆU & TÌM KIẾM
/// — mỗi hàng vòng nền nhạt + icon teal + tên + dòng phụ + phần cuối. Hàng
/// Widget màn hình chính hiển thị switch "bật" câm, chạm toàn hàng mở hướng dẫn
/// ghim widget theo nền tảng (R5); **2 công tắc thật** (Ẩn số dư tắt / Máy tính
/// bật — FR-006) bật/tắt + nhớ qua [UtilitiesStore] (ghi-through), nhưng chưa
/// kéo hiệu ứng màn khác (FR-007).
///
/// Hàng "Giao diện" **đã kích hoạt** (PBI 18) và hàng "Ngôn ngữ" **đã kích
/// hoạt** (PBI 19): phần cuối đọc reactive [ThemeController]/[LocaleController]
/// (Obx) nên hiện đúng lựa chọn hiện hành — kể cả khi người dùng vừa đổi ở màn
/// 02/03 rồi quay lại (màn này vẫn mounted dưới route, FR-007); chạm hàng →
/// push `ThemeScreen`/`LanguageScreen` (FR-001). 3 hàng điều hướng còn lại vẫn
/// no-op chờ màn con 04–07. Màu màn đọc theo theme qua [SoraColors] nên giao
/// diện tối không còn vùng trắng chói.
///
/// StatefulWidget (R6) đọc store 1 lần khi mở, không GetX controller; seam
/// [store] để test bơm fake (R7). Ghi-through nối đuôi để bật/tắt nhanh không
/// để save cũ đè save mới (plan §Rủi ro — trạng thái cuối đúng lần chạm cuối).
class UtilitiesScreen extends StatefulWidget {
  const UtilitiesScreen({super.key, this.store});

  /// Seam test: mặc định null → [ensureUtilitiesStore] khi vào.
  final UtilitiesStore? store;

  @override
  State<UtilitiesScreen> createState() => _UtilitiesScreenState();
}

class _UtilitiesScreenState extends State<UtilitiesScreen> {
  late final UtilitiesStore _store;
  UtilitiesPrefs _prefs = const UtilitiesPrefs();
  bool _loading = true;
  String? _error;

  /// Nối đuôi các lần save — bật/tắt liên tiếp ghi tuần tự, save cuối cùng
  /// (trạng thái mới nhất) luôn là lần ghi cuối (không lẫn trường khác).
  Future<void> _saveTail = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? ensureUtilitiesStore();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await _store.load();
      if (!mounted) return;
      setState(() {
        _prefs = prefs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không đọc được cài đặt.';
        _loading = false;
      });
    }
  }

  void _setPrefs(UtilitiesPrefs next) {
    setState(() => _prefs = next);
    _saveTail = _saveTail.then((_) async {
      try {
        await _store.save(next);
      } catch (_) {
        // Ghi lỗi bỏ qua — lần chạm sau ghi lại toàn trạng thái mới nhất.
      }
    });
  }

  void _toggleHideBalance(bool value) =>
      _setPrefs(_prefs.copyWith(hideBalance: value));

  void _toggleCalculator(bool value) =>
      _setPrefs(_prefs.copyWith(amountCalculatorEnabled: value));

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
          _navRow(
            colors: colors,
            icon: Icons.tune,
            name: 'Định dạng & Tiền tệ'.tr,
            subtitle: 'Ngày, tiền tệ, tuần, kỳ tài chính'.tr,
            trailing: Icon(Icons.chevron_right, color: colors.tabInactive),
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
          _switchRow(
            colors: colors,
            icon: Icons.visibility_off_outlined,
            name: 'Ẩn số dư (Privacy mode)'.tr,
            subtitle: 'Che số tiền trên màn hình chính'.tr,
            value: _prefs.hideBalance,
            onChanged: _toggleHideBalance,
          ),
          _switchRow(
            colors: colors,
            icon: Icons.calculate_outlined,
            name: 'Máy tính khi nhập số tiền'.tr,
            subtitle: 'Cho phép +, -, x, / khi nhập'.tr,
            value: _prefs.amountCalculatorEnabled,
            onChanged: _toggleCalculator,
          ),
        ]),
        _SectionLabel('DỮ LIỆU & TÌM KIẾM'.tr),
        ..._rows(colors, [
          _navRow(
            colors: colors,
            icon: Icons.search,
            name: 'Tìm kiếm toàn cục'.tr,
            subtitle: 'Giao dịch, danh mục, ví'.tr,
            trailing: Icon(Icons.chevron_right, color: colors.tabInactive),
          ),
          // Dòng phụ mô tả sạch (không `#…`/số tag giả — R4/FR-009/SC-008).
          _navRow(
            colors: colors,
            icon: Icons.sell_outlined,
            name: 'Quản lý Tag'.tr,
            subtitle: 'Gắn nhãn cho giao dịch'.tr,
            trailing: Icon(Icons.chevron_right, color: colors.tabInactive),
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
