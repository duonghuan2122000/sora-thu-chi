# Mô hình dữ liệu — PBI 24: Quét hóa đơn (AI)

**Mã PBI**: 24
**Liên kết spec**: [./spec.md](./spec.md) · **Nghiên cứu**: [./research.md](./research.md)
**Ngày tạo**: 2026-09-12

Đợt này **có** thay đổi schema: drift lên **v8** (thêm 1 cột + 1 bảng); ngoài ra dùng bảng key-value `AppSettings` sẵn có cho cài đặt quét (không migration). Mọi thực thể còn lại là **đại lượng tạm** sinh ra trong một lần quét (không lưu, trừ bản ghi phiên quét).

---

## 1. Bảng drift — thay đổi v8

### 1.1 `transactions` — thêm cột `source`

| Cột | Kiểu drift | Ghi chú |
|---|---|---|
| `source` | `textEnum<TxnSource>()`, default `manual` | **MỚI (v8)** — phân biệt giao dịch tạo qua quét (`aiScan`) với nhập thay (`manual`). Dòng cũ nhận `manual` |

Domain tương ứng (`lib/core/transaction/transaction.dart`): thêm `enum TxnSource { manual, aiScan }` + field `final TxnSource source` (mặc định `TxnSource.manual`) trên `Transaction`. **Chỉ đọc/ghi dữ liệu**; đợt này **không** hiển thị nhãn nguồn ở UI (spec: dùng để lọc/thống kê *về sau*).

### 1.2 `scan_sessions` — bảng **mới** (FR-034)

| Cột | Kiểu drift | Bắt buộc | Ghi chú |
|---|---|---|---|
| `id` | `integer().autoIncrement()` | ✅ | khóa chính |
| `imagePath` | `text()` | ✅ | đường dẫn ảnh hóa đơn đã copy vào kho (`<documents>/receipts/…`) |
| `rawText` | `text()` | ✅ | văn bản thô OCR trả về (dòng nối bằng `\n`) |
| `parsedJson` | `text()` | ✅ | kết quả trích xuất (số tiền/ngày/cửa hàng/danh mục + độ tin cậy từng trường) |
| `engine` | `textEnum<ScanEngine>()` | ✅ | `ruleBased` \| `geminiNano` \| `gemma3nE2b` — chế độ **đã dùng** cho lần quét này (AI lỗi → `ruleBased`) |
| `transactionId` | `integer().nullable()` | — | giao dịch đã tạo; `null` = chưa/chưa từng lưu |
| `createdAt` | `dateTime()` | ✅ | thời điểm quét |

Tên bảng drift = `scan_sessions`; class dòng = `ScanSessionsRow`. Không FK (bám nếp `category_id`/`transfer_group_id` — plain int).

### 1.3 Migration `v7 → v8`

```dart
if (from < 8) {
  await m.addColumn(transactions, transactions.source);   // default 'manual' cho mọi dòng cũ
  await m.createTable(scanSessions);                      // thuần tạo bảng, KHÔNG seed
}
```

- `source` có default ⇒ **không mất dữ liệu**, không cần backfill.
- `scan_sessions` **không seed** (giống `budgets` v6): lần mở đầu tiên bảng rỗng là đúng nghiệp vụ.
- DB tạo mới (`onCreate`): `m.createAll()` sinh cả 2 thứ với định nghĩa mới ⇒ không nhánh riêng.
- **Không** đụng `wallets`/`categories`/`budgets`/`AppSettings`; **không** chạy `build_runner` ngoài lần sinh `.g.dart` cho v8.

### 1.4 `AppSettings` — 4 key mới (không migration)

