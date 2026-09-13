import 'package:sora_thu_chi/core/notification/notification_ledger.dart';

/// Bản bộ nhớ của [NotificationLedger] — engine test được toàn bộ luật chống
/// trùng/hoà giải mà không cần sqlite native (bám `fake_notification_store.dart`).
///
/// [entries] giữ nguyên thứ tự chèn (`LinkedHashMap` ngầm) nên test assert được
/// cả nội dung lẫn số dòng. [failUpsert]/[failHistory] cắm lỗi để kiểm FR-024
/// (engine **không** ném ra ngoài).
class FakeNotificationLedger implements NotificationLedger {
  FakeNotificationLedger({List<NotificationLedgerEntry>? stored}) {
    for (final e in stored ?? const <NotificationLedgerEntry>[]) {
      entries[e.entryKey] = e;
    }
  }

  /// Toàn bộ sổ, khoá theo `entryKey`.
  final Map<String, NotificationLedgerEntry> entries = {};

  /// Số lần [upsert] đã gọi — kiểm "cùng khoá không nhân đôi dòng".
  int upsertCount = 0;

  bool failUpsert = false;
  bool failHistory = false;

  @override
  Future<NotificationLedgerEntry?> byKey(String entryKey) async =>
      entries[entryKey];

  @override
  Future<List<NotificationLedgerEntry>> dueBefore(DateTime now) async => [
    for (final e in entries.values)
      if (!e.scheduledFor.isAfter(now) && e.pendingHistory) e,
  ];

  @override
  Future<List<NotificationLedgerEntry>> all() async => entries.values.toList();

  @override
  Future<void> upsert(NotificationLedgerEntry entry) async {
    upsertCount++;
    if (failUpsert) throw StateError('upsert failed');
    entries[entry.entryKey] = entry;
  }

  @override
  Future<void> markHistoryWritten(
    String entryKey,
    int historyId,
    DateTime at,
  ) async {
    if (failHistory) throw StateError('markHistoryWritten failed');
    final current = entries[entryKey];
    if (current == null) return;
    entries[entryKey] = current.copyWith(
      historyWrittenAt: at,
      historyId: historyId,
    );
  }

  @override
  Future<void> suppress(String entryKey) async {
    final current = entries[entryKey];
    if (current == null) return;
    entries[entryKey] = current.copyWith(suppressed: true);
  }

  @override
  Future<void> pruneBefore(DateTime cutoff) async {
    entries.removeWhere(
      (_, e) =>
          e.scheduledFor.isBefore(cutoff) &&
          (e.suppressed || e.historyWrittenAt != null),
    );
  }
}
