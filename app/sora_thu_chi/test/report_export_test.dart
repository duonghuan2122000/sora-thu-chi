import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/date_range.dart';
import 'package:sora_thu_chi/core/report/report_export.dart';
import 'package:sora_thu_chi/core/report/report_view.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';

/// Test module thuần màn Xuất báo cáo (PBI 27) — không DB, không widget.
/// Bộ lọc/ngày/tiền đều bơm tham số (không dùng giờ thật).

Category _cat(
  int id,
  String name, {
  CategoryType type = CategoryType.expense,
  int? parentId,
  int sortOrder = 0,
}) => Category(
  id: id,
  name: name,
  type: type,
  icon: 'category',
  color: 0xFF0F6E56,
  parentId: parentId,
  sortOrder: sortOrder,
);

Transaction _txn({
  required int id,
  required TxnType type,
  required int amount,
  required DateTime date,
  required int walletId,
  int? categoryId,
  String category = '',
  String note = '',
  String tags = '',
  int? transferGroupId,
}) => Transaction(
  id: id,
  walletId: walletId,
  type: type,
  category: category,
  note: note,
  amount: amount,
  date: date,
  transferGroupId: transferGroupId,
  categoryId: categoryId,
  tags: tags,
);

/// Danh mục: 1 'Ăn uống' (cha) → 2 'Cà phê' (con); 3 'Du lịch' (cha);
/// 4 'Lương' (thu).
final _categories = [
  _cat(1, 'Ăn uống'),
  _cat(2, 'Cà phê', parentId: 1, sortOrder: 1),
  _cat(3, 'Du lịch', sortOrder: 2),
  _cat(4, 'Lương', type: CategoryType.income, sortOrder: 3),
];

const _walletNames = {1: 'Tiền mặt', 2: 'Ngân hàng'};

/// Tháng 9/2026 — gồm biên 01/09 & 30/09, 2 dòng ngoài khoảng (31/08, 01/10),
/// 1 cặp chuyển khoản + 1 điều chỉnh số dư (vào danh sách, **không** vào con số),
/// 1 dòng cũ không `categoryId` khớp theo tên, 1 dòng tag.
final _all = [
  _txn(
    id: 1,
    type: TxnType.expense,
    amount: -300000,
    date: DateTime(2026, 9, 1),
    walletId: 1,
    categoryId: 1,
    category: 'Ăn uống',
    tags: 'dulich',
  ),
  _txn(
    id: 2,
    type: TxnType.expense,
    amount: -200000,
    date: DateTime(2026, 9, 30),
    walletId: 1,
    categoryId: 2,
    category: 'Cà phê',
  ),
  _txn(
    id: 3,
    type: TxnType.income,
    amount: 5000000,
    date: DateTime(2026, 9, 5),
    walletId: 1,
    categoryId: 4,
    category: 'Lương',
  ),
  _txn(
    id: 4,
    type: TxnType.expense,
    amount: -100000,
    date: DateTime(2026, 8, 31),
    walletId: 1,
    categoryId: 1,
    category: 'Ăn uống',
  ),
  _txn(
    id: 5,
    type: TxnType.expense,
    amount: -400000,
    date: DateTime(2026, 10, 1),
    walletId: 1,
    categoryId: 1,
    category: 'Ăn uống',
  ),
  _txn(
    id: 6,
    type: TxnType.transfer,
    amount: -1000000,
    date: DateTime(2026, 9, 10),
    walletId: 1,
    transferGroupId: 6,
  ),
  _txn(
    id: 7,
    type: TxnType.transfer,
    amount: 1000000,
    date: DateTime(2026, 9, 10),
    walletId: 2,
    transferGroupId: 6,
  ),
  _txn(
    id: 8,
    type: TxnType.adjustment,
    amount: -50000,
    date: DateTime(2026, 9, 12),
    walletId: 2,
  ),
  _txn(
    id: 9,
    type: TxnType.expense,
    amount: -150000,
    date: DateTime(2026, 9, 15),
    walletId: 2,
    categoryId: 3,
    category: 'Du lịch',
    tags: 'Du lịch',
  ),
  _txn(
    id: 10,
    type: TxnType.expense,
    amount: -70000,
    date: DateTime(2026, 9, 20),
    walletId: 2,
    category: 'Ăn uống',
  ),
  _txn(
    id: 11,
    type: TxnType.expense,
    amount: -30000,
    date: DateTime(2026, 9, 21),
    walletId: 1,
    category: 'Khác',
    note: 'ghi chú có chữ dulich',
  ),
];

