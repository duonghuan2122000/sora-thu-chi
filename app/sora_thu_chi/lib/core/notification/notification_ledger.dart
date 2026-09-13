import 'app_notification.dart';

/// Một dòng **sổ thông báo** (PBI 31, data-model §1) — bộ nhớ duy nhất để
/// (a) chống bắn trùng, (b) biết mốc nào còn **nợ** một bản ghi Trung tâm,
/// (c) tra ngược `history_id` khi người dùng chạm thông báo.
///
/// Vì sao cần sổ riêng thay vì đọc thẳng bảng `notifications`: khi app **đóng**
/// lúc mốc bắn, hệ điều hành không chạy Dart (R0) nên bản ghi Trung tâm chỉ được
/// **ghi bù** ở lần mở app kế tiếp; sổ là thứ duy nhất sống qua khoảng đó.
class NotificationLedgerEntry {
  const NotificationLedgerEntry({
    required this.entryKey,
    required this.kind,
    required this.title,
    required this.body,
    required this.scheduledFor,
    this.relatedId,
    this.suppressed = false,
    this.historyWrittenAt,
    this.historyId,
  });

  /// Khoá nghiệp vụ duy nhất, **mang kỳ** (R7): `daily:<yyyy-MM-dd>`,
  /// `summary:week:<yyyy-MM-dd>`, `summary:month:<yyyy-MM>`,
  /// `budget:early|over:<budgetId>:<đầu kỳ>` — cũng là khoá chính của bảng.
  final String entryKey;

  /// Loại thông báo — dùng lại enum của PBI 30. Đợt này sổ **chỉ** chứa
  /// `dailyReminder`/`budgetAlert`/`periodSummary` (FR-002).
  final NotificationKind kind;

  /// `budgetId` cho cảnh báo ngân sách; `null` cho nhắc hàng ngày & tổng kết.
  final int? relatedId;

  /// Câu chữ **snapshot** theo ngôn ngữ lúc lên lịch/bắn (FR-027) — hiển thị
  /// nguyên văn, không dịch lại.
  final String title;
  final String body;

  /// Mốc dự kiến bắn (giờ địa phương). **Cũng là `created_at`** của bản ghi
  /// Trung tâm tương ứng ⇒ nhãn thời gian & nhóm ngày khớp lúc thông báo hiện ra.
  final DateTime scheduledFor;

  /// Bị chặn (cờ "chỉ nhắc nếu chưa ghi" hoặc Q3 đang ở màn liên quan) ⇒ không
  /// bắn, **không bao giờ** có bản ghi.
  final bool suppressed;

  /// `null` = chưa ghi bản ghi Trung tâm (còn nợ); có giá trị = đã ghi lúc đó.
  final DateTime? historyWrittenAt;

  /// `notifications.id` của bản ghi tương ứng — dùng để `markRead` khi chạm.
  final int? historyId;

  /// Còn nợ một bản ghi Trung tâm (bất biến 3: `suppressed` ⇒ luôn `false`).
  bool get pendingHistory => !suppressed && historyWrittenAt == null;

  NotificationLedgerEntry copyWith({
    String? entryKey,
    NotificationKind? kind,
    int? relatedId,
    String? title,
    String? body,
    DateTime? scheduledFor,
    bool? suppressed,
    DateTime? historyWrittenAt,
    int? historyId,
  }) => NotificationLedgerEntry(
    entryKey: entryKey ?? this.entryKey,
    kind: kind ?? this.kind,
    relatedId: relatedId ?? this.relatedId,
    title: title ?? this.title,
    body: body ?? this.body,
    scheduledFor: scheduledFor ?? this.scheduledFor,
    suppressed: suppressed ?? this.suppressed,
    historyWrittenAt: historyWrittenAt ?? this.historyWrittenAt,
    historyId: historyId ?? this.historyId,
  );

  @override
  bool operator ==(Object other) =>
      other is NotificationLedgerEntry &&
      other.entryKey == entryKey &&
      other.kind == kind &&
      other.relatedId == relatedId &&
      other.title == title &&
      other.body == body &&
      other.scheduledFor == scheduledFor &&
      other.suppressed == suppressed &&
      other.historyWrittenAt == historyWrittenAt &&
      other.historyId == historyId;

  @override
  int get hashCode => Object.hash(
    entryKey,
    kind,
    relatedId,
    title,
    body,
    scheduledFor,
    suppressed,
    historyWrittenAt,
    historyId,
  );
}

/// Seam đọc/ghi sổ — engine phụ thuộc interface này để test bơm fake (không cần
/// sqlite native). Impl thật: `DriftNotificationLedger`.
///
/// Cố ý **không** có `delete`: dòng sổ chỉ được **dọn** qua [pruneBefore] (mốc
/// quá cũ **đã xử lý xong**), nên khoá chống trùng của kỳ đang chạy không thể
/// mất — bám tinh thần "không thao tác xoá hàng loạt" của PBI 30.
abstract class NotificationLedger {
  Future<NotificationLedgerEntry?> byKey(String entryKey);

  /// Mọi mốc **đã tới hạn** ([now] trở về trước) mà **còn nợ** bản ghi Trung tâm
  /// — tức `scheduled_for <= now && suppressed = false && history_written_at IS NULL`.
  Future<List<NotificationLedgerEntry>> dueBefore(DateTime now);

  Future<List<NotificationLedgerEntry>> all();

  /// Ghi/đè theo [NotificationLedgerEntry.entryKey] — lên lịch lại **cùng khoá**
  /// không sinh dòng thứ hai (bất biến 1).
  Future<void> upsert(NotificationLedgerEntry entry);

  /// Đánh dấu đã ghi bản ghi Trung tâm — ghi **cả** mốc thời gian **lẫn** id
  /// (bất biến 4: có `historyWrittenAt` ⇒ có `historyId`).
  Future<void> markHistoryWritten(String entryKey, int historyId, DateTime at);

  /// Chặn một mốc **chưa bắn** — chỉ đặt cờ, không xoá dòng.
  Future<void> suppress(String entryKey);

  /// Dọn dòng `scheduled_for < cutoff` **đã xử lý xong** (đã chặn hoặc đã ghi
  /// bản ghi) — dòng còn nợ **không** bị xoá.
  Future<void> pruneBefore(DateTime cutoff);
}
