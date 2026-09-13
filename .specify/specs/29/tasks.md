# Danh sách Task: Cấu hình nhắc nhập giao dịch hằng ngày (màn 02)

**Mã PBI**: 29
**Nguồn**: spec.md, plan.md, data-model.md, research.md, quickstart.md
**Mốc trước PBI**: 1004 test pass + 1 test đỏ **có sẵn** (`test/transactions_dao_test.dart`, từ PBI 11 — không liên quan PBI 29)

## Định dạng task

`- [ ] [MãTask] [P?] [Story?] Mô tả kèm đường dẫn file`

- `[P]`: chạy song song được (khác file, không phụ thuộc task chưa xong)
- `[Story]`: chỉ có ở pha User Story (`[US1]`, `[US2]`, `[US3]`)

## Pha 1: Setup

- [X] T001 Chạy baseline từ `app/sora_thu_chi/`: `flutter pub get`, `flutter analyze`, `flutter test` — ghi nhận mốc **1004 pass + 1 đỏ có sẵn** theo `.specify/specs/29/quickstart.md` §5 (xác nhận `pubspec.yaml` **không** cần sửa)
- [X] T002 [P] Đọc mockup `docs/notification/02-cau-hinh-nhac-nhap-giao-dich.svg` + `docs/notification/notification-solution.md` §2/§3.1, đối chiếu mục "Kiến trúc chi tiết" của `.specify/specs/29/plan.md` để chốt bố cục 4 khối trước khi code

## Pha 2: Foundational

*(Nền dùng chung cho cả 3 user story — phải xong trước US1)*

- [X] T003 [P] Thêm trường `dailyWeekdays` (`List<int>`, mặc định `[1..7]`) + `isEveryDay` + `isDayEnabled(int)` + `toggleDay(int)` (tắt ngày cuối → trả **chính object cũ**) + `_weekdays(Object?)` parse tolerant vào `lib/core/notification/notification_prefs.dart` (data-model luật 1–14; `toJson`/`fromSettings`/`copyWith`/`==`/`hashCode` thêm khoá mới, 16 trường cũ **không đổi**)
- [X] T004 [P] Thêm `dayLabel(int weekday)` (`1 => 'T2'.tr` … `7 => 'CN'.tr`, ngoài miền → `''`) + `daysLabel(List<int>)` (nén dải liên tiếp dài **≥3**, ngày rời liệt kê, phân cách `, `) vào `lib/core/date_label.dart` (research R10)
- [X] T005 [P] Thêm ~17 khoá dịch EN vào `lib/core/locale/sora_translations.dart`: 7 nhãn ngày (`T2`→`Mon` … `CN`→`Sun`), `'Nhắc nhập giao dịch'`, `'THỜI GIAN NHẮC'`, `'LẶP LẠI VÀO CÁC NGÀY'`, `'Chỉ nhắc nếu chưa ghi giao dịch'`, `'Bỏ qua nhắc nhở nếu hôm nay bạn đã nhập'`, `'XEM TRƯỚC THÔNG BÁO'`, `'Đừng quên ghi lại thu chi hôm nay nhé!'`, `'Lưu thay đổi'`, `'@giờ vào @ngày'` (FR-015; **không** dịch `'Sora Thu Chi'` và `HH:mm`)
- [X] T006 [P] Bổ sung test luật tập ngày vào `test/notification_prefs_test.dart`: mặc định `[1..7]`; parse tolerant (thiếu khoá / `[]` / sai kiểu / phần tử `0`,`8`,`null`,số thực,`"T2"` / trùng lặp → chuẩn hoá đúng, **không ném**); ghi ra luôn sắp tăng; round-trip; `isEveryDay`; `toggleDay` thêm/bớt/`identical` khi còn 1 ngày/không chạm 15 trường khác (data-model luật 1–14)
- [X] T007 [P] Bổ sung test `dayLabel` + `daysLabel` vào `test/date_label_test.dart`: `1→T2` … `7→CN`, ngoài miền → `''`; `[1..7]→'T2–T7, CN'`, `[1..6]→'T2–T7'`, `[1,2,3,5]→'T2–T4, T5'`, `[1,7]→'T2, CN'`, `[3]→'T3'`, `[]→''`

