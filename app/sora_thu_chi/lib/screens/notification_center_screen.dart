import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/notification/app_notification.dart';
import '../core/notification/notification_history_store.dart';
import '../core/notification/notification_tap.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/notification_history_deps.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';
import 'notification_settings_screen.dart';

/// Màn "Thông báo" (mockup `03`, PBI 30) — màn con: app bar teal + back + bánh
/// răng, **không** bottom nav, **không** FAB (FR-002).
///
/// Đọc lịch sử **một lần** khi mở màn (1 truy vấn, ≤ [kMaxNotifications] dòng)
/// rồi lọc tab **trong bộ nhớ** (FR-003/FR-017). Màn **chỉ** đọc thêm và cập
/// nhật `read_at`: không tạo/sửa/xoá dữ liệu nghiệp vụ nào, không xin quyền,
/// không bắn thông báo (FR-012/FR-013).
///
/// `title`/`body` của bản ghi là **snapshot** do engine sinh lúc bắn ⇒ hiển thị
/// nguyên văn, **không** `.tr` (FR-014).
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({
    super.key,
    this.store,
    this.onSelectTab,
    this.now,
  });

  /// Seam test: mặc định null → [ensureNotificationHistoryStore] khi vào.
  final NotificationHistoryStore? store;

  /// Đích "tổng kết kỳ" là tab Báo cáo **trong shell** — shell bơm xuống.
  final ValueChanged<int>? onSelectTab;

  /// Mốc "bây giờ" — test bơm cố định, chạy thật lấy giờ hệ thống.
  final DateTime? now;

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

/// 2 tab lọc của màn (FR-003) — lọc trong bộ nhớ, không truy vấn lại.
enum _Tab { all, unread }

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  late final NotificationHistoryStore _store;
  List<AppNotification> _items = const [];
  _Tab _tab = _Tab.all;
  bool _loading = true;
  String? _error;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? ensureNotificationHistoryStore();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _store.loadRecent();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không đọc được thông báo.';
        _loading = false;
      });
    }
  }

  List<AppNotification> get _visible => _tab == _Tab.unread
      ? _items.where((n) => !n.isRead).toList()
      : _items;

  /// Chạm mục (FR-007, R11): đánh dấu đã đọc **trước** (lưu bền), rồi mới điều
  /// hướng — loại không có màn đích vẫn được đánh dấu, chỉ là không đi đâu.
  Future<void> _open(AppNotification item) async {
    if (!item.isRead) {
      try {
        await _store.markRead(item.id, _now);
      } catch (_) {
        // Ghi lỗi không chặn điều hướng — mục khác không bị ảnh hưởng.
      }
      if (!mounted) return;
      setState(() {
        _items = [
          for (final n in _items)
            n.id == item.id ? n.copyWith(readAt: _now) : n,
        ];
      });
    }
    if (!mounted) return;
    await _navigate(item);
  }

  /// Đích theo `kind` (FR-008) — bảng đích dùng **chung** với engine thông báo
  /// (PBI 31) qua `notification_tap.dart`, nên hai đường vào không thể lệch.
  /// Loại chưa có màn đích và cảnh báo thiếu `relatedId` → **im lặng**: 0 route,
  /// 0 SnackBar, 0 dialog.
  Future<void> _navigate(AppNotification item) {
    return openNotificationTarget(
      target: notificationTargetFor(
        kind: item.kind,
        relatedId: item.relatedId,
      ),
      relatedId: item.relatedId,
      onSelectTab: widget.onSelectTab,
      context: context,
    );
  }

  /// Bánh răng → màn `01` "Thông báo & nhắc nhở" (PBI 28).
  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationSettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return SubPageScaffold(
      title: 'Thông báo'.tr,
      actions: [
        IconButton(
          key: const ValueKey('notification-settings-entry'),
          tooltip: 'Mở cài đặt thông báo'.tr,
          icon: const Icon(Icons.settings_outlined),
          onPressed: _openSettings,
        ),
      ],
      child: Column(
        children: [
          _TabBar(
            colors: colors,
            selected: _tab,
            onChanged: (tab) => setState(() => _tab = tab),
          ),
          Expanded(child: _body(colors)),
        ],
      ),
    );
  }

  Widget _body(SoraColors colors) {
    if (_loading) return const Center(child: CircularProgressIndicator());
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
    // Lịch sử rỗng → câu chung; tab "Chưa đọc" rỗng (mà lịch sử có mục) →
    // câu **riêng** (FR-011, SC-007).
    if (_items.isEmpty) {
      return _EmptyState(
        colors: colors,
        title: 'Chưa có thông báo nào'.tr,
        subtitle: 'Thông báo và nhắc nhở sẽ hiện ở đây.'.tr,
      );
    }
    if (_visible.isEmpty) {
      return _EmptyState(
        colors: colors,
        title: 'Không có thông báo chưa đọc'.tr,
        subtitle: 'Bạn đã đọc hết thông báo.'.tr,
      );
    }
    return ListView(children: _grouped(colors));
  }

  /// Nhóm theo thời gian, **chỉ** vẽ nhóm có mục (FR-011), đúng thứ tự
  /// HÔM NAY → TUẦN NÀY → TRƯỚC ĐÓ.
  List<Widget> _grouped(SoraColors colors) {
    final out = <Widget>[];
    for (final group in NotificationGroup.values) {
      final items = _visible
          .where((n) => notificationGroup(n.createdAt, _now) == group)
          .toList();
      if (items.isEmpty) continue;
      out.add(_GroupLabel(colors: colors, group: group));
      for (final item in items) {
        out.add(
          _NotificationTile(
            colors: colors,
            item: item,
            now: _now,
            onTap: () => _open(item),
          ),
        );
      }
    }
    return out;
  }
}

