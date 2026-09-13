# Kế hoạch triển khai: Trung tâm thông báo trong app (màn `03`)

**Mã PBI**: 30
**Liên kết spec**: [.specify/specs/30/spec.md](./spec.md)
**Ngày tạo**: 2026-09-13

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12 / Flutter (Android + iOS), app **offline hoàn toàn** (không đăng nhập, không server) |
| Framework / Thư viện chính | GetX `^4.7.3` (điều hướng + DI + i18n), Material. **Không thêm dependency** — chỉ dùng thứ repo đã có (`InkWell`, `Icon`, `ListView`, `SoraColors`, `AppColors`) |
| Lưu trữ dữ liệu | drift `^2.34.4` — **schema v8 → v9**: thêm **1 bảng** `Notifications` (7 cột, thuần tạo, **không seed**) + chạy `build_runner` sinh lại `app_database.g.dart`. Không sửa/xoá bảng nào đang có |
| Kiểm thử | `flutter_test` — mốc trước PBI: **1052 pass + 1 test đỏ CÓ SẴN** (`transactions_dao_test`, từ PBI 11). Thêm **3 file test mới + 1 fake mới**, **sửa 6 file** (4 file drift đổi `schemaVersion` 8→9, `widget_test`, `dark_theme_smoke_test`). Host này **có** sqlite native (đã chạy thử `notification_store_drift_test` — không bị skip) ⇒ test DAO/trần 200 chạy thật |
| Nền tảng triển khai | Build local (`flutter build apk` / iOS build) — không server, không CI đặc biệt, **không cấu hình native mới**, `pubspec.yaml` không đổi |
| Ràng buộc hiệu năng | FR-017/SC-012: mở màn + đổi tab **dưới 1 giây** kể cả ~200 mục. Thiết kế thoả sẵn: nạp **một lần** khi mở màn (1 truy vấn, ≤200 dòng), đổi tab chỉ **lọc trong bộ nhớ** (0 I/O); màn Tổng quan đọc 1 lần khi boot + 1 lần sau khi quay về |
| Ràng buộc khác | Ngôn ngữ giao diện/tài liệu/commit: **tiếng Việt có dấu**; bám Design System (teal `#0F6E56` = hành động/đang chọn/chưa đọc; coral `#D85A30` **chỉ** cho loại cảnh báo ngân sách — FR-006/FR-015); mọi màu đi qua token `AppColors`/`SoraColors`, **không** hex cứng trong widget; **mọi nhãn tĩnh phải có bản dịch EN** (PBI 19 — `sora_translations_test` quét `lib/` và đỏ nếu thiếu); **nội dung bản ghi lưu là snapshot** — hiển thị nguyên văn, không dịch lại (FR-014) |
| Nguồn chân lý nghiệp vụ | Mockup `docs/notification/03-trung-tam-thong-bao.svg` + `docs/notification/notification-solution.md` (§1 hai tầng, §2 bảng 5 loại + deep link, §3.1 `NotificationLog`, §5 điểm vào "biểu tượng chuông ở màn hình Tổng quan"); kế thừa PBI 28 (màn `01` + `NotificationStore` + khuôn icon/nhóm), PBI 29 (khuôn `.tr` literal + `dayLabel`), PBI 18 (`SoraColors` 2 theme), PBI 19 (khoá dịch = chuỗi tiếng Việt), PBI 26/27 (nút tròn 48 px ở `ScreenHeader.trailing`), PBI 20/21 (`popUntil(isFirst)` + `onSelectTab` để đổi tab shell) |

*Không còn mục `NEEDS CLARIFICATION`: spec đã "Đã làm rõ" (Q1=A, Q2=A, Q3=A chốt
2026-09-13, ghi ở mục "Quyết định đã chốt"); các quyết định còn lại là chi tiết
triển khai — xem [research.md](./research.md) (R1…R18).*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

`.specify/memory/constitution.md` **không tồn tại** (repo chưa tạo hiến pháp) ⇒
đối chiếu theo `CLAUDE.md` của repo và các quyết định đã chốt trong `docs/`.