## Pha 3: User Story 1 — Mở màn 02 từ màn 01, đổi giờ/ngày/cờ và lưu (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: người dùng chạm vùng tiêu đề hàng "Nhắc nhập giao dịch hằng ngày" → màn `02` mở ra đúng mockup `02`; đổi giờ:phút (quay vòng), đảo 7 chip ngày (luôn ≥1 ngày), tắt/bật cờ "chỉ nhắc nếu chưa ghi"; khối xem trước đổi giờ ngay; **chỉ** ghi khi bấm "Lưu thay đổi", back thì bỏ thay đổi.
**Tiêu chí kiểm thử độc lập**: với `FakeNotificationStore`, mở màn 02 → thao tác → `storedPrefs` **không** đổi; chạm back → `storedPrefs` không đổi; bấm Lưu → `storedPrefs` đúng bản nháp và màn pop. Không cần US2/US3.

- [X] T008 [US1] Tạo `lib/screens/daily_reminder_config_screen.dart`: `DailyReminderConfigScreen({NotificationStore? store})` + `_store`/`_draft`/`_loading`/`_error`; `_load()` **chỉ đọc** (`store.load()` → `setState`) — **không** ghi lại khi mở màn (khác màn `01`); `SubPageScaffold(title: 'Nhắc nhập giao dịch'.tr)`; 3 nhánh thân màn: spinner / `'Không đọc được cài đặt.'` + nút `'Thử lại'` / danh sách (research R8, plan §3)
- [X] T009 [US1] Dựng khối **THỜI GIAN NHẮC** trong `lib/screens/daily_reminder_config_screen.dart`: `_SectionLabel` + `_timeBlock` (nền `softCardBg`, bo 10) chứa `_TimeColumn` giờ · `Text(':')` · `_TimeColumn` phút; mỗi cột ▲ (`Icons.keyboard_arrow_up`) → giá trị lân cận trên → ô đang chọn (nền `tealOnNeutral` alpha ~0.10, chữ 26 px `tealOnNeutral`) → lân cận dưới → ▼; `_stepHour(d)`/`_stepMinute(d)` dùng `% 24` / `% 60` (FR-003, SC-003; research R4/R5)
- [X] T010 [US1] Dựng khối **LẶP LẠI VÀO CÁC NGÀY** trong `lib/screens/daily_reminder_config_screen.dart`: `Wrap(spacing: 10, runSpacing: 10)` với 7 `_DayChip` (vòng tròn 36 px: chọn → nền `AppColors.teal` + nhãn trắng; không chọn → nền `colors.surface` + viền `colors.divider` + nhãn `colors.tabInactive`; nhãn clamp `maxScaleFactor: 1.4`); `_toggleDay(w)` gọi `_draft.toggleDay(w)` (FR-004, FR-009, SC-005; research R6)
- [X] T011 [US1] Dựng hàng công tắc + khối **XEM TRƯỚC THÔNG BÁO** trong `lib/screens/daily_reminder_config_screen.dart`: `_toggleRow` (tiêu đề `'Chỉ nhắc nếu chưa ghi giao dịch'.tr` + dòng phụ `'Bỏ qua nhắc nhở nếu hôm nay bạn đã nhập'.tr` + `Switch` gắn `dailyOnlyIfNoTxnToday`) và `_previewCard` (bo 10, viền `colors.divider`: vòng 28 px `tealLightBg` chữ `'S'` + `'Sora Thu Chi'` + câu nội dung + `formatClock(_draft.dailyHour, _draft.dailyMinute)` góc phải — đọc **trực tiếp** từ `_draft` trong `build`) (FR-005, FR-006, SC-004; research R12)
- [X] T012 [US1] Dựng `_saveBar()` ghim `bottomNavigationBar` của `SubPageScaffold` (44 px, `AppColors.teal`, chữ trắng, bo 8, nhãn `'Lưu thay đổi'.tr`) + `_save()`: `try store.save(_draft) catch(_){}` rồi `Get.back()` — nút **luôn** bấm được (FR-007, SC-014; research R7)
- [X] T013 [US1] Nối điểm vào trong `lib/screens/notification_settings_screen.dart`: `_itemRow` bọc `InkWell` **chỉ** quanh cụm icon + tiêu đề/dòng phụ (`trailing` nằm **ngoài**), `_switchRow` thêm tham số `VoidCallback? onTap` (mặc định `null` ⇒ 5 hàng còn lại y nguyên), truyền `onTap: _openDailyConfig` cho hàng nhắc hàng ngày, `_openDailyConfig()` → `Get.to(() => DailyReminderConfigScreen(store: _store))` (FR-001, FR-002, SC-002; research R9)
- [X] T014 [US1] Tạo `test/daily_reminder_config_screen_test.dart` (dùng `FakeNotificationStore`): đủ 3 nhãn nhóm + hàng công tắc + nút Lưu; 2 trục hiện giá trị đang chọn + 2 lân cận; mũi tên ±1 và **quay vòng** 23↔00, 00↔59; khối xem trước đổi **ngay** cùng nhịp chạm mà `storedPrefs` **không** đổi; chạm chip chỉ đổi **chip đó**; chip cuối **không** tắt được; **back → store không ghi**; bấm Lưu → store nhận đúng bản nháp + pop; bấm Lưu khi không đổi gì vẫn pop; nhánh lỗi đọc + `'Thử lại'` đọc lại thành công
- [X] T015 [US1] Chạy `flutter test test/daily_reminder_config_screen_test.dart test/notification_settings_screen_test.dart test/sora_translations_test.dart test/settings_screen_test.dart` — xác nhận 0 khoá dịch EN thiếu và test PBI 28 (2 hàng chevron, 6 công tắc độc lập) còn xanh sau khi sửa `_itemRow`

