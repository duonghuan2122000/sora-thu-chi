# Kế hoạch triển khai: Thêm giao dịch bằng quét hóa đơn (AI)

**Mã PBI**: 24
**Liên kết spec**: [.specify/specs/24/spec.md](./spec.md)
**Ngày tạo**: 2026-09-12

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12 / Flutter 3.44 (Android + iOS), app **offline hoàn toàn** |
| Framework / Thư viện chính | GetX `^4.7.3` (điều hướng + DI + i18n), Material. **Thêm 5 dependency mới**: `google_mlkit_text_recognition` (OCR on-device, bản bundled — model trong APK, chạy offline), `camera` (màn chụp có khung ngắm + flash), `image_picker` (chọn ảnh thư viện), `image` (tiền xử lý thuần Dart), `device_info_plus` (RAM/phiên bản hệ điều hành). Chặng 2 thêm package LLM (R18) |
| Lưu trữ dữ liệu | drift `^2.34.4` + sqlite local — **schema lên v8**: `transactions.source` (cột mới, default `manual`) + bảng mới `scan_sessions`; cài đặt quét lưu bằng 4 key trong bảng key-value `AppSettings` sẵn có (**không** migration cho phần này); **phải chạy `build_runner`** để sinh lại `app_database.g.dart` |
| Kiểm thử | `flutter_test` — 683 test hiện có; bổ sung **~12 file test mới** + sửa **3 file** (fake repo, smoke dark theme, settings screen). Phần lớn logic nằm ở hàm thuần Dart ⇒ test không cần plugin |
| Nền tảng triển khai | Build local (`flutter build apk` / iOS build) — không server, không CI đặc thù. **iOS deployment target 13.0 → 15.5** (yêu cầu ML Kit) |
| Ràng buộc hiệu năng | SC-007: chụp → màn xác nhận **< 3 giây** (Chế độ cơ bản). Tiền xử lý ảnh (decode/encode JPEG) chạy trong **isolate** để không chặn UI; ảnh thu nhỏ cạnh dài 2000px trước khi đưa vào OCR |
| Ràng buộc khác | Ngôn ngữ giao diện/tài liệu/commit: **tiếng Việt có dấu**; bám Design System (teal `#0F6E56` cho hành động chính; coral `#D85A30` **chỉ** cho cảnh báo/chi tiêu ⇒ chỉ báo "Kiểm tra lại", banner trùng, thông báo lỗi); mọi màu qua token `SoraColors` để chạy đúng dark mode (PBI 18); mọi nhãn tĩnh có bản dịch EN (PBI 19; `sora_translations_test` tự quét `.tr`) |
| Nguồn chân lý nghiệp vụ | `docs/ai/tinh-nang-quet-hoa-don-ai-local.md` (§2 pipeline, §3 luồng chi tiết, §3.5 bộ luật + độ tin cậy, §3.7 lưu dữ liệu, §6 quyền riêng tư, §8 stack bổ sung, §11 kiểm tra cấu hình & tier) + mockup `scan-01`…`scan-04`, `scan-10`, `scan-11` |
| Phân kỳ thi công | **2 chặng trong cùng PBI** (người dùng chốt 2026-09-12 — research R1): chặng 1 = luồng quét trọn vẹn + bộ luật + kiểm tra cấu hình + Cài đặt (QA được toàn bộ trên emulator); chặng 2 = Tier A/B thật (model + tải/xoá) |

*Không còn mục `NEEDS CLARIFICATION`: spec đã "Đã làm rõ"; mọi quyết định kỹ thuật chốt ở `research.md` (R1…R19); các mục phải kiểm chứng lại khi thi công đều thuộc **chặng 2** và không chặn chặng 1.*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

`.specify/memory/constitution.md` **không tồn tại** (repo chưa tạo hiến pháp) ⇒ đối chiếu theo `CLAUDE.md` của repo và các quyết định đã chốt trong `docs/`.

| Nguyên tắc (nguồn: CLAUDE.md + docs) | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline hoàn toàn, không server/không auth | ✅ | OCR dùng bản **bundled** (model trong APK, không tải); không có request mạng nào ngoài bước tải model AI nâng cao (chặng 2, do người dùng chủ động — FR-037). QA nhóm K chạy ở chế độ máy bay |
| Ngôn ngữ giao diện/tài liệu/commit: tiếng Việt có dấu | ✅ | Mọi nhãn, tài liệu, comment, commit của PBI này bằng tiếng Việt |
| Stack đã chốt (drift + GetX + fl_chart) | ⚠️→✅ | Thêm 5 package **ngoài** stack gốc nhưng **đúng doc §8** (doc chỉ định `google_mlkit_text_recognition`, `camera`, `image_picker`, `image`); `device_info_plus` là bổ sung có lý do (R5: đo RAM/OS). Không thay thế package nào đã chốt; fl_chart không dùng ở PBI này |
| Design system: 1 màu thương hiệu teal, coral chỉ cho chi/cảnh báo, không hex cứng trong widget | ✅ | Mọi màu qua `SoraColors`/`AppColors`; coral chỉ ở chỉ báo "Kiểm tra lại" + banner trùng + thông báo lỗi (đúng ngữ nghĩa cảnh báo) |
| Số dư ví là đại lượng suy ra, không sửa tay | ✅ | Đường ghi mới `addScannedTransaction` bù `balance` **theo loại** đúng như `addTransaction`, một transaction DB; màn xác nhận không có ô sửa số dư |
| Thu/chi/chuyển khoản: transfer không tính là thu/chi | ✅ | Giao dịch quét chỉ tạo thu/chi; luồng Chuyển khoản trong sheet vẫn đi vào luồng PBI 8 hiện có, không đổi |
| Màn cấp tab có bottom nav, **màn con không** | ✅ | 5 màn mới (chụp/xử lý/xác nhận/kiểm tra cấu hình/sheet) đều là route đè shell hoặc modal — không đụng `AppShell`/`AppBottomNavBar` |
| Không sửa dữ liệu người dùng ngoài phạm vi | ✅ | Chỉ **thêm** 1 cột (`source`, default `manual`) + 1 bảng mới (`scan_sessions`); không đụng `wallets`/`categories`/`budgets`; không seed |
| Không phá vỡ hành vi PBI trước | ⚠️ có kiểm soát | **Cố ý** đổi hành vi FAB (FR-001/FR-002: FAB giờ mở bottom sheet thay vì mở thẳng form — spec §Quyết định đã chốt 2026-09-12). Chữ ký `addTransaction`/`WalletRepository` cũ **giữ nguyên**; màn thêm giao dịch chỉ **thêm** tham số `initialType` (mặc định = hành vi cũ) |
| Bảo mật: PIN/sinh trắc học, dữ liệu nhạy cảm | ✅ | Luồng quét chỉ chạy sau khi đã mở khoá app (không có màn quét ngoài khoá); ảnh hóa đơn nằm trong thư mục documents riêng của app |
| YAGNI / không abstraction sớm | ✅ | Không bảng ánh xạ, không học theo người dùng, không màn Scan History, không crop tay, không hàng đợi xử lý nền; seam chỉ dựng ở chỗ **bắt buộc** để test được plugin (OCR, camera, đo cấu hình, lưu ảnh) |
| Quy trình PBI: spec → plan → task → implement | ✅ | Đang ở bước plan; `tasks.md` sinh ở bước sau, chia rõ **chặng 1 / chặng 2** |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại [research.md](./research.md). Tóm tắt các quyết định chính:

