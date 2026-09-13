import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/add_transaction_screen.dart';
import 'package:sora_thu_chi/screens/budget_detail_screen.dart';

import 'package:sora_thu_chi/core/budget/budget.dart';
import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/report/report_view.dart';
import 'package:sora_thu_chi/core/notification/app_notification.dart';
import 'package:sora_thu_chi/core/notification/notification_engine.dart';
import 'package:sora_thu_chi/core/notification/notification_ledger.dart';
import 'package:sora_thu_chi/core/notification/notification_prefs.dart';
import 'package:sora_thu_chi/core/notification/notification_presenter.dart';
import 'package:sora_thu_chi/core/notification/notification_presence.dart';
import 'package:sora_thu_chi/core/notification/notification_schedule.dart';
import 'package:sora_thu_chi/core/notification/notification_tap.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';

import 'fakes/fake_notification_history_store.dart';
import 'fakes/fake_notification_ledger.dart';
import 'fakes/fake_notification_presenter.dart';
import 'fakes/fake_notification_store.dart';
import 'fakes/fake_wallet_repository.dart';

import 'package:sora_thu_chi/data/db/app_database.dart' hide NotificationLedger;
import 'package:sora_thu_chi/data/notification_history_store_drift.dart';
import 'package:sora_thu_chi/data/notification_ledger_drift.dart';

/// Mở DB drift trong bộ nhớ (skip-guard như các test drift khác của repo).
Future<AppDatabase?> _tryMemoryDb() async {
  try {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    return db;
  } catch (_) {
    return null;
  }
}

/// Bộ khung test engine (PBI 31) — cả 3 seam đều là fake nên **toàn bộ** luật
/// nghiệp vụ kiểm được không cần plugin/thiết bị (R15).
///
/// `now` là biến đổi được: engine nhận `clock: () => now` nên test "đi tới
/// tương lai" chỉ cần gán lại biến rồi gọi `reconcile()`.

/// Một giao dịch bất kỳ trong fake repository (mặc định là **Chi** hôm nay).
Transaction _txn({
  required int id,
  required DateTime date,
  TxnType type = TxnType.expense,
  int amount = -100000,
  int? categoryId,
  String category = '',
}) => Transaction(
  id: id,
  walletId: 1,
  type: type,
  amount: amount,
  date: date,
  category: category,
  categoryId: categoryId,
);

NotificationLedgerEntry _entry(
  String key, {
  required DateTime at,
  NotificationKind kind = NotificationKind.dailyReminder,
  int? relatedId,
  bool suppressed = false,
  DateTime? historyWrittenAt,
  int? historyId,
}) => NotificationLedgerEntry(
  entryKey: key,
  kind: kind,
  title: 'Tiêu đề cũ',
  body: 'Mô tả cũ',
  scheduledFor: at,
  relatedId: relatedId,
  suppressed: suppressed,
  historyWrittenAt: historyWrittenAt,
  historyId: historyId,
);

/// Dòng sổ **cảnh báo ngân sách** — `reconcile()` cũng ghi dòng nhắc hàng ngày
/// nên không thể khẳng định cả sổ rỗng.
Iterable<NotificationLedgerEntry> _budgetRows(
  List<NotificationLedgerEntry> rows,
) => rows.where((e) => e.kind == NotificationKind.budgetAlert);

/// Dòng sổ **nhắc hàng ngày** — `reconcile()` cuốn cả 2 loại tổng kết nữa.
Iterable<NotificationLedgerEntry> _dailyRows(List<NotificationLedgerEntry> rows) =>
    rows.where((e) => e.kind == NotificationKind.dailyReminder);

/// Lịch **nhắc hàng ngày** đã đăng ký (bỏ mốc tổng kết tuần/tháng).
Iterable<OsNotification> _dailyScheduled(FakeNotificationPresenter presenter) =>
    presenter.scheduled.where(
      (n) => n.kind == NotificationKind.dailyReminder,
    );

/// Bản ghi Trung tâm của **nhắc hàng ngày**.
Iterable<AppNotification> _dailyRecords(FakeNotificationHistoryStore history) =>
    history.stored.where((n) => n.kind == NotificationKind.dailyReminder);

