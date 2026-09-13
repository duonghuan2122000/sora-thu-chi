import '../../data/wallet_repository.dart';
import '../budget/budget.dart';
import '../budget/budget_view.dart';
import '../category/category.dart';
import '../transaction/transaction.dart';
import '../report/report_view.dart';
import 'app_notification.dart';
import 'notification_content.dart';
import 'notification_history_store.dart';
import 'notification_ledger.dart';
import 'notification_prefs.dart';
import 'notification_presenter.dart';
import 'notification_presence.dart';
import 'notification_schedule.dart';
import 'notification_store.dart';
import 'notification_tap.dart';

/// **Số ngày giữ sổ** trước khi dọn (data-model §1) — lớn hơn mọi kỳ ngân sách
/// (tháng/năm) nên **không** làm mất khoá chống trùng của kỳ đang chạy.
const int kLedgerRetentionDays = 90;

/// Bộ điều phối thông báo (PBI 31) — quyết định **khi nào** bắn cái gì, sinh
/// câu chữ, chống trùng và hoà giải bản ghi Trung tâm.
///
/// Ba luật xuyên suốt:
///
/// * **Chỉ đọc** dữ liệu nghiệp vụ (giao dịch/ngân sách/danh mục) và **chỉ ghi**
///   sổ + lịch sử Trung tâm (FR-023/SC-013) — không chạm ví/danh mục/ngân sách.
/// * **Không bao giờ ném ra ngoài**: mọi API công khai bọc `try/catch` nuốt lỗi
///   (FR-024/SC-012) — thông báo là tính năng phụ, không được làm hỏng hay làm
///   chậm luồng lưu giao dịch.
/// * Mọi tham số **đọc lại từ cấu hình đang lưu** ở mỗi lần tính (FR-030) —
///   engine không giữ bản sao và không có màn chỉnh tham số riêng.
class NotificationEngine {
  NotificationEngine({
    required this.presenter,
    required this.ledger,
    required this.history,
    required this.repository,
    required this.prefsStore,
    this.presence,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final NotificationPresenter presenter;
  final NotificationLedger ledger;
  final NotificationHistoryStore history;
  final WalletRepository repository;
  final NotificationStore prefsStore;

  /// Màn đang mở (Q3) — `null` khi test không quan tâm luật "đang ở màn liên quan".
  final NotificationPresence? presence;

  final DateTime Function() _clock;

  /// Đồng bộ hoá: hoà giải bản ghi còn nợ → dọn sổ → cuốn lịch từng loại đang
  /// bật. Gọi fire-and-forget khi boot và ở **mỗi** lần app trở lại tiền cảnh.
  Future<void> reconcile() async {
    try {
      final now = _clock();
      await _reconcilePendingHistory(now);
      await ledger.pruneBefore(
        now.subtract(const Duration(days: kLedgerRetentionDays)),
      );
      final prefs = await prefsStore.load();
      await _rollDaily(prefs, now);
      await _rollSummaries(prefs, now);
    } catch (_) {
      // Nuốt lỗi: engine hỏng không được ảnh hưởng người dùng (FR-024).
    }
  }

  /// Người dùng vừa đổi cấu hình ở màn `01`/`02` ⇒ hiệu lực **ngay** (FR-021):
  /// huỷ các mốc đang chờ của loại vừa tắt rồi cuốn lại lịch.
  Future<void> onPrefsChanged() async {
    try {
      final prefs = await prefsStore.load();
      if (!prefs.dailyEnabled) {
        await presenter.cancelKind(NotificationKind.dailyReminder);
      }
      await reconcile();
    } catch (_) {
      // Nuốt lỗi (FR-024).
    }
  }

  /// Vừa lưu **một giao dịch** (thu/chi/quét/chuyển khoản).
  ///
  /// Cờ "chỉ nhắc nếu chưa ghi" (FR-008/FR-011): hôm nay đã có **bất kỳ** giao
  /// dịch nào ⇒ huỷ mốc nhắc hôm nay và chặn nó — **chuyển khoản cũng tính**
  /// (spec §FR-011) dù nó không vào ngân sách.
  ///
  /// [type] là loại giao dịch vừa lưu: cảnh báo ngân sách **chỉ** chạy khi đó là
  /// giao dịch **Chi** (FR-012/FR-014) — lưu khoản Thu hay chuyển khoản **không**
  /// được kích hoạt cảnh báo. `null` (không rõ loại) ⇒ bỏ qua nhánh ngân sách.
  Future<void> onTransactionSaved({
    required DateTime at,
    TxnType? type,
  }) async {
    try {
      final prefs = await prefsStore.load();
      if (prefs.dailyEnabled && prefs.dailyOnlyIfNoTxnToday) {
        await _suppressTodayDailyIfLogged(prefs, at);
      }
      if (prefs.budgetEnabled && type == TxnType.expense) {
        await _checkBudgets(prefs, at);
      }
      await reconcile();
    } catch (_) {
      // Nuốt lỗi — luồng lưu giao dịch không được biết engine có sự cố (FR-024).
    }
  }

  /// Người dùng **chạm** một thông báo (payload = `entryKey`).
  ///
  /// Hoà giải **trước** để bảo đảm bản ghi Trung tâm đã tồn tại (mốc có thể vừa
  /// bắn trong lúc app đóng), rồi đánh dấu đã đọc và trả đích + tham số điều
  /// hướng. Sổ thiếu dòng (app được cài lại khi thông báo còn trên khay) ⇒ suy
  /// loại từ **tiền tố khoá** và vẫn điều hướng được tới màn chung.
  Future<NotificationTapResult> handleTap(
    String entryKey, {
    int? relatedId,
  }) async {
    var kind = _kindOfEntryKey(entryKey);
    int? id = relatedId;
    try {
      await reconcile();
      final row = await ledger.byKey(entryKey);
      if (row != null) {
        kind = row.kind;
        id = row.relatedId;
        final historyId = row.historyId;
        if (historyId != null && historyId > 0) {
          await history.markRead(historyId, _clock());
        }
      }
    } catch (_) {
      // Nuốt lỗi: chạm thông báo vẫn phải mở được màn đích nếu suy ra được.
    }
    return (
      target: notificationTargetFor(kind: kind, relatedId: id),
      relatedId: id,
      period: _summaryPeriodOf(entryKey),
    );
  }

  /// Kỳ cần chọn sẵn khi chạm **thông báo tổng kết** (FR-018/AC#12) — khoá mang
  /// đúng đơn vị kỳ (`summary:week:`/`summary:month:`); khoá khác ⇒ `null` (giữ
  /// hành vi PBI 30: tab Báo cáo mở với kỳ mặc định).
  static ReportPeriod? _summaryPeriodOf(String entryKey) {
    if (entryKey.startsWith('summary:week:')) return ReportPeriod.week;
    if (entryKey.startsWith('summary:month:')) return ReportPeriod.month;
    return null;
  }

  // ---------------------------------------------------------------------------
  // Hoà giải
  // ---------------------------------------------------------------------------

  /// Ghi bù bản ghi Trung tâm cho mọi mốc **đã tới hạn mà còn nợ** (R6).
  ///
  /// `created_at` = `scheduled_for` (mốc bắn, không phải giờ mở app) ⇒ nhãn thời
  /// gian & nhóm ngày trên màn Trung tâm khớp đúng lúc thông báo hiện ra — người
  /// dùng **không phân biệt được** với ghi tại chỗ (quickstart §5 lệch 1).
  Future<void> _reconcilePendingHistory(DateTime now) async {
    for (final entry in await ledger.dueBefore(now)) {
      await history.append(
        AppNotification(
          kind: entry.kind,
          title: entry.title,
          body: entry.body,
          createdAt: entry.scheduledFor,
          relatedId: entry.relatedId,
        ),
      );
      await ledger.markHistoryWritten(
        entry.entryKey,
        await _historyIdOfLastAppend(entry),
        now,
      );
    }
  }

  /// Id của bản ghi vừa `append` — seam lịch sử của PBI 30 **không đổi** hợp
  /// đồng (không trả id), nên tra lại dòng khớp `(kind, title, createdAt)` và
  /// **chưa đọc**. Không tra được (store lạ/hỏng) ⇒ `0`: vẫn đánh dấu "đã ghi"
  /// để không ghi bù lặp vô hạn, chỉ mất khả năng `markRead` khi chạm.
  Future<int> _historyIdOfLastAppend(NotificationLedgerEntry entry) async {
    final recent = await history.loadRecent();
    for (final n in recent) {
      if (!n.isRead &&
          n.kind == entry.kind &&
          n.title == entry.title &&
          n.createdAt == entry.scheduledFor) {
        return n.id;
      }
    }
    return 0;
  }

  // ---------------------------------------------------------------------------
  // Nhắc nhập giao dịch hằng ngày (US1)
  // ---------------------------------------------------------------------------

  /// Cuốn lịch nhắc hàng ngày: mỗi mốc trong cửa sổ [kDailyWindowDays] ngày là
  /// **một lịch một-lần** (R2) nên huỷ được đúng mốc hôm nay khi đã ghi giao
  /// dịch. Mốc đã trôi qua **không** được đăng ký lại (FR-028).
  Future<void> _rollDaily(NotificationPrefs prefs, DateTime now) async {
    if (!prefs.dailyEnabled) {
      await presenter.cancelKind(NotificationKind.dailyReminder);
      return;
    }
    final loggedToday = await _hasTxnOn(now);
    final moments = dailyFireMoments(
      now: now,
      hour: prefs.dailyHour,
      minute: prefs.dailyMinute,
      weekdays: prefs.dailyWeekdays,
    );
    for (final moment in moments) {
      final entryKey = dailyEntryKey(moment);
      final existing = await ledger.byKey(entryKey);
      // Đã bắn/đã chặn rồi ⇒ không dựng lại (bất biến "sổ không hồi tố").
      if (existing != null && !existing.pendingHistory) continue;
      final content = dailyReminderContent(
        hasTxnToday: _isSameDay(moment, now) && loggedToday,
      );
      await ledger.upsert(
        NotificationLedgerEntry(
          entryKey: entryKey,
          kind: NotificationKind.dailyReminder,
          title: content.title,
          body: content.body,
          scheduledFor: moment,
        ),
      );
      await presenter.schedule(
        OsNotification(
          id: notificationIdFor(entryKey),
          kind: NotificationKind.dailyReminder,
          title: content.title,
          body: content.body,
          at: moment,
          payload: entryKey,
        ),
      );
    }
  }

  /// Huỷ + chặn mốc nhắc **hôm nay** khi người dùng vừa ghi giao dịch (R5).
  /// Chỉ chặn mốc **chưa bắn** — mốc đã bắn thì bản ghi của nó đã tồn tại và sổ
  /// không hồi tố.
  Future<void> _suppressTodayDailyIfLogged(
    NotificationPrefs prefs,
    DateTime at,
  ) async {
    if (!await _hasTxnOn(at)) return;
    final entryKey = dailyEntryKey(at);
    final entry = await ledger.byKey(entryKey);
    // Mốc chưa có trong sổ (ngày không được chọn, hoặc đã qua cửa sổ) ⇒ không
    // có gì để chặn; mốc đã bắn ⇒ giữ nguyên bản ghi đã có.
    if (entry == null || !entry.pendingHistory) return;
    await presenter.cancel(notificationIdFor(entryKey));
    await ledger.suppress(entryKey);
  }

  /// Hôm nay (theo ngày lịch của [at]) đã có **ít nhất một** giao dịch chưa —
  /// **mọi loại**, kể cả chuyển khoản (FR-011).
  Future<bool> _hasTxnOn(DateTime at) async {
    final transactions = await repository.allTransactions();
    return transactions.any((t) => _isSameDay(t.date, at));
  }

  // ---------------------------------------------------------------------------
  // Cảnh báo ngân sách (US2)
  // ---------------------------------------------------------------------------

  /// Xét **2 ngưỡng** của mọi ngân sách chưa lưu trữ sau khi lưu một giao dịch
  /// **Chi** (FR-012/FR-014).
  ///
  /// Tái dùng **nguyên hàm** của module ngân sách (`budgetPeriodRange` +
  /// `budgetScopeCategoryIds` + `budgetSpent`) nên phép lọc "Chi/đúng danh mục/
  /// trong kỳ" không thể lệch với màn Chi tiết ngân sách (SC-005). Ngưỡng đọc
  /// từ cấu hình đang lưu, không hard-code (FR-012/FR-030).
  Future<void> _checkBudgets(NotificationPrefs prefs, DateTime at) async {
    final budgets = await repository.budgets();
    if (budgets.isEmpty) return;
    final transactions = await repository.allTransactions();
    final categories = await repository.categoriesIncludingHidden(
      type: CategoryType.expense,
    );
    final categoryById = {for (final c in categories) c.id: c};

    for (final budget in budgets) {
      // Ngân sách đã lưu trữ không còn theo dõi (PBI 21); danh mục đã bị xoá ⇒
      // không đoán — 0 thông báo.
      if (budget.isArchived || budget.amount <= 0) continue;
      final category = categoryById[budget.categoryId];
      if (category == null) continue;

      // Q3 (FR-016/AC#10): đang mở **đúng** Chi tiết ngân sách này ⇒ bỏ qua
      // **hoàn toàn** — 0 thông báo, 0 bản ghi, 0 dòng sổ.
      if (_isViewingBudget(budget.id)) continue;

      final range = budgetPeriodRange(budget.period, at);
      final spent = budgetSpent(
        categoryIds: budgetScopeCategoryIds(budget.categoryId, categories),
        transactions: transactions,
        range: range,
      );
      final percent = spent * 100 ~/ budget.amount;

      // Ngưỡng **vượt mức** ưu tiên: chạm 104% chỉ báo "đã vượt", không báo
      // thêm "sắp vượt" (AC#7). Mỗi ngưỡng vẫn độc lập theo kỳ nhờ khoá mang kỳ.
      final bool? over = percent >= prefs.budgetOverPercent
          ? true
          : percent >= prefs.budgetEarlyPercent
          ? false
          : null;
      if (over == null) continue;

      final entryKey = budgetEntryKey(
        budgetId: budget.id,
        over: over,
        periodStart: range.start,
      );
      // Đã báo ngưỡng này trong kỳ ⇒ không lặp (FR-013); nhờ khoá mang kỳ nên
      // sang kỳ mới tự do báo lại.
      if (await ledger.byKey(entryKey) != null) continue;

      await _showBudgetAlert(
        entryKey: entryKey,
        budget: budget,
        categoryName: category.name,
        percent: percent,
        over: over,
        period: budget.period,
        periodStart: range.start,
        now: at,
      );
    }
  }

  /// Bắn ngay + ghi bản ghi + đánh dấu sổ — ba việc của **một** lần cảnh báo
  /// (FR-003: có thông báo thì phải có bản ghi, và ngược lại).
  Future<void> _showBudgetAlert({
    required String entryKey,
    required Budget budget,
    required String categoryName,
    required int percent,
    required bool over,
    required BudgetPeriod period,
    required DateTime periodStart,
    required DateTime now,
  }) async {
    final content = budgetAlertContent(
      categoryName: categoryName,
      percent: percent,
      over: over,
      periodLabel: budgetPeriodLabel(period, periodStart),
    );
    await presenter.show(
      OsNotification(
        id: notificationIdFor(entryKey),
        kind: NotificationKind.budgetAlert,
        title: content.title,
        body: content.body,
        at: now,
        payload: entryKey,
      ),
    );
    final entry = NotificationLedgerEntry(
      entryKey: entryKey,
      kind: NotificationKind.budgetAlert,
      relatedId: budget.id,
      title: content.title,
      body: content.body,
      scheduledFor: now,
    );
    await history.append(
      AppNotification(
        kind: entry.kind,
        title: entry.title,
        body: entry.body,
        createdAt: now,
        relatedId: budget.id,
      ),
    );
    // Ghi luôn `history_written_at` + `history_id`: cảnh báo ghi **tại chỗ**
    // (không nợ bản ghi) nên sổ chỉ còn việc chống trùng theo kỳ.
    await ledger.upsert(
      entry.copyWith(
        historyWrittenAt: now,
        historyId: await _historyIdOfLastAppend(entry),
      ),
    );
  }

  /// Đang mở **đúng** Chi tiết ngân sách [budgetId] (Q3 — FR-016/AC#10).
  bool _isViewingBudget(int budgetId) {
    final presence = this.presence;
    return presence != null &&
        presence.screen.value == NotificationScreens.budgetDetail &&
        presence.budgetId.value == budgetId;
  }

  // ---------------------------------------------------------------------------
  // Tổng kết tuần / tháng (US3)
  // ---------------------------------------------------------------------------

  /// Cuốn lịch tổng kết: **một mốc kế tiếp** cho mỗi loại đang bật (R3) — khác
  /// nhắc hàng ngày (cửa sổ 30 ngày) vì nội dung phải **tươi**: số liệu và câu so
  /// sánh được **tính lại ở mỗi lần `reconcile()`**, lưu vào sổ dưới dạng
  /// snapshot (FR-009/FR-027).
  ///
  /// Khoá mang **kỳ vừa kết thúc** (`summary:week:<Thứ Hai>` / `summary:month:<yyyy-MM>`)
  /// ⇒ chống trùng 1 lần/tuần, 1 lần/tháng (FR-015/SC-006) mà sang kỳ mới tự do
  /// báo lại.
  Future<void> _rollSummaries(NotificationPrefs prefs, DateTime now) async {
    await _rollSummaryType(
      prefs: prefs,
      now: now,
      enabled: prefs.weeklyEnabled,
      period: ReportPeriod.week,
      moment: nextWeeklySummaryMoment(now, prefs.weeklyHour, prefs.weeklyMinute),
      prefix: 'summary:week:',
    );
    await _rollSummaryType(
      prefs: prefs,
      now: now,
      enabled: prefs.monthlyEnabled,
      period: ReportPeriod.month,
      moment: nextMonthlySummaryMoment(
        now,
        prefs.monthlyHour,
        prefs.monthlyMinute,
      ),
      prefix: 'summary:month:',
    );
  }

  Future<void> _rollSummaryType({
    required NotificationPrefs prefs,
    required DateTime now,
    required bool enabled,
    required ReportPeriod period,
    required DateTime moment,
    required String prefix,
  }) async {
    if (!enabled) {
      await _stopSummaryType(prefix);
      return;
    }
    final transactions = await repository.allTransactions();
    final categories = await repository.categoriesIncludingHidden(
      type: CategoryType.expense,
    );
    // Kỳ **vừa kết thúc** tính từ mốc bắn; kỳ đối chiếu là kỳ liền trước.
    final ended = reportPeriodRange(period, moment);
    final previous = reportRefRange(period, ended, CompareMode.previous);
    final comparison = reportComparison(
      transactions: transactions,
      categories: categories,
      period: period,
      leftAnchor: moment,
      rightAnchor: previous.start,
    );

    final entryKey = period == ReportPeriod.week
        ? summaryWeekEntryKey(ended.start)
        : summaryMonthEntryKey(ended.start);
    final existing = await ledger.byKey(entryKey);
    if (existing != null && !existing.pendingHistory) return;

    final content = summaryContent(
      weekly: period == ReportPeriod.week,
      comparisonSentence: comparison.insight,
    );
    await ledger.upsert(
      NotificationLedgerEntry(
        entryKey: entryKey,
        kind: NotificationKind.periodSummary,
        title: content.title,
        body: content.body,
        scheduledFor: moment,
      ),
    );
    await presenter.schedule(
      OsNotification(
        id: notificationIdFor(entryKey),
        kind: NotificationKind.periodSummary,
        title: content.title,
        body: content.body,
        at: moment,
        payload: entryKey,
      ),
    );
  }

  /// Huỷ mốc đang chờ **của riêng một loại tổng kết** (theo tiền tố khoá) và
  /// **chặn** dòng sổ tương ứng — nếu chỉ huỷ lịch mà để dòng sổ còn nợ thì lần
  /// hoà giải sau sẽ ghi bù một bản ghi cho thông báo người dùng **đã tắt**.
  ///
  /// [onlyToday] ≠ null ⇒ **chỉ** chặn mốc rơi vào **đúng ngày lịch** đó: dùng
  /// cho Q3, vì ghé màn Báo cáo chỉ được phép huỷ mốc **có thể bắn trong lúc
  /// đang xem** — chặn cả mốc tuần sau thì chỉ cần mở tab Báo cáo một lần là mất
  /// luôn tổng kết tuần này (mốc cùng khoá đã bị chặn nên lần cuốn sau bỏ qua).
  Future<void> _stopSummaryType(String prefix, {DateTime? onlyToday}) async {
    for (final entry in await ledger.all()) {
      if (!entry.entryKey.startsWith(prefix) || !entry.pendingHistory) continue;
      if (onlyToday != null &&
          !_isSameDay(entry.scheduledFor, onlyToday)) {
        continue;
      }
      await presenter.cancel(notificationIdFor(entry.entryKey));
      await ledger.suppress(entry.entryKey);
    }
  }

  /// Vào một màn **liên quan** (Q3/FR-016): đang mở Báo cáo đúng lúc tới giờ
  /// tổng kết ⇒ huỷ mốc **hôm nay** + chặn, để không bắn cũng không ghi bản ghi.
  Future<void> onEnterRelatedScreen(String screen) async {
    try {
      if (screen != NotificationScreens.report) return;
      final now = _clock();
      await _stopSummaryType('summary:week:', onlyToday: now);
      await _stopSummaryType('summary:month:', onlyToday: now);
    } catch (_) {
      // Nuốt lỗi (FR-024).
    }
  }

  /// Rời màn liên quan: cuốn lịch lại. Mốc **đã trôi qua** trong lúc ở màn Báo
  /// cáo **không** được ghi bù (dòng sổ của nó đã bị chặn ⇒ không còn nợ bản
  /// ghi); mốc tuần/tháng **kế tiếp** được đăng ký lại (H4/FR-028).
  Future<void> onLeaveRelatedScreen() async {
    await reconcile();
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Loại suy ra từ **tiền tố** khoá sổ — dùng khi sổ thiếu dòng (VD app được
  /// cài lại trong lúc thông báo còn nằm trên khay hệ thống).
  static NotificationKind _kindOfEntryKey(String entryKey) {
    if (entryKey.startsWith('budget:')) return NotificationKind.budgetAlert;
    if (entryKey.startsWith('summary:')) return NotificationKind.periodSummary;
    return NotificationKind.dailyReminder;
  }
}
