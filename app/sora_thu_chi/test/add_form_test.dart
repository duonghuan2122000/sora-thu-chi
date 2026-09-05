import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/transaction/add_form.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';

Wallet _wallet(int id) => Wallet(id: id, name: 'Ví $id', type: WalletType.cash, balance: 0);

Category _category() => const Category(
  id: 1,
  name: 'Ăn uống',
  type: CategoryType.expense,
  icon: 'restaurant',
  color: 0xFF3D8C77,
);

void main() {
  group('appendAmountDigit — bỏ số 0 đầu & chặn tràn 12 chữ số', () {
    test('0 + chữ số → ghi đè (bỏ số 0 đầu)', () {
      expect(appendAmountDigit(0, 5), 5);
      expect(appendAmountDigit(0, 0), 0);
    });

    test('nối từng chữ số', () {
      var v = 0;
      for (final d in [1, 2, 5, 0, 0, 0, 0]) {
        v = appendAmountDigit(v, d);
      }
      expect(v, 1250000);
    });

    test('đủ 12 chữ số → chặn tràn giữ nguyên', () {
      const max = 999999999999; // 12 chữ số.
      expect(appendAmountDigit(max, 9), max);
      expect(appendAmountDigit(max, 0), max);
    });

    test('digit ngoài 0..9 → bỏ qua', () {
      expect(appendAmountDigit(12, -1), 12);
      expect(appendAmountDigit(12, 10), 12);
    });
  });

  group('backspaceAmount', () {
    test('0 → 0', () => expect(backspaceAmount(0), 0));
    test('xóa từng số', () {
      expect(backspaceAmount(5), 0);
      expect(backspaceAmount(1234), 123);
      expect(backspaceAmount(1250000), 125000);
    });
  });

  group('missingRequiredFields', () {
    test('thiếu hết → đủ 4 tên (thứ tự cố định)', () {
      expect(
        missingRequiredFields(amount: 0, category: null, wallet: null, date: null),
        ['amount', 'category', 'wallet', 'date'],
      );
    });

    test('amount 0 → có amount', () {
      expect(
        missingRequiredFields(amount: 0, category: _category(), wallet: _wallet(1), date: DateTime.now()),
        ['amount'],
      );
    });

    test('thiếu riêng từng trường → đúng danh sách', () {
      final full = (
        amount: 1000,
        category: _category(),
        wallet: _wallet(1),
        date: DateTime.now(),
      );
      expect(
        missingRequiredFields(amount: full.amount, category: null, wallet: full.wallet, date: full.date),
        ['category'],
      );
      expect(
        missingRequiredFields(amount: full.amount, category: full.category, wallet: null, date: full.date),
        ['wallet'],
      );
      expect(
        missingRequiredFields(amount: full.amount, category: full.category, wallet: full.wallet, date: null),
        ['date'],
      );
    });

    test('đủ dữ liệu → rỗng (hợp lệ)', () {
      expect(
        missingRequiredFields(amount: 1000, category: _category(), wallet: _wallet(1), date: DateTime.now()),
        isEmpty,
      );
    });
  });

  group('isDirty', () {
    final now = DateTime(2026, 9, 5, 9, 41, 30);
    final base = (
      amount: 0,
      category: null as Category?,
      note: '',
      type: TxnType.expense,
    );

    test('form mặc định (Chi, sạch, đúng giờ) → chưa dirty', () {
      expect(
        isDirty(
          amount: base.amount,
          category: base.category,
          note: base.note,
          date: now,
          type: base.type,
          now: now,
        ),
        isFalse,
      );
    });

    test('mỗi điều kiện một mình → dirty', () {
      bool dirty({int? amount, Category? category, String? note, DateTime? date, TxnType? type}) =>
          isDirty(
            amount: amount ?? base.amount,
            category: category ?? base.category,
            note: note ?? base.note,
            date: date ?? now,
            type: type ?? base.type,
            now: now,
          );

      expect(dirty(amount: 1000), isTrue); // số tiền > 0.
      expect(dirty(category: _category()), isTrue); // đã chọn danh mục.
      expect(dirty(note: 'đi chợ'), isTrue); // ghi chú khác rỗng.
      expect(dirty(date: DateTime(2026, 9, 4, 9, 41)), isTrue); // ngày khác now.
      expect(dirty(type: TxnType.income), isTrue); // đổi loại Chi → Thu.
    });
  });
}
