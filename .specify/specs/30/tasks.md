# Danh sách Task: Trung tâm thông báo trong app (màn `03`)

**Mã PBI**: 30
**Nguồn**: plan.md, spec.md, data-model.md, research.md, quickstart.md
**Mốc test trước PBI**: 1052 pass + **1 test đỏ CÓ SẴN** (`test/transactions_dao_test.dart`, từ PBI 11) — mục tiêu: **không tăng** số đỏ.
**Nguyên tắc**: 0 dependency mới · `pubspec.yaml` không đổi · không hex cứng trong widget · mọi nhãn tĩnh có bản dịch EN · nội dung bản ghi lưu hiển thị nguyên văn (không `.tr`).

## Định dạng task

`- [ ] [MãTask] [P?] [Story?] Mô tả kèm đường dẫn file`

- `[P]`: có thể chạy song song (khác file, không phụ thuộc task chưa xong)
- `[Story]`: bắt buộc ở pha User Story (VD `[US1]`), không dùng ở Setup/Foundational/Polish

## Pha 1: Setup

- [X] T001 Chạy `flutter pub get` + `flutter test` tại `app/sora_thu_chi/` để ghi nhận mốc baseline (1052 pass + 1 đỏ có sẵn ở `test/transactions_dao_test.dart`) và xác nhận `dart run build_runner` chạy được — **không** thêm dependency (plan.md §Ngữ cảnh kỹ thuật: `pubspec.yaml` không đổi)

## Pha 2: Foundational

*(Bắt buộc xong trước mọi user story: thực thể + seam + bảng drift v9 + i18n)*

