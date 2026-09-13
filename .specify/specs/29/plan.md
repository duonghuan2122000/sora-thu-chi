# Kế hoạch triển khai: Cấu hình nhắc nhập giao dịch hằng ngày (màn 02)

**Mã PBI**: 29
**Liên kết spec**: [.specify/specs/29/spec.md](./spec.md)
**Ngày tạo**: 2026-09-13

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12 / Flutter (Android + iOS), app **offline hoàn toàn** (không đăng nhập, không server) |
| Framework / Thư viện chính | GetX `^4.7.3` (điều hướng + DI + i18n), Material. **Không thêm dependency** — đợt này chỉ dùng thứ repo đã có (`Switch`, `IconButton`, `InkWell`, `Wrap`, `SoraColors`, `AppColors`) |
| Lưu trữ dữ liệu | drift `^2.34.4` — **schema giữ nguyên v8** (PBI 24): **thêm 1 khoá** vào row JSON `AppSettings(key='notificationPrefs')` đã có (PBI 28); **không** bảng/cột/migration, **không** `build_runner`, **không** row mới |
| Kiểm thử | `flutter_test` — mốc trước PBI: **1004 pass + 1 test đỏ CÓ SẴN** (`transactions_dao_test`, từ PBI 11). Thêm **1 file test mới**, **sửa 4 file** (mốc + 2 file test màn, 1 file test nhãn ngày), **tái dùng** `FakeNotificationStore` sẵn có (PBI 28). Luật model/format kiểm ở **tầng thuần** (không cần binding nặng); màn kiểm bằng store giả (không cần sqlite native) |
| Nền tảng triển khai | Build local (`flutter build apk` / iOS build) — không server, không CI đặc biệt, **không cấu hình native mới**, `pubspec.yaml` không đổi |
| Ràng buộc hiệu năng | Không có ngân sách thời gian đặc biệt: màn đọc **1 row** khi mở và ghi **1 row** khi bấm Lưu; mũi tên/chip chỉ `setState` (0 I/O); không truy vấn bảng nghiệp vụ nào |
| Ràng buộc khác | Ngôn ngữ giao diện/tài liệu/commit: **tiếng Việt có dấu**; bám Design System (teal `#0F6E56` = hành động/đang chọn; coral `#D85A30` **không** dùng ở màn này — không có ngữ cảnh chi tiêu/cảnh báo); mọi màu đi qua token `SoraColors`/`AppColors`; **mọi nhãn tĩnh phải có bản dịch EN** (PBI 19 — `sora_translations_test` quét `lib/` và đỏ nếu thiếu) |
| Nguồn chân lý nghiệp vụ | Mockup `docs/notification/02-cau-hinh-nhac-nhap-giao-dich.svg` + `docs/notification/notification-solution.md` (§2 loại 1: "1 lần/ngày, theo các ngày trong tuần đã chọn"; §3.1 `config.weekdays`; §4 mockup `02`); kế thừa PBI 28 (row `notificationPrefs` + seam `NotificationStore` + màn `01`), PBI 17 (khuôn `_SectionLabel`/`_itemRow`), PBI 18 (`SoraColors` 2 theme), PBI 19 (khoá dịch = chuỗi tiếng Việt), PBI 8/11 (`formatClock`, khuôn nút đáy form) |

*Không còn mục `NEEDS CLARIFICATION`: spec đã "Đã làm rõ" (Q1=B, Q2=A, Q3=A chốt
2026-09-13, ghi ở mục "Quyết định đã chốt"); các quyết định còn lại là chi tiết
triển khai — xem [research.md](./research.md) (R1…R16).*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

`.specify/memory/constitution.md` **không tồn tại** (repo chưa tạo hiến pháp) ⇒
đối chiếu theo `CLAUDE.md` của repo và các quyết định đã chốt trong `docs/`.