| Nguyên tắc (nguồn: CLAUDE.md + docs) | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline hoàn toàn, không server/không auth | ✅ | Chỉ sqlite local; **0** lời gọi mạng; **0** plugin thông báo, **0** xin quyền, **0** lịch (FR-013) |
| Ngôn ngữ giao diện/tài liệu/commit: tiếng Việt có dấu | ✅ | Mọi nhãn/comment/tài liệu tiếng Việt; bản dịch EN thêm vào nhánh `_en`; giờ `HH:mm`/ngày `dd/MM` **không** dịch; nội dung bản ghi lưu **không** dịch lại (FR-014) |
| Stack đã chốt (drift + GetX + fl_chart) | ✅ | **0 dependency mới**; `pubspec.yaml` không sửa; **không** dùng `flutter_local_notifications`/`timezone` (engine là PBI sau) |
| Design system: 1 màu thương hiệu teal, coral chỉ cho chi/cảnh báo, không hex cứng trong widget | ✅ | Coral **chỉ** ở vòng icon loại cảnh báo ngân sách (FR-006); chấm chưa đọc dùng teal như mockup; chấm trên chuông dùng coral **có lý do** (R12 — ngoại lệ 1); **không** sửa `sora_colors.dart`/`app_theme.dart` |
| Màn cấp tab có bottom nav, **màn con không** | ✅ | `SubPageScaffold` (app bar teal + back + `actions` bánh răng); **không** bottom nav, **không** FAB (FR-002) |
| Số dư ví là đại lượng suy ra, không sửa tay | ✅ | Màn **không** chạm bảng `wallets` |
| Thu/chi/chuyển khoản: transfer không tính là thu/chi | ✅ | Màn **không** đọc/ghi `transactions` — PBI này **0** phép tính tiền |
| Không sửa dữ liệu người dùng ngoài phạm vi | ✅ | Chỉ đọc + ghi `read_at` của bảng `notifications` (bảng mới của chính PBI này); **0** ghi vào 6 bảng cũ (FR-012) |
| Không phá vỡ hành vi PBI trước | ✅ | Chỉ **thêm** bảng (không sửa cột/bảng cũ); `NotificationStore`/`FakeNotificationStore`/màn `01`/`02` **không sửa**; `DashboardScreen` đang là khung rỗng nên đổi thành `StatefulWidget` không phá gì; `AppShell` chỉ **thêm 1 tham số** cho màn Tổng quan (khuôn đang bơm cho `ReportScreen`) |
| YAGNI / không abstraction sớm | ✅ | 1 bảng + 2 file core + 2 file data + 1 màn mới + 5 widget **private** trong màn; **không** controller, **không** widget dùng chung mới, **không** token màu mới, **không** package mới, **không** seed dữ liệu mẫu |
| Quy trình PBI: spec → plan → task → implement | ✅ | Đang ở bước plan; `tasks.md` sinh ở bước sau |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại [research.md](./research.md). Tóm tắt các quyết định chính:

- **Nơi lưu lịch sử (R1)** — **Quyết định**: **bảng drift `Notifications`**
  (schema **v9**, migration thuần tạo, không seed) thay vì row JSON trong
  `AppSettings`. **Lý do**: lịch sử là log **có trần** (200) + trạng thái **ghi
  trên từng dòng**; dọn vượt trần = 1 câu SQL, đọc 1 mục không ghi đè mục khác;
  doc §3.1 đã định nghĩa `NotificationLog` là bảng và PBI 28 đã hoãn đúng bảng này
  "vì chưa có màn đọc". **Phương án khác**: 1 row JSON (mọi thao tác thành
  đọc–sửa–ghi cả khối, trần phải tự viết bằng Dart); seed dữ liệu mẫu (spec cấm);
  `shared_preferences` (package mới).
- **Cấu trúc bản ghi (R2)** — 7 cột phẳng (`kind` + `title` + `body` + `created_at`
  + `read_at?` + `related_id?`), **không** cột `payload` JSON: đích điều hướng do
  `kind` quyết định (FR-008) nên chỉ cần mang **một** id. `kind` lưu `.name`
  (quy ước repo), không FK (xoá đối tượng nghiệp vụ **không** làm mất lịch sử).
- **Trần 200 (R3)** — cưỡng chế ở **tầng ghi** (`append` chèn rồi xoá ngoài top-200
  theo `created_at DESC, id DESC`), không phải lúc đọc: mọi đường ghi đều đúng,
  kể cả engine tương lai.
- **Seam (R4)** — seam **mới** `NotificationHistoryStore` (3 phương thức:
  `loadRecent`/`append`/`markRead`); **không** nới `NotificationStore` của PBI 28
  (tránh chạm file/fake/test đã QA). Bỏ `unreadCount` — đếm bằng Dart ở chỗ gọi.
- **Chấm đỏ trên chuông (R5)** — state cục bộ ở `DashboardScreen` (`_unread`) +
  đếm lại **sau** `await Navigator.push(...)`; **không** GetX controller, **không**
  stream. Đúng và đủ vì trạng thái chỉ đổi được ở màn Trung tâm (mở từ chính nó).
- **Điểm vào (R6)** — chuông ở `ScreenHeader.trailing` màn Tổng quan (nút tròn
  48 px); `AppShell` bơm `onSelectTab` xuống màn Tổng quan (đích "tổng kết kỳ" là
  tab Báo cáo).
- **2 tab (R7)** — hàng tự vẽ + gạch chân 2 px teal + kẻ `listDivider`; **không**
  `TabBar`/`TabController` (đổi tab chỉ là 1 `setState` lọc trong bộ nhớ — FR-003).
