import 'package:get/get.dart';

/// Chu kỳ ngân sách (PBI 20) — 3 giá trị đúng mockup `02`.
enum BudgetPeriod { weekly, monthly, yearly }

extension BudgetPeriodLabelX on BudgetPeriod {
  /// Nhãn tiếng Việt (có bản dịch EN) — dùng cho chip chọn chu kỳ & nhãn chu kỳ
  /// trên dòng màn Tổng quan.
  String get label => switch (this) {
    BudgetPeriod.weekly => 'Tuần'.tr,
    BudgetPeriod.monthly => 'Tháng'.tr,
    BudgetPeriod.yearly => 'Năm'.tr,
  };
}

/// Ngân sách theo danh mục — map 1-1 dòng bảng `budgets` (data-model §Thực thể 1).
/// Số tiền giới hạn [amount] luôn dương (validate ở tầng luật);
/// "đã chi"/"% đã dùng"/trạng thái là **đại lượng suy ra**, không lưu ở đây.
class Budget {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.period,
    required this.isRecurring,
    required this.startDate,
  });

  /// id thật trong DB; 0 = chưa lưu (repository sinh id khi insert).
  final int id;

  /// Danh mục **Chi** (cha hoặc con) — trỏ `categories.id`.
  final int categoryId;

  /// Giới hạn chi tiêu (VND, dương).
  final int amount;

  final BudgetPeriod period;

  /// Bật = tự tiếp tục kỳ sau; tắt = chỉ kỳ chứa [startDate] rồi kết thúc.
  final bool isRecurring;

  /// Ngày bắt đầu áp dụng (tạo mới = hôm nay).
  final DateTime startDate;
}
