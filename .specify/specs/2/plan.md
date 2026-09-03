# Kế hoạch triển khai: Khung điều hướng ứng dụng

**Mã PBI**: 2
**Liên kết spec**: .specify/specs/2/spec.md
**Ngày tạo**: 2026-09-03

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12.x (Flutter 3.44.x stable — khảo sát trên máy, theo PBI 1) |
| Framework / Thư viện chính | Flutter Material, UI thuần widget; **không thêm thư viện mới**. GetX 4.7.3 đã có nhưng chưa dùng trong shell (lý do ở research) |
| Lưu trữ dữ liệu | Không dùng — đợt này không có dữ liệu (màn khung trống, FR-007) |
| Kiểm thử | `flutter analyze` sạch + `flutter test` (widget test thay counter demo) + QA thủ công trên Android emulator API 37 theo `quickstart.md` |
| Nền tảng triển khai | Android (kiểm chứng chính); iOS (code thuần widget, rủi ro thấp — verify khi có máy macOS) |
| Ràng buộc hiệu năng | Không đặc thù; `IndexedStack` giữ 4 tab sống — bộ nhớ không đáng kể cho màn khung |
| Ràng buộc khác | App offline; UI/tài liệu/commit tiếng Việt có dấu; tuân design system (1 màu thương hiệu teal `#0F6E56`, FAB tròn 48–52px, tab chọn teal/chưa chọn xám `#9B9B9B`); **cấm số liệu/ảnh minh họa giả** (FR-007); style tập trung 1 nơi (theme/token); không vỡ khi cỡ chữ lớn & vùng an toàn (SC-004/005) |

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md`. Đối chiếu quy ước `CLAUDE.md` + design system:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không server | ✅ | Không gọi mạng, không auth |
| Đúng stack đã chốt | ✅ | Không thêm dependency; GetX giữ cho PBI có controller |
| Đúng design system | ✅ | Nav/FAB/header đọc từ design doc §2.1 + mockup `auth/01-khung-dieu-huong.svg` |
| Style tập trung 1 nơi | ✅ | Tạo theme/token trung tâm, widget không hex cứng |
| Cấm fake data | ✅ | Màn chính chỉ tiêu đề + body trống |
| Shell tách khỏi màn bảo mật | ✅ | Khóa PIN/Onboarding ngoài phạm vi; shell không chặn gắn sau (home có thể đổi) |
| Tài liệu & commit tiếng Việt có dấu | ✅ | Toàn bộ file tiếng Việt |

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Không phình layer nghiệp vụ | ✅ | Chỉ shell/theme/screen khung, không controller/db/giả lập |
| Không vi phạm mới phát sinh | ✅ | Toàn bộ quyết định research đều nhất quán hiến pháp |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Tóm tắt quyết định chính:
- **Navigator chuẩn (MaterialApp)**, chưa dùng GetX router — shell tĩnh không cần; GetX vào khi có controller (đổi MaterialApp→GetMaterialApp 1 dòng).
- **IndexedStack** giữ state 4 tab (FR-004); chỉ số tab = `int` trong `State` shell.
- **Tự dựng bottom nav 5 vị trí** (Row 5 ô: 4 tab + ô giữa trống) + FAB `Scaffold.centerDocked` nổi giữa — khớp mockup; không dùng NavigationBar M3/BottomAppBar notch.
- **Sub-page dùng chung** `SubPageScaffold` (AppBar teal + back, không nav); push route phủ toàn màn = tự ẩn bottom nav (FR-006/8); Cài đặt PBI sau tái dùng.
- **Theme/token tập trung**: `app_colors.dart` (màu thực dùng) + `app_theme.dart`; widget không hex cứng.
- **4 màn chính là file riêng**, mỗi màn header teal + body trống (chỗ bám cho PBI module).
- **Kiểm chứng**: widget test host (thay counter demo) + QA thủ công emulator cho SC-004/005; chống vỡ cỡ chữ bằng label co mềm trong ô.

## Giai đoạn 1 — Thiết kế

- Mô hình dữ liệu: **không tạo** — không thực thể, ngoài phạm vi spec.
- Hợp đồng giao diện: **không tạo** — app nội bộ, không API/CLI công khai.
- Kịch bản khởi động nhanh: xem `quickstart.md` — 8 mục QA đối chiếu SC-001..006.

## Cấu trúc dự án dự kiến

```
app/sora_thu_chi/lib/
├── main.dart                                  # [SỬA] bỏ counter demo → runApp(SoraApp)
├── app.dart                                   # [TẠO] SoraApp: MaterialApp + AppTheme + home AppShell
├── theme/
│   ├── app_colors.dart                        # [TẠO] token màu đang dùng (teal, xám tab, divider...)
│   └── app_theme.dart                         # [TẠO] AppTheme → ThemeData (appBar/colorScheme)
├── core/
│   ├── app_shell.dart                         # [TẠO] StatefulWidget: IndexedStack 4 tab + bottom nav + FAB
│   └── widgets/
│       ├── app_bottom_nav_bar.dart            # [TẠO] thanh 5 vị trí (4 tab + ô giữa) + nút chọn
│       ├── screen_header.dart                 # [TẠO] header teal cho màn chính (vùng tiêu đề)
│       └── sub_page_scaffold.dart             # [TẠO] AppBar teal + back, dùng cho màn phụ (FR-008)
└── screens/
    ├── dashboard_screen.dart                  # [TẠO] Tổng quan — khung
    ├── transaction_screen.dart                # [TẠO] Giao dịch — khung
    ├── report_screen.dart                     # [TẠO] Báo cáo — khung
    ├── settings_screen.dart                   # [TẠO] Cài đặt — khung
    └── add_transaction_screen.dart            # [TẠO] màn phụ "Thêm giao dịch" — khung

app/sora_thu_chi/test/widget_test.dart         # [SỬA] test counter → smoke test shell

Không đổi: pubspec.yaml, android/, ios/ (không cần cấu hình nền tảng mới).
```

## Rủi ro & ngoại lệ có lý do

- **Lệch pixel so với mockup**: design doc chỉ "icon gợi ý"; icon/vị trí chính xác căn theo `docs/auth/01-khung-dieu-huong.svg`. Trong quá trình thi công đối chiếu svg; sai khác nhỏ không phải ràng buộc (mock gợi ý, không phải đặc tả tuyệt đối).
- **Cỡ chữ lớn làm nhãn tab tràn ô** (SC-005): phòng ngừa bằng label co mềm (`FittedBox`) + `SafeArea` chân thanh; nếu vẫn vỡ trên thiết bị thật → điều chỉnh lại rồi ghi vào trạng thái sau thi công, không bỏ ngang.
- **Vùng an toàn đáy** (SC-004): thanh nav nằm trong `SafeArea`; kiểm chứng trên emulator có phím hệ thống / cử chỉ.
- **iOS chưa verify** (máy Windows): code thuần widget Flutter nên rủi ro thấp; giữ trạng thái, verify khi có máy macOS.
- **FAB đè nội dung body** khi màn module sau có nội dung dài: `Scaffold` tự chèn padding dưới = chiều cao nav; khi gắn nội dung thật, module tự canh padding cuối. Ghi để PBI module lưu ý, không xử lý thừa bây giờ.

## File đã tạo

- `.specify/specs/2/research.md`
- `.specify/specs/2/quickstart.md`
- `.specify/specs/2/plan.md`

Bước tiếp theo: chạy `/sora-task 2` để phân rã thành tasks.md.
