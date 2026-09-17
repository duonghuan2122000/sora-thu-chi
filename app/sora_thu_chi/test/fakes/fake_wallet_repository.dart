import 'package:sora_thu_chi/core/budget/budget.dart';
import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/category/category_source.dart';
import 'package:sora_thu_chi/core/scan/scan_result.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/transaction/transaction_source.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/core/wallet/wallet_source.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';

/// Tham số một lần gọi [FakeWalletRepository.addScannedTransaction] — test assert.
class ScannedCall {
  const ScannedCall({
    required this.walletId,
    required this.type,
    required this.amount,
    required this.date,
    required this.receiptImage,
    required this.engine,
    required this.rawText,
    required this.parsedJson,
    required this.category,
    required this.note,
  });

  final int walletId;
  final TxnType type;
  final int amount;
  final DateTime date;
  final String receiptImage;
  final ScanEngine engine;
  final String rawText;
  final String parsedJson;
  final Category? category;
  final String note;
}

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
  /// [budgetsSeed] (PBI 20) mặc định **rỗng** — ngân sách không seed như ví.
  FakeWalletRepository.withCategories({
    List<Wallet>? wallets,
    DateTime? now,
    List<Transaction>? transactions,
    List<Category>? categoriesSeed,
    List<Budget>? budgetsSeed,
  }) : this._(
         wallets: wallets,
         now: now,
         transactions: transactions,
         categoriesSeed: categoriesSeed,
         budgetsSeed: budgetsSeed,
       );

  FakeWalletRepository._({
    List<Wallet>? wallets,
    DateTime? now,
    List<Transaction>? transactions,
    List<Category>? categoriesSeed,
    List<Budget>? budgetsSeed,
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
    // Ngân sách (PBI 20) — mặc định rỗng, chỉ seed khi test truyền.
    _budgets.addAll(budgetsSeed ?? const []);
    _nextBudgetId =
        _budgets.fold<int>(1, (max, b) => b.id >= max ? b.id + 1 : max);
  }

  final Map<int, Wallet> _store = {};
  final List<Transaction> _transactions = [];
  final List<Category> _categories = [];
  final List<Budget> _budgets = [];
  late int _nextId;
  late int _nextTxnId;
  late int _nextCategoryId;
  late int _nextBudgetId;

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
  Future<void> reorderCategories({required List<int> orderedIds}) async {
    // Với mỗi id theo thứ tự list gán sortOrder = index (0..n−1) cho phần tử
    // tương ứng trong store; phần tử khác (con cấp 2, loại kia) bất biến.
    for (var i = 0; i < orderedIds.length; i++) {
      final idx = _categories.indexWhere((c) => c.id == orderedIds[i]);
      if (idx < 0) {
        throw StateError('Không tìm thấy danh mục ${orderedIds[i]} trong fake.');
      }
      final c = _categories[idx];
      _categories[idx] = Category(
        id: c.id,
        name: c.name,
        type: c.type,
        icon: c.icon,
        color: c.color,
        parentId: c.parentId,
        sortOrder: i,
        isHidden: c.isHidden,
        isSystem: c.isSystem,
      );
    }
  }

  @override
  Future<void> addTransaction({
    required int walletId,
    required TxnType type,
    required int amount,
    required Category category,
    required DateTime date,
    String note = '',
    String tags = '',
    String receiptImage = '',
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
        tags: tags,
        receiptImage: receiptImage,
      ),
    );
  }

  /// Tham số của mọi lần [addScannedTransaction] — test assert số lần gọi và
  /// giá trị truyền xuống (PBI 24 T042).
  final List<ScannedCall> scannedCalls = [];

  /// Bật để giả lập lỗi ghi (test nhánh "lưu lỗi → thông báo, không pop").
  bool failOnScanned = false;

  @override
  Future<void> addScannedTransaction({
    required int walletId,
    required TxnType type,
    required int amount,
    required DateTime date,
    required String receiptImage,
    required ScanEngine engine,
    required String rawText,
    required String parsedJson,
    Category? category,
    String note = '',
    DateTime? createdAt,
  }) async {
    if (failOnScanned) throw StateError('Lỗi ghi giả lập.');
    final wallet = _store[walletId];
    if (wallet == null) {
      throw StateError('Không tìm thấy ví trong fake.');
    }
    final signedAmount = type == TxnType.income ? amount : -amount;
    _store[walletId] = wallet.copyWith(balance: wallet.balance + signedAmount);
    final id = _nextTxnId++;
    _transactions.add(
      Transaction(
        id: id,
        walletId: walletId,
        type: type,
        category: category?.name ?? '',
        note: note,
        amount: signedAmount,
        date: date,
        categoryId: category?.id,
        receiptImage: receiptImage,
        source: TxnSource.aiScan,
      ),
    );
    scannedCalls.add(
      ScannedCall(
        walletId: walletId,
        type: type,
        amount: amount,
        date: date,
        receiptImage: receiptImage,
        engine: engine,
        rawText: rawText,
        parsedJson: parsedJson,
        category: category,
        note: note,
      ),
    );
  }

  @override
  Future<List<Budget>> budgets() async => List.unmodifiable(_budgets);

  @override
  Future<Budget> insertBudget(Budget budget) async {
    // Bỏ qua id đưa vào — fake tự sinh (như drift thật).
    final created = Budget(
      id: _nextBudgetId++,
      categoryId: budget.categoryId,
      amount: budget.amount,
      period: budget.period,
      isRecurring: budget.isRecurring,
      startDate: budget.startDate,
      isArchived: budget.isArchived,
    );
    _budgets.add(created);
    return created;
  }

  @override
  Future<Budget> updateBudget(Budget budget) async {
    final i = _budgets.indexWhere((b) => b.id == budget.id);
    if (i < 0) {
      throw StateError('Không tìm thấy ngân sách ${budget.id} trong fake.');
    }
    _budgets[i] = budget;
    return budget;
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
