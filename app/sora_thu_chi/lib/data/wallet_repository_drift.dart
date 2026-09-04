import 'package:drift/drift.dart' show Value;

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
