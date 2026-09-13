# Mô hình dữ liệu: Trung tâm thông báo trong app (màn `03`)

**Mã PBI**: 30
**Liên kết spec**: [spec.md](./spec.md) · **Nghiên cứu**: [research.md](./research.md)
**Ngày tạo**: 2026-09-13

---

## 1. Thực thể 1 — Bản ghi thông báo (`AppNotification`)

Tầng nghiệp vụ thuần, `lib/core/notification/app_notification.dart`. Một bản ghi =
**một thông báo đã phát sinh** (doc §3.1 `NotificationLog`).

| # | Trường | Kiểu | Bắt buộc | Miền / ràng buộc |
|---|---|---|---|---|
| 1 | `id` | `int` | ✓ | Khoá dòng trong DB; `0` = chưa ghi (dùng khi dựng đối tượng để `append`) |
| 2 | `kind` | `NotificationKind` | ✓ | 5 giá trị §2 |
| 3 | `title` | `String` | ✓ | **Snapshot** do engine sinh lúc bắn — hiển thị **nguyên văn**, không dịch lại (FR-014) |
| 4 | `body` | `String` | ✓ | Dòng mô tả kèm số liệu, cùng luật snapshot; `''` hợp lệ (mục chỉ có tiêu đề) |
| 5 | `createdAt` | `DateTime` | ✓ | Thời điểm **phát sinh** (múi giờ thiết bị); khoá sắp xếp + tính nhóm thời gian |
| 6 | `readAt` | `DateTime?` | – | `null` = chưa đọc; có giá trị = đã đọc **tại thời điểm đó** |
| 7 | `relatedId` | `int?` | – | Id đối tượng nghiệp vụ liên quan (ngân sách / khoản định kỳ / mục tiêu); `null` cho loại không gắn đối tượng |

**Dẫn xuất**: `bool get isRead => readAt != null`.

**Hằng**: `const int kMaxNotifications = 200` — trần lưu lịch sử (spec Q3=A), **không**
phải cấu hình người dùng.

**Quan hệ**: mỗi bản ghi tham chiếu **tối đa một** đối tượng nghiệp vụ qua
`relatedId` (không FK). Bản ghi **không** sở hữu, **không** sửa, **không** cascade
theo đối tượng đó: xoá/ẩn ví/danh mục/ngân sách **không** làm mất hay đổi lịch sử
(spec §Quan hệ; luật 17).

## 2. Enum `NotificationKind` (5 loại, doc §2)

| Giá trị (`.name` lưu trong DB) | Nghĩa | Icon / sắc (UI, R10) | Đích khi chạm (FR-008) |
|---|---|---|---|
| `dailyReminder` | Nhắc nhập giao dịch hàng ngày | chuông · teal | màn Thêm giao dịch |
| `budgetAlert` | Cảnh báo ngân sách (sớm/vượt) | cảnh báo · **coral** | màn Chi tiết ngân sách (`relatedId`) |
| `recurringDue` | Nhắc giao dịch định kỳ sắp đến hạn | lịch · teal | **không có màn đích** → chỉ đánh dấu đã đọc |
| `goalReminder` | Nhắc mục tiêu tiết kiệm | bullseye · teal | **không có màn đích** → chỉ đánh dấu đã đọc |
| `periodSummary` | Tổng kết cuối tuần / cuối tháng | biểu đồ tròn · teal | tab Báo cáo của shell |

Lưu bằng `textEnum<NotificationKind>()` (drift ghi `.name`) — **quy ước repo**
(`TxnSource.manual/aiScan`, `ScanEngine`), khác snake_case trong doc §3.1.
Đích điều hướng **do `kind` quyết định**, không lưu riêng (R2).

## 3. Enum `NotificationGroup` (3 nhóm thời gian, FR-004 — R8)

| Giá trị | Điều kiện (`notificationGroup(at, now)`) | Nhãn |
|---|---|---|
| `today` | Cùng **ngày lịch** với `now` | `'HÔM NAY'` |
| `thisWeek` | 1…7 ngày trước `now` (không tính hôm nay) | `'TUẦN NÀY'` |
| `earlier` | Hơn 7 ngày trước `now` | `'TRƯỚC ĐÓ'` |

