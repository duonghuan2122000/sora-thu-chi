# Kế hoạch triển khai: Cài đặt Thông báo & nhắc nhở (màn Cài đặt)

**Mã PBI**: 28
**Liên kết spec**: [.specify/specs/28/spec.md](./spec.md)
**Ngày tạo**: 2026-09-13

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12 / Flutter (Android + iOS), app **offline hoàn toàn** (không đăng nhập, không server) |
| Framework / Thư viện chính | GetX `^4.7.3` (điều hướng + DI + i18n), Material. **Không thêm dependency** — đợt này chỉ dùng những gì repo đã có (`Switch`, icon Material, `SoraColors`) |
| Lưu trữ dữ liệu | drift `^2.34.4` — **schema giữ nguyên v8** (PBI 24): chỉ **thêm 1 row** vào bảng key-value `AppSettings` đã có (PBI 17); **không** bảng/cột/migration, **không** `build_runner` |
| Kiểm thử | `flutter_test` — mốc trước PBI: **960 pass + 1 test đỏ CÓ SẴN** (`transactions_dao_test`, từ PBI 11); thêm **3 file test mới** + **sửa 2 file** + 1 fake; mục tiêu **không tăng** số test đỏ. Luật parse/lưu kiểm ở **tầng thuần**; màn kiểm bằng store giả (không cần sqlite native) |
| Nền tảng triển khai | Build local (`flutter build apk` / iOS build) — không server, không CI đặc biệt, không cấu hình native mới |
| Ràng buộc hiệu năng | Không có ngân sách thời gian đặc biệt: màn đọc **1 row** và ghi **1 row** (upsert) mỗi lần chạm — không truy vấn bảng nghiệp vụ nào, không tính toán nặng |
| Ràng buộc khác | Ngôn ngữ giao diện/tài liệu/commit: **tiếng Việt có dấu**; bám Design System (teal `#0F6E56` = hành động/bật; coral `#D85A30` **chỉ** cho ngữ cảnh cảnh báo chi tiêu — 2 hàng nhóm NGÂN SÁCH); mọi màu đi qua token `SoraColors`; **mọi nhãn tĩnh phải có bản dịch EN** (PBI 19 — test `sora_translations_test` quét `lib/` và đỏ nếu thiếu) |
| Nguồn chân lý nghiệp vụ | `docs/notification/notification-solution.md` (§2 bảng 5 loại + nguyên tắc "mỗi loại có công tắc độc lập", §3.1 data model, §4 mockup `01`) + mockup `docs/notification/01-cai-dat-thong-bao.svg`; kế thừa PBI 17 (bảng `AppSettings`, khuôn `UtilitiesScreen` + seam store), PBI 18 (`SoraColors` 2 theme), PBI 19 (khoá dịch = chuỗi tiếng Việt), PBI 13/17 (điểm vào no-op) |

*Không còn mục `NEEDS CLARIFICATION`: spec đã "Đã làm rõ" (Q1/Q2/Q3 chốt 1A/2A/3A
ngày 2026-09-13, ghi ở mục "Quyết định đã chốt"); các quyết định còn lại là chi
tiết triển khai — xem [research.md](./research.md) (R1…R14).*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

`.specify/memory/constitution.md` **không tồn tại** (repo chưa tạo hiến pháp) ⇒
đối chiếu theo `CLAUDE.md` của repo và các quyết định đã chốt trong `docs/`.

