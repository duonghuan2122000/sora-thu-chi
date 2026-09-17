# Mô hình dữ liệu: PBI 47 — Nhật ký trích xuất AI

## Bảng `ScanExtractionLogs` (drift, schema v11)

Đặt trong `lib/data/db/app_database.dart`, cạnh `ScanSessions` (dòng 96).

| Cột | Kiểu | Ràng buộc | Ghi chú |
|---|---|---|---|
| `id` | int | PK autoincrement | |
| `createdAt` | DateTime | not null | thời điểm phiên quét kết thúc |
| `imagePath` | text | nullable | ảnh gốc, copy vào `<appDocuments>/scan_logs/`; null nếu chưa kịp chụp ảnh (lỗi rất sớm) |
| `rawText` | text | nullable | văn bản OCR thô; null nếu OCR chưa chạy tới (lỗi trước OCR) |
| `extractionJson` | text | nullable | `ScanExtraction.toJson()` — kết quả AI đề xuất ban đầu; null nếu trích xuất lỗi hoàn toàn |
| `engine` | text | nullable | enum `ScanEngine` dạng text (ruleBased/geminiNano/gemma3nE2b), null nếu không xác định được engine trước khi lỗi |
| `outcome` | text | not null | enum: `saved` / `cancelled` / `error` |
| `finalValuesJson` | text | nullable | giá trị cuối user lưu (type/amount/date/category/description); chỉ có khi `outcome = saved` |
| `errorMessage` | text | nullable | thông điệp lỗi; chỉ có khi `outcome = error` |
| `eventsJson` | text | not null, default `'[]'` | mảng JSON các `ScanLogEvent` (xem dưới), đúng thứ tự thời gian |

**Luật hợp lệ**:
- `outcome = saved` ⇒ `finalValuesJson` khác null.
- `outcome = error` ⇒ `errorMessage` khác null.
- Không có ràng buộc khóa ngoại tới `transactions`/`scan_sessions` — nhật ký độc lập với vòng đời giao dịch (đúng trường hợp biên trong spec).

**Trần lưu trữ**: hằng số `kMaxScanLogs = 200` (đặt cạnh `kMaxNotifications`, `lib/core/notification/app_notification.dart` hoặc file tương ứng trong `lib/core/scan/`). Sau mỗi lần insert, trim theo `(createdAt DESC, id DESC)`, đồng thời xoá file tại `imagePath` của các dòng bị trim (nếu có).

## Kiểu `ScanLogEvent` (model Dart thuần, không phải bảng riêng)

Đặt tại `lib/core/scan/scan_log.dart`, cạnh `ScanExtraction` (`scan_result.dart`).

| Field | Kiểu | Ghi chú |
|---|---|---|
| `type` | enum `ScanLogEventType` | `edit` / `back` / `cancel` / `save` |
| `field` | String? | tên trường bị sửa (`type`/`amount`/`date`/`category`/`description`); null nếu `type != edit` |
| `fromValue` | String? | giá trị trước khi sửa (serialize dạng chuỗi hiển thị được) |
| `toValue` | String? | giá trị sau khi sửa |
| `atMillis` | int | mốc thời gian tương đối trong phiên (epoch millis) |

Serialize/deserialize qua `toJson()`/`fromJson()` giống pattern `ScanExtraction` (`scan_result.dart:112`).

## Kiểu `ScanLogSession` (model Dart thuần, bộ đệm trong luồng quét)

Đối tượng tạm giữ trong bộ nhớ suốt 1 phiên quét (tạo lúc `startScanFlow()`, ghi xuống DB 1 lần lúc kết thúc):

| Field | Kiểu | Ghi chú |
|---|---|---|
| `tempImagePath` | String? | đường dẫn ảnh tạm trong cache |
| `rawText` | String? | gán khi OCR xong |
| `extraction` | ScanExtraction? | gán khi trích xuất AI xong |
| `engine` | ScanEngine? | |
| `events` | List<ScanLogEvent> | tích lũy qua các lần sửa/back/cancel/save |

Phương thức `finish(outcome, {finalValues, errorMessage})` → build `ScanExtractionLogs` row, copy ảnh qua `ScanLogImageStore`, ghi DB, trim FIFO.

## Quan hệ với thực thể đã có

- Không sửa `ScanSessions`, `Transactions`, `Categories` — bảng mới hoàn toàn độc lập, tránh đụng luồng hiện có (đúng nguyên tắc "0 breaking change" đã thấy ở các PBI trước).
- `ScanExtraction`, `ScanEngine`, `TxnType` tái dùng nguyên trạng từ `lib/core/scan/scan_result.dart` — không định nghĩa lại.
