# Danh sách Task: Thêm giao dịch bằng quét hóa đơn (AI)

**Mã PBI**: 24
**Nguồn**: spec.md, plan.md, data-model.md, research.md (R1…R19), quickstart.md
**Phân kỳ**: **Chặng 1** = Pha 1 → Pha 5 (luồng quét trọn vẹn ở Chế độ cơ bản + kiểm tra cấu hình + Cài đặt, QA được 100% trên emulator). **Chặng 2** = Pha 6 (Tier A/B thật) — thi công ở lượt riêng theo R1.

## Định dạng task

`- [ ] [MãTask] [P?] [Story?] Mô tả kèm đường dẫn file`
Đường dẫn tính từ gốc repo (`app/sora_thu_chi/…`), đúng như plan.md §Cấu trúc dự án dự kiến.

---

## Pha 1: Setup

- [X] T001 [P] Thêm 5 dependency chặng 1 vào `app/sora_thu_chi/pubspec.yaml` (`google_mlkit_text_recognition`, `camera`, `image_picker`, `image`, `device_info_plus`) rồi chạy `flutter pub get`
- [X] T002 [P] Khai báo quyền camera trong `app/sora_thu_chi/android/app/src/main/AndroidManifest.xml` (`android.permission.CAMERA` + `<uses-feature android:name="android.hardware.camera" android:required="false"/>`)
- [X] T003 [P] Cấu hình nền tảng iOS chặng 1: 3 khóa quyền (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSMicrophoneUsageDescription`) trong `app/sora_thu_chi/ios/Runner/Info.plist`; bump `platform :ios, '15.5'` trong `app/sora_thu_chi/ios/Podfile` và 3 chỗ `IPHONEOS_DEPLOYMENT_TARGET` trong `app/sora_thu_chi/ios/Runner.xcodeproj/project.pbxproj` (R17 — bắt buộc cho ML Kit)
- [X] T004 [P] Tạo kênh native `sora_thu_chi/device_probe` trên Android: `app/sora_thu_chi/android/app/src/main/kotlin/…/DeviceProbeChannel.kt` trả `freeStorageGb`, `supportsOnDeviceAi`, `supportsGpuDelegate`; đăng ký trong `MainActivity.kt` (chặng 2 cắm tiếp GenAI vào chính kênh này)
- [X] T005 [P] Tạo kênh native `sora_thu_chi/device_probe` trên iOS: `app/sora_thu_chi/ios/Runner/DeviceProbeChannel.swift` trả `freeStorageGb` + `supportsOnDeviceAi = false` + `supportsGpuDelegate = false`; đăng ký trong `AppDelegate.swift` (R17 — thiếu đăng ký ⇒ màn `scan-10` treo ở "Đang kiểm tra…")

## Pha 2: Foundational

*(Bắt buộc xong trước mọi user story)*

- [X] T006 [P] Thêm `enum TxnSource { manual, aiScan }` + field `final TxnSource source` (mặc định `manual`) vào `app/sora_thu_chi/lib/core/transaction/transaction.dart` (data-model §1.1)
- [X] T007 Thêm cột `source` (`textEnum<TxnSource>()`, default `manual`) vào bảng `transactions` và bảng mới `ScanSessions` (`id`, `imagePath`, `rawText`, `parsedJson`, `engine` `textEnum<ScanEngine>()`, `transactionId` nullable, `createdAt`) trong `app/sora_thu_chi/lib/data/db/app_database.dart`; nâng `schemaVersion = 8` + nhánh migration `if (from < 8)` (`addColumn` + `createTable`, **không** seed) (data-model §1.2–1.3)
- [X] T008 Chạy `dart run build_runner build --delete-conflicting-outputs` trong `app/sora_thu_chi/` để sinh lại `lib/data/db/app_database.g.dart` (bắt buộc sau T007 — quên là build lỗi/thiếu cột)
- [X] T009 [P] Tạo `app/sora_thu_chi/lib/core/scan/scan_result.dart`: `ScanRect` (chuẩn hoá 0..1), `ScanTextLine`, `FieldConfidence`, `ScanField<T>`, `ScanEngine`, `ScanExtraction`, `ScanRecord` (data-model §2.1–2.4)
- [X] T010 [P] Tạo `app/sora_thu_chi/lib/core/scan/scan_settings.dart` (`ScanSettings` + `fromSettings`/`toSettings`/`needsDeviceCheck(now)`, chuỗi lạ/thiếu key → mặc định an toàn, không ném) và `app/sora_thu_chi/test/scan_settings_test.dart`
- [X] T011 [P] Tạo `app/sora_thu_chi/lib/core/scan/device_tier.dart` (`DeviceCapability` + `toJson`/`fromJson` an toàn, `AiTier`, `classifyTier` — biên đóng 4.0GB/2.0GB, `isStale(…, days: 30)`) và `app/sora_thu_chi/test/device_tier_test.dart` (biên 3.9/4.0, 1.9/2.0/2.5, 29/30/31 ngày, JSON hỏng → `null`)
- [X] T012 [P] Khai báo 4 seam trong `app/sora_thu_chi/lib/core/scan/`: `receipt_ocr.dart` (`ReceiptOcr.readText`), `device_probe.dart` (`DeviceProbe.measure`), `scan_image_store.dart` (`ScanImageStore.save/delete`), `scan_settings_store.dart` (`ScanSettingsStore.load/save`) — chỉ interface, không impl
- [X] T013 Tạo `app/sora_thu_chi/lib/data/scan_settings_store_drift.dart` (map 4 key `scanEnabled`/`scanEngineMode`/`scanModelBytes`/`scanDeviceCheck`, ghi **chỉ 4 key của mình**, không xoá key khác) + `app/sora_thu_chi/test/scan_settings_store_drift_test.dart` (bám `utilities_store_drift_test`)
- [X] T014 Tạo `app/sora_thu_chi/lib/data/scan_deps.dart`: `ensureScanSettingsStore()`, `ensureScanController()`, `ensureReceiptOcr()`, `ensureScanImageStore()` (bám nếp `theme_deps.dart`/`utilities_deps.dart`)
- [X] T015 Tạo `app/sora_thu_chi/lib/core/scan/scan_controller.dart`: `ScanController extends GetxController` giữ `Rx<ScanSettings>`, `load()`, `setEnabled(bool)` (write-through nối đuôi `save`), `setMode(ScanEngine)`, `checkDevice()` (đo → `classifyTier` → lưu) (R15)
- [X] T016 Đăng ký + nạp `ScanController` trong `app/sora_thu_chi/lib/app.dart` (bám chỗ đăng ký `ThemeController`)
- [X] T017 [P] Thêm nhóm khóa dịch "Quét hóa đơn (PBI 24)" (~55 khóa: bottom sheet, màn chụp, màn xử lý, màn xác nhận, màn kiểm tra cấu hình, mục Cài đặt) vào `app/sora_thu_chi/lib/core/locale/sora_translations.dart` — `test/sora_translations_test.dart` tự quét `.tr` nên thiếu khóa là đỏ
- [X] T018 [P] Tạo fake cho mọi seam plugin: `app/sora_thu_chi/test/fakes/fake_scan_ocr.dart`, `fake_device_probe.dart`, `fake_scan_image_store.dart`, `fake_scan_settings_store.dart`, `fake_camera_gateway.dart`; và cài `addScannedTransaction` (ghi list in-memory + ghi lại tham số để assert) vào `app/sora_thu_chi/test/fakes/fake_wallet_repository.dart` (mọi test cũ giữ nguyên hành vi)
- [X] T019 Thêm `addScannedTransaction(...)` vào `app/sora_thu_chi/lib/data/wallet_repository.dart` (interface) và impl trong `app/sora_thu_chi/lib/data/wallet_repository_drift.dart`: **một** `db.transaction()` gồm bù `balance` ví theo loại + insert `transactions` (`source = aiScan`, `receipt_image`, `category_id` có thể null, `note` = merchant) + insert `scan_sessions` (`transaction_id` vừa sinh, `engine` đã dùng) (R11, data-model §4.4–4.5)
- [X] T020 Viết `app/sora_thu_chi/test/scan_dao_test.dart` (bám `transactions_dao_test`): tạo đúng 1 giao dịch + 1 dòng `scan_sessions` khớp `transaction_id`, `balance` bù đúng dấu theo loại, danh mục `null` được, và **migration v7→v8** (`source` dòng cũ = `manual`, bảng `scan_sessions` rỗng)
- [X] T021 Sửa `app/sora_thu_chi/lib/core/app_shell.dart` (~25 dòng): `_openAddTransaction` → `_openAddSheet` mở `AddTransactionSheet`, nhận `AddSheetChoice?` rồi dispatch; giữ nguyên khối làm mới `ensureTransactionController().load()` + `ensureReportController().load()`; **không** đụng `AppBottomNavBar`/`AddTransactionFab` (file sheet tạo ở T031 — đặt trước để chốt điểm vào)

## Pha 3: User Story 1 — Bật tính năng & quét trọn luồng ở Chế độ cơ bản (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: FAB → bottom sheet "Thêm giao dịch" (`scan-01`) → màn chụp (`scan-02`) → màn xử lý (`scan-03`, OCR + bộ luật) → màn xác nhận (`scan-04`) → lưu 1 giao dịch nguồn "AI Scan" có ảnh đính kèm; danh sách + Tổng quan + Báo cáo làm mới ngay. Không tự lưu khi chưa xác nhận.
**Tiêu chí kiểm thử độc lập**: bật công tắc trong Cài đặt → quét một ảnh hóa đơn có sẵn từ thư viện → sửa/giữ nguyên các trường → Lưu → giao dịch xuất hiện ngay ở màn Giao dịch với nguồn AI Scan + ảnh mở xem được; thoát giữa luồng ⇒ không có gì được ghi. Phủ FR-001, FR-002, FR-003 (công tắc), FR-009, FR-013…FR-036, FR-038; SC-001, SC-002, SC-004, SC-005, SC-007, SC-011, SC-012, SC-015.

- [X] T022 [P] [US1] Tạo `app/sora_thu_chi/lib/core/scan/receipt_parser.dart`: `parseVietnameseAmount` (`55.000`/`55,000`/`55 000`/`55000`/`55.000đ`; loại `12.5`, loại số < 1000 không nhóm) + `parseReceipt({lines, now, expenseCategories, incomeCategories})` theo FR-021…FR-026 (số tiền → dòng từ khoá tổng rồi số lớn nhất cuối; ngày 4 định dạng, không có → `now` + `low`; merchant theo từ khoá hoặc cỡ chữ 30% đầu; trả kèm `confidence` + `rect`)
- [X] T023 [P] [US1] Viết `app/sora_thu_chi/test/receipt_parser_test.dart`: 6 định dạng số, hóa đơn Circle K (lấy dòng TỔNG CỘNG chứ không phải dòng mặt hàng), nhiều con số, không có dòng tổng → số lớn nhất cuối, không có số tiền → rỗng + `low`, ngày 3 định dạng có/không giờ, ngày sai (31/02) → bỏ qua, merchant theo từ khoá vs theo cỡ chữ, dòng chỉ có ĐT/MST không bị lấy làm tiền
- [X] T024 [P] [US1] Tạo `app/sora_thu_chi/lib/core/scan/merchant_dictionary.dart`: `suggestCategoryName(String merchant)` (bỏ dấu + thường hoá, ~50 khoá khớp **tên danh mục seed**) + `resolveCategory(String? name, List<Category> active)` (chỉ danh mục đang hoạt động, không có → `null`) (FR-024)
- [X] T025 [P] [US1] Viết `app/sora_thu_chi/test/merchant_dictionary_test.dart`: khớp có/không dấu (`Circle K`/`CIRCLE K`), khớp chuỗi con, không khớp → `null`, `resolveCategory` bỏ danh mục ẩn, mọi tên đích phải tồn tại trong `CategorySource`
- [X] T026 [P] [US1] Tạo `app/sora_thu_chi/lib/core/scan/scan_duplicate.dart` (`findRecentDuplicate(existing, {amount, date, window: 24h})` — bỏ transfer/adjustment) và `app/sora_thu_chi/test/scan_duplicate_test.dart` (cùng số tiền trong 24h → có; lệch 1 đồng / lệch 24h01 → không; danh sách rỗng → `null`) (FR-035)
- [X] T027 [P] [US1] Tạo `app/sora_thu_chi/lib/core/scan/image_preprocess.dart` (`preprocessForOcr(input, {maxSide = 2000})`: `bakeOrientation` → resize → `adjustColor(contrast: 1.15, saturation: 0)` → `encodeJpg(quality: 88)`, kèm comment `ponytail:` ghi rõ **không** dò biên/crop theo R4) và `app/sora_thu_chi/test/image_preprocess_test.dart` (ảnh nhỏ giữ kích thước, ảnh lớn thu về `maxSide`, JPEG/PNG đều ra JPEG đọc lại được — thuần Dart, không plugin) (FR-017)
- [X] T028 [US1] Tạo `app/sora_thu_chi/lib/core/scan/receipt_extractor.dart`: seam `ReceiptExtractor` + `RuleBasedExtractor` (gọi `parseReceipt`, nhận `List<ScanTextLine>` + danh mục đang hoạt động, trả `ScanExtraction` cùng định dạng cho cả 2 nhánh về sau) (R7)
- [X] T029 [US1] Cài impl `MlKitReceiptOcr` trong `app/sora_thu_chi/lib/core/scan/receipt_ocr.dart`: `TextRecognition` bản Latin (bundled, chạy offline), nối text + chuẩn hoá `boundingBox` pixel → `ScanRect` 0..1 theo kích thước ảnh (FR-018)
- [X] T030 [P] [US1] Cài impl `LocalScanImageStore` trong `app/sora_thu_chi/lib/core/scan/scan_image_store.dart`: copy ảnh vào `<appDocuments>/receipts/<millis>.jpg`, `delete` tương ứng; **chỉ** được gọi trong nhánh lưu (FR-036, R12)
- [X] T031 [US1] Tạo `app/sora_thu_chi/lib/screens/scan/add_transaction_sheet.dart` theo mockup `scan-01`: `AddTransactionSheet` + `showModalBottomSheet`, 4 hàng (Khoản Thu / Khoản Chi / Chuyển khoản / Quét hóa đơn (AI) + nhãn "MỚI" + mô tả), hàng quét **chỉ hiện khi** `ScanController.settings.enabled`; trả `AddSheetChoice`; `ValueKey('add-sheet-scan')`… (FR-001, FR-003)
- [X] T032 [US1] Viết `app/sora_thu_chi/test/add_transaction_sheet_test.dart`: đủ 4 hàng + nhãn "MỚI" khi bật, thiếu hàng quét khi tắt, chạm từng hàng trả đúng `AddSheetChoice`, nhãn EN khi locale `en`
- [X] T033 [US1] Nối dispatch ở `app/sora_thu_chi/lib/core/app_shell.dart`: `income`/`expense` → `AddTransactionScreen(initialType: …)`, `transfer` → `AddTransactionScreen(initialType: TxnType.transfer)`, `scan` → `startScanFlow(context)`; cờ "đã lưu" giữ nguyên khối làm mới hiện có (FR-002)
- [X] T034 [US1] Sửa `app/sora_thu_chi/lib/screens/add_transaction_screen.dart`: thêm tham số `TxnType initialType = TxnType.expense`; khi `initialType == transfer` thì sau khi nạp ví xong tự gọi `_openTransferFlow()` **một lần** (cờ `_autoTransferOpened`) — không đổi gì khác (bộ test PBI 7/11 giữ nguyên) (R14)
- [X] T035 [US1] Thêm hàng công tắc bật/tắt vào `app/sora_thu_chi/lib/screens/settings_screen.dart` (`ValueKey('scan-enabled-switch')`, đọc/ghi qua `ScanController` bằng `Obx`) và bổ sung ca tương ứng vào `app/sora_thu_chi/test/settings_screen_test.dart` (FR-003; khối trạng thái AI làm ở T050)
- [X] T036 [US1] Tạo `app/sora_thu_chi/lib/screens/scan/scan_camera_screen.dart` theo mockup `scan-02`: nền **tối cố định**, `CameraPreview`, overlay khung ngắm nét đứt 4 góc (`CustomPainter`), nút back/flash/Thư viện (`image_picker`)/chụp tròn, dòng gợi ý "Đặt hóa đơn vừa khung, tránh bóng đổ"; **xin quyền đúng lúc này**; **không** có nút "Quét nhiều"; bọc `CameraGateway` (khởi tạo `enableAudio: false`) để test widget không cần camera thật (FR-013, FR-014, FR-015, FR-016, FR-040)
- [X] T037 [US1] Viết `app/sora_thu_chi/test/scan_camera_screen_test.dart` (với `CameraGateway` fake): có `CustomPaint` khung ngắm, có nút flash/thư viện/chụp, có dòng gợi ý, **không** có nút "Quét nhiều", nền tối bất kể theme, chọn thư viện → trả đường dẫn ảnh
- [X] T038 [US1] Tạo `app/sora_thu_chi/lib/screens/scan/scan_processing_screen.dart` theo mockup `scan-03`: ảnh thu nhỏ + vệt quét, tiêu đề "Đang xử lý hóa đơn…", **4 bước** với trạng thái xong/đang chạy/chưa tới, dòng cam kết "Không gửi dữ liệu lên bất kỳ máy chủ nào"; chạy pipeline (`compute(preprocessForOcr)` → OCR → `RuleBasedExtractor`) trong `initState`; nhánh không đọc được chữ → thông báo + "Chụp lại"/"Nhập tay" (mở form trống), **không** gọi seam ghi (FR-019, FR-020)
- [X] T039 [US1] Viết `app/sora_thu_chi/test/scan_processing_screen_test.dart`: 4 bước hiện đủ + bước đang chạy khác bước khác; OCR fake có văn bản → đẩy sang xác nhận; OCR fake rỗng → thông báo + 2 nút, "Nhập tay" mở form trống, không gọi seam ghi
- [X] T040 [US1] Tạo `app/sora_thu_chi/lib/screens/scan/widgets/receipt_viewer.dart`: ảnh gốc trong `InteractiveViewer` + lớp phủ **khoanh vùng** theo `ScanRect` đang chọn (không xác định vùng → không khoanh) (FR-029)
- [X] T041 [US1] Tạo `app/sora_thu_chi/lib/screens/scan/scan_confirm_screen.dart` theo mockup `scan-04` (dùng `SubPageScaffold`, app bar teal, **không** bottom nav): ảnh thu nhỏ + "Xem ảnh gốc", 6 trường (Loại giao dịch segmented, Số tiền + bàn phím số, Ngày giờ, Cửa hàng/Ghi chú, Danh mục, Ví), chỉ báo độ tin cậy (cao → teal trung tính, trung bình → xám, `low`/rỗng → **coral + "Kiểm tra lại"**), chạm trường → khoanh vùng, banner cảnh báo trùng, dòng "Nguồn: Quét hóa đơn (AI)…", nút **"Lưu giao dịch"** ở `bottomNavigationBar` + `SafeArea` (nút vô hiệu khi số tiền rỗng/≤ 0; cờ `_saving` chống bấm đúp; ví mặc định, không có ví hợp lệ → bắt chọn; lưu = `ScanImageStore.save` → `addScannedTransaction`) (FR-025…FR-033, FR-035, FR-041)
- [X] T042 [US1] Viết `app/sora_thu_chi/test/scan_confirm_screen_test.dart`: vẽ đủ 6 trường + ảnh + dòng nguồn + nút lưu; số tiền rỗng → nút vô hiệu, nhập số → bật; nhãn coral cho `low`/rỗng, teal/xám cho cao/trung bình; chạm trường → `ReceiptViewer` nhận đúng `ScanRect`; banner trùng hiện/không hiện; bấm lưu 2 lần → repo nhận **1** lần gọi; sửa danh mục/ví/ngày rồi lưu → tham số xuống repo đúng; lưu lỗi → thông báo tiếng Việt, không pop; English → không nhãn Việt (nhớ khôi phục `Get.locale` trong `addTearDown`, `Get.reset()` sau `Get.put`)
- [X] T043 [US1] Tạo `app/sora_thu_chi/lib/core/scan/scan_flow.dart`: `Future<bool> startScanFlow(BuildContext)` điều phối chụp → xử lý → xác nhận, trả `true` nếu đã lưu giao dịch; nhánh kiểm tra cấu hình (`needsDeviceCheck`) chừa chỗ, T048 cắm màn `scan-10` vào (FR-036 — huỷ giữa luồng không để lại gì)
- [X] T044 [US1] QA tay trên emulator theo `quickstart.md` nhóm **A, C, D, E, F, G, H, I, J, K, L** — ghi lại kết quả từng mục (SC-001, SC-002, SC-004, SC-005, SC-007, SC-011, SC-012, SC-015)

## Pha 4: User Story 2 — Kiểm tra cấu hình máy & chọn chế độ (Ưu tiên: P2)

**Mục tiêu**: lần quét đầu (hoặc sau khi bật công tắc) chạy kiểm tra cấu hình (`scan-10`), phân loại 3 mức, người dùng chọn dùng tiếp; kết quả lưu lại và tái sử dụng, tự kiểm tra lại sau 30 ngày.
**Tiêu chí kiểm thử độc lập**: xoá kết quả kiểm tra đã lưu → mở luồng quét → màn `scan-10` hiện 4 mục đo có giá trị + Đạt/Không đạt và 1 trong 3 thẻ kết quả; chọn dùng tiếp → vào màn chụp bình thường; mở lại lần nữa → **không** chạy lại kiểm tra. Phủ FR-005…FR-008; SC-008, SC-010.

- [X] T045 [P] [US2] Tạo `app/sora_thu_chi/lib/data/platform/device_probe_platform.dart`: `PlatformDeviceProbe implements DeviceProbe` dùng `device_info_plus` (RAM, phiên bản OS) + `MethodChannel('sora_thu_chi/device_probe')` (dung lượng trống, AICore, GPU delegate); bọc `try/catch` với **giá trị mặc định an toàn** (dung lượng 0 ⇒ Tier C, luồng vẫn chạy) (R5, rủi ro 11)
- [X] T046 [US2] Tạo `app/sora_thu_chi/lib/screens/scan/device_check_screen.dart` theo mockup `scan-10`: app bar teal + nút back + tiêu đề "Kiểm tra cấu hình máy"; danh sách 4 mục đo (bộ nhớ trong, dung lượng trống, khả năng hỗ trợ AI, phiên bản HĐH) với giá trị + Đạt/Không đạt/Đang kiểm tra; **3 thẻ kết quả** (dùng được AI ngay / phải tải model / Chế độ cơ bản — nêu rõ tiêu chí chưa đạt); nút "Kiểm tra lại" chạy lại đo; trạng thái trung gian chặng 1: nút Tier A/B **vô hiệu** + chú thích "Chưa khả dụng trong bản này" (FR-006; gỡ ở T056)
- [X] T047 [US2] Viết `app/sora_thu_chi/test/device_check_screen_test.dart` (với `DeviceProbe` fake 3 ca A/B/C): đúng thẻ kết quả + đúng tiêu chí chưa đạt; 4 mục có giá trị + Đạt/Không đạt; "Kiểm tra lại" gọi lại probe; nút Tier A/B vô hiệu + có nhãn chú thích (chỉ khẳng định trạng thái trung gian, không khẳng định là hành vi cuối)
- [X] T048 [US2] Nối nhánh kiểm tra cấu hình vào `app/sora_thu_chi/lib/core/scan/scan_flow.dart` + `checkDevice()` ở `app/sora_thu_chi/lib/core/scan/scan_controller.dart`: `needsDeviceCheck(now)` → đẩy `DeviceCheckScreen`, lưu lựa chọn của người dùng vào `settings.mode` (hoặc "Dùng chế độ cơ bản"); lần mở sau dùng kết quả đã lưu, chỉ đo lại khi quá 30 ngày (FR-007, FR-008)
- [X] T049 [US2] QA tay trên emulator theo `quickstart.md` nhóm **B** — kiểm 3 thẻ kết quả (emulator luôn Tier C), "Kiểm tra lại" và việc không chạy lại kiểm tra ở lần mở sau (SC-008, SC-010)

## Pha 5: User Story 3 — Khối trạng thái AI trong Cài đặt (Ưu tiên: P3)

**Mục tiêu**: mục Cài đặt cho biết đang ở chế độ nào và cho phép kiểm tra lại cấu hình máy.
**Tiêu chí kiểm thử độc lập**: mở Cài đặt → thấy mức phân loại + mốc kiểm tra gần nhất + nút "Kiểm tra lại cấu hình máy" đẩy sang `scan-10`. Phủ FR-004 (phần trạng thái + kiểm tra lại); phần dung lượng/"Xoá model" thuộc chặng 2.

- [X] T050 [US3] Thêm khối trạng thái AI vào nhóm "QUÉT HÓA ĐƠN AI" trong `app/sora_thu_chi/lib/screens/settings_screen.dart`: dòng "Trạng thái AI" (Tier + model/Chế độ cơ bản), "Lần kiểm tra gần nhất", hàng **"Kiểm tra lại cấu hình máy"** → đẩy `DeviceCheckScreen`; đọc qua `Obx` để đổi công tắc ở đây phản ánh ngay vào sheet FAB (FR-004, R15)
- [X] T051 [US3] Bổ sung ca vào `app/sora_thu_chi/test/settings_screen_test.dart`: khối trạng thái hiện tier + mốc kiểm tra, hàng "Kiểm tra lại cấu hình máy" đẩy màn `scan-10`

## Pha 6: User Story 4 — AI nâng cao Tier A/B (Ưu tiên: P4) — **Chặng 2, thi công lượt riêng**

**Mục tiêu**: khi thiết bị đủ điều kiện, trích xuất bằng model trên máy (Gemini Nano qua AICore, hoặc Gemma 3n tải về), có timeout + tự chuyển sang bộ luật cơ bản khi lỗi; tải/xoá model và trạng thái model trong Cài đặt.
**Tiêu chí kiểm thử độc lập**: trên thiết bị thật đủ điều kiện — kiểm tra cấu hình ra Tier A/B, tải model (nếu Tier B), quét cho kết quả tương đương bộ luật; ngắt model/timeout → vẫn ra màn xác nhận và phiên quét ghi `engine = ruleBased`. Phủ FR-010, FR-011, FR-012; SC-009; QA nhóm M, N.

- [X] T052 [US4] Tạo `app/sora_thu_chi/lib/core/scan/llm_extractor.dart`: `LlmExtractor implements ReceiptExtractor` (một lần gọi cho mỗi lần quét, trả cùng định dạng `ScanExtraction`), timeout **10 giây** + `try/catch` fallback sang `RuleBasedExtractor` trong cùng seam, ghi nhận `engine` thực dùng (FR-010, FR-011)
- [X] T053 [US4] Viết test cho `LlmExtractor` với fake model: model trả kết quả hợp lệ; model ném lỗi → kết quả của bộ luật + `engine = ruleBased`; model treo quá timeout → như trên (SC-009)
- [X] T054 [US4] Tạo `app/sora_thu_chi/android/app/src/main/kotlin/…/GenAiChannel.kt` (ML Kit GenAI Prompt API — Tier A) và nối vào kênh `sora_thu_chi/device_probe` sẵn có (R18)
- [X] T055 [US4] Tạo `app/sora_thu_chi/lib/core/scan/model_manager.dart` (tải/xoá/kiểm tra model Tier B ~1.8GB, ghi `scanModelBytes`; tải bị ngắt → không kích hoạt AI, vẫn ở Chế độ cơ bản) + thêm package LLM vào `app/sora_thu_chi/pubspec.yaml` (R18)
- [X] T056 [US4] Làm UI tải model ở `app/sora_thu_chi/lib/screens/scan/device_check_screen.dart` (nút "Tải model (~1.8GB) qua Wifi" + tiến trình + lựa chọn "Dùng chế độ cơ bản") và khối model trong `app/sora_thu_chi/lib/screens/settings_screen.dart` (dung lượng model đang chiếm, "Xoá model", "Kiểm tra cập nhật model") — **gỡ** nút vô hiệu + chú thích trung gian của T046 (FR-007, FR-012)
- [X] T057 [US4] Nối chọn engine theo tier trong `app/sora_thu_chi/lib/core/scan/scan_controller.dart` + `app/sora_thu_chi/lib/core/scan/scan_flow.dart`: Tier A/B → `LlmExtractor`, Tier C → `RuleBasedExtractor`; bổ sung ca test tương ứng
- [X] T058 [US4] QA tay nhóm **M, N** trên thiết bị thật đủ điều kiện (Tier A: Pixel 8+/S24+ có AICore; Tier B: tải/xoá model) — **CHƯA KIỂM CHỨNG**: lượt thi công này không có thiết bị thật đủ điều kiện (emulator luôn Tier C). Phần phủ được bằng test tự động: chọn engine theo tier, fallback AI→bộ luật khi lỗi/timeout/JSON hỏng, tải model thất bại → không bật AI, xoá model → về Chế độ cơ bản. Phần **còn phải QA trên máy thật**: M1–M4 (AICore thật, `engine = geminiNano` ghi vào phiên quét, đo < 10s) và N1–N5 (tiến trình tải thật, ngắt mạng giữa chừng, dung lượng model hiển thị đúng, xoá model giải phóng dung lượng). Ngoài ra **nguồn model Tier B chưa chốt**: repo HuggingFace đang dùng là gated ⇒ cần token (xem `kGemmaModelUrl` trong `lib/data/platform/gemma_model_manager.dart`), phải chọn nguồn phân phối công khai trước khi phát hành (rủi ro 5)

## Pha cuối: Polish & Cross-cutting

- [X] T059 [P] Bổ sung smoke vào `app/sora_thu_chi/test/dark_theme_smoke_test.dart`: pump màn xác nhận + màn kiểm tra cấu hình ở theme tối → không overflow, token tối thật sự áp (FR-040, SC-013)
- [X] T060 Chạy `flutter analyze` (phải sạch) và `flutter test` toàn bộ trong `app/sora_thu_chi/` — 683 test cũ + test mới phải xanh; xử lý test cũ nào phụ thuộc hành vi FAB → form (FAB **cố ý** đổi thành bottom sheet theo spec)
- [X] T061 Rà lại toàn bộ `.tr` trong `app/sora_thu_chi/lib/` ở locale `en` (nhóm L quickstart) — 0 nhãn tĩnh tiếng Việt còn sót trong luồng quét (SC-013)
- [X] T062 Đo lại kích thước APK (`flutter build apk`) và ghi nhận mức tăng do model OCR bundled (~4–6MB dự kiến) (rủi ro 2)
- [X] T063 Tick checklist `.specify/specs/24/checklists/requirements.md` sau khi thi công xong (giữ nguyên nội dung đã duyệt)
- [X] T064 Đồng bộ wiki theo skill `sora-wiki`: cập nhật `wiki-knowledge/entity/Giao dịch.md` (nguồn "AI Scan" + ảnh hóa đơn + bảng phiên quét), `wiki-knowledge/entity/Hồ sơ & Bảo mật.md` (công tắc quét hóa đơn AI + trạng thái AI/tier + kiểm tra cấu hình máy), `wiki-knowledge/concept/Lộ trình phát triển.md`, `wiki-knowledge/concept/Design system.md` (màn chụp nền tối cố định; chỉ báo độ tin cậy teal/xám/coral), `wiki-knowledge/concept/Stack.md` (5 package mới, iOS 15.5) + append `wiki-knowledge/log.md` và cập nhật `wiki-knowledge/index.md` (chặng 2 xong thì bổ sung mục Tier A/B + trạng thái model)

## Sơ đồ phụ thuộc

```text
Pha 1 Setup (T001–T005, song song)
        ↓
Pha 2 Foundational (T006–T021)
   T006 ─┬─ T007 → T008
   T009/010/011/012 ─→ T013 → T014 → T015 → T016
   T019 ─→ T020
   T012 ─→ T018 (fakes)        T017 (i18n) độc lập
        ↓
US1 (P1) T022–T044  🎯 MVP
   parser/dictionary/duplicate/preprocess (T022–T027) → extractor T028 → processing screen T038
   T036 camera → T038 → T041 confirm → T043 scan_flow → T044 QA
   T031 sheet ─→ T033 app_shell (T021 chốt điểm vào) ─→ T044
        ↓
US2 (P2) T045–T049   (T043 scan_flow được nối thêm ở T048)
        ↓
US3 (P3) T050–T051   (cần kết quả tier của US2)
        ↓
US4 (P4) T052–T058   chặng 2 — gỡ trạng thái trung gian của T046
        ↓
Polish T059–T064
```

## Ví dụ chạy song song

```text
# Pha 1 — 5 task khác file, chạy cùng lúc:
T001 pubspec.yaml · T002 AndroidManifest · T003 Info.plist/Podfile/pbxproj · T004 DeviceProbeChannel.kt · T005 DeviceProbeChannel.swift

# Pha 2 — nhóm model thuần độc lập:
T006 transaction.dart · T009 scan_result.dart · T010 scan_settings.dart · T011 device_tier.dart · T012 4 seam interface · T017 i18n

# US1 — 5 nhánh độc lập (mỗi nhánh gồm impl + test):
T022/T023 receipt_parser · T024/T025 merchant_dictionary · T026 scan_duplicate · T027 image_preprocess · T030 ScanImageStore
# rồi tuần tự: T028 extractor → T038 processing → T041 confirm → T043 scan_flow
# nhánh UI chạy song song với nhánh logic: T031 sheet · T035 settings switch · T036 camera · T040 receipt_viewer
```

## Chiến lược triển khai

- **MVP đề xuất (chặng 1, giao được ngay)**: Pha 1 → Pha 2 → **US1**. Kết thúc US1 là có tính năng dùng được trọn vẹn ở Chế độ cơ bản (SC-002, SC-004, SC-005, SC-015 đạt), chưa cần cấu hình máy hay AI.
- **Tăng dần trong chặng 1**: US2 (kiểm tra cấu hình) → US3 (khối trạng thái trong Cài đặt). Sau Pha 5, chặng 1 QA được 100% trên emulator (quickstart A–L) ⇒ mốc để đồng bộ wiki (T064).
- **Chặng 2 tách lượt**: US4 (Tier A/B) gần như không QA được trên emulator (emulator luôn Tier C) — thi công khi có thiết bị thật; seam `ReceiptExtractor` giữ cho phần bộ luật vẫn là đường chạy thật, nên chặng 1 không bị chặn.
- **Điểm dễ vỡ nhất**: T008 (quên `build_runner` ⇒ thiếu cột `source`), T016 (`ScanController` chưa nạp ⇒ sheet không thấy trạng thái), T033 (không trả cờ "đã lưu" ⇒ danh sách/Tổng quan đứng yên).
