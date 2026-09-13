import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:sora_thu_chi/core/budget/budget.dart';
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
  group('Budgets drift — lưu trữ (schema v7, PBI 21)', () {
    test('insert mặc định is_archived = false', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);

      final saved = await repo.insertBudget(
        Budget(
          id: 0,
          categoryId: 1,
          amount: 3000000,
          period: BudgetPeriod.monthly,
          isRecurring: true,
          startDate: DateTime(2026, 9, 1),
        ),
      );
      expect(saved.isArchived, isFalse);

      final raw = await db
          .customSelect('SELECT is_archived FROM budgets')
          .get();
      expect(raw.single.read<bool>('is_archived'), isFalse);
    });

    test('updateBudget ghi isArchived = true rồi đọc lại; budgets() vẫn trả',
        () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);

      final saved = await repo.insertBudget(
        Budget(
          id: 0,
          categoryId: 1,
          amount: 3000000,
          period: BudgetPeriod.monthly,
          isRecurring: true,
          startDate: DateTime(2026, 9, 1),
        ),
      );
      await repo.updateBudget(saved.copyWith(isArchived: true));

      final all = await repo.budgets();
      // Lọc archived thuộc tầng view — repository không lọc (data-model §Hợp đồng).
      expect(all, hasLength(1));
      expect(all.single.isArchived, isTrue);
      expect(all.single.amount, 3000000);
    });
  });

  group('Budgets drift — migration v6 → v7', () {
    test('DB v6 thiếu cột is_archived → mở lại có cột, dữ liệu cũ nguyên vẹn',
        () async {
      final probe = await _tryMemoryDb();
      if (probe == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      await probe.close();

      final dir = await Directory.systemTemp.createTemp('sora_dao_v6');
      addTearDown(() async {
        try {
          await dir.delete(recursive: true);
        } catch (_) {}
      });
      final file = File(p.join(dir.path, 'v6.sqlite'));

      // (1) Mở lần đầu (v7) rồi giả lập DB cũ v6: thay bảng budgets bằng hình
      //     dạng v6 (chưa is_archived) + 1 dòng cũ, hạ user_version = 6.
      final first = AppDatabase(NativeDatabase.createInBackground(file));
      await first.customSelect('SELECT 1').get();
      await first.customStatement('DROP TABLE budgets');
      await first.customStatement(
        'CREATE TABLE budgets ('
        'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'category_id INTEGER NOT NULL, '
        'amount INTEGER NOT NULL, '
        'period TEXT NOT NULL, '
        'is_recurring INTEGER NOT NULL DEFAULT 1, '
        'start_date INTEGER NOT NULL)',
      );
      await first.customInsert(
        'INSERT INTO budgets (category_id, amount, period, is_recurring, '
        'start_date) VALUES (?, ?, ?, ?, ?)',
        variables: [
          Variable(1),
          Variable(3000000),
          Variable('monthly'),
          Variable(1),
          Variable(1788220800),
        ],
      );
      // DB v6 thật chưa có cột `source` của giao dịch (schema v8, PBI 24) —
      // bỏ đi để mô phỏng đúng hình dạng cũ.
      try {
        await first.customStatement(
          'ALTER TABLE transactions DROP COLUMN source',
        );
      } catch (_) {
        await first.close();
        markTestSkipped('sqlite bản này không hỗ trợ DROP COLUMN — bỏ qua.');
        return;
      }
      await first.customStatement('PRAGMA user_version = 6');
      await first.close();

      // (2) Mở lại → onUpgrade 6→7 addColumn is_archived default false; ngân
      //     sách cũ giữ nguyên số tiền, ví/giao dịch seed còn nguyên.
      final db = AppDatabase(NativeDatabase.createInBackground(file));
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);

      final all = await repo.budgets();
      expect(all, hasLength(1));
      expect(all.single.amount, 3000000);
      expect(all.single.categoryId, 1);
      expect(all.single.period, BudgetPeriod.monthly);
      expect(all.single.isArchived, isFalse);
      expect((await repo.loadAll()).length, 5);
      expect((await repo.allTransactions()).length, 11);
    });
  });

  group('Budgets drift — schema v6 (PBI 20)', () {
    test('bảng budgets rỗng sau khi tạo mới (không seed)', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      addTearDown(db.close);

      final count = await db
          .customSelect('SELECT COUNT(*) c FROM budgets')
          .get();
      expect(count.single.read<int>('c'), 0);
      final repo = DriftWalletRepository(db);
      expect(await repo.budgets(), isEmpty);
    });

    test('insertBudget → budgets() đọc lại đủ 6 trường (id DB sinh, bỏ id vào)',
        () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);

      final saved = await repo.insertBudget(
        Budget(
          id: 999, // bỏ qua — DB sinh
          categoryId: 1,
          amount: 3000000,
          period: BudgetPeriod.monthly,
          isRecurring: true,
          startDate: DateTime(2026, 9, 1, 8, 30),
        ),
      );

      expect(saved.id, isNot(999));
      expect(saved.categoryId, 1);
      expect(saved.amount, 3000000);
      expect(saved.period, BudgetPeriod.monthly);
      expect(saved.isRecurring, isTrue);
      expect(saved.startDate, DateTime(2026, 9, 1, 8, 30));

      final all = await repo.budgets();
      expect(all.length, 1);
      expect(all.single.id, saved.id);
      expect(all.single.categoryId, 1);
      expect(all.single.amount, 3000000);
      expect(all.single.period, BudgetPeriod.monthly);
      expect(all.single.isRecurring, isTrue);
      expect(all.single.startDate, DateTime(2026, 9, 1, 8, 30));
    });

    test('insert giữ mặc định is_recurring = true; enum chu kỳ ghi/đọc đúng',
        () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);

      await repo.insertBudget(
        Budget(
          id: 0,
          categoryId: 2,
          amount: 500000,
          period: BudgetPeriod.weekly,
          isRecurring: true,
          startDate: DateTime(2026, 9, 7),
        ),
      );
      await repo.insertBudget(
        Budget(
          id: 0,
          categoryId: 2,
          amount: 8000000,
          period: BudgetPeriod.yearly,
          isRecurring: false,
          startDate: DateTime(2026, 1, 1),
        ),
      );

      final raw = await db
          .customSelect("SELECT period, is_recurring FROM budgets WHERE amount = 500000")
          .get();
      expect(raw.single.read<String>('period'), 'weekly');
      expect(raw.single.read<bool>('is_recurring'), isTrue);

      final all = await repo.budgets();
      expect(all.map((b) => b.period).toSet(),
          {BudgetPeriod.weekly, BudgetPeriod.yearly});
      expect(all.firstWhere((b) => b.period == BudgetPeriod.yearly).isRecurring,
          isFalse);
    });

    test('updateBudget đổi amount + isRecurring, giữ nguyên dòng khác', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);

      final a = await repo.insertBudget(
        Budget(
          id: 0,
          categoryId: 1,
          amount: 3000000,
          period: BudgetPeriod.monthly,
          isRecurring: true,
          startDate: DateTime(2026, 9, 1),
        ),
      );
      await repo.insertBudget(
        Budget(
          id: 0,
          categoryId: 4,
          amount: 2500000,
          period: BudgetPeriod.monthly,
          isRecurring: true,
          startDate: DateTime(2026, 9, 1),
        ),
      );

      final updated = await repo.updateBudget(
        Budget(
          id: a.id,
          categoryId: 1,
          amount: 4500000,
          period: BudgetPeriod.monthly,
          isRecurring: false,
          startDate: DateTime(2026, 9, 1),
        ),
      );
      expect(updated.amount, 4500000);
      expect(updated.isRecurring, isFalse);

      final all = await repo.budgets();
      expect(all.length, 2);
      final reread = all.firstWhere((b) => b.id == a.id);
      expect(reread.amount, 4500000);
      expect(reread.isRecurring, isFalse);
      expect(all.firstWhere((b) => b.categoryId == 4).amount, 2500000);
    });
  });

  group('Budgets drift — migration v5 → v6', () {
    test('DB v5 thiếu bảng budgets → mở lại tạo bảng, dữ liệu cũ nguyên vẹn',
        () async {
      final probe = await _tryMemoryDb();
      if (probe == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua DAO drift tích hợp.');
        return;
      }
      await probe.close();

      final dir = await Directory.systemTemp.createTemp('sora_dao_v5');
      addTearDown(() async {
        try {
          await dir.delete(recursive: true);
        } catch (_) {}
      });
      final file = File(p.join(dir.path, 'v5.sqlite'));

      // (1) Mở lần đầu (v6) rồi giả lập DB cũ v5: bỏ bảng budgets + cột
      //     `source` của giao dịch (schema v8, PBI 24), hạ version.
      final first = AppDatabase(NativeDatabase.createInBackground(file));
      await first.customSelect('SELECT 1').get();
      await first.customStatement('DROP TABLE budgets');
      try {
        await first.customStatement(
          'ALTER TABLE transactions DROP COLUMN source',
        );
      } catch (_) {
        await first.close();
        markTestSkipped('sqlite bản này không hỗ trợ DROP COLUMN — bỏ qua.');
        return;
      }
      await first.customStatement('PRAGMA user_version = 5');
      await first.close();

      // (2) Mở lại → onUpgrade 5→6 tạo bảng budgets; ví/giao dịch seed còn nguyên.
      final db = AppDatabase(NativeDatabase.createInBackground(file));
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);

      expect(await repo.budgets(), isEmpty);
      expect((await repo.loadAll()).length, 5);
      expect((await repo.allTransactions()).length, 11);

      final saved = await repo.insertBudget(
        Budget(
          id: 0,
          categoryId: 1,
          amount: 3000000,
          period: BudgetPeriod.monthly,
          isRecurring: true,
          startDate: DateTime(2026, 9, 1),
        ),
      );
      expect((await repo.budgets()).single.id, saved.id);
    });
  });
}
