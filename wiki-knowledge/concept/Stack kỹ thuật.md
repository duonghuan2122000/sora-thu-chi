---
title: "Stack kỹ thuật"
date: 2026-09-03
tags: [concept, stack, architecture]
sources:
  - ../docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md
  - ../docs/budget/nghiep-vu-ngan-sach.md
  - ../docs/wallet/nghiep-vu-vi-tai-khoan.md
  - ../../.specify/specs/18/research.md
  - ../docs/notification/notification-solution.md
  - ../../.specify/specs/30/data-model.md
---

# Stack kỹ thuật

Chốt trong doc tính năng tổng §Stack. App: **Flutter Mobile (Android/iOS), offline hoàn toàn** — không server, dữ liệu local.

## Thư viện chính
| Thư viện | Mục đích | Module dùng |
|---|---|---|
| `drift` | Local DB (SQLite) | Toàn app — bảng `wallets`, `transactions`, `categories`, `budgets`, `scan_sessions`, **`notifications` (schema **v9** — PBI 30)**, `app_settings` |
| `GetX` | State management + **Translations (i18n)** | Toàn app — VD `BudgetController` quản DS budget active + snapshot (budget doc §9) |
| `fl_chart` `^1.2.0` | Biểu đồ | **Đã dùng thật**: `BarChart` cột đôi + `ExtraLinesData` nét đứt ở màn `03` Chi tiết Ngân sách (PBI 21), **`PieChart` lần đầu** (vòng tròn phân bổ) + `BarChart` cột ghép đôi có tooltip ở màn `01` Báo cáo (PBI 22), **`LineChart` + `dashArray`** ở màn `03` So sánh kỳ (PBI 26) — [[Báo cáo]]. Còn lại: line chart xu hướng **một kỳ** ở màn `01` |
| `pdf` `^3.13.0` *(PBI 27)* | Sinh **PDF thuần Dart** (`pw.Document` + `MultiPage` + `ThemeData.withFont`) — chạy được trong isolate | Màn `04` Xuất báo cáo (định dạng PDF) |
| `excel_community` `^2.4.0` *(PBI 27)* | Sinh `.xlsx` 2 sheet | Màn `04` Xuất báo cáo (định dạng Excel) |
| `share_plus` `^13.3.0` *(PBI 27)* | Mở **bảng chia sẻ của hệ điều hành** (`SharePlus.instance.share` + `XFile.fromData`) | Màn `04` — cả 3 định dạng đi **một** đường chia sẻ |
| `flutter_local_notifications` | Thông báo local push | Nhắc gd định kỳ, cảnh báo budget, nhắc mục tiêu, tổng kết |
| `flutter_secure_storage` | Lưu bí mật khóa app + khóa mã hóa (Keychain/Keystore) | Khóa app — PBI 3: key `pin_salt_hash` (hash PIN), key `lock_state` (chống dò JSON) |
| `crypto` | Băm **SHA-256** (PBI 3, dep mới) | Hash PIN có muối — [[Hồ sơ & Bảo mật]] |
| `local_auth` | Sinh trắc học (vân tay/FaceID) | Lớp mở khóa tiện lợi + xác thực data nhạy cảm |
| `google_mlkit_text_recognition` `^0.17.1` | OCR **bộ Latin đóng gói sẵn**, chạy offline | Quét hóa đơn (PBI 24) — [[Giao dịch]] |
| `camera` `^0.12.1` | Preview + chụp ảnh (`enableAudio: false`) | Màn chụp `scan-02` |
| `image_picker` `^1.2.3` | Chọn ảnh từ **thư viện** | Màn chụp — nút "Thư viện" |
| `image` `^4.9.2` | Tiền xử lý ảnh **thuần Dart** (xoay/resize/contrast/JPEG) | Pipeline trước OCR (chạy trong `compute`) |
| `device_info_plus` `^13.2.0` | RAM + phiên bản HĐH | Kiểm tra cấu hình `scan-10` |
| `com.google.mlkit:genai-prompt` `1.0.0-beta4` *(Android native, chặng 2)* | Gọi **Gemini Nano** do AICore hệ thống quản lý (không tải model về app) | Tier A — kênh `sora_thu_chi/device_probe`, method `genAiGenerate` |
| `flutter_gemma` `^1.8.1` + `flutter_gemma_litertlm` `^1.6.3` *(chặng 2)* | Chạy **Gemma 3n E2B** (`.litertlm`) trên máy + tải/xoá model có tiến trình | Tier B — `GemmaLlm`, `GemmaModelManager` |
| JSON file | Backup/restore (GĐ3) | Export/import toàn bộ dữ liệu |