Tính theo **ngày lịch** (`DateTime(y, m, d).difference(...).inDays`), không theo
số giờ — cùng quy ước `relativeDayLabel`/`formatDayGroupHeader` (`date_label.dart`).
Múi giờ theo thiết bị. Chỉ vẽ nhóm **có mục** (FR-011).

## 4. Bảng drift `Notifications` (schema **v9**, R1)

`lib/data/db/app_database.dart` — thêm vào `@DriftDatabase(tables: [...])`.

| Cột drift | Kiểu | Ghi chú |
|---|---|---|
| `id` | `integer().autoIncrement()` | khoá chính |
| `kind` | `textEnum<NotificationKind>()` | §2 |
| `title` | `text()` | snapshot |
| `body` | `text().withDefault(const Constant(''))` | snapshot, `''` hợp lệ |
| `created_at` | `dateTime()` | thời điểm phát sinh |
| `read_at` | `dateTime().nullable()` | `NULL` = chưa đọc |
| `related_id` | `integer().nullable()` | không FK (nếp `transactions.category_id`) |

`@DataClassName('NotificationsRow')`. **Không** index riêng (bảng tối đa 200 dòng,
truy vấn luôn quét cả bảng — index là thừa; thêm khi bảng lớn hơn nhiều).

**Migration** (`schemaVersion` 8 → 9):

```dart
// from < 9 (PBI 30): bảng lịch sử thông báo — thuần tạo, KHÔNG seed (spec:
// không dựng cơ chế seed dữ liệu mẫu). Không đụng bảng nào khác.
if (from < 9) {
  await m.createTable(notifications);
}
```

`onCreate` dùng `m.createAll()` ⇒ DB mới có bảng luôn, không cần nhánh riêng.
Sinh lại `app_database.g.dart`: `dart run build_runner build --delete-conflicting-outputs`.
Bảng **không** đụng 6 bảng cũ (wallets / categories / transactions / appSettings /
budgets / scanSessions) ⇒ không rủi ro dữ liệu người dùng.

## 5. Seam `NotificationHistoryStore` (R4)

`lib/core/notification/notification_history_store.dart`.

| Phương thức | Hợp đồng |
|---|---|
| `Future<List<AppNotification>> loadRecent()` | Toàn bộ lịch sử, **mới nhất trước** (`created_at DESC, id DESC`); bảng rỗng → `[]` (không ném) |
| `Future<void> append(AppNotification n)` | Chèn 1 dòng (`id` của `n` **bị bỏ qua**, DB tự sinh) rồi **dọn vượt trần**: xoá mọi dòng ngoài top-`kMaxNotifications` theo `(created_at DESC, id DESC)` |
| `Future<void> markRead(int id, DateTime readAt)` | `UPDATE … WHERE id = ? AND read_at IS NULL` — chỉ dòng **đang chưa đọc**; gọi lại **không** đổi `read_at` (một chiều, FR-009); id không tồn tại → không lỗi, không tạo dòng |

Không có `unreadCount` (đếm bằng Dart ở chỗ gọi), `markAllRead`, `delete` (R4).
Impl thật: `DriftNotificationHistoryStore(AppDatabase())` trong
`lib/data/notification_history_store_drift.dart`; DI:
`ensureNotificationHistoryStore()` (`lib/data/notification_history_deps.dart`,
GetX singleton — test `Get.put` fake trước ⇒ không mở drift).
**Không** sửa `NotificationStore`/`DriftNotificationStore`/`FakeNotificationStore`
(PBI 28) — hai mối quan tâm tách rời (R4).

## 6. Luật bất biến

