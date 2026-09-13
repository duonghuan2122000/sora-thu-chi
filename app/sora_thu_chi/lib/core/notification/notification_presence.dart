import 'package:get/get.dart';

/// Tên màn "liên quan" mà engine cần biết để **không** bắn khi người dùng đang
/// xem đúng thứ thông báo nói tới (Q3 — R9/FR-016).
abstract final class NotificationScreens {
  static const String budgetDetail = 'budgetDetail';
  static const String report = 'report';
}

/// Dịch vụ **hiện diện** (PBI 31, R9) — cực nhỏ, chỉ để trả lời câu hỏi "người
/// dùng đang mở màn nào?".
///
/// * Cảnh báo ngân sách: đang mở **đúng** Chi tiết ngân sách của danh mục đó ⇒
///   **không** bắn, **không** ghi (AC#10).
/// * Tổng kết: đang mở màn Báo cáo ⇒ huỷ mốc đang chờ (AC#10/H3).
///
/// Màn khai báo lúc `initState` và **ngưng** lúc `dispose`; 2 màn này không bao
/// giờ mở đồng thời nên một cặp biến là đủ.
class NotificationPresence {
  /// Tên màn đang hiện (`''` = không màn nào liên quan).
  final RxString screen = ''.obs;

  /// `budgetId` của màn Chi tiết ngân sách đang hiện (`0` = không phải màn đó).
  final RxInt budgetId = 0.obs;

  /// Màn Chi tiết ngân sách đang mở.
  void enterBudgetDetail(int budgetId) {
    screen.value = NotificationScreens.budgetDetail;
    this.budgetId.value = budgetId;
  }

  /// Màn Báo cáo đang mở.
  void enterReport() {
    screen.value = NotificationScreens.report;
    budgetId.value = 0;
  }

  /// Rời màn liên quan.
  void leave() {
    screen.value = '';
    budgetId.value = 0;
  }
}
