import 'dart:typed_data';

import 'package:excel_community/excel_community.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../money_format.dart';
import 'report_export.dart';

/// Tầng **sinh tệp** của màn Xuất báo cáo (PBI 27): Excel (T025) và PDF (T030).
/// Cả hai hàm **thuần** — không `Widget`/`BuildContext`, không đọc asset ⇒ gọi
/// được trong `compute()` sau khi main isolate đã nạp font (R11).

/// Bytes tệp `.xlsx` hai sheet (FR-013, luật 27):
/// - `Tổng hợp`: 3 số tổng hợp (`formatMoney`) + bảng phân bổ chi theo danh mục
///   (tên + số tiền + %).
/// - `Giao dịch`: dòng tiêu đề + mỗi dòng một giao dịch, cùng bộ cột CSV; cột
///   **số tiền** ghi **ô số** (không kèm `đ`) ⇒ cộng được trong bảng tính.
Uint8List buildXlsxBytes(ReportExportData data) {
  final excel = Excel.createExcel();

  final summary = excel['Tổng hợp'];
  summary.appendRow([
    TextCellValue('Báo cáo thu chi'.tr),
    TextCellValue(
      '@from – @to'.trParams({
        'from': formatFileDate(data.range.start),
        'to': formatFileDate(data.filter.lastDay),
      }),
    ),
  ]);
  summary.appendRow([TextCellValue('')]);
  summary.appendRow([
    TextCellValue('Tổng thu'.tr),
    TextCellValue(formatMoney(data.income)),
  ]);
  summary.appendRow([
    TextCellValue('Tổng chi'.tr),
    TextCellValue(formatMoney(data.expense)),
  ]);
  summary.appendRow([
    TextCellValue('Chênh lệch'.tr),
    TextCellValue(formatMoney(data.balance)),
  ]);

  if (data.allocation.isNotEmpty) {
    summary.appendRow([TextCellValue('')]);
    summary.appendRow([
      TextCellValue('Phân bổ chi theo danh mục'.tr),
      TextCellValue('Số tiền'.tr),
      TextCellValue('%'),
    ]);
    for (final slice in data.allocation) {
      summary.appendRow([
        TextCellValue(slice.name),
        TextCellValue(formatMoney(slice.amount)),
        IntCellValue(slice.percent),
      ]);
    }
  }
  summary.setColumnWidth(0, 28);
  summary.setColumnWidth(1, 18);

  final transactions = excel['Giao dịch'];
  transactions.appendRow([
    for (final title in exportColumnTitles()) TextCellValue(title),
  ]);
  for (final row in data.rows) {
    final cells = exportRowCells(row);
    transactions.appendRow([
      for (var i = 0; i < cells.length; i++)
        // Cột "Số tiền" (index 4) là **ô số** để bảng tính cộng được (luật 19).
        if (i == 4) IntCellValue(row.amount) else TextCellValue(cells[i]),
    ]);
  }
  transactions.setColumnWidth(0, 12);
  transactions.setColumnWidth(2, 22);
  transactions.setColumnWidth(3, 20);
  transactions.setColumnWidth(5, 30);
  transactions.setColumnWidth(6, 20);

  // Sheet mặc định của thư viện không dùng tới.
  excel.delete('Sheet1');

  final bytes = excel.encode();
  if (bytes == null) {
    throw StateError('Không dựng được tệp Excel.');
  }
  return Uint8List.fromList(bytes);
}

/// Màu thương hiệu dùng trong tệp PDF (cùng giá trị với design system) —
/// teal cho thu, coral cho chi, xám cho phần còn lại.
const _teal = PdfColor.fromInt(0xFF0F6E56);
const _coral = PdfColor.fromInt(0xFFD85A30);
const _grey = PdfColor.fromInt(0xFFB4B2A9);
const _divider = PdfColor.fromInt(0xFFE0E0E0);

/// Bytes tệp PDF (FR-012, luật 26): trang tổng hợp (tiêu đề + khoảng thời gian +
/// 3 số `formatMoney` + **biểu đồ dòng tiền** ≤ 6 khoảng con + **phân bổ chi theo
/// danh mục** dạng thanh ngang tỉ lệ) rồi **danh sách giao dịch** phân trang tự
/// động. Biểu đồ **vẽ lại** bằng widget của `pdf` từ đúng dữ liệu màn 01 (không
/// chụp ảnh — ngoại lệ có lý do #2 của plan) nên hàm **thuần Dart**, gọi được
/// trong `compute()`; font nhúng truyền từ main isolate (R9/R11).
Future<Uint8List> buildPdfBytes({
  required ReportExportData data,
  required Uint8List fontRegular,
  required Uint8List fontBold,
}) async {
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(
      base: pw.Font.ttf(ByteData.sublistView(fontRegular)),
      bold: pw.Font.ttf(ByteData.sublistView(fontBold)),
    ),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox()
          : pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                'Báo cáo thu chi'.tr,
                style: const pw.TextStyle(fontSize: 10, color: _grey),
              ),
            ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${context.pageNumber}/${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: _grey),
        ),
      ),
      build: (context) => [
        pw.Text(
          'Báo cáo thu chi'.tr,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '@from – @to'.trParams({
            'from': formatFileDate(data.range.start),
            'to': formatFileDate(data.filter.lastDay),
          }),
          style: const pw.TextStyle(fontSize: 11, color: _grey),
        ),
        pw.SizedBox(height: 14),
        _totalsRow(data),
        pw.SizedBox(height: 16),
        _cashflowChart(data),
        pw.SizedBox(height: 16),
        _allocationSection(data),
        pw.SizedBox(height: 18),
        pw.Text(
          'Danh sách giao dịch'.tr,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        _transactionsTable(data),
      ],
    ),
  );

  return doc.save();
}

