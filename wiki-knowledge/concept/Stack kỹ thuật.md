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
| `drift` | Local DB (SQLite) | Toàn app — bảng `wallets`, `transactions`, `categories`, `budgets` (schema **v7**), `app_settings` |
| `GetX` | State management + **Translations (i18n)** | Toàn app — VD `BudgetController` quản DS budget active + snapshot (budget doc §9) |
| `fl_chart` `^1.2.0` | Biểu đồ | **Đã dùng thật lần đầu ở PBI 21**: `BarChart` cột đôi + `ExtraLinesData` nét đứt ở màn `03` Chi tiết Ngân sách ([[Ngân sách]]). Còn lại: tab Báo cáo (pie/bar/line) |
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

## Đa ngôn ngữ (i18n) — rule & cơ chế đã thi công (PBI 19)
Cơ chế chốt: **GetX Translations** (gói `get`, sẵn trong pubspec). Đã triển khai thật ở PBI 19 (màn `03` — [[Hồ sơ & Bảo mật]]).

**Điểm khác biệt cốt lõi — khóa dịch LÀ chuỗi tiếng Việt đang hiển thị**, không phải slug:
- Bản đồ `SoraTranslations extends Translations` chỉ có **nhánh `'en'`**; **không có nhánh `'vi'`** và **không set `fallbackLocale`**. Vì thiếu nhánh/thiếu khóa/`Get.locale == null` thì `String.tr` (get_utils) trả lại chính khóa ⇒ tiếng Việt hiển thị đúng mà không cần bản đồ nào, và mọi widget test cũ (pump `MaterialApp` thường) giữ nguyên kết quả.
- Widget gọi `'Nhãn tiếng Việt'.tr`; chuỗi có phần động dùng `.trParams({'x': …})` (placeholder `@x` trong khóa), **không ghép chuỗi tay**. Một nguồn duy nhất cho nhãn dùng chung nhiều màn (VD `themeModeLabel`).
- **Hệ quả quy ước:** khi thêm nhãn mới phải gắn `.tr` **ngay trong cùng bước** và thêm khóa `'en'` tương ứng. Test `sora_translations_test.dart` quét `lib/**` bắt literal trước `.tr/.trArgs/.trParams` rồi assert có bản dịch ⇒ bắt được lỗi *gắn `.tr` thiếu khóa*, **không** bắt được lỗi *quên gắn `.tr`* (phải QA tay).

**Cấu hình tại root `SoraApp`:** `GetMaterialApp(translations: SoraTranslations(), locale: <LocaleController>, supportedLocales: [vi, en], localizationsDelegates: [GlobalMaterial/Widgets/Cupertino])` — `flutter_localizations` (**chỉ SDK Flutter**, không package bên thứ ba) + 3 delegate chuẩn cho hộp thoại/nhãn hệ thống (date picker…). Mặc định + giá trị khi chưa chọn = **`vi`**; `en` là ngôn ngữ thứ hai duy nhất (*không* có "theo ngôn ngữ hệ thống").

**Đổi ngôn ngữ tức thì (bài học đo được):** hạ `locale:` xuống `GetMaterialApp` là **không đủ** — route đang mở **không** tự rebuild khi locale đổi (probe `LEAF BUILDS before=1 after=1`). Nên `LocaleController.setLocale` gọi thêm **`Get.updateLocale(locale)`** = `reassembleApplication()` → dựng lại toàn cây widget (giữ state + stack điều hướng), nhãn mọi màn đổi ngay (FR-005). Đây là **ngoại lệ có lý do** so với "rebuild tối thiểu": thao tác rất hiếm (user chủ động đổi ngôn ngữ), không nằm đường đi nóng; chỉ gọi khi giá trị **thật sự đổi** (no-op khi chạm lại hàng đang chọn). Gọi **bắn-và-quên** (không `await`) — `await` làm test treo vì fake async không hoàn tất reassemble.

