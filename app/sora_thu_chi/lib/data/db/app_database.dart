import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/wallet/wallet.dart';
import '../../core/wallet/wallet_source.dart';

part 'app_database.g.dart';

/// Bảng ví — 18 cột nghiệp vụ (data-model.md §Bảng drift), schemaVersion 1.
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

/// Kết nối mặc định: file sqlite trong thư mục documents của app (offline local).
QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'sora_thu_chi.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(tables: [Wallets])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedSampleWallets();
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
}
