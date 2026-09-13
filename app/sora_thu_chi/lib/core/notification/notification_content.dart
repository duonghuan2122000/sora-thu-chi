import 'package:get/get.dart';

import '../budget/budget.dart';

/// Module **thuần** sinh câu chữ thông báo (PBI 31, R12/FR-005…FR-009) — không
/// Widget, không I/O, không đọc DB.
///
/// Câu chữ bám **nguyên văn mockup `04`** (`docs/notification/04-mau-thong-bao-day.svg`):
/// tiêu đề ngắn + dòng mô tả **có số liệu cụ thể** (tên danh mục, %, kỳ, số tiền,
/// giờ) — không có câu chung chung kiểu "bạn có thông báo mới" (FR-005).
///
/// Khoá dịch **là chính chuỗi tiếng Việt** (khuôn PBI 19) nên mọi câu ở đây phải
/// viết literal ngay trước `.tr`/`.trParams` để `sora_translations_test` ràng buộc
/// được bản `_en`. Nội dung sinh ra là **snapshot theo ngôn ngữ lúc bắn** (FR-027)
/// — engine lưu nguyên văn, màn Trung tâm không dịch lại.

/// Tiêu đề + mô tả của một thông báo. `body` rỗng hợp lệ (mục chỉ có tiêu đề).
typedef NotificationContent = ({String title, String body});

/// Nhắc nhập giao dịch hằng ngày (FR-008).
///
/// [hasTxnToday] = hôm nay **đã có** giao dịch. Khi cờ "chỉ nhắc nếu chưa ghi"
/// **tắt**, thông báo vẫn bắn dù đã ghi ⇒ câu chữ **không** được khẳng định
/// "bạn chưa ghi giao dịch nào hôm nay"; dùng lời nhắc chung (AC#3).
NotificationContent dailyReminderContent({required bool hasTxnToday}) {
  if (hasTxnToday) {
    return (
      title: 'Nhắc ghi chép giao dịch'.tr,
      body: 'Đừng quên ghi lại thu chi hôm nay nhé!'.tr,
    );
  }
  return (
    title: 'Nhắc ghi chép giao dịch'.tr,
    body: 'Bạn chưa ghi giao dịch nào hôm nay.'.tr,
  );
}

/// Nhãn **kỳ** của ngân sách trong câu chữ cảnh báo (FR-007) — `tháng 9`,
/// `năm 2026`, `tuần 07/09`. [periodStart] là ngày đầu kỳ
/// ([budgetPeriodRange] của module ngân sách quyết định kỳ nào).
String budgetPeriodLabel(BudgetPeriod period, DateTime periodStart) =>
    switch (period) {
      BudgetPeriod.weekly => 'tuần @ngày/@tháng'.trParams({
        'ngày': _two(periodStart.day),
        'tháng': _two(periodStart.month),
      }),
      BudgetPeriod.monthly => 'tháng @tháng'.trParams({
        'tháng': '${periodStart.month}',
      }),
      BudgetPeriod.yearly => 'năm @năm'.trParams({'năm': '${periodStart.year}'}),
    };

/// Cảnh báo ngân sách (FR-007) — **sắp vượt** (ngưỡng sớm) và **đã vượt**
/// (ngưỡng vượt mức) phải **phân biệt được bằng chữ**, không chỉ bằng con số
/// (AC#5). Câu chữ nêu **tên danh mục** + **phần trăm** + **kỳ** đúng mockup:
/// "Bạn đã dùng 82% ngân sách tháng 9 cho danh mục Ăn uống."
NotificationContent budgetAlertContent({
  required String categoryName,
  required int percent,
  required bool over,
  required String periodLabel,
}) {
  final title = over
      ? 'Đã vượt ngân sách @danh_mục'.trParams({'danh_mục': categoryName})
      : 'Sắp vượt ngân sách @danh_mục'.trParams({'danh_mục': categoryName});
  return (
    title: title,
    body: 'Bạn đã dùng @phần_trăm% ngân sách @kỳ cho danh mục @danh_mục.'
        .trParams({
          'phần_trăm': '$percent',
          'kỳ': periodLabel,
          'danh_mục': categoryName,
        }),
  );
}

/// Tổng kết tuần/tháng (FR-009) — [comparisonSentence] là câu so sánh **đã dựng
/// sẵn** từ module báo cáo (`reportComparison().insight`), nên luật "kỳ trước
/// rỗng ⇒ bỏ câu so sánh, không chia 0" (AC#20) **miễn phí**.
///
/// [comparisonSentence] rỗng ⇒ chỉ còn dòng mời xem báo cáo (kỳ vừa kết thúc
/// rỗng vẫn bắn — AC#19).
NotificationContent summaryContent({
  required bool weekly,
  required String comparisonSentence,
}) {
  final title = weekly ? 'Tổng kết tuần'.tr : 'Tổng kết tháng'.tr;
  final text = comparisonSentence.trim();
  return (
    title: title,
    body: text.isEmpty
        ? 'Xem chi tiết báo cáo.'.tr
        : '$text\n${'Xem chi tiết báo cáo.'.tr}',
  );
}

String _two(int value) => value.toString().padLeft(2, '0');