## Pha 4: User Story 2 — Dòng phụ màn 01 phản ánh giờ và tập ngày đang lưu (Ưu tiên: P2)

**Mục tiêu**: hàng "Nhắc nhập giao dịch hằng ngày" ở màn `01` đọc **lại mỗi lần mở** và hiển thị đúng giờ + tập ngày: đủ 7 ngày → giữ `'@giờ mỗi ngày'`, thiếu ngày → `'@giờ vào @ngày'` với dải nén (`T2–T7, CN`).
**Tiêu chí kiểm thử độc lập**: `FakeNotificationStore` với các tập ngày `[1..7]`, `[1..6]`, `[1,2,3,5]`, `[1,7]` → dòng phụ đúng chuỗi tương ứng; không cần mở màn `02`.

- [X] T016 [US2] Sửa `_dailySubtitle()` trong `lib/screens/notification_settings_screen.dart`: `_prefs.isEveryDay` → giữ chuỗi cũ `'@giờ mỗi ngày'`; ngược lại → `'@giờ vào @ngày'.trParams({'giờ': formatClock(...), 'ngày': daysLabel(_prefs.dailyWeekdays)})`; hậu tố `' · chỉ nhắc nếu chưa ghi'` giữ nguyên khi cờ bật (FR-011, kịch bản 13; research R10)
- [X] T017 [US2] Bổ sung test vào `test/notification_settings_screen_test.dart`: dòng phụ theo 4 tập ngày mẫu (`mỗi ngày` / `T2–T7` / `T2–T4, T5` / `T2, CN`); chạm **vùng tiêu đề/dòng phụ** hàng nhắc hàng ngày → **đúng 1** route `DailyReminderConfigScreen`; chạm **công tắc** → **0** route mới, chỉ đổi trạng thái; 5 hàng công tắc còn lại không mở màn nào; 2 hàng chevron vẫn no-op (FR-001, FR-011, SC-002)

## Pha 5: User Story 3 — Màn 02 đúng ngôn ngữ, chế độ Tối và cỡ chữ lớn (Ưu tiên: P3)

**Mục tiêu**: màn `02` hiển thị đủ bản dịch EN (kể cả 7 nhãn chip, giờ `HH:mm` không đổi), dùng đúng bộ màu theme Tối, và không vỡ bố cục ở cỡ chữ lớn nhất / màn hẹp.
**Tiêu chí kiểm thử độc lập**: pump màn `02` ở English → 0 nhãn tiếng Việt sót; pump ở theme `dark` → token tối thật sự áp và không overflow; pump `textScaleFactor 2.0` @360×640 → không tràn.

- [X] T018 [US3] Rà toàn bộ nhãn tĩnh của `lib/screens/daily_reminder_config_screen.dart` (app bar, 3 nhãn nhóm, hàng công tắc + dòng phụ, câu xem trước, nút Lưu, nhãn chip qua `dayLabel`) đều đi qua `.tr`; bổ sung khoá còn thiếu vào `lib/core/locale/sora_translations.dart` rồi chạy `flutter test test/sora_translations_test.dart` (FR-015, SC-011)
- [X] T019 [US3] Thêm màn `02` (đăng ký `FakeNotificationStore`) vào danh sách smoke theme tối trong `test/dark_theme_smoke_test.dart`: không overflow, token tối thật sự áp (`background`/`softCardBg`), chip đang chọn phân biệt được với chip không chọn (FR-016, SC-011; plan rủi ro 6)
- [X] T020 [US3] Bổ sung test vào `test/daily_reminder_config_screen_test.dart`: pump ở English → app bar + 3 nhãn nhóm + nút Lưu + 7 nhãn chip hiện tiếng Anh, giờ vẫn `HH:mm`; pump `MediaQuery(textScaler 2.0)` + `surfaceSize 360×640` → không exception overflow, cuộn tới được nút Lưu (FR-015, FR-017, SC-012)