- **Nhóm thời gian (R8)** — `today`/`thisWeek`/`earlier` = **7 ngày gần nhất**
  (cuốn theo ngày, không cắt theo tuần lịch) — theo **định nghĩa tường minh** ở
  spec §Giả định; lệch có chủ ý so với câu "tuần bắt đầu Thứ Hai" cùng mục (đã ghi
  quickstart §4.2).
- **Nhãn thời gian (R9)** — hôm nay `HH:mm`; 1…7 ngày **tên thứ đầy đủ**
  (`weekdayName` mới); cũ hơn `dd/MM`; mục trong ngày dùng **giờ tuyệt đối** (lệch
  mockup "2 giờ trước" — spec chốt cố ý).
- **Icon & màu (R10)** — map 5 loại, đúng bộ icon PBI 28 (chuông/cảnh báo/lịch/
  bullseye/pie); coral **chỉ** ở cảnh báo ngân sách (mockup: 2 sắc nền).
- **Chạm một mục (R11)** — đánh dấu đã đọc **trước**, rồi điều hướng theo `kind`;
  2 loại chưa có màn đích + `relatedId == null` ⇒ **im lặng** (không lỗi, không
  "sắp có"); tab Báo cáo = `popUntil(isFirst)` + `onSelectTab(2)`.
- **Chấm trên chuông (R12)** — `AppColors.coral` + viền trắng (`AppColors.white`):
  bảng màu dự án **không có token đỏ** và chấm nằm trên nền teal ⇒ viền trắng bắt
  buộc để đủ tương phản (ngoại lệ 1).
- **Một chiều (R13)** — `markRead` chỉ `UPDATE … WHERE read_at IS NULL` (bất biến
  cưỡng chế trong SQL); không nút đọc-tất-cả, không xoá (FR-019/Q2=A).
- **i18n (R14)** — ~12 khoá mới (literal trước `.tr`); tái dùng `'Tất cả'`,
  `'HÔM NAY'`, `'Thử lại'`, `'Thông báo & nhắc nhở'`; `title`/`body` của bản ghi
  **không** `.tr`.
- **Kiểm thử (R15)** — 3 file mới + 1 fake mới + 6 file sửa (4 file drift đổi
  `schemaVersion`, `widget_test`, smoke tối).
- **Xếp lớp (R16)** — `core/notification/` (2 file) · `data/` (2 file) ·
  `screens/notification_center_screen.dart`; `date_label.dart` **thêm** `weekdayName`.
- **Không GetX controller / không widget dùng chung (R17)**; **không làm** (R18):
  engine, plugin/quyền thông báo, màn `04`, đọc-tất-cả/xoá/tìm kiếm/chi tiết, seed,
  backup JSON, widget màn hình chính.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem [data-model.md](./data-model.md) — bảng drift
  `Notifications` (**schema v9**), `AppNotification` (7 trường), 2 enum
  (`NotificationKind`, `NotificationGroup`), seam `NotificationHistoryStore`
  (3 phương thức), **26 luật bất biến** + bảng vòng đời giá trị. **Không** sửa thực
  thể nào của PBI trước.
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app thuần nội bộ, không
  API/CLI/endpoint lộ ra ngoài (đồng nhất PBI 19–29). Hợp đồng nội bộ duy nhất mới
  là seam `NotificationHistoryStore` (mô tả ở data-model §5).
- **Kịch bản khởi động nhanh**: xem [quickstart.md](./quickstart.md) — **14 nhóm
  kiểm thử tay A–N**, phủ FR-001…FR-019 và SC-001…SC-014, kèm mốc test trước PBI
  (**1052 pass + 1 đỏ có sẵn**), cách chèn lịch sử mẫu để QA nhóm có dữ liệu (§1.2),
  và 6 lệch nhỏ đã biết.

### Kiến trúc chi tiết

**1. Tầng nghiệp vụ thuần — `lib/core/notification/app_notification.dart` (MỚI, ~130 dòng)**

| Thành phần | Vai trò |
|---|---|
| `const int kMaxNotifications = 200` | Trần lịch sử (FR-010, Q3=A) — hằng số, không cấu hình |
| `enum NotificationKind { dailyReminder, budgetAlert, recurringDue, goalReminder, periodSummary }` | 5 loại doc §2; lưu `.name` qua `textEnum` |
| `enum NotificationGroup { today, thisWeek, earlier }` + `String get label` | Nhãn `'HÔM NAY'`/`'TUẦN NÀY'`/`'TRƯỚC ĐÓ'` (literal trước `.tr`) |
| `class AppNotification` | 7 trường data-model §1; `const`; `bool get isRead`; `==`/`hashCode`; `copyWith({DateTime? readAt})` |
| `NotificationGroup notificationGroup(DateTime at, DateTime now)` | Luật 18 — so **ngày lịch** (`DateTime(y,m,d).difference(...).inDays`) |
| `String notificationTimeLabel(DateTime at, DateTime now)` | Luật 19 — `HH:mm` / `weekdayName(weekday)` / `dd/MM` (tái dùng `formatClock`, `_two` qua `date_label.dart`) |

