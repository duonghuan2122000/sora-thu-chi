import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/core/wallet/wallet_source.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';

/// Bản map bộ nhớ của [WalletRepository] — dùng cho mọi test widget/controller
/// (không cần sqlite native). Seed mặc định = [WalletSource.all()].
class FakeWalletRepository implements WalletRepository {
  FakeWalletRepository([List<Wallet>? seed]) {
    for (final w in seed ?? WalletSource.all()) {
      _store[w.id] = w;
    }
    _nextId = (_store.keys.fold<int>(0, (max, id) => id > max ? id : max)) + 1;
  }

  final Map<int, Wallet> _store = {};
  late int _nextId;

  List<Wallet> get allStored => _store.values.toList();

  @override
  Future<List<Wallet>> loadAll() async {
    final list = _store.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
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
