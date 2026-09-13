# Kế hoạch triển khai: Thông báo đẩy — engine bắn thông báo & nhắc nhở

**Mã PBI**: 31
**Liên kết spec**: [.specify/specs/31/spec.md](./spec.md)
**Ngày tạo**: 2026-09-13

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12 / Flutter 3.44 (Android + iOS), app **offline hoàn toàn** (không đăng nhập, không server, **không FCM**) |
| Framework / Thư viện chính | GetX `^4.7.3` (DI + i18n), Material. **Thêm 3 dependency** (lần đầu kể từ PBI 27): `flutter_local_notifications: ^22.3.1` · `timezone: ^0.11.1` · `flutter_timezone: ^5.1.0` (R1) |
| Lưu trữ dữ liệu | drift `^2.34.4` — **schema v9 → v10**: thêm **1 bảng** `NotificationLedger` (9 cột, thuần tạo, **không seed**) + `build_runner` sinh lại `app_database.g.dart`. Thêm **1 row** `AppSettings` (`notificationPermissionAsked` — không migration). **0** sửa/xoá bảng đang có |
| Kiểm thử | `flutter_test` — mốc trước PBI: **1100 pass + 1 test đỏ CÓ SẴN** (`transactions_dao_test`, từ PBI 11). Thêm **5 file test + 2 fake**, sửa **~6 file** (các file drift đổi `schemaVersion` 9→10, `notification_settings_screen_test`, `widget_test`). Host **có** sqlite native ⇒ test DAO/sổ chạy thật |
| Nền tảng triển khai | Build local (`flutter build apk` / iOS build). **Có cấu hình native lần đầu sau PBI 25**: manifest (quyền + 2 receiver) · gradle (**core library desugaring** — bắt buộc, hiện chưa bật ⇒ thiếu là đỏ build) · 3 vector drawable icon nhỏ · `ios/Runner/AppDelegate.swift` (R14) |
| Ràng buộc hiệu năng | FR-024/SC-012: lưu giao dịch **< 1 giây**, **0** lỗi hiện ra kể cả khi engine gặp sự cố ⇒ mọi tính toán của engine chạy **fire-and-forget sau** khi giao dịch đã ghi, bọc `try/catch`, **không** `await` ở đường đi nóng; hoà giải lúc boot cũng fire-and-forget (không chặn splash/`PinGate`) |
| Ràng buộc khác | Ngôn ngữ giao diện/tài liệu/commit: **tiếng Việt có dấu**; bám Design System (teal `#0F6E56` = thông báo thường, coral `#D85A30` **chỉ** ở cảnh báo chi tiêu — FR-006/SC-001; mọi màu qua token `AppColors`/`SoraColors`); **mọi khoá dịch mới phải có bản `_en`** (`sora_translations_test` quét `lib/`); nội dung thông báo & bản ghi là **snapshot nguyên văn** (không dịch lại — FR-027); engine **chỉ đọc** dữ liệu nghiệp vụ (FR-023) |
| Nguồn chân lý nghiệp vụ | `docs/notification/notification-solution.md` (§1 không FCM · §2 bảng 5 loại + tần suất + deep link · §3.2 cơ chế lên lịch · §3.3 quyền & giới hạn nền tảng) + mockup `docs/notification/04-mau-thong-bao-day.svg` (câu chữ + icon/màu) & `01-cai-dat-thong-bao.svg`; kế thừa PBI 28/29 (cấu hình + màn `01`/`02`), PBI 30 (bảng `notifications` + `NotificationHistoryStore` + **bảng đích điều hướng** theo loại), PBI 20/21 (`budgetPeriodRange`/`budgetScopeCategoryIds`/`budgetSpent`), PBI 22/26 (`reportComparison` + câu insight), PBI 19 (khoá dịch = chuỗi tiếng Việt), PBI 3 (khoá PIN) |

*Không còn mục `NEEDS CLARIFICATION`: spec đã "Đã làm rõ" (Q1=A · Q2=C · Q3=A
chốt 2026-09-13); các quyết định còn lại là chi tiết triển khai — xem
[research.md](./research.md) (R0…R17).*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

`.specify/memory/constitution.md` **không tồn tại** (repo chưa tạo hiến pháp) ⇒
đối chiếu theo `CLAUDE.md` của repo và các quyết định đã chốt trong `docs/`.

