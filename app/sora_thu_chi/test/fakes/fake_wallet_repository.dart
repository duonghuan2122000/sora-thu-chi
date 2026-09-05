import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/category/category_source.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/transaction/transaction_source.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/core/wallet/wallet_source.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';

/// Bản map bộ nhớ của [WalletRepository] — dùng cho mọi test widget/controller
/// (không cần sqlite native). Seed mặc định = [WalletSource.all()] + 11 dòng
/// giao dịch [TransactionSource.all()] để khớp màn chi tiết (spec acceptance 7).
class FakeWalletRepository implements WalletRepository {
  /// Giữ API cũ (seed ví/giao dịch positional) — mọi test PBI trước không đổi.
  FakeWalletRepository([
    List<Wallet>? seed,
    DateTime? seedNow,
    List<Transaction>? seedTransactions,
  ]) : this._(
         wallets: seed,
         now: seedNow,
         transactions: seedTransactions,
         categoriesSeed: null,
       );

  /// Thêm seed danh mục tuỳ chọn (PBI 13 — màn danh sách cần case ẩn/con lạ):
  /// mặc định giữ [CategorySource.all], additive nên test cũ không đổi hành vi.
  FakeWalletRepository.withCategories({
    List<Wallet>? wallets,
    DateTime? now,
    List<Transaction>? transactions,
    List<Category>? categoriesSeed,
  }) : this._(
         wallets: wallets,
         now: now,
         transactions: transactions,
         categoriesSeed: categoriesSeed,
       );

  FakeWalletRepository._({
    List<Wallet>? wallets,
    DateTime? now,
    List<Transaction>? transactions,
    List<Category>? categoriesSeed,
  }) {
    for (final w in wallets ?? WalletSource.all()) {
      _store[w.id] = w;
    }
    _nextId = (_store.keys.fold<int>(0, (max, id) => id > max ? id : max)) + 1;

    // Dòng mẫu giữ id (seed DB tự sinh 1..N cùng thứ tự). [now] ấn định
    // ngày seed (mặc định giờ thật) để test deterministic. Gán transferGroupId
    // cho 2 vế transfer như seed DB (R7): group = id vế nguồn (ghi trước) —
    // chỉ khi seed từ [TransactionSource] (custom list do caller tự đặt group).
    final source = transactions ?? TransactionSource.all(at: now);
    var maxId = 0;
    for (final t in source) {
      _transactions.add(t);
      if (t.id > maxId) maxId = t.id;
    }
    if (transactions == null) {
      for (final entry in TransactionSource.transferGroupLegs.entries) {
        final group = entry.key; // domain id vế nguồn == id fake (giữ id gốc).
        for (var i = 0; i < _transactions.length; i++) {
          final t = _transactions[i];
          if (t.id == group || t.id == entry.value) {
            _transactions[i] = Transaction(
              id: t.id,
              walletId: t.walletId,
              type: t.type,
              category: t.category,
              note: t.note,
              amount: t.amount,
              date: t.date,
              transferGroupId: group,
            );
          }
        }
      }
    }
    _nextTxnId = maxId + 1;
    // Bộ danh mục **biến đổi được** (PBI 14): bản sao seed để insert/update ghi
    // vào store; mọi test cũ chỉ đọc nên hành vi giữ (data-model §Fake & test).
    _categories.addAll(categoriesSeed ?? CategorySource.all);
    _nextCategoryId =
        _categories.fold<int>(1, (max, c) => c.id >= max ? c.id + 1 : max);
  }

  final Map<int, Wallet> _store = {};
  final List<Transaction> _transactions = [];
  final List<Category> _categories = [];
  late int _nextId;
  late int _nextTxnId;
  late int _nextCategoryId;

  List<Wallet> get allStored => _store.values.toList();

  /// Store danh mục hiện tại (chỉ đọc) — test assert sau insert/update.
  List<Category> get categoriesStored => List.unmodifiable(_categories);