| Nguyên tắc (nguồn: CLAUDE.md + docs) | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline hoàn toàn, không server/không auth | ✅ | Cấu hình nằm trong sqlite local; **không** lời gọi mạng nào; **không** xin quyền thông báo, **không** bắn thông báo (FR-012) |
| Ngôn ngữ giao diện/tài liệu/commit: tiếng Việt có dấu | ✅ | Mọi nhãn/comment/tài liệu tiếng Việt; bản dịch EN thêm vào nhánh `_en`; **giờ và định dạng ngày/số không dịch** (FR-015) |
| Stack đã chốt (drift + GetX + fl_chart) | ✅ | **Không** thêm dependency, không đổi stack; `Switch`/icon là Material sẵn có |
| Design system: 1 màu thương hiệu teal, coral chỉ cho chi/cảnh báo, không hex cứng trong widget | ✅ | Chỉ **đọc** token `SoraColors` đã có (`tealLightBg`/`tealOnNeutral`/`coralLightBg`/`coralOnNeutral`/`listDivider`); **không** sửa `sora_colors.dart`/`app_theme.dart`; coral **đúng** ngữ nghĩa (2 hàng nhóm NGÂN SÁCH — FR-004) |
| Số dư ví là đại lượng suy ra, không sửa tay | ✅ | Màn **không** chạm bảng `wallets` (data-model luật 17) |
| Thu/chi/chuyển khoản: transfer không tính là thu/chi | ✅ | Màn **không** đọc/ghi `transactions` — không có phép tính tiền nào trong PBI này |
| Màn cấp tab có bottom nav, **màn con không** | ✅ | `SubPageScaffold` (app bar teal + back, không bottom nav, không FAB); **không** đụng `AppShell`/`AppBottomNavBar` |
| Không sửa dữ liệu người dùng ngoài phạm vi | ✅ | Chỉ ghi **1 row** `AppSettings` của chính nó; upsert không xoá row khác (khoá PBI 17/24 nguyên vẹn — data-model luật 9) |
| Không phá vỡ hành vi PBI trước | ✅ | Màn Cài đặt chỉ **thêm 1 hàng** + 1 seam callback (khuôn 3 hàng đã có); `utilities_screen.dart`/`app_database.dart`/`sora_colors.dart` **không sửa**; `date_label.dart` chỉ **thêm** hàm (hành vi `formatTimeLabel` giữ nguyên) |
| YAGNI / không abstraction sớm | ✅ | 1 màn mới + 2 file core nhỏ + 2 file data + 1 fake; **không** controller, **không** bảng drift mới, **không** widget dùng chung mới, **không** token màu mới, **không** package mới; 16 tham số lưu đúng những gì có hiển thị (research R3) |
| Quy trình PBI: spec → plan → task → implement | ✅ | Đang ở bước plan; `tasks.md` sinh ở bước sau |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại [research.md](./research.md). Tóm tắt các quyết định chính:

- **Nơi lưu (R1)** — **Quyết định**: **1 row JSON** key `notificationPrefs` trong
  bảng `AppSettings` đã có (schema **v8** giữ nguyên). **Lý do**: bảng key-value
  sinh ra đúng cho việc này, PBI sau chỉ thêm row; tiền lệ `scanDeviceCheck`
  (PBI 24) cũng `jsonEncode` một object phức. **Phương án khác**: 16 row phẳng
  (lệch trạng thái dễ, 16 upsert cho lần mở đầu); bảng `notification_rules` riêng
  (cần migration v9 + `build_runner`, mà `lastFiredAt` chỉ có nghĩa khi engine tồn
  tại — PBI sau); `shared_preferences` (package mới, lệch "mọi local trong drift").
- **Ghi mặc định lần mở đầu (R2)** — **Quyết định**: màn `load()` rồi `save()`
  ngay bộ vừa đọc (idempotent) ⇒ FR-007/FR-008 thoả, seam giữ nguyên khuôn 2
  phương thức. **Phương án khác**: seam `loadEnsuringDefaults()` (gấp đôi bề mặt),
  `load()` tự ghi (side-effect ẩn), chỉ ghi khi người dùng chạm (vi phạm kịch bản 6).
- **Tham số lưu (R3)** — 16 trường: 6 cờ bật/tắt + giờ nhắc hàng ngày (20:30, cờ
  "chỉ nhắc nếu chưa ghi"), ngưỡng 80%/100%, nhắc trước 3 ngày, giờ tổng kết
  tuần/tháng. **Hoãn có lý do**: danh sách ngày trong tuần (chưa có UI chọn),
  chu kỳ/mốc % của mục tiêu (per-mục-tiêu, GĐ3), thứ của tổng kết tuần (mockup cố
  định Chủ nhật), ngưỡng riêng từng ngân sách (ngoài phạm vi) — xem "Ngoại lệ".
- **Parse chịu lỗi (R4)** — JSON hỏng/thiếu khoá/sai kiểu/ngoài miền → **mặc định
  an toàn**, không bao giờ ném (tiền lệ `UtilitiesPrefs`/`ScanSettings`).
- **Kiến trúc màn (R5)** — `StatefulWidget` + seam store bơm được + ghi bám đuôi
  (`_saveTail`), **không** GetX controller (khuôn PBI 17; chưa màn nào khác tiêu thụ
  state này ở đợt này).
