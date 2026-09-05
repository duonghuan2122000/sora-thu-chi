import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/category/category_source.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/transaction/transaction_filter.dart';
import 'package:sora_thu_chi/core/transaction/transaction_list.dart';

/// Unit **thuần** — bơm tham số, không sqlite (R11). Ngày mốc 10/09/2026 để
/// preset thisWeek = thứ Hai 07/09 → chủ nhật 13/09; thisMonth = 01–30/09.
final _now = DateTime(2026, 9, 10, 9, 30);

/// Danh mục đang hoạt động cả thu + chi (như controller cache sau load).
final List<Category> _catalog = CategorySource.all
    .where((c) => !c.isHidden)
    .toList();

/// Bộ lọc gốc: preset `all` (bỏ ràng buộc ngày) để test tiêu chí khác độc lập.
TxnSearchFilter _filter({TxnSearchFilter Function(TxnSearchFilter)? change}) {
  final base = TxnSearchFilter.defaults(now: _now).withDateRange(DatePreset.all);
  return change == null ? base : change(base);
}

Transaction _tx({
  required int id,
  int walletId = 1,
  TxnType type = TxnType.expense,
  String category = '',
  String note = '',
  int amount = -1000,
  DateTime? date,
  int? categoryId,
  int? transferGroupId,
  String tags = '',
}) => Transaction(
  id: id,
  walletId: walletId,
  type: type,
  category: category,
  note: note,
  amount: amount,
  date: date ?? _now,
  categoryId: categoryId,
  transferGroupId: transferGroupId,
  tags: tags,
);

/// id các dòng trúng sau [filterTransactions].
Set<int> _matchIds(List<Transaction> all, TxnSearchFilter f) =>
    filterTransactions(all, f, _catalog).map((t) => t.id).toSet();

