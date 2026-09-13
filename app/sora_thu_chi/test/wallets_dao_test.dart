import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/data/db/app_database.dart';
import 'package:sora_thu_chi/data/wallet_repository_drift.dart';

/// Mở DB drift trong bộ nhớ. Host Windows thiếu sqlite native → trả null
/// (test skip-guard, research Q12 — app thật dùng sqlite3_flutter_libs).
Future<AppDatabase?> _tryMemoryDb() async {
  try {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get(); // buộc mở connection
    return db;
  } catch (_) {
    return null;
  }
}

void main() {
  test('onCreate: 0 ví, 0 giao dịch (PBI 32) + CRUD/map field', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    final repo = DriftWalletRepository(db);
    expect(await repo.loadAll(), isEmpty);

    // Map trường optional — tạo ví savings đủ field rồi đọc lại.
    final maturity = DateTime(2027, 1, 15);
    final created = await repo.insert(
      Wallet(
        id: 0,
        name: 'Sổ Agribank',
        type: WalletType.savings,
        icon: '🏷️',
        initialBalance: 5000000,
        balance: 5000000,
        color: 0xFF355070,
        sortOrder: 9,
        termMonths: 12,
        maturityDate: maturity,
        institutionName: 'Agribank',
        lastDigits: '1234',
      ),
    );
    expect(created.id, greaterThan(0));
    expect(created.isHidden, isFalse);

    final reloaded = (await repo.loadAll()).firstWhere((w) => w.id == created.id);
    expect(reloaded.type, WalletType.savings);
    expect(reloaded.termMonths, 12);
    expect(reloaded.maturityDate, maturity);
    expect(reloaded.institutionName, 'Agribank');
    expect(reloaded.lastDigits, '1234');
    expect(reloaded.color, 0xFF355070);

    // update giữ is_hidden cũ (FR-012): ví tiền mặt đang active vẫn active.
    final updated = await repo.update(
      created.copyWith(name: 'Sổ Agribank X', balance: 999),
    );
    expect(updated.name, 'Sổ Agribank X');
    expect(updated.balance, 999);
    expect(updated.isHidden, isFalse); // không bị ghi đè sang ẩn
    final after = (await repo.loadAll()).firstWhere((w) => w.id == created.id);
    expect(after.isHidden, isFalse);
    expect(after.name, 'Sổ Agribank X');
  });

  test('schema v2: onCreate không seed giao dịch (PBI 32); transfer tự tạo hoạt động', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    final repo = DriftWalletRepository(db);
    expect(await repo.loadAll(), isEmpty);

    final cash = await repo.insert(
      Wallet(
        id: 0,
        name: 'Tiền mặt',
        type: WalletType.cash,
        icon: '💵',
        initialBalance: 0,
        balance: 0,
      ),
    );
    final momo = await repo.insert(
      Wallet(
        id: 0,
        name: 'Momo',
        type: WalletType.eWallet,
        icon: '📱',
        initialBalance: 0,
        balance: 0,
      ),
    );
    expect(await repo.transactionsOf(cash.id), isEmpty);
    expect(await repo.transactionsOf(momo.id), isEmpty);

    // 2 vế chuyển tự tạo liên kết cùng transfer_group_id (nguồn − / đích +).
    final sourceId = await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        walletId: cash.id,
        type: TxnType.transfer,
        amount: -700000,
        transactionDate: DateTime(2026, 1, 1),
      ),
    );
    await (db.update(db.transactions)..where((r) => r.id.equals(sourceId)))
        .write(TransactionsCompanion(transferGroupId: Value(sourceId)));
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        walletId: momo.id,
        type: TxnType.transfer,
        amount: 700000,
        transactionDate: DateTime(2026, 1, 1),
        transferGroupId: Value(sourceId),
      ),
    );

    final groupRows = await db.customSelect(
      'SELECT wallet_id, amount, transfer_group_id FROM transactions '
      'WHERE transfer_group_id IS NOT NULL ORDER BY id',
    ).get();
    expect(groupRows.length, 2);
    expect(groupRows[0].read<int>('amount'), -700000);
    expect(groupRows[1].read<int>('amount'), 700000);
    expect(
      groupRows[0].read<int>('transfer_group_id'),
      groupRows[1].read<int>('transfer_group_id'),
    );
  });

  test('migration v1→v2: onUpgrade tạo bảng transactions rỗng, giữ ví đã có', () async {
    // Bỏ qua nếu host thiếu sqlite native.
    final probe = await _tryMemoryDb();
    if (probe == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    await probe.close();

    final dir = await Directory.systemTemp.createTemp('sora_dao_v1v2');
    addTearDown(() async {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });
    final file = File(p.join(dir.path, 'legacy.sqlite'));

    // (1) Mở DB lần đầu ở schema hiện tại → onCreate không seed ví/giao dịch,
    //     tự chèn 1 ví để mô phỏng dữ liệu thật đã có trước khi nâng cấp.
    final first = AppDatabase(NativeDatabase.createInBackground(file));
    final repo1 = DriftWalletRepository(first);
    final wallet = await repo1.insert(
      Wallet(
        id: 0,
        name: 'Tiền mặt',
        type: WalletType.cash,
        icon: '💵',
        initialBalance: 0,
        balance: 14800000,
      ),
    );
    // Giả lập trạng thái DB "cũ" v1: bỏ bảng giao dịch + danh mục (cả hai chưa
    // tồn tại ở schema v1), hạ user_version.
    await first.customStatement('DROP TABLE transactions');
    await first.customStatement('DROP TABLE categories');
    await first.customStatement('PRAGMA user_version = 1');
    await first.close();

    // (2) Mở lại cùng file → drift chạy onUpgrade 1→2 (chỉ tạo bảng, không
    // seed — FR-006: dữ liệu ví đã có không bị đụng tới).
    final db = AppDatabase(NativeDatabase.createInBackground(file));
    addTearDown(db.close);
    final repo = DriftWalletRepository(db);

    final wallets = await repo.loadAll();
    expect(wallets.length, 1); // ví đã có không bị phá khi upgrade.
    expect(wallets.first.id, wallet.id);
    expect(wallets.first.balance, 14800000);

    // Bảng transactions mới, rỗng (PBI 32: không seed nữa).
    expect(await repo.transactionsOf(wallet.id), isEmpty);
  });
}
