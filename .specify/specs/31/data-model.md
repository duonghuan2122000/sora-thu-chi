# Mô hình dữ liệu: Thông báo đẩy — engine bắn thông báo & nhắc nhở

**Mã PBI**: 31
**Liên kết spec**: [spec.md](./spec.md) · **Nghiên cứu**: [research.md](./research.md)
**Ngày tạo**: 2026-09-13

> PBI này **chỉ thêm 1 bảng** và **chỉ ghi** vào 2 bảng của chính nó + bảng lịch
> sử của PBI 30. **0** thay đổi lên 6 bảng nghiệp vụ (FR-023/SC-013).

---

## 1. Thực thể 1 — Dòng sổ thông báo (`NotificationLedgerEntry`, **MỚI**)

Tầng nghiệp vụ thuần, `lib/core/notification/notification_ledger.dart`. Một dòng =
**một mốc thông báo đã được lên lịch, đã bắn, hoặc đã bị chặn** — bộ nhớ duy nhất
để (a) chống bắn trùng, (b) biết mốc nào còn nợ một bản ghi Trung tâm, (c) tra
ngược `history_id` khi người dùng chạm thông báo (R6/R7/R8).

| # | Trường | Kiểu | Bắt buộc | Miền / ràng buộc |
|---|---|---|---|---|
| 1 | `entryKey` | `String` | ✓ | **Khoá nghiệp vụ duy nhất** (R7): `daily:<yyyy-MM-dd>` · `summary:week:<yyyy-MM-dd>` · `summary:month:<yyyy-MM>` · `budget:early\|over:<budgetId>:<đầu kỳ>` |
| 2 | `kind` | `NotificationKind` | ✓ | Dùng lại **enum của PBI 30** (5 giá trị) — đợt này chỉ sinh 3 loại đầu + tổng kết |
| 3 | `relatedId` | `int?` | – | `budgetId` cho cảnh báo ngân sách; `null` cho nhắc hàng ngày & tổng kết |
| 4 | `title` | `String` | ✓ | **Snapshot** câu chữ sinh lúc lên lịch/bắn (ngôn ngữ lúc đó) |
| 5 | `body` | `String` | ✓ | Dòng mô tả kèm số liệu, cùng luật snapshot; `''` hợp lệ |
| 6 | `scheduledFor` | `DateTime` | ✓ | Mốc dự kiến bắn (giờ địa phương). **Cũng là `created_at`** của bản ghi lịch sử tương ứng ⇒ nhãn thời gian & nhóm ngày đúng như lúc bắn |
| 7 | `suppressed` | `bool` | ✓ | `true` = bị chặn (Q3 đang ở màn liên quan R9, hoặc cờ "chỉ nhắc nếu chưa ghi" R5) ⇒ **không** bắn, **không** ghi bản ghi |
| 8 | `historyWrittenAt` | `DateTime?` | – | `NULL` = chưa ghi bản ghi Trung tâm (còn nợ); có giá trị = đã ghi lúc đó |
| 9 | `historyId` | `int?` | – | `notifications.id` của bản ghi tương ứng — dùng để `markRead` khi chạm thông báo (R8). Không FK (đồng bộ nếp PBI 30) |

**Dẫn xuất**: `bool get pendingHistory => !suppressed && historyWrittenAt == null`.

**Bất biến**:
1. `entryKey` duy nhất (khoá chính) — lên lịch lại **không** sinh dòng thứ hai.
2. Dòng `kind ∈ {dailyReminder, budgetAlert, periodSummary}` — 2 loại chưa có
   module **không bao giờ** xuất hiện trong sổ (Q1=A/FR-002).
3. `suppressed = true` ⇒ `historyWrittenAt` **luôn** `null` (bị chặn thì không bao
   giờ có bản ghi — FR-003/FR-016).
4. `historyWrittenAt != null` ⇒ `historyId != null`.
5. Chống trùng **gắn với kỳ**, không vĩnh viễn: khoá mang kỳ ⇒ kỳ mới tự do báo
   lại (spec §Trường hợp biên "cùng ngưỡng ở kỳ mới").
6. Dòng sổ **không** hồi tố: sửa/xoá giao dịch hay ngân sách sau đó **không** đổi
   `title`/`body`/`suppressed` của dòng đã có (spec §Giả định "ảnh chụp").