- **Điểm vào (R6)** — +1 hàng "Thông báo & nhắc nhở" trong nhóm **KHÁC**, ngay sau
  "Tiện ích & Cá nhân hóa", + seam `onManageNotificationsTap` (khuôn 3 hàng cũ).
- **Bố cục (R7)** — viết lại tại chỗ khuôn màn Tiện ích (`_SectionLabel`,
  `_ItemRow` 36 px, divider **giữa các hàng trong nhóm**); **không** nâng widget
  dùng chung (tránh sửa màn đã QA); đường kẻ bám khuôn code, không bám lỗi đồ hoạ
  của mockup.
- **Màu & icon (R8)** — 2 hàng nhóm NGÂN SÁCH coral (`coralLightBg` +
  `coralOnNeutral`), 6 hàng còn lại teal; icon Material map từ mockup
  (`notifications_none`, `warning_amber_rounded`, `event_outlined`,
  `track_changes`, `pie_chart_outline`, `chevron_right`); công tắc dùng màu
  `ColorScheme` như PBI 17/24 (không thêm `switchTheme`).
- **Định dạng giờ (R9)** — thêm `formatClock(int, int)` vào `date_label.dart`
  (2 dòng, tái dùng `_two` sẵn có) thay vì viết lại padLeft lần thứ 5.
- **Dòng phụ & i18n (R10)** — dựng ở tầng màn bằng `.trParams` với khoá có
  placeholder (giờ/số **không** dịch); mọi khoá là literal trước `.tr` nên test
  dịch quét `lib/` bắt buộc phải có bản dịch EN.
- **Hàng chevron (R11)** — `InkWell` handler rỗng (tiền lệ "điểm vào no-op" PBI
  13/17): 0 màn mới, 0 thông báo lỗi (SC-008).
- **Xếp lớp file (R12)** — `core/notification/` (prefs + seam),
  `data/notification_store_drift.dart` + `data/notification_deps.dart`,
  `screens/notification_settings_screen.dart`, `test/fakes/fake_notification_store.dart`
  — để **engine** PBI sau ở cùng thư mục.
- **Kiểm thử (R13)** — 3 file mới + 2 file sửa + 1 fake (chi tiết ở §Kiểm thử).
- **Không làm (R14)** — không engine, không plugin thông báo/quyền, không màn
  `02/03/04` của doc, không `NotificationLog`, không dependency, không schema.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem [data-model.md](./data-model.md) — **không đổi schema
  (v8)**; 3 thực thể (`NotificationPrefs` 16 trường + miền hợp lệ + mặc định, bảng
  hàng 5 nhóm/8 hàng, hình dạng JSON row) + seam `NotificationStore` + **17 luật
  bất biến** + bảng vòng đời giá trị + bảng truy vết FR → luật.
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app thuần nội bộ, không
  API/CLI/endpoint lộ ra ngoài (đồng nhất PBI 19–27). Hợp đồng nội bộ duy nhất mới
  là seam `NotificationStore` (2 phương thức, mô tả ở data-model §1.4).
- **Kịch bản khởi động nhanh**: xem [quickstart.md](./quickstart.md) — **11 nhóm
  kiểm thử tay A–K**, phủ FR-001…FR-018 và SC-001…SC-012, kèm mốc test trước PBI
  (960 pass + 1 đỏ có sẵn) và 4 lệch nhỏ đã biết.

### Kiến trúc chi tiết

**1. Tầng nghiệp vụ thuần — `lib/core/notification/notification_prefs.dart` (MỚI, ~150 dòng)**

| Thành phần | Vai trò |
|---|---|
| `kKeyNotificationPrefs = 'notificationPrefs'` | Khoá row trong bảng `AppSettings` (khớp nếp `kKeyHideBalance`, `kKeyScanEnabled`) |
| `class NotificationPrefs` (bất biến, `const`) | 16 trường §1.1 data-model; constructor có **mặc định** = bộ FR-008 |
| `copyWith({...})` | Chỉ đổi trường được truyền — UI gọi `copyWith(dailyEnabled: v)` ⇒ luật 11/12 |
| `toSettings()` / `fromSettings(Map<String, String>)` | `jsonEncode`/`jsonDecode` + parse tolerant (luật 1–6); clamp miền hợp lệ |
| `static const defaults` | Bộ mặc định dùng cho cả constructor lẫn nhánh lỗi parse |

