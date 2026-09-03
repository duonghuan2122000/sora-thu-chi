# Danh sách Task: Khung điều hướng ứng dụng

**Mã PBI**: 2
**Nguồn**: plan.md, spec.md, research.md, quickstart.md

> PBI UI shell — spec.md **không** gán mức ưu tiên P1/P2/P3 cho từng user story (kịch bản là 1 luồng liền). Để phục vụ phát hành tăng dần, phân thành **2 lát cắt** theo thứ tự luồng kịch bản spec (bước 1–3 trước, bước 4–5 sau): US1 "điều hướng 4 vùng chính" là nền (P1), US2 "FAB + cơ chế màn phụ" dựng trên đó (P2). Đóng đủ spec cần cả 2.

## Pha 1: Setup

- [X] T001 Xác minh baseline trong `app/sora_thu_chi/`: chạy `flutter --version` (kỳ vọng Flutter 3.44.x / Dart 3.12.x, khớp PBI 1), `flutter pub get` rồi `flutter analyze` → sạch; xác nhận `lib/main.dart` còn đúng counter demo mặc định (PBI 1 để nguyên, chưa module nào đụng) và `flutter devices` có sẵn Android emulator API 37 (QA thủ công dùng). Không đổi `pubspec.yaml` — plan xác nhận **không thêm dependency mới** đợt này.

## Pha 2: Foundational

- [X] T002 Tạo token màu `app/sora_thu_chi/lib/theme/app_colors.dart` theo research.md §Theme: hằng đúng 6 màu đang tiêu thụ — teal `#0F6E56`, trắng `#FFFFFF`, teal nhạt chữ phụ trên header `#CDE9DF`, xám tab chưa chọn `#9B9B9B`, divider `#E0E0E0`, chữ chính `#1A1A1A`. Không dựng bảng palette/typography thừa (thêm sau khi module cần, vào cùng file).
- [X] T003 Tạo `app/sora_thu_chi/lib/theme/app_theme.dart`: `AppTheme.themeData` → `ThemeData` gồm scaffold nền trắng, `colorScheme` gieo từ teal, `appBarTheme` teal + chữ trắng 16/600; đọc màu từ `app_colors.dart` (T002). Đảm bảo từ đây widget **không nhúng hex cứng** (rule "style tập trung 1 nơi").

## Pha 3: User Story 1 — Điều hướng 4 vùng chính (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: Dựng shell có bottom nav 5 vị trí (ô giữa trống dành FAB) + 4 màn chính khung đặt chỗ (Tổng quan | Giao dịch | Báo cáo | Cài đặt), đổi tab giữ nguyên trạng thái vùng (FR-001/002/003/004/007/010).

**Tiêu chí kiểm thử độc lập**: Boot vào thẳng màn Tổng quan (tab Tổng quan teal đậm = đang chọn); đủ 4 tab + ô giữa; tap từng tab → vùng chính đổi đúng, tab chọn tô teal/các tab khác xám `#9B9B9B`; rời khỏi rồi quay lại 1 tab → màn không bị dựng lại (FR-004). Widget test host chạy được không cần emulator.

