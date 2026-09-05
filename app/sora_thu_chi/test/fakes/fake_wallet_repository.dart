import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/transaction/transaction_source.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/core/wallet/wallet_source.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';

/// Bản map bộ nhớ của [WalletRepository] — dùng cho mọi test widget/controller
/// (không cần sqlite native). Seed mặc định = [WalletSource.all()] + 11 dòng
/// giao dịch [TransactionSource.all()] để khớp màn chi tiết (spec acceptance 7).
class FakeWalletRepository implements WalletRepository {
  FakeWalletRepository([List<Wallet>? seed]) {
    for (final w in seed ?? WalletSource.all()) {
      _store[w.id] = w;
    }
    _nextId = (_store.keys.fold<int>(0, (max, id) => id > max ? id : max)) + 1;

    // Dòng mẫu đánh lại id tăng dần theo thứ tự seed (giữ thứ tự ổn định).
    var txnId = 1;
    for (final t in TransactionSource.all()) {
      _transactions.add(
        Transaction(
          id: txnId++,
          walletId: t.walletId,
          type: t.type,
          category: t.category,
          note: t.note,
          amount: t.amount,
          date: t.date,
        ),
      );
    }
    _nextTxnId = txnId;
  }

  final Map<int, Wallet> _store = {};
  final List<Transaction> _transactions = [];
  late int _nextId;
  late int _nextTxnId;

  List<Wallet> get allStored => _store.values.toList();

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

    // 2 vế liên kết group = id vế ghi trước (R7). Domain không chứa group —
    // màn chi tiết chỉ cần thấy 2 dòng; group được kiểm ở DAO drift (T015).
    final groupId = _nextTxnId++;
    _transactions.add(
      Transaction(
        id: groupId,
        walletId: fromWalletId,
        type: TxnType.transfer,
        note: note,
        amount: -amount,
        date: date,
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
