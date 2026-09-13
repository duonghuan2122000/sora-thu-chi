# Nghiên cứu kỹ thuật: Thông báo đẩy — engine bắn thông báo & nhắc nhở

**Mã PBI**: 31
**Liên kết spec**: [spec.md](./spec.md)
**Ngày tạo**: 2026-09-13

> Spec đã "Đã làm rõ" (Q1=A · Q2=C · Q3=A — chốt 2026-09-13) ⇒ **không còn
> `NEEDS CLARIFICATION`**. Các mục dưới đây là quyết định triển khai còn lại.
>
> Nguồn chân lý nghiệp vụ: `docs/notification/notification-solution.md`
> (§1 không FCM · §2 bảng 5 loại + tần suất · §3.2 cơ chế lên lịch · §3.3 quyền &
> giới hạn nền tảng · §5 luồng) + mockup `04-mau-thong-bao-day.svg` (câu chữ +
> icon/màu theo loại). Điểm nối đã có: PBI 28/29 (cấu hình) · PBI 30 (bảng
> `notifications` + `NotificationHistoryStore` + điều hướng theo loại).

---

## R0 — Ràng buộc gốc quyết định mọi thứ còn lại: **không có Dart khi app đóng**

- **Sự thật kỹ thuật**: `flutter_local_notifications` (FLN) **không chạy mã Dart**
  lúc thông báo tới giờ. Cả `zonedSchedule` lặp lẫn một-lần đều do **hệ điều hành**
  bắn; app đóng thì **không có nhánh Dart nào chạy** để (a) kiểm tra điều kiện,
  (b) tính lại số liệu, (c) ghi bản ghi vào Trung tâm.
