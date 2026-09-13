# Nghiên cứu kỹ thuật — PBI 24: Thêm giao dịch bằng quét hóa đơn (AI)

**Mã PBI**: 24
**Liên kết spec**: [./spec.md](./spec.md)
**Ngày tạo**: 2026-09-12
**Trạng thái**: mọi `NEEDS CLARIFICATION` đã giải quyết.

Nguồn chân lý nghiệp vụ: `docs/ai/tinh-nang-quet-hoa-don-ai-local.md` (§2 kiến trúc pipeline, §3 luồng, §8 stack bổ sung, §11 kiểm tra cấu hình & tier) + mockup `scan-01`…`scan-04`, `scan-10`, `scan-11`. Nền kỹ thuật kế thừa: PBI 9/10 (danh sách & chi tiết giao dịch), PBI 11 (form thêm + picker danh mục/ví), PBI 12 (bộ lọc), PBI 17/18/19 (`AppSettings` key-value, theme token, i18n).

---

## R1 — Kiến trúc tổng & chia 2 chặng thi công ✅ (người dùng chốt 2026-09-12)

**Quyết định**: giữ nguyên phạm vi spec, thi công trong **cùng một PBI nhưng 2 chặng**:

- **Chặng 1 — luồng quét trọn vẹn ở Chế độ cơ bản**: FAB → bottom sheet (`scan-01`) → xin quyền đúng lúc → màn chụp (`scan-02`) → tiền xử lý + OCR on-device → bộ luật thuần Dart → màn xác nhận (`scan-04`, có khoanh vùng ảnh gốc + chỉ báo độ tin cậy + cảnh báo trùng) → lưu (nguồn `AI Scan` + ảnh đính kèm + bản ghi phiên quét); kèm màn kiểm tra cấu hình (`scan-10`, phân loại 3 tier thật) và khối Cài đặt (công tắc + trạng thái AI). **Toàn bộ chặng 1 QA được trên emulator** (chụp qua camera ảo của emulator hoặc chọn ảnh từ thư viện).
- **Chặng 2 — AI nâng cao**: nối model thật cho Tier A (Gemini Nano) và Tier B (Gemma 3n tải ~1.8GB) + UI tải/xoá model + tự chuyển sang bộ luật khi model lỗi/timeout.

**Lý do**: chặng 1 là phần mang giá trị nghiệp vụ (giảm thao tác nhập tay) và kiểm chứng được 100% bằng test + QA tay; chặng 2 là phần phụ thuộc thiết bị thật (emulator luôn rơi vào Tier C ⇒ không QA được bằng đường thường), cần native Kotlin + package LLM native + bump iOS — tách ra để chặng 1 không bị chặn.

**Phương án khác**: (a) làm cả hai chặng trong một lượt thi công — rủi ro cao, phần lớn code không kiểm chứng được, dễ kéo dài vô hạn; (b) bỏ hẳn Tier A/B khỏi PBI này — phải sửa spec (FR-005/007/010/011/012) và lệch quyết định đã chốt 2026-09-12.

**Trạng thái trung gian giữa 2 chặng** (chỉ tồn tại giữa hai lượt thi công, không phải bản phát hành): màn `scan-10` dựng **đủ 3 thẻ kết quả** theo mockup, nhưng ở thẻ Tier A/B nút kích hoạt ở trạng thái **vô hiệu + chú thích "Chưa khả dụng trong bản này"**, và luồng quét chạy bằng Chế độ cơ bản. Chặng 2 gỡ trạng thái này (không test nào khẳng định nút bị vô hiệu là hành vi cuối).

---

## R2 — OCR on-device: `google_mlkit_text_recognition` (bản **bundled**)

**Quyết định**: dùng package `google_mlkit_text_recognition` (nhánh Latin), tức phụ thuộc Android `com.google.mlkit:text-recognition:16.0.1` — bản **bundled** (model nằm trong APK), không phải bản `-unbundled` (tải qua Google Play Services). iOS dùng pod `MLKitTextRecognition` (model trong framework).

**Lý do**: doc §8 chỉ định đúng package này; bản bundled chạy **hoàn toàn offline ngay từ lần đầu** (không phát sinh tải model ⇒ không mâu thuẫn FR-037/SC-006: chỉ bước tải model AI nâng cao mới cần mạng). API trả `TextBlock → lines → elements` kèm `boundingBox` (pixel) ⇒ đủ cho FR-018 (văn bản thô **và** vùng chữ) và FR-029 (khoanh vùng).

