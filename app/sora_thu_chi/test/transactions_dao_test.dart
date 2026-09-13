import 'dart:io';

import 'package:drift/drift.dart' show Value, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
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

/// Chèn 1 ví fixture (PBI 32: onCreate không còn seed ví mẫu).
Future<Wallet> _insertWallet(
  DriftWalletRepository repo, {
  String name = 'Ví',
  int balance = 0,
}) =>
    repo.insert(
      Wallet(
        id: 0,
        name: name,
        type: WalletType.cash,
        icon: '💵',
        initialBalance: balance,
        balance: balance,
      ),
    );

void main() {
  group('Transactions drift — performTransfer atomic', () {
    test('onCreate: 0 giao dịch; performTransfer tạo 2 dòng chung group', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      addTearDown(db.close);

      final total = await db.customSelect('SELECT COUNT(*) c FROM transactions').get();
      expect(total.single.read<int>('c'), 0);

      final repo = DriftWalletRepository(db);
      final vcb = await _insertWallet(repo, name: 'Vietcombank', balance: 12800000);
      final momo = await _insertWallet(repo, name: 'Momo', balance: 1450000);
      await repo.performTransfer(
        fromWalletId: vcb.id,
        toWalletId: momo.id,
        amount: 700000,
        date: DateTime(2026, 9, 1),
        note: 'Nạp Momo',
      );

      final groups = await db.customSelect(
        'SELECT id, wallet_id, amount, transfer_group_id, note '
        'FROM transactions WHERE type = \'transfer\' ORDER BY id',
      ).get();
      expect(groups.length, 2);
      final src = groups.first;
      final dst = groups.last;
      expect(src.read<int>('wallet_id'), vcb.id);
      expect(src.read<int>('amount'), -700000);
      expect(src.read<int>('transfer_group_id'), src.read<int>('id'));
      expect(dst.read<int>('wallet_id'), momo.id);
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
      final vcb = await _insertWallet(repo, name: 'Vietcombank', balance: 14800000);
      final momo = await _insertWallet(repo, name: 'Momo', balance: 1450000);

      await repo.performTransfer(
        fromWalletId: vcb.id,
        toWalletId: momo.id,
        amount: 2000000,
        date: DateTime(2026, 9, 5, 9, 30),
        note: 'Nạp tiền ví điện tử',
      );

      final wallets = await repo.loadAll();
      expect(wallets.firstWhere((w) => w.id == vcb.id).balance, 12800000);
      expect(wallets.firstWhere((w) => w.id == momo.id).balance, 3450000);

      final vcbTx = await repo.transactionsOf(vcb.id);
      expect(vcbTx.length, 1);
      final srcLeg = vcbTx.firstWhere(
        (t) => t.type == TxnType.transfer && t.amount == -2000000,
      );
      final momoTx = await repo.transactionsOf(momo.id);
      expect(momoTx.length, 1);
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
      final vcb = await _insertWallet(repo, name: 'Vietcombank', balance: 14800000);
      final momo = await _insertWallet(repo, name: 'Momo', balance: 1450000);

      final before = await repo.loadAll();
      final beforeVcb = before.firstWhere((w) => w.id == vcb.id).balance;
      final beforeMomo = before.firstWhere((w) => w.id == momo.id).balance;

      // Làm giao dịch fail giữa chừng: đã trừ/cộng balance, bước insert vế giao
      // dịch chạm bảng đã bị xóa → ném lỗi; transaction phải rollback toàn bộ.
      await db.customStatement('DROP TABLE transactions');
      await expectLater(
        repo.performTransfer(
          fromWalletId: vcb.id,
          toWalletId: momo.id,
          amount: 2000000,
          date: DateTime(2026, 9, 5, 9, 30),
        ),
        throwsA(anything),
      );

      final after = await repo.loadAll();
      expect(after.firstWhere((w) => w.id == vcb.id).balance, beforeVcb);
      expect(after.firstWhere((w) => w.id == momo.id).balance, beforeMomo);
    });

    test('allTransactions: đủ 2 dòng, cặp transfer map chung transferGroupId', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);
      final vcb = await _insertWallet(repo, name: 'Vietcombank', balance: 14800000);
      final momo = await _insertWallet(repo, name: 'Momo', balance: 1450000);
      await repo.performTransfer(
        fromWalletId: vcb.id,
        toWalletId: momo.id,
        amount: 700000,
        date: DateTime(2026, 9, 1),
      );

      final all = await repo.allTransactions();
      expect(all.length, 2);

      final transfers = all
          .where((t) => t.type == TxnType.transfer)
          .toList()
        ..sort((a, b) => a.amount.compareTo(b.amount));
      expect(transfers.length, 2);
      final src = transfers.first; // vế nguồn −700.000.
      final dst = transfers.last; // vế đích +700.000.
      expect(src.walletId, vcb.id);
      expect(dst.walletId, momo.id);
      expect(src.transferGroupId, isNotNull);
      expect(src.transferGroupId, dst.transferGroupId);
    });
  });

  group('Transactions drift — schema v3: 3 cột tùy chọn (PBI 10, R3)', () {
    test('fresh schema v3: dòng tự ghi mang tags/location, dòng khác rỗng', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);
      final wallet = await _insertWallet(repo, balance: 3200000);

      // Dòng làm giàu tags/location — chèn trực tiếp (repo.addTransaction chưa
      // hỗ trợ 3 cột tùy chọn này ở tầng ghi).
      final row1Id = await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          walletId: wallet.id,
          type: TxnType.expense,
          amount: -85000,
          category: const Value('Ăn uống'),
          transactionDate: DateTime(2026, 9, 1),
          tags: const Value('côngty'),
          location: const Value('123 Láng Hạ, Đống Đa, Hà Nội'),
        ),
      );
      await repo.addTransaction(
        walletId: wallet.id,
        type: TxnType.expense,
        amount: 20000,
        category: const Category(
          id: 1,
          name: 'Di chuyển',
          type: CategoryType.expense,
          icon: 'directions_car',
          color: 0xFF3D8C77,
        ),
        date: DateTime(2026, 9, 2),
      );

      final all = await repo.allTransactions();
      expect(all.length, 2);

      final row1 = all.firstWhere((t) => t.id == row1Id);
      expect(row1.type, TxnType.expense);
      expect(row1.tags, 'côngty');
      expect(row1.location, '123 Láng Hạ, Đống Đa, Hà Nội');
      expect(row1.receiptImage, '');

      final others = all.where((t) => t.id != row1Id).toList();
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

      // (1) Mở lần đầu (schema v3), tự chèn 2 ví (mô phỏng dữ liệu thật đã có
      //     trước upgrade); rồi thay bảng transactions bằng hình dạng v2
      //     (không 3 cột mới) + 2 dòng "cũ".
      final first = AppDatabase(NativeDatabase.createInBackground(file));
      await first.customSelect('SELECT 1').get();
      final firstRepo = DriftWalletRepository(first);
      final vcbBefore = await _insertWallet(firstRepo, name: 'Vietcombank', balance: 14800000);
      final momoBefore = await _insertWallet(firstRepo, name: 'Momo', balance: 1450000);
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
          Variable(vcbBefore.id),
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
          Variable(momoBefore.id),
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
      final old = all.firstWhere((t) => t.walletId == vcbBefore.id);
      expect(old.category, 'Ăn uống');
      expect(old.note, 'Ăn trưa văn phòng');
      expect(old.tags, '');
      expect(old.receiptImage, '');
      expect(old.location, '');
      // Ví đã có trước upgrade không bị phá.
      final wallets = await repo.loadAll();
      expect(wallets.length, 2);
      expect(wallets.firstWhere((w) => w.id == vcbBefore.id).balance, 14800000);

      // performTransfer (PBI 8) vẫn chạy trên DB v2→v3 đã nâng cấp.
      await repo.performTransfer(
        fromWalletId: vcbBefore.id,
        toWalletId: momoBefore.id,
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

    test('category_id map đúng tên cùng type, tên lạ/transfer → null', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);
      final wallet = await _insertWallet(repo, balance: 3200000);
      final expenseCats = await repo.categories(type: CategoryType.expense);
      final anUong = expenseCats.firstWhere((c) => c.name == 'Ăn uống');

      // addTransaction (giao dịch mới) luôn gán category_id đúng.
      await repo.addTransaction(
        walletId: wallet.id,
        type: TxnType.expense,
        amount: 50000,
        category: anUong,
        date: DateTime(2026, 9, 1),
      );
      final matched = (await repo.allTransactions())
          .firstWhere((t) => t.category == 'Ăn uống');
      expect(matched.categoryId, anUong.id);

      // Tên lạ/transfer chèn thẳng qua DB không map category_id → null
      // (chỉ addTransaction/addScannedTransaction mới tự gán id).
      await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          walletId: wallet.id,
          type: TxnType.income,
          amount: 200000,
          category: const Value('Bán đồ cũ'),
          transactionDate: DateTime(2026, 9, 2),
        ),
      );
      final lastRow = (await repo.allTransactions())
          .firstWhere((t) => t.category == 'Bán đồ cũ');
      expect(lastRow.categoryId, isNull);
    });

    test('addTransaction: income/expense bù đúng balance + dòng đúng dấu/id/tên', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);
      final wallet1 = await _insertWallet(repo, name: 'Tiền mặt', balance: 3200000);
      final wallet2 = await _insertWallet(repo, name: 'Vietcombank', balance: 14800000);
      final expenseCats = await repo.categories(type: CategoryType.expense);
      final incomeCats = await repo.categories(type: CategoryType.income);
      final anNgoai = expenseCats.firstWhere((c) => c.name == 'Ăn ngoài');
      final luong = incomeCats.firstWhere((c) => c.name == 'Lương');

      // Chi 85.000 ví Tiền mặt (balance 3.200.000).
      await repo.addTransaction(
        walletId: wallet1.id,
        type: TxnType.expense,
        amount: 85000,
        category: anNgoai,
        date: DateTime(2026, 9, 5, 10, 0),
        note: 'Ăn trưa',
      );
      var w = (await repo.loadAll()).firstWhere((x) => x.id == wallet1.id);
      expect(w.balance, 3115000);
      final txn = (await repo.transactionsOf(wallet1.id)).firstWhere((t) => t.note == 'Ăn trưa');
      expect(txn.type, TxnType.expense);
      expect(txn.amount, -85000);
      expect(txn.category, 'Ăn ngoài');
      expect(txn.categoryId, anNgoai.id);
      expect(txn.note, 'Ăn trưa');
      expect(txn.tags, '');
      expect(txn.transferGroupId, isNull);

      // Thu 500.000 ví Vietcombank (balance 14.800.000).
      await repo.addTransaction(
        walletId: wallet2.id,
        type: TxnType.income,
        amount: 500000,
        category: luong,
        date: DateTime(2026, 9, 5, 11, 30),
      );
      w = (await repo.loadAll()).firstWhere((x) => x.id == wallet2.id);
      expect(w.balance, 15300000);
      final inc = (await repo.transactionsOf(wallet2.id))
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

      // (1) Mở lần đầu (schema v4), tự chèn 2 ví (mô phỏng dữ liệu thật đã có
      //     trước upgrade); rồi giả lập DB cũ v3: bỏ bảng categories, thay
      //     transactions bằng hình dạng v3 (chưa category_id) + 2 dòng cũ,
      //     hạ user_version = 3.
      final first = AppDatabase(NativeDatabase.createInBackground(file));
      await first.customSelect('SELECT 1').get();
      final firstRepo = DriftWalletRepository(first);
      final walletBefore1 = await _insertWallet(firstRepo, name: 'Tiền mặt', balance: 3200000);
      final walletBefore2 = await _insertWallet(firstRepo, name: 'Vietcombank', balance: 14800000);
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
          Variable(walletBefore1.id),
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
          Variable(walletBefore2.id),
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
      final chi = all.firstWhere((t) => t.walletId == walletBefore1.id);
      expect(chi.category, 'Di chuyển');
      expect(chi.categoryId, isNull, reason: 'dòng cũ upgrade giữ category_id null');
      final thu = all.firstWhere((t) => t.walletId == walletBefore2.id);
      expect(thu.categoryId, isNull);
      // Ví đã có trước upgrade không bị phá.
      final wallets = await repo.loadAll();
      expect(wallets.length, 2);
      expect(wallets.firstWhere((w) => w.id == walletBefore2.id).balance, 14800000);

      // addTransaction chạy tốt trên DB v3→v4 (ghi category_id mới).
      final anNgoai = expense.firstWhere((c) => c.name == 'Ăn ngoài');
      await repo.addTransaction(
        walletId: walletBefore1.id,
        type: TxnType.expense,
        amount: 50000,
        category: anNgoai,
        date: DateTime(2026, 9, 5, 12, 0),
      );
      final added = (await repo.transactionsOf(walletBefore1.id)).first;
      expect(added.categoryId, anNgoai.id);
    });
  });
}