- **Hệ quả trực tiếp lên spec**: FR-003 (bắn thông báo **và** ghi bản ghi "đồng
  thời"), FR-009 (nội dung tổng kết phải nêu **đúng** số liệu kỳ vừa kết thúc),
  FR-011 (kiểm tra "hôm nay đã ghi giao dịch chưa" **trước khi** bắn).
- **Hai đường đi**:
  - **(A)** Thêm cơ chế chạy nền Dart (`workmanager` / `android_alarm_manager_plus`)
    → mở drift trong **isolate thứ hai**, dựng lại `GetX`/`Get.locale`/store trong
    isolate nền, thêm 1 dependency nặng + quyền nền + rủi ro "database is locked"
    giữa 2 connection cùng file. Đổi lại: tính đúng ngay tại thời điểm bắn.
  - **(B)** Ở lại **thuần lịch của hệ điều hành** + **sổ đăng ký (ledger) trong
    drift** làm bộ nhớ bù: mọi mốc đã lên lịch đều có một dòng sổ; lần app chạy kế
    tiếp **hoà giải** (ghi bản ghi lịch sử cho mốc đã qua rồi tiến mốc kế tiếp).
- **Quyết định**: **(B)** — và mọi quyết định dưới đây được thiết kế để **điều kiện
  được kiểm tra trong lúc app đang mở, ở thời điểm sớm nhất có thể** thay vì lúc
  bắn (R4/R12), còn phần "ghi bản ghi" thì hoà giải bù (R6). **Lý do**: FR-022 nói
  rõ *"app KHÔNG được yêu cầu chạy nền liên tục"*; doc §3.2 cũng đã chốt
  `zonedSchedule` + `matchDateTimeComponents`; app này **offline, một người dùng,
  một tiến trình** — dựng tầng nền thứ hai cho 3 loại thông báo là cái giá lớn hơn
  nhiều so với giá trị, và là nguồn lỗi khó tái hiện (isolate nền + sqlite).
  **Phương án khác**: (A) (đã nêu trên) — **hoãn**; nếu sau này cần "đúng số liệu
  tại thời điểm bắn" cho người dùng mở app < 1 lần/kỳ thì mở PBI riêng.

---

## R1 — Plugin: **3 dependency mới** (lần đầu thêm package kể từ PBI 27)

- **Quyết định**: `flutter_local_notifications: ^22.3.1` (yêu cầu Flutter ≥ 3.38.1;
  toolchain hiện tại 3.44.6 ✓) · `timezone: ^0.11.1` · `flutter_timezone: ^5.1.0`.
- **Lý do**: FLN là thư viện đã được chốt trong `docs/tinh-nang…md §Stack` và
  `notification-solution.md` §3.2; `timezone` là dependency **bắt buộc** của
  `zonedSchedule` (FLN không tự biết múi giờ thiết bị); `flutter_timezone` là cách
  duy nhất lấy **tên IANA** của múi giờ thiết bị — `package:timezone` nói rõ việc
  tra cứu múi giờ thiết bị *"highly platform dependent and is not a goal of this
  package"*, nên nếu không có nó thì `tz.local` mãi là **UTC** ⇒ bắn sai giờ.
- **Phương án khác**: (a) `workmanager`/`android_alarm_manager_plus` (xem R0);
  (b) viết channel native Android + iOS tự đặt alarm (bỏ Flutter plugin) — mất
  tính đa nền tảng, phải tự viết BootReceiver/UNUserNotificationCenter, nhiều code
  native hơn toàn bộ PBI này; (c) `shared_preferences` để lưu cờ — **không** cần
  (đã có bảng `AppSettings`).

## R2 — Nhắc hàng ngày: **một-lần cho từng mốc trong cửa sổ 30 ngày**

- **Quyết định**: mỗi ngày được chọn (T2…CN) sinh **các lịch một-lần**
  (`zonedSchedule`, không lặp) cho **30 ngày kế tiếp**; mỗi mốc là một dòng sổ +
  một thông báo hệ điều hành với id cố định theo `(daily, ngày)`.
- **Lý do**: FLN có `matchDateTimeComponents.dayOfWeekAndTime` (lặp hằng tuần) —
  nội dung **tĩnh** nên lặp được — **nhưng** lặp hằng tuần **không huỷ được một
  mốc duy nhất**: đúng kịch bản AC#2/cờ "chỉ nhắc nếu chưa ghi" (người dùng ghi
  giao dịch lúc 15:00, phải hủy nhắc 20:30 **hôm nay**, mà **không** được mất các
  tuần sau). Huỷ rồi đăng ký lại lặp cùng thứ trong ngày hôm đó sẽ **bắn lại đúng
  20:30 hôm nay** (`dayOfWeekAndTime` tính mốc kế tiếp = hôm nay nếu giờ chưa
  qua). Một-lần cho từng mốc giải quyết triệt để: huỷ 1 mốc = huỷ 1 lịch, không
  dính gì tới mốc khác.
- **Vì sao 30 ngày**: cửa sổ phải đủ dài để người dùng **không mở app vài tuần**
  vẫn được nhắc (FR-022/SC-002/SC-010 — app đóng, kể cả sau khởi động lại), mà
  vẫn ≤ 30 lịch một-lần (giới hạn ~500 alarm của Android; 30 là rất xa ngưỡng);
  mỗi lần app chạy (mở/resume/đổi cấu hình/lưu giao dịch) **cửa sổ được cuốn lại**.
- **Đánh đổi đã biết**: người dùng **không mở app suốt > 30 ngày** thì các mốc
  sau đó không còn lịch ⇒ mất nhắc. Ghi vào mục rủi ro của plan; đây là người
  dùng đã bỏ app (không ghi giao dịch nào) nên không phải ca nghiệp vụ thật.
- **Phương án khác**: (a) lặp `dayOfWeekAndTime` — không huỷ được 1 mốc (lý do
  trên); (b) lặp `time` (hằng ngày) — **không lọc được ngày trong tuần** (AC#4
  đỏ ngay); (c) chạy nền kiểm tra (R0-A).

## R3 — Tổng kết tuần/tháng: **một-lần cho mốc kế tiếp, cuốn lại mỗi lần app chạy**