| Nguyên tắc (nguồn: CLAUDE.md + docs) | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline hoàn toàn, không server/không auth | ✅ | Chỉ sqlite local; **0** lời gọi mạng; **0** plugin thông báo, **0** xin quyền, **0** lịch (FR-014) |
| Ngôn ngữ giao diện/tài liệu/commit: tiếng Việt có dấu | ✅ | Mọi nhãn/comment/tài liệu tiếng Việt; bản dịch EN thêm vào nhánh `_en`; giờ `HH:mm` và tên thương hiệu **không** dịch (FR-015) |
| Stack đã chốt (drift + GetX + fl_chart) | ✅ | **0 dependency mới**; không sửa `pubspec.yaml`; không dùng `flutter_local_notifications`/`timezone` (engine là PBI sau) |
| Design system: 1 màu thương hiệu teal, coral chỉ cho chi/cảnh báo, không hex cứng trong widget | ✅ | Màn này **không** dùng coral (không có ngữ cảnh cảnh báo); teal lấy từ `AppColors.teal` (chip/nút — khuôn nút form sẵn có) và `SoraColors.tealOnNeutral` (chữ giá trị đang chọn — theme-aware); **không** sửa `sora_colors.dart`/`app_theme.dart` |
| Màn cấp tab có bottom nav, **màn con không** | ✅ | `SubPageScaffold` (app bar teal + back) + `bottomNavigationBar` chỉ để ghim **nút Lưu**; **không** bottom nav, **không** FAB (FR-002); không đụng `AppShell` |
| Số dư ví là đại lượng suy ra, không sửa tay | ✅ | Màn **không** chạm bảng `wallets` (luật 23 data-model) |
| Thu/chi/chuyển khoản: transfer không tính là thu/chi | ✅ | Màn **không** đọc/ghi `transactions` — không có phép tính tiền nào |
| Không sửa dữ liệu người dùng ngoài phạm vi | ✅ | Chỉ upsert **1 row** `AppSettings` của chính nó (thêm 1 khoá, không xoá khoá nào khác — luật 9 PBI 28 giữ nguyên) |
| Không phá vỡ hành vi PBI trước | ✅ | Màn `01` chỉ **thêm** 1 tham số `onTap` cho **1** hàng + đổi cách bọc vùng chạm trong `_itemRow` (hành vi 2 hàng chevron giữ nguyên "chạm không mở gì"); `notification_prefs.dart` chỉ **thêm** trường (16 trường cũ + mặc định không đổi); `notification_store*.dart`/`app_database.dart` **không sửa** |
| YAGNI / không abstraction sớm | ✅ | 1 màn mới + 1 trường model + 2 hàm format + 1 tầng chip/timeline private; **không** controller, **không** bảng drift, **không** widget dùng chung mới, **không** token màu mới, **không** package mới |
| Quy trình PBI: spec → plan → task → implement | ✅ | Đang ở bước plan; `tasks.md` sinh ở bước sau |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại [research.md](./research.md). Tóm tắt các quyết định chính:

- **Nơi lưu ngày trong tuần (R1)** — **Quyết định**: thêm khoá `dailyWeekdays`
  vào **chính** row JSON `notificationPrefs` (schema **v8** giữ nguyên).
  **Lý do**: ngày trong tuần là tham số của **cùng loại nhắc** (doc §3.1 gom
  `weekdays` vào `config`); 1 upsert nguyên khối, không trạng thái nửa vời; parse
  tolerant sẵn có tự lo row cũ thiếu khoá (FR-013). **Phương án khác**: row riêng
  (2 lần ghi, có thể lệch); bảng `notification_rules` (v9 + migration cho dữ liệu
  chưa ai đọc); `shared_preferences` (package mới).
- **Kiểu tập ngày (R2)** — `List<int>` **sắp tăng, khác rỗng**, `1=T2…7=CN` (ISO,
  tuần bắt đầu Thứ Hai). **Lý do**: `Set` không có equality giá trị (phải sort mỗi
  lần so); sắp sẵn là dạng cần cho nén dải ở dòng phụ (R10). **Phương án khác**:
  `Set<int>`, bitmask, 7 cờ bool.
- **Bất biến "luôn ≥1 ngày" (R3)** — đặt ở **model**: `toggleDay(d)` trả về **chính
  object cũ** khi phép tắt làm tập rỗng (FR-009); thêm `isEveryDay`,
  `isDayEnabled(d)`. **Phương án khác**: chặn ở `onTap` (mọi đường ghi mới phải nhớ
  lại), cho phép rỗng rồi coi rỗng = "mỗi ngày" (hai nghĩa một trạng thái).
