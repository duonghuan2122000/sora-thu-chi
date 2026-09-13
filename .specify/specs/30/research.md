# Nghiên cứu kỹ thuật: Trung tâm thông báo trong app (màn `03`)

**Mã PBI**: 30
**Liên kết spec**: [spec.md](./spec.md)
**Ngày tạo**: 2026-09-13

> Spec đã "Đã làm rõ" (Q1=A, Q2=A, Q3=A — chốt 2026-09-13) ⇒ **không còn
> `NEEDS CLARIFICATION`**. Các mục dưới đây là quyết định triển khai còn lại.

---

## R1 — Nơi lưu lịch sử: **bảng drift mới** (schema v9), không phải row JSON

- **Quyết định**: thêm **1 bảng drift** `Notifications` vào `app_database.dart`
  ⇒ `schemaVersion` **8 → 9**, migration `if (from < 9) await m.createTable(...)`
  (thuần tạo bảng, **không seed**), chạy `build_runner` sinh lại `app_database.g.dart`.
- **Lý do**: lịch sử thông báo là **log có trần + trạng thái ghi trên từng dòng**
  (FR-009/FR-010) — đúng hình dạng bảng, không phải blob:
  - dọn mục cũ nhất khi vượt 200 (FR-010/SC-014) = **1 câu SQL** (`DELETE` các id
    ngoài top-200 theo `created_at`), không phải đọc–sửa–ghi lại cả khối;
  - đọc 1 dòng đổi `read_at` (FR-009) không ghi đè dòng khác;
  - doc §3.1 đã định nghĩa `NotificationLog` là bảng; PBI 28 đã **hoãn có lý do**
    đúng bảng này ("chỉ có nghĩa khi có màn đọc nó") — PBI 30 là màn đó;
  - engine (PBI sau) chỉ cần `INSERT` một dòng khi bắn thông báo.
  Repo đã đi qua 5 lần nâng schema (v4→v8) với migration + test — rủi ro thấp,
  chi phí còn lại là **cơ học** (sinh code + 4 dòng test đổi số version).