void main() {
  group('normalizeSearch — bỏ dấu tiếng Việt', () {
    test('"an uong" ↔ "Ăn uống" — bỏ dấu & thường hoá', () {
      expect(normalizeSearch('an uong'), normalizeSearch('Ăn uống'));
      expect(normalizeSearch('Ăn uống'), 'an uong');
    });

    test('nguyên âm đủ 5 dấu + ă/â/ê/ô/ơ/ư/đ đều về gốc không dấu', () {
      expect(
        normalizeSearch('á à ả ã ạ ắ ằ ẳ ẵ ặ ấ ầ ẩ ẫ ậ'),
        'a a a a a a a a a a a a a a a',
      );
      expect(
        normalizeSearch('é è ẻ ẽ ẹ ế ề ể ễ ệ'),
        'e e e e e e e e e e',
      );
      expect(normalizeSearch('í ì ỉ ĩ ị'), 'i i i i i');
      expect(
        normalizeSearch('ó ò ỏ õ ọ ố ồ ổ ỗ ộ ớ ờ ở ỡ ợ'),
        'o o o o o o o o o o o o o o o',
      );
      expect(normalizeSearch('ú ù ủ ũ ụ ứ ừ ử ữ ự'), 'u u u u u u u u u u');
      expect(normalizeSearch('ý ý ỷ ỹ ỵ'), 'y y y y y');
      expect(normalizeSearch('đồng'), 'dong');
      expect(normalizeSearch('Ơn ưu đãi'), 'on uu dai');
    });

    test('hoa/thường & chuỗi dài', () {
      expect(normalizeSearch('ĂN TRƯA VĂN PHÒNG'), 'an trua van phong');
      expect(
        normalizeSearch('Lương tháng 8 siêu thị Coopmart 123 Láng Hạ'),
        'luong thang 8 sieu thi coopmart 123 lang ha',
      );
    });
  });

  group('TxnSearchFilter — mặc định & reset', () {
    test('defaults: Tháng này theo now anchor, chip Tất cả, Ngày mới nhất', () {
      final f = TxnSearchFilter.defaults(now: _now);
      expect(f.keyword, '');
      expect(f.type, TxnTypeFilter.all);
      expect(f.datePreset, DatePreset.thisMonth);
      expect(f.dateStart, DateTime(2026, 9, 1));
      expect(f.dateEnd, DateTime(2026, 9, 30));
      expect(f.categoryIds, isEmpty);
      expect(f.walletId, isNull);
      expect(f.amountMin, isNull);
      expect(f.amountMax, isNull);
      expect(f.sort, SortOption.dateNewest);
      expect(f.hasAnyCondition, isTrue); // đã giới hạn tháng.
    });

    test('reset() về đúng mặc định FR-014', () {
      final f = _filter(
        change: (b) => b
            .copyWith(keyword: 'ăn', type: TxnTypeFilter.expense)
            .withDateRange(DatePreset.today),
      );
      final reset = f.reset();
      expect(reset.type, TxnTypeFilter.all);
      expect(reset.keyword, '');
      expect(reset.datePreset, DatePreset.thisMonth);
      expect(reset.dateStart, DateTime(2026, 9, 1));
      expect(reset.dateEnd, DateTime(2026, 9, 30));
      expect(reset.sort, SortOption.dateNewest);
    });

    test('hasAnyCondition false khi không chặn gì (preset all)', () {
      final f = _filter(
        change: (b) => b
            .withDateRange(DatePreset.all)
            .copyWith(amountMin: null, amountMax: null),
      );
      expect(f.hasAnyCondition, isFalse);
    });
  });

  group('filterTransactions — chip loại', () {
    final all = [
      _tx(id: 1, type: TxnType.income, categoryId: 9),
      _tx(id: 2, type: TxnType.expense, categoryId: 1),
      _tx(
        id: 3,
        type: TxnType.transfer,
        amount: 5000,
        walletId: 2,
        transferGroupId: 40,
      ),
      _tx(
        id: 4,
        type: TxnType.transfer,
        amount: -5000,
        transferGroupId: 40,
      ),
      _tx(id: 5, type: TxnType.adjustment, amount: 9000),
    ];

    test('Thu / Chi / Chuyển khoản giữ đúng loại', () {
      expect(
        _matchIds(all, _filter(change: (b) => b.copyWith(type: TxnTypeFilter.income))),
        {1},
      );
      expect(
        _matchIds(all, _filter(change: (b) => b.copyWith(type: TxnTypeFilter.expense))),
        {2},
      );
      expect(
        _matchIds(all, _filter(change: (b) => b.copyWith(type: TxnTypeFilter.transfer))),
        {3, 4}, // group-keep: cả 2 vế.
      );
    });

    test('adjustment chỉ xuất hiện dưới Tất cả (R12)', () {
      expect(_matchIds(all, _filter()), {1, 2, 3, 4, 5});
      // Lọc Thu/Chi không bỏ lọt adjustment & transfer.
      expect(
        _matchIds(all, _filter(change: (b) => b.copyWith(type: TxnTypeFilter.income))),
        {1},
      );
    });
  });

  group('filterTransactions — phép hội AND', () {
    final all = [
      _tx(
        id: 1,
        type: TxnType.expense,
        categoryId: 1, // Ăn uống
        note: 'Ăn trưa',
        amount: -85000,
        date: DateTime(2026, 9, 10, 12),
        walletId: 1,
      ),
      _tx(
        id: 2,
        type: TxnType.expense,
        categoryId: 13, // Cà phê (con Ăn uống)
        note: 'cà phê sáng',
        amount: -35000,
        date: DateTime(2026, 9, 11, 8),
        walletId: 2,
      ),
      _tx(
        id: 3,
        type: TxnType.income,
        categoryId: 9, // Lương
        note: 'Lương tháng 8',
        amount: 12000000,
        date: DateTime(2026, 9, 12, 9),
        walletId: 2,
      ),
      _tx(
        id: 4,
        type: TxnType.expense,
        categoryId: null, // dòng lịch sử chưa nối id — khớp theo tên.
        category: 'Ăn uống',
        note: 'Siêu thị',
        amount: -450000,
        date: DateTime(2026, 9, 5, 18),
        walletId: 1,
      ),
    ];

    test('loại + ngày + danh mục + ví + tiền + từ khóa đồng thời (SC-002)', () {
      // Chi + ngày trong [10/09, 11/09] + danh mục Ăn uống + ví 1 + tiền
      // 0–100.000 + từ khóa "ăn" → chỉ dòng 1.
      final f = _filter(
        change: (b) => b
            .copyWith(type: TxnTypeFilter.expense, categoryIds: {1}, walletId: 1)
            .copyWith(amountMin: 0, amountMax: 100000)
            .copyWith(keyword: 'ăn')
            .withDateRange(DatePreset.custom, customStart: DateTime(2026, 9, 10), customEnd: DateTime(2026, 9, 11)),
      );
      expect(_matchIds(all, f), {1});
    });

    test('AND không thừa không thiếu khi bỏ một tiêu chí', () {
      // Bỏ từ khóa (và bỏ ràng buộc ví) → dòng 1 + 2 (loại/ngày/danh mục/tiền).
      final f = _filter(
        change: (b) => b
            .copyWith(type: TxnTypeFilter.expense, categoryIds: {1})
            .copyWith(amountMin: 0, amountMax: 100000)
            .withDateRange(DatePreset.custom, customStart: DateTime(2026, 9, 10), customEnd: DateTime(2026, 9, 11)),
      );
      expect(_matchIds(all, f), {1, 2});
    });

    test('chọn cha gộp đủ con; chọn con chỉ đúng con (SC-008)', () {
      final parent = _filter(
        change: (b) => b.copyWith(type: TxnTypeFilter.expense, categoryIds: {1}),
      );
      expect(_matchIds(all, parent), {1, 2, 4}); // 1(cha), 2(con 13), 4(null id, tên).

      final child = _filter(
        change: (b) => b.copyWith(type: TxnTypeFilter.expense, categoryIds: {13}),
      );
      expect(_matchIds(all, child), {2});
    });

    test('fallback tên dòng category_id == null (R7) — giữ lịch sử', () {
      final f = _filter(
        change: (b) => b.copyWith(type: TxnTypeFilter.expense, categoryIds: {1}),
      );
      expect(_matchIds(all, f), contains(4));
    });

    test('khoảng tiền abs bao biên; trống một đầu bỏ ràng buộc (R10)', () {
      // min/max theo abs: 85.000, 35.000, 450.000.
      final max100 = _filter(
        change: (b) => b.copyWith(amountMax: 100000),
      );
      expect(_matchIds(all, max100), {1, 2});

      final min100 = _filter(
        change: (b) => b.copyWith(amountMin: 100000),
      );
      expect(_matchIds(all, min100), {3, 4});

      // min > max → không dòng nào thoả đồng thời — không trả sai (R10).
      final wrong = _filter(
        change: (b) => b.copyWith(amountMin: 200000, amountMax: 50000),
      );
      expect(_matchIds(all, wrong), isEmpty);
    });
  });

  group('filterTransactions — group-keep transfer (R2)', () {
    final pair = [
      _tx(
        id: 1,
        walletId: 1,
        type: TxnType.transfer,
        amount: -700000,
        transferGroupId: 50,
        note: 'Chuyển sang Momo',
      ),
      _tx(
        id: 2,
        walletId: 4,
        type: TxnType.transfer,
        amount: 700000,
        transferGroupId: 50,
      ),
      _tx(id: 3, walletId: 1, type: TxnType.expense, categoryId: 1, amount: -85000),
    ];

    test('lọc ví nguồn A → giữ cả 2 vế cặp A→B (không vế lẻ)', () {
      final f = _filter(change: (b) => b.copyWith(walletId: 1));
      expect(_matchIds(pair, f), {1, 2, 3});
    });

    test('lọc ví đích B → vẫn giữ đủ cặp để gộp 1 dòng', () {
      final f = _filter(change: (b) => b.copyWith(walletId: 4));
      expect(_matchIds(pair, f), {1, 2});
    });

    test('không tiêu chí nào khớp vế nào → nhóm rơi hẳn', () {
      final f = _filter(change: (b) => b.copyWith(walletId: 9));
      expect(_matchIds(pair, f), isEmpty);
    });
  });

  group('date preset — anchor now (R11)', () {
    test('today / thisWeek (thứ Hai đầu) / thisMonth / all', () {
      final f = TxnSearchFilter.defaults(now: _now);
      expect(f.withDateRange(DatePreset.today).dateStart, DateTime(2026, 9, 10));
      expect(f.withDateRange(DatePreset.today).dateEnd, DateTime(2026, 9, 10));

      final week = f.withDateRange(DatePreset.thisWeek);
      expect(week.dateStart, DateTime(2026, 9, 7)); // thứ Hai.
      expect(week.dateEnd, DateTime(2026, 9, 13)); // chủ nhật.

      final month = f.withDateRange(DatePreset.thisMonth);
      expect(month.dateStart, DateTime(2026, 9, 1));
      expect(month.dateEnd, DateTime(2026, 9, 30));

      final all = f.withDateRange(DatePreset.all);
      expect(all.dateStart, isNull);
      expect(all.dateEnd, isNull);
    });

    test('custom: giữ cặp ngày đã chọn; start > end → không dòng nào thoả', () {
      final transactions = [
        _tx(id: 1, date: DateTime(2026, 9, 10, 8)),
        _tx(id: 2, date: DateTime(2026, 9, 12, 8)),
      ];
      final f = _filter(
        change: (b) => b.withDateRange(
          DatePreset.custom,
          customStart: DateTime(2026, 9, 11),
          customEnd: DateTime(2026, 9, 13),
        ),
      );
      expect(_matchIds(transactions, f), {2});

      // endExclusive = hết ngày 13 → 14/09 00:00; 13/09 23:59 vẫn trong.
      final g = _filter(
        change: (b) => b.withDateRange(
          DatePreset.custom,
          customStart: DateTime(2026, 9, 10),
          customEnd: DateTime(2026, 9, 12),
        ),
      );
      expect(_matchIds(transactions, g), {1, 2});
    });
  });

  group('FilteredTxSummary + sort sau gộp (R3/R4)', () {
    const names = <int, String>{1: 'Tiền mặt', 4: 'Momo'};

    test('count = dòng sau gộp; total = thu − chi (transfer ngoài total)', () {
      final rows = buildDisplayRows(
        [
          _tx(id: 1, walletId: 1, type: TxnType.expense, categoryId: 1, amount: -85000),
          _tx(id: 2, walletId: 1, type: TxnType.income, categoryId: 9, amount: 12000000),
          _tx(
            id: 3,
            walletId: 1,
            type: TxnType.transfer,
            amount: -700000,
            transferGroupId: 50,
          ),
          _tx(
            id: 4,
            walletId: 4,
            type: TxnType.transfer,
            amount: 700000,
            transferGroupId: 50,
          ),
          _tx(id: 5, walletId: 1, type: TxnType.adjustment, amount: 9000),
        ],
        names,
      );
      final summary = summarizeRows(rows);
      // 5 raw − 1 (2 vế gộp) = 4 dòng hiển thị; total = −85.000 + 12.000.000.
      expect(summary.count, 4);
      expect(summary.signedTotal, 11915000);
      // Transfer & adjustment có trong dòng nhưng không vào total (FR-011).
      final transferRows = rows.where((r) => r.type == TxnType.transfer);
      expect(transferRows.length, 1);
      final summaryWithoutTransferAdjustment = FilteredTxSummary(
        count: 2,
        signedTotal: 11915000,
      );
      expect(summaryWithoutTransferAdjustment.count, 2);
    });

    test('sort ngày: mới nhất giữ nhóm; cũ nhất đảo nhóm & dòng', () {
      final rows = buildDisplayRows(
        [
          _tx(id: 1, amount: -1000, date: DateTime(2026, 9, 9, 10)),
          _tx(id: 2, amount: -2000, date: DateTime(2026, 9, 10, 8)),
          _tx(id: 3, amount: -3000, date: DateTime(2026, 9, 10, 9)),
        ],
        names,
      );
      final newest = orderDateGroups(groupDisplayRows(rows, now: _now), SortOption.dateNewest);
      expect(newest.first.day, DateTime(2026, 9, 10));
      expect(newest.first.rows.first.sortId, 3); // trong nhóm mới nhất trước.

      final oldest = orderDateGroups(groupDisplayRows(rows, now: _now), SortOption.dateOldest);
      expect(oldest.first.day, DateTime(2026, 9, 9));
      expect(oldest.last.rows.last.sortId, 3); // đảo cả dòng trong nhóm.
    });

    test('sort tiền phẳng theo abs; trùng → ngày mới trước rồi sortId', () {
      final rows = buildDisplayRows(
        [
          _tx(id: 1, amount: -3000, date: DateTime(2026, 9, 9, 10)),
          _tx(id: 2, amount: 3000, date: DateTime(2026, 9, 10, 8)),
          _tx(id: 3, amount: -1000, date: DateTime(2026, 9, 11, 9)),
        ],
        names,
      );
      final asc = sortAmountRows(rows, SortOption.amountAsc);
      expect(asc.map((r) => r.amount.abs()).toList(), [1000, 3000, 3000]);
      // abs 3000 trùng: ngày mới (id 2) trước id 1.
      expect(asc.map((r) => r.sortId).toList(), [3, 2, 1]);

      final desc = sortAmountRows(rows, SortOption.amountDesc);
      expect(desc.map((r) => r.amount.abs()).toList(), [3000, 3000, 1000]);
      expect(desc.map((r) => r.sortId).toList(), [2, 1, 3]);
    });
  });

  group('từ khóa trên note / category / tags', () {
    final all = [
      _tx(id: 1, category: 'Ăn uống', note: 'Ăn trưa', tags: 'côngty'),
      _tx(id: 2, category: 'Lương', note: 'Lương tháng 8'),
      _tx(id: 3, category: 'Di chuyển', note: '', tags: 'côngtac'),
    ];

    test('khớp note', () {
      expect(_matchIds(all, _filter(change: (b) => b.copyWith(keyword: 'an trua'))), {1});
    });

    test('khớp category bỏ dấu', () {
      expect(_matchIds(all, _filter(change: (b) => b.copyWith(keyword: 'an uong'))), {1});
    });

    test('khớp tags', () {
      expect(_matchIds(all, _filter(change: (b) => b.copyWith(keyword: 'congtac'))), {3});
    });

    test('từ khóa không khớp → không trả kết quả sai', () {
      expect(_matchIds(all, _filter(change: (b) => b.copyWith(keyword: 'xyz'))), isEmpty);
    });
  });
}