- **Khối chọn giờ (R4)** — **mũi tên ▲/▼** mỗi trục, đổi 1 đơn vị, quay vòng
  `(v+delta+n)%n`; **không** `ListWheelScrollView`. **Lý do**: mockup vẽ mũi tên;
  mọi SC đo được (miền + quay vòng) thoả bằng phép `%`, không cần controller/animation.
- **Dải nền nhạt (R5)** — nền của **ô giá trị đang chọn** ở mỗi trục (2 dải thẳng
  hàng), màu `tealOnNeutral` alpha 0.10; **không** `Stack` + toạ độ cứng (vỡ ở cỡ
  chữ lớn — FR-017).
- **Chip ngày (R6)** — `Wrap` + vòng tròn 36 px tự vẽ (`AppColors.teal` + chữ trắng
  khi chọn); nhãn chip clamp cỡ chữ ≤1.4 (7 chip gọn 1 hàng ở 360 px).
- **Nút Lưu (R7)** — ghim đáy (`bottomNavigationBar`, 44 px, khuôn 4 màn form đã QA).
- **Ngữ nghĩa ghi (R8)** — màn giữ **1 bản nháp** `_draft`; **chỉ** ghi khi bấm Lưu;
  back **bỏ** thay đổi, **0** hộp thoại (Q2=A, FR-007/SC-014); **không** ghi lại khi
  mở màn (khác màn `01` — không cần seed).
- **Hai vùng chạm (R9)** — `InkWell` chỉ bọc cụm *icon + tiêu đề + dòng phụ*; công
  tắc nằm **ngoài** (FR-001); `_switchRow` thêm `onTap` (mặc định null ⇒ 5 hàng còn
  lại y nguyên).
- **Dòng phụ màn `01` (R10)** — đủ 7 ngày → giữ chuỗi cũ `'@giờ mỗi ngày'`; thiếu →
  `'@giờ vào @ngày'` với **nén dải liên tiếp dài ≥3** (`T2–T7, CN` — đúng ví dụ
  kịch bản 13).
- **i18n (R11)** — 7 nhãn ngày viết **literal trước `.tr`** (switch expression) để
  `sora_translations_test` còn ràng buộc; ~10 khoá mới; `'Sora Thu Chi'` và `HH:mm`
  không dịch.
- **Khối xem trước (R12)** — thẻ tĩnh (vòng tròn `S` + tên app + câu nội dung + giờ
  góc phải); giờ đọc **trực tiếp** từ `_draft` ⇒ đổi ngay (SC-004).
- **Không chạm engine (R13)** — 0 plugin/quyền/lịch (FR-014, SC-009).
- **Kiểm thử (R14)** — 1 file mới + 4 file sửa, tái dùng `FakeNotificationStore`.
- **Xếp lớp (R15)** — `screens/daily_reminder_config_screen.dart` nhận
  `NotificationStore?`; màn `01` truyền `_store` khi push.
- **Không làm (R16)** — engine, quyền/channel, màn `03`/`04`, nhiều khung giờ, sửa
  nội dung thông báo, hộp thoại xác nhận, backup JSON.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem [data-model.md](./data-model.md) — **không đổi schema
  (v8)**; `NotificationPrefs` **+1 trường** (`dailyWeekdays`), `NotificationStore`
  **không đổi**; **24 luật bất biến** (mặc định/parse tập ngày, round-trip, đảo
  trạng thái ngày, ngữ nghĩa đọc-ghi của màn, dòng phụ, không đụng dữ liệu khác) +
  bảng vòng đời giá trị + bảng truy vết FR → luật.
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app thuần nội bộ, không
  API/CLI/endpoint lộ ra ngoài (đồng nhất PBI 19–28). Hợp đồng nội bộ duy nhất là
  seam `NotificationStore` **đã có** (giữ nguyên 2 phương thức).
- **Kịch bản khởi động nhanh**: xem [quickstart.md](./quickstart.md) — **13 nhóm
  kiểm thử tay A–M**, phủ FR-001…FR-018 và SC-001…SC-014, kèm mốc test trước PBI
  (**1004 pass + 1 đỏ có sẵn**) và 5 lệch nhỏ đã biết.

### Kiến trúc chi tiết

**1. Model — `lib/core/notification/notification_prefs.dart` (sửa, ~55 dòng thêm)**

