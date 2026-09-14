import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/backup/backup_data.dart';
import 'package:sora_thu_chi/core/budget/budget.dart';
import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';

void main() {
  test('roundtrip toJson/fromJson giữ nguyên id và quan hệ khoá ngoại', () {
    final data = BackupData(
      wallets: const [
        Wallet(id: 1, name: 'Tiền mặt', type: WalletType.cash, balance: 100000),
        Wallet(
          id: 2,
          name: 'Ngân hàng',
          type: WalletType.bank,
          balance: 500000,
          isDefault: true,
        ),
      ],
      categories: const [
        Category(
          id: 10,
          name: 'Ăn uống',
          type: CategoryType.expense,
          icon: 'food',
          color: 0xFFAABBCC,
        ),
        Category(
          id: 11,
          name: 'Cà phê',
          type: CategoryType.expense,
          icon: 'coffee',
          color: 0xFFAABBCC,
          parentId: 10,
        ),
      ],
      transactions: [
        Transaction(
          id: 100,
          walletId: 1,
          type: TxnType.expense,
          amount: -50000,
          date: DateTime(2026, 9, 1),
          categoryId: 11,
          category: 'Cà phê',
        ),
        Transaction(
          id: 101,
          walletId: 2,
          type: TxnType.transfer,
          amount: 200000,
          date: DateTime(2026, 9, 2),
          transferGroupId: 102,
        ),
      ],
      budgets: [
        Budget(
          id: 1000,
          categoryId: 10,
          amount: 2000000,
          period: BudgetPeriod.monthly,
          isRecurring: true,
          startDate: DateTime(2026, 9, 1),
        ),
      ],
      settings: const {'themeMode': 'dark', 'locale': 'vi'},
    );

    final json = data.toJson();
    final restored = BackupData.fromJson(json);

    expect(restored.wallets.map((w) => w.id), [1, 2]);
    expect(restored.wallets[1].isDefault, isTrue);
    expect(restored.categories.map((c) => c.id), [10, 11]);
    expect(restored.categories[1].parentId, 10);
    expect(restored.transactions.map((t) => t.id), [100, 101]);
    expect(restored.transactions[0].categoryId, 11);
    expect(restored.transactions[1].transferGroupId, 102);
    expect(restored.budgets.single.categoryId, 10);
    expect(restored.settings, {'themeMode': 'dark', 'locale': 'vi'});
    expect(restored.counts, {
      'wallets': 2,
      'categories': 2,
      'transactions': 2,
      'budgets': 1,
    });
  });

  test('fromJson dữ liệu rỗng → mọi danh sách rỗng, không ném', () {
    final data = BackupData.fromJson(const {});
    expect(data.wallets, isEmpty);
    expect(data.categories, isEmpty);
    expect(data.transactions, isEmpty);
    expect(data.budgets, isEmpty);
    expect(data.settings, isEmpty);
  });
}