**Phương án khác**: (a) bản unbundled — nhẹ APK hơn nhưng lần chạy đầu phải tải model qua mạng ⇒ vi phạm "offline hoàn toàn"; (b) OCR tự viết/TFLite tự train — ngoài phạm vi, chất lượng thấp hơn nhiều.

**Hệ quả cần xử lý khi thi công**: iOS deployment target hiện `13.0` phải nâng lên **15.5** (yêu cầu của ML Kit iOS) — xem R17. APK tăng ~4–6MB (model Latin) — chấp nhận, ghi ở mục Rủi ro của plan.

## R3 — Chụp ảnh: `camera` (màn chụp) + `image_picker` (thư viện ảnh)

**Quyết định**: 2 package. `camera` cho **màn chụp `scan-02`** (preview trực tiếp + `setFlashMode` + `takePicture`), `image_picker` với `ImageSource.gallery` cho nút **thư viện**.

**Lý do**: FR-014/SC-001 đòi khung ngắm nét đứt, nút flash, nút chụp tròn **trên màn của app** — `image_picker` một mình chỉ mở app camera của hệ điều hành (không có viewfinder của mình). `camera` không có API chọn ảnh từ thư viện ⇒ cần `image_picker`. Cả hai đều là package chính thức của flutter.dev.

**Phương án khác**: chỉ dùng `image_picker` (`ImageSource.camera`) — bỏ được 1 dependency nhưng **không dựng được mockup `scan-02`** ⇒ vỡ SC-001.

**Ghi chú triển khai**: `camera` tạo file tạm trong cache dir; chỉ **copy sang kho vĩnh viễn khi người dùng lưu** (R12) ⇒ FR-036 (huỷ giữa luồng không để lại ảnh) tự đúng. Nút "Quét nhiều" của mockup không hiển thị (FR-016).

## R4 — Tiền xử lý ảnh: package `image`, chạy trong isolate; **bỏ** dò biên/crop

**Quyết định**: một hàm thuần `Future<Uint8List> preprocessForOcr(Uint8List input, {int maxSide = 2000})` chạy qua `compute()` (isolate): `bakeOrientation` (sửa chiều theo EXIF) → thu nhỏ cạnh dài về `maxSide` → tăng tương phản nhẹ (`adjustColor(contrast: 1.15)` + chuyển xám) → mã hoá lại JPEG. **Không** dò biên hóa đơn, **không** crop, **không** màn kéo 4 góc.

**Lý do**: FR-017 yêu cầu tiền xử lý tự động (chỉnh chiều + tương phản) và cho phép "không phát hiện được biên thì dùng nguyên ảnh" — nên **luôn dùng nguyên ảnh** là nhánh hợp lệ, rẻ nhất. Thu nhỏ cạnh dài là phần thực sự có giá trị: ảnh 12MP làm ML Kit chậm gấp nhiều lần mà không tăng độ chính xác (SC-007 < 3 giây). `image` là package thuần Dart (không kênh native), decode/encode 12MP mất vài trăm ms ⇒ phải chạy isolate để không chặn UI.

**Phương án khác**: (a) thêm `image_cropper` cho crop tay — doc §3.3 có nhưng spec đã **loại khỏi đợt này** ("đợt này chỉ có tiền xử lý tự động"); (b) tự viết dò biên bằng Sobel trong Dart — code nhiều, lợi ích không đo được trong đợt này; (c) không tiền xử lý gì — vi phạm FR-017.

**`ponytail:`** ghi trong code: không có dò biên/crop; thêm khi ảnh thực tế cho thấy OCR sai vì nền lẫn.

## R5 — Đo cấu hình thiết bị: `device_info_plus` + dung lượng trống + kênh native AICore

**Quyết định**: một seam `DeviceProbe { Future<DeviceCapability> measure(); }`, impl thật `PlatformDeviceProbe` ghép 3 nguồn:

| Mục (mockup `scan-10`) | Nguồn |
|---|---|
| Bộ nhớ RAM | `device_info_plus` — `AndroidInfo.physicalRamSize` / `IosInfo.physicalRamSize` (byte → GB) |
| Dung lượng trống | `MethodChannel('sora_thu_chi/device_probe').invokeMethod<double>('freeStorageGb')` — Android `StatFs(documentsDir).availableBytes`, iOS `URL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])` |
| Hỗ trợ AI trên máy (AICore) | cùng kênh: `invokeMethod<bool>('supportsOnDeviceAi')` — Android kiểm tra `PackageManager.getPackageInfo("com.google.android.aicore")` (có ⇒ máy thuộc dòng được Google hỗ trợ Gemini Nano); iOS trả `false` |
| Phiên bản hệ điều hành | `device_info_plus` (`version.release`) |

