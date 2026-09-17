# Mô hình dữ liệu: PBI 38 — Cập nhật giao diện màn Thêm giao dịch

Không migration, không bump schema version. Toàn bộ cột dùng đã tồn tại từ schema v3 (`tags`, `receipt_image`) — PBI này chỉ mở seam ghi mà trước đây `addTransaction` luôn để trống (R3 cũ).

## Transaction (mở rộng cách ghi, không đổi cấu trúc)

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `tags` | `String` (cột `tags`, đã có v3) | Chuỗi tag phân tách `,`, trim khoảng trắng mỗi tag, không chứa `#`. Nay `addTransaction` ghi giá trị người dùng chọn ở `TagPickerScreen` thay vì luôn `''`. |
| `receiptImage` | `String` (cột `receipt_image`, đã có v3) | Đường dẫn tuyệt đối file ảnh đã copy vào `<appDocuments>/receipts/`. Nay `addTransaction` ghi giá trị này khi người dùng đính kèm ảnh ở màn Thêm giao dịch (trước đây chỉ `addScannedTransaction` ghi được). |

Luật hợp lệ giữ nguyên như `parseTags`/hiển thị màn Chi tiết đã có: rỗng = không có tag/ảnh → các dòng liên quan ẩn ở màn Chi tiết (không đổi).

## Tag (khái niệm nghiệp vụ — KHÔNG có bảng riêng)

Tag không phải thực thể lưu trữ độc lập; suy ra tại runtime bằng cách đọc cột `tags` của toàn bộ giao dịch hiện có, tách theo `parseTags`, gộp + khử trùng (so sánh không phân biệt hoa/thường, trim khoảng trắng thừa) để làm danh sách gợi ý ở `TagPickerScreen`.

| Thuộc tính (khái niệm) | Nguồn |
|---|---|
| Tên tag | Chuỗi con tách từ `transactions.tags` của mọi giao dịch |
| Trùng lặp | Khử trùng bằng so sánh chữ thường (`toLowerCase().trim()`); hiển thị theo dạng lần xuất hiện đầu tiên |

## Hàm thuần mới/mở rộng dự kiến (module `core/transaction`)

- `List<String> distinctTags(List<Transaction> transactions)` — gộp + khử trùng tag từ toàn bộ giao dịch (dùng `parseTags` có sẵn), phục vụ `TagPickerScreen`. Đặt cạnh `parseTags` trong `transaction_detail.dart` hoặc file tag riêng nếu file hiện tại đã dài — quyết định tại lúc thi công.
- `String joinTags(List<String> tags)` — nối list tag đã chọn thành chuỗi `,` để ghi cột `tags` (đối xứng với `parseTags`), trim + lọc rỗng trước khi nối.

## `WalletRepository.addTransaction` — chữ ký mới

```
Future<void> addTransaction({
  required int walletId,
  required TxnType type,
  required int amount,
  required Category category,
  required DateTime date,
  String note = '',
  String tags = '',          // MỚI — mặc định rỗng, tương thích lời gọi cũ
  String receiptImage = '',  // MỚI — mặc định rỗng, tương thích lời gọi cũ
});
```

Hai tham số mới có default `''` → mọi lời gọi hiện có (nếu có ở test/nơi khác) không cần sửa.
