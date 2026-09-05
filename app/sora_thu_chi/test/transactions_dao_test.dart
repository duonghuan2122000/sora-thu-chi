import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/data/db/app_database.dart';
import 'package:sora_thu_chi/data/wallet_repository_drift.dart';

/// Mở DB drift trong bộ nhớ. Host thiếu sqlite native → trả null (skip-guard).
Future<AppDatabase?> _tryMemoryDb() async {
  try {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    return db;
  } catch (_) {
    return null;
  }
}

void main() {
  group('Transactions drift — seed v2 + performTransfer atomic', () {
    test('migration v2: seed đủ 11 dòng mẫu, 2 vế transfer chung group', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      addTearDown(db.close);

      final total = await db.customSelect('SELECT COUNT(*) c FROM transactions').get();
      expect(total.single.read<int>('c'), 11);

      final groups = await db.customSelect(
        'SELECT id, wallet_id, amount, transfer_group_id, note '
        'FROM transactions WHERE type = \'transfer\' ORDER BY id',
      ).get();
      // Cặp mẫu: vế nguồn VCB −700.000 (id 8) ↔ vế đích Momo +700.000 (id 11).
      expect(groups.length, 2);
      final src = groups.first;
      final dst = groups.last;
      expect(src.read<int>('wallet_id'), 2);
      expect(src.read<int>('amount'), -700000);
      expect(src.read<int>('transfer_group_id'), src.read<int>('id'));
      expect(dst.read<int>('wallet_id'), 4);
      expect(dst.read<int>('amount'), 700000);
      expect(dst.read<int>('transfer_group_id'), src.read<int>('id'));
      expect(src.read<String>('note'), dst.read<String>('note'));
    });

    test('performTransfer: 2 dòng cùng group + trừ/cộng đúng balance 2 ví', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);

      await repo.performTransfer(
        fromWalletId: 2,
        toWalletId: 4,
        amount: 2000000,
        date: DateTime(2026, 9, 5, 9, 30),
        note: 'Nạp tiền ví điện tử',
      );

      final wallets = await repo.loadAll();
      expect(wallets.firstWhere((w) => w.id == 2).balance, 12800000);
      expect(wallets.firstWhere((w) => w.id == 4).balance, 3450000);

      final vcbTx = await repo.transactionsOf(2);
      expect(vcbTx.length, 7); // 6 mẫu + 1 vế nguồn.
      final srcLeg = vcbTx.firstWhere(
        (t) => t.type == TxnType.transfer && t.amount == -2000000,
      );
      final momoTx = await repo.transactionsOf(4);
      expect(momoTx.length, 2); // 1 mẫu + 1 vế đích.
      final dstLeg = momoTx.firstWhere(
        (t) => t.type == TxnType.transfer && t.amount == 2000000,
      );
      expect(srcLeg.note, dstLeg.note);
      expect(srcLeg.date, dstLeg.date);

      // PBI 10: 2 vế transfer mới mang 3 cột tùy chọn default '' (R3).
      expect(srcLeg.tags, '');
      expect(srcLeg.receiptImage, '');
      expect(srcLeg.location, '');
      expect(dstLeg.tags, '');

      // group = id vế nguồn ghi trước (R7) — đọc thẳng DB.
      final groupRows = await db.customSelect(
        "SELECT id, amount, transfer_group_id FROM transactions "
        "WHERE note = 'Nạp tiền ví điện tử' ORDER BY id",
      ).get();
      expect(groupRows.length, 2);
      expect(groupRows.first.read<int>('transfer_group_id'), groupRows.first.read<int>('id'));
      expect(groupRows.last.read<int>('transfer_group_id'), groupRows.first.read<int>('id'));
    });

    test('lỗi giữa chừng → rollback, không lệch balance một phía (FR-012/015)', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);

      final before = await repo.loadAll();
      final beforeVcb = before.firstWhere((w) => w.id == 2).balance;
      final beforeMomo = before.firstWhere((w) => w.id == 4).balance;

      // Làm giao dịch fail giữa chừng: đã trừ/cộng balance, bước insert vế giao
      // dịch chạm bảng đã bị xóa → ném lỗi; transaction phải rollback toàn bộ.
      await db.customStatement('DROP TABLE transactions');
      await expectLater(
        repo.performTransfer(
          fromWalletId: 2,
          toWalletId: 4,
          amount: 2000000,
          date: DateTime(2026, 9, 5, 9, 30),
        ),
        throwsA(anything),
      );

      final after = await repo.loadAll();
      expect(after.firstWhere((w) => w.id == 2).balance, beforeVcb);
      expect(after.firstWhere((w) => w.id == 4).balance, beforeMomo);
    });

    test('allTransactions: đủ 11 dòng, cặp transfer map chung transferGroupId', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);

      final all = await repo.allTransactions();
      expect(all.length, 11);

      final transfers = all
          .where((t) => t.type == TxnType.transfer)
          .toList()
        ..sort((a, b) => a.amount.compareTo(b.amount));
      expect(transfers.length, 2);
      final src = transfers.first; // vế nguồn −700.000.
      final dst = transfers.last; // vế đích +700.000.
      expect(src.walletId, 2);
      expect(dst.walletId, 4);
      expect(src.transferGroupId, isNotNull);
      expect(src.transferGroupId, dst.transferGroupId);
    });
  });

  group('Transactions drift — schema v3: 3 cột tùy chọn (PBI 10, R3)', () {
    test('fresh schema v3: row 1 mang tags/location, dòng khác rỗng', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);

      final all = await repo.allTransactions();
      expect(all.length, 11);

      // Row 1 (chi 85.000 Tiền mặt) được làm giàu để QA đối chiếu mockup 04.
      final row1 = all.firstWhere((t) => t.id == 1);
      expect(row1.type, TxnType.expense);
      expect(row1.tags, 'côngty');
      expect(row1.location, '123 Láng Hạ, Đống Đa, Hà Nội');
      expect(row1.receiptImage, '');

      // Mọi dòng khác: 3 field tùy chọn default '' → màn ẩn hàng rỗng.
      final others = all.where((t) => t.id != 1).toList();
      expect(
        others.every(
          (t) => t.tags == '' && t.receiptImage == '' && t.location == '',
        ),
        isTrue,
      );
    });

    test('migration v2→v3: giữ dữ liệu cũ, thêm 3 cột default "" (data-model)', () async {
      final probe = await _tryMemoryDb();
      if (probe == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      await probe.close();

      final dir = await Directory.systemTemp.createTemp('sora_dao_v2v3');
      addTearDown(() async {
        try {
          await dir.delete(recursive: true);
        } catch (_) {}
      });
      final file = File(p.join(dir.path, 'v2.sqlite'));

      // (1) Mở lần đầu (schema v3) → bảng wallets seed đủ ví; rồi thay bảng
      //     transactions bằng hình dạng v2 (không 3 cột mới) + 2 dòng "cũ".
      final first = AppDatabase(NativeDatabase.createInBackground(file));
      await first.customSelect('SELECT 1').get();
      // Giả lập DB cũ v2: bỏ bảng categories (chưa tồn tại ở v2) + thay bảng
      //     transactions bằng hình dạng v2 (không 3 cột v3/categoryId).
      await first.customStatement('DROP TABLE categories');
      await first.customStatement('DROP TABLE transactions');
      await first.customStatement(
        'CREATE TABLE transactions ('
        'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'wallet_id INTEGER NOT NULL, '
        'type TEXT NOT NULL, '
        'amount INTEGER NOT NULL, '
        "category TEXT NOT NULL DEFAULT '', "
        "note TEXT NOT NULL DEFAULT '', "
        'transaction_date INTEGER NOT NULL, '
        'transfer_group_id INTEGER)',
      );
      await first.customInsert(
        'INSERT INTO transactions '
        '(wallet_id, type, amount, category, note, transaction_date, '
        'transfer_group_id) VALUES (?, ?, ?, ?, ?, ?, ?)',
        variables: [
          Variable(1),
          Variable('expense'),
          Variable(-85000),
          Variable('Ăn uống'),
          Variable('Ăn trưa văn phòng'),
          Variable(1700000000),
          Variable(null),
        ],
      );
      await first.customInsert(
        'INSERT INTO transactions '
        '(wallet_id, type, amount, category, note, transaction_date, '
        'transfer_group_id) VALUES (?, ?, ?, ?, ?, ?, ?)',
        variables: [
          Variable(2),
          Variable('income'),
          Variable(12000000),
          Variable('Lương'),
          Variable('Lương tháng 8'),
          Variable(1700000000),
          Variable(null),
        ],
      );
      await first.customStatement('PRAGMA user_version = 2');
      await first.close();

      // (2) Mở lại cùng file → onUpgrade 2→3 addColumn 3 cột default ''.
      final db = AppDatabase(NativeDatabase.createInBackground(file));
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);

      // Dữ liệu cũ không mất; 3 cột mới map về domain default ''.
      final all = await repo.allTransactions();
      expect(all.length, 2);
      final old = all.firstWhere((t) => t.walletId == 1);
      expect(old.category, 'Ăn uống');
      expect(old.note, 'Ăn trưa văn phòng');
      expect(old.tags, '');
      expect(old.receiptImage, '');
      expect(old.location, '');
      // Ví seed không bị phá khi upgrade.
      final wallets = await repo.loadAll();
      expect(wallets.length, 5);
      expect(wallets.firstWhere((w) => w.id == 2).balance, 14800000);

      // performTransfer (PBI 8) vẫn chạy trên DB v2→v3 đã nâng cấp.
      await repo.performTransfer(
        fromWalletId: 2,
        toWalletId: 4,
        amount: 1000000,
        date: DateTime(2026, 9, 5, 9, 0),
      );
      final legs = (await repo.allTransactions())
          .where((t) => t.type == TxnType.transfer && t.amount.abs() == 1000000)
          .toList();
      expect(legs.length, 2);
      expect(legs.every((t) => t.tags == ''), isTrue);
    });
  });

  group('Transactions drift — schema v4: categories seed + category_id (PBI 11, R1/R2/R4)', () {
    test('fresh v4: seed đủ 12 cha + 3 con đúng type/parent_id', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);

      final chi = await repo.categories(type: CategoryType.expense);
      final thu = await repo.categories(type: CategoryType.income);
      // 8 cha chi + 3 con (Ăn uống) = 11 expense; 4 thu.
      expect(chi.length, 11);
      expect(thu.length, 4);
      expect(thu.map((c) => c.name), contains('Khác'));

      final parents = [...chi, ...thu].where((c) => c.isParent).toList();
      expect(parents.length, 12);
      expect(parents.map((c) => c.name), containsAll(['Ăn uống', 'Lương']));
      final food = chi.firstWhere((c) => c.name == 'Ăn uống');
      final children = chi.where((c) => c.parentId == food.id).toList();
      expect(children.map((c) => c.name).toSet(), {'Cà phê', 'Ăn ngoài', 'Đi chợ'});
      expect(children.every((c) => c.type == CategoryType.expense), isTrue);
    });

    test('seed giao dịch: category_id map đúng tên cùng type, tên lạ/transfer → null', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);
      final cats = await repo.categories(type: CategoryType.expense);
      final idByName = {for (final c in cats) c.name: c.id};

      final all = await repo.allTransactions();
      // 'Ăn uống' (expense) → gán id; 'Di chuyển' → gán id.
      for (final t in all.where((t) => t.category == 'Ăn uống')) {
        expect(t.categoryId, idByName['Ăn uống']);
      }
      expect(
        all.firstWhere((t) => t.category == 'Di chuyển').categoryId,
        idByName['Di chuyển'],
      );
      // Thu 'Lương' → gán id danh mục thu Lương.
      final income = all.firstWhere((t) => t.category == 'Lương');
      expect(income.categoryId, isNotNull);
      final thuCats = await repo.categories(type: CategoryType.income);
      expect(income.categoryId, thuCats.firstWhere((c) => c.name == 'Lương').id);
      // Tên lạ & transfer → null (không khớp bộ mặc định / không gắn danh mục).
      for (final t in all) {
        if (const {'Bán đồ cũ', 'Thu nhập khác', 'Xăng xe'}.contains(t.category)) {
          expect(t.categoryId, isNull, reason: '${t.category} không nên map id');
        }
        if (t.type == TxnType.transfer) {
          expect(t.categoryId, isNull, reason: 'transfer không gắn danh mục');
        }
      }
    });

    test('addTransaction: income/expense bù đúng balance + dòng đúng dấu/id/tên', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);
      final expenseCats = await repo.categories(type: CategoryType.expense);
      final incomeCats = await repo.categories(type: CategoryType.income);
      final anNgoai = expenseCats.firstWhere((c) => c.name == 'Ăn ngoài');
      final luong = incomeCats.firstWhere((c) => c.name == 'Lương');

      // Chi 85.000 ví Tiền mặt (id 1, balance 3.200.000).
      await repo.addTransaction(
        walletId: 1,
        type: TxnType.expense,
        amount: 85000,
        category: anNgoai,
        date: DateTime(2026, 9, 5, 10, 0),
        note: 'Ăn trưa',
      );
      var w = (await repo.loadAll()).firstWhere((x) => x.id == 1);
      expect(w.balance, 3115000);
      final txn = (await repo.transactionsOf(1)).firstWhere((t) => t.note == 'Ăn trưa');
      expect(txn.type, TxnType.expense);
      expect(txn.amount, -85000);
      expect(txn.category, 'Ăn ngoài');
      expect(txn.categoryId, anNgoai.id);
      expect(txn.note, 'Ăn trưa');
      expect(txn.tags, '');
      expect(txn.transferGroupId, isNull);

      // Thu 500.000 ví Vietcombank (id 2, balance 14.800.000).
      await repo.addTransaction(
        walletId: 2,
        type: TxnType.income,
        amount: 500000,
        category: luong,
        date: DateTime(2026, 9, 5, 11, 30),
      );
      w = (await repo.loadAll()).firstWhere((x) => x.id == 2);
      expect(w.balance, 15300000);
      final inc = (await repo.transactionsOf(2))
          .firstWhere((t) => t.type == TxnType.income && t.amount == 500000);
      expect(inc.amount, 500000);
      expect(inc.category, 'Lương');
      expect(inc.categoryId, luong.id);
    });

    test('migration v3→v4: thêm categories + category_id, giữ dữ liệu giao dịch cũ (null)', () async {
      final probe = await _tryMemoryDb();
      if (probe == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      await probe.close();

      final dir = await Directory.systemTemp.createTemp('sora_dao_v3v4');
      addTearDown(() async {
        try {
          await dir.delete(recursive: true);
        } catch (_) {}
      });
      final file = File(p.join(dir.path, 'v3.sqlite'));

      // (1) Mở lần đầu (schema v4) → seed; rồi giả lập DB cũ v3: bỏ bảng
      //     categories, thay transactions bằng hình dạng v3 (chưa category_id)
      //     + 2 dòng cũ, hạ user_version = 3.
      final first = AppDatabase(NativeDatabase.createInBackground(file));
      await first.customSelect('SELECT 1').get();
      await first.customStatement('DROP TABLE categories');
      await first.customStatement('DROP TABLE transactions');
      await first.customStatement(
        'CREATE TABLE transactions ('
        'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'wallet_id INTEGER NOT NULL, '
        'type TEXT NOT NULL, '
        'amount INTEGER NOT NULL, '
        "category TEXT NOT NULL DEFAULT '', "
        "note TEXT NOT NULL DEFAULT '', "
        'transaction_date INTEGER NOT NULL, '
        'transfer_group_id INTEGER, '
        "tags TEXT NOT NULL DEFAULT '', "
        "receipt_image TEXT NOT NULL DEFAULT '', "
        "location TEXT NOT NULL DEFAULT '')",
      );
      await first.customInsert(
        'INSERT INTO transactions (wallet_id, type, amount, category, note, '
        'transaction_date) VALUES (?, ?, ?, ?, ?, ?)',
        variables: [
          Variable(1),
          Variable('expense'),
          Variable(-120000),
          Variable('Di chuyển'),
          Variable(''),
          Variable(1700000000),
        ],
      );
      await first.customInsert(
        'INSERT INTO transactions (wallet_id, type, amount, category, note, '
        'transaction_date) VALUES (?, ?, ?, ?, ?, ?)',
        variables: [
          Variable(2),
          Variable('income'),
          Variable(12000000),
          Variable('Lương'),
          Variable('Lương tháng 8'),
          Variable(1700000000),
        ],
      );
      await first.customStatement('PRAGMA user_version = 3');
      await first.close();

      // (2) Mở lại → onUpgrade 3→4: tạo + seed categories, thêm cột category_id
      //     (nullable); giao dịch cũ giữ category_id null, dữ liệu không mất.
      final db = AppDatabase(NativeDatabase.createInBackground(file));
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);

      final expense = await repo.categories(type: CategoryType.expense);
      expect(expense.length, 11); // seed đủ sau upgrade.
      expect(
        expense.firstWhere((c) => c.name == 'Ăn ngoài').parentId,
        isNotNull,
      );

      final all = await repo.allTransactions();
      expect(all.length, 2);
      final chi = all.firstWhere((t) => t.walletId == 1);
      expect(chi.category, 'Di chuyển');
      expect(chi.categoryId, isNull, reason: 'dòng cũ upgrade giữ category_id null');
      final thu = all.firstWhere((t) => t.walletId == 2);
      expect(thu.categoryId, isNull);
      // Ví seed không bị phá.
      final wallets = await repo.loadAll();
      expect(wallets.length, 5);
      expect(wallets.firstWhere((w) => w.id == 2).balance, 14800000);

      // addTransaction chạy tốt trên DB v3→v4 (ghi category_id mới).
      final anNgoai = expense.firstWhere((c) => c.name == 'Ăn ngoài');
      await repo.addTransaction(
        walletId: 1,
        type: TxnType.expense,
        amount: 50000,
        category: anNgoai,
        date: DateTime(2026, 9, 5, 12, 0),
      );
      final added = (await repo.transactionsOf(1)).first;
      expect(added.categoryId, anNgoai.id);
    });
  });
}
