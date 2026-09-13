
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel_community/excel_community.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/date_range.dart';
import 'package:sora_thu_chi/core/report/report_export.dart';
import 'package:sora_thu_chi/core/report/report_export_writers.dart';
import 'package:sora_thu_chi/core/report/report_view.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';

/// Test tầng sinh tệp (PBI 27) — chỉ kiểm **cấu trúc** tệp (không có Excel/
/// trình đọc PDF trong CI); "mở bằng bảng tính thật" là QA tay (quickstart nhóm I).

Category _cat(int id, String name, {int? parentId, int sortOrder = 0}) =>
    Category(
      id: id,
      name: name,
      type: CategoryType.expense,
      icon: 'restaurant',
      color: 0xFF0F6E56,
      parentId: parentId,
      sortOrder: sortOrder,
    );

Transaction _expense(int id, int amount, DateTime date, {int? categoryId}) =>
    Transaction(
      id: id,
      walletId: 1,
      type: TxnType.expense,
      category: categoryId == null ? '' : 'Ăn uống',
      amount: -amount,
      date: date,
      categoryId: categoryId,
      note: 'Ghi chú, có "dấu phẩy"',
    );

final _categories = [_cat(1, 'Ăn uống'), _cat(2, 'Cà phê', parentId: 1)];

final _transactions = [
  Transaction(
    id: 1,
    walletId: 1,
    type: TxnType.income,
    category: 'Lương',
    amount: 5000000,
    date: DateTime(2026, 9, 5),
  ),
  _expense(2, 300000, DateTime(2026, 9, 3), categoryId: 1),
  _expense(3, 1500000, DateTime(2026, 9, 10), categoryId: 2),
  Transaction(
    id: 4,
    walletId: 1,
    type: TxnType.transfer,
    amount: -200000,
    date: DateTime(2026, 9, 15),
    transferGroupId: 4,
  ),
];

ReportExportData _data({
  DateTime? start,
  DateTime? end,
  ExportFormat format = ExportFormat.excel,
}) => buildReportExport(
  transactions: _transactions,
  categories: _categories,
  walletNames: const {1: 'Tiền mặt'},
  filter: ReportExportFilter(
    start: start ?? DateTime(2026, 9, 1),
    end: end ?? DateTime(2026, 10, 1),
  ),
  format: format,
);

String _cellText(Data? cell) {
  final value = cell?.value;
  if (value is TextCellValue) return value.value.text ?? '';
  return '$value';
}