Thuần Dart (không `Widget`, không `icon`, không màu) ⇒ test tầng thấp không cần
binding. Map icon/màu để ở **màn** (R10 — chỉ một màn dùng).

**2. Seam — `lib/core/notification/notification_history_store.dart` (MỚI, ~20 dòng)**

```dart
abstract class NotificationHistoryStore {
  Future<List<AppNotification>> loadRecent();        // mới nhất trước, ≤ 200
  Future<void> append(AppNotification notification); // chèn + dọn vượt trần (R3)
  Future<void> markRead(int id, DateTime readAt);    // chỉ dòng đang chưa đọc
}
```

**3. Impl drift — `lib/data/notification_history_store_drift.dart` (MỚI, ~75 dòng)**

```dart
loadRecent() → select(notifications)..orderBy([createdAt DESC, id DESC]) → map domain
append(n)    → insert 1 dòng → SELECT id top-200 → delete(id.isNotIn(keep))
markRead(id, t) → update ..where(id.equals(id) & readAt.isNull()) → write(readAt: t)
```

Bám khuôn `DriftNotificationStore` (mỏng, không tự quản connection). Cột `kind` là
`textEnum` ⇒ `NotificationKind.values.byName` khi map về domain.

**4. Đăng ký DI — `lib/data/notification_history_deps.dart` (MỚI, ~18 dòng)**

`ensureNotificationHistoryStore()` — GetX singleton, tạo **đúng 1**
`DriftNotificationHistoryStore(AppDatabase())`; test `Get.put` fake trước ⇒ trả
fake, không mở drift (bám `ensureNotificationStore`).

**5. Bảng drift — `lib/data/db/app_database.dart` (SỬA, ~20 dòng + sinh code)**

- thêm `@DataClassName('NotificationsRow') class Notifications extends Table` (7 cột
  data-model §4);
- `@DriftDatabase(tables: [..., Notifications])`;
- `schemaVersion => 9`;
- `onUpgrade`: `if (from < 9) await m.createTable(notifications);` (**không** seed,
  không đụng bảng cũ) — đặt **sau** nhánh `from < 8`;
- `dart run build_runner build --delete-conflicting-outputs` → `app_database.g.dart`.

**6. Màn mới — `lib/screens/notification_center_screen.dart` (MỚI, ~330 dòng)**

```
NotificationCenterScreen (StatefulWidget: store?, onSelectTab?, now?)
  initState → _load(): store.loadRecent() → setState(_items)      // 1 truy vấn
  state: _store · _items (List<AppNotification>) · _tab · _loading · _error
  _visible      → _tab == unread ? _items.where(!isRead) : _items   // FR-003 (0 I/O)
  _open(item)   → await store.markRead(id, _now) ; setState(đã đọc) ; _navigate(item)
  _navigate(i)  → switch (kind):  dailyReminder → push AddTransactionScreen()
                                  budgetAlert   → relatedId == null ? return
                                                  : push BudgetDetailScreen(onSelectTab:)
                                  periodSummary → popUntil(isFirst) ; onSelectTab?.call(2)
                                  recurringDue/goalReminder → return   // FR-008
  _openSettings() → push NotificationSettingsScreen(store: ...)     // màn 01 (PBI 28)
  SubPageScaffold(title: 'Thông báo'.tr, actions: [gear])           // FR-002
    └ Column
        ├ _TabBar(selected: _tab, onChanged: setState)              // R7
        └ Expanded( nhánh thân: _loading → spinner │ _error → câu + 'Thử lại'
                     │ rỗng → _EmptyState │ còn lại → ListView nhóm )
```

| Widget con (private) | Ghi chú |
|---|---|
| `_TabBar(colors, selected, onChanged)` | `Row` 2 `GestureDetector(opaque)`: nhãn 13 px (`AppColors.teal` w600 khi chọn, `colors.tabInactive` khi không) + `Container` cao 2 px `AppColors.teal` **dưới** nhãn đang chọn; `ValueKey('notification-tab-all'/'unread')`; dưới cùng `Container` cao 1 `colors.listDivider` |
| `_GroupLabel(colors, group)` | `group.label`, 11 px w600, `colors.tabInactive`, padding `(20, 20, 20, 8)` |
| `_NotificationTile(colors, item, onTap)` | `InkWell` → `Row(crossAxisAlignment: start)`: cột trái = **chấm 8 px** (`AppColors.teal`, chỉ khi `!isRead`; chỗ trống 8 px khi đã đọc để **không** xô lệch) + vòng tròn **36 px** (nền `tealLightBg`/`coralLightBg`, glyph 20 px `tealOnNeutral`/`coralOnNeutral`) → `Expanded(Column)`: `Row(Expanded(tiêu đề), SizedBox(8), nhãn thời gian)` rồi dòng mô tả **wrap tự nhiên** (không `maxLines` — số liệu không bị cắt, FR-016) + `Divider(colors.listDivider, height: 1)` thụt lề 20 px |
| Màu chữ | chưa đọc: tiêu đề `colors.textPrimary` **w600**, mô tả `colors.textSecondary`; đã đọc: tiêu đề `colors.listLabel` w400, mô tả `colors.tabInactive` (khác biệt **cả** chấm **lẫn** độ đậm/màu — FR-005) |
| `_EmptyState(colors, title, subtitle)` | Khuôn `transaction_screen._EmptyState`: icon `Icons.notifications_none` 44 px `colors.tabInactive` + câu chính 16 px w600 + câu phụ 13 px (2 câu **khác nhau**: rỗng chung vs tab "Chưa đọc") |
| `_iconFor(kind)` / `_tintFor(kind, colors)` | Bảng R10 (chỉ màn này dùng) |