**Lý do**: `device_info_plus` phủ RAM + OS (không tự viết native được gì thêm), nhưng **không** cho dung lượng trống và không cho biết AICore. Hai thứ thiếu đó gộp vào **một** kênh native ~30 dòng Java/Kotlin + ~20 dòng Swift — ít code hơn và ít phụ thuộc hơn một package dung lượng thứ ba. Kênh này cũng chính là nơi chặng 2 cắm tiếp phần Gemini Nano (R18) nên không phải dựng kênh thứ hai.

**Phương án khác**: (a) thêm `disk_space_plus`/`disk_space_2` cho dung lượng — bớt code native nhưng thêm 1 dependency ngoài luồng chính, và vẫn phải tự viết native cho AICore; (b) bỏ mục AICore, chỉ phân loại B/C — màn `scan-10` sai mockup và FR-005 mất nhánh Tier A.

**Seam cho test**: `DeviceProbe` bơm fake ⇒ test widget màn `scan-10` chạy được không cần plugin.

## R6 — Phân loại tier & lưu hồ sơ năng lực: hàm thuần + 1 row JSON

**Quyết định**: module thuần `device_tier.dart`: `DeviceCapability` (ramGb, freeStorageGb, supportsOnDeviceAi, osVersion, supportsGpuDelegate, checkedAt) + `enum AiTier { a, b, c }` + `AiTier classifyTier(DeviceCapability)` + `bool isStale(DeviceCapability, DateTime now, {int days = 30})` + `toJson/fromJson`. Ngưỡng theo doc §11.2: **A** nếu `supportsOnDeviceAi`; ngược lại **B** nếu `ramGb ≥ 4 && freeStorageGb ≥ 2 && supportsGpuDelegate`; còn lại **C**. Lưu **một row** `AppSettings` key `scanDeviceCheck` chứa JSON của `DeviceCapability`.

**Lý do**: toàn bộ luật phân loại là logic thuần ⇒ unit test được hết (biên 3.9/4.0 GB, 1.9/2.0 GB, thiếu AICore, quá 30 ngày) mà không cần thiết bị thật. Một row JSON thay vì 6 row rời: ít key hơn, một lần đọc/ghi, đổi cấu trúc sau này không phải thêm key (bảng `AppSettings` là key-value ⇒ không migration).

**Phương án khác**: (a) 6 row rời (`scanRamGb`, `scanFreeStorageGb`, …) — nhiều key, dễ lệch trạng thái nửa vời; (b) bảng drift riêng cho hồ sơ thiết bị — thừa: đúng 1 bản ghi/thiết bị, không truy vấn.

**Ghi chú**: `supportsGpuDelegate` lấy từ chính kênh native (Android: `Build.SUPPORTED_ABIS`/NNAPI có mặt, iOS: `true` với máy ≥ A12 — trả `true` mặc định trên iOS hiện đại). Kết quả chỉ dùng để chọn chế độ, không cam kết chất lượng (spec §Giả định).

## R7 — Engine trích xuất: một seam, hai nhánh, **cùng định dạng kết quả**

**Quyết định**: `abstract class ReceiptExtractor { Future<ScanExtraction> extract(List<ScanTextLine> lines, {required DateTime now, required List<Category> categories}); }` với 2 impl: `RuleBasedExtractor` (chặng 1, thuần Dart) và `LlmExtractor` (chặng 2, gọi model). Màn xác nhận **không biết** engine nào đã chạy — chỉ nhận `ScanExtraction` + `ScanEngine` để ghi vào phiên quét.

**Lý do**: doc §2/§11.4 chốt "cả 2 nhánh cho cùng một định dạng kết quả ⇒ màn xác nhận dùng chung"; FR-011 (AI lỗi → tự chuyển sang bộ luật cho riêng lần quét đó) chính là một `try/catch` quanh nhánh LLM trong cùng seam ⇒ để dành được, không phải sửa màn.

**Phương án khác**: (a) viết thẳng logic vào màn xác nhận — không test được, không có chỗ fallback; (b) hai đường ống riêng cho 2 nhánh — nhân đôi màn xác nhận, lệch kết quả.

## R8 — Bộ luật trích xuất (FR-021…FR-026): đầu vào là **dòng chữ + vùng**, không phải ảnh

**Quyết định**: `receipt_parser.dart` thuần Dart nhận `List<ScanTextLine>` (`text` + `ScanRect` **chuẩn hoá 0..1** so với kích thước ảnh, để màn xác nhận vẽ khoanh vùng ở bất kỳ tỉ lệ hiển thị nào). Luật:

| Trường | Luật | Tin cậy |
|---|---|---|
| **Số tiền** | Ưu tiên dòng chứa từ khoá tổng (`tổng cộng`, `tổng tiền`, `tổng`, `thanh toán`, `phải trả`, `total`, `t.tiền`) → lấy số **lớn nhất** trên dòng đó; nếu không có → số lớn nhất trong **40% cuối ảnh** thoả định dạng tiền (≥ 1000 và có nhóm 3 chữ số hoặc kèm `đ`/`vnd`). Bỏ số nằm trong dòng ngày/giờ/điện thoại/MST/số hoá đơn | cao nếu khớp dòng từ khoá, trung bình nếu suy từ số lớn nhất, **để trống** nếu không tìm ra (→ bắt buộc nhập tay) |
| **Ngày giờ** | Regex `dd/mm/yyyy`, `dd-mm-yyyy`, `yyyy-mm-dd` (cho phép 1–2 chữ số ngày/tháng) + tuỳ chọn `hh:mm`. Kiểm tra hợp lệ (tháng 1–12, ngày ≤ số ngày của tháng) | cao nếu đủ ngày/tháng/năm, trung bình nếu chỉ có ngày/tháng, **không tìm thấy → dùng `now` + tin cậy thấp** (FR-022) |
| **Tên cửa hàng** | Dòng chứa `cửa hàng`/`chi nhánh`/`cn` → ưu tiên; nếu không, dòng có **chiều cao vùng chữ lớn nhất** trong **30% đầu ảnh**; bỏ dòng thuần số/điện thoại/quá ngắn (< 3 ký tự) | trung bình nếu khớp từ khoá, **thấp** nếu suy theo cỡ chữ (khớp mockup `scan-04`: "Circle K - Trần Duy Hưng" hiện "Kiểm tra lại") |
| **Danh mục gợi ý** | Từ điển R9: chuẩn hoá merchant (bỏ dấu, thường hoá) → khớp khoá → tên danh mục → tra trong **danh mục chi đang hoạt động** để lấy `Category` | trung bình nếu khớp từ điển (nhãn trung tính, khớp mockup: Danh mục không có badge coral), **thấp/để trống** nếu không khớp |
| **Loại giao dịch** | Luôn **Chi tiêu** (FR-025), người dùng đổi được | — |

Nhãn hiển thị (FR-026): `high` → teal trung tính "Độ tin cậy cao"; `medium` → xám trung tính "Độ tin cậy trung bình"; `low` **hoặc để trống** → **coral + "Kiểm tra lại"**.

**Lý do**: doc §2.1 chỉ rõ OCR Latin đọc **số** chính xác nhất, chữ có dấu kém hơn ⇒ ưu tiên số, merchant chỉ gợi ý. Đặt toàn bộ luật ở tầng thuần nghĩa là mọi ca khó (nhiều con số, dòng tổng, hóa đơn không dấu, không có ngày) test được bằng fixture văn bản — không cần ảnh, không cần ML Kit.

**Phương án khác**: (a) parse trong màn xác nhận — không test được; (b) dùng `intl`/regex thư viện ngoài — không cần, luật chỉ ~5 regex.

**Hàm phụ trợ thuần (test riêng)**: `int? parseVietnameseAmount(String)` — hiểu `55.000`, `55,000`, `55 000`, `55000`, `55.000đ`, `55.000 VND`; **loại** số thập phân kiểu `12.5` và số không có nhóm nghìn khi < 1000.

## R9 — Từ điển cửa hàng → danh mục: tĩnh trong app, khớp **tên danh mục seed**

**Quyết định**: `merchant_dictionary.dart` — danh sách hằng `(List<String> khoá, String tênDanhMục)`; khoá đã bỏ dấu/thường hoá, so khớp bằng `contains` trên merchant đã chuẩn hoá. Đích là **tên danh mục có thật trong `CategorySource`** (`Ăn uống`, `Di chuyển`, `Mua sắm`, `Hóa đơn`, `Nhà ở`, `Sức khỏe`, `Giải trí`, `Cà phê`…), rồi tra sang `Category` trong danh mục **chi đang hoạt động**; không khớp hoặc danh mục đã bị ẩn/xoá → để trống (FR-024, spec §Trường hợp biên). Khoảng 50 khoá phủ chuỗi phổ biến: `circle k`, `highlands`, `phúc long`, `winmart`, `coopmart`, `bách hóa xanh`, `điện máy xanh`, `thế giới di động`, `petrolimex`, `grab`, `be`, `shopee`, `lazada`, `cgv`, `long châu`, `evn`, …

