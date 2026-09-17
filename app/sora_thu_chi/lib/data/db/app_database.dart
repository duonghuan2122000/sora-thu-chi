import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/budget/budget.dart';
import '../../core/category/category.dart';
import '../../core/category/category_source.dart';
import '../../core/notification/app_notification.dart';
import '../../core/scan/scan_log.dart';
import '../../core/scan/scan_result.dart';
import '../../core/transaction/transaction.dart';
import '../../core/wallet/wallet.dart';

part 'app_database.g.dart';

/// Bảng ví — 18 cột nghiệp vụ (data-model.md §Bảng drift), schemaVersion 4.
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
/// (default `''` — schema v3, PBI 10).
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

  /// Nguồn tạo (schema v8, PBI 24): `manual` cho mọi dòng cũ/nhập tay,
  /// `aiScan` cho giao dịch tạo qua quét hóa đơn.
  TextColumn get source =>
      textEnum<TxnSource>().withDefault(const Constant('manual'))();
}

/// Bảng phiên quét hóa đơn (data-model §1.2, schema v8 — PBI 24): vết của mỗi
/// lần quét **đã lưu** (text OCR thô + kết quả trích xuất JSON + engine đã dùng)
/// để tra cứu/gỡ lỗi và cải thiện bộ luật sau này (FR-034). Không FK — bám nếp
/// `category_id`/`transfer_group_id` (plain int). Không seed: lần mở đầu tiên
/// bảng rỗng là đúng nghiệp vụ.
@DataClassName('ScanSessionsRow')
class ScanSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get imagePath => text()();
  TextColumn get rawText => text()();
  TextColumn get parsedJson => text()();
  TextColumn get engine => textEnum<ScanEngine>()();
  IntColumn get transactionId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Bảng cài đặt key-value chung (data-model §AppSettings, schema v5) — nguồn
/// lưu mọi cài đặt tiện ích về sau (PBI 17: 2 công tắc; PBI sau chỉ thêm row,
/// không thêm migration). Key vắng = chưa từng đổi → mặc định do tầng domain
/// quyết định; row ghi khi người dùng bật/tắt.
@DataClassName('AppSettingsRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Bảng ngân sách theo danh mục (data-model §Thực thể 1, schema v6 — PBI 20):
/// 6 cột có hiệu lực đợt này. "Đã chi"/% đã dùng/trạng thái là **đại lượng suy
/// ra** khi nạp màn (không lưu, không bảng snapshot — research R3); không tạo
/// quan hệ FK drift (bám kiểu `transactions.category_id`). Migration v5→v6 =
/// thuần tạo bảng, **không seed** (spec đòi trạng thái rỗng lần mở đầu).
@DataClassName('BudgetsRow')
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer()();
  IntColumn get amount => integer()();
  TextColumn get period => textEnum<BudgetPeriod>()();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(true))();
  DateTimeColumn get startDate => dateTime()();
  // PBI 21 (schema v7): ngừng theo dõi mà không mất dữ liệu giao dịch.
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

/// Bảng lịch sử thông báo (data-model §4, schema v9 — PBI 30): mỗi lần một
/// thông báo **đã phát sinh** được ghi lại. Trần [kMaxNotifications] cưỡng chế ở
/// tầng ghi (`DriftNotificationHistoryStore.append`), không phải lúc đọc. Không
/// FK — bám nếp `transactions.category_id`: xoá đối tượng nghiệp vụ **không** làm
/// mất/đổi lịch sử. Không seed: lần mở đầu tiên bảng rỗng là đúng nghiệp vụ.
@DataClassName('NotificationsRow')
class Notifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => textEnum<NotificationKind>()();
  TextColumn get title => text()();
  TextColumn get body => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get readAt => dateTime().nullable()();
  IntColumn get relatedId => integer().nullable()();
}

/// Bảng **sổ thông báo** (data-model §3, schema v10 — PBI 31): mỗi dòng = một
/// mốc thông báo đã lên lịch / đã bắn / đã bị chặn. `entry_key` là **khoá chính**
/// (khoá nghiệp vụ mang kỳ) nên lên lịch lại cùng khoá **không** nhân đôi dòng.
///
/// Vì sao cần bảng này: khi app đóng lúc mốc bắn, hệ điều hành không chạy Dart ⇒
/// bản ghi Trung tâm (bảng `notifications`, PBI 30) chỉ được **ghi bù** ở lần mở
/// app kế tiếp; sổ là thứ duy nhất sống qua khoảng đó và cũng là bộ nhớ chống
/// bắn trùng. Migration v9→v10 = **thuần tạo bảng, KHÔNG seed** (bám nếp v6/v9).
/// Không FK (bám nếp `transactions.category_id`).
@DataClassName('NotificationLedgerRow')
class NotificationLedger extends Table {
  TextColumn get entryKey => text()();
  TextColumn get kind => textEnum<NotificationKind>()();
  IntColumn get relatedId => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get body => text().withDefault(const Constant(''))();
  DateTimeColumn get scheduledFor => dateTime()();
  BoolColumn get suppressed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get historyWrittenAt => dateTime().nullable()();
  IntColumn get historyId => integer().nullable()();