| Key | Giá trị | Ý nghĩa |
|---|---|---|
| `scanEnabled` | `'true'`/`'false'` | công tắc bật/tắt tính năng (FR-003). **Vắng mặt = tắt** |
| `scanEngineMode` | `'rule_based'`\|`'gemini_nano'`\|`'gemma_3n_e2b'` | chế độ AI đang dùng (FR-004). Vắng mặt = suy từ tier |
| `scanModelBytes` | số (chuỗi) | dung lượng model đang chiếm; `0`/vắng = chưa tải (FR-004) |
| `scanDeviceCheck` | JSON `DeviceCapability` | kết quả kiểm tra cấu hình + `checkedAt` (FR-008, hết hạn 30 ngày) |

Bảng `AppSettings` là key-value ⇒ **không** migration; row chỉ ghi khi người dùng đổi (write-through bám `UtilitiesPrefs`).

---

## 2. Thực thể domain (trong bộ nhớ, `lib/core/scan/`)

### 2.1 `ScanRect`, `ScanTextLine` — đầu vào của bộ luật (FR-018)

```dart
/// Vùng chữ trên ảnh, **chuẩn hoá 0..1** theo kích thước ảnh (gốc trên-trái).
class ScanRect { final double left, top, right, bottom; double get height; double get centerY; }

/// Một dòng chữ OCR đọc được.
class ScanTextLine { final String text; final ScanRect rect; }
```

**Bất biến**: toạ độ trong `[0,1]`; `right > left`, `bottom > top`. Chuẩn hoá ngay ở tầng OCR ⇒ mọi màn hiển thị (thu nhỏ hay ảnh gốc full) vẽ khoanh vùng bằng cùng một phép nhân tỉ lệ.

### 2.2 `ScanField<T>` + `FieldConfidence` (FR-026)

```dart
enum FieldConfidence { high, medium, low }

class ScanField<T> {
  final T? value;                 // null = không trích xuất được / để trống
  final FieldConfidence confidence;
  final ScanRect? rect;           // vùng chữ tương ứng để khoanh (null = không xác định)
  bool get isEmpty => value == null;
  bool get needsReview => value == null || confidence == FieldConfidence.low;
}
```

Nhãn hiển thị: `high` → teal trung tính "Độ tin cậy cao"; `medium` → xám trung tính "Độ tin cậy trung bình"; `needsReview` → **coral + "Kiểm tra lại"**.

### 2.3 `ScanExtraction` — kết quả trích xuất (đại lượng **tạm**)

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `type` | `TxnType` | luôn `expense` khi khởi tạo (FR-025), người dùng đổi ở màn xác nhận |
| `amount` | `ScanField<int>` | rỗng ⇒ **bắt buộc** nhập tay trước khi lưu (FR-021/FR-032) |
| `date` | `ScanField<DateTime>` | không tìm thấy ⇒ `now` + `low` (FR-022) |
| `merchant` | `ScanField<String>` | đổ vào **ghi chú** của giao dịch khi lưu (FR-031) |
| `category` | `ScanField<Category>` | gợi ý theo từ điển; rỗng ⇒ để trống, **không** tự tạo danh mục (FR-024) |
| `engine` | `ScanEngine` | chế độ đã dùng cho lần quét này |

```dart
enum ScanEngine { ruleBased, geminiNano, gemma3nE2b }
```

### 2.4 `ScanRecord` ⇄ `scan_sessions`

```dart
class ScanRecord {
  final String imagePath, rawText, parsedJson;
  final ScanEngine engine;
  final int? transactionId;
  final DateTime createdAt;
}
```

`parsedJson` = JSON của `ScanExtraction` (số tiền, ngày ISO, cửa hàng, `categoryId`, loại, độ tin cậy từng trường). Không cần `fromJson` ở chặng 1 (chưa có màn đọc lại) — **chỉ ghi**; `ponytail:` ghi chú trong code rằng đọc lại thuộc PBI Scan History.

### 2.5 `DeviceCapability` + `AiTier` (R6)

| Trường | Kiểu | Nguồn |
|---|---|---|
| `ramGb` | `int` | `device_info_plus` |
| `freeStorageGb` | `double` | kênh native `freeStorageGb` |
| `supportsOnDeviceAi` | `bool` | kênh native `supportsOnDeviceAi` (AICore, Android) |
| `supportsGpuDelegate` | `bool` | kênh native `supportsGpuDelegate` |
| `osVersion` | `String` | `device_info_plus` |
| `checkedAt` | `DateTime` | lúc đo |

