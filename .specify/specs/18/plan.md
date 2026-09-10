# Kế hoạch triển khai: Thay đổi giao diện Sáng / Tối / Theo hệ thống

**Mã PBI**: 18
**Liên kết spec**: .specify/specs/18/spec.md
**Ngày tạo**: 2026-09-06

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart / Flutter (Android + iOS) |
| Framework / Thư viện chính | Material 3, `get` (GetX — DI + reactive), drift (local DB) |
| Lưu trữ dữ liệu | SQLite qua drift; bảng `AppSettings` key-value (schema **v5** — giữ nguyên, chỉ thêm row `themeMode`) |
| Kiểm thử | `flutter_test` + drift in-memory; seam store fake; widget test màn; test suite hiện hữu **409** (không được vỡ) |
| Nền tảng triển khai | Android/iOS, offline hoàn toàn |
| Ràng buộc hiệu năng | SC-001 mở màn 02 ≤1s (màn tĩnh); đổi theme áp ngay, không restart |
| Ràng buộc khác | Design system + bảng màu tối theo `docs/tool/giai-phap-tien-ich-ca-nhan-hoa.md` §1; giữ nhận diện teal/coral; màn con shell: SubPageScaffold + back, không bottom nav; tiếng Việt có dấu; không thêm dependency |

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md`. Đối chiếu constraint trong `docs/` + `CLAUDE.md`:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline, không server, lưu local | ✅ | Chỉ drift local (R1) |
| Stack chốt: drift + GetX — **không thêm dependency** | ✅ | Tái dùng `ThemeMode` Flutter + drift `AppSettings`; không package mới |
| Migration drift an toàn | ✅ | Schema v5 giữ nguyên, thêm row — không migration (R1) |
| Màn con từ Tiện ích: SubPageScaffold + back, không bottom nav | ✅ | Màn 02 (R6) |
| Design system: teal 1 màu chính, thu=teal/chi=coral, số tiền `…đ` | ✅ | Dark giữ nhận diện; chỉ điều chỉnh độ sáng cần thiết (R4) |
| Màn chưa kích hoạt = no-op; điểm vào PBI sau kích hoạt | ✅ | Hàng "Giao diện" nay kích hoạt; 4 hàng no-op khác giữ nguyên |
| Ngôn ngữ/tài liệu tiếng Việt có dấu | ✅ | |

## Giai đoạn 0 — Nghiên cứu

Xem `research.md`. Quyết định chính:

- **R1**: Lưu row `('themeMode', 'light'|'dark'|'system')` trong `AppSettings` (v5) — không migration;
  key vắng = mặc định `system`.
- **R2**: `ThemeController` (GetxController, `Rx<ThemeMode>`) đăng ký ở gốc `SoraApp`;
  `GetMaterialApp` nhận `theme` + `darkTheme` + `themeMode` (Obx) → đổi theme **toàn app ngay**.
- **R4**: Bộ 2 theme qua `ThemeExtension<SoraColors>`: bản light **giữ nguyên giá trị token hiện
  có** (409 test cũ không vỡ); bản dark theo doc §1.2. Refactor token "màu thay đổi" (~26 file
  widget) sang lookup theo `BuildContext`, tách `white` nền sáng vs on-brand.
- **R5**: Refactor **mọi màn/chrome sau mở khóa** + màn PIN/boot (không để nền trắng chói ở tối).
- **R6**: Màn 02 dựng theo `02-giao-dien.svg`, radio tự dựng; chọn → `controller.setMode`.
- **R7**: Màn 01 hàng "Giao diện": trailing reactive + push `ThemeScreen`; 4 hàng nav khác no-op.
- **R9**: `ThemeMode.system` tự theo platform brightness (Material lo) — không tự viết observer.
- **R8**: Seam `ThemeStore`/`FakeThemeStore` + `ensureThemeStore()`/`ensureThemeController()`; `SoraApp`
  thêm seam `themeStore?`.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — không bảng/migration mới; thêm row `themeMode`; domain
  tái dùng `ThemeMode` Flutter; parse/label thuần.
- **Hợp đồng giao diện**: `contracts/` — **bỏ qua** (app nội bộ, offline, không API/CLI ngoài).
- **Kịch bản khởi động nhanh**: xem `quickstart.md`.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline, lưu local | ✅ | Chỉ drift |
| Không thêm dependency | ✅ | Không package mới |
| Migration drift an toàn | ✅ | Không migration — row mới trong bảng v5 (R1) |
| Test hiện hữu không vỡ | ✅ | Light token giữ giá trị cũ; extension có fallback `.light` khi theme không đăng ký (R4) |
| Màn con + back, không bottom nav | ✅ | SubPageScaffold màn 02 |
| Áp ngay toàn app, không restart | ✅ | themeMode ở gốc MaterialApp (R2) |
| Giữ nhận diện thương hiệu ở tối (FR-009) | ✅ | Giữ teal fill & trắng on-brand; glyph sáng hơn trên nền tối; ảnh/nội dung người nhập không đổi |
| Bố cục không vỡ (FR-010) | ✅ | ListView cuộn + hàng chống tràn (pattern màn 01) |

## Kiến trúc runtime (tóm tắt)

```text
runApp(SoraApp)
 └ SoraApp.initState: ThemeController(store) đăng ký + load()            (R8/R3)
 └ GetMaterialApp(theme: light, darkTheme: dark, themeMode: Obx(controller.mode))
     └ home: PinGate → (mở khóa) → AppShell … mọi màn đọc SoraColors.of(context)
     └ (push) UtilitiesScreen ──hàng "Giao diện" (Obx giá trị)──▶ push ThemeScreen
                                                        └ chọn → controller.setMode
                                                                 └ Rx đổi → MaterialApp rebuild toàn cây
                                                                 └ write-through row 'themeMode' (R1)