Thuần Dart (không `Widget`, không `.tr`) ⇒ test tầng thấp không cần binding.

**2. Seam — `lib/core/notification/notification_store.dart` (MỚI, ~15 dòng)**

```dart
abstract class NotificationStore {
  Future<NotificationPrefs> load();            // key vắng → cả bộ mặc định
  Future<void> save(NotificationPrefs prefs);  // upsert 1 row, KHÔNG xoá row khác
}
```

**3. Impl drift — `lib/data/notification_store_drift.dart` (MỚI, ~28 dòng)**

Bám **nguyên khuôn** `DriftUtilitiesStore`: `select(appSettings)` → map
`{key: value}` → `NotificationPrefs.fromSettings`; `save` = `insertOnConflictUpdate`
**chỉ 1 row** `notificationPrefs`. Không `build_runner` (dùng lại `AppSettingsCompanion`
đã sinh ở v8).

**4. Đăng ký DI — `lib/data/notification_deps.dart` (MỚI, ~18 dòng)**

`ensureNotificationStore()` — GetX singleton, tạo **đúng 1** `DriftNotificationStore(AppDatabase())`;
test đăng ký fake trước ⇒ trả fake, không mở drift (bám `ensureUtilitiesStore`).

**5. Màn mới — `lib/screens/notification_settings_screen.dart` (MỚI, ~340 dòng)**

```
NotificationSettingsScreen (StatefulWidget, nhận NotificationStore? store)
  initState → _load(): store.load() → setState(_prefs) → store.save(_prefs)   // R2
  _prefs · _loading · _error · _saveTail                                        // R5
  SubPageScaffold(title: 'Thông báo & nhắc nhở'.tr)                             // FR-002
    └ SafeArea(top: false) → ListView (padding bottom 48)
        ├ _SectionLabel('NHẮC NHỞ HÀNG NGÀY'.tr)
        │   └ _switchRow(bell, teal, _prefs.dailyEnabled, _toggleDaily)
        ├ _SectionLabel('NGÂN SÁCH'.tr)
        │   ├ _switchRow(warning, coral, _prefs.budgetEnabled, _toggleBudget)
        │   └ _navRow(warning, coral, 'Ngưỡng cảnh báo', chevron)              // no-op
        ├ _SectionLabel('GIAO DỊCH ĐỊNH KỲ'.tr)
        │   ├ _switchRow(calendar, teal, …recurringEnabled)
        │   └ _navRow(calendar, teal, 'Nhắc trước', chevron)                   // no-op
        ├ _SectionLabel('MỤC TIÊU TIẾT KIỆM'.tr)
        │   └ _switchRow(target, teal, _prefs.goalEnabled)
        └ _SectionLabel('TỔNG KẾT TỰ ĐỘNG'.tr)
            ├ _switchRow(pie, teal, …weeklyEnabled)
            └ _switchRow(pie, teal, …monthlyEnabled)
```

| Widget con (private, viết lại theo khuôn PBI 17) | Ghi chú |
|---|---|
| `_SectionLabel` | Nhãn nhóm viết hoa, màu `tabInactive`, 13 px w600, padding `(20, 24, 20, 8)` |
| `_ItemRow(colors, icon, iconColor, name, subtitle, trailing, onTap)` | Vòng tròn 36 px nền `tealLightBg`/`coralLightBg` + glyph 20 px `tealOnNeutral`/`coralOnNeutral`; cột giữa `Expanded` (tiêu đề `maxLines: 1` + ellipsis, dòng phụ **wrap tự nhiên**); `trailing` cuối hàng; có `onTap` → `InkWell` |
| `_switchRow(...)` | `trailing: Switch(value:, onChanged:)` |
| `_navRow(...)` | `trailing: Icon(Icons.chevron_right, color: colors.tabInactive)`, `onTap` = handler rỗng (R11) |
| `_rows(rows)` | Chèn `Divider(color: colors.listDivider, height: 1)` **giữa** các hàng trong nhóm |
| Dòng phụ | 8 getter/builder dùng `.trParams` (R10) + `formatClock(...)` (R9) |

Nhánh thân màn giữ **khuôn 3 nhánh** của PBI 17: `_loading` → spinner; `_error` →
"Không đọc được cài đặt." + nút **Thử lại**; còn lại → danh sách.