**7. Màn Tổng quan — `lib/screens/dashboard_screen.dart` (SỬA, ~90 dòng)**

```dart
class DashboardScreen extends StatefulWidget {   // đang là khung rỗng → StatefulWidget
  const DashboardScreen({super.key, this.store, this.onSelectTab});
  final NotificationHistoryStore? store;         // seam test
  final ValueChanged<int>? onSelectTab;          // đích 'tổng kết kỳ' = tab Báo cáo
}
// _unread: int (0 khi đọc lỗi → không chấm, không crash)
// initState → _refresh()                          : (await store.loadRecent()).where(!isRead).length
// _openCenter() → await Navigator.push(...) ; _refresh()      // R5
ScreenHeader(title: 'Tổng quan'.tr, trailing: _BellButton(unread: _unread, onTap: _openCenter))
```

`_BellButton` = `Tooltip('Thông báo'.tr)` + `InkWell(customBorder: CircleBorder())` +
`SizedBox(48×48)` + `Stack`: `Icon(Icons.notifications_none, 24, AppColors.white)` +
`if (unread > 0)` `Positioned(top: 10, right: 10)` chấm 9 px `AppColors.coral` viền
2 px `AppColors.white` (R12). `ValueKey('dashboard-notification-bell')` cho test.

**8. Shell — `lib/core/app_shell.dart` (SỬA, 1 dòng)**

```dart
DashboardScreen(onSelectTab: _onTabSelected),   // const bỏ đi; khuôn đang bơm cho ReportScreen
```

**9. Dùng chung ngày — `lib/core/date_label.dart` (SỬA, ~14 dòng)**

```dart
/// Tên thứ đầy đủ theo ISO (1 = Thứ Hai): 'Thứ Hai'…'Chủ Nhật' (EN: Monday…Sunday);
/// ngoài miền → ''. Literal ngay trước `.tr` để test dịch còn ràng buộc (R9/R14).
String weekdayName(int weekday) => switch (weekday) { 1 => 'Thứ Hai'.tr, … 7 => 'Chủ Nhật'.tr, _ => '' };
```

**10. i18n — `lib/core/locale/sora_translations.dart` (SỬA, ~19 khoá mới)**

`'Thông báo'`, `'Chưa đọc'`, `'TUẦN NÀY'`, `'TRƯỚC ĐÓ'`, `'Chưa có thông báo nào'`,
`'Thông báo và nhắc nhở sẽ hiện ở đây.'`, `'Không có thông báo chưa đọc'`,
`'Không đọc được thông báo.'`, `'Mở cài đặt thông báo'` + 7 tên thứ.
**Tái dùng**: `'Tất cả'`, `'HÔM NAY'`, `'Thử lại'`, `'Thông báo & nhắc nhở'`.
Không cần bản đồ tiếng Việt (khoá = chính chuỗi tiếng Việt).

**11. Kiểm thử**