| Thành phần | Vai trò |
|---|---|
| `final List<int> dailyWeekdays` | Mặc định `const [1,2,3,4,5,6,7]`; **1=T2…7=CN**, đã sắp tăng, khác rỗng |
| `bool get isEveryDay` | `dailyWeekdays.length == 7` — chọn chuỗi dòng phụ "mỗi ngày" (FR-011) |
| `bool isDayEnabled(int weekday)` | Trạng thái 1 chip (FR-004) |
| `NotificationPrefs toggleDay(int weekday)` | Đảo 1 ngày; tập còn 1 phần tử mà tắt ⇒ trả **chính object cũ** (FR-009) |
| `static List<int> _weekdays(Object? raw)` | Chuẩn hoá: không phải `List` → cả 7; lọc `int` ∈ 1…7, bỏ trùng, **sắp tăng**; rỗng → cả 7 (luật 2–7) |
| `toJson`/`fromSettings`/`copyWith`/`==`/`hashCode` | Thêm khoá `dailyWeekdays`; so list bằng `listEquals` (đã import `flutter/foundation.dart`), hash bằng `Object.hashAll` |

16 trường cũ (miền, mặc định, cách parse) **không đổi** ⇒ row PBI 28 đọc ra y
nguyên, chỉ thêm tập ngày mặc định.

**2. Nhãn ngày dùng chung — `lib/core/date_label.dart` (sửa, ~25 dòng thêm)**

```dart
/// 'T2'…'CN' theo ISO (1 = Thứ Hai). Literal trước `.tr` để test dịch ràng buộc.
String dayLabel(int weekday);            // 1 => 'T2'.tr … 7 => 'CN'.tr (ngoài miền → '')

/// Tập ngày → chuỗi cho dòng phụ màn `01`: nén dải liên tiếp dài >= 3
/// ([1..6] → 'T2–T7'), ngày rời liệt kê riêng, phân cách ', ' ([1,2,3,5] → 'T2–T4, T5').
String daysLabel(List<int> weekdays);
```

Đặt ở `date_label.dart` (nhà sẵn có của `formatClock`/`relativeDayLabel`, đã import
`get`) vì **hai màn** cùng cần (màn `01` dòng phụ, màn `02` nhãn chip) — tránh chép
lại 9 dòng ở hai file; unit test cạnh `date_label_test.dart` sẵn có.

**3. Màn mới — `lib/screens/daily_reminder_config_screen.dart` (MỚI, ~340 dòng)**

```
DailyReminderConfigScreen (StatefulWidget, nhận NotificationStore? store)
  initState → _load(): store.load() → setState(_draft)        // KHÔNG save (R8)
  state: _store · _draft (NotificationPrefs) · _loading · _error
  _stepHour(d)   → _draft.copyWith(dailyHour:  (_draft.dailyHour + d + 24) % 24)
  _stepMinute(d) → _draft.copyWith(dailyMinute: (_draft.dailyMinute + d + 60) % 60)
  _toggleDay(w)  → _draft.toggleDay(w)                         // FR-004/FR-009
  _toggleOnlyIfNoTxn(v) → _draft.copyWith(dailyOnlyIfNoTxnToday: v)
  _save()        → try store.save(_draft) catch(_){} ; Get.back()   // R8
  SubPageScaffold(title: 'Nhắc nhập giao dịch'.tr,               // FR-002
                  bottomNavigationBar: _saveBar())               // R7
    └ SafeArea(top:false) → ListView(padding bottom 16)
        ├ _SectionLabel('THỜI GIAN NHẮC'.tr)
        │   └ _timeBlock(colors)        // nền softCardBg bo 10
        ├ _SectionLabel('LẶP LẠI VÀO CÁC NGÀY'.tr)
        │   └ _dayChips(colors)         // Wrap 7 chip tròn 36
        ├ _toggleRow(colors)            // công tắc + dòng phụ (không nhãn nhóm)
        ├ _SectionLabel('XEM TRƯỚC THÔNG BÁO'.tr)
        │   └ _previewCard(colors)      // thẻ + giờ đọc từ _draft
```