**6. Điểm vào — `lib/screens/settings_screen.dart` (sửa, ~12 dòng)**

```dart
_SettingsRow(
  label: 'Thông báo & nhắc nhở'.tr,
  onTap: () => _openManageNotifications(context),
  trailing: Icon(Icons.chevron_right, color: colors.tabInactive),
),
```

Đặt **ngay sau** hàng "Tiện ích & Cá nhân hóa" (nhóm KHÁC) + seam
`onManageNotificationsTap` trong constructor (khuôn 3 seam đã có) + hàm
`_openManageNotifications` push `NotificationSettingsScreen`.

**7. Tiện ích dùng chung — `lib/core/date_label.dart` (sửa, 2 dòng)**

```dart
String formatClock(int hour, int minute) => '${_two(hour)}:${_two(minute)}';
String formatTimeLabel(DateTime d) => formatClock(d.hour, d.minute); // hành vi cũ giữ nguyên
```

**8. i18n — `lib/core/locale/sora_translations.dart` (sửa, ~20 khoá mới)**

Khoá mới (đều là literal tiếng Việt, thêm vào nhánh `_en`): tiêu đề app bar; hàng
Cài đặt mới; 5 nhãn nhóm; 8 tiêu đề hàng; 8 dòng phụ/khoá có placeholder
(`'@giờ mỗi ngày'`, `' · chỉ nhắc nếu chưa ghi'`, `'Khi đạt @sớm% và khi vượt @vượt%'`,
`'Sớm: @sớm% · Vượt mức: @vượt%'`, `'Tiền điện, tiền nhà, trả nợ...'`,
`'@n ngày trước hạn thanh toán'`, `'Theo chu kỳ đã đặt cho từng mục tiêu'`,
`'Chủ nhật hằng tuần, @giờ'`, `'Ngày cuối tháng, @giờ'`, `'Không đọc được cài đặt.'`,
`'Thử lại'` — khoá cuối tái dùng nếu đã có). Không cần bản đồ tiếng Việt (khoá =
chính chuỗi tiếng Việt).

**9. Kiểm thử**

| File | Việc |
|---|---|
| `test/notification_prefs_test.dart` | **MỚI** — 17 luật: mặc định; parse tolerant (JSON rác, `null`, mảng, thiếu khoá, sai kiểu, giờ 24/phút 60/% 150/ngày âm, chuỗi rỗng); round-trip; `copyWith` chỉ đổi 1 loại + giữ tham số khi tắt + tắt hết vẫn hợp lệ; `formatClock(20, 5) == '20:05'` |
| `test/notification_store_drift_test.dart` | **MỚI** — DB in-memory + skip-guard host thiếu sqlite native (khuôn `utilities_store_drift_test`): `schemaVersion == 8`; key vắng → mặc định; round-trip; `save` không xoá khoá `hideBalance`/`scanEnabled` |
| `test/notification_settings_screen_test.dart` | **MỚI** — màn với `FakeNotificationStore`: đủ 5 nhãn nhóm + 8 tiêu đề hàng + 8 dòng phụ đúng nội dung; **6 Switch + 2 chevron, không hàng nào có cả hai**; sắc icon 2 hàng ngân sách là coral còn 6 hàng kia teal (soi `Container` decoration); chạm công tắc → chỉ hàng đó đổi + `store.storedPrefs` cập nhật; chevron → 0 route mới, 0 dialog/SnackBar; mở lần đầu ghi mặc định vào store; mở lại sau khi đổi → đúng trạng thái; cỡ chữ 2.0 + màn 360×640 không tràn, cuộn tới hàng cuối |
| `test/settings_screen_test.dart` | **SỬA** — thêm "Thông báo & nhắc nhở" vào danh sách thứ tự hàng; chạm → mở `NotificationSettingsScreen` (đăng ký fake store để không mở drift); back về; bơm `onManageNotificationsTap` → gọi callback, không push |
| `test/dark_theme_smoke_test.dart` | **SỬA** — thêm màn mới vào danh sách smoke giao diện tối (không overflow, token tối thật sự áp) |
| `test/fakes/fake_notification_store.dart` | **MỚI** — bản bộ nhớ của seam (`storedPrefs` để assert), bám `FakeUtilitiesStore` |

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline hoàn toàn | ✅ | Chỉ sqlite local; không mã nào gọi mạng/plugin thông báo; không xin quyền (FR-012) |
| Tiếng Việt có dấu | ✅ | ~20 khoá dịch thêm vào nhánh `_en`; không có chuỗi tiếng Anh trần ngoài nhánh đó |
| Stack đã chốt | ✅ | **0 dependency mới**, 0 package, 0 cấu hình native; không sửa `pubspec.yaml` |
| Design system & token màu | ✅ | Không hex cứng, không sửa `sora_colors.dart`/`app_theme.dart`; coral chỉ ở nhóm NGÂN SÁCH |
| Số dư ví suy ra / transfer không tính thu chi | ✅ | PBI này không đọc/ghi `wallets`/`transactions` — không có phép tính tiền |
| Màn con không bottom nav | ✅ | `SubPageScaffold`; không đụng `AppShell` |
| Không phá vỡ PBI trước | ✅ | Chỉ **thêm**: 1 màn, 2 file core, 2 file data, 1 fake, ~20 khoá dịch, 1 hàng ở màn Cài đặt, 1 hàm ở `date_label.dart`; `utilities_screen.dart`, `app_database.dart`, `scan_*`, `report_*` **không sửa** |
| YAGNI | ✅ | Không controller/bảng/package/widget dùng chung/token mới; 16 tham số lưu đúng những gì có hiển thị (R3) |
| Bảo mật & riêng tư | ✅ | Không log dữ liệu, không gửi đi đâu; cấu hình nằm trong DB local như mọi cài đặt khác; màn chỉ mở được **sau** khi đã mở khoá app (PIN — PBI 3) |
| Không ghi dữ liệu người dùng ngoài phạm vi | ✅ | 1 row `AppSettings`; upsert không xoá row khác (luật 9) |

