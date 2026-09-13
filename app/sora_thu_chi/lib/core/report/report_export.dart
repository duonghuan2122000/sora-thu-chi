import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';

import '../category/category.dart';
import '../date_range.dart';
import '../transaction/transaction.dart';
import '../transaction/transaction_filter.dart';
import 'report_view.dart';

/// Module **thuần** của màn Xuất báo cáo (màn `04`, PBI 27) — bộ lọc riêng của
/// màn, bản chiếu dòng tệp, tên tệp và bytes CSV. Không đọc DB/state: nhận dữ
/// liệu + bộ lọc, trả kết quả (data-model §1–§3, luật 1–29).

/// Định dạng tệp xuất (FR-009). Nhãn **không dịch** (tên định dạng — R17);
/// dòng chú thích **có** bản dịch.
enum ExportFormat { pdf, excel, csv }

extension ExportFormatX on ExportFormat {
  String get label => switch (this) {
    ExportFormat.pdf => 'PDF',
    ExportFormat.excel => 'Excel',
    ExportFormat.csv => 'CSV',
  };

  String get hint => switch (this) {
    ExportFormat.pdf => 'Có biểu đồ'.tr,
    ExportFormat.excel => 'Bảng dữ liệu'.tr,
    ExportFormat.csv => 'Dữ liệu thô'.tr,
  };

  /// Đuôi tệp (không kèm dấu chấm) — dùng cho tên tệp và MIME.
  String get fileExtension => switch (this) {
    ExportFormat.pdf => 'pdf',
    ExportFormat.excel => 'xlsx',
    ExportFormat.csv => 'csv',
  };

  String get mimeType => switch (this) {
    ExportFormat.pdf => 'application/pdf',
    ExportFormat.excel =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ExportFormat.csv => 'text/csv',
  };
}

/// Bộ lọc của màn 04 (FR-003…FR-008) — **bất biến**, sống trong phiên mở màn
/// (data-model §1.2). `walletIds`/`categoryIds` rỗng = không giới hạn nhóm đó;
/// `tag` rỗng = không lọc tag.
class ReportExportFilter {
  const ReportExportFilter({
    required this.start,
    required this.end,
    this.walletIds = const {},
    this.categoryIds = const {},
    this.tag = '',
  });

  /// Mặc định kế thừa **đúng kỳ đang xem** của màn Tổng quan (FR-003).
  factory ReportExportFilter.fromRange(DateRange range) =>
      ReportExportFilter(start: range.start, end: range.end);

  /// 00:00 ngày đầu khoảng (bao gồm).
  final DateTime start;

  /// 00:00 ngày **sau** ngày cuối (loại trừ) — quy ước [DateRange] (luật 4).
  final DateTime end;

  final Set<int> walletIds;
  final Set<int> categoryIds;
  final String tag;

  /// "Đến ngày" hiển thị = ngày cuối khoảng (`end` trừ 1 ngày — luật 5).
  DateTime get lastDay => end.subtract(const Duration(days: 1));

  ReportExportFilter withStart(DateTime value) => ReportExportFilter(
    start: value,
    end: end,
    walletIds: walletIds,
    categoryIds: categoryIds,
    tag: tag,
  );

  ReportExportFilter withEnd(DateTime value) => ReportExportFilter(
    start: start,
    end: value,
    walletIds: walletIds,
    categoryIds: categoryIds,
    tag: tag,
  );

  ReportExportFilter toggleWallet(int id) => ReportExportFilter(
    start: start,
    end: end,
    walletIds: _toggled(walletIds, id),
    categoryIds: categoryIds,
    tag: tag,
  );

  ReportExportFilter toggleCategory(int id) => ReportExportFilter(
    start: start,
    end: end,
    walletIds: walletIds,
    categoryIds: _toggled(categoryIds, id),
    tag: tag,
  );

  ReportExportFilter clearWallets() => ReportExportFilter(
    start: start,
    end: end,
    categoryIds: categoryIds,
    tag: tag,
  );

  ReportExportFilter clearCategories() => ReportExportFilter(
    start: start,
    end: end,
    walletIds: walletIds,
    tag: tag,
  );

  ReportExportFilter withTag(String value) => ReportExportFilter(
    start: start,
    end: end,
    walletIds: walletIds,
    categoryIds: categoryIds,
    tag: value,
  );

  static Set<int> _toggled(Set<int> source, int id) {
    final next = {...source};
    if (!next.remove(id)) next.add(id);
    return next;
  }
}

/// **Một dòng** trong mọi tệp xuất (FR-014/FR-015) — data-model §1.3.
class ExportTxn {
  const ExportTxn({
    required this.date,
    required this.typeLabel,
    required this.category,
    required this.wallet,
    required this.amount,
    required this.note,
    required this.tags,
  });