```dart
enum AiTier { a, b, c }          // a = dùng được AI hệ thống ngay, b = phải tải model, c = chế độ cơ bản
AiTier classifyTier(DeviceCapability c);        // A nếu supportsOnDeviceAi; B nếu ram>=4 && free>=2 && gpuDelegate; còn lại C
bool isStale(DeviceCapability c, DateTime now, {int days = 30});   // FR-008
```

**Bất biến**: `classifyTier` là hàm **thuần**, chỉ phụ thuộc tham số; `fromJson` với JSON hỏng/rỗng → `null` (coi như chưa kiểm tra), **không ném**.

### 2.6 `ScanSettings` — trạng thái cài đặt (view của 4 key §1.4)

```dart
class ScanSettings {
  final bool enabled;                  // mặc định false
  final ScanEngine mode;               // chế độ AI đang dùng (mặc định ruleBased)
  final int modelBytes;                // 0 = chưa tải
  final DeviceCapability? deviceCheck; // null = chưa từng kiểm tra
  bool get needsDeviceCheck(DateTime now);  // null hoặc isStale(..., 30 ngày) → cần kiểm tra lại
  Map<String, String> toSettings();
  factory ScanSettings.fromSettings(Map<String, String> rows);
}
```

**Bất biến**: mọi chuỗi lạ/thiếu key → giữ mặc định an toàn (bám `UtilitiesPrefs._parseBool`), **không ném**; `modelBytes < 0` → `0`.

---

## 3. Hàm thuần (toàn bộ test được không cần plugin)

| Hàm | File | Vai trò |
|---|---|---|
| `int? parseVietnameseAmount(String)` | `receipt_parser.dart` | hiểu `55.000` / `55,000` / `55 000` / `55000` / `55.000đ`; loại `12.5`, loại số < 1000 khi không có nhóm nghìn |
| `ScanExtraction parseReceipt({lines, now, expenseCategories, incomeCategories})` | `receipt_parser.dart` | bộ luật FR-021…FR-026 (số tiền → dòng tổng; ngày → regex; merchant → chữ lớn đầu hóa đơn; danh mục → từ điển) |
| `String? suggestCategoryName(String merchant)` | `merchant_dictionary.dart` | tra từ điển (đã bỏ dấu/thường hoá) |
| `Category? resolveCategory(String? name, List<Category> active)` | `merchant_dictionary.dart` | tra tên → `Category` trong danh mục **đang hoạt động**; không có → `null` |
| `AiTier classifyTier(DeviceCapability)` / `bool isStale(...)` | `device_tier.dart` | phân loại tier + hết hạn 30 ngày |
| `Transaction? findRecentDuplicate(...)` | `scan_duplicate.dart` | FR-035 (±24h, cùng số tiền, bỏ transfer/adjustment) |
| `Future<Uint8List> preprocessForOcr(Uint8List, {int maxSide})` | `image_preprocess.dart` | sửa chiều EXIF + thu nhỏ + tăng tương phản; chạy qua `compute()` |

---

## 4. Luật bất biến (invariants) — dùng làm checklist test