## Cấu trúc dự án dự kiến

```text
.specify/specs/28/
├── spec.md          (đã có)
├── checklists/      (đã có)
├── research.md      (MỚI — R1…R14)
├── data-model.md    (MỚI — 16 trường + 17 luật + truy vết FR)
├── quickstart.md    (MỚI — QA tay A–K)
├── plan.md          (MỚI — file này)
└── tasks.md         (bước sau: /sora-task 28)

app/sora_thu_chi/
├── lib/core/notification/
│   ├── notification_prefs.dart        (MỚI: 16 trường + JSON tolerant + mặc định)
│   └── notification_store.dart        (MỚI: seam NotificationStore)
├── lib/data/
│   ├── notification_store_drift.dart  (MỚI: DriftNotificationStore)
│   └── notification_deps.dart         (MỚI: ensureNotificationStore)
├── lib/screens/
│   ├── notification_settings_screen.dart (MỚI: màn Cài đặt Thông báo & nhắc nhở)
│   └── settings_screen.dart           (SỬA: +1 hàng + seam onManageNotificationsTap)
├── lib/core/date_label.dart           (SỬA: +formatClock, formatTimeLabel gọi lại)
├── lib/core/locale/sora_translations.dart (SỬA: +~20 khoá en)
└── test/
    ├── notification_prefs_test.dart          (MỚI)
    ├── notification_store_drift_test.dart    (MỚI)
    ├── notification_settings_screen_test.dart(MỚI)
    ├── fakes/fake_notification_store.dart    (MỚI)
    ├── settings_screen_test.dart             (SỬA)
    └── dark_theme_smoke_test.dart            (SỬA)

KHÔNG đụng: lib/data/db/app_database.dart (schema giữ v8 — không migration,
            không build_runner), lib/screens/utilities_screen.dart,
            lib/theme/*, lib/core/widgets/*, lib/core/app_shell.dart,
            pubspec.yaml, docs/, wiki-knowledge/ (wiki cập nhật ở bước sau —
            skill sora-wiki)
```

## Rủi ro & ngoại lệ có lý do

### Ngoại lệ có lý do