**Vòng đời `suppressed` (chỉ 2 đường vào)**:
| Nguồn | Khi nào | Hệ quả |
|---|---|---|
| R5 — cờ "chỉ nhắc nếu chưa ghi" | Lưu **bất kỳ** giao dịch nào trong ngày `D` ⇒ đặt `suppressed = true` cho `daily:<D>` **chưa bắn** | Huỷ lịch hệ điều hành của mốc đó (AC#2) |
| R9 — Q3 màn liên quan | (a) Cảnh báo ngân sách khi đang mở **đúng** `BudgetDetailScreen` của danh mục đó → dòng **không** được tạo; (b) Tổng kết khi đang mở màn **Báo cáo** → dòng đang chờ bị `suppressed = true` | (a) 0 thông báo, 0 bản ghi; (b) huỷ mốc đang chờ, rời màn thì cuốn lịch lại |

**Dọn sổ**: khi hoà giải, xoá dòng `scheduledFor < now − 90 ngày` **đã xử lý xong**
(`suppressed = true` hoặc `historyWrittenAt != null`). Biên 90 ngày > mọi kỳ ngân
sách (tháng/năm) ⇒ **không** mất khoá chống trùng của kỳ đang chạy.

## 2. Thực thể 2 — Lịch đã đăng ký với hệ điều hành (`OsSchedule`, **KHÔNG lưu DB**)

Là mặt **hệ điều hành** của cùng một mốc. Không có bảng riêng: mỗi dòng sổ ứng với
**tối đa một** lịch, định danh bằng **id số nguyên** = FNV-1a 32-bit của `entryKey`
(R7). Bảng dưới là hợp đồng của lớp `NotificationPresenter`:

| Việc | API (đã bọc qua seam) | Ghi chú |
|---|---|---|
| Lên lịch một mốc | `schedule(id, title, body, at, payload = entryKey, kind)` | `zonedSchedule` **một-lần**, `AndroidScheduleMode.exactAllowWhileIdle` (lùi về `inexactAllowWhileIdle` khi `canScheduleExactNotifications() == false` — R10) |
| Bắn ngay | `show(id, title, body, payload, kind)` | Chỉ dùng cho **cảnh báo ngân sách** (R4) |
| Huỷ một mốc | `cancel(id)` | Huỷ mốc bị chặn (R5/R9) |
| Huỷ cả loạt | `cancelKind(kind)` | Khi **tắt** một công tắc hoặc khi cuốn lại lịch (R2/R3) |
| Trạng thái quyền | `areEnabled()`, `requestPermission()`, `openSettings()` | R10/FR-032 |
| Kênh | dựng 1 lần lúc boot: `sora_daily`/`sora_budget`/`sora_summary` | R11/FR-025 |

**Bất biến**:
7. Một `entryKey` ⇒ **một** id ⇒ tối đa **một** thông báo nằm trên màn hình khoá
   cho khoá đó (FR-026 — thay thế, không xếp chồng).
8. Thông báo hệ điều hành **có thể không bao giờ hiện** (quyền bị chặn, hệ điều
   hành giết lịch) mà dòng sổ **vẫn** sinh bản ghi lịch sử — **cố ý** (FR-004/AC#14:
   "xem lại khi bỏ lỡ"). Không có cách phân biệt hai ca này khi không chạy nền (R0).

## 3. Bảng drift — `NotificationLedger` (**schema v9 → v10**)

Thêm vào `lib/data/db/app_database.dart`; migration
`if (from < 10) await m.createTable(notificationLedger);` — **thuần tạo bảng,
KHÔNG seed** (bám nếp v6/v9). Không `addColumn` bảng nào khác.

| Cột drift | Kiểu | Ghi chú |
|---|---|---|
| `entry_key` | `text()` | **khoá chính** (không `autoIncrement`) |
| `kind` | `textEnum<NotificationKind>()` | lưu `.name` — quy ước repo |
| `related_id` | `integer().nullable()` | không FK |
| `title` | `text()` | snapshot |
| `body` | `text().withDefault(const Constant(''))` | snapshot |
| `scheduled_for` | `dateTime()` | mốc bắn |
| `suppressed` | `boolean().withDefault(const Constant(false))` | |
| `history_written_at` | `dateTime().nullable()` | |
| `history_id` | `integer().nullable()` | |

`@DataClassName('NotificationLedgerRow')` · `primaryKey => {entryKey}` (khuôn bảng
`AppSettings`). **Không** index thêm (`entry_key` là PK; các truy vấn đều là quét
toàn bảng trên vài chục dòng — R6 dọn sổ nên bảng luôn nhỏ).

## 4. Thực thể 3 — Cấu hình nhắc nhở (**đã có, PBI 28/29 — chỉ ĐỌC**)

`NotificationPrefs` (17 trường, row JSON `notificationPrefs` trong `AppSettings`)
là **nguồn tham số duy nhất** của engine (FR-030): `dailyEnabled/dailyHour/dailyMinute/
dailyWeekdays/dailyOnlyIfNoTxnToday` · `budgetEnabled/budgetEarlyPercent/budgetOverPercent` ·
`weeklyEnabled/weeklyHour/weeklyMinute` · `monthlyEnabled/monthlyHour/monthlyMinute`.
Engine **KHÔNG** ghi vào đây (màn `01`/`02` vẫn là nơi duy nhất chỉnh — FR-030).

Hai trường **không** dùng đợt này: `recurringEnabled/recurringDaysBefore`,
`goalEnabled` (2 loại chưa có module — FR-002).

Thêm đúng **1 row `AppSettings`** mới (không migration): `notificationPermissionAsked`
= `'true'` sau lần đầu hiện soft-ask ở màn `01` (R10/FR-017).

## 5. Thực thể 4 — Cấu hình ngân sách & dữ liệu để tính (**đã có, chỉ ĐỌC**)

| Nguồn | Dùng cho |
|---|---|
| `budgets()` (PBI 20/21) | ngân sách **chưa lưu trữ** (`isArchived == false`), kỳ = `budgetPeriodRange(period, ngày giao dịch)`, danh mục = `budgetScopeCategoryIds` (cha + con trực tiếp) |
| `allTransactions()` (PBI 8) | "hôm nay đã ghi giao dịch chưa" (FR-011) + số liệu tổng kết |
| `budgetSpent()` (PBI 20, `budget_view.dart`) | `%` đã dùng — **tái dùng nguyên hàm**, không viết lại phép lọc Chi/trong kỳ/đúng danh mục (FR-014) |
| `reportComparison()` / câu insight (PBI 22/26, `report_view.dart`) | câu so sánh kỳ vừa kết thúc ↔ kỳ liền trước (FR-009/AC#18–20 — **miễn phí** luật "kỳ trước rỗng ⇒ bỏ câu so sánh, không chia 0") |

## 6. Seam mới (hợp đồng nội bộ)

```dart
/// engine ⟷ bảng sổ (impl thật: DriftNotificationLedger; test: fake)
abstract class NotificationLedger {
  Future<NotificationLedgerEntry?> byKey(String entryKey);
  Future<List<NotificationLedgerEntry>> dueBefore(DateTime now);   // còn nợ bản ghi
  Future<List<NotificationLedgerEntry>> all();
  Future<void> upsert(NotificationLedgerEntry entry);
  Future<void> markHistoryWritten(String entryKey, int historyId, DateTime at);
  Future<void> suppress(String entryKey);
  Future<void> pruneBefore(DateTime cutoff);
}

/// engine ⟷ hệ điều hành (impl thật: PluginNotificationPresenter; test: fake)
abstract class NotificationPresenter {
  Future<void> init();                       // channel + timezone + tap callback
  Future<bool> areEnabled();
  Future<bool> requestPermission();
  Future<void> openSettings();
  Future<void> schedule(OsNotification n);   // một-lần, id ổn định
  Future<void> show(OsNotification n);       // bắn ngay
  Future<void> cancel(int id);
  Future<void> cancelKind(NotificationKind kind);
}
```

`NotificationHistoryStore` (PBI 30) **không đổi** — engine là **nguồn ghi thứ hai**
qua đúng `append`/`markRead` đã có (bất biến trần 200 nằm sẵn ở tầng ghi).

## 7. Bất biến xuyên thực thể (đối chiếu FR/SC)

| # | Luật | FR/SC |
|---|---|---|
| 9 | Mỗi lần một loại **được kích hoạt**: **đúng 1** thông báo hệ điều hành + **đúng 1** bản ghi chưa đọc — **trừ** khi `suppressed` (khi đó **0** và **0**) | FR-003, FR-016, SC-007 |
| 10 | Quyền bị chặn ⇒ **0** thông báo hiện, **100%** bản ghi vẫn được ghi, **0** lỗi cho người dùng | FR-004, SC-009 |
| 11 | Tối đa **1** lần/ngày (nhắc hàng ngày), **1** lần/ngưỡng/ngân sách/kỳ (cảnh báo), **1**/tuần và **1**/tháng (tổng kết) — bền qua đóng/mở app & khởi động lại | FR-010, FR-013, FR-015, SC-005 |
| 12 | Cảnh báo ngân sách **chỉ** từ giao dịch **Chi**, **đúng danh mục**, **trong kỳ**; chuyển khoản **không** tính là chi (nhưng **có** tính là "đã ghi hôm nay" cho FR-011) | FR-012, FR-014 |
| 13 | Engine **chỉ đọc** dữ liệu nghiệp vụ; **chỉ ghi** sổ + lịch sử + `read_at` | FR-023, SC-013 |
| 14 | Lỗi bất kỳ trong engine **không** được làm hỏng/ làm chậm luồng lưu giao dịch | FR-024, SC-012 |
| 15 | **Không** bắn bù mốc đã trôi qua (khởi động lại, cấp lại quyền, vừa bật công tắc, DB cũ nâng cấp) | FR-028, AC#24/#29 |
| 16 | Trần **200** bản ghi lịch sử giữ nguyên khi engine ghi liên tục | FR-029, AC#25 |
| 17 | Nội dung sinh theo ngôn ngữ **lúc bắn** và lưu **nguyên văn** (không dịch lại) | FR-027, SC-014 |
| 18 | **0** dữ liệu ra khỏi thiết bị; engine chạy đủ khi không có mạng | FR-031, SC-017 |
| 19 | Tham số **luôn** đọc từ cấu hình đang lưu ở **mỗi lần** tính; engine **không** thêm màn chỉnh tham số | FR-030 |