| Nguyên tắc (nguồn: CLAUDE.md + docs) | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline hoàn toàn, không server/không auth | ✅ | **0** lời gọi mạng, **0** FCM/đăng ký thiết bị (FR-001/FR-031/SC-017); "thông báo đẩy" = thông báo do **chính thiết bị** sinh ra |
| Ngôn ngữ giao diện/tài liệu/commit: tiếng Việt có dấu | ✅ | Câu chữ thông báo lấy từ mockup `04` (tiếng Việt) + bản `_en`; mọi tài liệu/comment tiếng Việt |
| Stack đã chốt (drift + GetX + fl_chart) | ⚠️ → ✅ | **Có thêm dependency** — nhưng đúng 3 package **đã được chốt trong `docs/tinh-nang…md §Stack`** ("Thông báo local: `flutter_local_notifications`") và `notification-solution.md` §3.2 (kèm `timezone`). **Không** dùng `workmanager`/`android_alarm_manager_plus` (R0 loại phương án chạy nền) |
| Design system: 1 màu thương hiệu teal, coral chỉ cho chi/cảnh báo, không hex cứng trong widget | ✅ | Coral **chỉ** ở kênh + icon cảnh báo ngân sách (FR-006); 2 kênh còn lại teal; màu lấy từ `AppColors`, **không** thêm token mới |
| Màn cấp tab có bottom nav, **màn con không** | ✅ | PBI này **không dựng màn mới**; màn `01` chỉ thêm **1 dòng trạng thái** (FR-032) — `SubPageScaffold` giữ nguyên |
| Số dư ví là đại lượng suy ra, không sửa tay | ✅ | Engine **không** chạm bảng `wallets` (FR-023) |
| Thu/chi/chuyển khoản: transfer không tính là thu/chi | ✅ | Cảnh báo ngân sách **chỉ** tính giao dịch **Chi** (`budgetSpent` — FR-014); nhưng transfer **có** tính là "đã ghi hôm nay" cho cờ FR-011 (đúng câu chữ spec) |
| Không sửa dữ liệu người dùng ngoài phạm vi | ✅ | Engine ghi **đúng 3 chỗ**: sổ `notification_ledger` (bảng mới của PBI này) · `notifications` (bảng PBI 30, qua đúng `append`/`markRead`) · 1 row `notificationPermissionAsked` trong `AppSettings`. **0** ghi vào 6 bảng nghiệp vụ (FR-023/SC-013) |
| Không phá vỡ hành vi PBI trước | ✅ | Chỉ **thêm** bảng + row; `NotificationPrefs`/`NotificationStore`/`NotificationHistoryStore` **không** đổi hợp đồng; màn `01`/`02` chỉ thêm 1 dòng trạng thái + 1 lần gọi engine sau khi lưu; 3 điểm lưu giao dịch chỉ thêm **1 dòng gọi fire-and-forget**; bảng điều hướng của màn Trung tâm được **tách hàm dùng chung** (không đổi hành vi) |
| YAGNI / không abstraction sớm | ⚠️ → ✅ | 7 file core mới là **đúng số seam cần thiết** (mỗi thứ chạm native/DB có seam ⇒ test được, bám nếp repo); **không** controller GetX cho engine (gọi hàm trực tiếp qua `ensure…`), **không** màn mới, **không** widget dùng chung mới, **không** token màu mới, **không** `contracts/`, **không** cơ chế chạy nền, **không** bảng thứ hai cho chống trùng (R6: 1 bảng làm 3 việc) |
| Quy trình PBI: spec → plan → task → implement | ✅ | Đang ở bước plan; `tasks.md` sinh ở bước sau |
| Wiki tri thức: đọc trước, cập nhật khi nghiệp vụ đổi | ✅ | Đã đọc [[Hồ sơ & Bảo mật]] + [[Lộ trình phát triển]] + [[Stack kỹ thuật]] + [[Design system]]; sau thi công sẽ **sync wiki** (PBI này **đóng** mục ⚠ "engine bắn thông báo" của Lộ trình) |

*Hai dòng ⚠️ đều đã có lý do nằm sẵn trong `docs/` (stack chốt plugin; seam là nếp
repo) ⇒ **không** có ngoại lệ vi phạm nguyên tắc.*

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại [research.md](./research.md). Tóm tắt các quyết định chính:

- **R0 — Ràng buộc gốc**: plugin **không chạy Dart** khi app đóng ⇒ **Quyết định**:
  ở lại **lịch của hệ điều hành** (FR-022: "app KHÔNG được yêu cầu chạy nền liên
  tục") + **sổ đăng ký trong drift** để ghi bù bản ghi. **Phương án khác**:
  `workmanager`/`android_alarm_manager_plus` (isolate nền + drift 2 connection) —
  **hoãn**, mở PBI riêng nếu cần.
- **R1 — Plugin**: `flutter_local_notifications` + `timezone` + `flutter_timezone`
  (thiếu package thứ 3 thì `tz.local` mãi là UTC ⇒ bắn sai giờ).
- **R2 — Nhắc hàng ngày**: **lịch một-lần cho từng mốc trong cửa sổ 30 ngày**,
  cuốn lại mỗi lần app chạy. Lý do: lặp `dayOfWeekAndTime` **không huỷ được 1 mốc**;
  lặp `time` **không lọc được ngày trong tuần**.
- **R3 — Tổng kết tuần/tháng**: **một-lần cho mốc kế tiếp**, tính lại nội dung mỗi
  lần app chạy (nội dung phải tươi — FR-009/AC#18–20); `dayOfMonthAndTime` không
  diễn tả được "ngày cuối tháng".
- **R4 — Cảnh báo ngân sách**: bắn **ngay sau khi lưu** giao dịch chi (doc §3.2),
  chỉ 3 điểm nối ghi giao dịch của app.
- **R5 — Cờ "chỉ nhắc nếu chưa ghi"**: **kiểm tra ở lúc LƯU** (huỷ lịch + đánh dấu
  chặn) — điều kiện chỉ lật được khi app đang mở ⇒ **không** cần chạy nền mà nội
  dung vẫn luôn đúng.
- **R6 — Bản ghi khi app đóng**: **1 bảng `notification_ledger`** + **hoà giải** ghi
  bù ở lần chạy kế tiếp với `created_at = mốc bắn`. **Không** ghi trước (chấm đỏ
  hiện sớm + seam PBI 30 cấm `delete`).
- **R7/R8 — Khoá & điều hướng**: khoá nghiệp vụ mang kỳ (`daily:2026-09-13`,
  `budget:over:3:2026-09-01`…) + id **FNV-1a** ổn định; payload = `entry_key`;
  điều hướng **tách hàm dùng chung** với màn Trung tâm (PBI 30) và chờ qua `PinGate`.
- **R9 — Q3**: dịch vụ `NotificationPresence` rất nhỏ + 2 màn khai báo hiện diện;
  cảnh báo ngân sách chặn ngay, tổng kết **huỷ mốc đang chờ** khi đang ở màn Báo cáo.
- **R10 — Quyền**: soft-ask **1 lần** ở màn `01` (cờ trong `AppSettings`), dòng
  trạng thái khi quyền bị tắt; `USE_EXACT_ALARM` + **lùi inexact** khi hệ thống từ
  chối (plugin **im lặng** khi bị từ chối exact alarm — bẫy chết người).
- **R11 — Kênh & icon**: 3 kênh Android + 3 vector drawable tự viết (icon nhỏ thông
  báo **buộc** là drawable đơn sắc).
- **R12 — Nội dung**: module thuần sinh câu chữ theo khoá dịch chuỗi-tiếng-Việt
  (PBI 19) + **tái dùng** `budgetSpent`/`reportComparison`/câu insight.
- **R13 — Bootstrap**: `main()` khởi tạo plugin (channel + timezone + tap callback);
  `app.dart` đọc launch details + hoà giải khi boot/resume.
- **R14 — Cấu hình native bắt buộc**: **desugaring** (đang thiếu ⇒ đỏ build) ·
  3 quyền · 2 receiver (thiếu ⇒ mất lịch sau reboot) · delegate iOS · 3 drawable.
- **R15 — Kiểm thử**: seam `NotificationPresenter` + `NotificationLedger` ⇒ toàn bộ
  luật nghiệp vụ test được **không cần plugin/thiết bị**.
- **R16/R17 — Xếp lớp & phạm vi**: 7 file core · 2 file data · 1 bảng drift · 3 điểm
  nối lưu giao dịch · 2 màn cấu hình · native; **không** làm 2 loại chưa có module,
  màn chỉnh ngưỡng, widget, backup JSON, `contracts/`.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem [data-model.md](./data-model.md) — bảng drift
  `NotificationLedger` (**schema v10**), `NotificationLedgerEntry` (9 trường),
  `OsSchedule` (hợp đồng với hệ điều hành), 2 seam mới (`NotificationLedger`,
  `NotificationPresenter`), **19 luật bất biến** + bảng vòng đời `suppressed`.
  **Không** sửa thực thể nào của PBI trước.
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app thuần nội bộ, không
  API/CLI/endpoint lộ ra ngoài (đồng nhất PBI 19–30). Hợp đồng nội bộ mới là 2 seam
  ở [data-model.md](./data-model.md) §6.
- **Kịch bản khởi động nhanh**: xem [quickstart.md](./quickstart.md) — **16 nhóm
  kiểm thử tay A–P** phủ FR-001…FR-032 và SC-001…SC-019 (kèm 6 lệnh `adb`/`sqlite3`
  để kiểm lịch, quyền, sổ, lịch sử mà không phải chờ tới giờ), mốc test trước PBI
  (**1100 pass + 1 đỏ có sẵn**) và **5 lệch có chủ ý** đã ghi nhận.

### Kiến trúc chi tiết

**1. Tầng nghiệp vụ thuần — `lib/core/notification/` (MỚI, 7 file)**

| File | Vai trò | Điểm neo |
|---|---|---|
| `notification_schedule.dart` | **Thuần**: cuốn cửa sổ 30 ngày cho nhắc hàng ngày · mốc kế tiếp của tổng kết tuần/tháng · khoá nghiệp vụ (`daily:`/`summary:`/`budget:`) · `notificationIdFor(key)` (FNV-1a 32-bit) · kỳ ngân sách của một giao dịch | R2/R3/R7 |
| `notification_content.dart` | **Thuần**: sinh `(title, body)` theo loại + số liệu + ngôn ngữ hiện hành; câu so sánh kỳ tái dùng `reportComparison`/insight | R12, FR-005…FR-009 |
| `notification_ledger.dart` | Thực thể `NotificationLedgerEntry` + **seam** đọc/ghi sổ | data-model §1, §6 |
| `notification_presenter.dart` | **Seam** bọc hệ điều hành (`schedule`/`show`/`cancel`/`cancelKind`/`areEnabled`/`requestPermission`/`openSettings`/`init`) + `OsNotification` | data-model §2, R15 |
| `notification_engine.dart` | **Điều phối**: `onTransactionSaved()` · `onPrefsChanged()` · `reconcile()` (hoà giải + cuốn lịch) · `onEnterRelatedScreen/onLeave` · `handleTap(entryKey)` | R4–R9 |
| `notification_presence.dart` | `RxString screen` + `RxInt budgetId` — dịch vụ hiện diện cho Q3 | R9 |
| `notification_tap.dart` | `openNotificationTarget(kind, relatedId, onSelectTab)` (**tách từ màn Trung tâm PBI 30** để dùng chung) + `NotificationTapRouter` giữ payload qua `PinGate` | R8, FR-018/FR-019 |

**2. Tầng dữ liệu — `lib/data/` + drift**

| File | Việc |
|---|---|
| `data/db/app_database.dart` | Thêm bảng `NotificationLedger` + `schemaVersion => 10` + nhánh `if (from < 10) createTable` |
| `data/notification_ledger_drift.dart` (MỚI) | Impl drift của seam sổ (upsert theo khoá, `dueBefore`, `markHistoryWritten`, `suppress`, `pruneBefore`) |
| `data/notification_presenter_plugin.dart` (MỚI) | Impl thật bọc `FlutterLocalNotificationsPlugin` (kênh, `zonedSchedule` một-lần, kiểm `canScheduleExactNotifications()` + lùi inexact, timezone từ `flutter_timezone`) |
| `data/notification_deps.dart` (SỬA) | Thêm `ensureNotificationLedger()`, `ensureNotificationPresenter()`, `ensureNotificationEngine()` (khuôn `ensureNotificationStore`) |

**3. Điểm nối (mỗi chỗ 1 dòng, fire-and-forget)**

| File | Việc |
|---|---|
| `screens/add_transaction_screen.dart` · `screens/scan/scan_confirm_screen.dart` | Sau khi ghi giao dịch thành công → `ensureNotificationEngine().onTransactionSaved()` (không `await`, bọc lỗi bên trong engine) |
| `core/wallet/wallet_controller.dart` | Sau `performTransfer` → cùng lời gọi (transfer **có** tính là "đã ghi hôm nay" — FR-011) |
| `screens/notification_settings_screen.dart` | **Soft-ask 1 lần** + **dòng trạng thái quyền** (FR-017/FR-032) + sau `save()` → `onPrefsChanged()` |
| `screens/daily_reminder_config_screen.dart` | Sau `save()` → `onPrefsChanged()` (FR-021: hiệu lực ngay) |
| `screens/budget_detail_screen.dart` · `screens/report_screen.dart` | `initState`/`dispose` khai báo/ngưng hiện diện (Q3) |
| `screens/notification_center_screen.dart` | Chỉ **đổi chỗ** hàm điều hướng sang `notification_tap.dart` (hành vi không đổi) |
| `main.dart` · `app.dart` | Khởi tạo plugin (kênh + timezone + tap callback) trước `runApp`; đọc launch details; hoà giải khi boot **và** mỗi `resumed` |
| `android/app/build.gradle.kts` · `android/app/src/main/AndroidManifest.xml` · `android/app/src/main/res/drawable/ic_notif_{bell,warning,summary}.xml` · `ios/Runner/AppDelegate.swift` | R14 |

**4. Luồng dữ liệu của một mốc (đường chuẩn)**

```
cấu hình/lưu giao dịch/mở app
   → reconcile(): dòng sổ quá khứ còn nợ bản ghi → historyStore.append(created_at = scheduled_for) → ghi history_id
   → cuốn lịch: sinh dòng sổ cho các mốc kế tiếp (cửa sổ 30 ngày với daily; mốc kế tiếp với tổng kết)
   → presenter.schedule(id = FNV(entry_key), …)   [huỷ lịch của khoá bị chặn]

lưu giao dịch CHI
   → tính % của kỳ ngân sách (budgetSpent) → 2 ngưỡng từ cấu hình
   → ngưỡng vừa vượt & chưa có dòng sổ → presenter.show(id) + append bản ghi + dòng sổ
   → (Q3) nếu đang mở đúng Chi tiết ngân sách đó → bỏ qua hoàn toàn

chạm thông báo
   → payload = entry_key → reconcile() → sổ tra history_id → markRead
   → (qua PinGate nếu có PIN) → openNotificationTarget(kind, relatedId, onSelectTab)
```

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline hoàn toàn | ✅ | Không có nhánh mạng nào trong 3 package mới (plugin local-only); SC-017 kiểm bằng chế độ máy bay (M5) |
| Tiếng Việt có dấu | ✅ | Câu chữ + comment + tài liệu tiếng Việt; khoá dịch mới có bản `_en` |
| Stack (drift + GetX) | ✅ | 3 package **đã chốt trong docs**; không thêm `workmanager`/`alarm_manager` (R0) |
| Design system | ✅ | Coral **chỉ** cảnh báo ngân sách (kênh + icon); không token mới; màn `01` chỉ thêm 1 dòng trạng thái |
| Không sửa dữ liệu người dùng ngoài phạm vi | ✅ | Chỉ ghi sổ + lịch sử + 1 row cờ quyền (M6 kiểm chứng) |
| Không phá vỡ hành vi PBI trước | ✅ | Hợp đồng 2 seam cũ giữ nguyên; 3 điểm lưu chỉ thêm 1 dòng gọi; tách hàm điều hướng là refactor thuần (test màn Trung tâm vẫn xanh) |
| YAGNI | ✅ | 1 bảng (3 việc) · 7 file core · 0 màn mới · 0 controller GetX · 0 `contracts/` · 0 bảng thứ hai |
| Quy trình PBI | ✅ | `tasks.md` ở bước kế tiếp |
| Wiki tri thức | ✅ | Sẽ sync `Hồ sơ & Bảo mật` + `Lộ trình phát triển` + `Stack kỹ thuật` + `log.md` sau thi công (đóng mục ⚠ engine) |

## Cấu trúc dự án dự kiến

```text
.specify/specs/31/
  spec.md · checklists/requirements.md            (đã có)
  plan.md · research.md · data-model.md · quickstart.md   (PBI này)
  tasks.md                                        (bước sau)

app/sora_thu_chi/
  pubspec.yaml                                     SỬA  (+3 dependency)
  lib/main.dart                                    SỬA  (ensureInitialized + khởi tạo plugin/timezone/kênh)
  lib/app.dart                                     SỬA  (launch details + hoà giải boot/resume)
  lib/core/notification/
    notification_schedule.dart                     MỚI (thuần)
    notification_content.dart                      MỚI (thuần)
    notification_ledger.dart                       MỚI (thực thể + seam)
    notification_presenter.dart                    MỚI (seam hệ điều hành)
    notification_engine.dart                       MỚI (điều phối)
    notification_presence.dart                     MỚI (Q3)
    notification_tap.dart                          MỚI (đích điều hướng dùng chung + router qua PIN)
    (app_notification.dart · notification_prefs.dart · notification_store.dart ·
     notification_history_store.dart)              KHÔNG ĐỔI
  lib/data/
    db/app_database.dart                           SỬA  (bảng NotificationLedger, schema v10)
    db/app_database.g.dart                         SINH LẠI (build_runner)
    notification_ledger_drift.dart                 MỚI
    notification_presenter_plugin.dart             MỚI
    notification_deps.dart                         SỬA  (+3 hàm ensure…)
  lib/screens/
    notification_settings_screen.dart              SỬA  (soft-ask + dòng trạng thái + onPrefsChanged)
    daily_reminder_config_screen.dart              SỬA  (onPrefsChanged)
    notification_center_screen.dart                SỬA  (dùng hàm điều hướng chung)
    add_transaction_screen.dart                    SỬA  (1 dòng gọi engine)
    scan/scan_confirm_screen.dart                  SỬA  (1 dòng gọi engine)
    budget_detail_screen.dart                      SỬA  (khai báo hiện diện Q3)
    report_screen.dart                             SỬA  (khai báo hiện diện Q3)
  lib/core/wallet/wallet_controller.dart           SỬA  (1 dòng gọi engine)
  lib/core/locale/sora_translations.dart           SỬA  (khoá dịch mới cho câu chữ thông báo + màn 01)

  android/app/build.gradle.kts                     SỬA  (core library desugaring — BẮT BUỘC)
  android/app/src/main/AndroidManifest.xml         SỬA  (3 quyền + 2 receiver)
  android/app/src/main/res/drawable/ic_notif_bell.xml      MỚI (vector, đơn sắc)
  android/app/src/main/res/drawable/ic_notif_warning.xml   MỚI
  android/app/src/main/res/drawable/ic_notif_summary.xml   MỚI
  ios/Runner/AppDelegate.swift                     SỬA  (UNUserNotificationCenter delegate)

  test/notification_schedule_test.dart             MỚI
  test/notification_content_test.dart              MỚI
  test/notification_engine_test.dart               MỚI
  test/notification_ledger_drift_test.dart         MỚI
  test/fakes/fake_notification_ledger.dart         MỚI
  test/fakes/fake_notification_presenter.dart      MỚI
  test/notification_settings_screen_test.dart      SỬA
  test/*_dao_test.dart · *_store_drift_test.dart · widget_test.dart   SỬA (schemaVersion 9→10)
```

## Rủi ro & ngoại lệ có lý do

### Ngoại lệ có lý do

1. **Thêm 3 dependency** (lần đầu kể từ PBI 27) — không phải mở rộng stack mà là
   **thực thi đúng stack đã chốt** trong `docs/tinh-nang…md §Stack` và
   `notification-solution.md` §3.2. PBI 28/30 đã hoãn đúng phần này.
2. **Nội dung bản ghi Trung tâm không được ghi cùng khoảnh khắc với thông báo khi
   app đóng** — FR-003 nói "đồng thời", nhưng hệ điều hành không chạy Dart (R0).
   Ghi bù ở lần mở app kế tiếp với `created_at = mốc bắn` ⇒ **quan sát được là như
   nhau** với người dùng (nhãn thời gian, nhóm ngày, chấm đỏ, mục "bỏ lỡ rồi xem
   lại" đều đúng). Đánh đổi để giữ FR-022 ("app KHÔNG được yêu cầu chạy nền liên
   tục") — phương án chạy nền bị **loại có ghi nhận** (R0).
3. **`USE_EXACT_ALARM` thay vì xin `SCHEDULE_EXACT_ALARM`** — app phát hành qua
   GitHub Releases (`docs/publish/`), không qua Play, nên ràng buộc chính sách Play
   không áp dụng; đổi lại **không** thêm một luồng quyền ngoài spec Q2=C. Vẫn kiểm
   `canScheduleExactNotifications()` + lùi inexact để không chết im lặng.
4. **Cửa sổ 30 ngày cho nhắc hàng ngày** thay vì lặp vô hạn — cái giá **bắt buộc**
   để huỷ được đúng một mốc (cờ "chỉ nhắc nếu chưa ghi" — R5/AC#2). Hệ quả: người
   dùng không mở app > 30 ngày thì hết nhắc (đã ghi ở quickstart §5).

### Rủi ro & ứng phó

| Rủi ro | Mức | Ứng phó |
|---|---|---|
| **Thiếu core library desugaring** ⇒ build release đỏ ngay | Cao (chắc chắn xảy ra) | Việc **đầu tiên** của nhánh native (R14); `flutter build apk --release` là bước bắt buộc ở quickstart A4 |
| **R8/proguard chặn lớp của plugin** (tiền lệ ML Kit PBI 24) | Trung bình | FLN v19+ tự mang consumer rules; **kiểm chứng bằng build release thật**, không suy luận |
| **Thiếu 2 receiver** ⇒ mất toàn bộ lịch sau reboot (AC#17/SC-010 đỏ) | Trung bình | Đưa vào checklist A5 (`dumpsys package` kiểm quyền + receiver) và J2 (khởi động lại thật) |
| **Từ chối exact alarm ⇒ plugin im lặng, không lịch, không lỗi** | Trung bình | `canScheduleExactNotifications()` + lùi `inexactAllowWhileIdle` (R10); QA nhóm A/J kiểm `dumpsys alarm` |
| **`dumpsys alarm` bị nhà sản xuất ẩn/đổi** ⇒ QA nhóm C4/K1 khó kiểm | Thấp | Đã có đường thay thế: đặt giờ nhắc = bây giờ + 2 phút và quan sát thực tế |
| **QA tay phụ thuộc việc đổi giờ/ngày thiết bị** (mốc tuần/tháng) | Trung bình | Cho phép lùi/tiến ngày trong emulator (tắt "giờ tự động"); ca khó dựng (mốc cuối tháng 28/29/30/31, cuốn cửa sổ, câu chữ) đã **chuyển sang test tự động** (§3 quickstart) |
| **Engine làm chậm/đỏ luồng lưu giao dịch** | Cao nếu `await` | Mọi lời gọi từ đường lưu là **fire-and-forget** + `try/catch` **bên trong** engine; QA M2 (10 lần lưu liên tiếp) + AC#21 |
| **Drift bị 2 nơi ghi đồng thời** (hoà giải + lưu giao dịch) | Thấp | Cùng một process, cùng một `AppDatabase` singleton (`ensureWalletRepository`/`ensureNotificationLedger` dùng chung connection — bám nếp `ensure…` của repo) |
| **Cài lại app đè lên bản cũ thiếu plugin mới** ⇒ "0 thông báo, không lỗi" | Trung bình | Cảnh báo rõ ở quickstart §1: **gỡ app rồi cài lại**, ghi lại số liệu cần đối chiếu trước |
| **Nội dung tổng kết cũ** nếu app không mở suốt kỳ | Thấp | R3 + quickstart §5 lệch 3; trên thực tế giao dịch chỉ phát sinh khi app mở |
| **iOS chưa QA** | Thấp | Tiền lệ 3 PBI gần nhất; chỉ bắt buộc `flutter build ios --no-codesign` xanh |
| **Múi giờ thiết bị đổi** ⇒ lịch đã đăng ký sai giờ | Thấp | Đăng ký lại lịch mỗi lần app chạy + `tz.setLocalLocation` lúc boot; QA nhóm O |
