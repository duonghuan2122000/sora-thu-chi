import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/transaction/transaction.dart';
import '../../core/transaction/transaction_source.dart';
import '../../core/wallet/wallet.dart';
import '../../core/wallet/wallet_source.dart';

part 'app_database.g.dart';

/// Bảng ví — 18 cột nghiệp vụ (data-model.md §Bảng drift), schemaVersion 2.
/// Seed 5 ví mẫu (từ [WalletSource]) chỉ chạy lúc tạo DB lần đầu (onCreate) để
/// giữ liên tục demo PBI 5/6; gỡ khi PBI Giao dịch có dữ liệu thật.
@DataClassName('WalletsRow')
class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get walletType => textEnum<WalletType>()();
  TextColumn get icon => text()();
  IntColumn get color => integer().nullable()();
  IntColumn get initialBalance => integer()();
  IntColumn get balance => integer()();
  TextColumn get currency => text().withDefault(const Constant('VND'))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get creditLimit => integer().nullable()();
  IntColumn get creditUsed => integer().nullable()();
  DateTimeColumn get statementDate => dateTime().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  IntColumn get termMonths => integer().nullable()();
  DateTimeColumn get maturityDate => dateTime().nullable()();
  TextColumn get institutionName => text().nullable()();
  TextColumn get lastDigits => text().nullable()();
}

/// Bảng giao dịch — subset cột đủ PBI 8 (data-model.md §Giao dịch, research R3).
/// Một lần Transfer = **2 dòng** liên kết `transfer_group_id` (vế nguồn `−x`,
/// vế đích `+x`, cùng ngày/note) — group = id vế ghi trước (R7). `category` là
/// chữ tạm (chưa có bảng `categories`); thay bằng `category_id` khi module
/// Giao dịch đến. Seed 11 dòng mẫu (từ [TransactionSource]) ở onCreate/onUpgrade.
@DataClassName('TransactionsRow')
@TableIndex(name: 'transactions_wallet_id_index', columns: {#walletId})
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get walletId => integer()();
  TextColumn get type => textEnum<TxnType>()();
  IntColumn get amount => integer()();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get transactionDate => dateTime()();
  IntColumn get transferGroupId => integer().nullable()();
}

/// Kết nối mặc định: file sqlite trong thư mục documents của app (offline local).
QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'sora_thu_chi.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(tables: [Wallets, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedSampleWallets();
      await _seedSampleTransactions();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(transactions);
        await _seedSampleTransactions();
      }
    },
  );

  /// Nạp 5 ví mẫu [WalletSource] khi DB vừa tạo — giá trị bằng hằng seed cũ
  /// (kèm `initial_balance` — Vietcombank gốc 1.200.000 ≠ số dư đã giao dịch).
  Future<void> _seedSampleWallets() async {
    await batch((b) {
      b.insertAll(wallets, [
        for (final w in WalletSource.all())
          WalletsCompanion.insert(
            name: w.name,
            walletType: w.type,
            icon: w.icon,
            initialBalance: w.initialBalanceValue,
            balance: w.balance,
            currency: Value(w.currency),
            isDefault: Value(w.isDefault),
            isHidden: Value(w.isHidden),
            sortOrder: Value(w.sortOrder),
            creditLimit: Value(w.creditLimit),
            creditUsed: Value(w.creditUsed),
          ),
      ]);
    });
  }

  /// Nạp 11 dòng giao dịch mẫu [TransactionSource] (research R2) — chạy một lần
  /// lúc tạo DB mới (onCreate) hoặc upgrade v1→v2, tham chiếu `wallet_id` 1..5
  /// của seed ví. Bỏ qua `id` domain, để DB tự sinh; gán `transfer_group_id`
  /// = id vế nguồn vừa ghi (data-model §Migration R7).
  Future<void> _seedSampleTransactions() async {
    final seed = TransactionSource.all();
    final legs = TransactionSource.transferGroupLegs; // domain id nguồn → đích.
    final destIds = legs.values.toSet();
    final newIds = <int, int>{};

    // (1) Ghi mọi dòng trừ vế đích của cặp transfer. Vế nguồn tự cập nhật
    //     transfer_group_id = id vừa sinh (group = vế ghi trước).
    for (final t in seed) {
      if (destIds.contains(t.id)) continue;
      final id = await into(transactions).insert(
        TransactionsCompanion.insert(
          walletId: t.walletId,
          type: t.type,
          amount: t.amount,
          category: Value(t.category),
          note: Value(t.note),
          transactionDate: t.date,
        ),
      );
      newIds[t.id] = id;
      if (legs.containsKey(t.id)) {
        await (update(transactions)..where((r) => r.id.equals(id))).write(
          TransactionsCompanion(transferGroupId: Value(id)),
        );
      }
    }
    // (2) Vế đích gắn group = id vế nguồn đã ghi ở trên.
    for (final t in seed) {
      int? anchorId;
      for (final k in legs.keys) {
        if (legs[k] == t.id) {
          anchorId = k;
          break;
        }
      }
      if (anchorId == null) continue;
      await into(transactions).insert(
        TransactionsCompanion.insert(
          walletId: t.walletId,
          type: t.type,
          amount: t.amount,
          category: Value(t.category),
          note: Value(t.note),
          transactionDate: t.date,
          transferGroupId: Value(newIds[anchorId]),
        ),
      );
    }
  }
}