- **Chia 2 chặng trong cùng PBI (R1, người dùng chốt)** — chặng 1 là luồng quét trọn vẹn ở Chế độ cơ bản + kiểm tra cấu hình + Cài đặt (QA 100% trên emulator); chặng 2 là Tier A/B thật. Trạng thái trung gian được ghi rõ (nút kích hoạt Tier A/B vô hiệu + chú thích "Chưa khả dụng trong bản này"), chặng 2 gỡ.
- **OCR (R2)** — **Quyết định**: `google_mlkit_text_recognition`, bản **bundled** (`com.google.mlkit:text-recognition:16.0.1`, model trong APK) ⇒ chạy offline từ lần đầu, trả văn bản thô **+ bounding box** từng dòng. **Phương án khác**: bản unbundled (phải tải model lần đầu ⇒ vi phạm offline).
- **Chụp ảnh (R3)** — **Quyết định**: `camera` (viewfinder + flash của mockup `scan-02`) + `image_picker` (thư viện ảnh). **Phương án khác**: chỉ `image_picker` ⇒ mất khung ngắm, vỡ SC-001.
- **Tiền xử lý (R4)** — **Quyết định**: `image` trong isolate (sửa chiều EXIF + thu nhỏ cạnh dài 2000 + tăng tương phản); **bỏ** dò biên/crop (nhánh "dùng nguyên ảnh" mà FR-017 cho phép). **Phương án khác**: `image_cropper`/Sobel — spec đã loại crop tay, lợi ích không đo được đợt này.
- **Đo cấu hình máy (R5)** — **Quyết định**: `device_info_plus` cho RAM/OS + **một** kênh native `sora_thu_chi/device_probe` cho dung lượng trống, AICore và GPU delegate (kênh này chặng 2 cắm tiếp Gemini Nano). **Phương án khác**: thêm package dung lượng thứ ba — vẫn phải tự viết native cho AICore.
- **Phân loại tier (R6)** — **Quyết định**: hàm thuần `classifyTier`/`isStale` theo ngưỡng doc §11.2, lưu **1 row JSON** `scanDeviceCheck`. **Phương án khác**: 6 row rời / bảng drift riêng — thừa.
- **Engine trích xuất (R7, R18)** — **Quyết định**: một seam `ReceiptExtractor` với 2 impl (bộ luật / LLM) cho **cùng định dạng kết quả** ⇒ màn xác nhận dùng chung; fallback AI→bộ luật là `try/catch` + timeout 10 giây trong cùng seam (FR-011). Chặng 2: Tier A qua ML Kit GenAI (kênh native), Tier B qua `flutter_gemma` + Gemma 3n E2B ~1.8GB.
- **Bộ luật trích xuất (R8, R9)** — **Quyết định**: `receipt_parser.dart` thuần Dart trên `List<ScanTextLine>` (text + **vùng chuẩn hoá 0..1**): số tiền theo từ khoá tổng → số lớn nhất cuối hóa đơn (≥ 1000, loại số trong dòng ngày/ĐT/MST); ngày theo 4 định dạng; merchant theo từ khoá hoặc cỡ chữ lớn nhất 30% đầu; danh mục theo **từ điển tĩnh ~50 khoá** khớp tên danh mục seed (chỉ danh mục hoạt động, không tự tạo, không học). Độ tin cậy 3 mức ⇒ nhãn teal/xám/coral.
- **Lưu trữ (R10, R11, R12)** — **Quyết định**: schema v8 (`transactions.source` + `scan_sessions`, không seed); cài đặt quét bằng 4 key `AppSettings`; ghi giao dịch quét bằng method **mới** `addScannedTransaction` (1 transaction DB: giao dịch + ví + phiên quét), `addTransaction` cũ **không đổi**; ảnh copy vào `<documents>/receipts/` **chỉ khi lưu**, dùng lại cột `receipt_image` (PBI 10 hiển thị sẵn).
- **Cảnh báo trùng (R13)** — **Quyết định**: hàm thuần `findRecentDuplicate` lọc trong `allTransactions()` (±24h, cùng số tiền, bỏ transfer/adjustment); cảnh báo nhẹ, không chặn.
- **Điểm vào & Cài đặt (R14, R15)** — **Quyết định**: `AppShell` mở `AddTransactionSheet` 4 hàng (hàng quét ẩn khi tắt công tắc); màn thêm giao dịch **thêm** tham số `initialType` để "Chuyển khoản" từ sheet vào đúng luồng cũ; trạng thái quét giữ ở `ScanController` (GetX, bám `ThemeController`) ⇒ sheet và Cài đặt cùng thấy; khối trạng thái AI nhúng thẳng vào màn Cài đặt (không dựng `scan-05`).
- **Nền tảng (R17)** — **Quyết định**: iOS bump **15.5** (3 chỗ + Podfile), 3 khóa quyền trong `Info.plist`, `CAMERA` trong `AndroidManifest`, `camera` khởi tạo `enableAudio: false`.
- **Test (R19)** — **Quyết định**: đẩy logic sang hàm thuần + seam bơm fake cho mọi thứ chạm plugin; QA tay phủ camera/OCR/quyền/tương phản.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem [data-model.md](./data-model.md) — schema **v8** (1 cột + 1 bảng), 4 key `AppSettings`, 7 thực thể domain, **17 luật bất biến** + bảng vòng đời "khi nào cái gì đổi".
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app thuần nội bộ, không API/CLI/endpoint lộ ra ngoài (đồng nhất PBI 19–23). Hợp đồng nội bộ duy nhất là `WalletRepository` (thêm **1 method**, không đổi method cũ) và các seam plugin mới mô tả dưới đây.
- **Kịch bản khởi động nhanh**: xem [quickstart.md](./quickstart.md) — **14 nhóm kiểm thử tay A–N** (A–L chặng 1, M–N chặng 2), phủ FR-001…FR-041 và SC-001…SC-015.

