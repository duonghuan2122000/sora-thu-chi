import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

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
  test('migration schemaVersion 1 + seed 5 ví + CRUD/map field', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    final repo = DriftWalletRepository(db);
    final all = await repo.loadAll();
    expect(all.length, 5);

    // Seed khớp WalletSource: tên + Vietcombank initial_balance khác số dư.
    final names = all.map((w) => w.name).toList();
    expect(
      names,
      ['Tiền mặt', 'Vietcombank', 'Thẻ tín dụng VIB', 'Momo', 'Sổ tiết kiệm'],
    );
    final vc = all.firstWhere((w) => w.name == 'Vietcombank');
    expect(vc.initialBalanceValue, 1200000);
    expect(vc.balance, 14800000);
    expect(vc.currency, 'VND');

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
    final cash = all.firstWhere((w) => w.id == 1);
    final updated = await repo.update(
      cash.copyWith(name: 'Tiền mặt X', balance: 999),
    );
    expect(updated.name, 'Tiền mặt X');
    expect(updated.balance, 999);
    expect(updated.isHidden, isFalse); // không bị ghi đè sang ẩn
    final after = (await repo.loadAll()).firstWhere((w) => w.id == 1);
    expect(after.isHidden, isFalse);
    expect(after.name, 'Tiền mặt X');
  });

  test('schema v2: onCreate seed ví (không phá) + 11 dòng giao dịch mẫu', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    final repo = DriftWalletRepository(db);
    final wallets = await repo.loadAll();
    expect(wallets.length, 5); // seed ví PBI 7 giữ nguyên.

    // Seed giao dịch đủ 11 dòng, đúng ví (data-model §Migration).
    expect((await repo.transactionsOf(1)).length, 2); // Tiền mặt
    expect((await repo.transactionsOf(2)).length, 6); // Vietcombank
    expect((await repo.transactionsOf(3)).length, 2); // VIB
    expect((await repo.transactionsOf(4)).length, 1); // Momo (vế đích transfer)
    expect((await repo.transactionsOf(5)), isEmpty); // Sổ tiết kiệm

    // 2 vế chuyển mẫu liên kết cùng transfer_group_id (VCB − / Momo +).
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
    expect(groupRows[0].read<int>('transfer_group_id'), greaterThan(0));
  });

  test('migration v1→v2: giữ seed ví PBI 7, tạo bảng + seed giao dịch (onUpgrade)', () async {
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

    // (1) Mở DB lần đầu ở schema v2 → onCreate seed đủ ví + giao dịch.
    final first = AppDatabase(NativeDatabase.createInBackground(file));
    final repo1 = DriftWalletRepository(first);
    expect((await repo1.loadAll()).length, 5);
    // Giả lập trạng thái DB "cũ" v1: bỏ bảng giao dịch + danh mục (cả hai chưa
    // tồn tại ở schema v1), hạ user_version.
    await first.customStatement('DROP TABLE transactions');
    await first.customStatement('DROP TABLE categories');
    await first.customStatement('PRAGMA user_version = 1');
    await first.close();

    // (2) Mở lại cùng file → drift chạy onUpgrade 1→2 (chỉ thêm giao dịch).
    final db = AppDatabase(NativeDatabase.createInBackground(file));
    addTearDown(db.close);
    final repo = DriftWalletRepository(db);

    final wallets = await repo.loadAll();
    expect(wallets.length, 5); // seed ví không bị phá khi upgrade.
    expect(wallets.firstWhere((w) => w.id == 2).balance, 14800000);
    expect(wallets.firstWhere((w) => w.id == 5).isHidden, isTrue);

    // Bảng transactions mới + seed 11 dòng.
    expect((await repo.transactionsOf(1)).length, 2);
    expect((await repo.transactionsOf(2)).length, 6);
    expect((await repo.transactionsOf(4)).length, 1);
  });
}
