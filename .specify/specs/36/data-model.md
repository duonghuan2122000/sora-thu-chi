# Mô hình dữ liệu: PBI 36 — Quét ảnh thông báo giao dịch ngân hàng

Không có bảng/cột DB mới (R9) — thay đổi duy nhất nằm ở **cấu trúc trong bộ nhớ** `ScanExtraction` (đã có từ PBI 24) và nội dung JSON nó sinh ra.

## `ScanExtraction` (mở rộng)

| Trường | Kiểu | Thay đổi | Ghi chú |
|---|---|---|---|
| `type` | `TxnType` | không đổi kiểu | Nay có thể là `TxnType.income` ngay từ khi trích xuất (trước đây luôn `expense`) |
| `typeNeedsReview` | `bool` | **mới**, mặc định `false` | `true` khi bộ luật/AI không đủ căn cứ suy loại GD — màn xác nhận hiển thị "Kiểm tra lại" dưới ô Loại giao dịch |
| `amount`, `date`, `category`, `engine` | *(không đổi)* | | |
| `merchant` | `ScanField<String>` | không đổi kiểu | Với ảnh ngân hàng: chứa nội dung/người nhận-gửi thay vì tên cửa hàng (tái dùng field, R5) |

`copyWith` thêm tham số `typeNeedsReview`. `toJson()` thêm khoá `'typeNeedsReview': typeNeedsReview` (khoá `'type'` đã có sẵn, nay giá trị có thể là `'income'`).

## Hàm mới — `lib/core/scan/bank_notif_parser.dart`

| Hàm | Chữ ký | Vai trò |
|---|---|---|
| `looksLikeBankNotification` | `bool Function(List<ScanTextLine> lines)` | Phát hiện ảnh ngân hàng (R2) — thuần, không side-effect |
| `parseBankNotification` | `ScanExtraction Function({required List<ScanTextLine> lines, required DateTime now, required List<Category> expenseCategories, required List<Category> incomeCategories})` | Trích xuất số tiền/loại GD/ngày/ghi chú theo bộ luật R3–R6; chữ ký khớp `parseReceipt` để 2 hàm hoán đổi được trong dispatcher |

Không có class/enum mới — tái dùng toàn bộ `ScanRect`/`ScanTextLine`/`FieldConfidence`/`ScanField<T>`/`ScanEngine` sẵn có.

## Luật bất biến bổ sung

1. `typeNeedsReview == true` **chỉ** khi bộ luật/AI không tìm được tín hiệu ghi nợ/ghi có/chuyển tiền rõ ràng — không bao giờ bật cờ này cho hóa đơn cửa hàng (nhánh `parseReceipt` luôn trả `typeNeedsReview = false`, giữ đúng hành vi cũ).
2. `parseBankNotification` không bao giờ trả `type == TxnType.transfer` hay `TxnType.adjustment` (FR-004) — chỉ `income`/`expense`.
3. Số tiền được chọn bởi `parseBankNotification` không bao giờ đến từ dòng/vị trí chứa từ khoá "so du" (R3) — bất biến kiểm chứng được bằng test trên mọi fixture.
4. `merchant`/ghi chú của ảnh ngân hàng không bắt buộc phải có giá trị — rỗng vẫn hợp lệ (giống hóa đơn hiện tại), không chặn lưu.

## Vòng đời

Không đổi vòng đời sẵn có của PBI 24: `ScanExtraction` là đại lượng tạm, chỉ sống trong luồng chụp → xử lý → xác nhận; chỉ `toJson()` của nó (nay có thêm `typeNeedsReview`) được ghi vào `scan_sessions.parsed_json` tại thời điểm lưu giao dịch.