### Kiến trúc chi tiết

**1. Tầng nghiệp vụ thuần — `lib/core/scan/` (mới, ~6 file, không phụ thuộc plugin)**

| File | Nội dung |
|---|---|
| `scan_result.dart` | `ScanRect` (chuẩn hoá 0..1), `ScanTextLine`, `FieldConfidence`, `ScanField<T>`, `ScanEngine`, `ScanExtraction`, `ScanRecord` |
| `receipt_parser.dart` | `int? parseVietnameseAmount(String)` (hiểu `55.000`/`55,000`/`55 000`/`55000`/`55.000đ`) + `ScanExtraction parseReceipt({lines, now, expenseCategories, incomeCategories})` — bộ luật FR-021…FR-026 |
| `merchant_dictionary.dart` | `String? suggestCategoryName(String merchant)` (bỏ dấu + thường hoá, ~50 khoá) + `Category? resolveCategory(String? name, List<Category> active)` |
| `device_tier.dart` | `DeviceCapability` (+`toJson`/`fromJson` an toàn), `AiTier`, `classifyTier`, `isStale(…, days: 30)` |
| `scan_settings.dart` | `ScanSettings` (+`fromSettings`/`toSettings`, `needsDeviceCheck(now)`) — view của 4 key `AppSettings` |
| `scan_duplicate.dart` | `Transaction? findRecentDuplicate(existing, {amount, date, window: 24h})` |

Không đọc DB, không đọc mạng, không `BuildContext` ⇒ test thuần.

**2. Seam chạm plugin (mỗi seam có impl thật + fake cho test)**

| Seam | Impl thật | Ghi chú |
|---|---|---|
| `ReceiptOcr { Future<List<ScanTextLine>> readText(String path); }` | `MlKitReceiptOcr` (dùng `TextRecognition` bản Latin; chuẩn hoá `boundingBox` pixel → `ScanRect` theo kích thước ảnh) | Mỏng nhất có thể — mọi luật nằm ở `receipt_parser` |
| `DeviceProbe { Future<DeviceCapability> measure(); }` | `PlatformDeviceProbe` (`device_info_plus` + `MethodChannel('sora_thu_chi/device_probe')`) | Kênh native: `freeStorageGb`, `supportsOnDeviceAi`, `supportsGpuDelegate` |
| `ScanImageStore { Future<String> save(Uint8List); Future<void> delete(String); }` | `LocalScanImageStore` (`<appDocuments>/receipts/<millis>.jpg`) | Chỉ gọi trong nhánh lưu (FR-036) |
| `ScanSettingsStore { Future<ScanSettings> load(); Future<void> save(ScanSettings); }` | `DriftScanSettingsStore` (map bảng `AppSettings`, ghi **chỉ 4 key của mình**) | Bám `DriftUtilitiesStore` |
| `ReceiptExtractor { Future<ScanExtraction> extract(...); }` | `RuleBasedExtractor` (chặng 1) · `LlmExtractor` (chặng 2) | Cùng định dạng kết quả; fallback trong cùng seam |
| `CameraGateway` (chỉ trong màn chụp) | bọc `availableCameras`/`CameraController`/`XFile` | Để test widget màn `scan-02` không cần camera thật |

**3. Trạng thái — `lib/core/scan/scan_controller.dart` + `lib/core/scan/image_preprocess.dart`**

```dart
class ScanController extends GetxController {          // bám ThemeController (R15)
  ScanController(this._store, this._probe);
  final ScanSettingsStore _store;  final DeviceProbe _probe;
  final Rx<ScanSettings> settings = const ScanSettings().obs;
  Future<void> load();
  void setEnabled(bool v);                              // write-through, nối đuôi save
  void setMode(ScanEngine m);
  Future<DeviceCapability> checkDevice();               // đo → classifyTier → lưu
}
```

`image_preprocess.dart`: `Future<Uint8List> preprocessForOcr(Uint8List input, {int maxSide = 2000})` — `bakeOrientation` → resize → `adjustColor(contrast: 1.15, saturation: 0)` → `encodeJpg(quality: 88)`; gọi qua `compute()` từ màn xử lý. **`ponytail:`** comment: không dò biên/crop.