  @override
  Future<List<Wallet>> loadAll() async {
    final list = _store.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  @override
  Future<List<Transaction>> transactionsOf(int walletId) async {
    return sortNewestFirst(
      transactionsForWallet(_transactions.toList(), walletId),
    );
  }

  @override
  Future<List<Transaction>> allTransactions() async {
    return sortNewestFirst(_transactions.toList());
  }

  @override
  Future<void> performTransfer({
    required int fromWalletId,
    required int toWalletId,
    required int amount,
    required DateTime date,
    String note = '',
  }) async {
    final src = _store[fromWalletId];
    final dst = _store[toWalletId];
    if (src == null || dst == null) {
      throw StateError('Không tìm thấy ví nguồn/đích trong fake.');
    }
    _store[fromWalletId] = src.copyWith(balance: src.balance - amount);
    _store[toWalletId] = dst.copyWith(balance: dst.balance + amount);

    // 2 vế liên kết group = id vế ghi trước (R7) — như seed DB & drift thật.
    final groupId = _nextTxnId++;
    _transactions.add(
      Transaction(
        id: groupId,
        walletId: fromWalletId,
        type: TxnType.transfer,
        note: note,
        amount: -amount,
        date: date,
        transferGroupId: groupId,
      ),
    );
    _transactions.add(
      Transaction(
        id: _nextTxnId++,
        walletId: toWalletId,
        type: TxnType.transfer,
        note: note,
        amount: amount,
        date: date,
        transferGroupId: groupId,
      ),
    );
  }

  @override
  Future<List<Category>> categories({required CategoryType type}) async {
    final list = _categories
        .where((c) => !c.isHidden && c.type == type)
        .toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  @override
  Future<List<Category>> categoriesIncludingHidden({
    required CategoryType type,
  }) async {
    // Màn quản lý danh mục (PBI 13): không lọc ẩn — trả cha + con gồm cả ẩn.
    final list = _categories.where((c) => c.type == type).toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  @override
  Future<bool> categoryHasTransactions(int categoryId) async {
    return _transactions.any((t) => t.categoryId == categoryId);
  }

  @override
  Future<Category> insertCategory(Category category) async {
    final created = Category(
      id: _nextCategoryId++,
      name: category.name,
      type: category.type,
      icon: category.icon,
      color: category.color,
      parentId: category.parentId,
      sortOrder: category.sortOrder,
      isHidden: category.isHidden,
      isSystem: false,
    );
    _categories.add(created);
    return created;
  }

  @override
  Future<Category> updateCategory(Category category) async {
    final i = _categories.indexWhere((c) => c.id == category.id);
    if (i < 0) {
      throw StateError('Không tìm thấy danh mục ${category.id} trong fake.');
    }
    _categories[i] = category;
    return category;
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
    final wallet = _store[walletId];
    if (wallet == null) {
      throw StateError('Không tìm thấy ví trong fake.');
    }
    final signedAmount = type == TxnType.income ? amount : -amount;
    _store[walletId] = wallet.copyWith(balance: wallet.balance + signedAmount);
    _transactions.add(
      Transaction(
        id: _nextTxnId++,
        walletId: walletId,
        type: type,
        category: category.name,
        note: note,
        amount: signedAmount,
        date: date,
        categoryId: category.id,
      ),
    );
  }

  @override
  Future<Wallet> insert(Wallet wallet) async {
    final id = _nextId++;
    final created = Wallet(
      id: id,
      name: wallet.name,
      type: wallet.type,
      icon: wallet.icon,
      initialBalance: wallet.initialBalanceValue,
      balance: wallet.balance,
      currency: wallet.currency,
      color: wallet.color,
      isDefault: wallet.isDefault,
      isHidden: false, // tạo luôn hoạt động (FR-012)
      sortOrder: wallet.sortOrder,
      creditLimit: wallet.creditLimit,
      creditUsed: wallet.creditUsed,
      statementDate: wallet.statementDate,
      dueDate: wallet.dueDate,
      termMonths: wallet.termMonths,
      maturityDate: wallet.maturityDate,
      institutionName: wallet.institutionName,
      lastDigits: wallet.lastDigits,
    );
    _store[id] = created;
    return created;
  }

  @override
  Future<Wallet> update(Wallet wallet) async {
    final existing = _store[wallet.id];
    // Giữ nguyên trạng thái ẩn đang có (FR-012).
    final saved = Wallet(
      id: wallet.id,
      name: wallet.name,
      type: wallet.type,
      icon: wallet.icon,
      initialBalance: wallet.initialBalanceValue,
      balance: wallet.balance,
      currency: wallet.currency,
      color: wallet.color,
      isDefault: wallet.isDefault,
      isHidden: existing?.isHidden ?? wallet.isHidden,
      sortOrder: wallet.sortOrder,
      creditLimit: wallet.creditLimit,
      creditUsed: wallet.creditUsed,
      statementDate: wallet.statementDate,
      dueDate: wallet.dueDate,
      termMonths: wallet.termMonths,
      maturityDate: wallet.maturityDate,
      institutionName: wallet.institutionName,
      lastDigits: wallet.lastDigits,
    );
    _store[wallet.id] = saved;
    return saved;
  }
}