1. **Không tự lưu**: mọi đường vào DB đều đi qua màn xác nhận + nút "Lưu giao dịch" (SC-004); không có mã nào gọi `addScannedTransaction` ngoài màn xác nhận.
2. **Một lần bấm = một giao dịch**: cờ `_saving` chặn bấm đúp (FR-032).
3. **Số tiền bắt buộc > 0**: `amount.value == null || <= 0` ⇒ nút lưu vô hiệu (FR-032/SC-011).
4. **Giao dịch quét**: `source == aiScan`, `receipt_image` khác rỗng, `category_id` có thể `null`, `note` = merchant (FR-031/FR-033).
5. **Phiên quét luôn có `transaction_id` sau khi lưu** (ghi trong cùng một transaction DB — R11); trước khi lưu **không có** bản ghi nào.
6. **Huỷ giữa luồng**: 0 giao dịch, 0 file ảnh trong kho đính kèm, 0 bản ghi phiên quét (FR-036).
7. **Không mạng**: ngoài bước tải model (chặng 2), mọi hàm chạy được khi tắt mạng hoàn toàn (SC-006/FR-037).
8. **Ảnh lưu chỉ khi lưu giao dịch** (`ScanImageStore.save` chỉ được gọi trong nhánh lưu).
9. **Tier C luôn dùng được**: `classifyTier` trả `c` không bao giờ chặn luồng (SC-008).
10. **Ngưỡng tier**: `ram = 4.0` và `free = 2.0` là **đạt** (biên đóng); `3.9`/`1.9` là không đạt.
11. **Kiểm tra cấu hình chỉ chạy lại** khi chưa có kết quả, quá 30 ngày, hoặc người dùng bấm "Kiểm tra lại" (FR-008/SC-010).
12. **Số tiền trích xuất**: chỉ lấy số ≥ 1000; số nằm trong dòng ngày/giờ/điện thoại/MST/số hóa đơn bị loại (tránh lấy `2026` hay số điện thoại làm số tiền).
13. **Danh mục gợi ý**: chỉ là danh mục **đang hoạt động**; không tự tạo danh mục mới; không ghi nhớ lựa chọn sửa (FR-024).
14. **Ví áp dụng**: mặc định ví mặc định đang hoạt động; không có ví hợp lệ ⇒ bắt chọn trước khi lưu, **không** tự bịa ví (FR-030).
15. **Cảnh báo trùng**: chỉ hiện khi có ca khớp; không hiện banner rỗng; **không chặn** lưu (FR-035).
16. **Số dư ví vẫn suy ra**: giao dịch quét chỉ bù `balance` theo loại như `addTransaction`; màn xác nhận không sửa số dư trực tiếp.
17. **Định dạng tiền**: mọi chỗ hiển thị số tiền dùng `formatMoney` (dấu chấm phân tách nghìn + `đ`).

---

## 5. Vòng đời dữ liệu — khi nào cái gì đổi

| Sự kiện | `transactions` | `scan_sessions` | `AppSettings` | File ảnh |
|---|---|---|---|---|
| Mở luồng quét | — | — | — | — |
| Chụp/chọn ảnh (ảnh tạm trong cache) | — | — | — | — |
| OCR + trích xuất xong | — | — | — | — |
| Bấm "Lưu giao dịch" | +1 dòng (`source = aiScan`) | +1 dòng (`transaction_id` vừa sinh) | — | +1 file trong `receipts/` |
| Huỷ / back giữa luồng | — | — | — | — |
| Bấm đúp nút lưu | +1 dòng (lần 2 bị chặn bởi `_saving`) | +1 dòng | — | +1 file |
| Bật/tắt công tắc Cài đặt | — | — | `scanEnabled` | — |
| Kiểm tra lại cấu hình máy | — | — | `scanDeviceCheck` | — |
| Chọn "Dùng chế độ cơ bản" | — | — | `scanEngineMode` | — |
| Tải/xoá model (chặng 2) | — | — | `scanEngineMode`, `scanModelBytes` | file model |

---

## 6. Không thuộc mô hình dữ liệu đợt này

- Bảng `merchant_category_mapping` (học theo người dùng — doc §4/§3.5): **GĐ2**, spec đã loại.
- Cột `source_type` của `scan_sessions` (doc §10.5) và liên kết 1 phiên quét → nhiều giao dịch: thuộc PBI mở rộng nguồn (SMS/sao kê).
- Trích xuất danh sách mặt hàng / mã số thuế: ngoài phạm vi.
- Đơn vị tiền tệ của giao dịch quét: hiểu theo đơn vị mặc định của app (đa tiền tệ vẫn là quyết định mở).