**Seam & DI theo pattern PBI 17/18:** domain thuần `locale_prefs.dart` (hằng `kKeyLocale`, `localeToStorage`/`localeFromStorage` — giá trị lạ ⇒ `vi`, không ném; hằng `kLanguageOptions` 2 hàng màn `03`) + abstract `LocaleStore` (`load()→Locale?`, `save`) + `DriftLocaleStore` (**1 row `locale`** trong `AppSettings`, chỉ upsert key này — không xoá `themeMode`/công tắc) + `ensureLocaleStore()`/`ensureLocaleController()`; `SoraApp` có seam `localeStore?`; test bơm `FakeLocaleStore`. Lưu ghi write-through **nối đuôi** (chạm nhanh liên tiếp → lần cuối thắng).

**Không dịch:** dữ liệu người dùng (tên giao dịch/ghi chú/tag/**tên ví** kể cả ví mẫu, danh mục tự tạo hoặc đã đổi tên), tên riêng/thương hiệu, chuỗi dùng làm `ValueKey`/`Key`, dữ liệu seed. **Tên danh mục mặc định chưa đổi tên** thì dịch — quy tắc ở [[Danh mục]].

**Không trộn i18n với định dạng số/tiền/ngày:** số tiền theo quy tắc [[Design system]] (dấu chấm nghìn, đơn vị `đ`) và format ngày `dd/MM/yyyy` (chỉ phần chữ `Hôm nay`/`Hôm qua` đi qua `.tr`) là vấn đề **riêng, không đổi theo ngôn ngữ giao diện** (tài liệu giải pháp §2.2) — thuộc màn `04` "Định dạng & Tiền tệ" (PBI sau).
- Chuỗi có tham số/ngữ cảnh (VD insight "Bạn chi nhiều hơn tháng trước 15%") → placeholder trong khóa + truyền tham số, **không ghép chuỗi tay**.

## Giao diện Sáng/Tối — cơ chế (rule, PBI 18)
Cơ chế chốt (quyết định user, lệch gợi ý `docs/tool/giai-phap-tien-ich-ca-nhan-hoa.md §1.2` dùng `Get.changeThemeMode()`):
- **`ThemeController` (GetxController) giữ `Rx<ThemeMode>`**, đăng ký Get singleton ở **gốc `SoraApp`** (bám pattern `PinController`) — không dựa vào `Get.changeThemeMode()` + `ThemeService` ngầm (khó bơm seam trong widget test).
- `GetMaterialApp` nhận `theme` + `darkTheme` + `themeMode` đọc từ controller → đổi Rx là **toàn cây rebuild tức thì** (FR-005/SC-004), không restart. Controller cũng là nguồn cho radio màn `02` và giá trị hàng "Giao diện" màn `01`.
- **"Theo hệ thống"** dựa sẵn `ThemeMode.system` của Material (tự nghe `platformBrightness`) — **không** tự viết `WidgetsBindingObserver.didChangePlatformBrightness`.
- **Nạp lúc boot:** mặc định `system` trước khi `load()` xong; `home` là cổng boot nền trống + phải mở khóa PIN mới thấy nội dung → chấp nhận nháy nền khung đầu, không chặn frame.
- **Seam & DI theo pattern PBI 17:** abstract `ThemeStore` (`load()→ThemeMode?`, `save`) + `DriftThemeStore` (1 row `themeMode` trong `AppSettings`) + `ensureThemeStore()`/`ensureThemeController()`; `SoraApp` thêm seam `themeStore?`; test bơm `FakeThemeStore` (không khởi tạo sqlite native). Ghi write-through **nối đuôi** để chọn nhanh liên tiếp không bị save cũ đè.
- Bộ màu 2 theme: xem [[Design system]] §Giao diện Sáng / Tối.

## Liên kết
- [[Lộ trình phát triển]] — giai đoạn gắn tech (notification là GĐ2, backup GĐ3); đa ngôn ngữ đã xong ở PBI 19.
- [[Nguyên tắc nghiệp vụ]] — constraint thiết kế DB.
- [[Design system]] — bảng token light/dark; [[Hồ sơ & Bảo mật]] — màn 02 + bảng `AppSettings`.