| File | Việc |
|---|---|
| `test/app_notification_test.dart` | **MỚI** — `notificationGroup`: cùng ngày / 23:59 hôm qua khi `now` 00:01 (vẫn `today`? **không** — 1 ngày ⇒ `thisWeek`) / 1 / 7 / 8 ngày / khác tháng-năm; `notificationTimeLabel`: `HH:mm` (`'20:30'`), tên thứ, `dd/MM`; `weekdayName` 7 giá trị + `0`/`8` → `''`; `isRead`; `kMaxNotifications == 200`; `==`/`hashCode`/`copyWith(readAt)` |
| `test/notification_history_store_drift_test.dart` | **MỚI** — drift in-memory (skip-guard như các test drift khác): `schemaVersion == 9`; bảng rỗng → `[]`; `append` 3 dòng → `loadRecent` **mới nhất trước** (kể cả 2 dòng cùng `createdAt` → theo `id` giảm); **trần 200**: `append` 205 dòng → `loadRecent().length == 200` và mục **cũ nhất** đã mất, mục mới nhất còn; `markRead`: đọc được, gọi lần 2 **không** đổi `readAt`, id không tồn tại → không lỗi/không tạo dòng; `append`+`markRead` **không** đụng `appSettings`/`wallets`/`transactions` |
| `test/notification_center_screen_test.dart` | **MỚI** — store giả: app bar + tiêu đề + bánh răng; 2 tab + gạch chân ở tab đang chọn; nhãn nhóm đúng thứ tự + **không** vẽ nhóm rỗng; chấm teal **chỉ** ở mục chưa đọc; 2 sắc icon (soi `Container.decoration`, coral chỉ `budgetAlert`); nhãn thời gian 3 dạng; chạm mục chưa đọc → `readAt` trong store + đúng **1** route đích; chạm mục đã đọc → vẫn điều hướng, `readAt` **không** đổi; `recurringDue`/`goalReminder`/`budgetAlert` thiếu `relatedId` → **0** route, 0 dialog/SnackBar, vẫn đánh dấu đã đọc; `periodSummary` → pop về màn gốc + `onSelectTab(2)`; tab "Chưa đọc" lọc đúng + giữ nhóm; 2 trạng thái rỗng (**2 câu khác nhau**); bánh răng → `NotificationSettingsScreen`; nhánh lỗi đọc + **Thử lại**; `now` bơm cố định; cỡ chữ 2.0 + 360×640 không overflow + cuộn tới mục cuối |
| `test/fakes/fake_notification_history_store.dart` | **MỚI** — bản bộ nhớ: `stored` (assert), `failLoad`, `failMarkRead`; bám `FakeNotificationStore` |
| `test/widget_test.dart` | **SỬA** — `pumpShell` đăng ký fake store (màn Tổng quan đọc lịch sử ngay khi boot); +test: chuông có mặt, **không** chấm khi rỗng, **có** chấm khi có mục chưa đọc, 1 chạm mở Trung tâm, back → chấm cập nhật |
| `test/notification_store_drift_test.dart` | **SỬA** — `expect(db.schemaVersion, 9)` (tên test đổi theo) |
| `test/scan_settings_store_drift_test.dart` | **SỬA** — `schemaVersion` 8 → 9 |
| `test/utilities_store_drift_test.dart` | **SỬA** — `schemaVersion` 8 → 9 |
| `test/scan_dao_test.dart` | **SỬA** — `schemaVersion` 8 → 9 |
| `test/dark_theme_smoke_test.dart` | **SỬA** — thêm màn Trung tâm (đăng ký fake store) vào smoke tối |

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline hoàn toàn | ✅ | Chỉ sqlite local; không mã nào import plugin thông báo; 0 quyền, 0 lịch (R13/R18) |
| Tiếng Việt có dấu | ✅ | ~19 khoá dịch thêm vào nhánh `_en`; không chuỗi tiếng Anh trần ngoài nhánh đó; tài liệu/comment tiếng Việt |
| Stack đã chốt | ✅ | **0 dependency mới**; `drift`/`build_runner` đã có sẵn trong `pubspec.yaml`; không cấu hình native |
| Design system & token màu | ✅ | Không hex cứng trong widget; coral chỉ ở cảnh báo ngân sách + chấm chuông (ngoại lệ 1 — R12); không sửa `sora_colors.dart`/`app_theme.dart` |
| Số dư ví suy ra / transfer không tính thu chi | ✅ | Không đọc/ghi `wallets`/`transactions` — PBI này 0 phép tính tiền |
| Màn con không bottom nav | ✅ | `SubPageScaffold`; màn Trung tâm không FAB, không bottom nav |
| Không phá vỡ PBI trước | ✅ | Bảng mới không sửa cột cũ; `NotificationStore`/`FakeNotificationStore`/màn `01`/`02`/`utilities_*`/`settings_screen` **không sửa**; `AppShell` +1 tham số; `DashboardScreen` vốn là khung rỗng; `date_label.dart` chỉ **thêm** hàm |
| YAGNI | ✅ | 1 bảng + 4 file mới + 6 widget private; không controller/widget dùng chung/token mới; bỏ `unreadCount` khỏi seam (đếm ở chỗ gọi) |
| Bảo mật & riêng tư | ✅ | Không log dữ liệu, không gửi đi đâu; lịch sử nằm trong DB local như dữ liệu khác; màn chỉ mở được **sau** khi đã mở khoá app (PIN — PBI 3) |
| Không ghi dữ liệu người dùng ngoài phạm vi | ✅ | Chỉ `insert`/`update read_at` trên bảng `notifications` của chính PBI này; 0 ghi vào 6 bảng cũ (luật 14) |

## Cấu trúc dự án dự kiến