  final DateTime date;

  /// `Thu`/`Chi`/`Chuyển khoản`/`Điều chỉnh số dư` — **đã dịch**.
  final String typeLabel;

  /// Tên danh mục snapshot; transfer/adjustment ⇒ rỗng.
  final String category;

  /// Tên ví tra từ `Map<int, String>`; ví không còn ⇒ rỗng.
  final String wallet;

  /// **Có dấu** đúng như giao dịch (luật 19).
  final int amount;

  final String note;
  final String tags;
}

/// Kết quả dựng cho một bộ lọc (data-model §1.4) — bất biến.
class ReportExportData {
  const ReportExportData({
    required this.filter,
    required this.range,
    required this.transactions,
    required this.rows,
    required this.income,
    required this.expense,
    required this.allocation,
    required this.fileName,
  });

  final ReportExportFilter filter;
  final DateRange range;

  /// Giao dịch khớp (**đủ mọi loại**), sắp tăng dần theo `date` rồi `id`.
  final List<Transaction> transactions;

  /// Bản chiếu 1-1 của [transactions] cho tệp (cùng thứ tự).
  final List<ExportTxn> rows;

  /// Từ `reportTotals` — **đã loại** transfer + adjustment (luật 14).
  final int income;
  final int expense;

  /// Từ `reportBreakdown` — top 5 danh mục cha + "Khác" (luật 15).
  final List<ReportSlice> allocation;

  final String fileName;

  int get count => rows.length;

  bool get isEmpty => transactions.isEmpty;

  /// Chênh lệch = `income − expense` (luật 16).
  int get balance => income - expense;
}

/// Giao dịch khớp bộ lọc xuất (luật 1–13, FR-004…FR-008/FR-015): **VÀ** giữa
/// nhóm (ngày ∧ ví ∧ danh mục ∧ tag), **HOẶC** trong nhóm, nhóm rỗng = không giới
/// hạn. Giữ **mọi** loại giao dịch và **không** group-keep hai vế chuyển khoản
/// (khác bộ lọc màn Giao dịch — luật 12); sắp tăng dần theo `date` rồi `id`.
List<Transaction> filterForExport(
  List<Transaction> all,
  ReportExportFilter filter,
  List<Category> categories,
) {
  if (all.isEmpty) return const [];
  final effective = effectiveCategoryIds(filter.categoryIds, categories);
  final effectiveNames = <String>{
    for (final c in categories)
      if (effective.contains(c.id)) normalizeSearch(c.name),
  };
  final needle = filter.tag.trim().replaceFirst('#', '').trim();
  final tagNeedle = normalizeSearch(needle);

  final result = all.where((t) {
    if (t.date.isBefore(filter.start) || !t.date.isBefore(filter.end)) {
      return false;
    }
    if (filter.walletIds.isNotEmpty && !filter.walletIds.contains(t.walletId)) {
      return false;
    }
    if (filter.categoryIds.isNotEmpty) {
      final byId =
          t.categoryId != null && effective.contains(t.categoryId);
      // Dữ liệu cũ không có `categoryId` → khớp theo tên đã bỏ dấu (luật 7);
      // transfer/adjustment không danh mục ⇒ tự bị loại khi nhóm này được chọn.
      final byName =
          !byId &&
          t.categoryId == null &&
          effectiveNames.contains(normalizeSearch(t.category));
      if (!byId && !byName) return false;
    }
    if (tagNeedle.isNotEmpty &&
        !normalizeSearch(t.tags).contains(tagNeedle)) {
      return false;
    }
    return true;
  }).toList();

  result.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  });
  return result;
}

/// Tên tệp ASCII `bao-cao-thu-chi_<yyyyMMdd>-<yyyyMMdd>.<ext>` (FR-024, luật
/// 24–25); ngày cuối = `end − 1 ngày`.
String exportFileName(DateTime start, DateTime end, ExportFormat format) {
  final last = end.subtract(const Duration(days: 1));
  return 'bao-cao-thu-chi_${_ymd(start)}-${_ymd(last)}'
      '.${format.fileExtension}';
}

String _ymd(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}'
    '${date.month.toString().padLeft(2, '0')}'
    '${date.day.toString().padLeft(2, '0')}';

/// Ngày trong tệp: `dd/MM/yyyy` — **không** đổi theo ngôn ngữ (FR-020).
String formatFileDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

/// Tiêu đề cột danh sách giao dịch — dùng chung **cả 3** định dạng (luật 17).
List<String> exportColumnTitles() => [
  'Ngày'.tr,
  'Loại'.tr,
  'Danh mục'.tr,
  'Ví'.tr,
  'Số tiền'.tr,
  'Ghi chú'.tr,
  'Tag'.tr,
];

