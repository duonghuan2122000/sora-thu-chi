import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

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
}
