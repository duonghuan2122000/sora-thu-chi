import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/money_format.dart';
import '../core/notification/notification_history_store.dart';
import '../core/privacy/privacy_controller.dart';
import '../core/transaction/transaction_controller.dart';
import '../core/widgets/month_stat_row.dart';
import '../core/widgets/screen_header.dart';
import '../core/widgets/txn_row_tile.dart';
import '../data/notification_history_deps.dart';
import '../data/privacy_deps.dart';
import '../data/transaction_deps.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';
import 'notification_center_screen.dart';

/// Màn Tổng quan — vùng tiêu đề teal (tổng số dư + **chuông thông báo**,
/// FR-001), 2 thẻ thu/chi tháng này, 5 giao dịch gần nhất (PBI 33).
///
/// Chấm đỏ là state **cục bộ** ([_unread]) chứ không GetX controller: trạng thái
/// đọc chỉ đổi được ở màn Trung tâm, mà màn đó mở từ chính màn này ⇒ `await
/// push` rồi đếm lại là đúng và đủ (research R5).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.store,
    this.onSelectTab,
    this.privacyController,
  });

  /// Seam test: mặc định null → [ensureNotificationHistoryStore] khi vào.
  final NotificationHistoryStore? store;

  /// Đích "tổng kết kỳ"/"Xem tất cả" là tab Giao dịch/Báo cáo **trong
  /// shell** — shell bơm xuống.
  final ValueChanged<int>? onSelectTab;

  /// Seam test: mặc định null → [ensurePrivacyController] khi vào (PBI 48).
  final PrivacyController? privacyController;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final NotificationHistoryStore _store;
  late final PrivacyController _privacy;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? ensureNotificationHistoryStore();
    _privacy = widget.privacyController ?? ensurePrivacyController();
    _privacy.load();
    _refresh();
    // Tab mặc định lúc boot — không đi qua AppShell._onTabSelected nên tự
    // nạp ở đây (FR-001); các lần quay lại sau do AppShell nạp (FR-007).
    ensureTransactionController().load();
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

  /// Đang tắt → bật hẳn Privacy mode (đồng bộ Cài đặt, kịch bản 6). Đang bật →
  /// đảo "xem tạm thời" (FR-003/004/005, PBI 48).
  void _toggleEye() {
    if (!_privacy.hideBalance.value) {
      _privacy.setHideBalance(true);
    } else {
      _privacy.revealed.value = !_privacy.revealed.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ensureTransactionController();
    return Column(
      children: [
        ScreenHeader(
          title: 'Tổng quan'.tr,
          trailing: Obx(
            () => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _EyeButton(hideBalance: _privacy.hideBalance.value, onTap: _toggleEye),
                _BellButton(unread: _unread, onTap: _openCenter),
              ],
            ),
          ),
          bottom: Obx(() {
            final view = controller.data.value;
            final masked = _privacy.hideBalance.value && !_privacy.revealed.value;
            final total = view?.walletTotal ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng số dư'.tr,
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  masked ? maskMoney(total) : formatMoney(total),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          }),
        ),
        Expanded(
          child: Obx(() {
            final view = controller.data.value;
            if (view == null) return const SizedBox.expand();
            return _DashboardContent(
              view: view,
              onSelectTab: widget.onSelectTab,
              masked: _privacy.hideBalance.value && !_privacy.revealed.value,
            );
          }),
        ),
      ],
    );
  }
}

/// Nội dung dưới header: thẻ thu/chi + 5 giao dịch gần nhất (FR-002 → FR-006).
class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.view,
    required this.onSelectTab,
    this.masked = false,
  });

  final TransactionView view;
  final ValueChanged<int>? onSelectTab;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final recent = view.groups.expand((g) => g.rows).take(5).toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        MonthStatRow(stat: view.stat, masked: masked),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Giao dịch gần đây'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => onSelectTab?.call(1),
                child: Text('Xem tất cả'.tr),
              ),
            ],
          ),
        ),
        if (recent.isEmpty)
          const _RecentEmptyState()
        else
          for (final row in recent) TxnRowTile(row: row, masked: masked),
      ],
    );
  }
}

/// Trạng thái rỗng khu "Giao dịch gần đây" (FR-006) — chưa từng có giao dịch.
class _RecentEmptyState extends StatelessWidget {
  const _RecentEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: colors.tabInactive, size: 40),
          const SizedBox(height: 12),
          Text(
            'Chưa có giao dịch nào.'.tr,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon con mắt trên vùng tiêu đề (cạnh chuông, mockup `06`, PBI 48) — mở =
/// đang hiện số thật, gạch chéo = Privacy mode đang bật (che hoặc đang xem
/// tạm thời cũng hiện gạch chéo, vì Privacy mode vẫn đang bật).
class _EyeButton extends StatelessWidget {
  const _EyeButton({required this.hideBalance, required this.onTap});

  final bool hideBalance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: (hideBalance ? 'Hiện số tiền' : 'Ẩn số tiền (Privacy mode)').tr,
      child: InkWell(
        key: const ValueKey('dashboard-privacy-eye'),
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Icon(
              hideBalance ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 22,
              color: AppColors.white,
            ),
          ),
        ),
      ),
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