**Lý do**: doc §3.5/§4 xếp "gợi ý danh mục theo từ điển" vào đợt này, còn "học theo người dùng" (bảng ánh xạ) là GĐ2 — đã loại ở spec. Từ điển khớp theo **tên danh mục** (không phải id) nên không phụ thuộc id DB, đổi seed cũng không vỡ.

**Phương án khác**: (a) bảng `merchant_category_mapping` trong DB — spec đã loại (học theo người dùng là PBI sau); (b) khớp theo id danh mục — vỡ khi seed đổi.

## R10 — Lưu trữ: schema **v8** (`transactions.source` + bảng `scan_sessions`) + 4 key `AppSettings`

**Quyết định**:

1. `transactions` thêm cột `source` (`textEnum<TxnSource>` = `manual` | `aiScan`), default `manual` cho mọi dòng cũ ⇒ **additive, không mất dữ liệu** (khớp nếp `tags`/`receipt_image` v3).
2. Bảng mới `scan_sessions` (FR-034): `id`, `image_path`, `raw_text`, `parsed_json`, `engine` (`textEnum<ScanEngine>` = `ruleBased` | `geminiNano` | `gemma3nE2b`), `transaction_id` (nullable), `created_at`. Thuần **tạo bảng, không seed** (bám `budgets` v6).
3. `AppSettings` thêm 4 key (không migration): `scanEnabled`, `scanEngineMode`, `scanModelBytes`, `scanDeviceCheck` (JSON R6).

**Lý do**: FR-034 đòi lưu bản ghi phiên quét (ảnh gốc, văn bản thô, kết quả trích xuất, chế độ xử lý, giao dịch đã tạo) nhưng spec đã loại **màn** Scan History ⇒ chỉ cần bảng + đường ghi, không cần UI đọc. Enum engine 3 giá trị khớp doc §4 (`llm_tier_a`/`llm_tier_b`/`rule_based` gộp thành `geminiNano`/`gemma3nE2b`/`ruleBased`); trường hợp AI lỗi → ghi `ruleBased` (đúng FR-011: "ghi nhận lần quét đó là do chế độ cơ bản xử lý").

**Phương án khác**: (a) không thêm `source`, phân biệt bằng `receipt_image != ''` — sai (giao dịch thủ công cũng có thể có ảnh), và FR-033 yêu cầu tường minh; (b) bảng `merchant_category_mapping` — PBI sau; (c) thêm cột `source_type` của doc §10.5 — spec đã chốt **chưa thêm** (chỉ 1 nguồn).

## R11 — Seam ghi: `addScannedTransaction` (một transaction DB), **không** đổi `addTransaction`

**Quyết định**: thêm method vào `WalletRepository`:

```dart
Future<void> addScannedTransaction({
  required int walletId, required TxnType type, required int amount,
  Category? category,                     // null = không gợi ý/người dùng bỏ trống
  required DateTime date, String note = '',
  required String receiptImage,           // đường dẫn ảnh đã copy vào kho (R12)
  required String rawText, required String parsedJson, required ScanEngine engine,
});
```

Impl drift: **một** `db.transaction()` — bù `balance` ví (như `addTransaction`), insert 1 dòng `transactions` (`source = aiScan`, `receipt_image`, `category_id`/`category` nếu có), rồi insert `scan_sessions` với `transaction_id` vừa sinh (atomic ⇒ FR-034 không thể nửa vời).

**Lý do**: đường thủ công `addTransaction` **bắt buộc** có `Category` (màn thêm giao dịch chặn lưu khi thiếu danh mục — FR-013 PBI 11), còn giao dịch quét **cho phép trống danh mục** (FR-015/FR-024) ⇒ không thể tái dùng chữ ký cũ mà không nới lỏng luật của màn thủ công. Giữ `addTransaction` nguyên vẹn ⇒ 293 test cũ không đổi hành vi.

**Phương án khác**: (a) thêm tham số optional vào `addTransaction` — nới lỏng seam dùng chung, dễ vô tình cho phép giao dịch thủ công thiếu danh mục; (b) ghi phiên quét ở lần gọi thứ hai (không atomic) — có thể mất bản ghi khi app bị đóng giữa hai lệnh.

## R12 — Ảnh hóa đơn: copy vào `<documents>/receipts/` **lúc lưu**, dùng lại cột `receipt_image`

