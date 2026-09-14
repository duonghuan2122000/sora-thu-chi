import '../core/backup/backup_data.dart';
import '../core/budget/budget.dart';
import '../core/category/category.dart';
import '../core/transaction/transaction.dart';
import '../core/wallet/wallet.dart';
import 'db/app_database.dart';

/// Đọc **toàn bộ** dữ liệu hiện có thành [BackupData] — đi thẳng qua `AppDatabase`
/// (không qua `WalletRepository`): đây là bản chụp thô cho backup/restore, khác
/// các truy vấn đã lọc theo nghiệp vụ UI (VD `categories()` chỉ lấy đang hoạt
/// động). Dùng chung mapping với `WalletRepositoryDrift` (nhân bản ngắn, tránh
/// public hoá 4 hàm private chỉ vì 1 nơi dùng thêm).
Future<BackupData> loadBackupData(AppDatabase db) async {
  final wallets = await db.select(db.wallets).get();
  final categories = await db.select(db.categories).get();
  final transactions = await db.select(db.transactions).get();
  final budgets = await db.select(db.budgets).get();
  final settings = await db.select(db.appSettings).get();
  return BackupData(
    wallets: wallets.map(_toWallet).toList(),
    categories: categories.map(_toCategory).toList(),
    transactions: transactions.map(_toTransaction).toList(),
    budgets: budgets.map(_toBudget).toList(),
    settings: {for (final r in settings) r.key: r.value},
  );
}

Wallet _toWallet(WalletsRow r) => Wallet(
  id: r.id,
  name: r.name,
  type: r.walletType,
  icon: r.icon,
  initialBalance: r.initialBalance,
  balance: r.balance,
  currency: r.currency,
  color: r.color,
  isDefault: r.isDefault,
  isHidden: r.isHidden,
  sortOrder: r.sortOrder,
  creditLimit: r.creditLimit,
  creditUsed: r.creditUsed,
  statementDate: r.statementDate,
  dueDate: r.dueDate,
  termMonths: r.termMonths,
  maturityDate: r.maturityDate,
  institutionName: r.institutionName,
  lastDigits: r.lastDigits,
);

Category _toCategory(CategoryRow r) => Category(
  id: r.id,
  name: r.name,
  type: r.type,
  icon: r.icon,
  color: r.color,
  parentId: r.parentId,
  sortOrder: r.sortOrder,
  isHidden: r.isHidden,
  isSystem: r.isSystem,
);

Transaction _toTransaction(TransactionsRow r) => Transaction(
  id: r.id,
  walletId: r.walletId,
  type: r.type,
  category: r.category,
  note: r.note,
  amount: r.amount,
  date: r.transactionDate,
  transferGroupId: r.transferGroupId,
  categoryId: r.categoryId,
  tags: r.tags,
  receiptImage: r.receiptImage,
  location: r.location,
  source: r.source,
);

Budget _toBudget(BudgetsRow r) => Budget(
  id: r.id,
  categoryId: r.categoryId,
  amount: r.amount,
  period: r.period,
  isRecurring: r.isRecurring,
  startDate: r.startDate,
  isArchived: r.isArchived,
);
