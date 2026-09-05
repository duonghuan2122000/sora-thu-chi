import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/category/category.dart';
import '../../core/category/category_source.dart';
import '../../core/transaction/transaction.dart';
import '../../core/transaction/transaction_source.dart';
import '../../core/wallet/wallet.dart';
import '../../core/wallet/wallet_source.dart';

part 'app_database.g.dart';

/// Bảng ví — 18 cột nghiệp vụ (data-model.md §Bảng drift), schemaVersion 4.
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

/// Bảng danh mục thu/chi (data-model.md §Bảng drift mới, R1) — schema v4.
/// Nguồn chân lý cho picker giao dịch mới (cha-con 2 cấp). `icon` là khóa chuỗi
/// → IconData qua map [categoryIcon] (tầng UI); `color` ARGB bắt buộc. Không tạo
/// quan hệ FK drift (bám kiểu `transfer_group_id` — plain int). Seed mặc định
/// [CategorySource] chỉ chạy khi bảng rỗng (không duplicate khi upgrade).
@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<CategoryType>()();
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  IntColumn get parentId => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
}

/// Bảng giao dịch — subset cột đủ PBI 8/10 (data-model.md §Giao dịch, R3).
/// Một lần Transfer = **2 dòng** liên kết `transfer_group_id` (vế nguồn `−x`,
/// vế đích `+x`, cùng ngày/note) — group = id vế ghi trước (R7). `category`
/// (text) giữ là **snapshot tên hiển thị** — màn danh sách/chi tiết (PBI 9/10)
/// không đổi; `category_id` (schema v4, R2) là tham chiếu `categories.id` cho
/// module Danh mục sau (giao dịch cũ/transfer không khớp → null). Giao dịch
/// thu/chi mới ghi cả hai. `tags`/`receipt_image`/`location` là 3 cột tùy chọn
/// (default `''` — schema v3, PBI 10). Seed 11 dòng mẫu (từ [TransactionSource])
/// ở onCreate/onUpgrade.
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
  IntColumn get categoryId => integer().nullable()();
  TextColumn get tags => text().withDefault(const Constant(''))();
  TextColumn get receiptImage => text().withDefault(const Constant(''))();
  TextColumn get location => text().withDefault(const Constant(''))();
}

/// Kết nối mặc định: file sqlite trong thư mục documents của app (offline local).
QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'sora_thu_chi.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(tables: [Wallets, Categories, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedCategories();
      await _seedSampleWallets();
      await _seedSampleTransactions();
    },
    onUpgrade: (m, from, to) async {
      // from < 4: DB cũ hơn v4 chưa từng có bảng categories → tạo + seed.
      // Đặt trước mọi bước tạo/seed giao dịch: giao dịch seed mới cần category_id.
      if (from < 4) {
        await m.createTable(categories);
        await _seedCategories();
      }
      // from < 2: bảng transactions chưa tồn tại → tạo mới theo định nghĩa hiện
      // tại (**đã gồm 3 cột v3 + categoryId v4**) + seed; không addColumn nữa
      // (else-if) để tránh duplicate-column trên DB v1 nâng thẳng lên v4.
      if (from < 2) {
        await m.createTable(transactions);
        await _seedSampleTransactions();
      } else if (from < 3) {
        // DB v2 cũ: bảng đã có dữ liệu → chỉ thêm 3 cột tùy chọn (default ''),
        // an toàn, không mất dữ liệu (data-model §Migration, R3).
        await m.addColumn(transactions, transactions.tags);
        await m.addColumn(transactions, transactions.receiptImage);
        await m.addColumn(transactions, transactions.location);
      }
      // DB v2/v3 (from ≥ 2): bảng transactions đã tồn tại trước v4 → thêm cột
      // category_id (nullable, an toàn). DB v1 đã tạo mới ở nhánh trên (cột có
      // sẵn) → bỏ qua; dòng cũ giữ category_id null — hiển thị text không đổi.
      if (from >= 2 && from < 4) {
        await m.addColumn(transactions, transactions.categoryId);
      }
    },
  );

  /// Nạp danh mục mặc định [CategorySource] (schema v4, R4) — cha trước (lấy id
  /// thật DB theo tên từng cha), rồi con gán `parent_id`; màu/icon từ hằng. Chỉ
  /// chèn khi bảng rỗng để tránh duplicate khi DB upgrade nhiều bước.
  Future<void> _seedCategories() async {
    final rows = await select(categories).get();
    if (rows.isNotEmpty) return;
    final parents = CategorySource.all.where((c) => c.isParent).toList();
    final dbIdBySourceId = <int, int>{};
    for (final c in parents) {
      final id = await into(categories).insert(
        CategoriesCompanion.insert(
          name: c.name,
          type: c.type,
          icon: c.icon,
          color: c.color,
          sortOrder: Value(c.sortOrder),
          isSystem: const Value(true),
          isHidden: const Value(false),
        ),
      );
      dbIdBySourceId[c.id] = id;
    }
    for (final c in CategorySource.all.where((c) => !c.isParent)) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          name: c.name,
          type: c.type,
          icon: c.icon,
          color: c.color,
          parentId: Value(dbIdBySourceId[c.parentId!]),
          sortOrder: Value(c.sortOrder),
          isSystem: const Value(true),
          isHidden: const Value(false),
        ),
      );
    }
  }

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

    // Map tên danh mục (đã seed) → id thật — gán category_id cho dòng seed khớp
    // tên cùng type (R4); tên lạ ('Xăng xe', 'Thu nhập khác'…) & transfer → null.
    final catIdByName = <String, int>{
      for (final r in await select(categories).get()) r.name: r.id,
    };
    int? categoryIdFor(Transaction t) =>
        (t.type == TxnType.income || t.type == TxnType.expense)
            ? catIdByName[t.category]
            : null;

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
          categoryId: Value(categoryIdFor(t)),
          tags: Value(t.tags),
          receiptImage: Value(t.receiptImage),
          location: Value(t.location),
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
          categoryId: Value(categoryIdFor(t)),
          tags: Value(t.tags),
          receiptImage: Value(t.receiptImage),
          location: Value(t.location),
        ),
      );
    }
  }
}
