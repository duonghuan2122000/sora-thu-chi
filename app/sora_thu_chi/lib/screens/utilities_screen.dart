import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';

import '../core/utilities/utilities.dart';
import '../core/utilities/utilities_store.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/utilities_deps.dart';
import '../theme/app_colors.dart';

/// Màn "Tiện ích & Cá nhân hóa" (mockup `01`, PBI 17) — màn con từ Cài đặt: app
/// bar "Tiện ích & Cá nhân hóa" + back, không bottom nav (FR-001). Thân liệt kê
/// **3 nhóm / 8 hàng** đúng mockup: HIỂN THỊ / TRẢI NGHIỆM / DỮ LIỆU & TÌM KIẾM
/// — mỗi hàng vòng nền nhạt + icon teal + tên + dòng phụ + phần cuối. Hàng
/// Widget màn hình chính hiển thị switch "bật" câm, chạm toàn hàng mở hướng dẫn
/// ghim widget theo nền tảng (R5); **2 công tắc thật** (Ẩn số dư tắt / Máy tính
/// bật — FR-006) bật/tắt + nhớ qua [UtilitiesStore] (ghi-through), nhưng chưa
/// kéo hiệu ứng màn khác (FR-007); 5 hàng điều hướng no-op chờ màn con 02–07.
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
  void _showWidgetHelp() {
    final android = defaultTargetPlatform == TargetPlatform.android;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hướng dẫn ghim widget'),
        content: Text(
          android
              ? 'App không tự ghim widget lên màn hình chính được.\n\n'
                  'Cách ghim trên Android:\n'
                  '• Chạm-giữ màn hình chính\n'
                  '• Chọn "Widgets"\n'
                  '• Kéo widget của app ra màn hình chính'
              : 'App không tự ghim widget lên màn hình chính được.\n\n'
                  'Cách ghim trên iPhone/iPad:\n'
                  '• Chạm-giữ màn hình chính\n'
                  '• Chạm nút "+" phía trên\n'
                  '• Chọn app rồi thêm widget',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SubPageScaffold(
      title: 'Tiện ích & Cá nhân hóa',
      child: SafeArea(
        top: false,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 48),
      children: [
        const _SectionLabel('HIỂN THỊ'),
        ..._rows([
          _navRow(
            icon: Icons.wb_sunny_outlined,
            name: 'Giao diện',
            subtitle: 'Sáng / Tối / Theo hệ thống',
            trailing: _trailingValue('Hệ thống'),
          ),
          _navRow(
            icon: Icons.language,
            name: 'Ngôn ngữ',
            subtitle: 'Ngôn ngữ hiển thị trong ứng dụng',
            trailing: _trailingValue('Tiếng Việt'),
          ),
          _navRow(
            icon: Icons.tune,
            name: 'Định dạng & Tiền tệ',
            subtitle: 'Ngày, tiền tệ, tuần, kỳ tài chính',
            trailing: const Icon(Icons.chevron_right, color: AppColors.tabInactive),
          ),
        ]),
        const _SectionLabel('TRẢI NGHIỆM'),
        ..._rows([
          _helpRow(
            icon: Icons.widgets_outlined,
            name: 'Widget màn hình chính',
            subtitle: 'Hiện số dư & chi tiêu hôm nay',
            trailing: const Switch(value: true, onChanged: null),
          ),
          _switchRow(
            icon: Icons.visibility_off_outlined,
            name: 'Ẩn số dư (Privacy mode)',
            subtitle: 'Che số tiền trên màn hình chính',
            value: _prefs.hideBalance,
            onChanged: _toggleHideBalance,
          ),
          _switchRow(
            icon: Icons.calculate_outlined,
            name: 'Máy tính khi nhập số tiền',
            subtitle: 'Cho phép +, -, x, / khi nhập',
            value: _prefs.amountCalculatorEnabled,
            onChanged: _toggleCalculator,
          ),
        ]),
        const _SectionLabel('DỮ LIỆU & TÌM KIẾM'),
        ..._rows([
          _navRow(
            icon: Icons.search,
            name: 'Tìm kiếm toàn cục',
            subtitle: 'Giao dịch, danh mục, ví',
            trailing: const Icon(Icons.chevron_right, color: AppColors.tabInactive),
          ),
          // Dòng phụ mô tả sạch (không `#…`/số tag giả — R4/FR-009/SC-008).
          _navRow(
            icon: Icons.sell_outlined,
            name: 'Quản lý Tag',
            subtitle: 'Gắn nhãn cho giao dịch',
            trailing: const Icon(Icons.chevron_right, color: AppColors.tabInactive),
          ),
        ]),
      ],
    );
  }

  /// Chèn [Divider] giữa các hàng trong nhóm (không sau hàng cuối — mockup 01).
  List<Widget> _rows(List<Widget> rows) {
    final out = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      out.add(rows[i]);
      if (i < rows.length - 1) {
        out.add(const Divider(color: AppColors.listDivider, height: 1));
      }
    }
    return out;
  }

  /// Hàng điều hướng (no-op — R3/FR-005): phản hồi chạm nhưng không mở màn.
  Widget _navRow({
    required IconData icon,
    required String name,
    String? subtitle,
    required Widget trailing,
  }) {
    return _itemRow(
      icon: icon,
      name: name,
      subtitle: subtitle,
      trailing: trailing,
      onTap: () {},
    );
  }

  /// Hàng Widget màn hình chính (R5): chạm toàn hàng kể cả vùng switch → dialog
  /// hướng dẫn ghim; switch "bật" câm không đảo (onChanged null).
  Widget _helpRow({
    required IconData icon,
    required String name,
    required String subtitle,
    required Widget trailing,
  }) {
    return _itemRow(
      icon: icon,
      name: name,
      subtitle: subtitle,
      trailing: trailing,
      onTap: _showWidgetHelp,
    );
  }

  /// Hàng công tắc thật — toggle ghi-through store (write-through).
  Widget _switchRow({
    required IconData icon,
    required String name,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _itemRow(
      icon: icon,
      name: name,
      subtitle: subtitle,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _itemRow({
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
            decoration: const BoxDecoration(
              color: AppColors.tealLightBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.teal, size: 20),
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
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
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
  Widget _trailingValue(String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.tabInactive, fontSize: 12),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, color: AppColors.tabInactive, size: 20),
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
        style: const TextStyle(
          color: AppColors.tabInactive,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