- [X] T002 [P] Tạo `lib/core/notification/app_notification.dart`: hằng `const int kMaxNotifications = 200`, `enum NotificationKind` (5 giá trị `dailyReminder`/`budgetAlert`/`recurringDue`/`goalReminder`/`periodSummary`), `enum NotificationGroup` (3 giá trị + `String get label` literal `'HÔM NAY'`/`'TUẦN NÀY'`/`'TRƯỚC ĐÓ'` trước `.tr`), `class AppNotification` (7 trường `const`, `bool get isRead`, `==`/`hashCode`, `copyWith({DateTime? readAt})`) — data-model.md §1–3
- [X] T003 [P] Thêm `String weekdayName(int weekday)` vào `lib/core/date_label.dart`: `switch` 1…7 → `'Thứ Hai'`…`'Chủ Nhật'` (literal **ngay trước** `.tr`, không gom `const List` — bẫy PBI 29 R11), ngoài miền → `''`
- [X] T004 Thêm 2 hàm thuần vào `lib/core/notification/app_notification.dart`: `NotificationGroup notificationGroup(DateTime at, DateTime now)` (luật 18 — so **ngày lịch** bằng `DateTime(y,m,d).difference(...).inDays`) và `String notificationTimeLabel(DateTime at, DateTime now)` (luật 19 — `HH:mm` / `weekdayName` / `dd/MM`, tái dùng `formatClock` + `_two` của `date_label.dart`)
- [X] T005 [P] Viết `test/app_notification_test.dart`: `notificationGroup` (cùng ngày; 23:59 hôm qua với `now` 00:01 → `thisWeek`; 1 / 7 / 8 ngày; khác tháng-năm), `notificationTimeLabel` (`'20:30'` / tên thứ / `dd/MM`), `weekdayName` 7 giá trị + `0`/`8` → `''`, `kMaxNotifications == 200`, `isRead`, `==`/`hashCode`/`copyWith(readAt)`
- [X] T006 [P] Tạo seam `lib/core/notification/notification_history_store.dart`: `abstract class NotificationHistoryStore` với `Future<List<AppNotification>> loadRecent()`, `Future<void> append(AppNotification notification)`, `Future<void> markRead(int id, DateTime readAt)` — **không** có `unreadCount`/`markAllRead`/`delete` (R4); **không** sửa `notification_store.dart` (PBI 28)
- [X] T007 Thêm bảng `@DataClassName('NotificationsRow') class Notifications extends Table` (7 cột: `id` autoIncrement, `kind` `textEnum<NotificationKind>()`, `title` text, `body` text default `''`, `created_at` dateTime, `read_at` dateTime nullable, `related_id` integer nullable — không FK) vào `lib/data/db/app_database.dart`; thêm vào `@DriftDatabase(tables: [...])`; `schemaVersion => 9`; nhánh `if (from < 9) await m.createTable(notifications);` đặt **sau** nhánh `from < 8`, **không** seed — data-model.md §4
- [X] T008 Chạy `dart run build_runner build --delete-conflicting-outputs` sinh lại `lib/data/db/app_database.g.dart`, rồi `flutter analyze` phải sạch (rủi ro 1 của plan.md)
- [X] T009 Sửa `schemaVersion` 8 → 9 (1 dòng/file, chỉ đổi số khẳng định) tại `test/notification_store_drift_test.dart`, `test/scan_settings_store_drift_test.dart`, `test/utilities_store_drift_test.dart`, `test/scan_dao_test.dart` — ngoại lệ 6 của plan.md
- [X] T010 Tạo `lib/data/notification_history_store_drift.dart` (`class DriftNotificationHistoryStore implements NotificationHistoryStore`): `loadRecent` `orderBy([createdAt DESC, id DESC])` → map domain (`NotificationKind.values.byName`); `append` insert 1 dòng (bỏ qua `n.id`) rồi dọn vượt trần bằng SELECT top-200 + `delete(id.isNotIn(keep))` (R3, luật 2–4); `markRead` `UPDATE … WHERE id = ? AND read_at IS NULL` (luật 6–7) — bám khuôn mỏng `notification_store_drift.dart`
- [X] T011 Viết `test/notification_history_store_drift_test.dart` (drift in-memory + skip-guard như các test drift khác): `schemaVersion == 9`; bảng rỗng → `[]`; `append` 3 dòng → `loadRecent` mới nhất trước (2 dòng cùng `createdAt` → `id` giảm); **trần 200** (`append` 205 dòng → `length == 200`, khẳng định **tập id còn lại** = 200 id mới nhất, mục cũ nhất mất); `markRead` gọi lần 2 **không** đổi `readAt`, id không tồn tại → không lỗi/không tạo dòng; `append` + `markRead` **không** đụng `appSettings`/`wallets`/`transactions` (rủi ro 7; luật 14)
- [X] T012 [P] Tạo `test/fakes/fake_notification_history_store.dart` (bản bộ nhớ: `stored` để assert, cờ `failLoad`/`failMarkRead`) — bám `test/fakes/fake_notification_store.dart`
- [X] T013 [P] Tạo `lib/data/notification_history_deps.dart`: `NotificationHistoryStore ensureNotificationHistoryStore()` — GetX singleton tạo **đúng 1** `DriftNotificationHistoryStore(AppDatabase())`; test `Get.put` fake trước ⇒ trả fake, không mở drift (bám `ensureNotificationStore` ở `lib/data/notification_deps.dart`)
- [X] T014 [P] Thêm ~19 khoá dịch EN vào nhánh `_en` của `lib/core/locale/sora_translations.dart`: `'Thông báo'`, `'Chưa đọc'`, `'TUẦN NÀY'`, `'TRƯỚC ĐÓ'`, `'Chưa có thông báo nào'`, `'Thông báo và nhắc nhở sẽ hiện ở đây.'`, `'Không có thông báo chưa đọc'`, `'Không đọc được thông báo.'`, `'Mở cài đặt thông báo'` + 7 tên thứ; tái dùng `'Tất cả'`/`'HÔM NAY'`/`'Thử lại'`/`'Thông báo & nhắc nhở'` (không thêm lại) — chạy `flutter test test/sora_translations_test.dart` ngay sau (rủi ro 8)