void main() {
  group('buildXlsxBytes (US3, FR-013)', () {
    test('không rỗng và là tệp zip hợp lệ', () {
      final bytes = buildXlsxBytes(_data());
      expect(bytes, isNotEmpty);
      // Chữ ký zip: PK\x03\x04.
      expect(bytes.sublist(0, 4), [0x50, 0x4B, 0x03, 0x04]);
    });

    test('giải nén ⇒ có xl/workbook.xml', () {
      final archive = ZipDecoder().decodeBytes(buildXlsxBytes(_data()));
      final names = archive.files.map((f) => f.name).toList();
      expect(names, contains('xl/workbook.xml'));
    });

    test('đúng 2 sheet tên "Tổng hợp" và "Giao dịch"', () {
      final excel = Excel.decodeBytes(buildXlsxBytes(_data()));
      expect(excel.sheets.keys.toSet(), {'Tổng hợp', 'Giao dịch'});
    });

    test('ô tiếng Việt có dấu đọc lại đúng nguyên văn', () {
      final excel = Excel.decodeBytes(buildXlsxBytes(_data()));
      final summary = excel['Tổng hợp'];
      final texts = [
        for (final row in summary.rows)
          for (final cell in row) _cellText(cell),
      ];
      expect(texts, contains('Báo cáo thu chi'));
      // Bảng phân bổ gộp con vào cha ⇒ chỉ có 'Ăn uống' (1.800.000 = 300.000 +
      // 1.500.000 của 'Cà phê'), không có dòng 'Cà phê' riêng.
      expect(texts, contains('Ăn uống'));
      expect(texts, contains('Tổng thu'));
      expect(texts, contains('Tổng chi'));
      expect(texts, contains('Chênh lệch'));
      expect(texts, contains('5.000.000 đ'));
      expect(texts, contains('1.800.000 đ'));
      expect(texts, contains('3.200.000 đ'));
    });

    test('sheet "Giao dịch" đủ 7 cột tiêu đề + số dòng = rows.length', () {
      final data = _data();
      final excel = Excel.decodeBytes(buildXlsxBytes(data));
      final sheet = excel['Giao dịch'];
      final header = sheet.rows.first.map(_cellText).toList();
      expect(header, [
        'Ngày',
        'Loại',
        'Danh mục',
        'Ví',
        'Số tiền',
        'Ghi chú',
        'Tag',
      ]);
      expect(sheet.rows.length, data.rows.length + 1);
    });

    test('cột số tiền là ô SỐ (không kèm đơn vị) — bảng tính cộng được', () {
      final excel = Excel.decodeBytes(buildXlsxBytes(_data()));
      final sheet = excel['Giao dịch'];
      final amounts = [
        for (final row in sheet.rows.skip(1)) row[4]?.value,
      ];
      expect(amounts.every((v) => v is IntCellValue || v is DoubleCellValue), isTrue);
      final values = [
        for (final v in amounts)
          if (v is IntCellValue) v.value else (v as DoubleCellValue).value,
      ];
      expect(values, contains(-300000));
      expect(values, contains(5000000));
    });

    test('ô ghi chú có dấu phẩy + nháy kép giữ nguyên', () {
      final data = _data();
      final excel = Excel.decodeBytes(buildXlsxBytes(data));
      final sheet = excel['Giao dịch'];
      final notes = [
        for (final row in sheet.rows.skip(1)) _cellText(row[5]),
      ];
      expect(notes, contains('Ghi chú, có "dấu phẩy"'));
    });

    test('khoảng nhiều năm vẫn dựng được', () {
      final bytes = buildXlsxBytes(
        _data(start: DateTime(2019, 1, 1), end: DateTime(2027, 1, 1)),
      );
      expect(bytes, isNotEmpty);
    });
  });

  group('exportCashflowBuckets (US4, FR-012)', () {
    test('kỳ 1 ngày ⇒ đúng 1 phần', () {
      final buckets = exportCashflowBuckets(_transactions, DateRange(
        start: DateTime(2026, 9, 3),
        end: DateTime(2026, 9, 4),
      ));
      expect(buckets, hasLength(1));
      expect(buckets.single.income, 0);
      expect(buckets.single.expense, 300000);
    });

    test('khoảng dài ⇒ tối đa 6 phần, phủ trọn khoảng không mất ngày', () {
      final range = DateRange(
        start: DateTime(2019, 1, 1),
        end: DateTime(2027, 1, 1),
      );
      final buckets = exportCashflowBuckets(_transactions, range);
      expect(buckets.length, lessThanOrEqualTo(6));
      expect(buckets.first.range.start, range.start);
      expect(buckets.last.range.end, range.end);
      // Liền kề: phần sau bắt đầu đúng chỗ phần trước kết thúc.
      for (var i = 1; i < buckets.length; i++) {
        expect(buckets[i].range.start, buckets[i - 1].range.end);
      }
    });

    test('tổng các phần bằng reportTotals toàn khoảng', () {
      final range = DateRange(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 10, 1),
      );
      final buckets = exportCashflowBuckets(_transactions, range);
      final totals = reportTotals(_transactions, range);
      expect(
        buckets.fold<int>(0, (sum, b) => sum + b.income),
        totals.income,
      );
      expect(
        buckets.fold<int>(0, (sum, b) => sum + b.expense),
        totals.expense,
      );
      // Khoảng 30 ngày ⇒ đúng 6 phần.
      expect(buckets, hasLength(6));
    });

    test('khoảng rỗng/âm ⇒ không có phần nào', () {
      expect(
        exportCashflowBuckets(_transactions, DateRange(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 1),
        )),
        isEmpty,
      );
    });
  });

  group('buildPdfBytes (US4, FR-012)', () {
    late Uint8List fontRegular;
    late Uint8List fontBold;

    setUpAll(() async {
      // `flutter test` chạy với cwd = gốc package ⇒ đọc thẳng asset trong repo.
      fontRegular = await File(
        'assets/fonts/Roboto-Regular.ttf',
      ).readAsBytes();
      fontBold = await File('assets/fonts/Roboto-Bold.ttf').readAsBytes();
    });

    test('bắt đầu bằng %PDF và không rỗng', () async {
      final bytes = await buildPdfBytes(
        data: _data(format: ExportFormat.pdf),
        fontRegular: fontRegular,
        fontBold: fontBold,
      );
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });

    test('khoảng nhiều năm (2019→2026) vẫn dựng được', () async {
      final bytes = await buildPdfBytes(
        data: _data(
          start: DateTime(2019, 1, 1),
          end: DateTime(2027, 1, 1),
          format: ExportFormat.pdf,
        ),
        fontRegular: fontRegular,
        fontBold: fontBold,
      );
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });

    test('kỳ rỗng vẫn dựng được (không có bảng/danh sách)', () async {
      final bytes = await buildPdfBytes(
        data: _data(
          start: DateTime(2020, 1, 1),
          end: DateTime(2020, 2, 1),
          format: ExportFormat.pdf,
        ),
        fontRegular: fontRegular,
        fontBold: fontBold,
      );
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });
  });
}
