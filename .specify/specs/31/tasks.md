# Danh sách Task: Thông báo đẩy — engine bắn thông báo & nhắc nhở

**Mã PBI**: 31
**Nguồn**: plan.md, spec.md, data-model.md, research.md, quickstart.md
**Mốc test trước PBI**: 1100 pass + **1 test đỏ CÓ SẴN** (`test/transactions_dao_test.dart`, từ PBI 11) — mục tiêu: **không tăng** số đỏ.
**Nguyên tắc**: 3 dependency mới (đã chốt trong docs — R1) · schema drift **v9 → v10** · engine **chỉ đọc** dữ liệu nghiệp vụ, **chỉ ghi** sổ + lịch sử + 1 row cờ quyền (FR-023) · mọi lời gọi từ đường lưu giao dịch là **fire-and-forget** + `try/catch` bên trong engine (FR-024) · 0 màn mới · 0 hex cứng trong widget · mọi khoá dịch mới có bản `_en`.

## Định dạng task

`- [ ] [MãTask] [P?] [Story?] Mô tả kèm đường dẫn file`

- `[P]`: có thể chạy song song (khác file, không phụ thuộc task chưa xong)
- `[Story]`: bắt buộc ở pha User Story (VD `[US1]`), không dùng ở Setup/Foundational/Polish

## Pha 1: Setup

- [X] T001 Chạy `flutter pub get` + `flutter test` tại `app/sora_thu_chi/` ghi nhận mốc baseline (1100 pass + 1 đỏ có sẵn ở `test/transactions_dao_test.dart`), xác nhận `dart run build_runner build --delete-conflicting-outputs` chạy được — **chưa** đổi `pubspec.yaml` ở bước này
- [X] T002 [P] Thêm 3 dependency vào `app/sora_thu_chi/pubspec.yaml`: `flutter_local_notifications: ^22.3.1`, `timezone: ^0.11.1`, `flutter_timezone: ^5.1.0` rồi `flutter pub get` (R1 — toolchain 3.44.6 thoả yêu cầu ≥ 3.38.1)
- [X] T003 [P] Bật **core library desugaring** tại `app/sora_thu_chi/android/app/build.gradle.kts` (`compileOptions { isCoreLibraryDesugaringEnabled = true }` + `dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }`) rồi `flutter build apk --release` **phải xanh** — FLN v10+ bắt buộc desugaring, thiếu là đỏ build ngay (R14, rủi ro cao nhất của plan.md)
- [X] T004 [P] Tạo 3 vector drawable **đơn sắc** 24dp tại `app/sora_thu_chi/android/app/src/main/res/drawable/`: `ic_notif_bell.xml` (chuông), `ic_notif_warning.xml` (cảnh báo), `ic_notif_summary.xml` (biểu đồ tròn) — icon nhỏ của thông báo Android buộc là drawable đơn sắc (không dùng `Icons.*` hay ảnh launcher) — R11/FR-006

## Pha 2: Foundational

*(Bắt buộc xong trước mọi user story: tầng thuần + 2 seam + fake + bảng drift v10 + native + i18n)*

