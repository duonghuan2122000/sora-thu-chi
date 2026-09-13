# Nghiên cứu — PBI 28 (Cài đặt Thông báo & nhắc nhở — màn Cài đặt)

**Mã PBI**: 28
**Liên kết spec**: [spec.md](./spec.md)
**Ngày**: 2026-09-13

> Spec đã "Đã làm rõ" (Q1/Q2/Q3 chốt 1A/2A/3A ngày 2026-09-13) — **không còn
> `NEEDS CLARIFICATION`**. Dưới đây là các quyết định **triển khai**.
> Nguồn chân lý nghiệp vụ: `docs/notification/notification-solution.md` (§2 bảng
> 5 loại + nguyên tắc công tắc độc lập, §3.1 data model, §4 mockup `01`) và mockup
> `docs/notification/01-cai-dat-thong-bao.svg`.

---

## R1 — Lưu cấu hình ở đâu?

- **Quyết định**: **một row JSON** trong bảng key-value `AppSettings` đã có —
  key `notificationPrefs`, value = `jsonEncode(NotificationPrefs.toJson())`.
  **Không** nâng schema (giữ **v8**), **không** `build_runner`, **không** thêm
  dependency.
- **Lý do**: (a) bảng `AppSettings` (schema v5, PBI 17) sinh ra đúng cho việc này —
  PBI sau chỉ **thêm row**, không thêm migration (ghi chú ngay trong
  `app_database.dart`); (b) cấu hình này là **một khối 16 trường có tham số khác
  nhau theo từng loại** — JSON gói gọn trong 1 row, đọc/ghi nguyên khối, không
  thể lệch nửa nọ nửa kia; tiền lệ có sẵn: `scanDeviceCheck` (PBI 24) cũng
  `jsonEncode` một object phức vào `AppSettings`; (c) mặc định "ghi lại ngay lần
  mở đầu" (FR-007) thành **1 upsert** thay vì 16.
- **Phương án khác**:
  - **16 row phẳng** (`notifDailyHour`, `notifBudgetEarlyPct`, …) như
    `UtilitiesPrefs`/`ScanSettings`: reject — prefs ở hai PBI đó chỉ 2–4 khoá nên
    phẳng là rẻ; 16 khoá thì phải kiểm vắng-mặt từng khoá, ghi 16 row và dễ lệch
    trạng thái khi ghi lỗi giữa chừng. Đổi lại JSON phải tự chịu lỗi parse (R3).
  - **Bảng drift riêng `notification_rules`** đúng như doc §3.1 `NotificationRule`:
    reject **ở đợt này** — cần migration v9 + `build_runner`, mà cột đáng giá của
    bảng đó (`lastFiredAt` chống bắn trùng, `config` theo loại) chỉ có nghĩa khi
    **engine** tồn tại (PBI sau). Dựng bảng rỗng bây giờ là bảng chết; khi engine
    ra đời sẽ quyết định bảng đó (lúc đó có thể migrate từ row JSON này).
  - **`shared_preferences`**: reject — không có trong repo, lệch nguyên tắc "mọi
    dữ liệu local nằm trong drift" đã chốt ở PBI 17 (R1 của PBI 17).
  - **`flutter_secure_storage`**: reject — không phải dữ liệu bí mật.

## R2 — Ghi bộ mặc định "ngay lần mở màn đầu" (FR-007, FR-008) bằng cách nào?

- **Quyết định**: màn, sau khi `load()` thành công, gọi luôn `save(prefs)` —
  **ghi lại nguyên khối vừa đọc** (idempotent). Cấu hình sau lần mở đầu tiên vì
  thế **luôn tồn tại** trong DB; không cần cờ "đã khởi tạo".
- **Lý do**: (a) seam giữ **đúng khuôn** `UtilitiesStore`/`ScanSettingsStore`
  (`load`/`save`), không thêm phương thức mới cho một hành vi một dòng; (b) ghi
  lại bản vừa đọc là vô hại (1 upsert 1 row, không xoá khoá nào khác) và có lợi
  phụ: giá trị lạ/hỏng trong DB được **chuẩn hoá** về giá trị hợp lệ mỗi lần mở;
  (c) đọc-rồi-ghi **không** đặt side-effect ẩn vào `load()` (khác phương án dưới).