| Widget con (private) | Ghi chú |
|---|---|
| `_timeBlock` | `Container(softCardBg, radius 10, padding (20,12))` → `Row` giữa: `_TimeColumn(giờ)` · `Text(':')` · `_TimeColumn(phút)` |
| `_TimeColumn(colors, value, prev, next, onUp, onDown)` | `Column`: `IconButton(▲, Icons.keyboard_arrow_up, colors.listLabel)` → `Text(prev)` (15 px, `tabInactive`) → ô giá trị đang chọn (`Container` bo 6, nền `tealOnNeutral` alpha 0.10, `Text` 26 px w600 **`tealOnNeutral`**) → `Text(next)` → `IconButton(▼)`; giá trị lân cận cũng quay vòng |
| `_DayChip(colors, weekday, selected, onTap)` | `InkWell` + `Container` tròn 36 px: chọn → nền `AppColors.teal` + nhãn `AppColors.white`; không chọn → nền `colors.surface` + viền `colors.divider` + nhãn `colors.tabInactive`; nhãn `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.4)` |
| `_toggleRow` | `Row`: cột `Expanded` (tiêu đề 15 px + dòng phụ 12 px) + `Switch` (**ngoài** `Expanded`); dòng phụ luôn hiển thị (FR-005) |
| `_previewCard` | `Container` bo 10, viền `colors.divider`, nền `colors.surface`; `Row`: vòng tròn 28 px `tealLightBg` + chữ `'S'` `tealOnNeutral` · cột `Expanded`(`'Sora Thu Chi'` + câu nội dung) · `Text(formatClock(...))` (`tabInactive`, 10 px) |
| `_SectionLabel` | Chép khuôn màn `01`/PBI 17 (viết hoa, `tabInactive`, 13 px w600, padding `(20,24,20,8)`) |
| `_saveBar()` | `SafeArea` + `Padding(20,10,20,12)` + `SizedBox(height: 44, width: double.infinity)` + `ElevatedButton` (`AppColors.teal`, chữ trắng, elevation 0, bo 8, 15 px w600) |

Nhánh thân màn giữ **khuôn 3 nhánh** của PBI 17/28: `_loading` → spinner; `_error` →
"Không đọc được cài đặt." + nút **Thử lại** (tái dùng khoá dịch sẵn có); còn lại →
danh sách.

**4. Màn `01` — `lib/screens/notification_settings_screen.dart` (sửa, ~35 dòng)**

```dart
// _itemRow: vùng chạm = hàng TRỪ trailing (R9) — công tắc không nằm trong InkWell
Row(children: [
  Expanded(child: onTap == null ? leading : InkWell(onTap: onTap, child: leading)),
  const SizedBox(width: 8),
  trailing,
])

// _switchRow: + VoidCallback? onTap  (mặc định null → 5 hàng còn lại y nguyên)
_switchRow(..., value: _prefs.dailyEnabled, onChanged: _toggleDaily,
           onTap: _openDailyConfig),

void _openDailyConfig() =>
    Get.to(() => DailyReminderConfigScreen(store: _store));   // cùng store (R9/R15)

// _dailySubtitle(): đủ 7 ngày → chuỗi cũ; thiếu → '@giờ vào @ngày' (R10)
```

**5. i18n — `lib/core/locale/sora_translations.dart` (sửa, ~17 khoá mới)**

Nhãn ngày `T2 T3 T4 T5 T6 T7 CN` → `Mon Tue Wed Thu Fri Sat Sun`; `'Nhắc nhập giao
dịch'`, `'THỜI GIAN NHẮC'`, `'LẶP LẠI VÀO CÁC NGÀY'`, `'Chỉ nhắc nếu chưa ghi giao
dịch'`, `'Bỏ qua nhắc nhở nếu hôm nay bạn đã nhập'`, `'XEM TRƯỚC THÔNG BÁO'`,
`'Đừng quên ghi lại thu chi hôm nay nhé!'`, `'Lưu thay đổi'`, `'@giờ vào @ngày'`.
Không cần bản đồ tiếng Việt (khoá = chính chuỗi tiếng Việt).

**6. Kiểm thử**

