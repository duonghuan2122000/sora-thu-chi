# Nghiên cứu — PBI 18 (Thay đổi giao diện Sáng / Tối / Theo hệ thống)

Ngày: 2026-09-06

## R1 — Lưu lựa chọn giao diện ở đâu?

- **Quyết định**: Lưu **trong drift** — thêm **row** `('themeMode', 'light'|'dark'|'system')` vào bảng
  key-value `AppSettings` đã có (schema **v5**, PBI 17). **Không** tạo bảng mới, **không**
  migration (mục tiêu thiết kế của PBI 17: "PBI sau chỉ thêm row, không thêm migration").
  Key **vắng mặt** = chưa từng đổi → mặc định `system`. Row ghi **write-through** khi người dùng
  chọn.
- **Lý do**: (a) nguồn lưu local duy nhất của app là drift — không thêm dependency mới; (b) trả
  đúng khoản đầu tư bảng key-value của PBI 17; (c) nhất quán pattern `UtilitiesStore`
  (DriftUtilitiesStore ghi vào đúng bảng này).
- **Phương án khác**:
  - `shared_preferences` / `GetStorage` / `Hive` (doc gợi ý "GetStorage/Hive"): reject — thêm
    package/nguồn lưu trữ mới trong khi `AppSettings` đã dùng được; lệch "mọi cài đặt chung một
    nguồn".
  - Bảng cột riêng cho theme: reject — thừa, key-value đã đủ.

## R2 — Trạng thái theme chạy toàn app (áp ngay, không restart) bằng cơ chế nào?

- **Quyết định**: Dùng `ThemeController` (GetxController) với `Rx<ThemeMode>`, đăng ký **Get
  singleton ở gốc `SoraApp`** (giống `PinController`). `GetMaterialApp` nhận
  `theme: AppTheme.themeData` + `darkTheme: AppTheme.darkThemeData` + `themeMode:` là `Obx` của
  controller → khi `setMode` đổi Rx, **toàn bộ cây MaterialApp rebuild theo theme mới ngay** (màn
  đang mở + màn khác), không cần khởi động lại (FR-005/SC-004). Controller cũng là nguồn cho
  radio màn 02 và giá trị hàng "Giao diện" màn 01.
- **Lý do**: rõ ràng, kiểm thử được, không dựa vào phần "đằng sau" không được chốt của `get`
  (`Get.changeThemeMode()` đổi state qua `ThemeService` nội bộ). Cùng hiệu quả "đổi ngay", nhưng
  ta chủ động: mọi màn phụ thuộc `Theme.of(context)` sẽ tự rebuild vì `Theme` là inherited widget
  thay đổi theo `themeMode`.
- **Phương án khác**: `Get.changeThemeMode()` + bộ `ThemeService` đúng nghĩa của `get` — reject
  (phụ thuộc cơ chế ngầm, khó bơm seam trong widget test). StatefulWidget root tự giữ mode — reject
  (không reactive cho màn 01/màn 02).

## R3 — Thời điểm nạp theme lúc khởi động (flash giao diện sai)?

- **Quyết định**: `ThemeController` mặc định `ThemeMode.system`; `SoraApp.initState` gọi
  `controller.load()` (đọc drift bất đồng bộ), xong thì Rx đổi về giá trị đã lưu. Vì `home` là
  `PinGate` nền trống, và người dùng phải mở khóa PIN trước khi thấy nội dung → mọi nội dung có
  thể đọc sai theme chỉ hiện sau khi đã nạp xong. Chấp nhận 1 khung nền gate có thể nháy sáng/tối
  khi lần đầu build trước khi `load()` trả về (cửa sổ rất ngắn, nền trống không nội dung).
- **Lý do**: thời điểm nạp trùng sẵn luồng bất đồng bộ PIN; không cần chặn frame đầu.
- **Phương án khác**: `main` async preload rồi mới `runApp` — reject (đẩy chậm khởi động, chưa
  cần); chặn build tới khi load xong — reject (phức tạp, lợi ích không đáng).

## R4 — Bảng màu tối & cách làm mọi màn hiện có hiển thị đúng?

