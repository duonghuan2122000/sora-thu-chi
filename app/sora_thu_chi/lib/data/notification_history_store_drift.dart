import 'package:drift/drift.dart';

import '../core/notification/app_notification.dart';
import '../core/notification/notification_history_store.dart';
import 'db/app_database.dart';

/// Impl thật (drift) của [NotificationHistoryStore] — map bảng `Notifications`
/// ↔ [AppNotification]. Trần [kMaxNotifications] cưỡng chế **ngay trong
/// [append]** (chèn rồi xoá ngoài top-200) nên mọi đường ghi đều đúng, kể cả
/// engine tương lai (research R3). [markRead] chỉ chạm dòng **đang chưa đọc**
/// (`read_at IS NULL`) — bất biến một chiều nằm trong câu SQL, không ở UI (R13).
class DriftNotificationHistoryStore implements NotificationHistoryStore {
  DriftNotificationHistoryStore(this._db);

  final AppDatabase _db;

  @override
  Future<List<AppNotification>> loadRecent() async {
    final rows =
        await (_db.select(_db.notifications)..orderBy([
              (r) => OrderingTerm.desc(r.createdAt),
              (r) => OrderingTerm.desc(r.id),
            ]))
            .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> append(AppNotification notification) async {
    await _db
        .into(_db.notifications)
        .insert(
          NotificationsCompanion.insert(
            kind: notification.kind,
            title: notification.title,
            body: Value(notification.body),
            createdAt: notification.createdAt,
            readAt: Value(notification.readAt),
            relatedId: Value(notification.relatedId),
          ),
        );
    await _trimToLimit();
  }

  @override
  Future<void> markRead(int id, DateTime readAt) async {
    await (_db.update(_db.notifications)
          ..where((r) => r.id.equals(id) & r.readAt.isNull()))
        .write(NotificationsCompanion(readAt: Value(readAt)));
  }

  /// Xoá mọi dòng **ngoài top-[kMaxNotifications]** theo `(createdAt DESC, id
  /// DESC)` — khoá phụ `id` để thứ tự tất định khi trùng `createdAt` (luật 3).
  Future<void> _trimToLimit() async {
    final keep =
        await (_db.selectOnly(_db.notifications)
              ..addColumns([_db.notifications.id])
              ..orderBy([
                OrderingTerm.desc(_db.notifications.createdAt),
                OrderingTerm.desc(_db.notifications.id),
              ])
              ..limit(kMaxNotifications))
            .map((r) => r.read(_db.notifications.id)!)
            .get();
    if (keep.isEmpty) return;
    await (_db.delete(
      _db.notifications,
    )..where((r) => r.id.isNotIn(keep))).go();
  }

  /// `kind` là `textEnum` ⇒ drift đã trả về enum; chỉ cần đổi tên trường.
  AppNotification _toDomain(NotificationsRow row) => AppNotification(
    id: row.id,
    kind: row.kind,
    title: row.title,
    body: row.body,
    createdAt: row.createdAt,
    readAt: row.readAt,
    relatedId: row.relatedId,
  );
}