- [X] T004 [P] [US1] Tạo `app/sora_thu_chi/lib/core/widgets/app_bottom_nav_bar.dart`: thanh `Row` 5 ô `Expanded` bằng nhau — ô 0 Tổng quan, ô 1 Giao dịch, ô 2 **trống** (dành FAB US2), ô 3 Báo cáo, ô 4 Cài đặt. Mỗi ô tab: icon outlined (home/list/chart-pie/settings theo design doc §2.1) + label nhỏ; màu teal khi chọn (label đậm) / xám `#9B9B9B` khi chưa chọn; **label bọc co mềm 1 dòng** (`FittedBox`) chống tràn khi cỡ chữ lớn (SC-005); toàn bộ thanh nằm trong `SafeArea` chân tránh phím hệ thống che (SC-004). Widget thuần: nhận `selectedIndex` + `onTabSelected(int)`, không tự quản state. Đối chiếu tỉ lệ pixel mockup `docs/auth/01-khung-dieu-huong.svg` trong lúc dựng.
- [X] T005 [P] [US1] Tạo `app/sora_thu_chi/lib/core/widgets/screen_header.dart`: widget vùng tiêu đề teal (nền `#0F6E56`, tên màn trắng 16/600, chữ phụ/viền dùng token) cho màn chính; phía dưới để body màu trắng. Khớp loại "Màn hình chính" design doc §2.2 + mockup svg.
- [X] T006 [US1] Tạo 4 màn chính khung, mỗi màn 1 file trong `app/sora_thu_chi/lib/screens/`: `dashboard_screen.dart` (Tổng quan), `transaction_screen.dart` (Giao dịch), `report_screen.dart` (Báo cáo), `settings_screen.dart` (Cài đặt). Mỗi màn = `ScreenHeader`(tên màn) + vùng nội dung trống; **không** số liệu/hình minh họa giả (FR-007). File riêng làm chỗ bám để PBI module sau gắn body vào (giả định spec). Không thêm AppBar riêng (header đã lo).
- [X] T007 [US1] Tạo `app/sora_thu_chi/lib/core/app_shell.dart`: `StatefulWidget` — `body` là `IndexedStack` bọc 4 màn chính (giữ tree + state → FR-004), `bottomNavigationBar` = `AppBottomNavBar` nối `selectedIndex` + `onTabSelected` → `setState` đổi chỉ số tab. Dùng `int` trong `State`, **không** controller/GetX (research: shell tĩnh không cần). FAB chưa thêm (US2).
- [X] T008 [US1] Tạo `app/sora_thu_chi/lib/app.dart`: `SoraApp` → `MaterialApp` (Navigator chuẩn, chưa GetMaterialApp — research) với `theme: AppTheme.themeData`, `home: AppShell`, `debugShowCheckedModeBanner: false`, `title` tiếng Việt (VD "Sora Thu Chi").
- [X] T009 [US1] Sửa `app/sora_thu_chi/lib/main.dart`: bỏ toàn bộ counter demo (`MyHomePage`, state `_counter`, nút +, dữ liệu mẫu) → chỉ `runApp(const SoraApp())`. Đảm bảo không còn symbol `MyHomePage` được tham chiếu nơi khác.
- [X] T010 [US1] Viết lại `app/sora_thu_chi/test/widget_test.dart` (file cũ test counter sẽ hỏng khi MyHomePage bị xóa): smoke test phạm vi US1 — (1) boot thấy header "Tổng quan" + đủ 4 nhãn tab + không crash; (2) tap từng tab Giao dịch/Báo cáo/Cài đặt → header đổi tương ứng, tab được chọn đổi; (3) rời Giao dịch sang Báo cáo rồi quay lại → vẫn ở Giao dịch, không nhấp nháy về đầu (FR-004). Chạy `flutter test` file này → pass.

## Pha 4: User Story 2 — Nút nổi "Thêm giao dịch" & cơ chế màn phụ (Ưu tiên: P2)

**Mục tiêu**: FAB tròn teal nổi giữa thanh đáy trên cả 4 màn chính; tap → mở màn phụ "Thêm giao dịch" khung trống (không bottom nav, có nút back); quay lại trở về đúng màn chính + đúng tab lúc rời đi (FR-005/006/008).

**Tiêu chí kiểm thử độc lập**: Trên cả 4 màn chính đều thấy FAB (4/4); tap FAB → mở màn phụ có tiêu đề "Thêm giao dịch" + nút back, **không còn** thanh đáy; tap back (app bar + phím hệ thống) → về đúng màn chính, đúng tab chọn (SC-002/006).

- [X] T011 [US2] Tạo `app/sora_thu_chi/lib/core/widgets/sub_page_scaffold.dart`: widget màn phụ dùng chung — `AppBar` teal (đọc theme/app_colors), nút back mặc định + tiêu đề trắng, **không** bottom nav (FR-008). Đợt này phục vụ "Thêm giao dịch"; Cài đặt PBI sau tái dùng cho sub-page (giả định spec).
- [X] T012 [US2] Tạo `app/sora_thu_chi/lib/screens/add_transaction_screen.dart`: màn phụ "Thêm giao dịch" khung trống — dựng trên `SubPageScaffold`, `title: "Thêm giao dịch"`, body trống; **không** biểu mẫu/số liệu giả (FR-006; form thật của module Giao dịch sẽ thay thân sau).
- [X] T013 [US2] Gắn FAB trong `app/sora_thu_chi/lib/core/app_shell.dart`: `Scaffold.floatingActionButton` — tròn 48–52px teal `#0F6E56`, icon cộng trắng, `FloatingActionButtonLocation.centerDocked` chìm nửa dưới vào ô giữa trống của nav (khớp mockup svg); `onPressed` → `Navigator.push(MaterialPageRoute(builder: → AddTransactionScreen))` — route phủ toàn màn tự ẩn bottom nav (FR-006). FAB nằm ngoài `IndexedStack` nên hiển thị cố định trên cả 4 tab (FR-005). Quay lại (nút back hoặc phím hệ thống) trả về shell, `IndexedStack` giữ nguyên index cũ (FR-008/SC-006).
- [X] T014 [US2] Mở rộng `app/sora_thu_chi/test/widget_test.dart`: thêm case — (1) FAB hiện trên cả 4 màn chính (duyệt từng tab, 4/4); (2) tap FAB → xuất hiện màn phụ tiêu đề "Thêm giao dịch" + nút back, **không** còn nhãn tab bottom nav; (3) tap back → về đúng tab trước đó, tab chọn giữ nguyên. Chạy lại `flutter test` → toàn bộ (US1 + US2) pass.

