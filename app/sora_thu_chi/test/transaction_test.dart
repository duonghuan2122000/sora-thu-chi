import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/transaction/transaction.dart';

void main() {
  Transaction txn(int id, int walletId, {int day = 4}) => Transaction(
    id: id,
    walletId: walletId,
    type: TxnType.expense,
    amount: -1000,
    date: DateTime(2026, 9, day, 12),
  );

  group('transactionsForWallet — lọc đúng ví (FR-008)', () {
    test('chỉ giữ dòng thuộc ví chỉ định, bỏ ví khác', () {
      final list = [txn(1, 1), txn(2, 2), txn(3, 1), txn(4, 2)];

      final inWallet2 = transactionsForWallet(list, 2);

      expect(inWallet2.map((t) => t.id), [2, 4]);
      expect(inWallet2.every((t) => t.walletId == 2), isTrue);
    });

    test('ví không có giao dịch → danh sách rỗng', () {
      expect(transactionsForWallet([txn(1, 2)], 1), isEmpty);
    });
  });

  group('sortNewestFirst — ngày mới nhất lên đầu', () {
    test('ngày khác nhau: giảm dần theo date', () {
      final list = [txn(1, 1, day: 1), txn(2, 1, day: 5), txn(3, 1, day: 3)];

      expect(sortNewestFirst(list).map((t) => t.id), [2, 3, 1]);
    });

    test('trùng ngày: ổn định theo id tăng dần', () {
      final list = [
        txn(3, 1, day: 3),
        txn(1, 1, day: 3),
        txn(2, 1, day: 3),
        txn(4, 1, day: 2),
      ];

      // Ngày 3 lên đầu, trong nhóm giữ thứ tự id 1 → 2 → 3; rồi ngày 2.
      expect(sortNewestFirst(list).map((t) => t.id), [1, 2, 3, 4]);
    });

    test('thuần — không đổi list đầu vào', () {
      final list = [txn(1, 1, day: 1), txn(2, 1, day: 2)];
      final copy = [...list];

      sortNewestFirst(list);

      expect(list.map((t) => t.id), copy.map((t) => t.id));
    });
  });
}