/// Bộ lọc mặc định = kỳ Tháng 9/2026 (`end` = 00:00 ngày 01/10).
ReportExportFilter _sep2026({
  Set<int> walletIds = const {},
  Set<int> categoryIds = const {},
  String tag = '',
}) => ReportExportFilter(
  start: DateTime(2026, 9, 1),
  end: DateTime(2026, 10, 1),
  walletIds: walletIds,
  categoryIds: categoryIds,
  tag: tag,
);

ReportExportData _build(
  ReportExportFilter filter, {
  ExportFormat format = ExportFormat.pdf,
}) => buildReportExport(
  transactions: _all,
  categories: _categories,
  walletNames: _walletNames,
  filter: filter,
  format: format,
);

List<int> _ids(List<Transaction> list) => [for (final t in list) t.id];

void main() {
  group('filterForExport — khoảng ngày (luật 4)', () {
    test('giao dịch đúng ngày đầu và ngày cuối đều có mặt', () {
      final result = filterForExport(_all, _sep2026(), _categories);
      expect(_ids(result), contains(1)); // 01/09
      expect(_ids(result), contains(2)); // 30/09
    });

    test('giao dịch ngoài khoảng không vào (31/08 và 01/10)', () {
      final result = filterForExport(_all, _sep2026(), _categories);
      expect(_ids(result), isNot(contains(4)));
      expect(_ids(result), isNot(contains(5)));
    });
  });

  group('filterForExport — nhóm ví (luật 2, 12)', () {
    test('nhiều ví là HOẶC', () {
      final result = filterForExport(
        _all,
        _sep2026(walletIds: const {2}),
        _categories,
      );
      expect(_ids(result), [7, 8, 9, 10]);
    });

    test('không group-keep hai vế chuyển khoản', () {
      // Chọn ví 2 ⇒ vế nguồn (ví 1) của cặp chuyển khoản **không** được kéo vào.
      final result = filterForExport(
        _all,
        _sep2026(walletIds: const {2}),
        _categories,
      );
      expect(_ids(result), isNot(contains(6)));
    });

    test('nhóm ví rỗng = không giới hạn', () {
      final result = filterForExport(_all, _sep2026(), _categories);
      expect(_ids(result), contains(1));
      expect(_ids(result), contains(7));
    });
  });

  group('filterForExport — nhóm danh mục (luật 6, 7, 8)', () {
    test('chọn danh mục cha ⇒ gồm cả con', () {
      final result = filterForExport(
        _all,
        _sep2026(categoryIds: const {1}),
        _categories,
      );
      // 1 (cha) + 2 (con) + 10 (dòng cũ không categoryId, khớp theo tên) —
      // sắp theo ngày: 01/09 → 20/09 → 30/09.
      expect(_ids(result), [1, 10, 2]);
    });

    test('dòng cũ không categoryId khớp theo tên đã bỏ dấu', () {
      final result = filterForExport(
        _all,
        _sep2026(categoryIds: const {3}),
        _categories,
      );
      // 9 khớp theo categoryId; dòng 10 tên 'Ăn uống' không thuộc 'Du lịch'.
      expect(_ids(result), [9]);
    });

    test('transfer/adjustment không khớp khi nhóm danh mục được chọn', () {
      final result = filterForExport(
        _all,
        _sep2026(categoryIds: const {1, 3}),
        _categories,
      );
      expect(_ids(result), [1, 9, 10, 2]);
    });

    test('giao dịch thu khớp danh mục thu', () {
      final result = filterForExport(
        _all,
        _sep2026(categoryIds: const {4}),
        _categories,
      );
      expect(_ids(result), [3]);
    });
  });

  group('filterForExport — tag (luật 9, 10)', () {
    test("'dulich', '#dulich', 'DULICH' cho cùng kết quả", () {
      final plain = filterForExport(
        _all,
        _sep2026(tag: 'dulich'),
        _categories,
      );
      final hash = filterForExport(
        _all,
        _sep2026(tag: '#dulich'),
        _categories,
      );
      final upper = filterForExport(
        _all,
        _sep2026(tag: 'DULICH'),
        _categories,
      );
      expect(_ids(plain), [1]);
      expect(_ids(hash), _ids(plain));
      expect(_ids(upper), _ids(plain));
    });

    test("'du lịch' khớp tag 'Du lịch' (bỏ dấu hai vế)", () {
      final result = filterForExport(
        _all,
        _sep2026(tag: 'du lịch'),
        _categories,
      );
      expect(_ids(result), [9]);
    });

    test('tag chỉ có trong ghi chú KHÔNG khớp', () {
      final result = filterForExport(
        _all,
        _sep2026(tag: 'dulich'),
        _categories,
      );
      expect(_ids(result), isNot(contains(11)));
    });

    test('ô tag trắng = không lọc tag', () {
      final result = filterForExport(
        _all,
        _sep2026(tag: '   '),
        _categories,
      );
      expect(_ids(result), hasLength(9));
    });
  });

  group('filterForExport — VÀ giữa các nhóm (luật 1)', () {
    test('ví ∧ danh mục ⇒ chỉ giao dịch thoả cả hai', () {
      final result = filterForExport(
        _all,
        _sep2026(walletIds: const {2}, categoryIds: const {3}),
        _categories,
      );
      expect(_ids(result), [9]);
    });

    test('ví ∧ tag ∧ danh mục rỗng', () {
      final result = filterForExport(
        _all,
        _sep2026(walletIds: const {1}, tag: 'dulich'),
        _categories,
      );
      expect(_ids(result), [1]);
    });
  });

  group('filterForExport — tập kết quả (luật 11, 13)', () {
    test('giữ mọi loại giao dịch + sắp tăng dần theo ngày rồi id', () {
      final result = filterForExport(_all, _sep2026(), _categories);
      expect(_ids(result), [1, 3, 6, 7, 8, 9, 10, 11, 2]);
    });
  });

  group('buildReportExport — số liệu tổng hợp (luật 14, 15, 16)', () {
    test('transfer/adjustment có trong danh sách nhưng không vào con số', () {
      final data = _build(_sep2026());
      expect(data.transactions.map((t) => t.type), contains(TxnType.transfer));
      expect(
        data.transactions.map((t) => t.type),
        contains(TxnType.adjustment),
      );
      expect(data.income, 5000000);
      expect(data.expense, 750000);
    });

    test('income/expense/allocation khớp gọi thẳng reportTotals/reportBreakdown',
        () {
      final filter = _sep2026();
      final data = _build(filter);
      final range = DateRange(start: filter.start, end: filter.end);
      final totals = reportTotals(data.transactions, range);
      expect(data.income, totals.income);
      expect(data.expense, totals.expense);
      final slices = reportBreakdown(
        transactions: data.transactions,
        categories: _categories,
        range: range,
      );
      expect(
        [for (final s in data.allocation) '${s.name}:${s.amount}:${s.percent}'],
        [for (final s in slices) '${s.name}:${s.amount}:${s.percent}'],
      );
    });

    test('kỳ chỉ có chuyển khoản ⇒ danh sách có dòng, con số bằng 0', () {
      final data = _build(
        ReportExportFilter(
          start: DateTime(2026, 9, 10),
          end: DateTime(2026, 9, 11),
        ),
      );
      expect(data.count, 2);
      expect(data.income, 0);
      expect(data.expense, 0);
      expect(data.balance, 0);
    });

    test('rows là bản chiếu 1-1 đúng thứ tự và nội dung', () {
      final data = _build(_sep2026(walletIds: const {2}));
      expect(data.count, 4);
      expect([for (final r in data.rows) r.wallet], everyElement('Ngân hàng'));
      expect(data.rows.first.typeLabel, 'Chuyển khoản');
      expect(data.rows.first.category, '');
      expect(data.rows.first.amount, 1000000);
      expect(data.rows.last.category, 'Ăn uống');
    });

    test('count/isEmpty/balance', () {
      final data = _build(_sep2026());
      expect(data.count, 9);
      expect(data.isEmpty, isFalse);
      expect(data.balance, 4250000);
    });

    test('bộ lọc rỗng ⇒ isEmpty, count 0', () {
      final data = _build(
        ReportExportFilter(
          start: DateTime(2020, 1, 1),
          end: DateTime(2020, 2, 1),
        ),
      );
      expect(data.isEmpty, isTrue);
      expect(data.count, 0);
      expect(data.allocation, isEmpty);
    });
  });

  group('exportFileName (luật 24, 25)', () {
    test('đúng mẫu, ngày cuối trừ 1, đuôi theo định dạng', () {
      expect(
        exportFileName(
          DateTime(2026, 9, 1),
          DateTime(2026, 10, 1),
          ExportFormat.pdf,
        ),
        'bao-cao-thu-chi_20260901-20260930.pdf',
      );
      expect(
        exportFileName(
          DateTime(2026, 9, 1),
          DateTime(2026, 10, 1),
          ExportFormat.excel,
        ),
        'bao-cao-thu-chi_20260901-20260930.xlsx',
      );
      expect(
        exportFileName(
          DateTime(2026, 9, 1),
          DateTime(2026, 10, 1),
          ExportFormat.csv,
        ),
        'bao-cao-thu-chi_20260901-20260930.csv',
      );
    });

    test('tên tệp không đổi theo định dạng ngày của ngôn ngữ', () {
      final data = _build(_sep2026(), format: ExportFormat.csv);
      expect(data.fileName, 'bao-cao-thu-chi_20260901-20260930.csv');
    });
  });

  group('ExportFormat', () {
    test('nhãn không dịch, chú thích có dịch, MIME đúng', () {
      expect(ExportFormat.pdf.label, 'PDF');
      expect(ExportFormat.excel.label, 'Excel');
      expect(ExportFormat.csv.label, 'CSV');
      expect(ExportFormat.pdf.mimeType, 'application/pdf');
      expect(ExportFormat.csv.mimeType, 'text/csv');
      expect(ExportFormat.excel.fileExtension, 'xlsx');
    });
  });

  group('buildCsvBytes (luật 21, 28)', () {
    /// Parser CSV tối thiểu (RFC 4180) — đọc lại để chắc chắn ô chứa `,`/`"`/
    /// xuống dòng không làm lệch cột.
    List<List<String>> parseCsv(String text) {
      final rows = <List<String>>[];
      var cells = <String>[];
      final cell = StringBuffer();
      var inQuotes = false;
      for (var i = 0; i < text.length; i++) {
        final ch = text[i];
        if (inQuotes) {
          if (ch == '"') {
            if (i + 1 < text.length && text[i + 1] == '"') {
              cell.write('"');
              i++;
            } else {
              inQuotes = false;
            }
          } else {
            cell.write(ch);
          }
          continue;
        }
        if (ch == '"') {
          inQuotes = true;
        } else if (ch == ',') {
          cells.add(cell.toString());
          cell.clear();
        } else if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') {
          cells.add(cell.toString());
          cell.clear();
          rows.add(cells);
          cells = <String>[];
          i++;
        } else {
          cell.write(ch);
        }
      }
      cells.add(cell.toString());
      rows.add(cells);
      return rows;
    }

    test('BOM UTF-8 ở đầu tệp và không lặp', () {
      final bytes = buildCsvBytes(_build(_sep2026()).rows);
      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      // Byte thứ 4 mở đầu dòng tiêu đề — không phải BOM thứ hai.
      expect(bytes.sublist(3, 6), isNot([0xEF, 0xBB, 0xBF]));
    });

    test('dòng tiêu đề đúng 7 cột + số dòng = rows.length', () {
      final data = _build(_sep2026());
      final rows = parseCsv(utf8.decode(buildCsvBytes(data.rows).sublist(3)));
      expect(rows.first, [
        'Ngày',
        'Loại',
        'Danh mục',
        'Ví',
        'Số tiền',
        'Ghi chú',
        'Tag',
      ]);
      expect(rows.length, data.rows.length + 1);
    });

    test('ô chứa `,` / `"` / xuống dòng được escape, không lệch cột', () {
      final rows = [
        ExportTxn(
          date: DateTime(2026, 9, 1),
          typeLabel: 'Chi',
          category: 'Ăn uống, cà phê',
          wallet: 'Ví "chính"',
          amount: -15000,
          note: 'dòng 1\ndòng 2',
          tags: 'a,b',
        ),
      ];
      final parsed = parseCsv(utf8.decode(buildCsvBytes(rows).sublist(3)));
      expect(parsed, hasLength(2));
      expect(parsed[1], [
        '01/09/2026',
        'Chi',
        'Ăn uống, cà phê',
        'Ví "chính"',
        '-15000',
        'dòng 1\ndòng 2',
        'a,b',
      ]);
    });

    test('số tiền có dấu, không đơn vị, không phân tách nghìn', () {
      final data = _build(_sep2026());
      final rows = parseCsv(utf8.decode(buildCsvBytes(data.rows).sublist(3)));
      final csv = rows.skip(1).map((r) => r[4]).toList();
      expect(csv, contains('5000000'));
      expect(csv, contains('-300000'));
      expect(csv.any((v) => v.contains(' ') || v.contains('đ')), isFalse);
      expect(csv.any((v) => v.contains('.')), isFalse);
    });

    test('danh sách có dòng chuyển khoản + điều chỉnh số dư (đủ mọi loại)', () {
      final data = _build(_sep2026());
      final rows = parseCsv(utf8.decode(buildCsvBytes(data.rows).sublist(3)));
      final types = rows.skip(1).map((r) => r[1]).toSet();
      expect(types, containsAll(['Thu', 'Chi', 'Chuyển khoản']));
      // Danh mục của dòng chuyển khoản để trống.
      final transferRow = rows.skip(1).firstWhere((r) => r[1] == 'Chuyển khoản');
      expect(transferRow[2], '');
    });

    test('chữ tiếng Việt có dấu giữ nguyên', () {
      final data = _build(_sep2026());
      final text = utf8.decode(buildCsvBytes(data.rows).sublist(3));
      expect(text, contains('Ăn uống'));
      expect(text, contains('Ngân hàng'));
    });
  });

  group('ReportExportFilter — bất biến', () {
    test('toggle hai lần trả về tập rỗng, các hàm with* giữ nguyên phần còn lại',
        () {
      final base = _sep2026(tag: 'abc');
      final on = base.toggleWallet(2).toggleCategory(3);
      expect(on.walletIds, {2});
      expect(on.categoryIds, {3});
      expect(on.tag, 'abc');
      expect(base.toggleWallet(2).toggleWallet(2).walletIds, isEmpty);
      expect(on.clearWallets().walletIds, isEmpty);
      expect(on.clearCategories().categoryIds, isEmpty);
      expect(on.withStart(DateTime(2026, 9, 2)).start, DateTime(2026, 9, 2));
      expect(on.withEnd(DateTime(2026, 9, 29)).lastDay, DateTime(2026, 9, 28));
    });

    test('fromRange kế thừa đúng khoảng', () {
      final filter = ReportExportFilter.fromRange(
        DateRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 10, 1)),
      );
      expect(filter.start, DateTime(2026, 9, 1));
      expect(filter.end, DateTime(2026, 10, 1));
      expect(filter.lastDay, DateTime(2026, 9, 30));
    });
  });
}