## Pha 3: User Story 1 — Màn Trung tâm hiển thị lịch sử (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: Mở màn `03` thấy đúng mockup — app bar teal + back + tiêu đề "Thông báo" + bánh răng, 2 tab lọc "Tất cả"/"Chưa đọc", danh sách nhóm theo thời gian (HÔM NAY / TUẦN NÀY / TRƯỚC ĐÓ), mục có chấm teal + icon tròn theo loại + tiêu đề + mô tả + nhãn thời gian; trạng thái rỗng 2 câu riêng; đủ Sáng/Tối + i18n + cỡ chữ lớn.

**Tiêu chí kiểm thử độc lập**: `Get.put` `FakeNotificationHistoryStore` có dữ liệu sẵn rồi push `NotificationCenterScreen()` → kiểm được toàn bộ bố cục, 2 tab, nhãn nhóm, 2 sắc icon, 2 câu rỗng, nhánh lỗi — **không** cần màn Tổng quan (FR-002…FR-006, FR-011, FR-014…FR-018).

- [X] T015 [US1] Tạo `lib/screens/notification_center_screen.dart`: `NotificationCenterScreen` (`StatefulWidget` với `store?`/`onSelectTab?`/`now?` để test bơm), `initState → _load()` gọi `store.loadRecent()` **một lần** rồi `setState`, state `_store`/`_items`/`_tab`/`_loading`/`_error`, `_visible` lọc **trong bộ nhớ** theo tab (FR-003, 0 I/O); thân là `SubPageScaffold(title: 'Thông báo'.tr, actions: [gear])` trên `Column` + nhánh `_loading` → spinner │ `_error` → câu `'Không đọc được thông báo.'` + `'Thử lại'` │ rỗng → `_EmptyState` │ còn lại → `ListView` nhóm (FR-002, FR-017)
- [X] T016 [US1] Thêm widget private `_TabBar(colors, selected, onChanged)` trong `lib/screens/notification_center_screen.dart` (R7: `Row` 2 `GestureDetector(opaque)`, nhãn 13 px — `AppColors.teal` w600 khi chọn / `colors.tabInactive` khi không, gạch chân 2 px `AppColors.teal` dưới nhãn đang chọn, `ValueKey('notification-tab-all')`/`ValueKey('notification-tab-unread')`, kẻ `colors.listDivider` cao 1 ở đáy) — **không** dùng `TabBar`/`TabController`
- [X] T017 [US1] Thêm widget private `_GroupLabel(colors, group)` + `_NotificationTile(colors, item, onTap)` trong `lib/screens/notification_center_screen.dart`: nhãn nhóm 11 px w600 `colors.tabInactive`; tile = `Row(crossAxisAlignment: start)` gồm **chấm 8 px** `AppColors.teal` khi `!isRead` (đã đọc vẫn chiếm 8 px để không xô lệch) + vòng tròn **36 px** nền `tealLightBg`/`coralLightBg` + glyph 20 px `tealOnNeutral`/`coralOnNeutral` + `Expanded` chứa `Row(Expanded(tiêu đề), SizedBox(8), nhãn thời gian)` rồi dòng mô tả **wrap tự nhiên** (không `maxLines`) + `Divider(colors.listDivider, height: 1)` thụt lề 20; chữ: chưa đọc `textPrimary` w600 / `textSecondary`, đã đọc `listLabel` w400 / `tabInactive` (FR-005, FR-016, SC-011)
- [X] T018 [US1] Thêm `_EmptyState(colors, title, subtitle)` + `_iconFor(kind)` + `_tintFor(kind, colors)` trong `lib/screens/notification_center_screen.dart`: icon `Icons.notifications_none` 44 px `colors.tabInactive` + câu chính 16 px w600 + câu phụ 13 px, **2 câu khác nhau** cho rỗng chung (`'Chưa có thông báo nào'`) và tab "Chưa đọc" (`'Không có thông báo chưa đọc'`); bảng icon/màu R10 — chuông (dailyReminder) / cảnh báo **coral** (budgetAlert) / lịch (recurringDue) / bullseye (goalReminder) / biểu đồ tròn (periodSummary), coral **chỉ** ở `budgetAlert` (FR-006, FR-011, FR-015, SC-001, SC-007)
- [X] T019 [US1] Nối `_openSettings()` trong `lib/screens/notification_center_screen.dart`: icon bánh răng ở `actions` → `Navigator.push` tới `NotificationSettingsScreen(store: ...)` (màn `01` của PBI 28) — SC-002
- [X] T020 [US1] Viết `test/notification_center_screen_test.dart` (phần hiển thị, dùng `FakeNotificationHistoryStore` + `now` bơm cố định): app bar + tiêu đề + bánh răng; 2 tab + gạch chân ở tab đang chọn; nhãn nhóm đúng thứ tự + **không** vẽ nhóm rỗng; chấm teal **chỉ** ở mục chưa đọc; 2 sắc icon (soi `Container.decoration`, coral chỉ `budgetAlert`); nhãn thời gian 3 dạng; tab "Chưa đọc" lọc đúng + giữ nhóm; 2 trạng thái rỗng với **2 câu khác nhau**; bánh răng → `NotificationSettingsScreen`; nhánh lỗi đọc + `'Thử lại'`; cỡ chữ 2.0 + surfaceSize 360×640 không overflow + cuộn tới mục cuối (SC-005, SC-007, SC-011)
- [X] T021 [US1] Sửa `test/dark_theme_smoke_test.dart`: thêm màn Trung tâm (đăng ký fake store) vào smoke tối — FR-015, SC-010

