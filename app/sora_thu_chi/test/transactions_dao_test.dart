import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });
}