- **Quyết định**: (1) Định nghĩa **bộ 2 theme qua `ThemeExtension<SoraColors>`**: bản `light` giữ
  **nguyên giá trị token hiện có** (ảnh "trước/sau" = không đổi), bản `dark` theo doc
  `docs/tool/giai-phap-tien-ich-ca-nhan-hoa.md` §1.2: nền `#121212`/card `#242420`, chữ chính
  `#F2F2F0`, chữ phụ `#A8A8A3`, phân cách `#3A3A36`; giữ teal thương hiệu cho **fill**, glyph
  teal sáng hơn `#3FA98A` và coral sáng hơn `#E8734C` khi nằm trên nền tối; nền vòng icon nhạt →
  tone tối tương ứng. `AppTheme.themeData`/`darkThemeData` đăng ký extension tương ứng.
  (2) **Refactor màu theo ngữ cảnh**: các token "màu thay đổi theo theme" hiện đang là `static
  const` trong `AppColors` (trắng-nền, chữ chính/phụ, divider, tint bg, tabInactive, listLabel,
  dotEmpty, icon-on-brand…) được chuyển thành lookup theo `BuildContext` (`SoraColors.of(context)`),
  có fallback `.light` khi theme không đăng ký extension → **test cũ pump `AppTheme.themeData`
  (light) không đổi kết quả**.
- **Lý do**: token tập trung hết ở `AppColors` nhưng là const → không thể "tự" đổi theo theme;
  cách duy nhất đúng là phân giải qua context. Giữ bản light bằng giá trị cũ giúp **409 test hiện
  hữu không vỡ**. `white` có 2 vai trò (nền sáng vs chữ/icon on-brand teal) → phải **tách token**
  (`onBrand` giữ trắng, nền → dark), không đổi tên máy móc.
- **Phương án khác**:
  - Biến `AppColors` thành getter đọc một biến toàn cục "brightness hiện tại": reject — phản
    pattern, không an toàn khi có 2 brightness cùng lúc trong cây transition, khó test.
  - Chỉ theme hoá theme/màn 02, bỏ mặc màn khác "vẫn đọc được": reject — vi phạm
    FR-005/SC-007 (app phải đổi đồng bộ, không vùng "chìm").

## R5 — Phạm vi refactor màu (file nào)?

- **Quyết định**: Refactor **mọi màn/chrome đọc được sau mở khóa**: chrome chung (`ScreenHeader`,
  `SubPageScaffold`, `AppBottomNavBar`, `AppShell`, `CategoryRow`, `AmountKeypad`, `ScreenHeader`),
  toàn bộ màn `screens/*` hiện dùng token biến đổi, và các màn PIN/boot (để không còn nền trắng
  chói ở màn khóa). Liệt kê đầy đủ trong plan §Cấu trúc. Ảnh hóa đơn/receipt, nội dung người nhập,
  bảng màu danh mục/ví (màu nhận diện) **không** đổi (FR-009).
- **Lý do**: dark mode là toàn cục; để sót màn nào = màn đó "chìm"/chói.
- **Phương án khác**: thu hẹp phạm vi — reject như R4.

## R6 — Màn 02 "Giao diện" (theme_screen) dựng thế nào?

- **Quyết định**: `ThemeScreen` là màn con shell → dùng `SubPageScaffold(title: 'Giao diện')`
  (app bar teal + back, không bottom nav — FR-001). Thân là `ListView` cuộn (chống vỡ cỡ chữ
  lớn/màn nhỏ — FR-010), gồm **3 card** đúng mockup `02-giao-dien.svg`: card bo 10, hàng chọn
  được **tô nền nhạt** + **vòng icon có viền teal**; mỗi hàng: vòng nền nhạt + icon minh họa
  (Sáng = mặt trời, Tối = mặt trăng, Theo hệ thống = thiết bị), tên (đậm) + dòng phụ mô tả, và
  **radio tròn** cuối hàng — chọn = chấm teal có dấu tích trắng, không chọn = vòng viền xám nhạt.
  Radio dùng widget tự dựng (mockup không phải `Radio` Material mặc định). Chân màn: dòng ghi chú
  xám "Thay đổi được áp dụng ngay lập tức, không cần khởi động lại ứng dụng."