**4. Điều phối luồng — `lib/core/scan/scan_flow.dart`**

`Future<bool> startScanFlow(BuildContext context)` (trả `true` nếu đã lưu giao dịch):

1. Đọc `ScanController.settings`; nếu `enabled == false` → thoát (không xảy ra vì sheet đã ẩn hàng).
2. `needsDeviceCheck(now)` → đẩy `DeviceCheckScreen`; kết quả chọn của người dùng được lưu vào `settings` (mode), hoặc chọn dùng tiếp Chế độ cơ bản.
3. Đẩy `ScanCameraScreen` → trả đường dẫn ảnh (chụp hoặc thư viện) — **xin quyền ở bước này** (FR-013).
4. Đẩy `ScanProcessingScreen(imagePath)` → chạy pipeline (tiền xử lý → OCR → `RuleBasedExtractor`); trả `ScanExtraction?` (`null` = không đọc được → màn xử lý tự hiện thông báo + 2 nút, không tạo gì).
5. Đẩy `ScanConfirmScreen(extraction, imagePath)`, chờ `bool?` (đã lưu). Trả tiếp cờ đó lên `AppShell` ⇒ shell gọi `ensureTransactionController().load()` + `ensureReportController().load()` (đường làm mới sẵn có).

**5. Màn hình — `lib/screens/scan/` (mới, 5 file + 1 widget)**