| File | Việc |
|---|---|
| `test/date_label_test.dart` | **SỬA** — `dayLabel(1) == 'T2'` … `dayLabel(7) == 'CN'` (và giá trị ngoài miền); `daysLabel([1..7]) == 'T2–T7, CN'`, `[1..6] == 'T2–T7'`, `[1,2,3,5] == 'T2–T4, T5'`, `[1,7] == 'T2, CN'`, `[3] == 'T3'`, danh sách rỗng → `''` |
| `test/notification_prefs_test.dart` | **SỬA** — luật 1–14 data-model: mặc định `[1..7]`; parse tolerant (thiếu khoá / `[]` / toàn phần tử sai / `null` / `"T2"` / số thực / phần tử 0 & 8 / trùng lặp → chuẩn hoá đúng, **không** ném); `toSettings` luôn ghi list sắp tăng; round-trip giữ tập ngày; `isEveryDay`; `toggleDay` thêm/bớt/`identical` khi còn 1 ngày/không chạm 15 trường khác |
| `test/daily_reminder_config_screen_test.dart` | **MỚI** — với `FakeNotificationStore`: đủ 3 nhãn nhóm + hàng công tắc + nút "Lưu thay đổi"; 2 trục hiện giá trị đang chọn + 2 lân cận; mũi tên ±1 và **quay vòng** 23↔00, 00↔59; **khối xem trước đổi ngay** cùng nhịp chạm mà `storedPrefs` **không** đổi; chạm chip chỉ đổi **chip đó**; chip cuối **không** tắt được; **back → store không ghi**; bấm Lưu → store nhận đúng `_draft` + pop; bấm Lưu khi không đổi gì vẫn pop; nhánh lỗi đọc + **Thử lại**; cỡ chữ 2.0 + màn 360×640 không overflow |
| `test/notification_settings_screen_test.dart` | **SỬA** — chạm vùng tiêu đề/dòng phụ hàng nhắc hàng ngày → **đúng 1 route** `DailyReminderConfigScreen`; chạm **công tắc** → 0 route mới, chỉ đổi trạng thái; dòng phụ theo tập ngày (3 tập mẫu); 5 hàng công tắc còn lại **không** mở màn nào; 2 hàng chevron vẫn **no-op** |
| `test/dark_theme_smoke_test.dart` | **SỬA** — thêm màn `02` (đăng ký `FakeNotificationStore`) vào danh sách smoke theme tối: không overflow, token tối thật sự áp (`softCardBg`/`background`) |
| `test/fakes/fake_notification_store.dart` | **TÁI DÙNG** nguyên trạng (đã có `storedPrefs` + `failLoad`) — chỉ sửa nếu test cần thêm khả năng assert |

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline hoàn toàn | ✅ | Chỉ sqlite local; không mã nào import plugin thông báo; 0 quyền, 0 lịch (R13) |
| Tiếng Việt có dấu | ✅ | ~17 khoá dịch thêm vào nhánh `_en`; không có chuỗi tiếng Anh trần ngoài nhánh đó |
| Stack đã chốt | ✅ | **0 dependency mới**, 0 package, 0 cấu hình native; `pubspec.yaml` không sửa |
| Design system & token màu | ✅ | Không hex cứng trong widget (dùng `AppColors.teal`/`SoraColors.*`); **không** dùng coral; không sửa `sora_colors.dart`/`app_theme.dart` |
| Số dư ví suy ra / transfer không tính thu chi | ✅ | Không đọc/ghi `wallets`/`transactions` — không có phép tính tiền |
| Màn con không bottom nav | ✅ | `SubPageScaffold`; `bottomNavigationBar` chỉ chứa **nút Lưu** (không phải nav) |
| Không phá vỡ PBI trước | ✅ | Màn `01`: +1 tham số `onTap`, đổi cách bọc vùng chạm (hành vi chevron giữ nguyên); model: chỉ **thêm** trường mới (16 trường cũ không đổi); `notification_store*.dart`, `app_database.dart`, `utilities_screen.dart` **không sửa** |
| YAGNI | ✅ | 1 màn + 1 trường model + 2 hàm format + ~17 khoá dịch; **không** controller/bảng/package/widget dùng chung/token mới |
| Bảo mật & riêng tư | ✅ | Không log dữ liệu, không gửi đi đâu; cấu hình nằm trong DB local như mọi cài đặt khác; màn chỉ mở được **sau** khi đã mở khoá app (PIN — PBI 3) |
| Không ghi dữ liệu người dùng ngoài phạm vi | ✅ | 1 row `AppSettings` (upsert, thêm 1 khoá); không xoá row nào khác (luật 9 PBI 28) |

## Cấu trúc dự án dự kiến