/// Hàng 2 tab tự vẽ (R7) — nhãn đang chọn teal w600 + gạch chân 2 px teal; kẻ
/// `listDivider` chạy ngang dưới hàng. Không `TabBar`/`TabController`: đổi tab
/// chỉ là 1 `setState` lọc trong bộ nhớ.
class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.colors,
    required this.selected,
    required this.onChanged,
  });

  final SoraColors colors;
  final _Tab selected;
  final ValueChanged<_Tab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 14),
          // Cỡ chữ lớn: co cả hàng tab xuống thay vì tràn (khuôn `_HeaderSummary`
          // màn Báo cáo) — gạch chân vẫn theo bề rộng chữ.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tab(
                  'Tất cả'.tr,
                  _Tab.all,
                  const ValueKey('notification-tab-all'),
                ),
                const SizedBox(width: 24),
                _tab(
                  'Chưa đọc'.tr,
                  _Tab.unread,
                  const ValueKey('notification-tab-unread'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 1),
        Container(height: 1, color: colors.listDivider),
      ],
    );
  }

  Widget _tab(String label, _Tab value, Key key) {
    final active = selected == value;
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.teal : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? AppColors.teal : colors.tabInactive,
          ),
        ),
      ),
    );
  }
}

/// Nhãn nhóm thời gian (HÔM NAY / TUẦN NÀY / TRƯỚC ĐÓ) — chữ hoa cỡ nhỏ, màu mờ.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.colors, required this.group});

  final SoraColors colors;
  final NotificationGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        group.label,
        style: TextStyle(
          color: colors.tabInactive,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Một mục trong danh sách (FR-005): chấm 8 px (chỉ khi chưa đọc) → vòng tròn
/// 36 px + glyph theo loại → tiêu đề + nhãn thời gian cùng hàng → dòng mô tả
/// **wrap tự nhiên** (không `maxLines` — số liệu không bị cắt, FR-016).
///
/// Chấm đã đọc vẫn chiếm đúng 8 px để hàng không xô lệch; mục đã đọc khác mục
/// chưa đọc ở **cả** chấm **lẫn** độ đậm/màu chữ.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.colors,
    required this.item,
    required this.now,
    required this.onTap,
  });

  final SoraColors colors;
  final AppNotification item;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !item.isRead;
    final coral = item.kind == NotificationKind.budgetAlert;
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  // Canh chấm vào tâm vòng tròn 36 px bên cạnh.
                  padding: const EdgeInsets.only(top: 14),
                  child: SizedBox(
                    width: 8,
                    height: 8,
                    child: unread
                        ? const DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.teal,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: coral ? colors.coralLightBg : colors.tealLightBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconFor(item.kind),
                    color: coral
                        ? colors.coralOnNeutral
                        : colors.tealOnNeutral,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              // Nội dung bản ghi = snapshot, không dịch lại.
                              item.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    unread ? FontWeight.w600 : FontWeight.w400,
                                color: unread
                                    ? colors.textPrimary
                                    : colors.listLabel,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            notificationTimeLabel(item.createdAt, now),
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.tabInactive,
                            ),
                          ),
                        ],
                      ),
                      if (item.body.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.body,
                          style: TextStyle(
                            fontSize: 12,
                            color: unread
                                ? colors.textSecondary
                                : colors.tabInactive,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: colors.listDivider,
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
        ],
      ),
    );
  }
}

/// Trạng thái rỗng (FR-011): biểu tượng trung tính + câu chính + câu phụ.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.colors,
    required this.title,
    required this.subtitle,
  });

  final SoraColors colors;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 44,
              color: colors.tabInactive,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.tabInactive, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon theo loại (FR-006, R10) — bám bộ icon màn `01` (PBI 28).
IconData _iconFor(NotificationKind kind) => switch (kind) {
  NotificationKind.dailyReminder => Icons.notifications_none,
  NotificationKind.budgetAlert => Icons.warning_amber_rounded,
  NotificationKind.recurringDue => Icons.event_outlined,
  NotificationKind.goalReminder => Icons.track_changes,
  NotificationKind.periodSummary => Icons.pie_chart_outline,
};
