import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/transaction/transaction_list.dart';

void main() {
  final now = DateTime(2026, 9, 10, 9, 30);

  Transaction txn(
    int id,
    int walletId,
    TxnType type,
    int amount, {
    DateTime? date,
    String note = '',
    String category = '',
    int? group,
  }) => Transaction(
    id: id,
    walletId: walletId,
    type: type,
    amount: amount,
    date: date ?? now,
    note: note,
    category: category,
    transferGroupId: group,
  );

  TxnRow row(int sortId, DateTime date) => TxnRow(
    type: TxnType.income,
    title: 'x',
    subtitle: 'Ví',
    amount: 1000,
    date: date,
    sortId: sortId,
  );

  group('buildDisplayRows — gộp cặp transfer thành 1 dòng (FR-007)', () {
    final names = {1: 'Tiền mặt', 2: 'Vietcombank'};

    test('2 vế chung group → 1 dòng "Chuyển khoản" nguồn → đích, |x|', () {
      final list = [
        txn(1, 1, TxnType.income, 100000, category: 'Lương'),
        txn(2, 1, TxnType.transfer, -500000, group: 50),
        txn(3, 2, TxnType.transfer, 500000, group: 50),
      ];

      final rows = buildDisplayRows(list, names);

      expect(rows.length, 2); // 1 thu + 1 chuyển đã gộp (không thành 2 dòng).
      final transfer = rows.firstWhere((r) => r.type == TxnType.transfer);
      expect(transfer.title, 'Chuyển khoản');
      expect(transfer.subtitle, 'Tiền mặt → Vietcombank');
      expect(transfer.amount, 500000); // |amount|, không dấu.
    });

    test('vế lẻ (group thiếu cặp) → dòng fallback, không crash', () {
      final list = [
        txn(1, 2, TxnType.transfer, -999000, group: 60),
        txn(2, 1, TxnType.income, 1000),
      ];

      final rows = buildDisplayRows(list, names);

      expect(rows.length, 2);
      final odd = rows.firstWhere((r) => r.type == TxnType.transfer);
      expect(odd.title, 'Chuyển khoản');
      expect(odd.amount, 999000); // fallback dương trung tính.
      expect(odd.subtitle, 'Vietcombank');
    });

    test('transfer không có group → giữ từng dòng riêng', () {
      final list = [
        txn(1, 1, TxnType.transfer, -200000),
        txn(2, 2, TxnType.transfer, 200000),
      ];

      final rows = buildDisplayRows(list, names);

      expect(rows.length, 2);
      expect(rows.every((r) => r.type == TxnType.transfer), isTrue);
    });

    test('ref mở chi tiết: đúng 1 trong 2 khác null (R2, PBI 10)', () {
      final list = [
        txn(1, 1, TxnType.income, 100000, category: 'Lương'),
        txn(2, 1, TxnType.expense, -50000),
        txn(3, 2, TxnType.adjustment, -3000),
        txn(4, 2, TxnType.transfer, -700000, group: 50),
        txn(5, 4, TxnType.transfer, 700000, group: 50),
        txn(6, 3, TxnType.transfer, -999000, group: 60), // vế lẻ (thiếu cặp).
      ];

      final rows = buildDisplayRows(list, {1: 'A', 2: 'B', 3: 'C', 4: 'D'});

      // Dòng transfer đã gộp → ref theo group, không mang id bút toán.
      final merged = rows.firstWhere((r) => r.amount == 700000);
      expect(merged.detailGroupId, 50);
      expect(merged.detailTransactionId, isNull);

      // Dòng thường (thu/chi/adjustment) → ref theo id bút toán.
      TxnRow byId(int id) =>
          rows.firstWhere((r) => r.detailTransactionId == id);
      expect(byId(1).title, 'Lương');
      expect(byId(1).detailGroupId, isNull);
      expect(byId(2).title, 'Chi');
      expect(byId(3).title, 'Điều chỉnh số dư');
      // Vế lẻ (group 60 thiếu cặp) → xử như dòng thường, ref theo id (R2).
      final odd = byId(6);
      expect(odd.title, 'Chuyển khoản');
      expect(odd.detailGroupId, isNull);

      // Mọi dòng đúng 1 trong 2 ref khác null (điều kiện assert ref).
      for (final r in rows) {
        expect(
          (r.detailTransactionId == null) != (r.detailGroupId == null),
          isTrue,
          reason: 'Dòng phải mang đúng 1 ref detail: ${r.title}',
        );
      }
    });

    test('dòng phụ thu/chi: "Ví · ghi chú"; không ghi chú → chỉ tên ví', () {
      final rows = buildDisplayRows([
        txn(1, 1, TxnType.expense, -85000, category: 'Ăn uống', note: 'Ăn trưa'),
        txn(2, 2, TxnType.expense, -45000, category: 'Xăng xe'),
      ], names);

      expect(rows[0].subtitle, 'Tiền mặt · Ăn trưa');
      expect(rows[1].subtitle, 'Vietcombank');
    });
  });

  group('groupDisplayRows — nhóm ngày mới nhất trên + header (FR-004/005)', () {
    test('thứ tự nhóm giảm dần, header HÔM NAY/HÔM QUA/dd/MM/yyyy', () {
      final groups = groupDisplayRows([
        row(1, DateTime(2026, 9, 5, 9, 0)), // 5 ngày trước.
        row(1, DateTime(2026, 9, 9, 9, 0)), // hôm qua.
        row(1, DateTime(2026, 9, 10, 9, 0)), // hôm nay.
      ], now: now);

      expect(groups.map((g) => g.header), [
        'HÔM NAY - 10/09/2026',
        'HÔM QUA - 09/09/2026',
        '05/09/2026',
      ]);
    });

    test('trùng ngày giờ → thứ tự ổn định theo sortId tăng (SC-004)', () {
      final sameTime = DateTime(2026, 9, 10, 12, 0);
      final groups = groupDisplayRows([
        row(2, sameTime),
        row(1, sameTime),
        row(3, DateTime(2026, 9, 9, 12, 0)),
      ], now: now);

      // Nhóm mới nhất (10/09) chứa 2 dòng trùng giờ → giữ sortId tăng [1, 2].
      expect(groups.first.rows.map((r) => r.sortId), [1, 2]);
    });

    test('giao dịch đặt lịch tương lai → nhóm nằm trên nhóm quá khứ', () {
      final groups = groupDisplayRows([
        row(1, DateTime(2026, 9, 8)),
        row(1, DateTime(2026, 9, 15)), // tương lai.
      ], now: now);

      expect(groups.first.day, DateTime(2026, 9, 15));
    });
  });

  group('monthlyIncomeExpense — Thu/Chi tháng này (FR-002/003/008)', () {
    test('đúng tổng; bỏ transfer & adjustment; bỏ tương lai cùng tháng', () {
      final list = [
        txn(1, 1, TxnType.income, 100000, date: DateTime(2026, 9, 5)),
        txn(2, 2, TxnType.income, 50000, date: DateTime(2026, 9, 10)),
        txn(3, 1, TxnType.expense, -20000, date: DateTime(2026, 9, 9)),
        txn(4, 1, TxnType.transfer, -70000, group: 1,
            date: DateTime(2026, 9, 8)),
        txn(5, 2, TxnType.transfer, 70000, group: 1,
            date: DateTime(2026, 9, 8)),
        txn(6, 1, TxnType.adjustment, -3000, date: DateTime(2026, 9, 7)),
        txn(7, 2, TxnType.income, 6000, date: DateTime(2026, 9, 12)),
        txn(8, 1, TxnType.expense, -40000, date: DateTime(2026, 8, 31)),
      ];

      final stat = monthlyIncomeExpense(list, now);

      expect(stat.incomeTotal, 150000); // 100.000 + 50.000; tương lai không tính.
      expect(stat.expenseTotal, 20000); // chuyển/điều chỉnh/tháng trước không tính.
    });

    test('ví ẩn vẫn tính (giữ lịch sử & báo cáo)', () {
      // Ví 99 không tồn tại trong "bộ ví" — hàm thuần không lọc theo ví.
      final list = [
        txn(1, 99, TxnType.income, 30000, date: DateTime(2026, 9, 3)),
        txn(2, 99, TxnType.expense, -5000, date: DateTime(2026, 9, 4)),
      ];

      final stat = monthlyIncomeExpense(list, now);

      expect(stat.incomeTotal, 30000);
      expect(stat.expenseTotal, 5000);
    });

    test('không có thu/chi trong tháng → 0 đ cả hai', () {
      final list = [
        txn(1, 1, TxnType.transfer, -1000, group: 1,
            date: DateTime(2026, 9, 8)),
        txn(2, 2, TxnType.transfer, 1000, group: 1,
            date: DateTime(2026, 9, 8)),
      ];

      final stat = monthlyIncomeExpense(list, now);

      expect(stat.incomeTotal, 0);
      expect(stat.expenseTotal, 0);
    });
  });

  group('categoryGlyph — glyph tạm + fallback (R5)', () {
    test('danh mục quen thuộc → glyph tương ứng', () {
      expect(categoryGlyph('Ăn uống'), Icons.restaurant);
      expect(categoryGlyph('Lương'), Icons.payments);
      expect(categoryGlyph('Di chuyển'), Icons.directions_car);
    });

    test('danh mục lạ → fallback chung, không crash', () {
      expect(categoryGlyph('Thú cưng'), Icons.receipt_long);
      expect(categoryGlyph(''), Icons.receipt_long);
    });
  });
}