## Pha 4: User Story 2 — Chạm mục: đánh dấu đã đọc & điều hướng (Ưu tiên: P2)

**Mục tiêu**: Chạm một mục → mục đó chuyển **đã đọc** (chấm teal mất, chữ mờ đi), trạng thái **lưu bền**, **và** mở đúng màn hình liên quan theo loại; loại chưa có màn đích thì chỉ đánh dấu đã đọc, **im lặng** — không lỗi, không "sắp có"; các mục khác không đổi.

**Tiêu chí kiểm thử độc lập**: Trên màn Trung tâm có sẵn dữ liệu, chạm lần lượt từng loại mục → đối chiếu `readAt` trong fake store + số route được mở; kiểm được **không** cần màn Tổng quan (FR-007, FR-008, FR-009, FR-019, SC-006).

- [X] T022 [US2] Cài `_open(item)` trong `lib/screens/notification_center_screen.dart`: nếu `!item.isRead` thì `await store.markRead(item.id, _now)` rồi `if (!mounted) return;` + `setState` cập nhật mục trong `_items` (mất chấm, chữ mờ); sau đó gọi `_navigate(item)` (R11 — đánh dấu **trước**, điều hướng **sau**; FR-007, luật 12–13)
- [X] T023 [US2] Cài `_navigate(item)` trong `lib/screens/notification_center_screen.dart` theo bảng FR-008: `dailyReminder` → push `AddTransactionScreen()`; `budgetAlert` → `relatedId == null` ⇒ return, ngược lại push `BudgetDetailScreen(onSelectTab: widget.onSelectTab)`; `periodSummary` → `popUntil(isFirst)` rồi `widget.onSelectTab?.call(2)` (tab Báo cáo); `recurringDue`/`goalReminder` → return **im lặng** (0 route, 0 SnackBar, 0 dialog — luật 20)
- [X] T024 [US2] Bổ sung vào `test/notification_center_screen_test.dart`: chạm mục chưa đọc → `readAt` được ghi trong fake store + **đúng 1** route đích; chạm mục đã đọc → vẫn điều hướng nhưng `readAt` **không** đổi; `recurringDue`/`goalReminder`/`budgetAlert` thiếu `relatedId` → **0** route, 0 SnackBar/dialog, nhưng **vẫn** đánh dấu đã đọc; `periodSummary` → pop về màn gốc + `onSelectTab(2)`; sau khi đọc mục cuối, chuyển tab "Chưa đọc" → danh sách rỗng đúng câu riêng (FR-003, FR-019, SC-005, SC-006)