- [X] T005 [P] Tạo `lib/core/notification/notification_schedule.dart` (thuần, không Widget/không I/O): `List<DateTime> dailyFireMoments({required DateTime now, required int hour, required int minute, required List<int> weekdays, int windowDays = 30})` (chỉ ngày trong `weekdays`, **bỏ** mốc đã qua — FR-028) · `DateTime nextWeeklySummaryMoment(DateTime now, int hour, int minute)` · `DateTime nextMonthlySummaryMoment(DateTime now, int hour, int minute)` (ngày cuối tháng kế tiếp — đúng 28/29/30/31) · `String dailyEntryKey(DateTime day)` (`daily:<yyyy-MM-dd>`) · `String summaryWeekEntryKey(DateTime mondayStart)` · `String summaryMonthEntryKey(DateTime month)` · `String budgetEntryKey({required int budgetId, required bool over, required DateTime periodStart})` · `int notificationIdFor(String entryKey)` (**FNV-1a 32-bit tự viết** — `String.hashCode` không ổn định giữa các bản SDK) — R2/R3/R7
- [X] T006 [P] Viết `test/notification_schedule_test.dart`: cửa sổ 30 ngày chỉ chứa ngày được chọn (AC#4) + **bỏ** mốc đã qua (FR-028); mốc Chủ Nhật kế tiếp (hôm nay là CN & giờ chưa qua → hôm nay; giờ đã qua → CN sau); ngày cuối tháng cho tháng 28/29/30/31 + tháng 2 nhuận; khoá mang kỳ đúng định dạng (`daily:2026-09-13`, `budget:over:3:2026-09-01`); `notificationIdFor` ổn định (2 lần cùng chuỗi ⇒ cùng số, luôn ≥ 0, chuỗi khác ⇒ số khác)
- [X] T007 [P] Tạo `lib/core/notification/notification_content.dart` (thuần): sinh `(title, body)` cho 3 loại — `dailyReminderContent({required bool hasTxnToday})` (câu chữ **chỉ** khẳng định "chưa ghi" khi thực tế đúng — FR-008), `budgetAlertContent({required String categoryName, required int percent, required bool over, required String periodLabel})` ("sắp vượt" vs "đã vượt" — FR-007), `summaryContent({required bool weekly, required String comparisonSentence})`; khoá dịch = **chuỗi tiếng Việt** + `.tr`/`.trParams` (khuôn PBI 19); số tiền `formatMoney`, giờ `formatClock` — R12, FR-005…FR-009
- [X] T008 [P] Viết `test/notification_content_test.dart`: câu "sắp vượt" và "đã vượt" **phân biệt được bằng chữ** (FR-007/AC#5); cờ bật + đã ghi ⇒ **không** dùng câu "bạn chưa ghi giao dịch nào hôm nay" (FR-008/AC#3); tổng kết có/không câu so sánh (AC#19/#20); tiêu đề + mô tả ở cả `vi` và `en`; định dạng `82%`, `42.500.000 đ`, giờ `HH:mm`
- [X] T009 [P] Thêm khoá dịch EN cho **câu chữ thông báo** vào nhánh `_en` của `lib/core/locale/sora_translations.dart` (tiêu đề + mô tả 3 loại, biến thể "sắp vượt"/"đã vượt", câu mời xem báo cáo) rồi chạy ngay `flutter test test/sora_translations_test.dart` — mọi khoá mới **phải** có bản `_en` (R12)
- [X] T010 [P] Tạo `lib/core/notification/notification_ledger.dart`: `class NotificationLedgerEntry` (**9 trường** theo data-model §1: `entryKey`/`kind`/`relatedId?`/`title`/`body`/`scheduledFor`/`suppressed`/`historyWrittenAt?`/`historyId?`, `const`, `==`/`hashCode`, `copyWith`) + `bool get pendingHistory => !suppressed && historyWrittenAt == null` + **seam** `abstract class NotificationLedger` (`byKey`, `dueBefore`, `all`, `upsert`, `markHistoryWritten`, `suppress`, `pruneBefore`) — data-model §6
- [X] T011 [P] Tạo `lib/core/notification/notification_presenter.dart`: `class OsNotification` (id/title/body/at/payload/kind) + **seam** `abstract class NotificationPresenter` (`init`, `launchPayload`, `areEnabled`, `requestPermission`, `openSettings`, `schedule`, `show`, `cancel`, `cancelKind`) — data-model §2/§6
- [X] T012 [P] Tạo `test/fakes/fake_notification_ledger.dart` (bản bộ nhớ có `entries` để assert + cờ cắm lỗi cho test FR-024) — bám `test/fakes/fake_notification_store.dart`
- [X] T013 [P] Tạo `test/fakes/fake_notification_presenter.dart` (ghi lại `scheduled`/`shown`/`cancelled`, cờ `enabled`/`permissionResult`/`launchPayload` để test FR-004/FR-017/FR-019)
- [X] T014 [P] Tạo `lib/core/notification/notification_presence.dart`: `class NotificationPresence` với `RxString screen` + `RxInt budgetId` + hằng tên màn (`'budgetDetail'`/`'report'`) — dịch vụ hiện diện cho Q3 (R9)
- [X] T015 Tạo `lib/core/notification/notification_tap.dart`: **chuyển** bảng đích khỏi `_navigate` của `lib/screens/notification_center_screen.dart` thành `enum NotificationTarget { addTransaction, budgetDetail, reportTab, none }` + hàm **thuần** `NotificationTarget notificationTargetFor({required NotificationKind kind, int? relatedId})` + `Future<void> openNotificationTarget({required NotificationTarget target, int? relatedId, ReportPeriod? period, ValueChanged<int>? onSelectTab, required BuildContext context})`; sửa `lib/screens/notification_center_screen.dart` dùng hàm chung (hành vi **không đổi** — `test/notification_center_screen_test.dart` vẫn xanh) — R8, FR-018/FR-020
- [X] T016 Thêm bảng `@DataClassName('NotificationLedgerRow') class NotificationLedger extends Table` (**9 cột** theo data-model §3, `entry_key` = `primaryKey`) vào `lib/data/db/app_database.dart`: thêm vào `@DriftDatabase(tables: [...])`, `schemaVersion => 10`, nhánh `if (from < 10) await m.createTable(notificationLedger);` đặt **sau** nhánh `from < 9`, **thuần tạo — KHÔNG seed**, không `addColumn` bảng nào khác
- [X] T017 Chạy `dart run build_runner build --delete-conflicting-outputs` sinh lại `lib/data/db/app_database.g.dart` rồi `flutter analyze` **phải sạch** (rủi ro 1 của plan.md)
- [X] T018 [P] Sửa `schemaVersion` **9 → 10** (chỉ đổi số khẳng định; nếu file có khẳng định **số bảng** thì cộng thêm 1) tại 6 file: `test/notification_history_store_drift_test.dart`, `test/notification_store_drift_test.dart`, `test/scan_dao_test.dart`, `test/scan_settings_store_drift_test.dart`, `test/utilities_store_drift_test.dart`, `test/wallets_dao_test.dart`
- [X] T019 Tạo `lib/data/notification_ledger_drift.dart`: `class DriftNotificationLedger implements NotificationLedger` — `upsert` = `insertOnConflictUpdate` theo `entryKey` (không nhân đôi dòng); `byKey`/`all` map domain (`NotificationKind.values.byName`); `dueBefore(now)` = `scheduled_for <= now` **và** `suppressed = false` **và** `history_written_at IS NULL`; `markHistoryWritten` ghi **cả** `history_written_at` + `history_id`; `suppress` chỉ set `suppressed = true`; `pruneBefore(cutoff)` xoá dòng `scheduled_for < cutoff` **đã xử lý xong** — bám khuôn mỏng `lib/data/notification_history_store_drift.dart`
- [X] T020 Viết `test/notification_ledger_drift_test.dart` (drift in-memory + skip-guard như các test drift khác): `schemaVersion == 10`; `upsert` cùng khoá 2 lần ⇒ **1** dòng; `dueBefore` lọc đúng và **bỏ** dòng `suppressed` / dòng đã có `history_written_at`; `markHistoryWritten` điền cả 2 cột; `pruneBefore` **chỉ** xoá dòng đã xử lý xong; `upsert`/`suppress` **không** đụng `notifications`/`appSettings`/`wallets`/`transactions`/`budgets`/`categories` (luật 13)
- [X] T021 Sửa `lib/data/notification_deps.dart`: thêm `ensureNotificationLedger()`, `ensureNotificationPresenter()`, `ensureNotificationEngine()` theo khuôn `ensureNotificationStore` (GetX singleton; test `Get.put` fake trước ⇒ trả fake, **không** mở drift/plugin)
- [X] T022 Tạo `lib/data/notification_presenter_plugin.dart`: `class PluginNotificationPresenter implements NotificationPresenter` — `init()` dựng **3 kênh** (`sora_daily` teal · `sora_budget` **coral `#D85A30`** · `sora_summary` teal — FR-025) + `tz.setLocalLocation` từ `flutter_timezone` + `initialize(onDidReceiveNotificationResponse:)`; `schedule` dùng `zonedSchedule` **một-lần** với `AndroidScheduleMode.exactAllowWhileIdle`, **lùi** `inexactAllowWhileIdle` khi `canScheduleExactNotifications() == false` (plugin **im lặng** khi bị từ chối — bẫy chết người, R10); `areEnabled`/`requestPermission` (Android 13+ `requestNotificationsPermission`, iOS `requestPermissions`)/`openSettings`/`show`/`cancel`; `cancelKind` huỷ các id đang chờ **thuộc đúng channel** của loại đó (không huỷ bừa id lạ); `launchPayload()` từ `getNotificationAppLaunchDetails()`
- [X] T023 [P] Sửa `app/sora_thu_chi/android/app/src/main/AndroidManifest.xml`: thêm 3 `uses-permission` (`POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `USE_EXACT_ALARM`) + 2 receiver `ScheduledNotificationReceiver` và `ScheduledNotificationBootReceiver` (`android:exported="false"`, intent-filter `BOOT_COMPLETED` / `MY_PACKAGE_REPLACED` / `QUICKBOOT_POWERON`) — thiếu receiver là **mất toàn bộ lịch sau khởi động lại** (AC#17/SC-010, R14)
- [X] T024 [P] Sửa `app/sora_thu_chi/ios/Runner/AppDelegate.swift`: `UNUserNotificationCenter.current().delegate = self` trong `didFinishLaunchingWithOptions` (thiếu ⇒ thông báo không hiện khi app đang mở — R14)

## Pha 3: User Story 1 — Nhắc nhập giao dịch hằng ngày (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: Cấu hình giờ + ngày trong tuần ở màn `02` → đến **đúng phút** đã cấu hình, kể cả khi app **đã đóng**, thiết bị hiện **thông báo hệ thống** đúng mẫu 2 của mockup `04` (tên app "Sora Thu Chi" + icon chuông teal + tiêu đề + dòng mô tả + nhãn thời gian) **và** đúng **một** bản ghi **chưa đọc** xuất hiện trong Trung tâm (chấm đỏ ở Tổng quan); cờ "chỉ nhắc nếu chưa ghi" **huỷ** mốc hôm nay khi người dùng đã ghi giao dịch; chạm thông báo (qua màn mở khoá PIN nếu có) → màn **Thêm giao dịch** + bản ghi chuyển **đã đọc**; app cũ nâng cấp **không** bị dội thông báo bù.

**Tiêu chí kiểm thử độc lập**: `NotificationEngine` + `FakeNotificationPresenter` + `FakeNotificationLedger` + `FakeNotificationHistoryStore` ⇒ kiểm được **toàn bộ** luật của US1 (sinh lịch, huỷ khi đã ghi, hoà giải ghi bù, chống bắn bù, lỗi không làm hỏng lưu) **không** cần plugin/cần thiết bị (FR-003/FR-008/FR-010/FR-011/FR-024/FR-028, AC#1–#4, AC#21, AC#24).

- [X] T025 [US1] Tạo `lib/core/notification/notification_engine.dart` (**phần lõi**): `class NotificationEngine` nhận qua tham số `presenter`/`ledger`/`history`/`repository`/`prefsStore` (test bơm fake); `Future<void> reconcile()` = (a) hoà giải mọi dòng `dueBefore(now)` → `history.append(AppNotification(kind/title/body lấy từ dòng sổ, createdAt: scheduledFor, readAt: null))` → `ledger.markHistoryWritten(entryKey, id, now)` (**ghi bù** — R6), (b) `ledger.pruneBefore(now − 90 ngày)`, (c) cuốn lịch từng loại đang bật; `Future<void> onPrefsChanged()` (huỷ `cancelKind` của loại vừa tắt rồi `reconcile()`); **toàn bộ** thân bọc `try/catch` **nuốt lỗi** — không ném ra ngoài, không chặn người dùng (FR-024)
- [X] T026 [US1] Thêm vào `lib/core/notification/notification_engine.dart` nhánh **nhắc hàng ngày**: `_rollDaily()` đọc `NotificationPrefs` (chỉ **đọc** — FR-030) → `dailyFireMoments(...)` → mỗi mốc: `ledger.upsert(...)` với `title`/`body` sinh theo `dailyReminderContent` bằng **ngôn ngữ hiện hành** (snapshot — FR-027) + `presenter.schedule(OsNotification(id: notificationIdFor(entryKey), payload: entryKey, at: mốc, …))`; **bỏ** mốc đã qua (FR-028); chỉ chạy khi `dailyEnabled`
- [X] T027 [US1] Thêm vào `lib/core/notification/notification_engine.dart` 2 API còn lại của US1: `Future<void> onTransactionSaved({required DateTime at})` — nếu `dailyOnlyIfNoTxnToday` **bật** **và** ngày `at` đã có **ít nhất 1** giao dịch thuộc **bất kỳ loại nào** (thu/chi/**chuyển khoản** — FR-011) ⇒ `presenter.cancel(notificationIdFor('daily:<D>'))` + `ledger.suppress('daily:<D>')` cho mốc **chưa bắn**, rồi `reconcile()`; `Future<NotificationTarget> handleTap(String entryKey, {int? relatedId})` — `reconcile()` **trước** (bảo đảm bản ghi đã tồn tại) → `ledger.byKey` → `history.markRead(historyId)` → trả `notificationTargetFor(...)` (R8)
- [X] T028 [US1] Sửa `lib/main.dart` + `lib/app.dart`: `WidgetsFlutterBinding.ensureInitialized()` rồi `ensureNotificationPresenter().init()` **trước** `runApp` (R13); trong `lib/app.dart`: đọc `launchPayload()` → đưa vào `NotificationTapRouter`; gọi `ensureNotificationEngine().reconcile()` **fire-and-forget** khi boot **và** ở **mỗi** `AppLifecycleState.resumed` — **không** chặn splash/`PinGate` (FR-024)
- [X] T029 [US1] Sửa `lib/core/app_shell.dart` + `lib/core/notification/notification_tap.dart`: sau khi shell đã dựng (**đã qua** `PinGate`/mở khoá) tiêu thụ payload **một lần** từ `NotificationTapRouter` → `await engine.handleTap(entryKey)` → `openNotificationTarget(...)`; mở khoá thất bại/huỷ ⇒ payload **không** được tiêu thụ và **không** vào màn đích (FR-019/AC#13)
- [X] T030 [P] [US1] Sửa `lib/screens/add_transaction_screen.dart`: sau khi `_repository.addTransaction(...)` thành công (dòng ~240) → gọi `ensureNotificationEngine().onTransactionSaved(at: ...)` **không** `await` (`unawaited`), lỗi nuốt bên trong engine — **không** đổi luồng lưu hiện có (FR-024/SC-012)
- [X] T031 [P] [US1] Sửa `lib/screens/scan/scan_confirm_screen.dart`: sau `addScannedTransaction(...)` (dòng ~217) → cùng lời gọi fire-and-forget (R4)
- [X] T032 [P] [US1] Sửa `lib/core/wallet/wallet_controller.dart`: sau `_repository.performTransfer(...)` (dòng ~104) → cùng lời gọi — transfer **không** tính vào ngân sách nhưng **có** tính là "đã ghi giao dịch hôm nay" (FR-011)
- [X] T033 [US1] Sửa `lib/screens/daily_reminder_config_screen.dart`: sau `_save()` (dòng ~90) → `ensureNotificationEngine().onPrefsChanged()` fire-and-forget ⇒ giờ/ngày mới **có hiệu lực ngay**, không cần mở lại app (FR-021/AC#16)
- [X] T034 [US1] Viết `test/notification_engine_test.dart` (fake presenter + fake ledger + fake history store + fake repository): đúng **1** thông báo + **đúng 1** bản ghi chưa đọc (FR-003/SC-007) và trần **200** vẫn đúng khi append liên tục (FR-029/AC#25); ngày **không** được chọn ⇒ 0 thông báo / 0 bản ghi (AC#4/SC-003); cờ bật + đã ghi hôm nay ⇒ **0/0** + `daily:<D>` `suppressed` — thử lần lượt **thu, chi, chuyển khoản** (AC#2/FR-011); cờ **tắt** + đã ghi ⇒ vẫn bắn, mô tả **không** khẳng định "chưa ghi" (AC#3); hoà giải: dòng sổ quá khứ chưa ghi ⇒ `history.append` với `created_at == scheduledFor` rồi `markHistoryWritten` (AC#1/J3); `reconcile()` trên DB cũ chỉ sinh dòng sổ cho mốc **tương lai** — **0** bắn bù (AC#24/N6–N7, FR-028); sổ **không bao giờ** chứa `recurringDue`/`goalReminder` (Q1=A/FR-002); cùng khoá ⇒ **cùng id** (FR-026 — thay thế, không xếp chồng); `handleTap` ⇒ `markRead` đúng `historyId` + trả đúng `NotificationTarget` cho cả 3 loại + 2 loại không có đích ⇒ `none`, `budgetAlert` thiếu `relatedId` ⇒ `none` (FR-018/FR-020); presenter/ledger cắm cờ lỗi ⇒ `onTransactionSaved` **không** ném ra ngoài (AC#21/FR-024); **tắt** công tắc ⇒ lần cuốn sau không sinh lịch của loại đó + `cancelKind` được gọi, **bật lại** ⇒ hoạt động lại (AC#15)

## Pha 4: User Story 2 — Cảnh báo ngân sách (Ưu tiên: P2)

**Mục tiêu**: Ngay sau khi lưu một giao dịch **chi** làm tổng chi của danh mục **vượt ngưỡng sớm** (mặc định 80%) → thông báo đúng mẫu 1 mockup `04` (icon cảnh báo **coral**, tiêu đề nêu tên danh mục, mô tả nêu **phần trăm** + **kỳ**) + 1 bản ghi chưa đọc; mỗi ngưỡng báo **tối đa 1 lần cho mỗi ngân sách trong mỗi kỳ** (bền qua đóng app/khởi động lại thiết bị); vượt mức (100%) có thông báo riêng diễn đạt **đã vượt**; đang mở **đúng** Chi tiết ngân sách đó ⇒ **không** bắn, **không** ghi.

**Tiêu chí kiểm thử độc lập**: Trên `NotificationEngine` với fake presenter/ledger/history + repository fake có ngân sách & giao dịch dựng sẵn ⇒ kiểm được toàn bộ luật ngân sách **không** cần UI (FR-012…FR-014, FR-016, SC-005, AC#5–#11).

- [X] T035 [US2] Thêm vào `lib/core/notification/notification_engine.dart` nhánh **cảnh báo ngân sách** trong `onTransactionSaved`: chỉ xét giao dịch **Chi** (chuyển khoản/điều chỉnh **không** tính — FR-014) → duyệt ngân sách **chưa lưu trữ** (`isArchived == false`) → mỗi ngân sách tính `%` = `budgetSpent(...)` của **kỳ chứa ngày giao dịch** (`budgetPeriodRange` + `budgetScopeCategoryIds` — **tái dùng nguyên hàm** PBI 20/21, không viết lại phép lọc) → so **2 ngưỡng đọc từ cấu hình đang lưu** (`budgetEarlyPercent`/`budgetOverPercent` — FR-012/FR-030) → ngưỡng **vừa vượt** **và** chưa có dòng sổ (`budgetEntryKey(budgetId, over:, periodStart:)`) ⇒ `presenter.show(OsNotification(id: notificationIdFor(key), …))` **ngay** + `history.append` + `ledger.upsert` (chống trùng **gắn với kỳ** — FR-013)
- [X] T036 [US2] Thêm vào `lib/core/notification/notification_engine.dart` luật **Q3** cho ngân sách: nếu `NotificationPresence.screen == 'budgetDetail'` **và** `presence.budgetId == budgetId` đang xét ⇒ **bỏ qua hoàn toàn** (0 thông báo, 0 bản ghi, **0** dòng sổ — AC#10); đang ở `budgetDetail` của **danh mục khác** hoặc màn khác ⇒ bắn bình thường (AC#11) — R9/FR-016
- [X] T037 [US2] Sửa `lib/screens/budget_detail_screen.dart`: `initState` khai báo hiện diện (`screen = 'budgetDetail'`, `budgetId = widget.budgetId`) + `dispose` xoá hiện diện (dùng `NotificationPresence` qua GetX — R9)
- [X] T038 [US2] Sửa `lib/screens/notification_settings_screen.dart`: sau **mỗi** lần `_store.save(...)` khi người dùng bật/tắt công tắc (dòng ~70 và ~84) → `ensureNotificationEngine().onPrefsChanged()` fire-and-forget ⇒ tắt công tắc **ngừng bắn ngay** (FR-021/AC#15)
- [X] T039 [US2] Bổ sung **nhóm ngân sách** vào `test/notification_engine_test.dart`: 78% → 82% ⇒ **1** thông báo + **1** bản ghi, câu chữ "sắp vượt" + tên danh mục + `82%` + kỳ (AC#5/FR-007); 82% → 89% → 95% → 99% ⇒ **0** bắn lặp cho ngưỡng sớm (AC#6/SC-005); vượt 104% ⇒ **đúng 1** cho ngưỡng vượt mức, câu chữ nói **đã vượt** (AC#7); giao dịch **Thu** / **chi ngoài kỳ** / **danh mục khác** ⇒ 0/0 (AC#8/FR-014); 2 ngân sách cùng vượt bằng **1** giao dịch ⇒ **2** thông báo + **2** bản ghi riêng (AC#9); đang mở đúng `budgetDetail` ⇒ 0/0, ở màn khác / budgetDetail danh mục khác ⇒ **vẫn bắn** (AC#10/#11); **tắt** công tắc ⇒ 0/0 rồi **bật lại** ⇒ ngưỡng **chưa từng báo trong kỳ** báo lại, ngưỡng **đã báo** trong kỳ **không** báo lại (AC#15/FR-021); sang **kỳ mới** ⇒ báo lại bình thường (biên "trùng ngưỡng ở kỳ mới"); dòng sổ **bền** qua `reconcile()` mới (mô phỏng đóng/mở app + khởi động lại — F1/F2/FR-013)
- [X] T040 [US2] Bổ sung **test điều hướng** vào `test/notification_engine_test.dart` (pump `MaterialApp` + `onSelectTab` giả): `handleTap('budget:early:<id>:<kỳ>')` ⇒ push **đúng** `BudgetDetailScreen` với `budgetId` của khoá; `budgetId` **không tồn tại** / ngân sách đã lưu trữ ⇒ **không** lỗi, **không** màn trắng, **không** khung "sắp có", bản ghi vẫn chuyển **đã đọc** (FR-020/F5/L6); `NotificationTarget.none` ⇒ **0** route, 0 SnackBar/dialog

## Pha 5: User Story 3 — Tổng kết tuần / tháng (Ưu tiên: P3)

**Mục tiêu**: Đến **Chủ nhật <giờ cấu hình>** (tuần) và **ngày cuối tháng <giờ cấu hình>** (tháng), app đóng vẫn có thông báo đúng mẫu 4 mockup `04` (icon biểu đồ tròn teal) với **số liệu của kỳ vừa kết thúc** + **so sánh kỳ liền trước** (nhiều hơn / ít hơn / tương đương, kèm %); kỳ rỗng vẫn bắn với câu chữ đúng; kỳ trước rỗng ⇒ **bỏ** câu so sánh; chạm → tab **Báo cáo** đã lọc sẵn kỳ; đang mở màn Báo cáo đúng lúc ⇒ **không** bắn, **không** ghi, **không** ghi bù khi rời màn.

**Tiêu chí kiểm thử độc lập**: Trên `NotificationEngine` (fake cả 3 seam) + repository fake có số liệu 2 kỳ liền nhau ⇒ kiểm được sinh mốc, nội dung so sánh, chống trùng theo tuần/tháng, Q3 — **không** cần UI (FR-009/FR-015/FR-016, SC-006, AC#18–#20).

- [X] T041 [US3] Thêm vào `lib/core/notification/notification_engine.dart` nhánh **tổng kết**: `weeklyEnabled` ⇒ mốc `nextWeeklySummaryMoment` (Chủ Nhật + giờ cấu hình), `monthlyEnabled` ⇒ mốc `nextMonthlySummaryMoment` (ngày cuối tháng + giờ) — **chỉ một mốc kế tiếp cho mỗi loại**, **tính lại nội dung ở mỗi lần `reconcile()`** (R3); số liệu + câu so sánh **tái dùng** `reportPeriodRange(ReportPeriod.week|month, anchor)` + `reportComparison`/câu insight của `lib/core/report/report_view.dart` (⇒ luật "kỳ trước rỗng ⇒ bỏ câu so sánh, không chia 0" **miễn phí** — FR-009/AC#18–#20); kỳ vừa kết thúc **rỗng** ⇒ vẫn sinh **một** mốc với câu chữ phản ánh đúng (AC#19); khoá `summary:week:<Thứ Hai đầu kỳ>` / `summary:month:<yyyy-MM>` ⇒ chống trùng 1 lần/tuần, 1 lần/tháng (FR-015/SC-006); mốc đã trôi qua **không** bắn bù (FR-028)
- [X] T042 [US3] Thêm vào `lib/core/notification/notification_engine.dart` luật **Q3** cho tổng kết: `onEnterRelatedScreen(String screen)` khi `screen == 'report'` ⇒ `presenter.cancel` mốc tổng kết đang chờ + `ledger.suppress(entryKey)` (AC#10/H3); `onLeaveRelatedScreen()` ⇒ `reconcile()` cuốn lịch lại **nhưng** mốc đã trôi qua **không** được ghi bù, mốc **tuần/tháng sau** được đăng ký lại (H4/FR-028)
- [X] T043 [US3] Sửa `lib/screens/report_screen.dart`: `ReportScreen` (đang `StatelessWidget`) → bọc `StatefulWidget` **mỏng** chỉ để khai báo/ngưng hiện diện `'report'` trong `initState`/`dispose` (qua `NotificationPresence`) — **không** đổi bố cục, không đổi chữ ký `onSelectTab`; các test hiện có của màn Báo cáo vẫn xanh (R9)
- [X] T044 [US3] Sửa `lib/core/notification/notification_tap.dart` (+ chỗ gọi ở `lib/core/app_shell.dart`): đích `reportTab` **chọn sẵn kỳ** — khi có thông tin tuần/tháng (chạm **từ thông báo**, khoá `summary:week:`/`summary:month:`) thì `ensureReportController().setPeriod(ReportPeriod.week|month)` **trước** `onSelectTab(2)` (FR-018/AC#12/G2: "Báo cáo đã lọc sẵn kỳ vừa tổng kết"); chạm **từ Trung tâm** (không có thông tin tuần/tháng trong `AppNotification`) ⇒ giữ nguyên hành vi PBI 30 (kỳ mặc định) — ghi nhận là **lệch có chủ ý 6** bổ sung vào `.specify/specs/31/quickstart.md` §5
- [X] T045 [US3] Bổ sung **nhóm tổng kết** vào `test/notification_engine_test.dart`: mốc tuần = Chủ Nhật giờ cấu hình, mốc tháng = **ngày cuối tháng** (thử 28/29/30/31 — AC#18/G3); nội dung **tính lại** sau khi có giao dịch mới (gọi `reconcile()` lần 2 ⇒ title/body mới — R3); đúng **1** thông báo/tuần và **1**/tháng sau nhiều lần `reconcile()` (SC-006); kỳ vừa kết thúc **rỗng** ⇒ vẫn **1** thông báo, câu chữ không có so sánh sai lệch (AC#19); **kỳ trước rỗng** ⇒ **0** "nhiều hơn ∞", **0** chia cho 0 (AC#20/G5); đang mở màn Báo cáo ⇒ 0/0 + dòng sổ `suppressed`, rời màn ⇒ mốc cũ **không** ghi bù + mốc kế tiếp được đăng ký (AC#10/H3–H4)

## Pha 6: User Story 4 — Quyền thông báo: hỏi 1 lần & dòng trạng thái (Ưu tiên: P4)

**Mục tiêu**: Lần **đầu tiên** mở Cài đặt → "Thông báo & nhắc nhở" (`01`): app hiện **lời giải thích trong app** (đồng ý / không đồng ý) **trước**; chỉ khi đồng ý mới gọi hộp thoại xin quyền của hệ điều hành; **không** hỏi lại ở các lần mở sau (dù kết quả nào). Khi quyền **không** được cấp ⇒ màn `01` có **đúng một** dòng trạng thái + lối mở cài đặt hệ điều hành, mọi công tắc/giá trị **giữ nguyên**; khi quyền đã cấp ⇒ màn **đúng mockup `01`**, 0 dòng thừa.

**Tiêu chí kiểm thử độc lập**: Pump `NotificationSettingsScreen` với `FakeNotificationStore` + `FakeNotificationPresenter` (cờ `permissionAsked`, `enabled`) ⇒ kiểm được soft-ask 1 lần + dòng trạng thái hiện/ẩn + giá trị cấu hình không đổi — **không** cần thiết bị (FR-017/FR-032, SC-018/SC-019, AC#27/#28).

- [X] T046 [US4] Mở rộng seam `lib/core/notification/notification_store.dart` thêm **2 hàm bổ sung** `Future<bool> permissionAsked()` / `Future<void> markPermissionAsked()` (row `AppSettings(key: 'notificationPermissionAsked')`, **không** migration) + impl trong `lib/data/notification_store_drift.dart` + cập nhật `test/fakes/fake_notification_store.dart` — **additive**, không đổi hành vi 6 hàm cũ (lệch nhỏ có chủ ý so với plan.md: giữ đúng **một** chỗ sở hữu cấu hình thông báo)
- [X] T047 [US4] Sửa `lib/screens/notification_settings_screen.dart`: lần mở màn **đầu tiên** (`permissionAsked() == false`) ⇒ hiện **hộp thoại giải thích trong app** (2 lựa chọn đồng ý / không đồng ý); **chỉ** khi đồng ý ⇒ `ensureNotificationPresenter().requestPermission()`; dù kết quả nào cũng `markPermissionAsked()` ⇒ **không** hỏi lại (FR-017/AC#27/SC-018) — **không** thêm màn onboarding mới, không hỏi ở màn `02`
- [X] T048 [US4] Thêm **dòng trạng thái quyền** vào `lib/screens/notification_settings_screen.dart`: đọc `presenter.areEnabled()` mỗi lần màn dựng; `false` ⇒ **đúng 1** dòng nêu thông báo đang bị tắt + nút gọi `presenter.openSettings()`; `true` ⇒ **0** dòng (đúng mockup `01`); việc hiện/ẩn **không** chạm giá trị công tắc/tham số (FR-032/AC#28/SC-019)
- [X] T049 [P] [US4] Thêm khoá dịch EN cho màn `01` vào nhánh `_en` của `lib/core/locale/sora_translations.dart` (lời giải thích, 2 nút đồng ý/không đồng ý, câu dòng trạng thái, nhãn nút mở cài đặt) rồi chạy `flutter test test/sora_translations_test.dart` — tên app **"Sora Thu Chi"** không dịch (N4)
- [X] T050 [US4] Sửa `test/notification_settings_screen_test.dart`: lần mở đầu ⇒ hộp thoại giải thích hiện **trước**, **chưa** gọi `requestPermission`; chọn **đồng ý** ⇒ `requestPermission` gọi **đúng 1 lần**; chọn **không đồng ý** ⇒ **không** gọi; mở lại màn nhiều lần ⇒ **không** hỏi lại (AC#27/SC-018); `areEnabled() == false` ⇒ **đúng 1** dòng trạng thái + nút gọi `openSettings()`, `true` ⇒ **0** dòng (AC#28); bật/tắt công tắc ⇒ giá trị cấu hình **không** bị dòng trạng thái làm đổi (SC-019)

## Pha cuối: Polish & Cross-cutting

- [X] T051 Chạy `flutter analyze` (phải sạch) + `flutter test` toàn bộ tại `app/sora_thu_chi/`; đối chiếu mốc T001 — **không tăng** số test đỏ so với baseline (1 đỏ có sẵn ở `transactions_dao_test`)
- [X] T052 Chạy `flutter build apk --release` (xác nhận proguard/desugaring không chặn plugin — bẫy proguard ML Kit PBI 24) + `flutter build ios --no-codesign` biên dịch được (P1/R14) — **APK release XANH** (212.9MB, desugaring + proguard OK). **Lệch**: máy thi công là **Windows** ⇒ Flutter **ẩn hẳn** lệnh `build ios` (`Could not find a subcommand named "ios"`), nên phần iOS **không chạy được ở đây** — cần chạy trên macOS. `ios/Runner/AppDelegate.swift` có sửa (thêm `UNUserNotificationCenter.delegate`) ⇒ **iOS chưa được biên dịch lần nào**.
- [ ] T053 Chạy QA tay nhóm **A–P** theo `.specify/specs/31/quickstart.md` §2 trên emulator — **gỡ app rồi cài lại** trước nhóm B (bẫy PBI 24/27: bản cài cũ thiếu plugin native ⇒ "0 thông báo, không lỗi"), dùng §1.2 (`adb dumpsys alarm`, `pm revoke/grant`, `sqlite3` đọc sổ + lịch sử) để kiểm lịch/quyền/sổ mà không phải chờ tới giờ; đối chiếu SC-001…SC-019
- [X] T054 Cập nhật `wiki-knowledge/` bằng skill `sora-wiki`: page **Hồ sơ & Bảo mật** (mục quyền thông báo + dòng trạng thái), **Lộ trình phát triển** (đóng mục ⚠ "engine bắn thông báo"), **Stack kỹ thuật** (3 package mới), `index.md` + append `wiki-knowledge/log.md`
- [X] T055 Rà soát cuối: **0** hex cứng ngoài `AppColors`/`SoraColors` trong `lib/core/notification/*` + `lib/screens/notification_settings_screen.dart`; coral **chỉ** ở kênh/icon cảnh báo ngân sách (FR-006/SC-001); xác nhận engine **không** gọi hàm ghi nào của 6 bảng nghiệp vụ (FR-023/SC-013) và **0** lời gọi mạng trong 3 package mới (FR-031/SC-017)

## Sơ đồ phụ thuộc

```text
Setup (T001–T004)  T001 → T002 → T003 ; T004 độc lập
   │
Foundational (T005–T024)
   ├─ T005 → T006
   ├─ T007 → T008
   ├─ T009, T012, T013, T014 độc lập
   ├─ T010 → T019 → T020 ; T012 → T019
   ├─ T011 → T013 → T022 ; T011 → T019
   ├─ T016 → T017 → T018 ; T016 → T019
   ├─ T021 (cần T010/T011/T016)
   └─ T023, T024 độc lập (native)
   │
US1 (T025–T034)  T025 → T026 → T027
   │             T028 (cần T011/T021/T025) ; T029 (cần T015/T027)
   │             T030, T031, T032, T033 (chỉ cần T027) ; T034 (cần T027)
   ▼
US2 (T035–T040)  T037 (presence) → T035 → T036 ; T038 độc lập → T039 → T040
   │
US3 (T041–T045)  T041 → T042 ; T043 độc lập ; T044 (cần T015/T041) → T045
   │
US4 (T046–T050)  T046 → T047 → T048 ; T049 độc lập ; T050 (cần T047/T048)
   ▼
Polish (T051–T055)
```

**Ghi chú**: US2/US3 đều **mở rộng cùng file** `lib/core/notification/notification_engine.dart` mà US1 tạo ⇒ ba story **không** chạy song song được trên cùng file; thứ tự P1 → P2 → P3 là bắt buộc về mặt kỹ thuật, không chỉ về ưu tiên. US4 **độc lập** với US1–US3 và có thể làm bất cứ lúc nào (chỉ chạm màn `01` + seam store) — nhưng trên Android 13+ muốn QA nhóm C–H phải **cấp quyền trước**, nên nếu chưa làm US4 thì dùng `adb shell pm grant $PKG android.permission.POST_NOTIFICATIONS` (quickstart §1.2).

## Ví dụ chạy song song

```text
# Setup — 3 nhánh khác file, chạy cùng lúc:
T002 [P] pubspec.yaml (+3 dependency)
T003 [P] android/app/build.gradle.kts (desugaring)
T004 [P] 3 drawable ic_notif_*.xml

# Foundational — nhóm thuần Dart / file riêng:
T005 [P] notification_schedule.dart        T006 [P] test/notification_schedule_test.dart
T007 [P] notification_content.dart         T008 [P] test/notification_content_test.dart
T009 [P] sora_translations.dart (khoá EN câu chữ thông báo)
T010 [P] notification_ledger.dart          T011 [P] notification_presenter.dart
T012 [P] test/fakes/fake_notification_ledger.dart
T013 [P] test/fakes/fake_notification_presenter.dart
T014 [P] notification_presence.dart
T018 [P] 6 file test đổi schemaVersion 9→10
T023 [P] AndroidManifest.xml               T024 [P] ios/Runner/AppDelegate.swift

# US1 — 4 điểm nối lưu giao dịch là 4 file khác nhau:
T030 [P] [US1] add_transaction_screen.dart
T031 [P] [US1] scan/scan_confirm_screen.dart
T032 [P] [US1] core/wallet/wallet_controller.dart
T033 [P] [US1] daily_reminder_config_screen.dart

# US4 — hai file độc lập:
T049 [P] [US4] sora_translations.dart (khoá EN màn 01)
```

## Chiến lược triển khai

- **MVP đề xuất**: **US1** (nhắc nhập giao dịch hằng ngày). Đây là lát cắt mang **toàn bộ** hạ tầng mới (bảng sổ v10 + 2 seam + engine + bootstrap + cấu hình native) và **kiểm thử độc lập được** bằng fake — đúng đòi hỏi cốt lõi của spec ("Trung tâm luôn rỗng trên máy thật" phải hết). QA MVP cần cấp quyền thông báo bằng `adb shell pm grant` nếu chưa làm US4.
- **Giao hàng tăng dần**:
  1. **US1** → hết "0 thông báo": nhắc hàng ngày bắn đúng giờ kể cả khi app đóng + bản ghi trong Trung tâm + tap → Thêm giao dịch.
  2. **+ US2** → cảnh báo ngân sách ngay sau khi lưu, chống trùng theo ngưỡng/kỳ ⇒ tính năng "nhắc nhở thông minh" đầu tiên có giá trị thật.
  3. **+ US3** → tổng kết tuần/tháng có số liệu so sánh ⇒ đủ 3/3 loại của Q1=A.
  4. **+ US4** → quyền thông báo đúng luồng (soft-ask + dòng trạng thái) ⇒ hoàn chỉnh PBI 31.
- **Thứ tự bắt buộc trong mỗi story**: chạy `build_runner` (T017) rồi `flutter analyze` **trước** khi viết impl drift (T019) và engine (T025); build release (T003) **sớm** vì desugaring thiếu là đỏ build ngay.
- **Lưu ý khi thi công**: (a) mọi lời gọi engine từ đường lưu giao dịch **không** `await` (FR-024/SC-012); (b) engine **chỉ đọc** dữ liệu nghiệp vụ — mọi phép tính tái dùng `budgetSpent`/`reportComparison`, **không** viết lại (FR-014/AC#18–20); (c) nội dung thông báo là **snapshot** theo ngôn ngữ lúc bắn, **không** `.tr` lại khi hiển thị từ lịch sử (FR-027, đồng bộ PBI 30); (d) mốc test đỏ có sẵn ở `transactions_dao_test.dart` **không** được tăng.
- **Sau khi xong**: commit bằng skill `git-commit` (Conventional Commits, tiếng Việt, **không** trailer `Co-Authored-By`), rồi chạy QA tay nhóm A–P (T053) và cập nhật wiki (T054).
