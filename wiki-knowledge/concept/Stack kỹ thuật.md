---
title: "Stack kỹ thuật"
date: 2026-09-03
tags: [concept, stack, architecture]
sources:
  - ../docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md
  - ../docs/budget/nghiep-vu-ngan-sach.md
  - ../docs/wallet/nghiep-vu-vi-tai-khoan.md
  - ../../.specify/specs/18/research.md
---

# Stack kỹ thuật

Chốt trong doc tính năng tổng §Stack. App: **Flutter Mobile (Android/iOS), offline hoàn toàn** — không server, dữ liệu local.

## Thư viện chính
| Thư viện | Mục đích | Module dùng |
|---|---|---|
| `drift` | Local DB (SQLite) | Toàn app — bảng `wallets`, `transactions`, `categories`, `budgets`, `budget_period_snapshots` |
| `GetX` | State management + **Translations (i18n)** | Toàn app — VD `BudgetController` quản DS budget active + snapshot (budget doc §9) |
| `fl_chart` | Biểu đồ | Báo cáo (pie/bar/line); so sánh dự kiến–thực tế budget (cột đôi/line chồng) |
| `flutter_local_notifications` | Thông báo local push | Nhắc gd định kỳ, cảnh báo budget, nhắc mục tiêu, tổng kết |
| `flutter_secure_storage` | Lưu bí mật khóa app + khóa mã hóa (Keychain/Keystore) | Khóa app — PBI 3: key `pin_salt_hash` (hash PIN), key `lock_state` (chống dò JSON) |
| `crypto` | Băm **SHA-256** (PBI 3, dep mới) | Hash PIN có muối — [[Hồ sơ & Bảo mật]] |
| `local_auth` | Sinh trắc học (vân tay/FaceID) | Lớp mở khóa tiện lợi + xác thực data nhạy cảm |
| JSON file | Backup/restore (GĐ3) | Export/import toàn bộ dữ liệu |

## Quyết định kiến trúc ghi nhận
- **Offline, không API**: tỷ giá quy đổi đa tiền tệ dùng bảng tỷ giá lưu sẵn/nhập tay — **không** real-time API ([[Ví & Tài khoản]]).
- **Mã hóa local**: SQLite/Hive mã hóa; không lưu số thẻ/ngân hàng thật.
- **Số liệu tính toán/cache**: `current_balance` ví, `budget_period_snapshots` — drift cache để khỏi tính lại toàn bộ lịch sử mỗi lần mở màn (budget doc §9). Snapshot vẫn **recompute** khi gd trong phạm vi đổi ([[Ngân sách]], [[Nguyên tắc nghiệp vụ]]).
- **Transfer 2 dòng liên kết** bằng `transfer_group_id` → xóa/sửa đồng bộ.
- Widget "% dùng hạn mức thẻ tín dụng" nên tách widget dùng chung → tái dùng cho thanh tiến độ ngân sách.

## Đa ngôn ngữ (i18n) — rule
Cơ chế chốt: **GetX Translations** (gói `get`, sẵn trong pubspec). Rule triển khai (quyết định user, chưa nằm `docs/`):
- **Áp từ khi dựng UI**: mọi chuỗi giao diện đi qua key i18n — 1 class `extends Translations` giữ map key→chuỗi theo từng ngôn ngữ, widget gọi `.tr`, **không hardcode tiếng Việt trong widget**. Làm từ đầu để tránh quét refactor khi bật tính năng đa ngôn ngữ (chưa thuộc MVP, xem [[Lộ trình phát triển]]).
- Cấu hình tại root: `GetMaterialApp(translations: <class Translations>, locale: Locale('vi'), fallbackLocale: Locale('vi'), supportedLocales: [...])`. Mặc định + fallback = **tiếng Việt**.
- **Ngôn ngữ hỗ trợ**: doc §12 gợi ý "Việt/Anh..." — chốt mặc định `vi`; `en` + danh sách đầy đủ ⚠ chưa chốt.
- **Không dịch dữ liệu người dùng** (tên ví/danh mục/giao dịch tự đặt, seed category là data) — chỉ dịch chuỗi hệ thống.
- Chuỗi có tham số/ngữ cảnh (VD insight "Bạn chi nhiều hơn tháng trước 15%") → placeholder trong key + truyền tham số, **không ghép chuỗi tay**.
- **Không trộn i18n với định dạng số/tiền/ngày**: số tiền theo quy tắc [[Design system]] (dấu chấm nghìn, đơn vị theo tiền tệ ví) và format ngày là vấn đề riêng, **không đổi theo ngôn ngữ giao diện**.
- Picker Material (date/time) đồng bộ locale → cần thêm `flutter_localizations` + `GlobalMaterialLocalizations` khi có ≥2 ngôn ngữ.

## Giao diện Sáng/Tối — cơ chế (rule, PBI 18)
Cơ chế chốt (quyết định user, lệch gợi ý `docs/tool/giai-phap-tien-ich-ca-nhan-hoa.md §1.2` dùng `Get.changeThemeMode()`):
- **`ThemeController` (GetxController) giữ `Rx<ThemeMode>`**, đăng ký Get singleton ở **gốc `SoraApp`** (bám pattern `PinController`) — không dựa vào `Get.changeThemeMode()` + `ThemeService` ngầm (khó bơm seam trong widget test).
- `GetMaterialApp` nhận `theme` + `darkTheme` + `themeMode` đọc từ controller → đổi Rx là **toàn cây rebuild tức thì** (FR-005/SC-004), không restart. Controller cũng là nguồn cho radio màn `02` và giá trị hàng "Giao diện" màn `01`.
- **"Theo hệ thống"** dựa sẵn `ThemeMode.system` của Material (tự nghe `platformBrightness`) — **không** tự viết `WidgetsBindingObserver.didChangePlatformBrightness`.
- **Nạp lúc boot:** mặc định `system` trước khi `load()` xong; `home` là cổng boot nền trống + phải mở khóa PIN mới thấy nội dung → chấp nhận nháy nền khung đầu, không chặn frame.
- **Seam & DI theo pattern PBI 17:** abstract `ThemeStore` (`load()→ThemeMode?`, `save`) + `DriftThemeStore` (1 row `themeMode` trong `AppSettings`) + `ensureThemeStore()`/`ensureThemeController()`; `SoraApp` thêm seam `themeStore?`; test bơm `FakeThemeStore` (không khởi tạo sqlite native). Ghi write-through **nối đuôi** để chọn nhanh liên tiếp không bị save cũ đè.
- Bộ màu 2 theme: xem [[Design system]] §Giao diện Sáng / Tối.

## Liên kết
- [[Lộ trình phát triển]] — giai đoạn gắn tech (notification là GĐ2, backup GĐ3); đa ngôn ngữ chưa gắn GĐ.
- [[Nguyên tắc nghiệp vụ]] — constraint thiết kế DB.
- [[Design system]] — bảng token light/dark; [[Hồ sơ & Bảo mật]] — màn 02 + bảng `AppSettings`.
