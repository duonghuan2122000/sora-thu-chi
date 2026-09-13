import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/notification/app_notification.dart';
import 'package:sora_thu_chi/data/db/app_database.dart';
import 'package:sora_thu_chi/data/notification_history_store_drift.dart';

const _skip = 'Host thiếu sqlite native — bỏ qua DAO drift tích hợp.';

/// Mở DB drift trong bộ nhớ. Host Windows thiếu sqlite native → trả null
/// (test skip-guard, như `notification_store_drift_test`).
Future<AppDatabase?> _tryMemoryDb() async {
  try {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get(); // buộc mở connection
    return db;
  } catch (_) {
    return null;
  }
}

AppNotification _n({
  required int id,
  required NotificationKind kind,
  required DateTime createdAt,
  String title = 'Tiêu đề',
  String body = '',
  DateTime? readAt,
  int? relatedId,
}) => AppNotification(
  id: id,
  kind: kind,
  title: title,
  body: body,
  createdAt: createdAt,
  readAt: readAt,
  relatedId: relatedId,
);

void main() {
  test('schema v9 (PBI 30 thêm bảng notifications)', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    expect(db.schemaVersion, 10);
  });

  test('bảng rỗng → loadRecent trả [] (không ném, không seed)', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    final store = DriftNotificationHistoryStore(db);
    expect(await store.loadRecent(), isEmpty);
    expect(await db.select(db.notifications).get(), isEmpty);
  });

  test('append 3 dòng → loadRecent mới nhất trước, id DB tự sinh', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    final store = DriftNotificationHistoryStore(db);
    // `id` domain bị bỏ qua (đây truyền 99) — DB tự sinh.
    await store.append(
      _n(
        id: 99,
        kind: NotificationKind.dailyReminder,
        title: 'Cũ nhất',
        createdAt: DateTime(2026, 9, 1, 8, 0),
      ),
    );
    await store.append(
      _n(
        id: 0,
        kind: NotificationKind.budgetAlert,
        title: 'Giữa',
        body: 'Đã dùng 82%',
        createdAt: DateTime(2026, 9, 5, 8, 0),
        relatedId: 4,
      ),
    );
    await store.append(
      _n(
        id: 0,
        kind: NotificationKind.periodSummary,
        title: 'Mới nhất',
        createdAt: DateTime(2026, 9, 10, 8, 0),
      ),
    );

    final items = await store.loadRecent();
    expect(items.map((n) => n.title), ['Mới nhất', 'Giữa', 'Cũ nhất']);
    expect(items.map((n) => n.id).toSet().length, 3, reason: 'id DB tự sinh');
    expect(items[1].kind, NotificationKind.budgetAlert);
    expect(items[1].body, 'Đã dùng 82%');
    expect(items[1].relatedId, 4);
    expect(items[1].isRead, isFalse);
  });

  test('hai dòng cùng createdAt → id giảm dần (khoá phụ tất định)', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    final store = DriftNotificationHistoryStore(db);
    final same = DateTime(2026, 9, 10, 8, 0);
    await store.append(
      _n(id: 0, kind: NotificationKind.goalReminder, title: 'A', createdAt: same),
    );
    await store.append(
      _n(id: 0, kind: NotificationKind.goalReminder, title: 'B', createdAt: same),
    );

    final items = await store.loadRecent();
    expect(items.map((n) => n.title), ['B', 'A']);
    expect(items[0].id, greaterThan(items[1].id));
  });

  test('trần 200: append 205 dòng → giữ đúng 200 id MỚI NHẤT', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    final store = DriftNotificationHistoryStore(db);
    for (var i = 1; i <= 205; i++) {
      await store.append(
        _n(
          id: 0,
          kind: NotificationKind.dailyReminder,
          title: 'Mục $i',
          createdAt: DateTime(2026, 9, 1).add(Duration(minutes: i)),
        ),
      );
    }

    final items = await store.loadRecent();
    expect(items, hasLength(kMaxNotifications));
    // Mỗi append dọn ngay ⇒ 5 mục cũ nhất (1…5) bị dọn; 6…205 còn nguyên.
    final titles = items.map((n) => n.title).toSet();
    expect(titles.contains('Mục 5'), isFalse);
    expect(titles.contains('Mục 6'), isTrue);
    expect(items.first.title, 'Mục 205');
    expect(items.last.title, 'Mục 6');
    expect(await db.select(db.notifications).get(), hasLength(200));
  });

  test('markRead: một chiều — gọi lần 2 không đổi readAt', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    final store = DriftNotificationHistoryStore(db);
    await store.append(
      _n(
        id: 0,
        kind: NotificationKind.dailyReminder,
        title: 'Một',
        createdAt: DateTime(2026, 9, 10, 8, 0),
      ),
    );
    final id = (await store.loadRecent()).single.id;
    final first = DateTime(2026, 9, 11, 9, 30);

    await store.markRead(id, first);
    var item = (await store.loadRecent()).single;
    expect(item.isRead, isTrue);
    expect(item.readAt, first);

    await store.markRead(id, DateTime(2026, 9, 12, 10, 0));
    item = (await store.loadRecent()).single;
    expect(item.readAt, first, reason: 'ghi đè bị chặn trong SQL');
  });

  test('markRead id không tồn tại → no-op, không ném, không tạo dòng', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    final store = DriftNotificationHistoryStore(db);
    await store.markRead(999, DateTime(2026, 9, 11));

    expect(await store.loadRecent(), isEmpty);
  });

  test('append + markRead không đụng appSettings/wallets/transactions', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    final settingsBefore = await db.select(db.appSettings).get();
    final walletsBefore = await db.select(db.wallets).get();
    final txnBefore = await db.select(db.transactions).get();

    final store = DriftNotificationHistoryStore(db);
    await store.append(
      _n(
        id: 0,
        kind: NotificationKind.budgetAlert,
        title: 'Cảnh báo',
        createdAt: DateTime(2026, 9, 10, 8, 0),
        relatedId: 1,
      ),
    );
    await store.markRead((await store.loadRecent()).single.id, DateTime.now());

    expect(await db.select(db.appSettings).get(), settingsBefore);
    expect(await db.select(db.wallets).get(), walletsBefore);
    expect(await db.select(db.transactions).get(), txnBefore);
  });
}
