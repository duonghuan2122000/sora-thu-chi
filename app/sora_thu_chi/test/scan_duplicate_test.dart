import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/scan/scan_duplicate.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';

Transaction _txn({
  required int id,
  required int amount,
  required DateTime date,
  TxnType type = TxnType.expense,
}) => Transaction(
  id: id,
  walletId: 1,
  type: type,
  amount: type == TxnType.income ? amount : -amount,
  date: date,
);

void main() {
  final now = DateTime(2026, 9, 12, 8, 24);

  test('cùng số tiền trong 24h → có cảnh báo', () {
    final existing = [_txn(id: 1, amount: 55000, date: DateTime(2026, 9, 12, 7))];
    final found = findRecentDuplicate(existing, amount: 55000, date: now);
    expect(found?.id, 1);
  });

  test('lệch 1 đồng → không', () {
    final existing = [_txn(id: 1, amount: 55001, date: DateTime(2026, 9, 12, 7))];
    expect(findRecentDuplicate(existing, amount: 55000, date: now), isNull);
  });

  test('lệch quá 24h01 → không', () {
    final existing = [
      _txn(id: 1, amount: 55000, date: DateTime(2026, 9, 11, 8, 23)),
    ];
    expect(findRecentDuplicate(existing, amount: 55000, date: now), isNull);
  });

  test('đúng biên 24h → vẫn cảnh báo', () {
    final existing = [
      _txn(id: 1, amount: 55000, date: DateTime(2026, 9, 11, 8, 24)),
    ];
    expect(findRecentDuplicate(existing, amount: 55000, date: now)?.id, 1);
  });

  test('bỏ qua chuyển khoản và điều chỉnh số dư', () {
    final existing = [
      _txn(id: 1, amount: 55000, date: now, type: TxnType.transfer),
      _txn(id: 2, amount: 55000, date: now, type: TxnType.adjustment),
    ];
    expect(findRecentDuplicate(existing, amount: 55000, date: now), isNull);
  });

  test('khoản thu cùng số tiền vẫn tính là trùng', () {
    final existing = [
      _txn(id: 1, amount: 55000, date: now, type: TxnType.income),
    ];
    expect(findRecentDuplicate(existing, amount: 55000, date: now)?.id, 1);
  });

  test('danh sách rỗng → null; nhiều ca khớp → trả ca gần ngày nhất', () {
    expect(findRecentDuplicate(const [], amount: 55000, date: now), isNull);
    final found = findRecentDuplicate(
      [
        _txn(id: 1, amount: 55000, date: DateTime(2026, 9, 11, 9)),
        _txn(id: 2, amount: 55000, date: DateTime(2026, 9, 12, 8)),
      ],
      amount: 55000,
      date: now,
    );
    expect(found?.id, 2);
  });
}