- **minSdk Android nâng lên 26** (chặng 2, do ML Kit GenAI Prompt API yêu cầu) — ghi `maxOf(flutter.minSdkVersion, 26)` trong `android/app/build.gradle.kts`.
- **Không dùng `excel` gốc**: `excel 4.0.6` buộc `archive ^3.6.1` còn `image ^4.9.2` (PBI 25) buộc `archive ^4.0.9` ⇒ resolver từ chối; `excel_community` giữ API nhưng mở `archive >=4.0.9`. **CSV tự viết** (~30 dòng RFC 4180 + BOM) thay vì thêm package `csv`; **không** dùng `printing` (nặng, có native view) vì cả 3 định dạng đi chung `share_plus`.

## Quyết định kiến trúc ghi nhận
- **Offline, không API**: tỷ giá quy đổi đa tiền tệ dùng bảng tỷ giá lưu sẵn/nhập tay — **không** real-time API ([[Ví & Tài khoản]]).
- **Mã hóa local**: SQLite/Hive mã hóa; không lưu số thẻ/ngân hàng thật.
- **Số liệu tính toán/cache**: `current_balance` ví, `budget_period_snapshots` — drift cache để khỏi tính lại toàn bộ lịch sử mỗi lần mở màn (budget doc §9). Snapshot vẫn **recompute** khi gd trong phạm vi đổi ([[Ngân sách]], [[Nguyên tắc nghiệp vụ]]).
  - **Thực tế đã đi ngược đề xuất này 2 lần** (PBI 21 và 22): **bỏ** bảng snapshot ngân sách và **bỏ** bảng tổng hợp báo cáo `report_monthly_summary` — mọi số liệu tính lại từ `transactions` khi nạp màn (dữ liệu cá nhân vài nghìn dòng ⇒ dưới ngưỡng 1 giây). Chỉ thêm cache khi **đo** thấy chậm.
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

## Quét hóa đơn AI — seam, kênh native & dữ liệu (PBI 24, **chặng 1 + chặng 2**)
Chặng 1 = **Chế độ cơ bản** (bộ luật, không LLM) + kiểm tra cấu hình máy + mục Cài đặt. **Chặng 2 = AI nâng cao**: Tier A (Gemini Nano qua AICore) + Tier B (Gemma 3n E2B tải ~1.8GB) — cùng seam `ReceiptExtractor`, fallback về bộ luật khi lỗi/timeout.

**5 seam tách khỏi plugin — test widget không cần camera/ML Kit/drift thật** (`lib/core/scan/`):
- `ReceiptOcr.readText` — impl thật `MlKitReceiptOcr` (TextRecognition bản Latin, nối text + chuẩn hoá `boundingBox` pixel → `ScanRect` 0..1 theo kích thước ảnh).
- `ReceiptExtractor` — seam **2 engine dùng chung một định dạng kết quả**: `RuleBasedExtractor` (bộ luật) và `LlmExtractor` (chặng 2: timeout **10s** + `try/catch` → gọi lại bộ luật trong cùng seam, ghi `engine` **thực dùng**). Chọn engine theo tier ở `ScanSettings.effectiveEngine` — Tier B **chỉ chạy khi đã tải model** (`modelBytes > 0`), còn lại rơi về bộ luật. Model trả JSON (`amount`/`date`/`merchant`/`category`) → `parseLlmReceipt` (JSON hỏng/không có JSON ⇒ coi như thất bại, không đoán); model **không** trả vùng chữ nên `rect` để trống (màn xác nhận không khoanh vùng).
- `ScanModelManager.download/cancelDownload/delete/installedBytes` — seam tải/xoá model Tier B; impl `GemmaModelManager` (`flutter_gemma`). Mọi lỗi ⇒ `false` và **không** bật AI (FR-012).
- `ScanImageStore.save/delete` — impl ghi `<appDocuments>/receipts/<millis>.jpg`; **chỉ** gọi ở nhánh lưu.
- `DeviceProbe.measure` — impl `PlatformDeviceProbe`: `device_info_plus` (RAM, phiên bản OS) + **MethodChannel `sora_thu_chi/device_probe`** (dung lượng trống, AICore, GPU delegate). Mọi lỗi ⇒ **giá trị mặc định an toàn** (dung lượng 0 ⇒ Tier C, luồng vẫn chạy), không ném.
- `ScanSettingsStore.load/save` — impl drift 4 key trong `AppSettings`.