- **Quyết định**: chỉ đăng ký **mốc kế tiếp** (`Chủ nhật <giờ>` / `ngày cuối
  tháng <giờ>`), đăng ký lại (kèm **tính lại nội dung**) mỗi lần app chạy và mỗi
  lần có giao dịch mới.
- **Lý do**: FR-009 + AC#18–20 **kiểm tra bằng số** — nội dung phải là số liệu của
  **kỳ vừa kết thúc**. `matchDateTimeComponents` lặp sẽ **đóng băng câu chữ tại
  lúc lên lịch**: tổng kết tháng 10 sẽ hiển thị số của tháng 8. Một-lần + cuốn lại
  ⇒ nội dung luôn được tính lại ở lần app chạy gần nhất. Với app thu chi (người
  dùng mở gần như hằng ngày), mức "cũ" tối đa là các giao dịch của những ngày sau
  lần mở cuối — và chính những giao dịch đó chỉ phát sinh **khi app đang mở** ⇒
  trên thực tế nội dung luôn khớp.
- **Không dùng `dayOfMonthAndTime`**: ngày cuối tháng đổi theo tháng (28/29/30/31)
  — biểu thức đó không diễn tả được.
- **Phương án khác**: (a) lặp `dayOfWeekAndTime` cho tuần (nội dung cũ — lý do
  trên); (b) lặp `dayOfMonthAndTime` = ngày 1 tháng sau (khác FR-015 "ngày cuối
  tháng"); (c) chạy nền (R0-A).

## R4 — Cảnh báo ngân sách: **bắn ngay sau khi lưu giao dịch chi** (không theo giờ)

- **Quyết định**: sau khi giao dịch **chi** được lưu, engine (fire-and-forget)
  đọc ngân sách + giao dịch, tính `%` của **kỳ ngân sách chứa giao dịch**, so với
  **2 ngưỡng đọc từ cấu hình**, và với mỗi ngưỡng **vừa vượt mà chưa có dòng sổ**
  → `show()` ngay + ghi bản ghi + ghi dòng sổ (chống trùng).
- **Lý do**: doc §3.2 chốt đúng cách này ("tính toán ngay trong transaction lưu
  giao dịch"); dữ liệu để tính chỉ tồn tại **sau** khi giao dịch được ghi; không
  có mốc thời gian nào để lên lịch trước.
- **Điểm nối**: 3 chỗ ghi giao dịch duy nhất của app —
  `lib/screens/add_transaction_screen.dart` (`addTransaction`),
  `lib/screens/scan/scan_confirm_screen.dart` (`addScannedTransaction`),
  `lib/core/wallet/wallet_controller.dart` (`performTransfer` — không tính vào
  ngân sách nhưng **có tính** là "đã ghi giao dịch hôm nay" theo FR-011).
  **Chỉ 3 chỗ** ⇒ gọi trực tiếp, **không** nhét engine vào tầng repository.
- **Phương án khác**: móc vào `WalletRepository` (buộc tầng data biết engine —
  đảo chiều phụ thuộc, và mọi test repository phải mang theo engine); stream
  `watch` của drift (mở một cơ chế mới cho 1 nhu cầu).

## R5 — Cờ "chỉ nhắc nếu chưa ghi": **kiểm tra ở lúc LƯU, không phải lúc bắn**

- **Quyết định**: khi lưu **bất kỳ** giao dịch nào (thu/chi/chuyển khoản) trong
  ngày `D`, engine **huỷ các lịch nhắc của ngày `D`** và đánh dấu dòng sổ tương
  ứng là **bị chặn (suppressed)** ⇒ không bắn, không ghi bản ghi.
- **Lý do**: điều kiện "hôm nay đã ghi giao dịch chưa" **chỉ có thể đổi thành
  "đã ghi" khi app đang mở** (ghi giao dịch là thao tác trong app). Nghĩa là tại
  thời điểm duy nhất điều kiện có thể lật, engine **đang chạy** và biết chắc kết
  quả ⇒ **không cần** chạy nền để kiểm tra. Nội dung tĩnh "Bạn chưa ghi giao dịch
  nào hôm nay." nhờ vậy **luôn đúng theo cấu trúc**, không phải phỏng đoán.
- **Hệ quả (đã ghi nhận)**: nếu người dùng **xoá/sửa** giao dịch đó sau giờ nhắc
  thì mốc hôm đó vẫn ở trạng thái chặn — chấp nhận được (spec: sửa/xoá **không**
  hồi tố, và AC#2 chỉ đòi "đã ghi ≥ 1 giao dịch ⇒ không bắn").
- **Phương án khác**: chạy nền để đọc DB tại 20:30 (R0-A); thêm cột "đã ghi hôm
  nay" (dữ liệu phái sinh — trái nguyên tắc "số dư là đại lượng suy ra").

## R6 — Bản ghi Trung tâm khi app đóng: **sổ đăng ký + hoà giải**

- **Quyết định**: **1 bảng drift mới** `notification_ledger` (schema **v10**,
  thuần tạo, không seed) — mỗi **mốc đã lên lịch / đã bắn** là **một dòng**, giữ
  `title`/`body` (snapshot), `scheduled_for`, `suppressed`, `history_written_at?`,
  `history_id?`. Hàm **hoà giải** chạy khi app khởi động, khi resume, sau khi lưu
  giao dịch và sau khi đổi cấu hình: mọi dòng `scheduled_for <= now`,
  `suppressed = false`, `history_written_at IS NULL` → `append` vào bảng
  `notifications` (PBI 30) với `created_at = scheduled_for` (⇒ nhãn thời gian và
  nhóm "HÔM NAY / TUẦN NÀY" **đúng như lúc bắn**), rồi ghi lại `history_id`.
- **Lý do**: FR-003 đòi "có thông báo thì có bản ghi"; khi app đóng, **cách duy
  nhất** để bản ghi xuất hiện mà không có tiến trình nền là **ghi bù ở lần chạy
  kế tiếp**. Bản ghi mang `created_at` = **mốc bắn** nên người dùng **không phân
  biệt được** với việc ghi tại chỗ (mục "bỏ lỡ rồi xem lại" của spec hoạt động
  nguyên vẹn).
- **Vì sao không ghi trước lúc lên lịch**: (a) chấm đỏ trên chuông sẽ hiện **trước
  khi** thông báo bắn (mở app 15:00 thấy bản ghi 20:30); (b) huỷ (R5) phải **xoá**
  bản ghi, mà seam `NotificationHistoryStore` của PBI 30 **cố ý không có `delete`**
  (spec PBI 30 cấm) ⇒ ghi trước là ngõ cụt.
- **Sổ cũng là bộ nhớ chống trùng** (FR-013) và là chỗ tra `entry_key` để đánh dấu
  đã đọc khi người dùng chạm thông báo (R8) — **một** bảng làm 3 việc, thay vì 3
  bảng nhỏ.
- **Dọn sổ**: khi hoà giải, xoá dòng `scheduled_for < now − 90 ngày` đã xử lý xong
  (giữ biên rộng hơn mọi kỳ ngân sách đang có ⇒ không bao giờ mất khoá chống
  trùng của kỳ hiện tại).
- **Phương án khác**: 2–3 bảng riêng (`series` + `fires`) — nhiều đường ghi, nhiều
  bất biến phải giữ đồng bộ; `pendingNotificationRequests()` của plugin làm nguồn
  sự thật — tài liệu plugin **không cam kết** độ tin cậy, và nó không mang
  `title`/`body`/khoá nghiệp vụ nên vẫn phải có sổ.

## R7 — Khoá chống trùng & id thông báo: **khoá nghiệp vụ tường minh + FNV-1a**

- **Định dạng khoá**:
  - nhắc hàng ngày: `daily:<yyyy-MM-dd>` (ngày **địa phương** của mốc);
  - tổng kết: `summary:week:<yyyy-MM-dd>` (Thứ Hai đầu kỳ) · `summary:month:<yyyy-MM>`;
  - ngân sách: `budget:early:<budgetId>:<kỳ>` · `budget:over:<budgetId>:<kỳ>` với
    `<kỳ>` = `yyyy-MM-dd` của **đầu kỳ ngân sách** (`budgetPeriodRange`).
- **Id thông báo hệ điều hành** = **FNV-1a 32-bit** của khoá (hàm 5 dòng, tự viết).
  **Lý do**: Android định danh thông báo bằng `int`; id **phải ổn định qua các lần
  chạy app** để `cancel(id)` huỷ đúng cái đã đăng ký. `String.hashCode` của Dart
  **không** được cam kết ổn định giữa các phiên bản SDK ⇒ tự viết 5 dòng an toàn
  hơn là tin vào chi tiết cài đặt.
- **FR-026 (thay thế, không xếp chồng) thoả tự nhiên**: cùng khoá ⇒ cùng id ⇒
  thông báo mới **đè** thông báo cũ trên màn hình khoá; mà chống trùng (R6) đã bảo
  đảm mỗi khoá chỉ bắn **một lần** trong kỳ.

## R8 — Chạm thông báo: **payload = khoá sổ**, dùng lại map điều hướng của PBI 30

- **Quyết định**: payload của thông báo hệ điều hành là **`entry_key`** (không
  phải `history_id` — bản ghi lịch sử ra đời **sau** khi lịch được đăng ký, xem
  R6). Khi người dùng chạm: engine **hoà giải trước** (để chắc bản ghi đã tồn tại),
  rồi tra sổ theo `entry_key` → `history_id` → `markRead`; rồi điều hướng.
- **Điều hướng**: bảng đích **đã có sẵn** ở `NotificationCenterScreen._navigate`
  (PBI 30): `dailyReminder` → màn Thêm giao dịch · `budgetAlert` → Chi tiết ngân
  sách **đúng `relatedId`** · `periodSummary` → tab Báo cáo + `onSelectTab(2)`.
  ⇒ **tách hàm dùng chung** `openNotificationTarget(kind, relatedId, onSelectTab)`
  để màn Trung tâm và engine **dùng chung một bảng** (0 bản sao thứ hai của luật
  FR-018/FR-020).
- **Cold start + PIN (FR-019)**: app đóng → chạm thông báo → `getNotificationAppLaunchDetails()`
  cho payload; app **vẫn đi qua `PinGate`** như mọi lần mở (PIN nếu có). Payload
  được giữ ở `NotificationTapRouter` (biến tĩnh trong `lib/core/notification/`) và
  **chỉ** được tiêu thụ **sau khi** `AppShell` đã dựng (tức đã qua mở khoá) — mở
  khoá thất bại/huỷ ⇒ payload **không** được dùng (FR-019).
- **Phương án khác**: đẩy `history_id` vào payload (bất khả thi về thứ tự — R6);
  `Get.toNamed` (app dùng `Navigator` trực tiếp, không có route table).

## R9 — Q3 "đang ở đúng màn liên quan": **1 dịch vụ hiện diện rất nhỏ**

- **Quyết định**: `NotificationPresence` — `RxString screen` + `RxInt budgetId`,
  đăng ký qua GetX; **chỉ 2 màn** tự khai báo trong `initState`/`dispose`:
  `BudgetDetailScreen` (`screen='budgetDetail'`, `budgetId`) và `ReportScreen`
  (`screen='report'`). App dùng `Navigator` trực tiếp nên `Get.currentRoute`
  **không** dùng được.
- **Luật**:
  - **Cảnh báo ngân sách** (bắn ngay, đồng bộ): đang ở `budgetDetail` **đúng
    `budgetId`** ⇒ **không** bắn, **không** ghi bản ghi (AC#10); màn khác ⇒ bắn
    bình thường (AC#11).
  - **Tổng kết** (theo giờ): vào màn Báo cáo ⇒ **huỷ** mốc tổng kết đang chờ +
    đánh dấu dòng sổ **suppressed**; rời màn ⇒ cuốn lịch lại (mốc đã trôi qua
    **không** ghi bù) ⇒ đúng AC#10, không lệch nhịp nào.
  - **Nhắc hàng ngày**: Q3 **không** áp dụng (màn đích là "Thêm giao dịch" — mở
    đúng màn đó lúc 20:30 vẫn bắn theo nghĩa vụ nhắc; spec chỉ nêu ví dụ ngân sách
    và tổng kết).
- **Phương án khác**: `RouteObserver`/`RouteAware` (đúng chuẩn Flutter nhưng cần
  đăng ký observer ở `GetMaterialApp.navigatorObservers` + mỗi màn
  subscribe/unsubscribe — nhiều dây hơn cho đúng 2 màn); suy từ `Navigator` stack
  (không có API công khai ổn định).

## R10 — Quyền thông báo: **soft-ask 1 lần ở màn 01 + dòng trạng thái**

- **Quyết định**: cờ "đã hỏi" lưu bằng **row mới trong `AppSettings`**
  (`notificationPermissionAsked = 'true'`) — **không** migration (bảng key-value,
  bám PBI 17/24/28). Màn `01` lần đầu mở: hiện hộp thoại giải thích trong app
  (đồng ý / không đồng ý); chỉ khi **đồng ý** mới gọi
  `requestNotificationsPermission()` (Android 13+) / `requestPermissions` (iOS).
  Sau đó **không hỏi lại** bất kể kết quả (FR-017/SC-018).
- **Dòng trạng thái (FR-032)**: hiện khi `areNotificationsEnabled() == false`
  (Android) / `checkPermissions()` (iOS); có nút mở **cài đặt thông báo của hệ
  điều hành**; **không** chạm giá trị công tắc/tham số. Trạng thái quyền đọc lại
  mỗi lần màn `01` được mở (app resume ⇒ màn dựng lại ⇒ đọc lại).
- **Exact alarm**: khai báo **`USE_EXACT_ALARM`** (targetSdk ≥ 33, không cần hỏi
  người dùng) + vẫn kiểm `canScheduleExactNotifications()` và **lùi về
  `AndroidScheduleMode.inexactAllowWhileIdle`** nếu hệ thống từ chối. **Lý do**:
  app phát hành qua GitHub Releases (không qua Play — xem `docs/publish/`), nên
  ràng buộc chính sách Play của `USE_EXACT_ALARM` không áp dụng; còn ca "từ chối
  exact alarm" của plugin là **im lặng, không ném lỗi** ⇒ nếu không kiểm và lùi
  thì thông báo **biến mất không dấu vết** (đúng loại lỗi khó tìm nhất).
- **Phương án khác**: `SCHEDULE_EXACT_ALARM` (phải xin ở cài đặt hệ thống, thêm
  một luồng quyền **ngoài** spec Q2=C); không kiểm gì (chấp nhận mất thông báo
  im lặng — trái SC-002/SC-010).

## R11 — Kênh & icon: **3 kênh Android + 3 vector drawable tự viết**

- **Quyết định**: 3 channel — `sora_daily` (nhắc hàng ngày, teal), `sora_budget`
  (cảnh báo ngân sách, **coral `#D85A30`**), `sora_summary` (tổng kết, teal) —
  FR-025 (tắt riêng từng loại ở cài đặt hệ điều hành **không** ảnh hưởng loại
  khác, và **không** làm mất bản ghi Trung tâm). 3 icon nhỏ **vector drawable XML**
  tự viết trong `android/app/src/main/res/drawable/` (chuông / cảnh báo / biểu đồ
  tròn, đơn sắc) — FR-006 + SC-001 đòi **icon theo loại**, mà icon nhỏ của thông
  báo Android **bắt buộc** là drawable đơn sắc (không dùng được `Icons.*` của
  Material hay ảnh launcher).
- **Phương án khác**: dùng chung `@mipmap/ic_launcher` cho cả 3 (đơn giản nhất
  nhưng **trắng/ô vuông** trên Android mới và **mất** phân biệt theo loại — trái
  FR-006/SC-001); thêm package icon (`flutter_launcher_icons`…) — thừa, chỉ cần 3
  file XML.

## R12 — i18n & nội dung: **module thuần sinh câu chữ, snapshot nguyên văn**

- **Quyết định**: `notification_content.dart` (thuần, không `Widget`) sinh
  `(title, body)` theo `kind` + số liệu + **ngôn ngữ hiện hành** — dùng đúng khuôn
  PBI 19: **khoá dịch = chuỗi tiếng Việt**, `.tr`/`.trParams`, chỉ thêm nhánh `_en`.
  Số tiền `formatMoney` (`42.500.000 đ`), giờ `formatClock` (`HH:mm`).
- **Câu chữ bám mockup `04`**:
  - ngân sách **sớm**: *"Sắp vượt ngân sách @danh mục"* / *"Bạn đã dùng @% ngân sách @kỳ cho danh mục @danh mục."*;
  - ngân sách **vượt mức**: câu chữ phải nói **đã vượt** (FR-007 — phân biệt bằng
    chữ, không chỉ bằng con số);
  - nhắc hàng ngày (cờ bật): *"Nhắc ghi chép giao dịch"* / *"Bạn chưa ghi giao dịch nào hôm nay."*;
  - nhắc hàng ngày (cờ **tắt**): **không** được khẳng định "chưa ghi" (FR-008/AC#3);
  - tổng kết: *"Tổng kết tuần"* / *"@so sánh. Xem chi tiết báo cáo."* — câu so
    sánh **tái dùng** `report_view` (PBI 22/26: `reportComparison` + câu insight đã
    có luật "kỳ trước rỗng ⇒ bỏ câu so sánh") ⇒ AC#19/#20 **miễn phí**, đúng điểm
    nối "dùng lại insight cho thông báo cuối tuần/cuối tháng" ghi ở
    [[Lộ trình phát triển]].
- **Snapshot**: nội dung **đông cứng** lúc sinh (lên lịch/bắn) và lưu **nguyên
  văn** vào bảng `notifications` — đổi ngôn ngữ sau đó **không** dịch lại (FR-027,
  đồng bộ PBI 30). `sora_translations_test` quét `lib/` ⇒ **mọi khoá mới phải có
  bản `_en`**.

## R13 — Bootstrap & vòng đời: **main() khởi tạo plugin, app.dart hoà giải**

- **Quyết định**: `main()` thêm `WidgetsFlutterBinding.ensureInitialized()` rồi
  khởi tạo plugin (channel + `initialize(onDidReceiveNotificationResponse:)` +
  `tz.setLocalLocation` từ `flutter_timezone`) **trước** `runApp` — tài liệu FLN
  yêu cầu và tránh đua với việc đọc chi tiết khởi động từ thông báo. `app.dart`
  giữ: đọc `getNotificationAppLaunchDetails()` → đưa payload vào
  `NotificationTapRouter`; chạy **hoà giải** (R6) khi boot và ở **mỗi**
  `AppLifecycleState.resumed`.
- **Không chặn khởi động**: hoà giải là fire-and-forget, có `try/catch` — FR-024
  (không làm chậm/không lỗi người dùng) áp cho cả đường boot.
- **Phương án khác**: khởi tạo plugin trong `initState` của widget gốc (muộn hơn
  cần thiết, dễ đua với launch details trên cold start).

## R14 — Cấu hình Android/iOS bắt buộc (thiếu là đỏ build/chết im lặng)

| Việc | File | Vì sao |
|---|---|---|
| Bật **core library desugaring** (`isCoreLibraryDesugaringEnabled = true` + `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`) | `android/app/build.gradle.kts` | FLN v10+ **bắt buộc** desugaring; hiện repo **chưa** bật ⇒ build đỏ ngay |
| `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `USE_EXACT_ALARM` | `AndroidManifest.xml` | quyền thông báo (Android 13+) · khôi phục lịch sau **khởi động lại** (FR-022/SC-010) · lịch chính xác |
| 2 receiver `ScheduledNotificationReceiver` + `ScheduledNotificationBootReceiver` (`exported=false`, action `BOOT_COMPLETED`/`MY_PACKAGE_REPLACED`/`QUICKBOOT_POWERON`) | `AndroidManifest.xml` | hiện **chưa có** — thiếu thì lịch mất sau reboot (đỏ AC#17/SC-010) |
| `UNUserNotificationCenter.current().delegate = self` trong `didFinishLaunchingWithOptions` | `ios/Runner/AppDelegate.swift` | hiện **chưa có**; thiếu thì thông báo không hiện khi app mở (iOS) |
| 3 drawable icon nhỏ | `android/app/src/main/res/drawable/ic_notif_*.xml` | R11 |
| `proguard-rules.pro`: **không** thêm gì | — | FLN v19+ tự mang consumer rules; chạy `flutter build apk --release` để **kiểm chứng** (bẫy proguard ML Kit của PBI 24) |

## R15 — Kiểm thử: seam `NotificationPresenter` để không cần plugin trong test

- **Quyết định**: seam `NotificationPresenter` (bọc FLN: `schedule`/`show`/`cancel`/
  `cancelAllOfKind`/`areEnabled`/`requestPermission`/`openSettings`) +
  `NotificationLedger` (seam đọc/ghi sổ). Test bơm **fake** cho cả hai ⇒ toàn bộ
  luật nghiệp vụ (R2–R9) test được **không cần** plugin, không cần thiết bị.
- **Lý do**: bám đúng nếp của repo (mọi thứ chạm native/DB đều có seam + fake:
  `NotificationStore`, `NotificationHistoryStore`, `PinStore`, `ScanOcr`…). Plugin
  thông báo **không** chạy được trong `flutter test` (không có
  `MethodChannel` thật) — nếu không có seam thì 0 test tự động cho PBI này.
- **Phạm vi kiểm thử**: `notification_schedule`/`notification_content` (thuần, test
  dày: cuốn cửa sổ, ngày trong tuần, mốc cuối tháng 28/29/30/31, câu chữ 2 ngôn
  ngữ, ca chia 0) · `notification_engine` (fake presenter + fake ledger: chặn
  trùng, Q3, huỷ khi đã ghi, hoà giải ghi bù, tắt/bật công tắc) · sổ drift + schema
  v10 (test DAO thật — host có sqlite native) · màn `01` (soft-ask 1 lần, dòng
  trạng thái).
- **Không** test: hành vi thật của plugin/hệ điều hành (lịch có thực sự nổ đúng
  giờ không) ⇒ **QA tay trên emulator** trong `quickstart.md` (đổi giờ hệ thống để
  kích hoạt mốc trong vài phút).

## R16 — Xếp lớp file (theo đúng nếp `core/` + `data/` + `screens/`)

`core/notification/` (mới: `notification_content`, `notification_schedule`,
`notification_ledger`, `notification_presenter`, `notification_engine`,
`notification_tap`, `notification_presence`) · `data/`
(`notification_ledger_drift`, `notification_presenter_plugin`, thêm hàm `ensure…`
vào `notification_deps.dart`) · `data/db/app_database.dart` (v10 + bảng mới) ·
`screens/` (2 màn cấu hình gọi engine sau khi lưu; `budget_detail_screen` +
`report_screen` khai báo hiện diện) · `main.dart`/`app.dart` (bootstrap + resume) ·
`android/` + `ios/` (R14).

## R17 — Việc **không** làm (giữ đúng phạm vi spec)

2 loại `recurringDue`/`goalReminder` (chưa có module — Q1=A) · màn chỉnh ngưỡng /
nhắc trước (2 hàng chevron vẫn no-op) · bắn lặp/nhiều khung giờ · tuỳ chỉnh âm
thanh/rung/nút hành động · widget màn hình chính · UI cảnh báo giới hạn nền tảng
(autostart/pin optimization) · đưa cấu hình & lịch sử vào backup/restore JSON ·
chạy nền Dart (R0-A) · `contracts/` (app thuần nội bộ — không API/CLI lộ ra ngoài,
đồng nhất PBI 19–30).
