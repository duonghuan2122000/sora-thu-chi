import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