## Pha 5: User Story 3 — Điểm vào chuông ở Tổng quan + chấm đỏ (Ưu tiên: P3)

**Mục tiêu**: Màn Tổng quan có biểu tượng chuông ở vùng tiêu đề, **luôn** bấm được, mở Trung tâm bằng **đúng 1 lần chạm**; hiện **chấm đỏ** khi còn ≥1 mục chưa đọc và mất chấm **ngay** sau khi đọc mục cuối rồi quay về.

**Tiêu chí kiểm thử độc lập**: Khởi động app (shell) với fake store rỗng → không chấm; fake store có 1 mục chưa đọc → có chấm; chạm chuông → mở Trung tâm; back → chấm cập nhật lại (FR-001, SC-002, SC-013).

- [X] T025 [US3] Sửa `lib/screens/dashboard_screen.dart`: `DashboardScreen` từ `StatelessWidget` (khung rỗng) → `StatefulWidget` với `this.store`/`this.onSelectTab`; state `_unread` (lỗi đọc ⇒ `0`, **nuốt lỗi**, không crash); `initState → _refresh()` = `(await store.loadRecent()).where(!isRead).length`; `_openCenter()` = `await Navigator.push(...)` **rồi** `_refresh()` (R5 — đọc lại **sau** khi quay về); `ScreenHeader(title: 'Tổng quan'.tr, trailing: _BellButton(...))` (luật 21–23, rủi ro 4–5)
- [X] T026 [US3] Thêm widget private `_BellButton(unread, onTap)` trong `lib/screens/dashboard_screen.dart`: `Tooltip('Thông báo'.tr)` + `InkWell(customBorder: CircleBorder())` + `SizedBox(48×48)` + `Stack` gồm `Icon(Icons.notifications_none, 24, AppColors.white)` và `if (unread > 0)` `Positioned(top: 10, right: 10)` chấm 9 px `AppColors.coral` viền 2 px `AppColors.white` (R12 — ngoại lệ 1), `ValueKey('dashboard-notification-bell')` (FR-001, SC-013)
- [X] T027 [US3] Sửa `lib/core/app_shell.dart`: đổi `DashboardScreen()` thành `DashboardScreen(onSelectTab: _onTabSelected)` (bỏ `const`; khuôn đang bơm cho `ReportScreen` ở dòng 33) — R6
- [X] T028 [US3] Sửa `test/widget_test.dart`: `pumpShell` đăng ký `FakeNotificationHistoryStore` **trước** khi pump (khuôn đang đăng ký `FakeWalletRepository`), thêm test: chuông có mặt; **không** chấm khi lịch sử rỗng; **có** chấm khi có mục chưa đọc; 1 chạm mở Trung tâm; back → chấm cập nhật (rủi ro 4–5, SC-013)

## Pha cuối: Polish & Cross-cutting

- [X] T029 Chạy `flutter analyze` (phải sạch) + `flutter test` toàn bộ tại `app/sora_thu_chi/`; đối chiếu mốc T001 — **không** tăng số test đỏ so với baseline (rủi ro 3)
- [X] T030 Chạy QA tay nhóm **A–N** theo `.specify/specs/30/quickstart.md` §2 trên emulator (chèn lịch sử mẫu bằng §1.2 cho nhóm E–J) và đối chiếu SC-001…SC-014; **ĐÃ ĐẠT** (2026-09-13, người dùng chạy tay trên emulator)
- [X] T031 Cập nhật `wiki-knowledge/` bằng skill `sora-wiki`: page liên quan (Hồ sơ & Bảo mật), page Lộ trình (đóng mục Trung tâm thông báo), `index.md` + append `wiki-knowledge/log.md`
- [X] T032 Rà soát cuối: 0 hex cứng trong `lib/screens/notification_center_screen.dart` + `lib/screens/dashboard_screen.dart` (mọi màu qua `AppColors`/`SoraColors`), `title`/`body` của bản ghi **không** bị `.tr` ở bất kỳ đâu trong `lib/` (FR-014, luật 16, 26)

