import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/notification/app_notification.dart';
import 'package:sora_thu_chi/core/notification/notification_ledger.dart';
import 'package:sora_thu_chi/data/db/app_database.dart';
import 'package:sora_thu_chi/data/notification_ledger_drift.dart';

const _skip = 'Host thiếu sqlite native — bỏ qua DAO drift tích hợp.';

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

NotificationLedgerEntry _entry(
  String key, {
  DateTime? at,
  bool suppressed = false,
  NotificationKind kind = NotificationKind.dailyReminder,
  int? relatedId,
  DateTime? historyWrittenAt,
  int? historyId,
}) => NotificationLedgerEntry(
  entryKey: key,
  kind: kind,
  title: 'Tiêu đề',
  body: 'Mô tả',
  scheduledFor: at ?? DateTime(2026, 9, 13, 20, 30),
  suppressed: suppressed,
  relatedId: relatedId,
  historyWrittenAt: historyWrittenAt,
  historyId: historyId,
);

void main() {
  test('schema v10 (PBI 31 thêm bảng notification_ledger)', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    expect(db.schemaVersion, 10);
  });

  test('bảng rỗng → all() trả [] (không ném, không seed)', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    expect(await DriftNotificationLedger(db).all(), isEmpty);
  });

  test('upsert cùng khoá 2 lần ⇒ đúng 1 dòng, giá trị là bản mới nhất', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);
    final ledger = DriftNotificationLedger(db);

    await ledger.upsert(_entry('daily:2026-09-13'));
    await ledger.upsert(
      _entry(
        'daily:2026-09-13',
        at: DateTime(2026, 9, 13, 21),
        kind: NotificationKind.budgetAlert,
        relatedId: 7,
      ),
    );

    final all = await ledger.all();
    expect(all, hasLength(1));
    expect(all.single.scheduledFor, DateTime(2026, 9, 13, 21));
    expect(all.single.kind, NotificationKind.budgetAlert);
    expect(all.single.relatedId, 7);
  });

  test('byKey trả null khi không có; trả đúng dòng khi có', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);
    final ledger = DriftNotificationLedger(db);

    expect(await ledger.byKey('daily:2026-09-13'), isNull);
    await ledger.upsert(_entry('daily:2026-09-13'));
    expect(
      (await ledger.byKey('daily:2026-09-13'))?.entryKey,
      'daily:2026-09-13',
    );
  });

  test('dueBefore: đúng mốc đã tới hạn và còn nợ bản ghi (FR-003)', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);
    final ledger = DriftNotificationLedger(db);
    final now = DateTime(2026, 9, 13, 21);

    await ledger.upsert(_entry('qua-khu', at: DateTime(2026, 9, 13, 20, 30)));
    await ledger.upsert(_entry('tuong-lai', at: DateTime(2026, 9, 14, 20, 30)));
    await ledger.upsert(
      _entry('da-chan', at: DateTime(2026, 9, 13, 19), suppressed: true),
    );
    await ledger.upsert(
      _entry(
        'da-ghi',
        at: DateTime(2026, 9, 13, 18),
        historyWrittenAt: DateTime(2026, 9, 13, 18, 5),
        historyId: 42,
      ),
    );

    final due = await ledger.dueBefore(now);
    expect(due.map((e) => e.entryKey), ['qua-khu']);
  });

  test('markHistoryWritten điền CẢ mốc thời gian LẪN history_id (luật 4)', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);
    final ledger = DriftNotificationLedger(db);
    await ledger.upsert(_entry('daily:2026-09-13'));

    final at = DateTime(2026, 9, 14, 8);
    await ledger.markHistoryWritten('daily:2026-09-13', 99, at);

    final row = (await ledger.byKey('daily:2026-09-13'))!;
    expect(row.historyWrittenAt, at);
    expect(row.historyId, 99);
    expect(row.pendingHistory, isFalse);
  });

  test('markHistoryWritten khoá không tồn tại → no-op, không ném', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    await DriftNotificationLedger(
      db,
    ).markHistoryWritten('khong-co', 1, DateTime(2026, 9, 14));
    expect(await DriftNotificationLedger(db).all(), isEmpty);
  });

  test('suppress chỉ đặt cờ, KHÔNG xoá dòng, không chạm history', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);
    final ledger = DriftNotificationLedger(db);
    await ledger.upsert(_entry('daily:2026-09-13'));

    await ledger.suppress('daily:2026-09-13');

    final row = (await ledger.byKey('daily:2026-09-13'))!;
    expect(row.suppressed, isTrue);
    expect(row.historyWrittenAt, isNull);
    expect(row.pendingHistory, isFalse);
    expect(await ledger.all(), hasLength(1));
  });

  test('pruneBefore CHỈ xoá dòng đã xử lý xong (luật dọn sổ)', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);
    final ledger = DriftNotificationLedger(db);
    final cutoff = DateTime(2026, 6, 1);

    await ledger.upsert(_entry('cu-da-chan', at: DateTime(2026, 1, 5), suppressed: true));
    await ledger.upsert(
      _entry(
        'cu-da-ghi',
        at: DateTime(2026, 1, 6),
        historyWrittenAt: DateTime(2026, 1, 6, 1),
        historyId: 3,
      ),
    );
    await ledger.upsert(_entry('cu-con-no', at: DateTime(2026, 1, 7)));
    await ledger.upsert(_entry('moi', at: DateTime(2026, 9, 13)));

    await ledger.pruneBefore(cutoff);

    expect(
      (await ledger.all()).map((e) => e.entryKey).toSet(),
      {'cu-con-no', 'moi'},
    );
  });

  test('sổ là bảng DUY NHẤT bị đụng — 6 bảng nghiệp vụ nguyên vẹn (luật 13)', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);
    final ledger = DriftNotificationLedger(db);

    Future<Map<String, int>> counts() async => {
      'wallets': (await db.select(db.wallets).get()).length,
      'transactions': (await db.select(db.transactions).get()).length,
      'categories': (await db.select(db.categories).get()).length,
      'budgets': (await db.select(db.budgets).get()).length,
      'notifications': (await db.select(db.notifications).get()).length,
      'appSettings': (await db.select(db.appSettings).get()).length,
    };

    final before = await counts();
    await ledger.upsert(_entry('daily:2026-09-13'));
    await ledger.suppress('daily:2026-09-13');
    await ledger.upsert(_entry('budget:over:3:2026-09-01'));
    await ledger.markHistoryWritten('budget:over:3:2026-09-01', 1, DateTime(2026, 9, 2));
    await ledger.pruneBefore(DateTime(2027, 1, 1));

    expect(await counts(), before);
  });
}