- **Phương án khác đã xem xét**: (a) **1 row JSON** `notificationLog` trong
  `AppSettings` (khuôn PBI 28) — không migration/không `build_runner`, nhưng biến
  mọi thao tác đọc 1 mục thành đọc–giải mã–sửa–mã hoá–ghi lại cả 200 bản ghi, và
  trần 200 phải tự viết bằng Dart (đúng thứ SQL làm sẵn); (b) bảng + **seed dữ
  liệu mẫu** để QA thấy màn có dữ liệu — spec **cấm** ("không dựng cơ chế seed dữ
  liệu mẫu trong app", mục Giả định); (c) `shared_preferences`/file JSON riêng —
  package mới hoặc I/O thứ hai, lệch quy ước "mọi dữ liệu local nằm trong drift".

## R2 — Cấu trúc bản ghi: cột phẳng, không `payload` JSON

- **Quyết định**: 7 cột — `id` (autoIncrement), `kind` (`textEnum`), `title`,
  `body`, `created_at` (DateTime), `read_at` (DateTime **nullable**),
  `related_id` (int **nullable**).
- **Lý do**: doc §3.1 gộp `payload` + `relatedEntityId` làm hai thứ, nhưng đích
  điều hướng trong đợt này **do `kind` quyết định** (FR-008: mỗi loại một màn
  đích cố định) ⇒ chỉ còn **một id** cần mang theo (`relatedId` = `budgetId` cho
  cảnh báo ngân sách, `recurringTxnId`/`goalId` cho 2 loại chưa có màn đích, null
  cho 2 loại còn lại). Không FK (bám nếp `transactions.category_id` /
  `scan_sessions.transaction_id`): xoá đối tượng nghiệp vụ **không** được làm mất
  hay cascade lịch sử (spec §Quan hệ).
  `kind` lưu bằng `.name` của enum (`textEnum<NotificationKind>()`) — **đúng quy
  ước repo** (`TxnSource.manual/aiScan`, `ScanEngine`), khác snake_case của doc.
- **Phương án khác đã xem xét**: cột `payload` text chứa JSON `{"type":…,"id":…}`
  (thừa: `kind` + `relatedId` đã đủ, JSON là tầng gián tiếp phải test round-trip);
  `related_id` text đa hình (`budget:3`) (phải parse chuỗi ở mọi chỗ đọc); FK
  drift (cascade/xoá theo — trái luật "không mất lịch sử").

## R3 — Trần 200 cưỡng chế ở **tầng ghi**, bằng SQL

- **Quyết định**: `append()` chèn dòng mới rồi xoá mọi dòng **ngoài top-200** theo
  `(created_at DESC, id DESC)`; `kMaxNotifications = 200` là hằng trong
  `app_notification.dart` (không phải cấu hình người dùng — spec Q3=A).
- **Lý do**: FR-010 đòi "số mục lưu **không bao giờ** vượt 200" — cưỡng chế ngay
  tại chỗ ghi thì **mọi** đường ghi (engine tương lai, test, sửa tay) đều đúng,
  không phụ thuộc màn nào đang mở. Thêm `id DESC` làm khoá phụ để thứ tự **tất
  định** khi nhiều bản ghi cùng `created_at` (test SC-014 khỏi flaky).
- **Phương án khác đã xem xét**: dọn khi **đọc** màn (màn không mở ⇒ DB phình vô
  hạn, trái FR-010); job dọn định kỳ lúc app khởi động (thêm vòng đời + chỗ chạy
  cho một việc 1 câu SQL); `LIMIT` khi đọc mà không xoá (DB vẫn vượt trần — spec
  đo "số mục lưu").

## R4 — Seam mới `NotificationHistoryStore`, **không** nới `NotificationStore`

- **Quyết định**: seam riêng `NotificationHistoryStore` (3 phương thức) trong
  `lib/core/notification/notification_history_store.dart`; `NotificationStore`
  (PBI 28) **giữ nguyên 2 phương thức**.
- **Lý do**: hai mối quan tâm khác nhau (cấu hình vs lịch sử) và hai hình dạng
  khác nhau (`NotificationPrefs` ↔ `List<AppNotification>`). Nới interface cũ buộc
  `DriftNotificationStore` + `FakeNotificationStore` (PBI 28) phải cài thêm 3
  phương thức ⇒ **chạm** file/fake/test đã QA của PBI 28 mà không được lợi gì.
- **3 phương thức**:
  ```dart
  Future<List<AppNotification>> loadRecent();          // mới nhất trước, ≤ 200
  Future<void> append(AppNotification notification);   // chèn + dọn vượt trần (R3)
  Future<void> markRead(int id, DateTime readAt);      // chỉ dòng đang chưa đọc
  ```
- **Phương án khác đã xem xét**: thêm `unreadCount()` (đếm chưa đọc) — màn Tổng
  quan chỉ cần **một con số** mà vẫn phải tải cả danh sách; 200 dòng là không
  đáng kể, và bỏ được 1 phương thức khỏi seam/fake ⇒ đếm bằng Dart ở chỗ gọi;
  `markAllRead()` (spec **cấm** — FR-019, Q2=A); `delete(id)` (spec cấm xoá).

## R5 — Chấm đỏ trên chuông: state cục bộ ở màn Tổng quan, **không** GetX controller

- **Quyết định**: `DashboardScreen` thành `StatefulWidget`, giữ `_unread` (int);
  `initState` → `loadRecent()` đếm chưa đọc; khi mở Trung tâm thì
  `await Navigator.push(...)` rồi **đếm lại** (đọc chỉ xảy ra trong màn Trung tâm).
- **Lý do**: FR-001/SC-013 chỉ đòi chấm phản ánh đúng trạng thái **khi người dùng
  nhìn thấy nó** — mà màn Tổng quan là màn duy nhất vẽ chấm, và trạng thái chỉ đổi
  được ở màn Trung tâm (mở từ chính nó). `await push` + đếm lại là **đúng và đủ**,
  0 file điều hướng mới, 0 vòng đời phải quản. Tiền lệ: `ReportScreen._openBudget`
  cũng `await push` rồi làm mới.
- **Phương án khác đã xem xét**: `NotificationCenterController` (GetX `RxInt`) —
  reactive thật nhưng thêm 1 file + DI + vòng đời cho **một** chỗ đọc, và vẫn phải
  bơm được fake khi test; `Stream`/`watch()` của drift (stream suốt vòng đời app
  cho 1 con số, phải quản subscription); `setState` sau khi `pop` bằng `.then`
  (khó hơn `await` mà không lợi gì).

## R6 — Điểm vào: chuông ở `ScreenHeader.trailing` màn Tổng quan + bơm `onSelectTab`

- **Quyết định**: `ScreenHeader(title: 'Tổng quan'.tr, trailing: _BellButton(...))`
  — nút tròn 48 px (khuôn `_CompareButton`/`_ExportButton` màn Báo cáo). Điều
  hướng đích của loại "tổng kết kỳ" là **tab Báo cáo** ⇒ `AppShell` bơm
  `onSelectTab: _onTabSelected` xuống `DashboardScreen` → `NotificationCenterScreen`
  (đúng khuôn đang bơm cho `ReportScreen`, PBI 20/22).
- **Lý do**: `ScreenHeader.trailing` sinh ra đúng cho ô nút vùng tiêu đề (PBI 26/27
  đã dùng cho 2 icon màn Báo cáo); mockup `03` không vẽ màn Tổng quan nên vị trí
  lấy theo tiền lệ (spec §Giả định cũng chốt vậy). Chuông **luôn** bấm được (không
  disable khi rỗng — FR-001).
- **Phương án khác đã xem xét**: FAB riêng cho chuông (trái bố cục shell: FAB giữa
  là "thêm giao dịch"); chuông ở tab Cài đặt (trái mockup/doc §5); mở tab Báo cáo
  bằng cách đẩy `ReportScreen` mới dạng màn con (nhân đôi màn + state, thay vì đổi
  tab — `popUntil(isFirst)` + `onSelectTab(2)` là khuôn đã có ở PBI 20/21).

## R7 — 2 tab: hàng tự vẽ + gạch chân 2 px teal, **không** `TabBar`/`TabController`

- **Quyết định**: `Row` 2 `GestureDetector(behavior: opaque)`; tab đang chọn: chữ
  `AppColors.teal` w600 + `Container` cao 2 px màu `AppColors.teal` (bề rộng theo
  nội dung — mockup: `rect` 42×2 ngay dưới "Tất cả"); tab kia `colors.tabInactive`;
  dưới cùng là đường kẻ `colors.listDivider` (mockup có `line` `#EFEFEF` sát dưới).
- **Lý do**: `TabBar` kéo theo `TabController`/`DefaultTabController` + phải đấu
  theme (`indicatorColor`, `labelColor`, `indicatorSize`) để ra đúng mockup, trong
  khi lọc chỉ là **một** `setState` trên danh sách đã có trong bộ nhớ (FR-003:
  "lọc lại danh sách ngay, không tải lại màn"). Repo cũng chưa dùng `TabBar` ở màn
  nào (chỉ `category_sort_screen` dùng cho việc khác).
- **Phương án khác đã xem xét**: `DefaultTabController` + `TabBar` + `TabBarView`
  (thêm animation chuyển tab mà mockup không có, và `TabBarView` giữ 2 danh sách
  sống song song — thừa cho 2 tập dữ liệu cùng nguồn); segmented control pill như
  màn Báo cáo (mockup vẽ **gạch chân**, không phải pill — lệch SC-001).

## R8 — Nhóm thời gian: HÔM NAY / TUẦN NÀY / TRƯỚC ĐÓ, "tuần này" = **7 ngày gần nhất**

- **Quyết định**: hàm thuần `notificationGroup(DateTime at, DateTime now)` →
  `today` (cùng ngày lịch), `thisWeek` (1…7 ngày trước), `earlier` (>7 ngày);
  nhãn `'HÔM NAY'`/`'TUẦN NÀY'`/`'TRƯỚC ĐÓ'`; **chỉ vẽ nhóm có mục** (FR-011).
- **Lý do**: spec §Giả định (mục "Nhóm thời gian") định nghĩa **chính xác** như
  vậy ("TUẦN NÀY (7 ngày gần nhất, không tính hôm nay)"), và FR-004 chỉ đòi "tối
  thiểu có HÔM NAY và TUẦN NÀY + có nhóm cho mục cũ hơn". **Lệch có chủ ý** so với
  câu "mốc 'tuần này' bắt đầu Thứ Hai" cùng mục Giả định (mốc đó nói về **múi
  giờ/tuần ISO** đồng bộ module Báo cáo): nếu cắt theo tuần lịch thì mục **hôm qua**
  rơi vào "TRƯỚC ĐÓ" khi hôm nay là Thứ Hai — nghịch nghĩa chữ "tuần này" trên
  màn lịch sử. Ghi rõ ở [quickstart.md](./quickstart.md) §4 để QA không tính là lỗi.
- **Phương án khác đã xem xét**: tuần lịch bắt đầu Thứ Hai (`budget_view`/
  `report_view` có sẵn hàm tuần) — bám chữ "tuần" theo nghĩa lịch, nhưng sinh nhóm
  "TRƯỚC ĐÓ" chứa mục 1 ngày tuổi; nhóm thứ ba đặt tên "CŨ HƠN" (spec đã chốt chữ
  "TRƯỚC ĐÓ" ở mục Giả định); gộp 7 ngày gần nhất **kể cả** hôm nay (mất nhóm
  HÔM NAY — FR-004 đòi có).

## R9 — Nhãn thời gian của mục: `HH:mm` / tên thứ đầy đủ / `dd/MM`

- **Quyết định**: `notificationTimeLabel(DateTime at, DateTime now)`:
  cùng ngày → `formatClock(at.hour, at.minute)` (tái dùng `date_label.dart`);
  1…7 ngày → **tên thứ đầy đủ** (`weekdayName(weekday)` mới, 7 khoá dịch:
  `'Thứ Hai'`…`'Chủ Nhật'`); cũ hơn → `dd/MM`.
- **Lý do**: spec §Giả định chốt **giờ tuyệt đối đồng nhất** cho mục trong ngày
  (lệch mockup "2 giờ trước" — có chủ ý, dễ đọc/dễ test); mockup vẽ nhãn tuần này
  là **"Thứ 3"**, **"Chủ nhật"** (tên thứ, không viết tắt) ⇒ `dayLabel` (`T3`/`CN`)
  không khớp mockup ở đây. `weekdayName` ở `date_label.dart` cạnh `dayLabel`, viết
  literal trước `.tr` (ràng buộc test dịch — R14).
- **Phương án khác đã xem xét**: dùng lại `dayLabel` (`T3`/`CN`) — 0 khoá mới
  nhưng lệch mockup rõ rệt trên màn lịch sử; `relativeDayLabel` (cho `'Hôm qua'`
  + `dd/MM`) — không có tên thứ, và lệch chữ với nhãn nhóm; "x giờ trước" tương
  đối (mockup) — phải tính lại theo thời điểm vẽ, khó test và lệch chốt ở spec.

## R10 — Icon & màu theo loại: map 5 loại, coral **chỉ** ở cảnh báo ngân sách

- **Quyết định**: hàm private trong màn (như PBI 28 R8):

  | Loại | Icon | Vòng nền | Glyph |
  |---|---|---|---|
  | `dailyReminder` | `Icons.notifications_none` | `colors.tealLightBg` | `colors.tealOnNeutral` |
  | `budgetAlert` | `Icons.warning_amber_rounded` | `colors.coralLightBg` | `colors.coralOnNeutral` |
  | `recurringDue` | `Icons.event_outlined` | `tealLightBg` | `tealOnNeutral` |
  | `goalReminder` | `Icons.track_changes` | `tealLightBg` | `tealOnNeutral` |
  | `periodSummary` | `Icons.pie_chart_outline` | `tealLightBg` | `tealOnNeutral` |

- **Lý do**: mockup `03` vẽ vòng tròn r=18 (36 px) với đúng 2 sắc nền
  (`#E1F5EE` cho 4 loại, `#D85A30`@14% cho 2 mục ngân sách); cùng bộ icon PBI 28
  đã dùng ở màn `01` ⇒ hai màn thông báo trông cùng một hệ. Coral **đúng** ngữ
  nghĩa (FR-006/FR-015: chỉ ngữ cảnh cảnh báo chi tiêu/ngân sách).
- **Phương án khác đã xem xét**: icon riêng cho từng loại khác mockup (`alarm`,
  `savings`) — lệch SC-001; bảng map ở `app_notification.dart` (tầng core) — kéo
  `material.dart` + token màu vào tầng domain, mà chỉ **một** màn dùng.

## R11 — Chạm một mục: đánh dấu đã đọc **rồi** điều hướng theo `kind`

- **Quyết định**: `await store.markRead(id, now)` → cập nhật danh sách trong bộ nhớ
  → `if (!mounted) return` → điều hướng:

  | `kind` | Đích (FR-008) |
  |---|---|
  | `dailyReminder` | `AddTransactionScreen()` (mặc định `initialType = expense`) |
  | `budgetAlert` | `BudgetDetailScreen(budgetId: relatedId!)` + `onSelectTab` |
  | `periodSummary` | `Navigator.popUntil(isFirst)` → `onSelectTab?.call(2)` (tab Báo cáo) |
  | `recurringDue`, `goalReminder` | **không điều hướng** (module chưa tồn tại) |
  | `budgetAlert` mà `relatedId == null` | **không điều hướng** (dữ liệu cũ/thiếu) |

- **Lý do**: (a) đánh dấu trước để "chạm là đã đọc" không phụ thuộc việc màn đích
  mở được hay không (FR-007 nói **cả hai** việc, không nói phụ thuộc nhau);
  (b) ngân sách đã bị xoá ⇒ `BudgetDetailScreen` **tự** hiện `'Danh mục đã bị xóa'`
  (đã kiểm trong code, `budget_detail_screen.dart` nhánh `budget == null`) nên
  không cần kiểm tra tồn tại trước khi push — 0 truy vấn thêm; (c) 2 loại chưa có
  màn đích chỉ đánh dấu đã đọc, **im lặng** (FR-008, đồng bộ tiền lệ PBI 28 Q3:
  không "sắp có", không vô hiệu hoá); (d) tab Báo cáo nằm **trong** shell ⇒ phải
  `popUntil(isFirst)` rồi đổi tab, đúng khuôn `_seeAll` của `BudgetDetailScreen`.
- **Phương án khác đã xem xét**: điều hướng trước rồi đánh dấu (chạm vào loại
  không có đích sẽ không đánh dấu được); `Get.to` thay `Navigator` (PBI 29 đã lệch
  sang `Navigator` — giữ một khuôn cho màn con); kiểm tra ngân sách tồn tại trước
  khi push (thêm 1 truy vấn + nhánh "không tìm thấy" mà màn đích đã lo).

## R12 — Chấm đỏ trên chuông: `AppColors.coral` + viền trắng (**ngoại lệ có lý do**)

- **Quyết định**: chấm tròn 9 px `AppColors.coral` viền 2 px `AppColors.white`, đặt
  góc trên-phải ô nút 48 px của chuông; chỉ vẽ khi `_unread > 0` (FR-001).
- **Lý do**: (a) spec viết "chấm **đỏ**" (FR-001/SC-013) nhưng **bảng màu dự án
  không có token đỏ nào** — Design System chỉ có teal thương hiệu + coral
  `#D85A30` (đỏ-cam) + xám; coral là sắc "cần chú ý" duy nhất có sẵn; (b) chấm nằm
  **trên nền teal** của vùng tiêu đề ⇒ phải có **viền trắng** mới đủ tương phản
  (nếp badge chuẩn); (c) thêm token đỏ mới = mở rộng bảng màu ngoài Design System
  cho **một** chấm 9 px.
- **Lệch đã biết**: QA sẽ thấy chấm **đỏ-cam** chứ không đỏ tươi — ghi ở
  [quickstart.md](./quickstart.md) §4; nếu người dùng muốn đỏ thật ⇒ thêm
  `AppColors.badge` (1 hằng số) ở PBI sau, đổi **1 dòng** trong `_BellButton`.
- **Phương án khác đã xem xét**: thêm `AppColors.categoryRed` (`#EB5757`) làm
  chấm — có sẵn nhưng là token **bảng màu danh mục**, mượn sai ngữ nghĩa (tên gọi
  nói dối người đọc code sau); token mới `badgeRed` — cần cập nhật
  `docs/design-system-app-thu-chi.md` (nguồn chân lý) trong cùng PBI; chấm teal như
  mockup `03` — mockup không vẽ chuông nên không có cơ sở, và teal trên teal **vô
  hình**.

## R13 — Trạng thái đã đọc: một chiều, ghi ở `markRead`, không thao tác hàng loạt

- **Quyết định**: `markRead(id, readAt)` chỉ `UPDATE … WHERE id = ? AND read_at IS
  NULL` ⇒ gọi lại **không** đổi `read_at` (bất biến một chiều, FR-009); UI cũng chỉ
  gọi khi `!isRead`. Màn **không** có nút "đánh dấu tất cả đã đọc", **không** xoá
  mục/lịch sử (FR-019, Q2=A); danh sách chỉ đọc + 1 cột trạng thái (FR-012).
- **Lý do**: điều kiện `read_at IS NULL` trong **câu SQL** là chỗ duy nhất cưỡng
  chế được bất biến này cho mọi đường gọi (kể cả engine/màn khác sau này); kiểm ở
  UI là chỗ dễ quên nhất.
- **Phương án khác đã xem xét**: `markRead` ghi đè vô điều kiện (mất tính một
  chiều, mục đã đọc lâu vẫn đổi "thời điểm đọc" mỗi lần chạm); lưu cờ `is_read`
  bool tách khỏi `read_at` (2 nguồn sự thật có thể lệch — `read_at != null` đã là
  cờ, và spec yêu cầu lưu **cả** thời điểm đọc).

## R14 — i18n: ~12 khoá mới, nội dung bản ghi **không** dịch lại

- **Quyết định**: khoá **mới** (literal trước `.tr` trong `lib/` ⇒ test
  `sora_translations_test` bắt buộc có bản EN): `'Thông báo'`, `'Chưa đọc'`,
  `'TUẦN NÀY'`, `'TRƯỚC ĐÓ'`, `'Chưa có thông báo nào'`, `'Thông báo và nhắc nhở
  sẽ hiện ở đây.'`, `'Không có thông báo chưa đọc'`, `'Không đọc được thông báo.'`,
  `'Mở cài đặt thông báo'` + 7 tên thứ đầy đủ. **Tái dùng** khoá đã có: `'Tất cả'`,
  `'HÔM NAY'`, `'Thử lại'`, `'Thông báo & nhắc nhở'` (tooltip bánh răng).
- **Lý do**: FR-014 tách rõ 2 nhóm — **nhãn tĩnh** của màn phải dịch, **nội dung
  thông báo đã lưu** (tiêu đề/dòng mô tả do engine sinh lúc bắn) giữ **nguyên văn**
  ⇒ bản ghi lưu `title`/`body` là **snapshot**, màn chỉ `Text(widget.title)`,
  **không** `.tr` lên chúng. Giờ `HH:mm` + ngày `dd/MM` không đổi theo ngôn ngữ.
- **Phương án khác đã xem xét**: lưu khoá dịch + tham số trong DB rồi dịch lúc vẽ
  (đổi số liệu đã chụp theo ngôn ngữ mới — trái FR-014); gom tên thứ vào `const
  List` rồi `map` (test dịch **lọt lưới** — tiền lệ PBI 29 R11).

## R15 — Kiểm thử: 3 file mới + 1 fake mới + 5 file sửa

- **Quyết định**:

  | File | Việc |
  |---|---|
  | `test/app_notification_test.dart` | **MỚI** — hàm thuần: nhóm thời gian (hôm nay / 1 / 7 / 8 ngày, mốc nửa đêm), nhãn thời gian 3 dạng, `weekdayName` 7 giá trị + ngoài miền, `isRead`, hằng `kMaxNotifications` |
  | `test/notification_history_store_drift_test.dart` | **MỚI** — drift in-memory (host này **có** sqlite native, đã chạy thử): `schemaVersion == 9`; bảng rỗng → `[]`; append → `loadRecent` mới nhất trước; **trần 200** (chèn 205 → còn 200, giữ 200 mục **mới nhất**, mục cũ nhất biến mất); `markRead` một chiều + idempotent; không đụng bảng khác |
  | `test/notification_center_screen_test.dart` | **MỚI** — màn với `FakeNotificationHistoryStore`: app bar + bánh răng, 2 tab, nhãn nhóm, chấm teal chỉ ở mục chưa đọc, 2 sắc icon (coral chỉ cảnh báo ngân sách), nhãn thời gian; chạm mục chưa đọc → đã đọc + **đúng 1 route** đích; chạm mục đã đọc → vẫn đọc, vẫn điều hướng; `recurringDue`/`goalReminder`/`relatedId == null` → 0 route, không lỗi; tab "Chưa đọc" lọc đúng; 2 trạng thái rỗng + **2 câu khác nhau**; bánh răng → màn `01`; `loading`/`error` + Thử lại; cỡ chữ 2.0 + 360×640 không tràn, cuộn tới mục cuối |
  | `test/fakes/fake_notification_history_store.dart` | **MỚI** — bản bộ nhớ (`stored` để assert, `failLoad`) |
  | `test/widget_test.dart` | **SỬA** — `pumpShell` đăng ký thêm fake store (màn Tổng quan đọc lịch sử ngay khi boot, không để mở drift thật); thêm nhóm test: chuông có/không chấm đỏ theo dữ liệu, mở Trung tâm 1 chạm, quay lại → chấm mất |
  | `test/notification_store_drift_test.dart` | **SỬA** — `schemaVersion` 8 → **9** (dòng 30) |
  | `test/scan_settings_store_drift_test.dart` | **SỬA** — `schemaVersion` 8 → 9 |
  | `test/utilities_store_drift_test.dart` | **SỬA** — `schemaVersion` 8 → 9 |
  | `test/scan_dao_test.dart` | **SỬA** — `schemaVersion` 8 → 9 |
  | `test/dark_theme_smoke_test.dart` | **SỬA** — thêm màn Trung tâm vào danh sách smoke tối |

- **Lý do**: luật thuần (nhóm/nhãn) kiểm ở tầng thấp không cần binding; trần 200
  kiểm ở **DAO thật** (host này chạy được sqlite native — khác mấy test drift phải
  skip-guard) để FR-010/SC-014 không chỉ là lời hứa; màn kiểm bằng store giả.
- **Phương án khác đã xem xét**: viết lại `FakeNotificationStore` (PBI 28) để phục
  vụ lịch sử (chạm file đã QA, và trộn 2 mối quan tâm vào 1 fake).

## R16 — Xếp lớp file

- **Quyết định**:
  `lib/core/notification/app_notification.dart` (bản ghi + enum + nhóm + nhãn),
  `lib/core/notification/notification_history_store.dart` (seam),
  `lib/data/notification_history_store_drift.dart` (impl),
  `lib/data/notification_history_deps.dart` (`ensureNotificationHistoryStore`),
  `lib/screens/notification_center_screen.dart` (màn `03`).
- **Lý do**: đúng nhà đã có của module Thông báo (`core/notification/` cho nghiệp
  vụ thuần, `data/` cho drift + DI — khuôn PBI 28), để engine PBI sau ở cùng thư
  mục; `date_label.dart` giữ vai trò "hàm ngày dùng chung" (thêm `weekdayName`).

## R17 — Không GetX controller, không widget dùng chung mới, không package mới

- **Quyết định**: màn giữ state cục bộ + seam bơm được; `_TabBar`, `_GroupLabel`,
  `_NotificationTile`, `_BellButton`, `_EmptyState` là widget **private** trong
  file màn; `pubspec.yaml` **không đổi**.
- **Lý do**: khuôn PBI 17/28 (màn + seam, không controller); các widget nhỏ này chỉ
  dùng ở **một** màn (nâng thành widget dùng chung bây giờ là abstraction cho 1 chỗ
  dùng — `screens/` đã có tiền lệ chép khuôn, PBI 28 R7).

## R18 — Không làm (ngoài phạm vi, giữ nguyên trong spec)

Notification Engine (tính điều kiện 5 loại, lên lịch, bắn cảnh báo sau khi lưu giao
dịch, chống trùng, nội dung kèm số liệu); `flutter_local_notifications`/`timezone`/
quyền thông báo/channel/autostart/deep link từ thông báo hệ thống; ghi lịch sử khi
loại thông báo được kích hoạt (nguồn ghi = engine, PBI sau); màn `04` mẫu thông báo
đẩy; đánh dấu tất cả đã đọc / xoá mục / xoá lịch sử / ghim / tìm kiếm trong lịch
sử / màn chi tiết một thông báo; seed dữ liệu mẫu trong app; đưa lịch sử vào
backup/restore JSON (GĐ3); widget màn hình chính.