| # | Luật | Nguồn |
|---|---|---|
| 1 | `kMaxNotifications == 200`, hằng số — không đọc từ cấu hình | FR-010, Q3=A |
| 2 | Sau **mọi** lần `append`, số dòng trong bảng `≤ 200` | FR-010 |
| 3 | Khi vượt trần, dòng bị xoá là **cũ nhất theo `created_at`** (khoá phụ `id` để tất định) | FR-010, SC-014 |
| 4 | Trần áp dụng **bất kể đã đọc hay chưa** — không giữ ngoại lệ mục chưa đọc | spec §Giả định |
| 5 | `loadRecent()` trả **mới nhất trước**; hai bản ghi cùng `created_at` xếp theo `id` giảm dần | FR-004 |
| 6 | `readAt` chỉ chuyển `null → giá trị`, **không** bao giờ ngược lại và **không** bị ghi đè | FR-009 |
| 7 | `markRead` trên dòng đã đọc / id không tồn tại → no-op, không ném, không tạo dòng | FR-009 |
| 8 | `isRead == (readAt != null)` — không có cờ thứ hai | R13 |
| 9 | Trạng thái đọc gắn với **bản ghi**, không với `kind`: 2 bản ghi cùng loại đọc độc lập | spec §Giả định |
| 10 | Bản ghi **không** xoá/sửa được từ UI: không nút đọc-tất-cả, không xoá mục, không xoá lịch sử | FR-019, Q2=A |
| 11 | Thao tác đọc duy nhất: **chạm vào mục** | FR-019 |
| 12 | Chạm mục **luôn** đánh dấu đã đọc nếu đang chưa đọc, **kể cả** khi không điều hướng được | FR-007, R11 |
| 13 | Chạm mục **không** đổi bất kỳ bản ghi nào khác (không đụng `createdAt`/`title`/`body`/`relatedId` dòng khác) | FR-007, SC-006 |
| 14 | Màn **chỉ** đọc + cập nhật `read_at` của bảng `notifications`; **0** ghi vào `wallets`/`transactions`/`categories`/`budgets`/`appSettings` | FR-012, SC-008 |
| 15 | Màn **không** xin quyền thông báo, không bắn thông báo, không đọc cấu hình `notificationPrefs` | FR-013, SC-009 |
| 16 | `title`/`body` là **snapshot**: hiển thị nguyên văn, không `.tr`, không tính lại số liệu khi mở màn | FR-014 |
| 17 | Xoá/ẩn đối tượng nghiệp vụ (`relatedId` trỏ tới) **không** làm mất/đổi bản ghi; chạm chỉ đánh dấu đã đọc | spec §Quan hệ |
| 18 | Nhóm thời gian: `today` = cùng ngày lịch, `thisWeek` = 1…7 ngày, `earlier` = >7 ngày; nhóm **rỗng không vẽ** | FR-004, FR-011, R8 |
| 19 | Nhãn thời gian mục: cùng ngày → `HH:mm`; 1…7 ngày → tên thứ đầy đủ; >7 ngày → `dd/MM`; **không** đổi theo ngôn ngữ | spec §Giả định, FR-014 |
| 20 | Đích điều hướng theo bảng §2; `relatedId == null` ở `budgetAlert` ⇒ **không** điều hướng | FR-008, R11 |
| 21 | Chuông màn Tổng quan: chấm hiện ⟺ **có ≥1** mục chưa đọc; lịch sử rỗng ⇒ **không** chấm | FR-001 |
| 22 | Chuông **luôn** bấm được (kể cả lịch sử rỗng / lỗi đọc) | FR-001 |
| 23 | Chấm cập nhật lại **ngay khi quay về** màn Tổng quan từ Trung tâm | FR-001, SC-013 |
| 24 | Tab "Chưa đọc" hiển thị **đúng** tập `readAt == null`, giữ nguyên cách nhóm; mục đã đọc biến mất khỏi tab này | FR-003, SC-005 |
| 25 | Trạng thái rỗng: lịch sử rỗng ⇒ câu **chung**; lịch sử khác rỗng mà tab "Chưa đọc" rỗng ⇒ câu **riêng** | FR-011, SC-007 |
| 26 | Mọi nhãn tĩnh có bản dịch EN; mọi màu đi qua token (`AppColors`/`SoraColors`) — không hex cứng trong widget | FR-014, FR-015 |

## 7. Vòng đời giá trị

```
[engine PBI sau] --append--> dòng mới: readAt = null
                                  │
                        (chạm mục ở màn 03)
                                  ▼
                        readAt = <thời điểm chạm>   (một chiều, luật 6)
                                  │
                        (vượt trần 200, theo createdAt)
                                  ▼
                        dòng cũ nhất bị xoá (luật 3) — dù đã đọc hay chưa
```

Đợt này **chưa có nguồn ghi trong app** (Q1=A: engine là PBI sau) ⇒ trên máy thật
bảng luôn rỗng, màn ở trạng thái rỗng. Mọi luật trên vẫn **kiểm được**: luật 1–9
bằng DAO drift in-memory (host này chạy được sqlite native); luật 10–26 bằng widget
test với store giả + test hàm thuần.
