import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/date_label.dart';
import '../core/notification/notification_prefs.dart';
import '../core/notification/notification_store.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/notification_deps.dart';
import '../theme/sora_colors.dart';
import 'daily_reminder_config_screen.dart';

/// Màn "Thông báo & nhắc nhở" (mockup `01`, PBI 28) — màn con từ Cài đặt: app
/// bar + nút back, **không** bottom nav, **không** FAB (FR-002).
///
/// Thân liệt kê **5 nhóm / 8 hàng** đúng mockup: NHẮC NHỞ HÀNG NGÀY (1 hàng) →
/// NGÂN SÁCH (2 hàng) → GIAO DỊCH ĐỊNH KỲ (2 hàng) → MỤC TIÊU TIẾT KIỆM (1) →
/// TỔNG KẾT TỰ ĐỘNG (2). Mỗi hàng có **đúng một** điều khiển: **6 công tắc**
/// thật (bật/tắt độc lập, không có công tắc "bật/tắt tất cả") + **2 hàng chevron
/// chạm không mở gì** (điểm nối cho PBI chỉnh tham số — chốt Q2=A, FR-011).
/// Dòng phụ đọc **từ cấu hình đã nạp**, không hằng cứng trong widget (FR-009).
///
/// Đợt này **chỉ ghi nhận cấu hình**: không xin quyền, không bắn thông báo nào
/// (FR-012). StatefulWidget + seam [store] bơm được (khuôn `UtilitiesScreen`) —
/// test dùng fake nên không cần sqlite native; ghi bám đuôi `_saveTail` để
/// bật/tắt liên tiếp không bị save cũ đè save mới.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key, this.store});

  /// Seam test: mặc định null → [ensureNotificationStore] khi vào.
  final NotificationStore? store;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late final NotificationStore _store;
  NotificationPrefs _prefs = NotificationPrefs.defaults;
  bool _loading = true;
  String? _error;

  /// Nối đuôi các lần save — bật/tắt liên tiếp ghi tuần tự, trạng thái mới nhất
  /// luôn là lần ghi cuối.
  Future<void> _saveTail = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? ensureNotificationStore();
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
      // Ghi lại nguyên khối vừa đọc (idempotent): lần mở đầu tiên trên máy chưa
      // từng cấu hình ⇒ bộ mặc định FR-008 **được lưu ngay**, không chờ thao tác
      // (FR-007/kịch bản 6). Đọc-rồi-ghi cũng chuẩn hoá giá trị lạ về miền hợp lệ.
      _saveTail = _saveTail.then((_) => _store.save(_prefs));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không đọc được cài đặt.';
        _loading = false;
      });
    }
  }

  void _setPrefs(NotificationPrefs next) {
    setState(() => _prefs = next);
    _saveTail = _saveTail.then((_) async {
      try {
        await _store.save(next);
      } catch (_) {
        // Ghi lỗi bỏ qua — lần chạm sau ghi lại toàn trạng thái mới nhất.
      }
    });
  }

  // Mỗi handler chỉ chạm **một** trường ⇒ không có cơ chế "bật/tắt tất cả"
  // (FR-006/FR-010). Tắt một loại không reset tham số của loại đó.
  void _toggleDaily(bool value) =>
      _setPrefs(_prefs.copyWith(dailyEnabled: value));

  void _toggleBudget(bool value) =>
      _setPrefs(_prefs.copyWith(budgetEnabled: value));

  void _toggleRecurring(bool value) =>
      _setPrefs(_prefs.copyWith(recurringEnabled: value));

  void _toggleGoal(bool value) =>
      _setPrefs(_prefs.copyWith(goalEnabled: value));

  void _toggleWeekly(bool value) =>
      _setPrefs(_prefs.copyWith(weeklyEnabled: value));

  void _toggleMonthly(bool value) =>
      _setPrefs(_prefs.copyWith(monthlyEnabled: value));

  /// Mở màn cấu hình nhắc hàng ngày, truyền **chính** store của màn này (giữ
  /// đúng 1 connection drift; test bơm fake qua màn `01` được).
  Future<void> _openDailyConfig() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DailyReminderConfigScreen(store: _store),
      ),
    );
    if (!mounted) return;
    // Về màn `01`: đọc lại để dòng phụ phản ánh giá trị vừa lưu (FR-011, kịch
    // bản 13/14) — chỉ đọc, không ghi lại như lúc mở màn.
    try {
      final prefs = await _store.load();
      if (!mounted) return;
      setState(() => _prefs = prefs);
    } catch (_) {
      // Đọc lỗi: giữ nguyên trạng thái đang hiển thị.
    }
  }

  @override
  Widget build(BuildContext context) {
    return SubPageScaffold(
      title: 'Thông báo & nhắc nhở'.tr,
      child: SafeArea(top: false, child: _body(context)),
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
        _SectionLabel('NHẮC NHỞ HÀNG NGÀY'.tr),
        ..._rows(colors, [
          _switchRow(
            colors: colors,
            icon: Icons.notifications_none,
            name: 'Nhắc nhập giao dịch hằng ngày'.tr,
            subtitle: _dailySubtitle(),
            value: _prefs.dailyEnabled,
            onChanged: _toggleDaily,
            onTap: _openDailyConfig,
          ),
        ]),
        _SectionLabel('NGÂN SÁCH'.tr),
        ..._rows(colors, [
          _switchRow(
            colors: colors,
            icon: Icons.warning_amber_rounded,
            name: 'Cảnh báo vượt ngân sách'.tr,
            subtitle: 'Khi đạt @sớm% và khi vượt @vượt%'.trParams({
              'sớm': '${_prefs.budgetEarlyPercent}',
              'vượt': '${_prefs.budgetOverPercent}',
            }),
            value: _prefs.budgetEnabled,
            onChanged: _toggleBudget,
            coral: true,
          ),
          _navRow(
            colors: colors,
            icon: Icons.warning_amber_rounded,
            name: 'Ngưỡng cảnh báo'.tr,
            subtitle: 'Sớm: @sớm% · Vượt mức: @vượt%'.trParams({
              'sớm': '${_prefs.budgetEarlyPercent}',
              'vượt': '${_prefs.budgetOverPercent}',
            }),
            coral: true,
          ),
        ]),
        _SectionLabel('GIAO DỊCH ĐỊNH KỲ'.tr),
        ..._rows(colors, [
          _switchRow(
            colors: colors,
            icon: Icons.event_outlined,
            name: 'Nhắc hóa đơn sắp đến hạn'.tr,
            subtitle: 'Tiền điện, tiền nhà, trả nợ...'.tr,
            value: _prefs.recurringEnabled,
            onChanged: _toggleRecurring,
          ),
          _navRow(
            colors: colors,
            icon: Icons.event_outlined,
            name: 'Nhắc trước'.tr,
            subtitle: '@n ngày trước hạn thanh toán'.trParams({
              'n': '${_prefs.recurringDaysBefore}',
            }),
          ),
        ]),
        _SectionLabel('MỤC TIÊU TIẾT KIỆM'.tr),
        ..._rows(colors, [
          _switchRow(
            colors: colors,
            icon: Icons.track_changes,
            name: 'Nhắc đóng góp mục tiêu'.tr,
            subtitle: 'Theo chu kỳ đã đặt cho từng mục tiêu'.tr,
            value: _prefs.goalEnabled,
            onChanged: _toggleGoal,
          ),
        ]),
        _SectionLabel('TỔNG KẾT TỰ ĐỘNG'.tr),
        ..._rows(colors, [
          _switchRow(
            colors: colors,
            icon: Icons.pie_chart_outline,
            name: 'Tổng kết cuối tuần'.tr,
            subtitle: 'Chủ nhật hằng tuần, @giờ'.trParams({
              'giờ': formatClock(_prefs.weeklyHour, _prefs.weeklyMinute),
            }),
            value: _prefs.weeklyEnabled,
            onChanged: _toggleWeekly,
          ),
          _switchRow(
            colors: colors,
            icon: Icons.pie_chart_outline,
            name: 'Tổng kết cuối tháng'.tr,
            subtitle: 'Ngày cuối tháng, @giờ'.trParams({
              'giờ': formatClock(_prefs.monthlyHour, _prefs.monthlyMinute),
            }),
            value: _prefs.monthlyEnabled,
            onChanged: _toggleMonthly,
          ),
        ]),
      ],
    );
  }

  /// Dòng phụ hàng nhắc hàng ngày — ghép **2 khoá dịch** (không nối chuỗi thủ
  /// công vào giữa khoá) để trật tự từ dịch được theo từng ngôn ngữ. Đủ 7 ngày
  /// giữ chuỗi "mỗi ngày" (PBI 28 không đổi); thiếu ngày → liệt kê tập ngày đã
  /// nén dải (FR-011).
  String _dailySubtitle() {
    final clock = _prefs.isEveryDay
        ? '@giờ mỗi ngày'.trParams({
            'giờ': formatClock(_prefs.dailyHour, _prefs.dailyMinute),
          })
        : '@giờ vào @ngày'.trParams({
            'giờ': formatClock(_prefs.dailyHour, _prefs.dailyMinute),
            'ngày': daysLabel(_prefs.dailyWeekdays),
          });
    if (!_prefs.dailyOnlyIfNoTxnToday) return clock;
    return '$clock${' · chỉ nhắc nếu chưa ghi'.tr}';
  }

  /// Chèn [Divider] **giữa** các hàng trong nhóm (không sau hàng cuối, không
  /// trước nhãn nhóm — khuôn màn Tiện ích, quickstart §4.1).
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

  Widget _switchRow({
    required SoraColors colors,
    required IconData icon,
    required String name,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool coral = false,
    VoidCallback? onTap,
  }) {
    return _itemRow(
      colors: colors,
      icon: icon,
      name: name,
      subtitle: subtitle,
      coral: coral,
      trailing: Switch(value: value, onChanged: onChanged),
      onTap: onTap,
    );
  }

  /// Hàng chevron: chạm **không mở gì** (0 route, 0 thông báo lỗi — FR-011);
  /// vẫn có phản hồi mực như mọi hàng điều hướng hiện có.
  Widget _navRow({
    required SoraColors colors,
    required IconData icon,
    required String name,
    required String subtitle,
    bool coral = false,
  }) {
    return _itemRow(
      colors: colors,
      icon: icon,
      name: name,
      subtitle: subtitle,
      coral: coral,
      trailing: Icon(Icons.chevron_right, color: colors.tabInactive),
      onTap: () {},
    );
  }

  /// Hàng danh sách: vòng tròn 36 px + tiêu đề (1 dòng, ellipsis) + dòng phụ
  /// wrap tự nhiên; `trailing` nằm **ngoài** `Expanded` nên cỡ chữ lớn không
  /// đè lên điều khiển (FR-017). [coral] dành **riêng** nhóm NGÂN SÁCH (FR-004).
  ///
  /// [onTap] (FR-001) đặt **hai** vùng chạm tách biệt trên **một** hàng: icon và
  /// khối tiêu đề/dòng phụ cùng gọi [onTap], còn `trailing` (công tắc/chevron)
  /// nằm **ngoài** mọi `InkWell` — chạm công tắc **không** mở màn con.
  Widget _itemRow({
    required SoraColors colors,
    required IconData icon,
    required String name,
    required String subtitle,
    required Widget trailing,
    bool coral = false,
    VoidCallback? onTap,
  }) {
    final iconCircle = Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: coral ? colors.coralLightBg : colors.tealLightBg,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: coral ? colors.coralOnNeutral : colors.tealOnNeutral,
        size: 20,
      ),
    );
    final texts = Column(
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
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
      ],
    );
    final handler = onTap;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          if (handler == null)
            iconCircle
          else
            InkWell(
              onTap: handler,
              customBorder: const CircleBorder(),
              child: iconCircle,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: handler == null
                ? texts
                : InkWell(onTap: handler, child: texts),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

/// Nhãn nhóm viết hoa (NHẮC NHỞ HÀNG NGÀY / NGÂN SÁCH / …) — màu mờ.
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