/// 3 ô số tổng hợp — tổng thu (teal), tổng chi (coral), chênh lệch (theo dấu).
pw.Widget _totalsRow(ReportExportData data) => pw.Row(
  children: [
    _totalBox('Tổng thu'.tr, data.income, _teal),
    pw.SizedBox(width: 8),
    _totalBox('Tổng chi'.tr, data.expense, _coral),
    pw.SizedBox(width: 8),
    _totalBox('Chênh lệch'.tr, data.balance, data.balance < 0 ? _coral : _teal),
  ],
);

pw.Widget _totalBox(String label, int amount, PdfColor color) => pw.Expanded(
  child: pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFF1EFE8),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _grey)),
        pw.SizedBox(height: 3),
        pw.Text(
          formatMoney(amount),
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  ),
);

/// Biểu đồ dòng tiền — cặp cột Thu (teal) / Chi (coral) cho ≤ 6 khoảng con.
pw.Widget _cashflowChart(ReportExportData data) {
  final buckets = exportCashflowBuckets(data.transactions, data.range);
  var maxValue = 0;
  for (final bucket in buckets) {
    if (bucket.income > maxValue) maxValue = bucket.income;
    if (bucket.expense > maxValue) maxValue = bucket.expense;
  }
  pw.Widget bar(int value, PdfColor color) => pw.Container(
    width: 7,
    height: maxValue <= 0 ? 0 : 80 * value / maxValue,
    color: color,
  );

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Dòng tiền'.tr,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 6),
      pw.Row(
        children: [
          _legendDot('Thu'.tr, _teal),
          pw.SizedBox(width: 12),
          _legendDot('Chi'.tr, _coral),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.SizedBox(
        height: 108,
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            for (final bucket in buckets)
              pw.Expanded(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        bar(bucket.income, _teal),
                        pw.SizedBox(width: 3),
                        bar(bucket.expense, _coral),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      formatFileDate(bucket.range.start).substring(0, 5),
                      style: const pw.TextStyle(fontSize: 7, color: _grey),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _legendDot(String label, PdfColor color) => pw.Row(
  children: [
    pw.Container(width: 6, height: 6, color: color),
    pw.SizedBox(width: 3),
    pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _grey)),
  ],
);

/// Phân bổ chi theo danh mục — thanh ngang tỉ lệ (bề rộng ∝ %), kèm số tiền.
pw.Widget _allocationSection(ReportExportData data) {
  if (data.allocation.isEmpty) {
    return pw.Text(
      'Chưa có chi tiêu nào trong kỳ này'.tr,
      style: const pw.TextStyle(fontSize: 10, color: _grey),
    );
  }
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Phân bổ chi theo danh mục'.tr,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 6),
      for (final slice in data.allocation) ...[
        pw.Row(
          children: [
            pw.SizedBox(
              width: 110,
              child: pw.Text(
                slice.name,
                maxLines: 1,
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Container(width: 1.8 * slice.percent, height: 9, color: _teal),
            pw.SizedBox(width: 6),
            pw.Text(
              '${formatMoney(slice.amount)} · ${slice.percent}%',
              style: const pw.TextStyle(fontSize: 9, color: _grey),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
      ],
    ],
  );
}

/// Danh sách giao dịch — bảng cùng bộ cột với CSV/Excel, phân trang tự động.
pw.Widget _transactionsTable(ReportExportData data) =>
    pw.TableHelper.fromTextArray(
      headers: exportColumnTitles(),
      data: [for (final row in data.rows) exportRowCells(row)],
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF1EFE8),
      ),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(3),
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _divider, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.4),
        1: pw.FlexColumnWidth(1.6),
        2: pw.FlexColumnWidth(2.2),
        3: pw.FlexColumnWidth(1.8),
        4: pw.FlexColumnWidth(1.4),
        5: pw.FlexColumnWidth(2.6),
        6: pw.FlexColumnWidth(1.6),
      },
    );