```

Đổi theme = `themeMode` đổi → `Theme` (inherited) mới → mọi widget gọi `Theme.of(context)`/token
tự rebuild theo màu mới — màn đang mở & màn khác đều đổi ngay (FR-005/SC-004). Ảnh, nội dung
người nhập, màu danh mục/ví không phụ thuộc theme → không đổi (FR-009).

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── theme/
│   │   ├── app_colors.dart                 # SỬA: chỉ giữ màu bất biến (teal fill, trắng on-brand,
│   │   │                                   #   coral fill, bảng danh mục/ví, avatar…) + hằng light
│   │   ├── sora_colors.dart                # MỚI: ThemeExtension<SoraColors> .light/.dark + getter
│   │   └── app_theme.dart                  # SỬA: + darkThemeData; đăng ký extension light/dark
│   ├── core/
│   │   ├── theme/                          # MỚI (domain giao diện — bám pattern core/utilities)
│   │   │   ├── theme_mode.dart             #   hằng kKeyThemeMode + parse ThemeMode↔chuỗi + nhãn UI
│   │   │   ├── theme_store.dart            #   abstract ThemeStore (load→ThemeMode?, save)
│   │   │   └── theme_controller.dart       #   ThemeController (Rx<ThemeMode>, load, setMode nối đuôi)
│   │   ├── app_shell.dart                  # SỬA: màu theo theme
│   │   └── widgets/                        # SỬA (chrome dùng chung): screen_header, sub_page_scaffold,
│   │       │                               #   app_bottom_nav_bar, category_row, amount_keypad
│   ├── data/
│   │   ├── theme_store_drift.dart          # MỚI: DriftThemeStore (1 row 'themeMode')
│   │   ├── theme_deps.dart                 # MỚI: ensureThemeStore() / ensureThemeController()
│   ├── screens/
│   │   ├── utilities_screen.dart           # SỬA: hàng "Giao diện" reactive + push ThemeScreen
│   │   ├── theme_screen.dart               # MÀN 02 "Giao diện" (3 card radio, mockup 02)
│   │   └── (các screen hiện hữu)           # SỬA: màu theo theme — dashboard, transaction(_detail,
│   │       │                               #   list, transfer), wallet(*), category_*(list/form/picker/
│   │       │                               #   child/sort), add_transaction, search_filter, settings,
│   │       │                               #   report; pin (setup/lock/keypad/dots); boot_gate
│   ├── main.dart                           # giữ nguyên
│   └── app.dart                            # SỬA: + darkTheme, themeMode (Obx), seam themeStore
├── test/
│   ├── fakes/fake_theme_store.dart         # MỚI
│   ├── theme_mode_test.dart                # MỚI: parse/label/mặc định
│   ├── theme_store_drift_test.dart         # MỚI: drift in-memory round-trip + key vắng = system
│   ├── theme_controller_test.dart          # MỚI: load/set→rx/ghi store
│   ├── theme_screen_test.dart              # MỚI: màn 02 — 3 card, radio, áp ngay, persist, cỡ chữ
│   ├── dark_theme_smoke_test.dart          # MỚI: smoke đại diện màn ở theme tối (không overflow/đọc được)
│   ├── utilities_screen_test.dart          # SỬA: Giao diện row mở màn, label "Theo hệ thống", đổi label
│   ├── pin_flow_test.dart / root test      # SỬA nếu có pump SoraApp: bơm FakeThemeStore
│   └── (screen test hiện hữu khác)         # thường không đổi (light giữ nguyên); bổ sung case dark nếu cần
```

## Ánh xạ token màu (light giữ nguyên giá trị hiện có; dark theo doc §1.2)