```text
.specify/specs/30/
├── spec.md          (đã có)
├── checklists/      (đã có)
├── research.md      (MỚI — R1…R18)
├── data-model.md    (MỚI — bảng v9 + 26 luật + truy vết FR)
├── quickstart.md    (MỚI — QA tay A–N + cách chèn lịch sử mẫu)
├── plan.md          (MỚI — file này)
└── tasks.md         (bước sau: /sora-task 30)

app/sora_thu_chi/
├── lib/core/notification/
│   ├── app_notification.dart                  (MỚI: bản ghi + 2 enum + nhóm + nhãn + trần 200)
│   ├── notification_history_store.dart        (MỚI: seam 3 phương thức)
│   ├── notification_prefs.dart                (KHÔNG sửa — PBI 28/29)
│   └── notification_store.dart                (KHÔNG sửa — PBI 28)
├── lib/data/
│   ├── notification_history_store_drift.dart  (MỚI: DriftNotificationHistoryStore)
│   ├── notification_history_deps.dart         (MỚI: ensureNotificationHistoryStore)
│   ├── notification_store_drift.dart          (KHÔNG sửa)
│   ├── notification_deps.dart                 (KHÔNG sửa)
│   └── db/app_database.dart                   (SỬA: bảng Notifications + v9 + migration)
│       db/app_database.g.dart                 (TÁI SINH: build_runner)
├── lib/screens/
│   ├── notification_center_screen.dart        (MỚI: màn 03 Trung tâm thông báo)
│   ├── dashboard_screen.dart                  (SỬA: StatefulWidget + chuông + chấm đỏ)
│   └── notification_settings_screen.dart      (KHÔNG sửa — chỉ được push tới)
├── lib/core/app_shell.dart                    (SỬA: +onSelectTab cho DashboardScreen)
├── lib/core/date_label.dart                   (SỬA: +weekdayName)
├── lib/core/locale/sora_translations.dart     (SỬA: +~19 khoá en)
└── test/
    ├── app_notification_test.dart                     (MỚI)
    ├── notification_history_store_drift_test.dart     (MỚI)
    ├── notification_center_screen_test.dart           (MỚI)
    ├── fakes/fake_notification_history_store.dart     (MỚI)
    ├── widget_test.dart                               (SỬA)
    ├── dark_theme_smoke_test.dart                     (SỬA)
    ├── notification_store_drift_test.dart             (SỬA: schemaVersion 9)
    ├── scan_settings_store_drift_test.dart            (SỬA: schemaVersion 9)
    ├── utilities_store_drift_test.dart                (SỬA: schemaVersion 9)
    └── scan_dao_test.dart                             (SỬA: schemaVersion 9)

KHÔNG đụng: lib/core/notification/notification_prefs.dart, notification/store.dart,
            lib/data/notification_store_drift.dart, lib/data/notification_deps.dart,
            lib/data/utilities_*, lib/data/theme_*, lib/screens/utilities_screen.dart,
            lib/screens/settings_screen.dart, lib/theme/*, lib/core/widgets/*,
            pubspec.yaml, docs/, wiki-knowledge/
            (wiki cập nhật ở bước sau — skill sora-wiki)

TÁI DÙNG nguyên trạng: test/fakes/fake_notification_store.dart (PBI 28)
```

## Rủi ro & ngoại lệ có lý do

### Ngoại lệ có lý do

| # | Ngoại lệ | Lý do |
|---|---|---|
| 1 | **Chấm chưa đọc trên chuông dùng `AppColors.coral`** (đỏ-cam) + viền trắng, không phải đỏ tươi như spec viết | Bảng màu dự án (Design System) **không có token đỏ**; chấm nằm trên nền **teal** của vùng tiêu đề nên viền trắng là bắt buộc để đủ tương phản. Coral là sắc "cần chú ý" duy nhất có sẵn. Thêm token mới = mở rộng bảng màu ngoài Design System cho một chấm 9 px (research R12; quickstart §4.1) |
| 2 | **"TUẦN NÀY" = 7 ngày gần nhất**, không cắt theo tuần lịch (spec §Giả định có 2 câu mâu thuẫn nhau) | Câu định nghĩa nhóm trong spec nói rõ "TUẦN NÀY (7 ngày gần nhất, không tính hôm nay)"; cắt theo tuần lịch sẽ đẩy mục **hôm qua** vào "TRƯỚC ĐÓ" khi hôm nay là Thứ Hai (research R8; quickstart §4.2) |
| 3 | **Nhãn thời gian là giờ tuyệt đối**, mockup vẽ "2 giờ trước" | Spec §Giả định chốt **cố ý** (dễ đọc, dễ kiểm thử; mockup không nhất quán giữa các mục) |
| 4 | **Không dựng `NotificationRule`** của doc §3.1 | Thuộc **engine** (lên lịch, `lastFiredAt` chống trùng) — ngoài phạm vi Q1=A; dựng bây giờ là bảng chết chưa ai ghi/đọc (đồng nhất PBI 28 ngoại lệ 1) |
| 5 | **Màn không có nguồn ghi dữ liệu trong đợt này** ⇒ trên máy thật luôn rỗng | Q1=A đã chốt và đã chấp nhận hệ quả; PBI này bàn giao đúng điểm nối (`append`) cho engine. QA nhóm có dữ liệu dùng §1.2 của quickstart hoặc test tự động |
| 6 | **4 file test drift phải sửa `schemaVersion` 8 → 9** (chạm test của PBI trước) | Không thể tránh: nâng schema là thay đổi toàn cục của DB. Sửa **1 dòng/file**, chỉ đổi con số khẳng định — không đổi hành vi kiểm |
| 7 | **`DashboardScreen` đổi từ `StatelessWidget` (khung rỗng) sang `StatefulWidget`** | Màn này hiện chỉ là placeholder (`Column` + header + `SizedBox`), chưa có nội dung nghiệp vụ — đổi không phá hành vi nào; chấm đỏ cần state + 1 lần đọc lại sau khi quay về (R5) |