**Kênh native `sora_thu_chi/device_probe`** (`DeviceProbeChannel.kt` + `DeviceProbeChannel.swift`, **phải đăng ký** trong `MainActivity`/`AppDelegate` — thiếu đăng ký ⇒ màn `scan-10` treo ở "Đang kiểm tra…"). iOS trả `supportsOnDeviceAi = false` + `supportsGpuDelegate = false`. **Chặng 2 cắm tiếp GenAI vào chính kênh này** (`GenAiChannel.kt`, method `genAiGenerate` — gọi Gemini Nano trên `Dispatchers.Main`, có `kotlinx-coroutines-android`).

**Trạng thái**: `ScanController extends GetxController` giữ `Rx<ScanSettings>` (bám `ThemeController`), write-through **nối đuôi** để chạm nhanh liên tiếp không bị save cũ đè; `ensureScanSettingsStore()`/`ensureScanController()` đăng ký ở gốc `SoraApp`.

**Dữ liệu (schema v8)**: cột `transactions.source` (`textEnum<TxnSource>`, default `manual`) + bảng `scan_sessions` (`image_path`, `raw_text`, `parsed_json`, `engine`, `transaction_id` nullable, `created_at`). Migration `from < 8` chỉ `addColumn` + `createTable`, **không seed**; 🪤 **quên `build_runner` sau khi sửa bảng ⇒ thiếu cột, build lỗi**. Ghi một lần quét = **một `db.transaction()`**: bù `balance` ví + insert `transactions` + insert `scan_sessions`.

**Tiền xử lý ảnh thuần Dart** (`package:image`, chạy trong `compute`): `bakeOrientation` → resize `maxSide 2000` → `adjustColor(contrast: 1.15, saturation: 0)` → JPEG `quality 88`. **Không** dò biên/crop hóa đơn (quyết định R4 — crop theo biên đoán sai làm mất dòng tổng).

