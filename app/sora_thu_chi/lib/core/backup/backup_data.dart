import '../budget/budget.dart';
import '../category/category.dart';
import '../transaction/transaction.dart';
import '../wallet/wallet.dart';

/// Snapshot tuần tự hoá **1-1** các bảng hiện có (data-model.md §3) — không phải
/// thực thể DB mới. Giữ nguyên `id` gốc mọi bản ghi để không đứt gãy khoá ngoại
/// (giao dịch ↔ ví ↔ danh mục ↔ ngân sách) khi ghi đè lúc khôi phục. Thuần Dart,
/// không phụ thuộc `drift` — [BackupWriter]/[BackupReader] là nơi duy nhất nối
/// với tầng DB.
///
/// [settings] là **toàn bộ** row `AppSettings` hiện có (key → value thô, đã là
/// JSON string với các row dạng khối) — khi khôi phục, `BackupRestorer` **bỏ
/// qua** khoá `backupPrefs`: cấu hình tự động sao lưu là của riêng thiết bị,
/// không phải dữ liệu nghiệp vụ nên không bị file backup ghi đè.
class BackupData {
  const BackupData({
    required this.wallets,
    required this.categories,
    required this.transactions,
    required this.budgets,
    required this.settings,
  });

  final List<Wallet> wallets;
  final List<Category> categories;
  final List<Transaction> transactions;
  final List<Budget> budgets;
  final Map<String, String> settings;

  Map<String, int> get counts => {
    'wallets': wallets.length,
    'categories': categories.length,
    'transactions': transactions.length,
    'budgets': budgets.length,
  };

  Map<String, Object?> toJson() => {
    'wallets': wallets.map(_walletToJson).toList(),
    'categories': categories.map(_categoryToJson).toList(),
    'transactions': transactions.map(_transactionToJson).toList(),
    'budgets': budgets.map(_budgetToJson).toList(),
    'settings': settings,
  };

  factory BackupData.fromJson(Map<String, Object?> json) => BackupData(
    wallets: _list(json['wallets']).map(_walletFromJson).toList(),
    categories: _list(json['categories']).map(_categoryFromJson).toList(),
    transactions: _list(
      json['transactions'],
    ).map(_transactionFromJson).toList(),
    budgets: _list(json['budgets']).map(_budgetFromJson).toList(),
    settings: _stringMap(json['settings']),
  );

  static List<Object?> _list(Object? raw) => raw is List ? raw : const [];

  static Map<String, String> _stringMap(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    };
  }

  static Map<String, Object?> _walletToJson(Wallet w) => {
    'id': w.id,
    'name': w.name,
    'type': w.type.name,
    'icon': w.icon,
    'initialBalance': w.initialBalance,
    'balance': w.balance,
    'currency': w.currency,
    'color': w.color,
    'isDefault': w.isDefault,
    'isHidden': w.isHidden,
    'sortOrder': w.sortOrder,
    'creditLimit': w.creditLimit,
    'creditUsed': w.creditUsed,
    'statementDate': w.statementDate?.toIso8601String(),
    'dueDate': w.dueDate?.toIso8601String(),
    'termMonths': w.termMonths,
    'maturityDate': w.maturityDate?.toIso8601String(),
    'institutionName': w.institutionName,
    'lastDigits': w.lastDigits,
  };

  static Wallet _walletFromJson(Object? raw) {
    final j = raw as Map;
    return Wallet(
      id: j['id'] as int,
      name: j['name'] as String,
      type: WalletType.values.byName(j['type'] as String),
      icon: j['icon'] as String? ?? '',
      initialBalance: j['initialBalance'] as int?,
      balance: j['balance'] as int,
      currency: j['currency'] as String? ?? 'VND',
      color: j['color'] as int?,
      isDefault: j['isDefault'] as bool? ?? false,
      isHidden: j['isHidden'] as bool? ?? false,
      sortOrder: j['sortOrder'] as int? ?? 0,
      creditLimit: j['creditLimit'] as int?,
      creditUsed: j['creditUsed'] as int?,
      statementDate: _dateTime(j['statementDate']),
      dueDate: _dateTime(j['dueDate']),
      termMonths: j['termMonths'] as int?,
      maturityDate: _dateTime(j['maturityDate']),
      institutionName: j['institutionName'] as String?,
      lastDigits: j['lastDigits'] as String?,
    );
  }

  static Map<String, Object?> _categoryToJson(Category c) => {
    'id': c.id,
    'name': c.name,
    'type': c.type.name,
    'icon': c.icon,
    'color': c.color,
    'parentId': c.parentId,
    'sortOrder': c.sortOrder,
    'isHidden': c.isHidden,
    'isSystem': c.isSystem,
  };

  static Category _categoryFromJson(Object? raw) {
    final j = raw as Map;
    return Category(
      id: j['id'] as int,
      name: j['name'] as String,
      type: CategoryType.values.byName(j['type'] as String),
      icon: j['icon'] as String,
      color: j['color'] as int,
      parentId: j['parentId'] as int?,
      sortOrder: j['sortOrder'] as int? ?? 0,
      isHidden: j['isHidden'] as bool? ?? false,
      isSystem: j['isSystem'] as bool? ?? false,
    );
  }

  static Map<String, Object?> _transactionToJson(Transaction t) => {
    'id': t.id,
    'walletId': t.walletId,
    'type': t.type.name,
    'category': t.category,
    'note': t.note,
    'amount': t.amount,
    'date': t.date.toIso8601String(),
    'transferGroupId': t.transferGroupId,
    'categoryId': t.categoryId,
    'tags': t.tags,
    'receiptImage': t.receiptImage,
    'location': t.location,
    'source': t.source.name,
  };

  static Transaction _transactionFromJson(Object? raw) {
    final j = raw as Map;
    return Transaction(
      id: j['id'] as int,
      walletId: j['walletId'] as int,
      type: TxnType.values.byName(j['type'] as String),
      category: j['category'] as String? ?? '',
      note: j['note'] as String? ?? '',
      amount: j['amount'] as int,
      date: DateTime.parse(j['date'] as String),
      transferGroupId: j['transferGroupId'] as int?,
      categoryId: j['categoryId'] as int?,
      tags: j['tags'] as String? ?? '',
      receiptImage: j['receiptImage'] as String? ?? '',
      location: j['location'] as String? ?? '',
      source: TxnSource.values.byName((j['source'] as String?) ?? 'manual'),
    );
  }

  static Map<String, Object?> _budgetToJson(Budget b) => {
    'id': b.id,
    'categoryId': b.categoryId,
    'amount': b.amount,
    'period': b.period.name,
    'isRecurring': b.isRecurring,
    'startDate': b.startDate.toIso8601String(),
    'isArchived': b.isArchived,
  };

  static Budget _budgetFromJson(Object? raw) {
    final j = raw as Map;
    return Budget(
      id: j['id'] as int,
      categoryId: j['categoryId'] as int,
      amount: j['amount'] as int,
      period: BudgetPeriod.values.byName(j['period'] as String),
      isRecurring: j['isRecurring'] as bool? ?? true,
      startDate: DateTime.parse(j['startDate'] as String),
      isArchived: j['isArchived'] as bool? ?? false,
    );
  }

  static DateTime? _dateTime(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;
}