| # | Ngoại lệ | Lý do |
|---|---|---|
| 1 | **Không dựng bảng `NotificationRule`/`NotificationLog`** như doc §3.1 | Cả hai phục vụ **engine** (lên lịch, chống bắn trùng qua `lastFiredAt`) và **Trung tâm thông báo** (màn `03`) — đều **ngoài phạm vi** (Q1=A). Dựng trước là bảng chết + migration v9 + `build_runner` cho dữ liệu không ai ghi/đọc. Khi engine ra đời, row `notificationPrefs` này là nguồn để migrate |
| 2 | **Không lưu "các ngày trong tuần" và "chu kỳ đóng góp + mốc %"** — mục "Thực thể chính" của spec có nhắc | Không có UI nào tạo ra giá trị đó trong phạm vi PBI (màn `02` và module Mục tiêu là PBI sau), nên lưu chỉ sinh dữ liệu chết + dòng phụ phải giả vờ đọc nó. Mockup cố định "mỗi ngày" và "Theo chu kỳ đã đặt cho từng mục tiêu" (research R3). Thêm trường về sau **không phá** dữ liệu cũ (parse tolerant — R4) |
| 3 | **Ghi lại cấu hình mỗi lần mở màn** (không chỉ khi có thay đổi) | Điều kiện để thoả FR-007/kịch bản 6 ("mặc định được ghi lại **ngay** lần mở đầu") mà không thêm phương thức seam hay side-effect ẩn trong `load()` (research R2). Hệ quả: 1 upsert 1 row mỗi lần mở — không đo được, không ảnh hưởng gì |
| 4 | **Viết lại `_ItemRow`/`_SectionLabel` ở màn mới** thay vì nâng widget dùng chung của PBI 17 | Hai màn khác nhau ở chỗ đáng kể (2 sắc icon theo nhóm, không có hàng "giá trị + chevron", số nhóm/hàng khác); gom chung phải sửa màn đã QA + thêm tham số — đổi rủi ro hồi quy lấy ít dòng tiết kiệm (research R7) |
| 5 | **Đường kẻ hàng không bám 100% mockup** (mockup vẽ 4 đường không nhất quán) | Bám khuôn code hiện có (kẻ giữa các hàng **trong** nhóm — PBI 17) để hai màn cài đặt trông cùng một hệ; ghi rõ ở `quickstart.md` §4 để QA không tính là lỗi |

### Rủi ro & ứng phó

| # | Rủi ro | Ứng phó |
|---|---|---|
| 1 | **Thiếu bản dịch EN** cho một khoá mới ⇒ `sora_translations_test` đỏ (test quét mọi literal trước `.tr` trong `lib/`) | Thêm khoá dịch **cùng lúc** với màn; chạy `flutter test test/sora_translations_test.dart` ngay sau khi viết màn |
| 2 | **Test đỏ có sẵn** `transactions_dao_test` (từ PBI 11) dễ bị nhầm là lỗi mới | Ghi rõ mốc baseline **960 pass / 1 fail** ở plan + quickstart §5; mục tiêu là **không tăng** số test đỏ |
| 3 | **JSON hỏng trong DB** (sửa tay, ghi dở) làm màn trắng/lỗi | Parse tolerant từng trường (luật 2–6) + test riêng cho JSON rác/`null`/mảng/sai kiểu/ngoài miền |
| 4 | **Ghi bất đồng bộ khi bật/tắt nhanh** ⇒ save cũ đè save mới | Ghi bám đuôi `_saveTail` như `UtilitiesScreen` (R5) + test "bật/tắt liên tiếp → store giữ trạng thái cuối" |
| 5 | **Cỡ chữ lớn / màn nhỏ** làm tiêu đề dài đè công tắc | Tiêu đề `maxLines: 1` + ellipsis, dòng phụ wrap trong `Expanded`, trailing ngoài `Expanded` (khuôn PBI 17); test surfaceSize 360×640 + `textScaleFactor 2.0` (tiền lệ `settings_screen_test`) |
| 6 | **Chế độ Tối** dùng màu `ColorScheme` mặc định cho `Switch` (không có `switchTheme` riêng) | Giống PBI 17/24 đã QA; QA nhóm I2/I3 kiểm tương phản; nếu thiếu tương phản ⇒ thêm `switchTheme` vào `app_theme.dart` (thay đổi nhỏ, phải QA lại 2 công tắc cũ) |
| 7 | **iOS chưa từng QA** ở các PBI trước | PBI này **không có plugin native mới** — rủi ro thấp; nếu có máy, chạy nhanh nhóm A/B/D |
| 8 | **Hai hàng chevron bị hiểu là lỗi** khi QA ("chạm không mở gì") | Đã ghi rõ ở `quickstart.md` §4 + spec chốt Q2=A; QA nhóm E kiểm đúng hành vi **im lặng**, không phải có màn |