```text
.specify/specs/29/
├── spec.md          (đã có)
├── checklists/      (đã có)
├── research.md      (MỚI — R1…R16)
├── data-model.md    (MỚI — +1 trường, 24 luật, truy vết FR)
├── quickstart.md    (MỚI — QA tay A–M)
├── plan.md          (MỚI — file này)
└── tasks.md         (bước sau: /sora-task 29)

app/sora_thu_chi/
├── lib/core/notification/notification_prefs.dart   (SỬA: +dailyWeekdays +toggleDay
│                                                    +isEveryDay +_weekdays; 16 trường cũ giữ nguyên)
├── lib/core/date_label.dart                        (SỬA: +dayLabel, +daysLabel)
├── lib/core/locale/sora_translations.dart          (SỬA: +~17 khoá en)
├── lib/screens/daily_reminder_config_screen.dart   (MỚI: màn 02)
├── lib/screens/notification_settings_screen.dart   (SỬA: vùng chạm hàng nhắc hàng
│                                                    ngày + điểm vào màn 02 + dòng phụ theo tập ngày)
└── test/
    ├── daily_reminder_config_screen_test.dart      (MỚI)
    ├── date_label_test.dart                        (SỬA)
    ├── notification_prefs_test.dart                (SỬA)
    ├── notification_settings_screen_test.dart      (SỬA)
    └── dark_theme_smoke_test.dart                  (SỬA)

KHÔNG đụng: lib/core/notification/notification_store.dart,
            lib/data/notification_store_drift.dart, lib/data/notification_deps.dart,
            lib/data/db/app_database.dart (schema giữ v8 — không migration,
            không build_runner), lib/screens/utilities_screen.dart, lib/screens/
            settings_screen.dart, lib/theme/*, lib/core/widgets/*,
            lib/core/app_shell.dart, pubspec.yaml, docs/, wiki-knowledge/
            (wiki cập nhật ở bước sau — skill sora-wiki)

TÁI DÙNG nguyên trạng: test/fakes/fake_notification_store.dart (PBI 28)
```

## Rủi ro & ngoại lệ có lý do

### Ngoại lệ có lý do

| # | Ngoại lệ | Lý do |
|---|---|---|
| 1 | **Không dựng bảng `NotificationRule`** như doc §3.1 — tập ngày nằm trong row JSON `notificationPrefs` | Bảng đó phục vụ **engine** (lên lịch, `lastFiredAt` chống trùng) — **ngoài phạm vi** (Q1 của PBI 28). `weekdays` là tham số cấu hình của **người dùng** ⇒ đúng chỗ trong row cấu hình; dựng bảng riêng là migration v9 + `build_runner` cho dữ liệu chưa ai đọc (research R1) |
| 2 | **Không dựng trục cuộn thật** (`ListWheelScrollView`/`CupertinoPicker`) — chỉ mũi tên ▲/▼ | Mockup vẽ mũi tên; FR-003 đòi mũi tên; mọi SC đo được (miền 0–23/0–59 + quay vòng hai đầu) thoả bằng phép `%`. Trục cuộn thêm controller/animation/canh giữa = bề mặt lỗi mới cho **0** yêu cầu đo được (research R4) |
| 3 | **Nút "Lưu thay đổi" ghim đáy** thay vì nằm cuối nội dung như mockup | Khuôn 4 màn form đã QA; FR-017/SC-012 chỉ đòi "cuộn tới được nút Lưu" — nút ghim thì **luôn** tới được, kể cả cỡ chữ lớn nhất (research R7; quickstart §4.1) |
| 4 | **Dải nền nhạt tách theo từng ô giá trị** thay vì 1 dải liền qua dấu `:` như mockup | FR-003 chỉ đòi "dải nền nhạt đánh dấu hàng đang chọn"; dải theo ô giá trị không dùng toạ độ cứng nên **không vỡ** ở cỡ chữ lớn (research R5; quickstart §4.2) |
| 5 | **Nhãn chip ngày clamp cỡ chữ ≤1.4×** | Giữ 7 vòng tròn 36 px nằm gọn trên 1 hàng ở màn 360 px; edge case của spec cho phép "chip xuống hàng hoặc thu nhỏ khoảng cách nhưng không cắt nhãn" (research R6; quickstart §4.3) |
| 6 | **Sửa `_itemRow` dùng chung của màn `01`** (vùng chạm = hàng trừ `trailing`) | FR-001 đòi **hai vùng chạm tách biệt** trên **một** hàng — nếu chỉ truyền `onTap` cho hàng đó thì chạm công tắc sẽ vừa toggle vừa mở màn (vi phạm FR-001). Tách trong widget dùng chung là **một** chỗ sửa; hệ quả duy nhất: 2 hàng chevron mất phản hồi mực ở đúng icon chevron, hành vi "chạm không mở gì" **không** đổi (research R9; quickstart §4.4) |
| 7 | **Không có hộp thoại "bỏ thay đổi chưa lưu"** khi back | Q2=A chốt rõ; SC-014 đo "0 hộp thoại hỏi lại" |
| 8 | **Dòng phụ màn `01` dùng dạng nén dải** (`T2–T7, CN`) | Bám **đúng** ví dụ ở kịch bản chấp nhận 13; ngưỡng nén ≥3 để 2 ngày rời vẫn liệt kê (`T2, CN`) (research R10; quickstart §4.5) |