## Sơ đồ phụ thuộc

```text
Setup (T001)
   │
Foundational (T002–T014)
   ├─ T002 → T004 → T005
   ├─ T003 → T004
   ├─ T006 → T010 → T011 ; T010 → T013
   ├─ T007 → T008 → T009 ; T008 → T010
   └─ T012, T014 độc lập
   │
US1 (T015–T021)  ── phụ thuộc Foundational (T002/T010/T013/T014)
   │                     T015 → T016, T017, T018 → T020 ; T015 → T019, T021
   ▼
US2 (T022–T024)  ── phụ thuộc T015 (màn đã có), T022 → T023 → T024
   │
US3 (T025–T028)  ── phụ thuộc T010/T013 (seam) + T015 (màn Trung tâm để push)
   │                     T025 → T026, T027 → T028
   ▼
Polish (T029–T032)
```

**Ghi chú**: US3 chỉ **phụ thuộc mềm** vào US1 — chấm đỏ và điểm vào kiểm được độc lập bằng fake store (test `widget_test` khẳng định chấm, không cần màn Trung tâm render đúng); nhưng luồng "chạm chuông → đọc mục → back → chấm mất" cần cả hai nên US3 xếp sau.

## Ví dụ chạy song song

```text
# Foundational — nhóm thuần Dart / file riêng, chạy cùng lúc:
T002 [P] app_notification.dart (thực thể + enum)
T003 [P] date_label.dart (+weekdayName)
T006 [P] notification_history_store.dart (seam)
T012 [P] test/fakes/fake_notification_history_store.dart
T014 [P] sora_translations.dart (+~19 khoá EN)

# US1 — sau khi T015 (khung màn) xong, 3 widget con độc lập về mặt nội dung
# nhưng CÙNG file notification_center_screen.dart ⇒ thi công tuần tự,
# chỉ test/smoke chạy song song với việc dựng widget:
T021 [US1] test/dark_theme_smoke_test.dart  (file khác, độc lập)

# US3 — T026 (_BellButton) và T027 (app_shell.dart) khác file:
T026 [US3] dashboard_screen.dart (_BellButton)
T027 [US3] app_shell.dart (+onSelectTab)
```

## Chiến lược triển khai

- **MVP đề xuất**: **US1** (màn Trung tâm hiển thị lịch sử + 2 tab + nhóm thời gian + trạng thái rỗng). Đây là lát cắt kiểm thử độc lập được ngay bằng fake store, và là toàn bộ phần "hộp thư" mà spec mô tả — chưa cần màn Tổng quan.
- **Giao hàng tăng dần**:
  1. **US1** → màn `03` đọc và hiển thị đúng mockup, đủ Sáng/Tối/EN/cỡ chữ lớn.
  2. **US1 + US2** → thêm vòng đời đọc: chạm mục đánh dấu đã đọc (lưu bền, một chiều) + điều hướng đích ⇒ màn dùng được thật.
  3. **US1 + US2 + US3** → nối vào app: chuông ở Tổng quan + chấm đỏ ⇒ hoàn chỉnh PBI 30.
- **Lưu ý khi thi công**: (a) chạy `build_runner` **ngay** sau T007 rồi `flutter analyze` trước khi viết store (T010); (b) trên máy thật màn sẽ **luôn rỗng** vì chưa có engine ghi lịch sử (Q1=A) — đây là hành vi đã chốt, không phải lỗi (plan.md ngoại lệ 5; QA dùng quickstart §1.2); (c) mốc test đỏ có sẵn ở `transactions_dao_test.dart` không được tăng.
- **Sau khi xong**: chạy `/sora-implement 30` để thi công, rồi commit bằng skill `git-commit` (Conventional Commits, tiếng Việt, không trailer `Co-Authored-By`), và cập nhật wiki bằng skill `sora-wiki`.