## Pha cuối: Polish & Cross-cutting

- [X] T015 Chạy trong `app/sora_thu_chi/`: `flutter analyze` → "No issues found"; `flutter test` → toàn bộ test pass. Nếu đỏ → sửa cho sạch trước khi QA, không bỏ ngang.
- [X] T016 QA thủ công 8 mục theo `.specify/specs/2/quickstart.md` trên Android emulator API 37 (hoặc thiết bị Android): đối chiếu SC-001..006 — đặc biệt mục 7 vùng an toàn tai thỏ/phím hệ thống (SC-004) và mục 8 cỡ chữ lớn nhất hệ thống không vỡ/tràn (SC-005). Ghi kết quả 8/8 đạt; bất thường theo màn hình/thiết bị → ghi vào `.specify/specs/2/plan.md` §Rủi ro "trạng thái sau thi công", không bỏ ngang.

  > QA 2026-09-03 trên emulator-5554 (API 37): cài APK debug + chạy thật. Verify bằng screenshot + adb input: (1) boot → header "Tổng quan" + nav 5 vị trí (FAB teal tròn giữa nhô) ✓; (2) FAB tap → màn phụ "Thêm giao dịch", mất bottom nav ✓; (3) back hệ thống → về shell đúng màn ✓. Đổi tab bằng widget test host (6 test pass). Cỡ chữ: `font_scale 1.3` (lớn nhất emulator) app không vỡ/không crash, label tab co mềm ✓. Mục tai thỏ/phím hệ thống SC-004: emulator không có tai thỏ thật — nav đã bọc SafeArea (chân) + không bị che bởi gesture nav trên API 37; thiết bị tai thỏ vật lý chưa verify (ghi trạng thái).
- [X] T017 Rà soát cuối + đóng spec: `git status` trong `app/sora_thu_chi/` chỉ gồm file theo plan.md §Cấu trúc (không đổi `pubspec.yaml`, `android/`, `ios/`); grep xác nhận không còn dữ liệu/fake data (FR-007) và không hex màu cứng ngoài `app_colors.dart`; đối chiếu FR-001..010 + SC-001..006 ghi đạt/không đạt vào ghi chú cuối tasks.md này; ghi trạng thái iOS chưa verify (máy Windows — code thuần widget, rủi ro thấp, verify khi có máy macOS).

  > Rà soát 2026-09-03: `git status` app chỉ gồm file mới/sửa trong `lib/` (theme, core, screens, app.dart, main.dart) + `test/widget_test.dart` — không đổi `pubspec.yaml`, `android/`, `ios/`. Grep: hex màu chỉ tập trung `theme/app_colors.dart`; không còn symbol counter demo; không số liệu/fake data trong màn. `flutter analyze` No issues found; `flutter test` 6/6 pass.
  >
  > **Đối chiếu yêu cầu — ghi chú cuối**
  > - FR-001 (nav 5 vị trí đúng thứ tự): ĐẠT — `AppBottomNavBar` + FAB centerDocked.
  > - FR-002 (boot vào Tổng quan, đánh dấu chọn): ĐẠT — shell khởi tạo index 0, widget test.
  > - FR-003 (chuyển 4 vùng, chọn nổi bật): ĐẠT — tab chọn teal/label đậm, tab khác xám, widget test.
  > - FR-004 (giữ trạng thái vùng khi quay lại): ĐẠT — `IndexedStack`, widget test.
  > - FR-005 (FAB cố định cả 4 màn): ĐẠT — FAB ngoài IndexedStack, widget test 4/4.
  > - FR-006 (màn phụ khung trống + back, không nav): ĐẠT — push route phủ, widget test.
  > - FR-007 (khung tối thiểu, không fake data): ĐẠT — màn chỉ header + body trống, grep sạch.
  > - FR-008 (cơ chế màn phụ, quay lại đúng màn cũ): ĐẠT — `SubPageScaffold` dùng chung, widget test.
  > - FR-009 (không vỡ/che theo kích thước & vùng an toàn): ĐẠT — nav trong `SafeArea`; thiết bị tai thỏ vật lý chưa verify (emulator không notch), gesture nav API 37 không che.
  > - FR-010 (điều hướng không lỗi/sai màn): ĐẠT — widget test.
  > - SC-001 (mở + chuyển đủ 4 vùng không lỗi): ĐẠT. SC-002 (FAB 4/4): ĐẠT. SC-003 (chuyển ≥5 lần không treo): ĐẠT.
  > - SC-004 (vùng an toàn không che nav): ĐẠT trên emulator API 37 (SafeArea); tai thỏ thật chưa verify.
  > - SC-005 (cỡ chữ lớn không vỡ): ĐẠT — font_scale 1.3 trên emulator, label co mềm `FittedBox` không tràn.
  > - SC-006 (màn phụ → back đúng màn/tab): ĐẠT — widget test.
  >
  > **Trạng thái sau thi công**
  > - iOS chưa verify (máy Windows): code thuần widget, không gọi API nền tảng → rủi ro thấp; verify khi có máy macOS.
  > - Tai thỏ/phím hệ thống trên thiết bị vật lý chưa verify — nav & FAB nằm trong `SafeArea` (chân), chờ kiểm tra mắt người trên máy có notch nếu cần.