- **Phương án khác**:
  - Thêm `loadEnsuringDefaults()` vào seam: reject — hai phương thức cho cùng một
    nguồn dữ liệu, mọi impl/fake phải cài đặt gấp đôi.
  - Cho `DriftNotificationStore.load()` **tự ghi** khi thiếu khoá: reject — side
    effect ẩn trong hàm đọc, và fake store trong test sẽ hành xử khác impl thật.
  - Chỉ ghi khi người dùng chạm công tắc (write-through thuần như PBI 17): reject
    — **vi phạm** kịch bản 6 ("các giá trị này được lưu lại ngay, không phải chờ
    người dùng thao tác").

## R3 — Lưu những tham số nào? (biên so với mục "Thực thể chính" của spec)

- **Quyết định**: lưu **16 trường**, đúng những gì **có hiển thị** hoặc **được
  FR-008 chốt mặc định**:

  | Loại nhắc | Trường lưu | Mặc định |
  |---|---|---|
  | Nhắc nhập giao dịch hằng ngày | `dailyEnabled`, `dailyHour`, `dailyMinute`, `dailyOnlyIfNoTxnToday` | `true`, 20, 30, `true` |
  | Cảnh báo vượt ngân sách | `budgetEnabled`, `budgetEarlyPercent`, `budgetOverPercent` | `true`, 80, 100 |
  | Nhắc hóa đơn sắp đến hạn | `recurringEnabled`, `recurringDaysBefore` | `true`, 3 |
  | Nhắc đóng góp mục tiêu | `goalEnabled` | `false` |
  | Tổng kết cuối tuần | `weeklyEnabled`, `weeklyHour`, `weeklyMinute` | `true`, 20, 0 |
  | Tổng kết cuối tháng | `monthlyEnabled`, `monthlyHour`, `monthlyMinute` | `true`, 20, 0 |

- **Lý do**: mọi trường trên đều **xuất hiện trong dòng phụ** của mockup `01`
  (giờ, ngưỡng %, số ngày, giờ tổng kết) nên FR-009 buộc chúng phải đọc từ cấu
  hình đang lưu; phần còn lại của mục "Thực thể chính" không có đường nào để
  người dùng tạo ra giá trị, nên lưu chỉ sinh **dữ liệu chết**.
- **Hoãn có lý do** (khác chữ của mục "Thực thể chính" — xem "Ngoại lệ" ở
  `plan.md`):
  - **"các ngày trong tuần"** của nhắc hàng ngày: mockup cố định "**mỗi ngày**";
    không có chip chọn ngày nào trong phạm vi PBI (màn `02` là PBI sau). Nếu lưu
    mà không ai đặt được thì giá trị mặc định "cả 7 ngày" chẳng bao giờ khác đi,
    còn dòng phụ lại phải giả vờ đọc nó ⇒ thêm một lớp giả.
  - **"chu kỳ đóng góp + các mốc %"** của mục tiêu: doc §2 nói rõ đây là cấu hình
    **per-mục-tiêu** ("nếu người dùng đặt", mốc 50/75/100%) — thuộc module **Mục
    tiêu tiết kiệm (GĐ3)** chưa tồn tại, không phải cấu hình cấp màn. Mockup chỉ
    vẽ dòng phụ tĩnh "Theo chu kỳ đã đặt cho từng mục tiêu".
  - **ngưỡng riêng từng ngân sách** (`alertThresholds`): spec đã ghi ngoài phạm vi.
  - **thứ của "Tổng kết cuối tuần"**: mockup cố định "Chủ nhật hằng tuần"; chỉ
    giờ:phút là giá trị đọc từ cấu hình.
  → Khi màn `02` (cấu hình nhắc hàng ngày) và module Mục tiêu ra đời, chúng thêm
  trường vào **cùng** object JSON này; parse tolerant của R4 khiến việc thêm
  trường sau này không phá dữ liệu cũ.

## R4 — Đọc JSON chịu lỗi thế nào?

- **Quyết định**: parse **tolerant, không ném**: key vắng → cả bộ mặc định; JSON
  hỏng (không parse được / không phải object) → cả bộ mặc định; **từng trường**
  sai kiểu/ngoài miền (giờ ∉ 0–23, phút ∉ 0–59, % ∉ 0–100, ngày ∉ 0–30, bool
  không phải bool) → **mặc định của riêng trường đó**, các trường còn lại giữ
  nguyên. Ghi: boom (clamp) giá trị về miền hợp lệ.
- **Lý do**: tiền lệ `UtilitiesPrefs.fromSettings`/`ScanSettings.fromSettings`
  ("mọi giá trị lạ/thiếu key → mặc định an toàn, không ném"); DB là dữ liệu người
  dùng, sửa tay/ghi dở dang không được làm màn trắng.
- **Phương án khác**: ném lỗi rồi cho màn hiện nhánh "Không đọc được cài đặt"
  (khuôn PBI 17): vẫn giữ nhánh lỗi cho **lỗi DB** (mở/ghi sqlite thất bại), nhưng
  không dùng cho dữ liệu hỏng — người dùng không có cách nào tự sửa.

## R5 — Màn dùng kiến trúc gì?

- **Quyết định**: `StatefulWidget` + **seam store bơm được** (`NotificationStore?`
  tham số constructor, mặc định `ensureNotificationStore()`), không GetX
  controller. Ghi bám đuôi (`_saveTail`) như `UtilitiesScreen` để bật/tắt liên
  tiếp không bị save cũ đè save mới.
- **Lý do**: đúng khuôn `UtilitiesScreen` (PBI 17) — màn chỉ có **một** nguồn dữ
  liệu, không chia sẻ trạng thái với màn nào khác trong đợt này (engine đọc cấu
  hình là PBI sau, lúc đó mới cần controller như `ScanController`); seam cho phép
  widget test bơm fake, không cần sqlite native.
- **Phương án khác**: `GetxController` + `Obx` như `ScanController`: reject — thêm
  lớp state cho một màn chỉ đọc-một-lần, và không ai khác tiêu thụ state đó.

## R6 — Điểm vào ở màn Cài đặt?

- **Quyết định**: thêm **1 `_SettingsRow`** nhãn "Thông báo & nhắc nhở" vào nhóm
  **KHÁC**, **ngay sau** "Tiện ích & Cá nhân hóa", trailing chevron, `onTap` mở
  `NotificationSettingsScreen`; kèm seam `onManageNotificationsTap` (khuôn 3 hàng
  đã có để test không phải đẩy route thật).
- **Lý do**: spec "Giả định" chốt vị trí này (nhóm KHÁC, sau Tiện ích) và FR-001
  đòi mở bằng **đúng 1 lần chạm**.
- **Phương án khác**: hàng riêng một nhóm mới "THÔNG BÁO" — reject, mockup `01`
  không vẽ màn Cài đặt và cách xếp hàng hiện có gom mọi màn con vào KHÁC.

## R7 — Bố cục & widget: tái dùng gì, viết mới gì?

- **Quyết định**: `SubPageScaffold(title: 'Thông báo & nhắc nhở'.tr)` (app bar teal
  + back, **không** bottom nav, **không** FAB — FR-002) + `ListView` thân màn, và
  **viết lại tại chỗ** các widget private của khuôn màn Tiện ích: `_SectionLabel`
  (nhãn nhóm viết hoa, mờ), `_ItemRow` (vòng tròn 36 chứa icon + tiêu đề + dòng
  phụ + trailing), hàm chèn `Divider` **giữa các hàng trong nhóm**, `_rows` cho
  hàng chevron. **Không** tạo widget dùng chung mới, **không** sửa
  `utilities_screen.dart`.
- **Lý do**: hai màn cùng khuôn mockup nhưng khác nhau ở chỗ đáng kể (màn này có
  **2 sắc icon** teal/coral theo nhóm, **không** có hàng "giá trị + chevron" ở
  bên phải, số nhóm/hàng khác) — gom thành widget chung là abstraction sớm, và
  PBI 17 đã chấp nhận trùng lặp này giữa các màn.
- **Phương án khác**: nâng `_ItemRow`/`_SectionLabel` của PBI 17 thành widget
  public dùng chung: reject — phải thêm tham số màu icon, sửa màn đã QA, đổi lợi
  ích lấy rủi ro hồi quy.
- **Divider**: chỉ chèn **giữa các hàng trong cùng nhóm** (khuôn PBI 17), không
  chèn sau hàng cuối nhóm, không chèn trước nhãn nhóm. Mockup vẽ 4 đường kẻ không
  nhất quán (có đường sau hàng cuối nhóm NGÂN SÁCH, thiếu ở nhóm MỤC TIÊU) — bám
  theo khuôn code hiện có thay vì vẽ lại lỗi đồ hoạ.

## R8 — Màu & icon

- **Quyết định**: hàng thuộc nhóm **NGÂN SÁCH** (2 hàng: "Cảnh báo vượt ngân
  sách", "Ngưỡng cảnh báo") dùng `colors.coralLightBg` (vòng tròn) +
  `colors.coralOnNeutral` (glyph); **6 hàng còn lại** dùng `colors.tealLightBg` +
  `colors.tealOnNeutral`. **Không** thêm token, **không** hex cứng trong widget.
- **Lý do**: mockup vẽ đúng như vậy (`#D85A30` opacity 0.14 cho 2 hàng ngân sách,
  `#E1F5EE` cho phần còn lại) và FR-004 chốt ngữ nghĩa "coral chỉ cho cảnh báo chi
  tiêu"; hai token đã tồn tại ở cả 2 theme (PBI 18) nên chế độ Tối tự đúng.
- **Icon** (map từ mockup `01`, đều là icon Material có sẵn):

  | Hàng | Mockup | Icon dùng |
  |---|---|---|
  | Nhắc nhập giao dịch hằng ngày | bell | `Icons.notifications_none` |
  | Cảnh báo vượt ngân sách | warning | `Icons.warning_amber_rounded` |
  | Ngưỡng cảnh báo | warning | `Icons.warning_amber_rounded` |
  | Nhắc hóa đơn sắp đến hạn | calendar+clock | `Icons.event_outlined` |
  | Nhắc trước | calendar+clock | `Icons.event_outlined` |
  | Nhắc đóng góp mục tiêu | bullseye | `Icons.track_changes` |
  | Tổng kết cuối tuần / cuối tháng | pie | `Icons.pie_chart_outline` |
  | Hàng chevron (trailing) | chevron | `Icons.chevron_right` |

- **Công tắc**: `Switch` mặc định của Material, màu lấy từ `ColorScheme` seed teal
  (đúng như 2 công tắc PBI 17 + công tắc "Quét hóa đơn bằng AI" PBI 24) — **không**
  thêm `switchTheme`; QA chế độ Tối kiểm tương phản.

## R9 — Giờ "20:30" định dạng ở đâu?

- **Quyết định**: thêm **2 dòng** vào `lib/core/date_label.dart`:
  `String formatClock(int hour, int minute) => '${_two(hour)}:${_two(minute)}';`
  và cho `formatTimeLabel(DateTime)` gọi lại nó. Dòng phụ dùng `formatClock(...)`.
- **Lý do**: `_two` (padLeft 2) đã nằm private trong file đó và `formatTimeLabel`
  đã cho đúng `HH:mm` — tái dùng thay vì viết lại padLeft lần thứ 5 trong repo;
  24 giờ, **không** đổi theo ngôn ngữ (FR-015).
- **Phương án khác**: gọi `formatTimeLabel(DateTime(2000, 1, 1, h, m))` — reject,
  dựng DateTime giả để lấy chuỗi giờ là cách nói vòng vo. Hay viết hàm riêng trong
  `notification_prefs.dart` — chấp nhận được nhưng lặp lại hằng `_two`.

## R10 — Nội dung dòng phụ & khoá dịch (FR-009, FR-015)

- **Quyết định**: dòng phụ dựng ở **tầng màn** bằng `.trParams` với các khoá có
  placeholder; giờ/số **không** dịch:

  | Hàng | Chuỗi | Ghi chú |
  |---|---|---|
  | Nhắc nhập giao dịch hằng ngày | `'@giờ mỗi ngày'` + (cờ bật) `' · chỉ nhắc nếu chưa ghi'` | ghép 2 khoá, **không** nối chuỗi thủ công vào giữa khoá |
  | Cảnh báo vượt ngân sách | `'Khi đạt @sớm% và khi vượt @vượt%'` | |
  | Ngưỡng cảnh báo | `'Sớm: @sớm% · Vượt mức: @vượt%'` | |
  | Nhắc hóa đơn sắp đến hạn | `'Tiền điện, tiền nhà, trả nợ...'` | tĩnh |
  | Nhắc trước | `'@n ngày trước hạn thanh toán'` | |
  | Nhắc đóng góp mục tiêu | `'Theo chu kỳ đã đặt cho từng mục tiêu'` | tĩnh |
  | Tổng kết cuối tuần | `'Chủ nhật hằng tuần, @giờ'` | |
  | Tổng kết cuối tháng | `'Ngày cuối tháng, @giờ'` | |

  Tất cả khoá đều là **literal ngay trước `.tr`/`.trParams`** ⇒ test
  `sora_translations_test` (quét `lib/`) bắt buộc phải có bản dịch `en` — thiếu là
  đỏ. Nhãn app bar, 5 nhãn nhóm, 8 tiêu đề hàng cũng vào cùng bộ khoá đó.
- **Lý do**: FR-015 đòi **mọi nhãn tĩnh** có bản dịch, nhưng giờ/ngày/số giữ
  nguyên; `.trParams` là cách repo đang dùng (`report_view`, `budget_detail_screen`).
- **Phương án khác**: ghép chuỗi kiểu `'20:30' + ' mỗi ngày'.tr` — reject, trật tự
  từ trong tiếng Anh khác tiếng Việt ("Every day at 20:30"), người dịch không sửa
  được vị trí nếu không có placeholder.

## R11 — Hàng chevron (Ngưỡng cảnh báo, Nhắc trước) hành xử thế nào?

- **Quyết định**: hàng có `trailing` = chevron + `onTap` = **handler rỗng**
  (`InkWell` phản hồi chạm nhưng không mở gì, không SnackBar, không dialog).
- **Lý do**: chốt Q2=A + tiền lệ "điểm vào no-op" PBI 13/17 (`onTap ?? () {}`);
  SC-008 đòi **0** màn mới, **0** thông báo lỗi/khung "sắp có".
- **Phương án khác**: bỏ `onTap` (hàng đứng im, không hiệu ứng mực): reject — lệch
  khuôn các hàng điều hướng hiện có và trông như lỗi cảm ứng.

## R12 — Cấu trúc file & tên seam

- **Quyết định**: theo đúng xếp lớp của PBI 17/24:
  `lib/core/notification/notification_prefs.dart` (hằng khoá + lớp `NotificationPrefs`
  bất biến + JSON), `lib/core/notification/notification_store.dart` (seam
  `NotificationStore`), `lib/data/notification_store_drift.dart`
  (`DriftNotificationStore`), `lib/data/notification_deps.dart`
  (`ensureNotificationStore()` GetX singleton), `lib/screens/notification_settings_screen.dart`,
  `test/fakes/fake_notification_store.dart`.
- **Lý do**: đặt tên thư mục `core/notification/` để **engine** (PBI sau: lên lịch,
  bắn cảnh báo, `NotificationLog`, deep link) ở cùng chỗ; nếp GetX singleton
  `ensureXStore()` là khuôn có sẵn (tránh 2 connection drift trên cùng file sqlite).
- **Phương án khác**: nhét vào `core/utilities/` (màn Tiện ích): reject — hai tính
  năng khác nhau, và engine sau này cần thư mục riêng.

## R13 — Kiểm thử

- **Quyết định**: 3 file test **mới** + 2 file test **sửa** + 1 fake:
  `notification_prefs_test.dart` (mặc định, round-trip JSON, parse tolerant từng
  trường, bất biến khi bật/tắt, `formatClock`), `notification_store_drift_test.dart`
  (DB in-memory, schema vẫn 8, key vắng → mặc định, round-trip, **không xoá khoá
  của PBI 17/24**), `notification_settings_screen_test.dart` (5 nhóm/8 hàng, 6
  công tắc + 2 chevron, màu icon theo nhóm, độc lập công tắc, chevron no-op, đọc
  lại sau khi mở lại, ghi mặc định khi mở lần đầu, cỡ chữ lớn không tràn),
  `settings_screen_test.dart` (SỬA: +1 hàng, thứ tự, chạm mở màn, seam callback),
  `dark_theme_smoke_test.dart` (SỬA: thêm màn mới vào danh sách smoke tối).
- **Lý do**: phủ FR-003…FR-012 ở tầng thấp + widget; baseline test đỏ **không tăng**
  (xem `quickstart.md` §5).
- **Phương án khác**: chỉ test màn (widget) — reject, luật parse/lưu là chỗ dễ sai
  nhất và test widget không chạm tới JSON.

## R14 — Việc **không** làm (chống phình)

- Không engine, không `flutter_local_notifications`, không xin quyền, không
  notification channel (Q1=A, FR-012).
- Không màn `02`/`03`/`04` của doc, không `NotificationLog`, không deep link.
- Không sửa `AppShell`/`AppBottomNavBar`, không thêm provider/controller toàn cục.
- Không thêm dependency, không nâng schema, không `build_runner`.
- Không widget dùng chung mới, không token màu mới, không migration.