**Quyết định**: seam `ScanImageStore { Future<String> save(Uint8List bytes); Future<void> delete(String path); }`, impl thật ghi `<appDocuments>/receipts/<millis>.jpg`; `receipt_image` của giao dịch = đường dẫn tuyệt đối đó ⇒ màn chi tiết giao dịch (PBI 10) **hiển thị sẵn** ảnh, không phải sửa gì (SC-005). Chỉ copy khi người dùng bấm "Lưu giao dịch"; huỷ giữa luồng không tạo file nào (FR-036).

**Lý do**: cột `receipt_image` + `_ReceiptThumb` (`Image.file`) đã có từ PBI 10 — dùng lại đúng cơ chế hiện có thay vì dựng kho ảnh mới. Copy (không di chuyển) để giữ nguyên file gốc người dùng chọn từ thư viện.

**Phương án khác**: lưu đường dẫn file gốc trong thư viện ảnh — mong manh (người dùng xoá ảnh là mất), và ảnh cache của camera có thể bị hệ điều hành dọn. Doc §6 nói "cùng cơ chế mã hóa đã áp dụng cho file đính kèm khác" — **repo chưa có** cơ chế mã hoá file đính kèm nào (đang là path thô) ⇒ đợt này giữ đúng hiện trạng, ghi nhận ở mục Rủi ro.

## R13 — Cảnh báo trùng (FR-035): hàm thuần trên dữ liệu đã có

**Quyết định**: hàm thuần `Transaction? findRecentDuplicate(List<Transaction> existing, {required int amount, required DateTime date, Duration window = const Duration(hours: 24)})` — khớp **cùng số tiền tuyệt đối** và `|date − txn.date| ≤ 24h`, bỏ qua transfer/adjustment. Màn xác nhận nạp `allTransactions()` một lần khi mở, hiện banner coral nhạt **không chặn** lưu; không có kết quả → **không hiện gì** (spec §Trường hợp biên).

**Lý do**: `allTransactions()` đã có trong seam (PBI 9) và màn chi tiết đã dùng ⇒ không thêm method đọc. Logic thuần ⇒ test biên (đúng 24h, lệch 1 đồng, transfer cùng số tiền).

**Phương án khác**: truy vấn SQL riêng theo amount+date — nhanh hơn nhưng thêm đường đọc trùng lặp và phải test lại ở tầng DAO; số giao dịch của app cá nhân đủ nhỏ để lọc trong bộ nhớ.

## R14 — Điểm vào: FAB → bottom sheet (mockup `scan-01`)

**Quyết định**: `AppShell._openAddTransaction` đổi thành mở `showModalBottomSheet` (`AddTransactionSheet`): 4 hàng — **Khoản Thu** → `AddTransactionScreen(initialType: income)`, **Khoản Chi** → `(initialType: expense)`, **Chuyển khoản** → `(initialType: transfer)` (màn thêm tự mở luồng chuyển khoản sau khi nạp ví, giữ nguyên luồng PBI 8), **Quét hóa đơn (AI)** (icon máy ảnh + mô tả + nhãn "MỚI") → `startScanFlow()`. Hàng quét **ẩn** khi công tắc tắt (FR-003). Sheet trả `bool?` "đã lưu" để shell làm mới (giữ nguyên logic `_openAddTransaction` hiện có, chỉ đổi nguồn cờ).

**Lý do**: FR-001/FR-002 yêu cầu đúng 4 lựa chọn và 3 lựa chọn cũ giữ hành vi. Thêm `initialType` (mặc định `expense` = hành vi hiện tại) là thay đổi nhỏ nhất để "Chuyển khoản" từ sheet vào đúng luồng cũ mà không nhân bản màn.

**Phương án khác**: (a) sheet đẩy thẳng `WalletTransferScreen` — phải tự chọn ví nguồn và bỏ qua logic dirty/preselect của màn thêm ⇒ hai đường vào luồng chuyển khoản lệch nhau; (b) giữ FAB mở thẳng form như cũ và thêm hàng quét ở nơi khác — vỡ FR-001/SC-001.

## R15 — Cài đặt: công tắc + khối trạng thái AI **ngay trong màn Cài đặt**, trạng thái qua `ScanController`

**Quyết định**: `ScanController extends GetxController` (bám `ThemeController`): `Rx<ScanSettings> settings` + `load()`, `setEnabled(bool)`, `setEngineMode(...)`, `checkDevice()` (gọi `DeviceProbe` → `classifyTier` → lưu), `refreshModelState()`. Đăng ký + `load()` ở `app.dart` (cùng chỗ `ThemeController`/`LocaleController`). Màn Cài đặt thêm nhóm **"QUÉT HÓA ĐƠN AI"**: hàng công tắc (`Switch`, `ValueKey('scan-enabled-switch')`) + khối trạng thái (Tier hiện tại + model/Chế độ cơ bản, dung lượng model nếu có, lần kiểm tra gần nhất) + nút **"Kiểm tra lại cấu hình máy"** (mở `DeviceCheckScreen`); nút **"Xoá model"/"Kiểm tra cập nhật model"** thuộc chặng 2.