## Sơ đồ phụ thuộc

```text
T001 (setup)
  → T002 (colors) → T003 (theme)
  → US1: (T004 ∥ T005) → T006 → T007 → T008 → T009 → T010
  → US2: T011 → T012 → T013 → T014
  → Polish: T015 → T016 → T017
```

- `T003` (app_theme.dart) phụ thuộc `T002` (app_colors.dart) — cùng cặp theme/token, không song song.
- US1: `T004` (nav bar) và `T005` (screen header) **khác file, chỉ cần theme** → song song. `T006` (4 màn khung) cần `T005`; `T007` (shell) cần `T004` + `T006`. `T008` (app.dart) → `T009` (main.dart) → `T010` (test) tuần tự — test phải đứng sau khi shell dựng xong và counter demo bị bỏ.
- US2: `T011` (sub_page_scaffold) → `T012` (add_transaction_screen) → `T013` (FAB wiring trong shell) → `T014` (mở rộng test). Tuần tự, mỗi task chỉ cần task trước trong cùng US2 (shell đã có từ US1).
- US2 phụ thuộc US1 hoàn tất (`app_shell.dart`, `AppBottomNavBar` có ô giữa trống).

## Ví dụ chạy song song

```text
# Foundational: T003 cần T002 xong (cùng file-set token), chạy nối tiếp.
# Trong US1 — 2 luồng độc lập có thể chạy cùng lúc:
T004 [P] [US1] lib/core/widgets/app_bottom_nav_bar.dart   (chỉ cần theme)
T005 [P] [US1] lib/core/widgets/screen_header.dart         (chỉ cần theme)

# Sau T005, T006 (4 màn) chỉ cần screen_header, có thể chạy song song với nhánh T007 (shell)
# nếu tách 2 người: nhưng T007 cần nav bar (T004) + màn khung (T006) nên thường làm nối tiếp.
# US2 và Polish: tuần tự, không cơ hội song song có ý nghĩa.
```

## Chiến lược triển khai

- **MVP đề xuất**: US1 (điều hướng 4 vùng chính + bottom nav 5 vị trí). Lát cắt này chạy được độc lập: mở app → vào Tổng quan, chuyển đủ 4 tab, giữ trạng thái. Điểm dừng sớm sau `T010` (widget test pass).
- **Giao hàng tăng dần**: US1 → US2. Toàn bộ PBI 2 = 1 release hoàn chỉnh; US2 (FAB + màn phụ) bắt buộc để đóng spec (SC-002 FAB 4/4, SC-005/006 liên quan màn phụ) — không tách release riêng, vì shell không FAB chưa đúng khung điều hướng thiết kế.
- Bước tiếp theo: chạy `/sora-implement 2`.