- **Chọn radio → `ThemeController.setMode(mode)`** → Rx đổi → toàn app đổi ngay, card được chọn
  tự chuyển tô đúng theme mới (FR-005). Radio đọc `controller.mode` (Obx) nên lần đầu chưa đổi =
  `system` được chọn sẵn (FR-004), và khi tắt app mở lại đọc đúng giá trị đã lưu (FR-006).
- **Lý do**: đối chiếu svg 1-1; tự dựng radio cho khớp mockup và dễ chủ động màu theo theme.
- **Phương án khác**: dùng `RadioListTile` Material — reject (lệch mockup: bố cục icon vòng bên
  trái + dòng phụ dài, radio riêng cuối hàng).

## R7 — Kích hoạt hàng "Giao diện" màn 01 + giá trị hiển thị

- **Quyết định**: Hàng "Giao diện" màn 01: (a) `trailing` đổi từ giá trị **tĩnh "Hệ thống"** (PBI
  17, no-op) sang **reactive** — đọc `ThemeController` (Obx): hiện "Sáng"/"Tối"/"Theo hệ thống"
  theo lựa chọn hiện hành, cập nhật ngay sau khi đổi (FR-007) kể cả khi người dùng đang ở màn 02
  rồi quay lại (màn 01 vẫn mounted dưới route); (b) `onTap` hàng → **push `ThemeScreen`** (FR-001,
  kích hoạt điểm vào no-op PBI 17). Các hàng điều hướng khác (Ngôn ngữ…) giữ no-op.
- **Lý do**: màn 01 phải phản ánh đúng trạng thái mà không cần logic "kết quả trả về" từ màn 02 —
  controller reactive là nguồn chung.
- **Phương án khác**: màn 01 giữ state cục bộ, đợi `Navigator.push(...).then` trả về để setState —
  reject (màn 02 còn đổi theme cho cả app; màn 01 chỉ là 1 viewer — dùng chung controller sạch hơn).

## R8 — Seam kiểm thử & điểm đăng ký

- **Quyết định**: Theo pattern hiện có:
  - `ThemeStore` (abstract `load` → `ThemeMode?`, `save(ThemeMode)`) — bản drift ghi đúng 1 row
    `themeMode` (`DriftThemeStore`); test dùng `FakeThemeStore`.
  - `ensureThemeStore()` / `ensureThemeController()` (Get singleton, fake-first như
    `ensureUtilitiesStore`/`ensureWalletController`).
  - `SoraApp` thêm seam `themeStore?` (mặc định → `ensureThemeStore()`); `ThemeController` được tạo
    ở `initState` SoraApp với store đó (đối xứng `PinStore`). Test `pin_flow`/root bơm
    `FakeThemeStore`.
- **Lý do**: giữ màn/widget test được không khởi tạo sqlite native — pattern PBI 7/13/17.

## R9 — "Theo hệ thống" tự đổi khi điện thoại đổi sáng/tối

- **Quyết định**: Dựa **sẵn của Material**: `themeMode: ThemeMode.system` → `MaterialApp` tự lắng
  nghe `platformBrightness` và rebuild. **Không** cần `WidgetsBindingObserver`
  (didChangePlatformBrightness như doc §1.2) — Material đã lo. Widget test kiểm tra bằng
  `tester.binding.platformDispatcher.platformBrightnessTestValue`.
- **Lý do**: không viết lại cơ chế Flutter có sẵn.
- **Phương án khác**: tự lắng nghe brightness + set Rx — reject (thừa).

## R10 — Tên hiển thị & nhận diện

- **Quyết định**: Bản đồ nhãn `ThemeMode → chữ`: `system`→"Theo hệ thống", `light`→"Sáng",
  `dark`→"Tối". Màn 01 thay chữ cũ "Hệ thống" bằng "Theo hệ thống" (thống nhất tên — spec Giả
  định). Dòng phụ màn 01 giữ "Sáng / Tối / Theo hệ thống" (PBI 17).
- **Lý do**: spec §Giả định: "Hệ thống" (cũ) và "Theo hệ thống" là cùng một lựa chọn; từ PBI này
  hiển thị đúng tên đầy đủ.
