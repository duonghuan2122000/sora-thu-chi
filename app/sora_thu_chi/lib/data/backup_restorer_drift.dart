import 'package:drift/drift.dart';

import '../core/backup/backup_data.dart';
import 'db/app_database.dart';

/// Khóa `AppSettings` **loại trừ** khi khôi phục (T032/data-model.md ghi chú
/// `BackupData.settings`) — cấu hình tự động sao lưu là của **thiết bị này**,
/// không phải dữ liệu nghiệp vụ trong file backup.
const String kBackupPrefsSettingsKey = 'backupPrefs';

/// Ghi đè toàn phần dữ liệu hiện có bằng [BackupData] trong **1**
/// `db.transaction()` (research R9/FR-015): xoá 4 bảng nghiệp vụ rồi ghi lại
/// từ snapshot, giữ nguyên `id` gốc — lỗi giữa chừng tự rollback, không để DB ở
/// trạng thái nửa vời.
class BackupRestorer {
  BackupRestorer(this._db);

  final AppDatabase _db;

  Future<void> restore(BackupData data) async {
    await _db.transaction(() async {
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.budgets).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.wallets).go();

      for (final w in data.wallets) {
        await _db.into(_db.wallets).insert(
          WalletsCompanion(
            id: Value(w.id),
            name: Value(w.name),
            walletType: Value(w.type),
            icon: Value(w.icon),
            color: Value(w.color),
            initialBalance: Value(w.initialBalanceValue),
            balance: Value(w.balance),
            currency: Value(w.currency),
            isDefault: Value(w.isDefault),
            isHidden: Value(w.isHidden),
            sortOrder: Value(w.sortOrder),
            creditLimit: Value(w.creditLimit),
            creditUsed: Value(w.creditUsed),
            statementDate: Value(w.statementDate),
            dueDate: Value(w.dueDate),
            termMonths: Value(w.termMonths),
            maturityDate: Value(w.maturityDate),
            institutionName: Value(w.institutionName),
            lastDigits: Value(w.lastDigits),
          ),
        );
      }

      for (final c in data.categories) {
        await _db.into(_db.categories).insert(
          CategoriesCompanion(
            id: Value(c.id),
            name: Value(c.name),
            type: Value(c.type),
            icon: Value(c.icon),
            color: Value(c.color),
            parentId: Value(c.parentId),
            sortOrder: Value(c.sortOrder),
            isHidden: Value(c.isHidden),
            isSystem: Value(c.isSystem),
          ),
        );
      }

      for (final t in data.transactions) {
        await _db.into(_db.transactions).insert(
          TransactionsCompanion(
            id: Value(t.id),
            walletId: Value(t.walletId),
            type: Value(t.type),
            amount: Value(t.amount),
            category: Value(t.category),
            note: Value(t.note),
            transactionDate: Value(t.date),
            transferGroupId: Value(t.transferGroupId),
            categoryId: Value(t.categoryId),
            tags: Value(t.tags),
            receiptImage: Value(t.receiptImage),
            location: Value(t.location),
            source: Value(t.source),
          ),
        );
      }

      for (final b in data.budgets) {
        await _db.into(_db.budgets).insert(
          BudgetsCompanion(
            id: Value(b.id),
            categoryId: Value(b.categoryId),
            amount: Value(b.amount),
            period: Value(b.period),
            isRecurring: Value(b.isRecurring),
            startDate: Value(b.startDate),
            isArchived: Value(b.isArchived),
          ),
        );
      }

      for (final entry in data.settings.entries) {
        if (entry.key == kBackupPrefsSettingsKey) continue;
        await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: entry.key, value: entry.value),
        );
      }
    });
  }
}
