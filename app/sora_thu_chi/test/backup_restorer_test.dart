import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/backup/backup_data.dart';
import 'package:sora_thu_chi/core/budget/budget.dart';
import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/data/backup_restorer_drift.dart';
import 'package:sora_thu_chi/data/db/app_database.dart';

/// Mở DB drift trong bộ nhớ. Host thiếu sqlite native → trả null (skip-guard,
/// khuôn `budgets_dao_test.dart`).
Future<AppDatabase?> _tryMemoryDb() async {
  try {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    return db;
  } catch (_) {
    return null;
  }
}

final _newData = BackupData(
  wallets: const [
    Wallet(id: 1, name: 'Ví mới', type: WalletType.cash, balance: 999),
  ],
  categories: const [
    Category(
      id: 1,
      name: 'Danh mục mới',
      type: CategoryType.expense,
      icon: 'x',
      color: 0xFF000000,
    ),
  ],
  transactions: [
    Transaction(
      id: 1,
      walletId: 1,
      type: TxnType.expense,
      amount: -999,
      date: DateTime(2026, 1, 1),
    ),
  ],
  budgets: [
    Budget(
      id: 1,
      categoryId: 1,
      amount: 500000,
      period: BudgetPeriod.monthly,
      isRecurring: true,
      startDate: DateTime(2026, 1, 1),
    ),
  ],
  settings: const {'themeMode': 'dark'},
);

void main() {
  test('restore thành công thay thế đúng toàn bộ dữ liệu cũ bằng dữ liệu mới', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua test drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    // Seed dữ liệu "cũ" trước khi restore.
    await db.into(db.wallets).insert(
      WalletsCompanion.insert(
        name: 'Ví cũ',
        walletType: WalletType.bank,
        icon: 'y',
        initialBalance: 111,
        balance: 111,
      ),
    );

    final restorer = BackupRestorer(db);
    await restorer.restore(_newData);

    final wallets = await db.select(db.wallets).get();
    expect(wallets, hasLength(1));
    expect(wallets.single.id, 1);
    expect(wallets.single.name, 'Ví mới');

    final categories = await db.select(db.categories).get();
    expect(categories.single.id, 1);

    final transactions = await db.select(db.transactions).get();
    expect(transactions.single.id, 1);

    final budgets = await db.select(db.budgets).get();
    expect(budgets.single.id, 1);

    final settings = await db.select(db.appSettings).get();
    expect(settings.any((r) => r.key == 'themeMode' && r.value == 'dark'), isTrue);
  });

  test('lỗi giữa chừng → rollback, dữ liệu cũ không mất một phần', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped('Host thiếu sqlite native — bỏ qua test drift tích hợp.');
      return;
    }
    addTearDown(db.close);

    await db.into(db.wallets).insert(
      WalletsCompanion.insert(
        name: 'Ví cũ',
        walletType: WalletType.bank,
        icon: 'y',
        initialBalance: 111,
        balance: 111,
      ),
    );
    await db.into(db.categories).insert(
      CategoriesCompanion.insert(
        name: 'Danh mục cũ',
        type: CategoryType.expense,
        icon: 'z',
        color: 1,
      ),
    );

    // 2 ví cùng id → insert thứ hai vi phạm khoá chính, restore phải rollback
    // toàn bộ (transaction), không để DB nửa vời.
    final broken = BackupData(
      wallets: const [
        Wallet(id: 5, name: 'A', type: WalletType.cash, balance: 0),
        Wallet(id: 5, name: 'B', type: WalletType.cash, balance: 0),
      ],
      categories: const [],
      transactions: const [],
      budgets: const [],
      settings: const {},
    );

    final restorer = BackupRestorer(db);
    await expectLater(restorer.restore(broken), throwsException);

    final wallets = await db.select(db.wallets).get();
    expect(wallets, hasLength(1));
    expect(wallets.single.name, 'Ví cũ', reason: 'dữ liệu cũ phải còn nguyên sau rollback');

    final categories = await db.select(db.categories).get();
    expect(
      categories.any((c) => c.name == 'Danh mục cũ'),
      isTrue,
      reason: 'dữ liệu cũ phải còn nguyên sau rollback',
    );
  });
}
