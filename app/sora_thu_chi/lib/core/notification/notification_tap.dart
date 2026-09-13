import 'package:flutter/material.dart';

import '../../data/report_deps.dart';
import '../../screens/add_transaction_screen.dart';
import '../../screens/budget_detail_screen.dart';
import '../report/report_view.dart';
import 'app_notification.dart';

/// Đích điều hướng khi người dùng chạm một thông báo (PBI 31, R8/FR-018/FR-020).
///
/// Bảng đích **do loại quyết định**, không lưu riêng trong DB — tách thành hàm
/// thuần dùng chung cho **cả hai** đường vào: chạm thông báo hệ điều hành
/// (`NotificationEngine.handleTap`) và chạm một mục trong Trung tâm (PBI 30).
enum NotificationTarget { addTransaction, budgetDetail, reportTab, none }

/// Kết quả một lần chạm thông báo: đích + tham số điều hướng đi kèm.
///
/// * [relatedId] — `budgetId` cho [NotificationTarget.budgetDetail].
/// * [period] — kỳ cần chọn sẵn cho [NotificationTarget.reportTab] (tổng kết
///   tuần/tháng); `null` khi chạm từ Trung tâm (không có thông tin kỳ).
typedef NotificationTapResult = ({
  NotificationTarget target,
  int? relatedId,
  ReportPeriod? period,
});

/// Payload của lần chạm **đang chờ được tiêu thụ** — sống qua màn mở khoá PIN.
///
/// Thông báo có thể mở app vào lúc `PinGate` còn đang chặn: nếu điều hướng ngay
/// thì màn đích nằm **dưới** màn khoá và người dùng không thấy (FR-019/AC#13).
/// Vì vậy payload được giữ ở đây rồi `AppShell` **tiêu thụ một lần** sau khi đã
/// qua cửa khoá; mở khoá thất bại/huỷ ⇒ payload **không** bị tiêu thụ.
class NotificationTapRouter {
  String? _pending;

  /// Ghi payload chờ xử lý (payload rỗng/`null` bị bỏ qua).
  void put(String? payload) {
    if (payload == null || payload.isEmpty) return;
    _pending = payload;
  }

  /// Payload đang chờ — **không** tiêu thụ (dùng khi cần kiểm trước khi điều hướng).
  String? peek() => _pending;

  /// Lấy và xoá payload đang chờ.
  String? take() {
    final payload = _pending;
    _pending = null;
    return payload;
  }
}

/// Đích của một thông báo theo [kind] (FR-018).
///
/// `budgetAlert` **thiếu** `relatedId` ⇒ [NotificationTarget.none] — không đoán
/// bừa ngân sách nào; 2 loại chưa có module (`recurringDue`/`goalReminder`) cũng
/// **im lặng**: 0 route, 0 SnackBar, 0 dialog.
NotificationTarget notificationTargetFor({
  required NotificationKind kind,
  int? relatedId,
}) => switch (kind) {
  NotificationKind.dailyReminder => NotificationTarget.addTransaction,
  NotificationKind.budgetAlert =>
    relatedId == null ? NotificationTarget.none : NotificationTarget.budgetDetail,
  NotificationKind.periodSummary => NotificationTarget.reportTab,
  NotificationKind.recurringDue ||
  NotificationKind.goalReminder => NotificationTarget.none,
};

/// Điều hướng tới [target] — dùng chung cho màn Trung tâm (PBI 30) và engine
/// (PBI 31), nên hai đường vào không thể lệch hành vi.
///
/// [relatedId] = `budgetId` khi [target] là [NotificationTarget.budgetDetail].
/// [period] ≠ null khi chạm **từ thông báo tổng kết** ⇒ tab Báo cáo được chọn
/// sẵn đúng kỳ (FR-018/AC#12); chạm từ Trung tâm (không có thông tin kỳ) giữ
/// nguyên hành vi PBI 30 — kỳ mặc định.
/// [onSelectTab] do shell bơm xuống; `null` ⇒ chỉ `popUntil` màn gốc.
Future<void> openNotificationTarget({
  required NotificationTarget target,
  required BuildContext context,
  int? relatedId,
  ReportPeriod? period,
  ValueChanged<int>? onSelectTab,
}) async {
  switch (target) {
    case NotificationTarget.none:
      return;
    case NotificationTarget.addTransaction:
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AddTransactionScreen()),
      );
    case NotificationTarget.budgetDetail:
      final id = relatedId;
      if (id == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              BudgetDetailScreen(budgetId: id, onSelectTab: onSelectTab),
        ),
      );
    case NotificationTarget.reportTab:
      // Tab Báo cáo nằm **trong** shell ⇒ pop về màn gốc rồi đổi tab.
      if (period != null) ensureReportController().setPeriod(period);
      Navigator.of(context).popUntil((route) => route.isFirst);
      onSelectTab?.call(2);
  }
}
