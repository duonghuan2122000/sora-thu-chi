import 'package:drift/drift.dart' show Value;

import '../core/category/category.dart';
import '../core/transaction/transaction.dart';
import '../core/wallet/wallet.dart';
import 'db/app_database.dart';
import 'wallet_repository.dart';

/// Impl thật (drift) của [WalletRepository] — map dòng `wallets` ↔ [Wallet].
class DriftWalletRepository implements WalletRepository {
  DriftWalletRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Wallet>> loadAll() async {
    final rows = await _db.select(_db.wallets).get();
    final wallets = rows.map(_toWallet).toList();
    // Sắp theo sortOrder — thứ tự hiển thị (ẩn do UI xử lý).
    wallets.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return wallets;
  }

  @override
  Future<Wallet> insert(Wallet wallet) async {
    final id = await _db.into(_db.wallets).insert(
      WalletsCompanion.insert(
        name: wallet.name,
        walletType: wallet.type,
        icon: wallet.icon,
        color: Value(wallet.color),
        initialBalance: wallet.initialBalanceValue,
        balance: wallet.balance,
        currency: Value(wallet.currency),
        isDefault: Value(wallet.isDefault),
        // Tạo ví mới luôn ở trạng thái hoạt động (FR-012).
        isHidden: const Value(false),
        sortOrder: Value(wallet.sortOrder),
        creditLimit: Value(wallet.creditLimit),
        creditUsed: Value(wallet.creditUsed),
        statementDate: Value(wallet.statementDate),
        dueDate: Value(wallet.dueDate),
        termMonths: Value(wallet.termMonths),
        maturityDate: Value(wallet.maturityDate),
        institutionName: Value(wallet.institutionName),
        lastDigits: Value(wallet.lastDigits),
      ),
    );
    final row = await (_db.select(_db.wallets)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    return _toWallet(row);
  }

  @override
  Future<Wallet> update(Wallet wallet) async {
    // Không ghi `is_hidden` (Value.absent) → giữ nguyên trạng thái ẩn (FR-012);
    // sửa ví chưa giao dịch đã đổi số dư → ghi cả initial_balance lẫn balance.
    await (_db.update(_db.wallets)..where((t) => t.id.equals(wallet.id))).write(
      WalletsCompanion(
        name: Value(wallet.name),
        walletType: Value(wallet.type),
        icon: Value(wallet.icon),
        color: Value(wallet.color),
        initialBalance: Value(wallet.initialBalanceValue),
        balance: Value(wallet.balance),
        currency: Value(wallet.currency),
        isDefault: Value(wallet.isDefault),
        sortOrder: Value(wallet.sortOrder),
        creditLimit: Value(wallet.creditLimit),
        creditUsed: Value(wallet.creditUsed),
        statementDate: Value(wallet.statementDate),
        dueDate: Value(wallet.dueDate),
        termMonths: Value(wallet.termMonths),
        maturityDate: Value(wallet.maturityDate),
        institutionName: Value(wallet.institutionName),
        lastDigits: Value(wallet.lastDigits),
      ),
    );
    final row = await (_db.select(_db.wallets)
          ..where((t) => t.id.equals(wallet.id)))
        .getSingle();
    return _toWallet(row);
  }

  @override
  Future<List<Transaction>> transactionsOf(int walletId) async {
    final rows = await (_db.select(_db.transactions)
          ..where((t) => t.walletId.equals(walletId)))
        .get();
    return sortNewestFirst(rows.map(_toTransaction).toList());
  }

  @override
  Future<List<Transaction>> allTransactions() async {
    final rows = await _db.select(_db.transactions).get();
    return sortNewestFirst(rows.map(_toTransaction).toList());
  }

  @override
  Future<void> performTransfer({
    required int fromWalletId,
    required int toWalletId,
    required int amount,
    required DateTime date,
    String note = '',
  }) async {
    // Một db.transaction() — 4 ghi đi cùng nhau, không bao giờ lệch một phía
    // (FR-012/015): trừ/cộng balance 2 ví + 2 dòng type=transfer liên kết group.
    await _db.transaction(() async {
      final src = await (_db.select(_db.wallets)
            ..where((t) => t.id.equals(fromWalletId)))
          .getSingle();
      final dst = await (_db.select(_db.wallets)
            ..where((t) => t.id.equals(toWalletId)))
          .getSingle();

      await (_db.update(_db.wallets)..where((t) => t.id.equals(fromWalletId)))
          .write(WalletsCompanion(balance: Value(src.balance - amount)));
      await (_db.update(_db.wallets)..where((t) => t.id.equals(toWalletId)))
          .write(WalletsCompanion(balance: Value(dst.balance + amount)));

      // Vế nguồn ghi trước (R7) → lấy id làm transfer_group_id của cả 2 vế.
      final sourceId = await _db.into(_db.transactions).insert(
        TransactionsCompanion.insert(
          walletId: fromWalletId,
          type: TxnType.transfer,
          amount: -amount,
          note: Value(note),
          transactionDate: date,
        ),
      );
      await _db.into(_db.transactions).insert(
        TransactionsCompanion.insert(
          walletId: toWalletId,
          type: TxnType.transfer,
          amount: amount,
          note: Value(note),
          transactionDate: date,
          transferGroupId: Value(sourceId),
        ),
      );
      await (_db.update(_db.transactions)..where((r) => r.id.equals(sourceId)))
          .write(TransactionsCompanion(transferGroupId: Value(sourceId)));
    });
  }

  @override
  Future<List<Category>> categories({required CategoryType type}) async {
    // Lọc is_hidden trong SQL; type lọc sau (cột enum dùng converter — so sánh
    // trong Dart cho chắc, bảng nhỏ local).
    final rows = await (_db.select(_db.categories)
          ..where((c) => c.isHidden.equals(false)))
        .get();
    final list = rows
        .where((r) => r.type == type)
        .map(_toCategory)
        .toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  @override
  Future<List<Category>> categoriesIncludingHidden({
    required CategoryType type,
  }) async {
    // Không lọc `is_hidden` (khác `categories()`) — màn quản lý hiện cả ẩn
    // (PBI 13 FR-006); lọc type trong Dart như categories() (cột enum converter).
    final rows = await _db.select(_db.categories).get();
    final list = rows
        .where((r) => r.type == type)
        .map(_toCategory)
        .toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  @override
  Future<bool> categoryHasTransactions(int categoryId) async {
    // Chỉ cần biết có ≥ 1 dòng — đếm gọn theo bảng nhỏ local (R3).
    final rows = await (_db.select(_db.transactions)
          ..where((t) => t.categoryId.equals(categoryId)))
        .get();
    return rows.isNotEmpty;
  }

  @override
  Future<Category> insertCategory(Category category) async {
    // Bỏ qua `category.id` — DB tự sinh (như insert ví). isSystem = false cho
    // danh mục tự tạo; isHidden theo form. Không tự validate/tính sortOrder.
    final id = await _db.into(_db.categories).insert(
      CategoriesCompanion.insert(
        name: category.name,
        type: category.type,
        icon: category.icon,
        color: category.color,
        parentId: Value(category.parentId),
        sortOrder: Value(category.sortOrder),
        isSystem: const Value(false),
        isHidden: Value(category.isHidden),
      ),
    );
    final row = await (_db.select(_db.categories)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    return _toCategory(row);
  }

  @override
  Future<Category> updateCategory(Category category) async {
    // Ghi đủ trường nghiệp vụ gồm isHidden (công tắc) + isSystem (giữ giá trị
    // dòng đang sửa). parentId null → xóa cha (bỏ cha → danh mục gốc).
    await (_db.update(_db.categories)..where((t) => t.id.equals(category.id)))
        .write(
          CategoriesCompanion(
            name: Value(category.name),
            type: Value(category.type),
            icon: Value(category.icon),
            color: Value(category.color),
            parentId: Value(category.parentId),
            sortOrder: Value(category.sortOrder),
            isSystem: Value(category.isSystem),
            isHidden: Value(category.isHidden),
          ),
        );
    final row = await (_db.select(_db.categories)
          ..where((t) => t.id.equals(category.id)))
        .getSingle();
    return _toCategory(row);
  }

  @override
  Future<void> addTransaction({
    required int walletId,
    required TxnType type,
    required int amount,
    required Category category,
    required DateTime date,
    String note = '',
  }) async {
    // Một db.transaction(): bù balance + insert — không bao giờ lệch một phía
    // (FR-012/SC-003). Số dư cập nhật ngay theo ngày ghi (balance eager,
    // ponytail: ceiling — số dư "suy ra theo ngày giao dịch" để module ví sau).
    final signedAmount = type == TxnType.income ? amount : -amount;
    await _db.transaction(() async {
      final wallet = await (_db.select(_db.wallets)
            ..where((t) => t.id.equals(walletId)))
          .getSingle();
      await (_db.update(_db.wallets)..where((t) => t.id.equals(walletId)))
          .write(WalletsCompanion(balance: Value(wallet.balance + signedAmount)));
      await _db.into(_db.transactions).insert(
        TransactionsCompanion.insert(
          walletId: walletId,
          type: type,
          amount: signedAmount,
          category: Value(category.name),
          note: Value(note),
          transactionDate: date,
          categoryId: Value(category.id),
        ),
      );
    });
  }

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
  );

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
}