void main() {
  // Chủ Nhật 13/09/2026 10:00 — giờ nhắc mặc định 20:30 còn ở tương lai.
  late DateTime now;
  late FakeNotificationPresenter presenter;
  late FakeNotificationLedger ledger;
  late FakeNotificationHistoryStore history;
  late FakeNotificationStore prefsStore;
  late FakeWalletRepository repository;
  late NotificationPresence presence;
  late NotificationEngine engine;

  void build({
    NotificationPrefs? prefs,
    List<Transaction> transactions = const [],
    List<Budget> budgets = const [],
    List<Category>? categories,
  }) {
    prefsStore = FakeNotificationStore(
      storedPrefs: prefs ?? NotificationPrefs.defaults,
    );
    repository = FakeWalletRepository.withCategories(
      transactions: transactions,
      budgetsSeed: budgets,
      categoriesSeed: categories,
    );
    engine = NotificationEngine(
      presenter: presenter,
      ledger: ledger,
      history: history,
      repository: repository,
      prefsStore: prefsStore,
      presence: presence,
      clock: () => now,
    );
  }

  setUp(() {
    now = DateTime(2026, 9, 13, 10);
    presenter = FakeNotificationPresenter();
    ledger = FakeNotificationLedger();
    history = FakeNotificationHistoryStore();
    presence = NotificationPresence();
  });

  group('US1 — sinh lịch nhắc hàng ngày', () {
    test('mọi ngày được chọn ⇒ mỗi mốc một lịch, KHÔNG sinh bản ghi sớm', () async {
      build();
      await engine.reconcile();

      // 30 mốc trong cửa sổ, đều 20:30 và đều ở tương lai.
      expect(_dailyScheduled(presenter), hasLength(kDailyWindowDays));
      expect(_dailyScheduled(presenter).first.at, DateTime(2026, 9, 13, 20, 30));
      expect(
        _dailyScheduled(presenter).every((n) => n.at.isAfter(now)),
        isTrue,
        reason: 'Không được đăng ký mốc đã trôi qua (FR-028)',
      );
      // Chưa tới giờ ⇒ chưa có bản ghi Trung tâm nào (FR-003: bản ghi sinh lúc bắn).
      expect(history.stored, isEmpty);
      expect(_dailyRows(await ledger.all()), hasLength(kDailyWindowDays));
    });

    test('chỉ ngày được chọn mới có lịch (AC#4/SC-003)', () async {
      // Chỉ Thứ Hai (ISO 1) — hôm nay là Chủ Nhật nên mốc đầu là 14/09.
      build(
        prefs: NotificationPrefs.defaults.copyWith(dailyWeekdays: const [1]),
      );
      await engine.reconcile();

      expect(_dailyScheduled(presenter), hasLength(5));
      expect(_dailyScheduled(presenter).every((n) => n.at.weekday == 1), isTrue);
      expect(
        _dailyRows(await ledger.all()).every((e) => e.scheduledFor.weekday == 1),
        isTrue,
      );
    });

    test('mốc tới hạn ⇒ đúng 1 bản ghi CHƯA ĐỌC, created_at = mốc bắn (AC#1)', () async {
      build();
      await engine.reconcile();
      expect(history.stored, isEmpty);

      // Đi tới hôm sau 10:00: mốc 20:30 hôm qua đã qua.
      now = DateTime(2026, 9, 14, 10);
      await engine.reconcile();

      expect(_dailyRecords(history), hasLength(1));
      final record = _dailyRecords(history).single;
      expect(record.kind, NotificationKind.dailyReminder);
      expect(record.createdAt, DateTime(2026, 9, 13, 20, 30));
      expect(record.isRead, isFalse);
      // Sổ đã đánh dấu "ghi xong" ⇒ lần cuốn sau KHÔNG ghi bù lần hai.
      final entry = await ledger.byKey('daily:2026-09-13');
      expect(entry!.historyWrittenAt, isNotNull);
      expect(entry.historyId, record.id);

      await engine.reconcile();
      expect(_dailyRecords(history), hasLength(1));
    });

    test('DB cũ nâng cấp (sổ rỗng) ⇒ KHÔNG bắn bù mốc quá khứ (AC#24/FR-028)', () async {
      build();
      now = DateTime(2026, 9, 13, 21); // giờ nhắc 20:30 hôm nay đã qua
      await engine.reconcile();

      expect(history.stored, isEmpty);
      expect(_dailyRows(await ledger.all()), hasLength(kDailyWindowDays - 1));
      expect(
        _dailyRows(await ledger.all()).every((e) => e.scheduledFor.isAfter(now)),
        isTrue,
      );
    });

    test('sổ không bao giờ chứa loại chưa có module (Q1=A/FR-002)', () async {
      build();
      await engine.reconcile();
      final kinds = (await ledger.all()).map((e) => e.kind).toSet();
      expect(kinds, isNot(contains(NotificationKind.recurringDue)));
      expect(kinds, isNot(contains(NotificationKind.goalReminder)));
      expect(
        kinds.difference({
          NotificationKind.dailyReminder,
          NotificationKind.periodSummary,
        }),
        isEmpty,
      );
    });

    test('cùng khoá ⇒ cùng id hệ điều hành (FR-026 — thay thế, không xếp chồng)', () async {
      build();
      await engine.reconcile();
      final first = presenter.scheduled.map((n) => n.id).toList();
      presenter.scheduled.clear();

      await engine.reconcile();
      expect(presenter.scheduled.map((n) => n.id).toSet(), first.toSet());
      expect(first, first.toSet().toList(), reason: 'id không được trùng nhau');
    });

    test('gọi reconcile nhiều lần ⇒ sổ không nhân đôi dòng', () async {
      build();
      await engine.reconcile();
      await engine.reconcile();
      await engine.reconcile();
      expect(_dailyRows(await ledger.all()), hasLength(kDailyWindowDays));
    });
  });

  group('US1 — cờ "chỉ nhắc nếu chưa ghi" (FR-008/FR-011)', () {
    for (final type in TxnType.values) {
      test('cờ BẬT + đã ghi hôm nay (${type.name}) ⇒ huỷ + chặn mốc hôm nay', () async {
        build(
          transactions: [
            _txn(id: 1, date: DateTime(2026, 9, 13, 9), type: type),
          ],
        );
        await engine.reconcile();
        // Sổ có mốc hôm nay đang chờ ⇒ lưu giao dịch phải huỷ nó.
        presenter.scheduled.clear();

        await engine.onTransactionSaved(at: DateTime(2026, 9, 13, 9));

        final entry = await ledger.byKey('daily:2026-09-13');
        expect(entry!.suppressed, isTrue);
        expect(entry.historyWrittenAt, isNull);
        expect(presenter.cancelled, contains(notificationIdFor('daily:2026-09-13')));
        // Ngày khác vẫn còn lịch.
        expect(
          _dailyRows(await ledger.all()).where((e) => !e.suppressed),
          hasLength(kDailyWindowDays - 1),
        );
      });
    }

    test('giao dịch NGÀY KHÁC không chặn mốc hôm nay', () async {
      build(transactions: [_txn(id: 1, date: DateTime(2026, 9, 12))]);
      await engine.reconcile();
      await engine.onTransactionSaved(at: DateTime(2026, 9, 13, 9));

      expect((await ledger.byKey('daily:2026-09-13'))!.suppressed, isFalse);
    });

    test('cờ TẮT + đã ghi ⇒ vẫn bắn, câu chữ KHÔNG khẳng định "chưa ghi" (AC#3)', () async {
      build(
        prefs: NotificationPrefs.defaults.copyWith(
          dailyOnlyIfNoTxnToday: false,
        ),
        transactions: [_txn(id: 1, date: DateTime(2026, 9, 13, 9))],
      );
      await engine.reconcile();
      await engine.onTransactionSaved(at: DateTime(2026, 9, 13, 9));

      final entry = await ledger.byKey('daily:2026-09-13');
      expect(entry!.suppressed, isFalse);
      expect(entry.body, isNot(contains('chưa ghi')));
    });

    test('mốc đã bắn rồi (đã có bản ghi) ⇒ chặn không hồi tố', () async {
      build(transactions: [_txn(id: 1, date: DateTime(2026, 9, 13, 9))]);
      ledger.entries['daily:2026-09-13'] = _entry(
        'daily:2026-09-13',
        at: DateTime(2026, 9, 13, 20, 30),
        historyWrittenAt: DateTime(2026, 9, 14),
        historyId: 7,
      );

      await engine.onTransactionSaved(at: DateTime(2026, 9, 13, 9));

      final entry = await ledger.byKey('daily:2026-09-13');
      expect(entry!.suppressed, isFalse);
      expect(entry.historyId, 7);
    });
  });

  group('US1 — cấu hình đổi có hiệu lực ngay (FR-021/AC#15)', () {
    test('tắt công tắc ⇒ huỷ loại đó + lần cuốn sau không sinh lịch', () async {
      build();
      prefsStore.save(
        NotificationPrefs.defaults.copyWith(dailyEnabled: false),
      );

      await engine.onPrefsChanged();

      expect(presenter.cancelledKinds, contains(NotificationKind.dailyReminder));
      expect(_dailyRows(await ledger.all()), isEmpty);
      expect(_dailyScheduled(presenter), isEmpty);
    });

    test('bật lại ⇒ hoạt động lại bình thường', () async {
      build();
      prefsStore.save(NotificationPrefs.defaults.copyWith(dailyEnabled: false));
      await engine.onPrefsChanged();
      presenter.cancelledKinds.clear();

      prefsStore.save(NotificationPrefs.defaults.copyWith(dailyEnabled: true));
      await engine.onPrefsChanged();

      expect(_dailyRows(await ledger.all()), hasLength(kDailyWindowDays));
      expect(presenter.scheduled, isNotEmpty);
    });

    test('đổi giờ nhắc ở màn 02 ⇒ mốc mới được đăng ký ngay (AC#16)', () async {
      build();
      await engine.reconcile();
      presenter.scheduled.clear();

      prefsStore.save(
        NotificationPrefs.defaults.copyWith(dailyHour: 7, dailyMinute: 15),
      );
      await engine.onPrefsChanged();

      expect(_dailyScheduled(presenter).first.at, DateTime(2026, 9, 14, 7, 15));
    });
  });

  group('US1 — chạm thông báo (FR-018/FR-020)', () {
    test('nhắc hàng ngày ⇒ thêm giao dịch + đánh dấu đã đọc', () async {
      history.stored.add(
        AppNotification(
          id: 5,
          kind: NotificationKind.dailyReminder,
          title: 'Nhắc ghi chép giao dịch',
          createdAt: DateTime(2026, 9, 13, 20, 30),
        ),
      );
      ledger.entries['daily:2026-09-13'] = _entry(
        'daily:2026-09-13',
        at: DateTime(2026, 9, 13, 20, 30),
        historyWrittenAt: DateTime(2026, 9, 14),
        historyId: 5,
      );
      build();

      final result = await engine.handleTap('daily:2026-09-13');

      expect(result.target, NotificationTarget.addTransaction);
      expect(history.stored.single.isRead, isTrue);
    });

    test('cảnh báo ngân sách ⇒ chi tiết ngân sách đúng id', () async {
      ledger.entries['budget:early:3:2026-09-01'] = _entry(
        'budget:early:3:2026-09-01',
        at: DateTime(2026, 9, 13),
        kind: NotificationKind.budgetAlert,
        relatedId: 3,
      );
      build();

      final result = await engine.handleTap('budget:early:3:2026-09-01');

      expect(result.target, NotificationTarget.budgetDetail);
      expect(result.relatedId, 3);
    });

    test('cảnh báo ngân sách THIẾU relatedId ⇒ im lặng', () async {
      ledger.entries['budget:early:3:2026-09-01'] = _entry(
        'budget:early:3:2026-09-01',
        at: DateTime(2026, 9, 13),
        kind: NotificationKind.budgetAlert,
      );
      build();

      expect(
        (await engine.handleTap('budget:early:3:2026-09-01')).target,
        NotificationTarget.none,
      );
    });

    test('tổng kết tuần/tháng ⇒ tab Báo cáo + kỳ chọn sẵn (FR-018/AC#12)', () async {
      build();

      final week = await engine.handleTap('summary:week:2026-09-07');
      expect(week.target, NotificationTarget.reportTab);
      expect(week.period, ReportPeriod.week);

      final month = await engine.handleTap('summary:month:2026-09');
      expect(month.period, ReportPeriod.month);
    });

    test('2 loại chưa có màn đích ⇒ none', () async {
      build();
      for (final kind in [
        NotificationKind.recurringDue,
        NotificationKind.goalReminder,
      ]) {
        ledger.entries['x:${kind.name}'] = _entry(
          'x:${kind.name}',
          at: DateTime(2026, 9, 13),
          kind: kind,
        );
      }
      // Khoá lạ ⇒ suy loại từ tiền tố (nhắc hàng ngày); dùng khoá thật thay thế.
      expect(
        notificationTargetFor(kind: NotificationKind.recurringDue),
        NotificationTarget.none,
      );
      expect(
        notificationTargetFor(kind: NotificationKind.goalReminder),
        NotificationTarget.none,
      );
      expect(
        notificationTargetFor(kind: NotificationKind.dailyReminder),
        NotificationTarget.addTransaction,
      );
    });

    test('sổ thiếu dòng ⇒ suy loại từ khoá, không ném', () async {
      build();
      expect(
        (await engine.handleTap('daily:2026-09-13')).target,
        NotificationTarget.addTransaction,
      );
      expect(
        (await engine.handleTap('summary:month:2026-09')).target,
        NotificationTarget.reportTab,
      );
    });
  });

  group('US2 — cảnh báo ngân sách (FR-012/FR-013/FR-014)', () {
    // Ngân sách tháng 1.000.000đ cho danh mục cha "Ăn uống" (id 1) — con của nó
    // (id 13/14/15) cũng thuộc phạm vi (budgetScopeCategoryIds).
    Budget anUong() => Budget(
      id: 3,
      categoryId: 1,
      amount: 1000000,
      period: BudgetPeriod.monthly,
      isRecurring: true,
      startDate: DateTime(2026, 1, 1),
    );

    /// Chi trong kỳ 9/2026 cho [categoryId].
    Transaction chi(int id, int amount, {int categoryId = 1, int month = 9}) =>
        _txn(
          id: id,
          date: DateTime(2026, month, 10),
          amount: -amount,
          categoryId: categoryId,
          category: 'Ăn uống',
        );

    Future<void> save({required int amount, TxnType type = TxnType.expense}) =>
        engine.onTransactionSaved(at: DateTime(2026, 9, 10), type: type);

    test('78% → 82% ⇒ đúng 1 thông báo + 1 bản ghi, câu chữ "sắp vượt" (AC#5)', () async {
      build(
        transactions: [chi(1, 780000)],
        budgets: [anUong()],
      );
      await save(amount: 780000);
      expect(presenter.shown, isEmpty);

      build(
        transactions: [chi(1, 780000), chi(2, 40000)],
        budgets: [anUong()],
      );
      await save(amount: 40000);

      expect(presenter.shown, hasLength(1));
      expect(history.stored, hasLength(1));
      expect(history.stored.single.isRead, isFalse);
      expect(history.stored.single.kind, NotificationKind.budgetAlert);
      expect(history.stored.single.relatedId, 3);

      final shown = presenter.shown.single;
      expect(shown.title, 'Sắp vượt ngân sách Ăn uống');
      expect(shown.body, contains('82%'));
      expect(shown.body, contains('tháng 9'));
      expect(shown.payload, 'budget:early:3:2026-09-01');
    });

    test('82% → 89% → 95% → 99% ⇒ 0 bắn lặp cho ngưỡng sớm (AC#6/SC-005)', () async {
      build(transactions: [chi(1, 820000)], budgets: [anUong()]);
      await save(amount: 820000);
      expect(presenter.shown, hasLength(1));

      for (final total in [890000, 950000, 990000]) {
        build(transactions: [chi(1, total)], budgets: [anUong()]);
        await save(amount: total);
      }
      expect(presenter.shown, hasLength(1));
      expect(history.stored, hasLength(1));

      // Sổ bền qua lần hoà giải mới (mô phỏng đóng/mở lại app — F1/F2).
      await engine.reconcile();
      expect(presenter.shown, hasLength(1));
      expect(history.stored, hasLength(1));
    });

    test('vượt 104% ⇒ đúng 1 cho ngưỡng vượt mức, câu chữ "đã vượt" (AC#7)', () async {
      build(transactions: [chi(1, 1040000)], budgets: [anUong()]);
      await save(amount: 1040000);

      expect(presenter.shown, hasLength(1));
      expect(presenter.shown.single.title, 'Đã vượt ngân sách Ăn uống');
      expect(presenter.shown.single.body, contains('104%'));
      expect(presenter.shown.single.payload, 'budget:over:3:2026-09-01');
    });

    test('giao dịch THU ⇒ 0/0 (FR-014)', () async {
      build(
        transactions: [
          _txn(
            id: 1,
            date: DateTime(2026, 9, 10),
            type: TxnType.income,
            amount: 900000,
            categoryId: 1,
          ),
        ],
        budgets: [anUong()],
      );
      await save(amount: 900000, type: TxnType.income);

      expect(presenter.shown, isEmpty);
      expect(history.stored, isEmpty);
    });

    test('chi NGOÀI KỲ ⇒ 0/0 (FR-014)', () async {
      build(transactions: [chi(1, 900000, month: 8)], budgets: [anUong()]);
      await save(amount: 900000);

      expect(presenter.shown, isEmpty);
      expect(history.stored, isEmpty);
    });

    test('chi DANH MỤC KHÁC ⇒ 0/0 (FR-014)', () async {
      build(
        transactions: [chi(1, 900000, categoryId: 2)],
        budgets: [anUong()],
      );
      await save(amount: 900000);

      expect(presenter.shown, isEmpty);
      expect(history.stored, isEmpty);
    });

    test('chi vào danh mục CON vẫn tính cho ngân sách CHA (FR-006)', () async {
      // Cà phê (id 13) là con của Ăn uống (id 1).
      build(transactions: [chi(1, 850000, categoryId: 13)], budgets: [anUong()]);
      await save(amount: 850000);

      expect(presenter.shown, hasLength(1));
    });

    test('2 ngân sách cùng vượt bằng 1 giao dịch ⇒ 2 thông báo + 2 bản ghi (AC#9)', () async {
      build(
        transactions: [chi(1, 900000, categoryId: 14)],
        budgets: [
          anUong(),
          Budget(
            id: 4,
            categoryId: 14, // "Ăn ngoài" — ngân sách trên chính danh mục con
            amount: 1000000,
            period: BudgetPeriod.monthly,
            isRecurring: true,
            startDate: DateTime(2026, 1, 1),
          ),
        ],
      );
      await save(amount: 900000);

      expect(presenter.shown, hasLength(2));
      expect(history.stored, hasLength(2));
      expect(
        presenter.shown.map((n) => n.payload).toSet(),
        {'budget:early:3:2026-09-01', 'budget:early:4:2026-09-01'},
      );
    });

    test('ngân sách đã LƯU TRỮ ⇒ không xét (PBI 21)', () async {
      build(
        transactions: [chi(1, 900000)],
        budgets: [
          Budget(
            id: 3,
            categoryId: 1,
            amount: 1000000,
            period: BudgetPeriod.monthly,
            isRecurring: true,
            startDate: DateTime(2026, 1, 1),
            isArchived: true,
          ),
        ],
      );
      await save(amount: 900000);

      expect(presenter.shown, isEmpty);
      expect(_budgetRows(await ledger.all()), isEmpty);
    });

    test('Q3: đang mở ĐÚNG Chi tiết ngân sách ⇒ 0 thông báo, 0 bản ghi, 0 dòng sổ (AC#10)', () async {
      presence.enterBudgetDetail(3);
      build(transactions: [chi(1, 900000)], budgets: [anUong()]);
      await save(amount: 900000);

      expect(presenter.shown, isEmpty);
      expect(history.stored, isEmpty);
      expect(_budgetRows(await ledger.all()), isEmpty);
    });

    test('Q3: đang mở Chi tiết ngân sách KHÁC ⇒ vẫn bắn (AC#11)', () async {
      presence.enterBudgetDetail(99);
      build(transactions: [chi(1, 900000)], budgets: [anUong()]);
      await save(amount: 900000);

      expect(presenter.shown, hasLength(1));
    });

    test('Q3: đang mở màn Báo cáo ⇒ cảnh báo ngân sách vẫn bắn (AC#11)', () async {
      presence.enterReport();
      build(transactions: [chi(1, 900000)], budgets: [anUong()]);
      await save(amount: 900000);

      expect(presenter.shown, hasLength(1));
    });

    test('tắt công tắc ⇒ 0/0; bật lại ⇒ ngưỡng CHƯA báo trong kỳ báo lại (AC#15)', () async {
      build(
        prefs: NotificationPrefs.defaults.copyWith(budgetEnabled: false),
        transactions: [chi(1, 900000)],
        budgets: [anUong()],
      );
      await save(amount: 900000);
      expect(presenter.shown, isEmpty);
      expect(history.stored, isEmpty);

      prefsStore.save(NotificationPrefs.defaults.copyWith(budgetEnabled: true));
      await save(amount: 900000);

      expect(presenter.shown, hasLength(1));
      // Ngưỡng ĐÃ báo trong kỳ ⇒ vẫn không báo lại.
      await save(amount: 900000);
      expect(presenter.shown, hasLength(1));
    });

    test('sang KỲ MỚI ⇒ báo lại bình thường (chống trùng gắn với kỳ)', () async {
      build(transactions: [chi(1, 900000)], budgets: [anUong()]);
      await save(amount: 900000);
      expect(presenter.shown, hasLength(1));

      // Cùng ngân sách, kỳ 10/2026 (khoá mới).
      build(
        transactions: [chi(1, 900000), chi(2, 900000, month: 10)],
        budgets: [anUong()],
      );
      await engine.onTransactionSaved(
        at: DateTime(2026, 10, 10),
        type: TxnType.expense,
      );

      expect(presenter.shown, hasLength(2));
      expect(presenter.shown.last.payload, 'budget:early:3:2026-10-01');
    });
  });

  group('US2 — điều hướng khi chạm (FR-020/F5/L6)', () {
    Budget anUong() => Budget(
      id: 3,
      categoryId: 1,
      amount: 1000000,
      period: BudgetPeriod.monthly,
      isRecurring: true,
      startDate: DateTime(2026, 1, 1),
    );

    /// Pump một nút gọi đúng chuỗi `handleTap` → `openNotificationTarget` mà
    /// `AppShell` dùng, để kiểm route thật sự được push.
    Future<void> pumpTap(WidgetTester tester, String entryKey) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await engine.handleTap(entryKey);
                    await openNotificationTarget(
                      target: result.target,
                      relatedId: result.relatedId,
                      period: result.period,
                      onSelectTab: (_) {},
                      context: context,
                    );
                  },
                  child: const Text('mở'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('mở'));
      await tester.pumpAndSettle();
    }

    testWidgets('cảnh báo ngân sách ⇒ push ĐÚNG Chi tiết ngân sách', (tester) async {
      ledger.entries['budget:early:3:2026-09-01'] = _entry(
        'budget:early:3:2026-09-01',
        at: DateTime(2026, 9, 10),
        kind: NotificationKind.budgetAlert,
        relatedId: 3,
      );
      build(budgets: [anUong()]);
      Get.put<WalletRepository>(repository);
      addTearDown(Get.reset);

      await pumpTap(tester, 'budget:early:3:2026-09-01');

      expect(find.byType(BudgetDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ngân sách KHÔNG tồn tại ⇒ không lỗi, không màn trắng, vẫn đã đọc', (
      tester,
    ) async {
      history.stored.add(
        AppNotification(
          id: 9,
          kind: NotificationKind.budgetAlert,
          title: 'Sắp vượt ngân sách',
          createdAt: DateTime(2026, 9, 10),
          relatedId: 999,
        ),
      );
      ledger.entries['budget:early:999:2026-09-01'] = _entry(
        'budget:early:999:2026-09-01',
        at: DateTime(2026, 9, 10),
        kind: NotificationKind.budgetAlert,
        relatedId: 999,
        historyWrittenAt: DateTime(2026, 9, 11),
        historyId: 9,
      );
      build(budgets: [anUong()]);
      Get.put<WalletRepository>(repository);
      addTearDown(Get.reset);

      await pumpTap(tester, 'budget:early:999:2026-09-01');

      expect(find.byType(BudgetDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(history.stored.single.isRead, isTrue);
    });

    testWidgets('đích none (loại chưa có màn) ⇒ 0 route, 0 dialog', (tester) async {
      ledger.entries['daily:x'] = _entry('daily:x', at: DateTime(2026, 9, 10));
      build();
      Get.put<WalletRepository>(repository);
      addTearDown(Get.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await openNotificationTarget(
                      target: NotificationTarget.none,
                      context: context,
                      onSelectTab: (_) {},
                    );
                  },
                  child: const Text('mở'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('mở'));
      await tester.pumpAndSettle();

      expect(find.byType(AddTransactionScreen), findsNothing);
      expect(find.byType(BudgetDetailScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('US3 — tổng kết tuần / tháng (FR-009/FR-015)', () {
    /// Chi trong kỳ [from, to) cho danh mục Ăn uống (id 1).
    List<Transaction> chiTrong(DateTime from, int amount, {int id = 1}) => [
      _txn(
        id: id,
        date: from.add(const Duration(days: 1)),
        amount: -amount,
        categoryId: 1,
        category: 'Ăn uống',
      ),
    ];

    test('mốc tuần = Chủ Nhật giờ cấu hình; mốc tháng = ngày cuối tháng (AC#18/G3)', () async {
      build();
      // now = Chủ Nhật 13/09/2026 10:00 → mốc tuần là chính hôm nay 20:00.
      await engine.reconcile();

      final weekly = await ledger.byKey(summaryWeekEntryKey(DateTime(2026, 9, 7)));
      expect(weekly, isNotNull);
      expect(weekly!.scheduledFor, DateTime(2026, 9, 13, 20, 0));
      expect(weekly.kind, NotificationKind.periodSummary);

      final monthly = await ledger.byKey(summaryMonthEntryKey(DateTime(2026, 9, 1)));
      expect(monthly!.scheduledFor, DateTime(2026, 9, 30, 20, 0));
    });

    test('mốc tháng đúng cho tháng 28/29/30/31 ngày (AC#18)', () async {
      for (final c in [
        (DateTime(2026, 1, 10), DateTime(2026, 1, 31)),
        (DateTime(2026, 4, 10), DateTime(2026, 4, 30)),
        (DateTime(2027, 2, 10), DateTime(2027, 2, 28)),
        (DateTime(2028, 2, 10), DateTime(2028, 2, 29)),
      ]) {
        now = c.$1;
        ledger.entries.clear();
        build();
        await engine.reconcile();

        final entry = (await ledger.all()).firstWhere(
          (e) => e.entryKey.startsWith('summary:month:'),
        );
        expect(entry.scheduledFor, c.$2.add(const Duration(hours: 20)));
      }
    });

    test('nội dung TÍNH LẠI sau khi có giao dịch mới (R3)', () async {
      build();
      await engine.reconcile();
      final before = (await ledger.byKey(
        summaryWeekEntryKey(DateTime(2026, 9, 7)),
      ))!;
      expect(before.body, contains('chi tiêu')); // hai kỳ đều rỗng

      build(transactions: chiTrong(DateTime(2026, 9, 7), 500000));
      await engine.reconcile();

      final after = (await ledger.byKey(
        summaryWeekEntryKey(DateTime(2026, 9, 7)),
      ))!;
      expect(after.body, isNot(before.body));
      expect(after.body, contains('500.000 đ'));
    });

    test('đúng 1 mốc/tuần và 1/tháng sau nhiều lần reconcile (SC-006)', () async {
      build();
      await engine.reconcile();
      await engine.reconcile();
      await engine.reconcile();

      final rows = await ledger.all();
      expect(
        rows.where((e) => e.entryKey.startsWith('summary:week:')),
        hasLength(1),
      );
      expect(
        rows.where((e) => e.entryKey.startsWith('summary:month:')),
        hasLength(1),
      );
    });

    test('kỳ vừa kết thúc RỖNG ⇒ vẫn 1 thông báo, câu chữ đúng (AC#19)', () async {
      build();
      await engine.reconcile();
      now = DateTime(2026, 9, 13, 21); // qua mốc 20:00
      await engine.reconcile();

      final records = history.stored
          .where((n) => n.kind == NotificationKind.periodSummary)
          .toList();
      expect(records, hasLength(1));
      expect(records.single.body, contains('Xem chi tiết báo cáo.'));
      expect(records.single.body, isNot(contains('null')));
    });

    test('kỳ TRƯỚC rỗng ⇒ bỏ câu so sánh sai lệch, không chia 0 (AC#20/G5)', () async {
      build(transactions: chiTrong(DateTime(2026, 9, 7), 500000));
      await engine.reconcile();
      now = DateTime(2026, 9, 13, 21);
      await engine.reconcile();

      final record = history.stored.firstWhere(
        (n) => n.kind == NotificationKind.periodSummary,
      );
      expect(record.body, isNot(contains('∞')));
      expect(record.body, isNot(contains('Infinity')));
      expect(record.body, isNot(contains('NaN')));
    });

    test('gọi reconcile sau mốc đã bắn ⇒ không bắn bù, mốc kế tiếp được đăng ký (FR-028)', () async {
      build();
      await engine.reconcile();
      now = DateTime(2026, 9, 13, 21);
      await engine.reconcile();
      expect(
        history.stored.where((n) => n.kind == NotificationKind.periodSummary),
        hasLength(1),
      );

      now = DateTime(2026, 9, 14, 8);
      presenter.scheduled.clear();
      await engine.reconcile();

      expect(
        history.stored.where((n) => n.kind == NotificationKind.periodSummary),
        hasLength(1),
        reason: 'Mốc tuần đã bắn không được ghi bù lần hai',
      );
      // Mốc tuần KẾ TIẾP (20/09) đã được đăng ký lại.
      final next = await ledger.byKey(summaryWeekEntryKey(DateTime(2026, 9, 14)));
      expect(next!.scheduledFor, DateTime(2026, 9, 20, 20, 0));
      expect(
        presenter.scheduled.any((n) => n.payload == next.entryKey),
        isTrue,
      );
    });

    test('tắt công tắc tổng kết ⇒ huỷ mốc đang chờ + không ghi bù (AC#15)', () async {
      build(prefs: NotificationPrefs.defaults.copyWith(weeklyEnabled: false));
      await engine.reconcile();

      expect(await ledger.byKey(summaryWeekEntryKey(DateTime(2026, 9, 7))), isNull);
      expect(presenter.cancelledKinds, isNot(contains(NotificationKind.periodSummary)));

      // Tháng vẫn hoạt động (hai công tắc độc lập).
      expect(
        await ledger.byKey(summaryMonthEntryKey(DateTime(2026, 9, 1))),
        isNotNull,
      );
    });

    test('Q3: ghé tab Báo cáo NGÀY THƯỜNG ⇒ không huỷ mốc tổng kết sắp tới', () async {
      // Thứ Tư 16/09 — mốc tuần là Chủ Nhật 20/09, KHÔNG rơi vào hôm nay.
      now = DateTime(2026, 9, 16, 10);
      build();
      await engine.reconcile();
      presence.enterReport();

      await engine.onEnterRelatedScreen(NotificationScreens.report);

      final weekKey = summaryWeekEntryKey(DateTime(2026, 9, 14));
      expect((await ledger.byKey(weekKey))!.suppressed, isFalse);
      expect(presenter.cancelled, isEmpty);
    });

    test('Q3: đang mở màn Báo cáo ⇒ huỷ mốc + chặn, rời màn không ghi bù (AC#10/H3–H4)', () async {
      build();
      await engine.reconcile();
      presence.enterReport();

      await engine.onEnterRelatedScreen(NotificationScreens.report);

      final weekKey = summaryWeekEntryKey(DateTime(2026, 9, 7));
      expect((await ledger.byKey(weekKey))!.suppressed, isTrue);
      expect(presenter.cancelled, contains(notificationIdFor(weekKey)));

      // Qua mốc trong lúc đang ở màn Báo cáo ⇒ không bản ghi nào.
      now = DateTime(2026, 9, 13, 21);
      presence.leave();
      await engine.onLeaveRelatedScreen();

      expect(
        history.stored.where((n) => n.kind == NotificationKind.periodSummary),
        isEmpty,
      );
      // Mốc tuần KẾ TIẾP được đăng ký lại.
      expect(
        await ledger.byKey(summaryWeekEntryKey(DateTime(2026, 9, 14))),
        isNotNull,
      );
    });
  });

  group('US1 — trần 200 bản ghi vẫn đúng khi engine ghi liên tục (FR-029/AC#25)', () {
    test('300 mốc quá khứ ⇒ lịch sử dừng ở 200', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped('Host thiếu sqlite native — bỏ qua test tích hợp drift.');
        return;
      }
      addTearDown(db.close);

      // Sổ có sẵn 300 mốc quá khứ còn nợ bản ghi — reconcile phải ghi bù hết
      // qua đúng `append` (nơi cưỡng chế trần), không tự chèn lách trần.
      final driftLedger = DriftNotificationLedger(db);
      for (var i = 0; i < 300; i++) {
        await driftLedger.upsert(
          _entry(
            'daily:past-$i',
            at: DateTime(2026, 1, 1).add(Duration(days: i)),
          ),
        );
      }
      build();
      engine = NotificationEngine(
        presenter: presenter,
        ledger: driftLedger,
        history: DriftNotificationHistoryStore(db),
        repository: repository,
        prefsStore: prefsStore,
        clock: () => DateTime(2026, 12, 31),
      );

      await engine.reconcile();

      final rows = await db.select(db.notifications).get();
      expect(rows, hasLength(kMaxNotifications));
      expect(rows.every((r) => r.readAt == null), isTrue);
    });
  });

  group('US1 — lỗi engine không làm hỏng luồng lưu (AC#21/FR-024)', () {
    test('ledger ném lỗi ⇒ onTransactionSaved vẫn trả về bình thường', () async {
      build(transactions: [_txn(id: 1, date: DateTime(2026, 9, 13, 9))]);
      ledger.failUpsert = true;
      ledger.failHistory = true;

      await expectLater(
        engine.onTransactionSaved(at: DateTime(2026, 9, 13, 9)),
        completes,
      );
    });

    test('presenter ném lỗi ⇒ reconcile/onPrefsChanged không ném ra ngoài', () async {
      build();
      presenter.failSchedule = true;

      await expectLater(engine.reconcile(), completes);
      await expectLater(engine.onPrefsChanged(), completes);
    });

    test('store cấu hình ném lỗi ⇒ reconcile không ném', () async {
      build();
      prefsStore.failLoad = true;

      await expectLater(engine.reconcile(), completes);
      await expectLater(engine.handleTap('daily:2026-09-13'), completes);
    });
  });
}