### Rủi ro & ứng phó

| # | Rủi ro | Ứng phó |
|---|---|---|
| 1 | **Thiếu bản dịch EN** cho một khoá mới (kể cả 7 nhãn ngày) ⇒ `sora_translations_test` đỏ | Viết nhãn ngày bằng **literal trước `.tr`** (switch) chứ không gom vào `const List` (gom sẽ **lọt lưới** test — research R11); thêm khoá dịch **cùng lúc** với màn; chạy `flutter test test/sora_translations_test.dart` ngay sau khi viết màn |
| 2 | **Test đỏ có sẵn** `transactions_dao_test` dễ bị nhầm là lỗi mới | Ghi rõ mốc baseline **1004 pass / 1 fail** ở plan + quickstart §5; mục tiêu **không tăng** số test đỏ |
| 3 | **Sửa `_itemRow` làm vỡ test PBI 28** (hit-test/ink/vùng chạm) | Chạy `flutter test test/notification_settings_screen_test.dart` + `test/settings_screen_test.dart` ngay sau khi sửa; test cũ khẳng định "2 hàng chevron no-op, 6 công tắc độc lập" phải còn xanh |
| 4 | **Parse tập ngày** nhận dữ liệu bẩn (DB sửa tay, ghi dở) | Chuẩn hoá ở **một** chỗ (`_weekdays`) + 8 ca test riêng (luật 1–7): thiếu khoá/`[]`/phần tử sai/null/số thực/0 & 8/trùng lặp/rỗng |
| 5 | **Cỡ chữ lớn** làm 7 chip tràn hoặc khối thời gian đè nhau | `Wrap` cho chip + clamp 1.4 cho nhãn chip + dải nền theo ô (không toạ độ cứng) + nút Lưu ghim đáy; test surfaceSize 360×640 + `textScaleFactor 2.0` (tiền lệ `wallet_transfer_screen_test`) |
| 6 | **Chế độ Tối**: chip đang chọn (`AppColors.teal` + chữ trắng) có thể chìm trên nền tối | Màn dùng `colors.surface`/`softCardBg`/`tealOnNeutral` cho mọi phần còn lại; QA nhóm L2 kiểm tương phản; nếu chìm ⇒ đổi nền chip chọn sang `colors.tealOnNeutral` + chữ `colors.surface` (thay đổi 2 dòng, phải QA lại L2/L4) |
| 7 | **Quên "không ghi khi mở màn"** (màn `01` có ghi, dễ chép nhầm sang màn `02`) | Luật 15 + test "mở màn → `storedPrefs` không đổi"; ngữ nghĩa bản nháp ghi rõ ở plan §1/§3 + docstring màn |
| 8 | **iOS chưa từng QA** ở các PBI trước | PBI này **0 plugin native mới** — rủi ro thấp; nếu có máy, chạy nhanh nhóm A/B/D/F |
| 9 | **Row cũ PBI 28 mất dữ liệu** khi ghi lại (ví dụ ghi `dailyWeekdays` rỗng ghi đè) | Luật 5 (rỗng ⇒ cả 7 ngày) + luật 8–9 (round-trip) + QA nhóm G6 (DB cũ thiếu khoá) và G8 (`[]` trong DB) |