### Rủi ro & ứng phó

| # | Rủi ro | Ứng phó |
|---|---|---|
| 1 | **`build_runner` sinh code lệch** hoặc quên chạy ⇒ `AppDatabase` không có `notifications` | Chạy `dart run build_runner build --delete-conflicting-outputs` **ngay sau** khi sửa `app_database.dart`, trước khi viết store; `flutter analyze` phải sạch; `app_database.g.dart` được **commit** như 5 lần nâng schema trước |
| 2 | **Nâng schema làm đỏ test PBI trước** (4 file khẳng định v8) | Đã liệt kê đủ 4 file ở §Kiểm thử (grep `schemaVersion` toàn `test/`); sửa cùng lúc với `app_database.dart`; chạy `flutter test` ngay sau khi nâng |
| 3 | **Test đỏ có sẵn** `transactions_dao_test` dễ bị nhầm là lỗi mới | Ghi rõ mốc baseline **1052 pass / 1 fail** ở plan + quickstart §5; mục tiêu **không tăng** số test đỏ |
| 4 | **`widget_test` đỏ vì màn Tổng quan mở drift thật khi boot** (host test thiếu plugin đường dẫn) | `pumpShell` đăng ký `FakeNotificationHistoryStore` trước khi pump (khuôn đang đăng ký `FakeWalletRepository` cho tab Giao dịch); màn Tổng quan **nuốt lỗi đọc** → `_unread = 0`, không crash |
| 5 | **Chấm đỏ không mất sau khi đọc mục cuối** (đọc lại sai thời điểm) | Đọc lại **sau** `await Navigator.push(...)` (không phải trước); test `widget_test` khẳng định chuông mất chấm sau khi back |
| 6 | **Chạm mục giữa lúc `await markRead` rồi widget bị gỡ** ⇒ `setState` sau `dispose` | `if (!mounted) return;` sau **mọi** `await` trong `_open` (khuôn các màn PBI 24/27) |
| 7 | **Trần 200 không được cưỡng chế đúng** (xoá nhầm mục mới) | Luật 2–3 + test DAO thật (host này chạy được sqlite native, **không** bị skip): 205 dòng → 200, khẳng định **tập id còn lại** = 200 id mới nhất |
| 8 | **Thiếu bản dịch EN** cho khoá mới (kể cả 7 tên thứ) ⇒ `sora_translations_test` đỏ | Tên thứ viết **literal trước `.tr`** (switch), không gom vào `const List` (gom sẽ lọt lưới — tiền lệ PBI 29 R11); thêm khoá **cùng lúc** với màn; chạy `flutter test test/sora_translations_test.dart` ngay sau |
| 9 | **Cỡ chữ lớn / màn hẹp** làm tiêu đề dài đè nhãn thời gian hoặc chấm xô lệch bố cục | Tiêu đề trong `Expanded`, nhãn thời gian ngoài `Expanded` (khuôn PBI 17/28); chấm đã đọc vẫn chiếm **8 px** (không xô lệch hàng); test surfaceSize 360×640 + `textScaleFactor 2.0` |
| 10 | **Chế độ Tối**: nhãn nhóm/dòng mô tả mờ quá, gạch chân tab chìm | Mọi màu đi qua `SoraColors` (`tabInactive`/`listDivider`/`textSecondary` đã có bản tối); gạch chân + chấm dùng teal **bất biến** trên nền **sáng** (màn con nền `background`) — không nằm trên app bar teal; QA nhóm M |
| 11 | **QA tay nhầm "màn rỗng" là lỗi** (không có engine ghi lịch sử) | Ghi đậm ở quickstart §1 + §4.4; QA nhóm B kiểm **đúng** trạng thái rỗng, nhóm E–J dùng §1.2 |
| 12 | **iOS chưa từng QA** ở các PBI trước | PBI này **0 plugin native mới**, chỉ thêm bảng sqlite — rủi ro thấp; nếu có máy, chạy nhóm A/B/C/M |