**Nền tảng**: 5 package trên nâng **iOS tối thiểu lên 15.5** (Podfile + 3 chỗ `IPHONEOS_DEPLOYMENT_TARGET` — bắt buộc cho ML Kit) và cần 3 khóa quyền (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSMicrophoneUsageDescription`) + `CAMERA` trong AndroidManifest. **Android release (R8/minify) cần `proguard-rules.pro`** `-dontwarn com.google.mlkit.vision.text.**` — plugin tham chiếu cả bộ nhận diện Nhật/Hàn/Trung trong nhánh `initialize` dù app chỉ đóng gói bộ Latin; thiếu luật này ⇒ `assembleRelease` **fail**.

## Xuất báo cáo — sinh tệp & chia sẻ (PBI 27)

- 🪤 **Thêm plugin native ⇒ PHẢI build lại + cài lại app** (`flutter run` từ đầu, không đủ hot reload/hot restart). Triệu chứng khi chạy bản cài cũ: `MissingPluginException(No implementation found for method share on channel dev.fluttercommunity.plus/share)` — bản APK build sau khi thêm dep **có** class plugin (`classes*.dex`) + `res/xml/flutter_share_file_paths.xml`, nên gặp lỗi này thì **xoá app khỏi máy rồi cài lại** trước khi nghi code.
- **Font nhúng**: `assets/fonts/Roboto-Regular.ttf` + `Roboto-Bold.ttf` (Apache-2.0, ~515 KB/file) khai báo trong `pubspec.yaml`. Font mặc định của `pdf` không có dấu tiếng Việt ⇒ **buộc** phải nhúng; **không** tải font lúc chạy (giữ app offline).
- 🪤 **`rootBundle` không dùng được trong isolate nền** ⇒ font **phải** nạp ở main isolate rồi truyền bytes vào `compute()` cùng phần dữ liệu thuần.
- Ba hàm sinh tệp **thuần Dart** (`lib/core/report/report_export.dart` + `report_export_writers.dart`): `buildCsvBytes`, `buildXlsxBytes`, `buildPdfBytes` — không `Widget`/`BuildContext`/asset ⇒ gọi được trong `compute`.
- 🪤 **Tên tệp khi chia sẻ**: trên Android/iOS `XFile.fromData(bytes, name: …)` **bỏ qua** `name` (cross_file chỉ suy `name` từ `path`) ⇒ phải truyền `ShareParams.fileNameOverrides` — thiếu thì tên tệp chia sẻ thành chuỗi ngẫu nhiên.
- Seam `ShareExport` (`typedef` + `defaultShareExport`) để test bơm bản giả, **không** mock MethodChannel.

## Lịch sử thông báo — seam & bảng drift (PBI 30, **0 dependency mới**)
- **Seam MỚI `NotificationHistoryStore`** (3 phương thức: `loadRecent()` / `append(n)` / `markRead(id, readAt)`) trong `lib/core/notification/` — **cố ý không nới** `NotificationStore` của PBI 28 (2 mối quan tâm khác nhau: cấu hình vs lịch sử; nới interface cũ buộc phải sửa `DriftNotificationStore` + `FakeNotificationStore` đã QA mà không được lợi gì). Bỏ `unreadCount` (đếm bằng Dart ở chỗ gọi — tối đa 200 dòng), không `markAllRead`/`delete` (spec cấm).
- **Bảng drift `notifications` (schema v9)**: `id` autoIncrement · `kind` `textEnum<NotificationKind>()` · `title` · `body` (default `''`) · `created_at` dateTime · `read_at` dateTime **nullable** · `related_id` int **nullable** (không FK — bám nếp `transactions.category_id`: xoá đối tượng nghiệp vụ **không** làm mất lịch sử). Migration `from < 9` chỉ `createTable`, **không seed**; DB mới có bảng nhờ `m.createAll()`. Không index (bảng tối đa 200 dòng, luôn quét cả bảng).
- **Trần 200 cưỡng chế ở TẦNG GHI** (`kMaxNotifications = 200`, hằng trong `app_notification.dart` — không phải cấu hình người dùng): `append` chèn 1 dòng rồi `SELECT id` top-200 theo `(created_at DESC, id DESC)` + `delete(id.isNotIn(keep))`. Nghĩa là **mọi** đường ghi đều đúng, kể cả engine tương lai; khoá phụ `id` làm thứ tự **tất định** khi trùng `created_at`.
- **Một chiều ở tầng SQL**: `markRead` = `UPDATE … WHERE id = ? AND read_at IS NULL` — gọi lại **không** đổi `read_at`; id không tồn tại → no-op, không ném. Không có cờ `is_read` thứ hai (`isRead ⟺ readAt != null`).
- `DriftNotificationHistoryStore` + `ensureNotificationHistoryStore()` (GetX singleton — **1** connection drift trên file sqlite; test `Get.put` fake trước ⇒ không mở drift); test bơm `FakeNotificationHistoryStore`.
- **Nâng schema ⇒ phải sửa số khẳng định ở 4 file test drift cũ** (`notification_store_drift` / `scan_settings_store_drift` / `utilities_store_drift` / `scan_dao`: `schemaVersion` 8 → 9) — không tránh được, chỉ đổi con số, không đổi hành vi kiểm.
- ⚠ **Trần 200 kiểm được ở DAO drift thật** trên host Windows này (có sqlite native) — tức test `notification_history_store_drift_test` **không** bị skip, khác mấy test drift phải skip-guard.

## Liên kết
- [[Lộ trình phát triển]] — giai đoạn gắn tech (notification là GĐ2, backup GĐ3); đa ngôn ngữ đã xong ở PBI 19.
- [[Nguyên tắc nghiệp vụ]] — constraint thiết kế DB.
- [[Design system]] — bảng token light/dark; [[Hồ sơ & Bảo mật]] — màn 02 + bảng `AppSettings`.