**Lý do**: spec §Giả định đã chốt **không** dựng màn `scan-05`/`scan-11` riêng — chỉ nhúng khối vào màn Cài đặt hiện có (mockup `scan-11` chỉ dùng để tham chiếu nội dung). Sheet FAB cần đọc công tắc ở tab bất kỳ ⇒ cần trạng thái **reactive dùng chung**, đúng khuôn `ThemeController` (đã có tiền lệ, gồm cả nếp "nối đuôi save" tránh save cũ đè save mới).

**Phương án khác**: (a) `StatefulWidget` + store như `UtilitiesScreen` — mỗi màn tự đọc, sheet không thấy thay đổi cho tới khi mở lại (đủ dùng nhưng phải đọc lại ở 3 nơi); (b) dựng màn Cài đặt quét riêng — spec đã loại.

## R16 — i18n & dark mode: ~55 khóa mới, màn chụp **luôn nền tối**

**Quyết định**: thêm các khóa vào `sora_translations.dart` theo nhóm (`Bottom sheet`, `Màn chụp`, `Màn xử lý`, `Màn xác nhận`, `Kiểm tra cấu hình`, `Cài đặt`, `Trạng thái/lỗi`). Mọi màu đi qua token `SoraColors`/`AppColors`; **coral chỉ** dùng cho cảnh báo/chi tiêu (chỉ báo "Kiểm tra lại", banner trùng, thông báo lỗi). Màn chụp `scan-02` **cố định nền tối** theo mockup bất kể theme (spec §FR-040 + §24); các màn còn lại theo theme hiện hành.

**Lý do**: `sora_translations_test` quét mọi literal `.tr` trong `lib/` ⇒ thiếu khóa là đỏ (lưới an toàn tự động). FR-040 yêu cầu màn chụp giữ nền tối để nhìn rõ hóa đơn — "nền tối cố định" là cách rẻ nhất và đúng mockup.

**Phương án khác**: dùng widget `Text` không `.tr` cho vài nhãn — vi phạm FR-039/SC-013.

## R17 — Cấu hình nền tảng: quyền + iOS 15.5

**Quyết định**:

