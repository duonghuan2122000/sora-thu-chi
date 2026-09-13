import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/notification/notification_history_store.dart';
import '../core/widgets/screen_header.dart';
import '../data/notification_history_deps.dart';
import '../theme/app_colors.dart';
import 'notification_center_screen.dart';

/// Màn Tổng quan — hiện có vùng tiêu đề teal + **chuông thông báo** (FR-001);
/// nội dung nghiệp vụ gắn sau (PBI module).
///
/// Chấm đỏ là state **cục bộ** ([_unread]) chứ không GetX controller: trạng thái
/// đọc chỉ đổi được ở màn Trung tâm, mà màn đó mở từ chính màn này ⇒ `await
/// push` rồi đếm lại là đúng và đủ (research R5).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.store, this.onSelectTab});

  /// Seam test: mặc định null → [ensureNotificationHistoryStore] khi vào.
  final NotificationHistoryStore? store;

  /// Đích "tổng kết kỳ" là tab Báo cáo **trong shell** — shell bơm xuống.
  final ValueChanged<int>? onSelectTab;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final NotificationHistoryStore _store;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? ensureNotificationHistoryStore();
    _refresh();
  }

  /// Đếm mục chưa đọc. Đọc lỗi ⇒ **0** (không chấm, không crash) — chuông vẫn
  /// luôn bấm được (luật 22).
  Future<void> _refresh() async {
    var count = 0;
    try {
      final items = await _store.loadRecent();
      count = items.where((n) => !n.isRead).length;
    } catch (_) {
      count = 0;
    }
    if (!mounted) return;
    setState(() => _unread = count);
  }

  /// Mở Trung tâm rồi đếm **lại sau khi quay về** (luật 23) — không đếm trước.
  Future<void> _openCenter() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationCenterScreen(
          store: widget.store,
          onSelectTab: widget.onSelectTab,
        ),
      ),
    );
    if (!mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: 'Tổng quan'.tr,
          trailing: _BellButton(unread: _unread, onTap: _openCenter),
        ),
        const Expanded(child: SizedBox()),
      ],
    );
  }
}

/// Nút tròn 48 px trên vùng tiêu đề mở màn Trung tâm — **luôn** bấm được.
/// Chấm chưa đọc: 9 px `AppColors.coral` viền trắng (ngoại lệ có lý do — bảng màu
/// dự án không có token đỏ, và chấm nằm trên nền teal nên cần viền trắng để đủ
/// tương phản; research R12).
class _BellButton extends StatelessWidget {
  const _BellButton({required this.unread, required this.onTap});

  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Thông báo'.tr,
      child: InkWell(
        key: const ValueKey('dashboard-notification-bell'),
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  Icons.notifications_none,
                  size: 24,
                  color: AppColors.white,
                ),
              ),
              if (unread > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