/// Một dòng giao dịch dạng ô chữ — **số tiền là số có dấu**, không phân tách
/// nghìn, không đơn vị (luật 19) ⇒ bảng tính đọc được thành số.
List<String> exportRowCells(ExportTxn row) => [
  formatFileDate(row.date),
  row.typeLabel,
  row.category,
  row.wallet,
  '${row.amount}',
  row.note,
  row.tags,
];

/// Chia [range] thành **tối đa 6** khoảng con liền kề cho biểu đồ dòng tiền của
/// tệp PDF (FR-012, luật 26/29): `n = min(6, số ngày)`, chia theo **số học ngày**
/// — không mất ngày nào, khoảng đầu bắt đầu đúng `range.start`, khoảng cuối kết
/// thúc đúng `range.end`. Mỗi khoảng tính thu/chi bằng [reportTotals] (transfer
/// + adjustment tự bị loại) ⇒ chi phí vẽ **không** tăng theo số ngày.
List<({DateRange range, int income, int expense})> exportCashflowBuckets(
  List<Transaction> transactions,
  DateRange range,
) {
  // Đếm số ngày bằng mốc UTC (chênh lệch ngày không phụ thuộc DST), nhưng **dựng
  // biên khoảng theo giờ địa phương** — trộn UTC vào `DateRange` sẽ lệch ngày.
  final days = DateTime.utc(range.end.year, range.end.month, range.end.day)
      .difference(
        DateTime.utc(range.start.year, range.start.month, range.start.day),
      )
      .inDays;
  if (days <= 0) return const [];
  final count = days < 6 ? days : 6;

  DateTime at(int offset) =>
      DateTime(range.start.year, range.start.month, range.start.day + offset);

  return [
    for (var i = 0; i < count; i++)
      () {
        final bucket = DateRange(
          start: at(days * i ~/ count),
          end: i == count - 1 ? at(days) : at(days * (i + 1) ~/ count),
        );
        final totals = reportTotals(transactions, bucket);
        return (
          range: bucket,
          income: totals.income,
          expense: totals.expense,
        );
      }(),
  ];
}

/// Bytes tệp CSV (luật 21, 28): **chỉ** danh sách giao dịch, dòng tiêu đề + mỗi
/// dòng một giao dịch, ô chứa `,`/`"`/xuống dòng bọc `"…"` + nhân đôi `"` bên
/// trong (RFC 4180), **BOM UTF-8** ở đầu để bảng tính không lỗi font tiếng Việt.
Uint8List buildCsvBytes(List<ExportTxn> rows) {
  final lines = <String>[
    exportColumnTitles().map(_csvCell).join(','),
    for (final row in rows) exportRowCells(row).map(_csvCell).join(','),
  ];
  return Uint8List.fromList([
    0xEF, 0xBB, 0xBF, // BOM UTF-8
    ...utf8.encode(lines.join('\r\n')),
  ]);
}

String _csvCell(String value) {
  final needsQuote =
      value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r');
  return needsQuote ? '"${value.replaceAll('"', '""')}"' : value;
}

/// Dựng toàn bộ dữ liệu màn/tệp cho một bộ lọc (luật 14–16, 23): danh sách
/// giao dịch + bản chiếu dòng + số tổng hợp (`reportTotals`) + phân bổ
/// (`reportBreakdown`) + tên tệp. Số tổng hợp **đi qua đúng** hai hàm của màn
/// Tổng quan ⇒ không thể lệch số (SC-004).
ReportExportData buildReportExport({
  required List<Transaction> transactions,
  required List<Category> categories,
  required Map<int, String> walletNames,
  required ReportExportFilter filter,
  required ExportFormat format,
}) {
  final range = DateRange(start: filter.start, end: filter.end);
  final matched = filterForExport(transactions, filter, categories);
  final totals = reportTotals(matched, range);
  return ReportExportData(
    filter: filter,
    range: range,
    transactions: matched,
    rows: [
      for (final t in matched)
        ExportTxn(
          date: t.date,
          typeLabel: t.type.label.tr,
          category: t.type == TxnType.transfer || t.type == TxnType.adjustment
              ? ''
              : t.category,
          wallet: walletNames[t.walletId] ?? '',
          amount: t.amount,
          note: t.note,
          tags: t.tags,
        ),
    ],
    income: totals.income,
    expense: totals.expense,
    allocation: reportBreakdown(
      transactions: matched,
      categories: categories,
      range: range,
    ),
    fileName: exportFileName(filter.start, filter.end, format),
  );
}
