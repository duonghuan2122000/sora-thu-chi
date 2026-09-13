import 'package:drift/drift.dart';

import '../core/notification/notification_ledger.dart';
// `hide`: bảng drift cũng tên `NotificationLedger` — che nó để tên trần trong
// file này luôn là **seam** ở trên (bảng chỉ dùng qua `_db.notificationLedger`).
import 'db/app_database.dart' hide NotificationLedger;

/// Impl thật (drift) của [NotificationLedger] — map bảng `NotificationLedger`
/// ↔ [NotificationLedgerEntry] (bám khuôn mỏng `notification_history_store_drift`).
///
/// Bất biến nằm **trong câu SQL**, không ở tầng gọi: [dueBefore] tự loại dòng
/// đã chặn/đã ghi bản ghi; [pruneBefore] **không** xoá dòng còn nợ. Nhờ vậy
/// engine không thể vô tình ghi bù hai lần cùng một mốc.
class DriftNotificationLedger implements NotificationLedger {
  DriftNotificationLedger(this._db);

  final AppDatabase _db;

  @override
  Future<NotificationLedgerEntry?> byKey(String entryKey) async {
    final row = await (_db.select(
      _db.notificationLedger,
    )..where((r) => r.entryKey.equals(entryKey))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<NotificationLedgerEntry>> dueBefore(DateTime now) async {
    final rows =
        await (_db.select(_db.notificationLedger)
              ..where(
                (r) =>
                    r.scheduledFor.isSmallerOrEqualValue(now) &
                    r.suppressed.equals(false) &
                    r.historyWrittenAt.isNull(),
              )
              ..orderBy([(r) => OrderingTerm.asc(r.scheduledFor)]))
            .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<NotificationLedgerEntry>> all() async {
    final rows = await (_db.select(_db.notificationLedger)..orderBy([
      (r) => OrderingTerm.asc(r.scheduledFor),
    ])).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> upsert(NotificationLedgerEntry entry) async {
    await _db
        .into(_db.notificationLedger)
        .insertOnConflictUpdate(
          NotificationLedgerCompanion.insert(
            entryKey: entry.entryKey,
            kind: entry.kind,
            title: entry.title,
            body: Value(entry.body),
            scheduledFor: entry.scheduledFor,
            relatedId: Value(entry.relatedId),
            suppressed: Value(entry.suppressed),
            historyWrittenAt: Value(entry.historyWrittenAt),
            historyId: Value(entry.historyId),
          ),
        );
  }

  @override
  Future<void> markHistoryWritten(
    String entryKey,
    int historyId,
    DateTime at,
  ) async {
    await (_db.update(
      _db.notificationLedger,
    )..where((r) => r.entryKey.equals(entryKey))).write(
      NotificationLedgerCompanion(
        historyWrittenAt: Value(at),
        historyId: Value(historyId),
      ),
    );
  }

  /// Chỉ đặt cờ — **không** xoá dòng (khoá chống trùng phải sống tiếp) và không
  /// chạm `history_written_at`/`history_id`.
  @override
  Future<void> suppress(String entryKey) async {
    await (_db.update(
      _db.notificationLedger,
    )..where((r) => r.entryKey.equals(entryKey))).write(
      const NotificationLedgerCompanion(suppressed: Value(true)),
    );
  }

  /// Xoá dòng quá cũ **đã xử lý xong** (đã chặn hoặc đã ghi bản ghi). Dòng còn
  /// nợ bản ghi **ở lại** — nếu không, hoà giải sẽ mất dấu và bản ghi Trung tâm
  /// của mốc đó không bao giờ được ghi.
  @override
  Future<void> pruneBefore(DateTime cutoff) async {
    await (_db.delete(_db.notificationLedger)..where(
          (r) =>
              r.scheduledFor.isSmallerThanValue(cutoff) &
              (r.suppressed.equals(true) | r.historyWrittenAt.isNotNull()),
        ))
        .go();
  }

  /// `kind` là `textEnum` ⇒ drift đã trả về enum; chỉ đổi tên trường.
  NotificationLedgerEntry _toDomain(NotificationLedgerRow row) =>
      NotificationLedgerEntry(
        entryKey: row.entryKey,
        kind: row.kind,
        relatedId: row.relatedId,
        title: row.title,
        body: row.body,
        scheduledFor: row.scheduledFor,
        suppressed: row.suppressed,
        historyWrittenAt: row.historyWrittenAt,
        historyId: row.historyId,
      );
}