  @override
  Set<Column> get primaryKey => {entryKey};
}

/// Bảng nhật ký trích xuất AI (data-model.md, schema v11 — PBI 47): mỗi dòng =
/// 1 phiên quét hóa đơn AI đã kết thúc (lưu/hủy/lỗi), ghi **một lần** lúc kết
/// thúc — không cập nhật lại (`ScanLogSession.finish`). Độc lập hoàn toàn với
/// `scan_sessions`/`transactions`: xóa giao dịch không ảnh hưởng bản ghi nhật
/// ký đã lưu. Trần [kMaxScanLogs] cưỡng chế ở tầng ghi (`DriftScanLogStore`).
/// Không FK, không seed.
@DataClassName('ScanExtractionLogsRow')
class ScanExtractionLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get rawText => text().nullable()();
  TextColumn get extractionJson => text().nullable()();
  TextColumn get engine => textEnum<ScanEngine>().nullable()();
  TextColumn get outcome => textEnum<ScanLogOutcome>()();
  TextColumn get finalValuesJson => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
  TextColumn get eventsJson => text().withDefault(const Constant('[]'))();
}

/// Kết nối mặc định: file sqlite trong thư mục documents của app (offline local).
QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'sora_thu_chi.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(
  tables: [
    Wallets,
    Categories,
    Transactions,
    AppSettings,
    Budgets,
    ScanSessions,
    Notifications,
    NotificationLedger,
    ScanExtractionLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedCategories();
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
      // from < 5 (PBI 17): mọi DB cũ hơn v5 chưa từng có bảng cài đặt → tạo
      // bảng key-value AppSettings (thuần tạo, không seed — R8); không đụng
      // nhánh migration/seed ví/danh mục/giao dịch hiện có.
      if (from < 5) {
        await m.createTable(appSettings);
      }
      // from < 6 (PBI 20): mọi DB cũ hơn v6 chưa từng có bảng ngân sách → tạo
      // bảng (6 cột, không seed); không đụng các bảng hiện có.
      if (from < 6) {
        await m.createTable(budgets);
      }
      // from < 7 (PBI 21): bảng budgets đã có (nhánh trên tạo mới cho DB cũ hơn
      // kèm sẵn cột) → chỉ thêm cột is_archived, default false cho mọi dòng cũ.
      if (from >= 6 && from < 7) {
        await m.addColumn(budgets, budgets.isArchived);
      }
      // from < 8 (PBI 24): thêm cột `source` (default 'manual' — dòng cũ nhận
      // manual, không cần backfill) + tạo bảng phiên quét (thuần tạo, KHÔNG
      // seed). Không đụng bảng nào khác.
      // DB `from < 2` đã tạo mới bảng transactions **kèm sẵn** cột source ở
      // nhánh trên ⇒ bỏ qua addColumn để tránh duplicate-column (bám nếp
      // nhánh category_id).
      if (from < 8) {
        if (from >= 2) {
          await m.addColumn(transactions, transactions.source);
        }
        await m.createTable(scanSessions);
      }
      // from < 9 (PBI 30): bảng lịch sử thông báo — thuần tạo, **KHÔNG** seed
      // (spec: không dựng cơ chế seed dữ liệu mẫu). Không đụng bảng nào khác.
      if (from < 9) {
        await m.createTable(notifications);
      }
      // from < 10 (PBI 31): bảng sổ thông báo — thuần tạo, **KHÔNG** seed. Bảng
      // rỗng lúc nâng cấp là đúng: engine tự cuốn lịch cho mốc **tương lai** ở
      // lần chạy kế tiếp, nên DB cũ nâng cấp **không** bị dội thông báo bù
      // (FR-028/AC#24). Không đụng bảng nào khác.
      if (from < 10) {
        await m.createTable(notificationLedger);
      }
      // from < 11 (PBI 47): bảng nhật ký trích xuất AI — thuần tạo, KHÔNG
      // seed. Không đụng bảng nào khác.
      if (from < 11) {
        await m.createTable(scanExtractionLogs);
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
}