## Pha cuối: Polish & Cross-cutting

- [X] T021 Chạy `flutter analyze` (phải sạch) + `flutter test` toàn bộ từ `app/sora_thu_chi/`: pass **tăng**, số test đỏ **không tăng** (vẫn đúng 1 — `test/transactions_dao_test.dart`)
- [X] T022 Đối chiếu trực quan với mockup `docs/notification/02-cau-hinh-nhac-nhap-giao-dich.svg` (SC-001) và rà 5 lệch nhỏ đã biết ở `.specify/specs/29/quickstart.md` §4
- [X] T023 Kiểm tra dữ liệu không bị đụng: `schemaVersion` vẫn **v8** (không migration, không `build_runner`), row `AppSettings` chỉ **thêm** khoá `dailyWeekdays` (17 khoá), các row khác (`hideBalance`, `scanEnabled`…) còn nguyên; số bản ghi `transactions`/`wallets`/`categories`/`budgets` không đổi (`.specify/specs/29/quickstart.md` §6, nhóm J1)
- [X] T024 Chạy QA tay nhóm **A–M** theo `.specify/specs/29/quickstart.md` §2 trên emulator (kèm DB cũ kiểu PBI 28 cho nhóm G6) và ghi nhận kết quả
- [X] T025 Đánh dấu hoàn tất các task trong `.specify/specs/29/tasks.md` + cập nhật wiki (`wiki-knowledge/`) bằng skill `sora-wiki` (page Hồ sơ & Bảo mật + Lộ trình + `log.md`)

## Sơ đồ phụ thuộc

```text
Setup (T001, T002)
  └─ Foundational (T003, T004, T005 ‖ T006, T007)
       ├─ US1 (T008 → T009 → T010 → T011 → T012 → T013 → T014 → T015)
       │     └─ US2 (T016 → T017)          # T017 cần điểm vào của T013
       └─ US3 (T018 → T019 → T020)         # cần màn 02 của US1 tồn tại
                                            └─ Polish (T021 → T022 → T023 → T024 → T025)
```

- T003/T004/T005 sửa 3 file **khác nhau** → song song được; T006/T007 là file test **khác** 3 file trên → song song được.
- US1 là **điều kiện** của US2 và US3 (cả hai đều cần màn `02` đã dựng).
- US2 và US3 **độc lập nhau** → làm theo thứ tự nào cũng được sau US1.
- Trong US1, T008→T012 **tuần tự** (cùng file `daily_reminder_config_screen.dart`).

## Ví dụ chạy song song

```text
# Pha Foundational — 5 task, 5 file khác nhau:
T003 [P] lib/core/notification/notification_prefs.dart
T004 [P] lib/core/date_label.dart
T005 [P] lib/core/locale/sora_translations.dart
T006 [P] test/notification_prefs_test.dart
T007 [P] test/date_label_test.dart

# Sau US1 — US2 và US3 chạm file khác nhau, chạy song song được:
T016 [US2] lib/screens/notification_settings_screen.dart
T019 [US3] test/dark_theme_smoke_test.dart
```

## Chiến lược triển khai

- **MVP đề xuất**: Pha 1 + Pha 2 + **US1** — màn `02` dựng xong, mở được từ màn `01`, đổi giờ/ngày/cờ và lưu bền; đã là lát cắt dùng được (dòng phụ màn `01` khi đó vẫn ghi `'@giờ mỗi ngày'` như PBI 28 nên **không** sai thông tin, chỉ chưa phản ánh tập ngày).
- **Giao hàng tăng dần**: US1 → US2 (dòng phụ đúng tập ngày) → US3 (i18n/tối/cỡ chữ) → Polish.
- **Rủi ro cần để mắt** (plan, mục Rủi ro & ứng phó): (1) thiếu khoá dịch EN ⇒ T005/T015/T018 chạy `test/sora_translations_test.dart` ngay; (2) sửa `_itemRow` làm vỡ test PBI 28 ⇒ T015 chạy `test/settings_screen_test.dart`; (3) quên "không ghi khi mở màn" ⇒ T014 có test `storedPrefs` không đổi.
- **Kiểm chứng tự động**: `flutter test` sau mỗi pha; mốc đỏ luôn là **1** (`test/transactions_dao_test.dart` — lỗi có sẵn từ PBI 11, không sửa trong PBI này).