- `android/app/src/main/AndroidManifest.xml`: thêm `<uses-permission android:name="android.permission.CAMERA"/>` + `<uses-feature android:name="android.hardware.camera" android:required="false"/>`. (Thư viện ảnh Android 13+ dùng photo picker của hệ thống — không cần quyền.)
- `ios/Runner/Info.plist`: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSMicrophoneUsageDescription` (pod `camera` khai báo cả micro; tắt audio khi khởi tạo `CameraController(..., enableAudio: false)` và vẫn khai báo khóa để tránh crash khi pod kiểm tra).
- `ios/Podfile`: `platform :ios, '15.5'`; `ios/Runner.xcodeproj/project.pbxproj`: `IPHONEOS_DEPLOYMENT_TARGET = 15.5` (3 chỗ) — yêu cầu của ML Kit iOS (R2).

**Lý do**: FR-013 (xin quyền đúng lúc vào luồng) chỉ đúng khi manifest đã khai báo quyền — Android runtime permission do package `camera` xin khi khởi tạo; khai báo manifest là điều kiện cần. Bump iOS là hệ quả bắt buộc của R2.

**Phương án khác**: hạ phiên bản `google_mlkit_text_recognition` để giữ iOS 13 — mất bản bundled/API vùng chữ mới, không đáng.

## R18 — Chặng 2: Tier A (Gemini Nano) & Tier B (Gemma 3n) — quyết định sơ bộ

**Quyết định (sơ bộ, chốt lại khi thi công chặng 2)**:

- **Tier A**: kênh native Android `com.google.mlkit:genai-prompt` (ML Kit GenAI Prompt API, model do AICore hệ thống quản lý, **không cần tải**) — mở rộng chính `MethodChannel('sora_thu_chi/device_probe')` thêm method `genAiStatus()` / `summarize(prompt)`; iOS không hỗ trợ Tier A.
- **Tier B**: package `flutter_gemma` (MediaPipe LLM Inference) + model Gemma 3n E2B quantized (~1.8GB) tải bằng chính package này (có tiến trình tải + huỷ), lưu trong thư mục documents; UI "Tải model (1.8GB)" / "Xoá model" / "Kiểm tra cập nhật model" theo mockup `scan-10`/`scan-11`.
- **Fallback**: `LlmExtractor` bọc `try/catch` + timeout (10 giây, SC-007) → rơi về `RuleBasedExtractor`, ghi `engine = ruleBased` vào phiên quét (FR-011).

**Lý do**: đúng doc §8/§11; đúng quyết định "giữ cả nhánh AI nâng cao" của spec. Tách sang chặng 2 vì phụ thuộc thiết bị thật.

**Phương án khác**: (a) chỉ làm Tier A (bỏ Tier B) — mất nhánh "tải model" là nội dung chính của mockup `scan-10`/`scan-11`; (b) bỏ cả hai — phải sửa spec.

**Cần kiểm chứng lại khi thi công chặng 2**: phiên bản + tính khả dụng thực tế của `com.google.mlkit:genai-prompt` và `flutter_gemma`; URL/định dạng model Gemma 3n; dung lượng và thời gian tải thật.

**Kết quả kiểm chứng (2026-09-13, khi thi công chặng 2)**:
- `com.google.mlkit:genai-prompt` — bản mới nhất **`1.0.0-beta4`**; API thật là `Generation.getClient()` → `generateContent(prompt)` (suspend) → `response.candidates.first().text`. Package `com.google.mlkit.genai.prompt`. **Yêu cầu minSdk 26** ⇒ đã nâng `minSdk = maxOf(flutter.minSdkVersion, 26)`. `android/app` biên dịch được (verify bằng `flutter build apk --debug`).
- `flutter_gemma` — bản **1.8.1**, nhưng **engine là package riêng, phải cài thêm**: `flutter_gemma_litertlm` (`.litertlm`) hoặc `flutter_gemma_mediapipe` (`.task`/`.bin`); `FlutterGemma.initialize(inferenceEngines: [LiteRtLmEngine()])`. Đã chọn **`.litertlm`** (hướng Google đang đẩy cho Gemma 3n). API dùng: `installModel(...).fromNetwork(url).withProgress(cb).withCancelToken(t).install()`, `getActiveModel(maxTokens:)` → `createSession()` → `addQueryChunk(Message.text(...))` → `getResponse()`, `getStorageInfo().totalSizeBytes`, `uninstallModel` + `clearActiveInferenceIdentity`.
- ⚠ **Model Gemma 3n E2B trên HuggingFace là GATED** (cần token) ⇒ **chưa có nguồn phân phối công khai** cho bản phát hành. Hiện `kGemmaModelUrl` trỏ repo `litert-community/...` không kèm token ⇒ lượt tải thất bại và người dùng ở lại Chế độ cơ bản (đúng FR-012, không vỡ luồng). **Việc còn lại của chặng 2**: chốt nguồn công khai (tự host / repo không gated). Chưa đo được dung lượng/thời gian tải thật (không có thiết bị + không có token).
- Hệ quả kích thước: `app-debug.apk` tăng do native libs của LiteRT-LM (build debug sau chặng 2 ≈ 342 MB cho mọi ABI) — cần đo lại **release + split-per-abi** trước khi phát hành.

## R19 — Chiến lược kiểm thử

**Quyết định**: đẩy tối đa logic sang hàm thuần Dart (parser, từ điển, phân loại tier, parse số tiền, tìm trùng, `ScanSettings` ⇄ rows) và mọi thứ chạm plugin (camera, ML Kit, `device_info_plus`, kênh native, file) đi qua **seam bơm fake** — nếp đã dùng cho `WalletRepository`/`UtilitiesStore`. Test widget cho cả 5 màn mới; QA tay (quickstart) phủ phần không thể tự động: camera thật, ML Kit thật, quyền hệ điều hành, tương phản dark mode.

**Lý do**: `flutter_test` không có camera/ML Kit/native ⇒ nếu không tách seam thì cả luồng không test được (bài học PBI 7 với drift, PBI 3 với secure storage).

**Phương án khác**: integration_test với emulator thật — chậm, không chạy được ML Kit trong CI, ngoài nếp repo.

---

## Điểm còn `NEEDS CLARIFICATION`

Không còn. Các mục chưa chốt cứng (phiên bản package LLM, URL model Tier B, ngưỡng `supportsGpuDelegate` thực tế) đều thuộc **chặng 2** và đã ghi rõ là "kiểm chứng lại khi thi công" — không chặn chặng 1.