| Vai trò (semantic) | Light (= `AppColors` cũ) | Dark | Ghi chú tách/giữ |
|---|---|---|---|
| Nền màn/bottom nav/thân (trắng-nền) | `#FFFFFF` | `#121212` | **Tách khỏi** `white` on-brand |
| Card/surface sáng trên nền | `#FFFFFF` | `#1E1E1E` | tùy ngữ cảnh có phân lớp card |
| Card beige / panel / ô nhập (`softCardBg`) | `#F1EFE8` | `#242420` | |
| Chữ chính (`textPrimary`) | `#1A1A1A` | `#F2F2F0` | |
| Chữ phụ (`textSecondary`) | `#6B6B6B` | `#A8A8A3` | |
| Mờ tab/icon/section (`tabInactive`) | `#9B9B9B` | `~#A8A8A3` | |
| Label mờ (`listLabel`) | `#5F5E5A` | `~#B4B4AE` | |
| Kẻ ngang (`divider`) | `#E0E0E0` | `#3A3A36` | |
| Kẻ hàng/list (`listDivider`) | `#EFEFEF` | `~#2E2E2A` | |
| Chấm rỗng radio/dot (`dotEmpty`) | `#B4B2A9` | `~#6E6D66` | |
| Vòng nền icon xanh (`tealLightBg`) | `#E1F5EE` | `~#17332C` | |
| Vòng nền icon cam (`coralLightBg`) | `#FAECE7` | `~#3A2518` | |
| Text xanh nhạt trên teal (`tealLightText`) | `#CDE9DF` | giữ / sáng nhẹ | |
| Glyph/icon/chữ teal trên nền trung tính | `#0F6E56` | `#3FA98A` | glyph teal **sáng hơn** ở tối |
| Glyph/chữ chi (coral) trên nền trung tính | `#D85A30` | `#E8734C` | glyph coral sáng hơn ở tối |
| Trắng **on-brand** (icon/chữ trên teal, FAB) | `#FFFFFF` | `#FFFFFF` | **Giữ nguyên** — không thành nền |
| Fill teal thương hiệu (app bar, nút, chấm chọn) | `#0F6E56` | `#0F6E56` | giữ nguyên |
| Bảng màu danh mục / ví / avatar | (giữ) | (giữ) | nhận diện, không đổi |

`AppColors` giữ màu bất biến; token "đổi theo theme" chuyển thành field của `SoraColors`. Mọi giá
trị light giữ y → test widget so màu với hằng light cũ vẫn xanh.

## Rủi ro & ngoại lệ có lý do

- **Refactor màu rộng (~26 file widget)** — rủi ro cao nhất, có thể lệch màu/để sót. Giảm thiểu:
  light giữ nguyên giá trị (chạy full suite sau từng nhóm file); `SoraColors` getter có fallback
  `.light` khi theme không đăng ký extension (test cũ pump `AppTheme.themeData` không crash); mỗi
  nhóm màn có smoke dark (không overflow, đọc được, không "chìm"). **Ngoại lệ có lý do**: chấp nhận
  khối lượng thay đổi vì SC-007 bắt buộc toàn app đọc được ở tối — không cắt phạm vi.
- **`white` hai vai trò (nền sáng vs on-brand)** — phải phân loại theo từng chỗ dùng, không đổi
  tên máy móc. **Ngoại lệ có lý do**: đây là điểm dễ nhầm nhất; test light giữ nguyên + smoke dark
  bắt lỗi.
- **Flash giao diện lúc boot** (chưa load xong row theme): mặc định `system` trước khi load — với
  `home` là màn khóa nền trống, chấp nhận (R3). Không chặn frame đầu.
- **Có thể nháy đổi theme khi mở lần đầu đúng lúc load**: Rx đổi 1 lần ở init — vô hại, không vòng
  lặp (setMode so bằng tránh ghi thừa).
- **Chọn nhanh liên tiếp**: ghi row qua chuỗi `_saveTail` (pattern màn 01 PBI 17) — lần chạm cuối là
  trạng thái cuối (trường hợp biên spec).
- **Test hiện hữu khẳng định hàng "Giao diện" no-op + giá trị "Hệ thống"** (utilities_screen_test):
  **cố ý sửa** vì PBI này kích hoạt hàng và đổi nhãn mặc định thành "Theo hệ thống" (FR-001/FR-007,
  spec §Giả định). Đây là thay đổi hành vi đúng spec, không phải hồi quy.
- **Phần ghi chú / nhãn chưa có trong mockup nhỏ**: dòng ghi chú chân màn 02 lấy nguyên văn từ svg.
- **Màu sáng nhẹ của glyph teal/coral ở dark** dùng giá trị gợi ý doc (`#3FA98A`, `#E8734C`); khi thi
  công đối chiếu tương phản trên từng nền, có thể chỉnh nhẹ trong token (đặc tả để ngỏ mã cụ thể —
  SC-007).

## Bước tiếp theo

Chạy `/sora-task 18` để phân rã thành task thi công.