| File | Mockup | Nội dung chính |
|---|---|---|
| `add_transaction_sheet.dart` | `scan-01` | `showModalBottomSheet` + `AddTransactionSheet`: 4 hàng (icon vòng tròn teal nhạt, tiêu đề, dòng mô tả, nhãn "MỚI"); hàng quét chỉ hiện khi `enabled`. `ValueKey('add-sheet-scan')`… |
| `scan_camera_screen.dart` | `scan-02` | Nền **tối cố định**; `CameraPreview` + overlay **khung ngắm nét đứt 4 góc** (`CustomPainter`), nút back, nút flash (`setFlashMode`), nút **Thư viện** (`image_picker`), nút **chụp tròn**; dòng gợi ý. **Không** nút "Quét nhiều" |
| `scan_processing_screen.dart` | `scan-03` | Ảnh thu nhỏ + **vệt quét** (animation), tiêu đề, **4 bước** với trạng thái xong/đang chạy/chưa tới, dòng cam kết không gửi dữ liệu; chạy pipeline trong `initState`; nhánh không đọc được → thông báo + **Chụp lại**/**Nhập tay** |
| `scan_confirm_screen.dart` | `scan-04` | `SubPageScaffold` (app bar teal, không bottom nav): ảnh thu nhỏ + **"Xem ảnh gốc"**, 6 trường (Loại giao dịch segmented, Số tiền + bàn phím số, Ngày giờ, Cửa hàng/Ghi chú, Danh mục, Ví), chỉ báo độ tin cậy, banner cảnh báo trùng, dòng "Nguồn: Quét hóa đơn (AI)…", nút **"Lưu giao dịch"** cố định chân màn |
| `device_check_screen.dart` | `scan-10` | Danh sách 4 mục đo (giá trị + Đạt/Không đạt) + **3 thẻ kết quả** (Tier A / Tier B / Tier C) đúng nội dung mockup; nút "Kiểm tra lại" chạy lại đo |
| `widgets/receipt_viewer.dart` | `scan-04` | Ảnh gốc (`InteractiveViewer`) + lớp phủ **khoanh vùng** theo `ScanRect` đang chọn (chạm trường nào → khoanh vùng đó; không xác định → không khoanh) |

**6. Điểm vào — `lib/core/app_shell.dart` (sửa ~25 dòng)**

`_openAddTransaction` → `_openAddSheet`: mở `AddTransactionSheet`, nhận `AddSheetChoice?` rồi:
- `income`/`expense` → `AddTransactionScreen(initialType: …)` (đường cũ, giữ nguyên logic làm mới khi `saved == true`);
- `transfer` → `AddTransactionScreen(initialType: TxnType.transfer)` — màn thêm tự mở luồng chuyển khoản sau khi nạp ví (R14);
- `scan` → `startScanFlow(context)`.
Sheet trả `bool?` "đã lưu" ⇒ giữ nguyên khối làm mới `ensureTransactionController().load()` (+ tab Báo cáo) hiện có. **Không** đụng `AppBottomNavBar`/`AddTransactionFab`.

**7. Màn thêm giao dịch — `lib/screens/add_transaction_screen.dart` (sửa nhỏ)**

Thêm tham số `TxnType initialType = TxnType.expense`; khi `initialType == transfer`, sau khi nạp ví xong tự gọi `_openTransferFlow()` một lần (cờ `_autoTransferOpened`). Không đổi gì khác (bộ test PBI 7/11 giữ nguyên).

**8. Cài đặt — `lib/screens/settings_screen.dart` (sửa ~60 dòng)**

Thêm nhóm **"QUÉT HÓA ĐƠN AI"** (giữa "TÀI KHOẢN" và "KHÁC", hoặc cuối nhóm KHÁC — bám mockup `scan-11`): hàng công tắc (`ValueKey('scan-enabled-switch')`) + khối trạng thái (dòng "Trạng thái AI": Tier + model/Chế độ cơ bản; "Dung lượng model" khi đã tải — chặng 2; "Lần kiểm tra gần nhất") + hàng **"Kiểm tra lại cấu hình máy"** → đẩy `DeviceCheckScreen`. Màn đọc `ScanController` qua `Obx` (đổi công tắc ở đây phản ánh ngay vào sheet FAB).

**9. Lưu trữ — `lib/data/`**

- `db/app_database.dart`: bảng `ScanSessions` + cột `transactions.source` + `schemaVersion = 8` + nhánh migration `if (from < 8)` (R10); chạy `dart run build_runner build` sinh lại `.g.dart`.
- `wallet_repository.dart` / `wallet_repository_drift.dart`: thêm `addScannedTransaction(...)` (1 `db.transaction()`: bù `balance` + insert `transactions` (`source = aiScan`, `receipt_image`, danh mục có thể null) + insert `scan_sessions`). Phần còn lại của seam **không đổi**.
- `scan_settings_store.dart` + `scan_settings_store_drift.dart` + `scan_deps.dart` (`ensureScanSettingsStore()`, `ensureScanController()`, `ensureReceiptOcr()`, `ensureScanImageStore()`).

**10. Nền tảng**

- `android/app/src/main/AndroidManifest.xml`: `<uses-permission android:name="android.permission.CAMERA"/>` + `<uses-feature android:name="android.hardware.camera" android:required="false"/>`.
- `ios/Runner/Info.plist`: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSMicrophoneUsageDescription`.
- iOS target: `ios/Podfile` → `platform :ios, '15.5'`; 3 chỗ `IPHONEOS_DEPLOYMENT_TARGET` trong `project.pbxproj` → `15.5`.
- `pubspec.yaml`: +5 package ở chặng 1 (`google_mlkit_text_recognition`, `camera`, `image_picker`, `image`, `device_info_plus`); chặng 2 thêm package LLM.
- Kênh native mới: `android/app/src/main/kotlin/…/DeviceProbeChannel.kt` + `ios/Runner/DeviceProbeChannel.swift`, đăng ký trong `MainActivity`/`AppDelegate`.

**11. i18n — `lib/core/locale/sora_translations.dart` (sửa, ~55 khóa mới)**

Nhóm mới "Quét hóa đơn (PBI 24)": nhãn sheet (4 hàng + "MỚI" + mô tả), màn chụp (tiêu đề, gợi ý, Thư viện, flash, các trạng thái lỗi quyền), màn xử lý (tiêu đề + 4 bước + 2 dòng cam kết), màn xác nhận (tiêu đề, 6 nhãn trường, "Xem ảnh gốc", 3 nhãn độ tin cậy + "Kiểm tra lại", dòng nguồn, "Lưu giao dịch", cảnh báo trùng, các thông báo lỗi lưu), màn kiểm tra cấu hình (tiêu đề, 4 mục đo, 3 thẻ kết quả + nội dung từng tier, các nút), mục Cài đặt (tên nhóm, công tắc, 4 nhãn trạng thái, 2 nút). Dùng lại: `'Hủy'`, `'Thoát'`, `'Chọn ví'`, `'Danh mục'`, `'Ví'`, `'Ngày giờ'`, `'Ghi chú'`, `'Chi'`, `'Thu'`, `'Chuyển khoản'`, `'Độ tin cậy…'` (thêm mới nếu chưa có).

**12. Test (chặng 1)**

| File | Nội dung |
|---|---|
| `test/receipt_parser_test.dart` **(mới)** | `parseVietnameseAmount`: 6 định dạng số + loại `12.5`/`2026`/số < 1000 không nhóm. `parseReceipt` trên fixture văn bản: hóa đơn Circle K (số tiền = dòng TỔNG CỘNG chứ không phải dòng mặt hàng), nhiều con số, không có dòng tổng → số lớn nhất cuối ảnh, không có số tiền → rỗng + `low`, ngày 3 định dạng + có/không giờ, ngày sai (31/02) → bỏ qua, merchant theo từ khoá vs theo cỡ chữ, danh mục khớp từ điển vs không khớp, dòng chỉ có số điện thoại/MST không bị lấy làm tiền. Mọi ca kiểm cả `confidence` và `rect` |
| `test/merchant_dictionary_test.dart` **(mới)** | Khớp có/không dấu (`Circle K`/`CIRCLE K`/`circle k`), khớp chuỗi con, không khớp → `null`, `resolveCategory` bỏ danh mục ẩn, tên không có trong danh sách hoạt động → `null`, mọi tên đích phải tồn tại trong `CategorySource` |
| `test/device_tier_test.dart` **(mới)** | Biên `ram 3.9/4.0`, `free 1.9/2.0/2.5`, có/không AICore, có/không GPU delegate ⇒ A/B/C; `isStale` đúng 30 ngày (29/30/31); `toJson/fromJson` round-trip + JSON hỏng → `null` |
| `test/scan_settings_test.dart` **(mới)** | `fromSettings` mặc định khi thiếu key/chuỗi lạ; `toSettings` đủ 4 key; `needsDeviceCheck` khi null và khi quá 30 ngày |
| `test/scan_duplicate_test.dart` **(mới)** | Cùng số tiền trong 24h → cảnh báo; lệch 1 đồng → không; lệch 24h01 → không; bỏ qua transfer/adjustment; danh sách rỗng → `null` |
| `test/image_preprocess_test.dart` **(mới)** | Ảnh nhỏ giữ nguyên kích thước; ảnh lớn bị thu về `maxSide`; ảnh JPEG/PNG đều ra JPEG đọc lại được (thuần Dart, không plugin) |
| `test/scan_dao_test.dart` **(mới)** | `addScannedTransaction`: tạo đúng 1 giao dịch (`source = aiScan`, `receipt_image`, ghi chú, danh mục null được) + 1 dòng `scan_sessions` (`transaction_id` khớp, `engine` đúng) + `balance` ví bù đúng dấu theo loại; giao dịch quét với danh mục `null`; migration **v7→v8**: `source` của dòng cũ = `manual`, bảng `scan_sessions` rỗng (bám `transactions_dao_test`) |
| `test/scan_settings_store_drift_test.dart` **(mới)** | Load/save 4 key, không xoá key khác trong `AppSettings` (bám `utilities_store_drift_test`) |
| `test/add_transaction_sheet_test.dart` **(mới)** | Đủ 4 hàng + nhãn "MỚI" khi bật; thiếu hàng quét khi tắt; chạm từng hàng trả đúng `AddSheetChoice`; nhãn EN khi locale `en` |
| `test/scan_camera_screen_test.dart` **(mới)** | Với `CameraGateway` fake: có khung ngắm (`CustomPaint`), nút flash/thư viện/chụp, dòng gợi ý, **không** có nút "Quét nhiều", nền tối bất kể theme; chọn thư viện → trả đường dẫn ảnh |
| `test/scan_processing_screen_test.dart` **(mới)** | 4 bước hiện đủ + bước đang chạy khác bước khác; OCR fake trả văn bản → đẩy sang xác nhận; OCR fake trả rỗng → thông báo + 2 nút, "Nhập tay" mở form trống, **không** gọi seam ghi |
| `test/scan_confirm_screen_test.dart` **(mới)** | Vẽ đủ 6 trường + ảnh + dòng nguồn + nút lưu; số tiền rỗng → nút lưu **vô hiệu**, nhập số → bật; nhãn tin cậy coral cho trường `low`/rỗng, teal/xám cho cao/trung bình; chạm trường → lớp khoanh vùng nhận đúng `ScanRect` (qua `ReceiptViewer`); cảnh báo trùng hiện/không hiện; bấm lưu 2 lần → repo nhận **1** lần gọi; sửa danh mục/ví/ngày rồi lưu → tham số truyền xuống repo đúng; lưu lỗi → thông báo lỗi tiếng Việt, không pop; English → không nhãn Việt |
| `test/device_check_screen_test.dart` **(mới)** | `DeviceProbe` fake (3 ca A/B/C) → đúng thẻ kết quả + đúng tiêu chí chưa đạt; danh sách 4 mục có giá trị + Đạt/Không đạt; bấm "Kiểm tra lại" gọi lại probe; nút Tier A/B vô hiệu + chú thích (trạng thái trung gian chặng 1) |
| `test/settings_screen_test.dart` **(sửa)** | Thêm ca: hàng công tắc hiện + đổi được (fake store), khối trạng thái hiện tier/mốc kiểm tra, hàng "Kiểm tra lại cấu hình máy" đẩy màn `scan-10` |
| `test/fakes/fake_wallet_repository.dart` **(sửa)** | Cài `addScannedTransaction` (ghi vào list in-memory + ghi lại tham số để assert) — mọi test cũ không đổi hành vi |
| `test/fakes/fake_scan_*.dart` **(mới)** | Fake OCR / DeviceProbe / ScanImageStore / ScanSettingsStore / CameraGateway |
| `test/dark_theme_smoke_test.dart` **(sửa)** | Thêm smoke: pump màn xác nhận + màn kiểm tra cấu hình ở theme tối → không overflow, token tối thật sự áp |
| `test/sora_translations_test.dart` | **Không sửa** — tự quét literal `.tr` trong `lib/`, thiếu khóa là đỏ (lưới an toàn cho ~55 khóa mới) |

Ghi chú test: test đụng `.tr` phải khôi phục `Get.locale` trong `addTearDown` (bài học PBI 19); mọi thời điểm dùng `now` **bơm tham số** (không dùng giờ thật); `Get.reset()` trong `tearDown` sau khi `Get.put(ScanController(...))` (bài học PBI 22/23).

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline, không server | ✅ | OCR bundled sẵn trong APK; tiền xử lý + bộ luật thuần Dart; 0 request mạng ở chặng 1 |
| Không sửa dữ liệu người dùng ngoài phạm vi | ✅ | Chỉ thêm cột `source` (default `manual`) + bảng `scan_sessions` (không seed); không đụng bảng khác; không xoá/sửa dữ liệu cũ |
| Số dư ví suy ra; transfer không tính thu/chi | ✅ | `addScannedTransaction` bù `balance` theo loại; giao dịch quét chỉ thu/chi |
| Design system + dark mode + i18n | ✅ | Màu qua token; coral chỉ cho cảnh báo; màn chụp nền tối cố định (đúng mockup + FR-040); ~55 khóa dịch, có lưới test tự động |
| Màn cấp tab có bottom nav, màn con không | ✅ | Cả 5 màn mới là route đè shell/modal; `AppShell` chỉ đổi nguồn mở form |
| Bảo mật & quyền riêng tư | ✅ | Xin quyền đúng lúc (FR-013); ảnh/xử lý chỉ trên máy; luồng quét sau khoá PIN; ảnh lưu trong documents riêng của app |
| YAGNI / không abstraction sớm | ✅ | Seam chỉ ở chỗ có plugin/IO; không bảng ánh xạ, không học theo người dùng, không Scan History, không crop tay, không xử lý nền |
| Không phá vỡ test/hành vi cũ | ⚠️ có kiểm soát | FAB **cố ý** đổi hành vi (spec chốt): test cũ nào phụ thuộc FAB→form phải cập nhật; `addTransaction`/`WalletRepository` cũ và màn thêm giao dịch giữ nguyên hành vi (chỉ thêm tham số mặc định) |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── app.dart                                   # SỬA: đăng ký + load ScanController
│   ├── core/
│   │   ├── app_shell.dart                         # SỬA: FAB → AddTransactionSheet (scan-01)
│   │   ├── locale/sora_translations.dart          # SỬA: +~55 khóa EN (PBI 24)
│   │   ├── scan/
│   │   │   ├── scan_result.dart                   # MỚI — ScanRect/ScanTextLine/ScanField/ScanExtraction/ScanEngine/ScanRecord
│   │   │   ├── receipt_parser.dart                # MỚI — parseVietnameseAmount + parseReceipt (FR-021…026)
│   │   │   ├── merchant_dictionary.dart           # MỚI — từ điển cửa hàng → danh mục (FR-024)
│   │   │   ├── device_tier.dart                   # MỚI — DeviceCapability/AiTier/classifyTier/isStale
│   │   │   ├── scan_settings.dart                 # MỚI — ScanSettings ⇄ 4 key AppSettings
│   │   │   ├── scan_duplicate.dart                # MỚI — findRecentDuplicate (FR-035)
│   │   │   ├── image_preprocess.dart              # MỚI — bakeOrientation + resize + contrast (isolate)
│   │   │   ├── receipt_ocr.dart                   # MỚI — seam OCR + MlKitReceiptOcr
│   │   │   ├── device_probe.dart                  # MỚI — seam đo cấu hình máy
│   │   │   ├── scan_image_store.dart              # MỚI — seam lưu ảnh hóa đơn
│   │   │   ├── scan_controller.dart               # MỚI — GetX Rx (công tắc + chế độ + hồ sơ thiết bị)
│   │   │   └── scan_flow.dart                     # MỚI — điều phối: kiểm tra cấu hình → chụp → xử lý → xác nhận
│   │   ├── transaction/transaction.dart           # SỬA: +enum TxnSource + field source
│   │   └── wallet/…                               # (không đổi)
│   ├── data/
│   │   ├── db/app_database.dart                   # SỬA: schema v8 (cột source + bảng scan_sessions) + .g.dart sinh lại
│   │   ├── wallet_repository.dart                 # SỬA: +addScannedTransaction
│   │   ├── wallet_repository_drift.dart           # SỬA: impl + map source
│   │   ├── scan_settings_store.dart               # MỚI — interface (bám UtilitiesStore)
│   │   ├── scan_settings_store_drift.dart         # MỚI — map bảng AppSettings
│   │   ├── scan_deps.dart                          # MỚI — ensureScanSettingsStore/Controller/Ocr/ImageStore
│   │   └── platform/device_probe_platform.dart    # MỚI — device_info_plus + MethodChannel
│   └── screens/
│       ├── add_transaction_screen.dart            # SỬA: +initialType (auto-mở luồng chuyển khoản)
│       ├── settings_screen.dart                   # SỬA: nhóm "QUÉT HÓA ĐƠN AI" (công tắc + trạng thái)
│       └── scan/
│           ├── add_transaction_sheet.dart         # MỚI — mockup scan-01
│           ├── scan_camera_screen.dart            # MỚI — mockup scan-02
│           ├── scan_processing_screen.dart        # MỚI — mockup scan-03
│           ├── scan_confirm_screen.dart           # MỚI — mockup scan-04
│           ├── device_check_screen.dart           # MỚI — mockup scan-10
│           └── widgets/receipt_viewer.dart        # MỚI — ảnh gốc + lớp khoanh vùng
├── android/app/src/main/AndroidManifest.xml       # SỬA: CAMERA + uses-feature
├── android/app/src/main/kotlin/…/DeviceProbeChannel.kt   # MỚI — freeStorageGb/AICore/gpuDelegate
├── ios/Runner/Info.plist                          # SỬA: 3 khóa quyền
├── ios/Runner/DeviceProbeChannel.swift            # MỚI — dung lượng trống (+ AICore = false)
├── ios/Podfile + ios/Runner.xcodeproj/project.pbxproj   # SỬA: iOS 15.5
├── pubspec.yaml                                   # SỬA: +5 dependency (chặng 1)
└── test/
    ├── receipt_parser_test.dart                   # MỚI
    ├── merchant_dictionary_test.dart              # MỚI
    ├── device_tier_test.dart                      # MỚI
    ├── scan_settings_test.dart                    # MỚI
    ├── scan_duplicate_test.dart                   # MỚI
    ├── image_preprocess_test.dart                 # MỚI
    ├── scan_dao_test.dart                         # MỚI (bám transactions_dao_test)
    ├── scan_settings_store_drift_test.dart        # MỚI
    ├── add_transaction_sheet_test.dart            # MỚI
    ├── scan_camera_screen_test.dart               # MỚI
    ├── scan_processing_screen_test.dart           # MỚI
    ├── scan_confirm_screen_test.dart              # MỚI
    ├── device_check_screen_test.dart              # MỚI
    ├── settings_screen_test.dart                  # SỬA
    ├── dark_theme_smoke_test.dart                 # SỬA
    └── fakes/{fake_wallet_repository.dart (SỬA), fake_scan_*.dart (MỚI)}

Chặng 2 (chỉ liệt kê, thi công ở lượt sau):
  lib/core/scan/llm_extractor.dart                 # MỚI — LlmExtractor + timeout/fallback (FR-011)
  lib/core/scan/model_manager.dart                 # MỚI — tải/xoá/kiểm tra model Tier B
  android/…/GenAiChannel.kt                        # MỚI — ML Kit GenAI Prompt API (Tier A)
  lib/screens/scan/model_download_*.dart           # MỚI — UI tải model + trạng thái trong Cài đặt
```

Không tạo `contracts/`: dự án thuần nội bộ, không có giao diện lộ ra ngoài.

## Rủi ro & ngoại lệ có lý do

1. **iOS 15.5 là hệ quả bắt buộc của ML Kit** (R2/R17): máy iOS cũ (< 15.5) không cài được bản này. **Giảm nhẹ**: ghi rõ trong plan; nếu cần hỗ trợ iOS 13 phải đổi OCR sang bản unbundled (mất tính offline) — **không** đánh đổi trong PBI này.
2. **APK tăng ~4–6MB** do model OCR Latin bundled trong APK. **Giảm nhẹ**: đúng doc §8; đổi sang unbundled sẽ vi phạm nguyên tắc offline. Ghi nhận, đo lại kích thước APK khi thi công.
3. **Độ chính xác OCR với tiếng Việt có dấu** ở mức tương đối (doc §2.1): số/ngày tốt, tên cửa hàng có thể sai dấu. **Giảm nhẹ**: merchant chỉ là gợi ý và luôn sửa được; SC-003 chỉ ràng buộc **số tiền + ngày giờ ≥ 90%**; QA nhóm F/G dùng ảnh thật.
4. **Ngưỡng tier là ước lệ** (doc §11.2): máy RAM 4GB có thể chạy model rất chậm. **Giảm nhẹ**: spec đã ghi rõ "kết quả chỉ dùng để chọn chế độ, không cam kết chất lượng"; fallback AI→bộ luật (FR-011) là lưới an toàn.
5. **Chặng 2 gần như không QA được trên emulator** (emulator luôn Tier C, không AICore): rủi ro code chết. **Giảm nhẹ**: tách sang lượt thi công riêng, giữ seam `ReceiptExtractor` để phần bộ luật vẫn là đường chạy thật; QA chặng 2 cần thiết bị thật (quickstart nhóm M/N).
6. **Camera thật không test tự động được**: bug chỉ hiện trên máy thật (tỉ lệ khung ngắm, xoay ảnh, flash). **Giảm nhẹ**: `CameraGateway` seam cho test widget; QA tay nhóm C/D trên emulator (camera ảo + thư viện ảnh) và trên máy thật khi có.
7. **Cảnh báo trùng dương tính giả** (2 hóa đơn cùng số tiền trong ngày, VD 2 ly cà phê 25.000). **Giảm nhẹ**: chỉ là banner nhẹ, **không** chặn lưu (FR-035); QA nhóm I mục 6.
8. **Số tiền bị lấy sai** ở hóa đơn có nhiều con số (số điện thoại, MST, số hóa đơn, mã đơn). **Giảm nhẹ**: luật loại số trong dòng ngày/ĐT/MST + chỉ nhận ≥ 1000 + ưu tiên dòng từ khoá tổng; nếu vẫn nghi ngờ → độ tin cậy trung bình ⇒ người dùng kiểm tra. Bộ test parser có fixture riêng cho ca này.
9. **Số dư / số liệu không làm mới**: nếu `AppShell` không nhận cờ `true` từ luồng quét thì danh sách + Tổng quan + Báo cáo đứng yên. **Giảm nhẹ**: `startScanFlow` trả `bool` xuyên suốt và tái dùng đúng khối làm mới sẵn có của `_openAddTransaction`; QA nhóm I mục 1/3 (SC-015).
10. **`build_runner` sinh lại `.g.dart`**: nếu quên chạy sau khi sửa schema, app build lỗi hoặc thiếu cột. **Giảm nhẹ**: nêu thành bước bắt buộc trong `tasks.md`; test `scan_dao_test` (migration v7→v8) là lưới phát hiện.
11. **Kênh native mới phải khớp 2 nền tảng**: iOS trả `supportsOnDeviceAi = false` (không có AICore) nhưng vẫn phải trả `freeStorageGb` — nếu Swift không đăng ký kênh, màn `scan-10` treo ở "Đang kiểm tra...". **Giảm nhẹ**: `DeviceProbe` bọc `try/catch` với **giá trị mặc định an toàn** (dung lượng = 0 ⇒ Tier C, luồng vẫn chạy); QA nhóm B trên cả 2 nền tảng nếu có thiết bị.
12. **Ảnh hóa đơn không được mã hoá** — doc §6 nói "cùng cơ chế mã hóa đã áp dụng cho file đính kèm khác", nhưng repo **chưa có** cơ chế đó (cột `receipt_image` đang là đường dẫn thô từ PBI 10). **Giảm nhẹ**: giữ đúng hiện trạng, không tự phát minh cơ chế mã hoá trong PBI này; ghi nhận để PBI bảo mật file đính kèm xử lý chung cho **mọi** ảnh, không riêng ảnh quét.
13. **Trạng thái trung gian giữa 2 chặng** (nút Tier A/B vô hiệu + chú thích): không phải hành vi phát hành. **Giảm nhẹ**: ghi rõ ở research R1 + plan; chặng 2 gỡ; test chỉ khẳng định trạng thái trung gian ở mức "có nhãn chú thích", không khẳng định là hành vi cuối.
14. **Màn xác nhận nhiều trường + bàn phím số trên màn nhỏ**: nút "Lưu giao dịch" có thể bị bàn phím che. **Giảm nhẹ**: nút lưu đặt ở `bottomNavigationBar` + `SafeArea` (bám nếp màn thêm giao dịch); thân màn `ListView` cuộn được; QA nhóm L mục 3/4.

## Việc bàn giao kèm (ngoài code)

- Tick `checklists/requirements.md` sau khi thi công xong (giữ nguyên nội dung đã duyệt).
- Đồng bộ wiki (`wiki-knowledge/`) theo skill `sora-wiki` sau khi **chặng 1** xong: cập nhật page **entity/Giao dịch** (nguồn `AI Scan` + ảnh hóa đơn + bảng phiên quét), page **entity/Hồ sơ & Bảo mật** (công tắc quét hóa đơn AI + trạng thái AI/tier + kiểm tra cấu hình máy), **concept/Lộ trình phát triển** (đánh dấu phần MVP AI Scan đã làm; còn Tier A/B ở chặng 2, các nguồn doc §10 + quét hàng loạt + Scan History + học danh mục là PBI sau), **concept/Design system** (màn chụp nền tối cố định; chỉ báo độ tin cậy teal/xám/coral) + **concept/Stack** (5 package mới, iOS 15.5) + append `wiki-knowledge/log.md` và cập nhật `index.md`. Sau khi **chặng 2** xong: bổ sung mục Tier A/B + trạng thái model.
