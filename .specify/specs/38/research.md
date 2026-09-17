# Nghiên cứu kỹ thuật: PBI 38 — Cập nhật giao diện màn Thêm giao dịch

## 1. Bàn phím số cho ô Số tiền

- **Quyết định**: Thay `AmountKeypad` (numpad tự vẽ) bằng `TextField(keyboardType: TextInputType.number)` hệ thống, dùng `TextInputFormatter` để giữ giá trị là số nguyên VND và hiển thị đã format dấu chấm nghìn (tái dùng `formatMoney`).
- **Lý do**: Đúng theo mockup `02-them-giao-dich-v2.svg` (R mới); giảm code tự vẽ, tận dụng bàn phím hệ điều hành người dùng đã quen; `appendAmountDigit`/`backspaceAmount` (`add_form.dart`) vẫn tái dùng được làm logic thuần xử lý chuỗi số nhập vào nếu cần chặn tràn `maxDigits`.
- **Phương án khác đã xem xét**: Giữ nguyên numpad tự vẽ + chỉ thêm 2 trường mới — bị loại vì lệch mockup mới, đây là yêu cầu chính của PBI.
- **Dọn dẹp kèm theo**: `AmountKeypad` (`lib/core/widgets/amount_keypad.dart`) không còn nơi nào dùng sau khi màn Thêm giao dịch đổi qua TextField → xóa file + test liên quan (không để lại dead code).

## 2. Lưu trữ Tag

- **Quyết định**: Không thêm bảng/migration mới. Cột `transactions.tags` (chuỗi phân tách `,`, có sẵn từ schema v3) tiếp tục là nơi lưu; danh sách "tag đã có" để gợi ý ở màn chọn tag lấy bằng cách đọc toàn bộ `tags` của các giao dịch hiện có, `parseTags` (đã có ở `transaction_detail.dart`) rồi gộp + khử trùng (không phân biệt hoa/thường, trim khoảng trắng).
- **Lý do**: Dữ liệu cá nhân, số giao dịch nhỏ (offline, 1 người dùng/máy) — quét toàn bộ bảng để suy ra tag duy nhất là đủ nhanh, không cần bảng `tags` riêng + khóa ngoại + migration (ponytail: YAGNI, tránh over-engineering cho tính năng phụ).
- **Phương án khác đã xem xét**: Bảng `tags` riêng + bảng nối `transaction_tags` (chuẩn hóa quan hệ nhiều-nhiều) — bị loại vì tốn 1 lần bump schema version + 2 bảng mới cho lợi ích không rõ ở quy mô dữ liệu này; để dành nếu sau này cần sửa/xóa tag hàng loạt (ngoài phạm vi PBI, đã ghi trong spec "Ngoài phạm vi").
- **Chuẩn hóa khi lưu**: nối tag đã chọn bằng `,` giống định dạng `parseTags` đọc ra, để tương thích màn Chi tiết/lọc đã có (không đổi định dạng cột).

## 3. Đính kèm Ảnh hóa đơn

- **Quyết định**: Dùng `ImagePicker().pickImage(source: ImageSource.camera | .gallery)` (package `image_picker` đã là dependency, đang dùng ở `scan_camera_screen.dart` cho đường thư viện) để lấy ảnh, sau đó lưu vào kho đính kèm bằng seam có sẵn `ScanImageStore`/`LocalScanImageStore` (`lib/core/scan/scan_image_store.dart`, ghi vào `<appDocuments>/receipts/<millis>.jpg`). Không chạy OCR/nhận diện — chỉ lưu đường dẫn vào cột `transactions.receipt_image` (đã có từ schema v3).
- **Lý do**: 0 dependency mới; tái dùng đúng seam đã kiểm thử của luồng quét hóa đơn (PBI 24) cho một nhu cầu nhỏ hơn (chỉ đính kèm, không phân tích); nhất quán nơi lưu file ảnh hóa đơn trong app (cùng thư mục `receipts/`).
- **Phương án khác đã xem xét**: Dựng lại `ScanCameraScreen` (camera preview tự vẽ dùng cho luồng quét OCR) — bị loại vì nặng hơn nhu cầu (không cần chỉ báo độ tin cậy, không cần preprocess ảnh cho OCR); `ImagePicker` hỗ trợ sẵn cả `ImageSource.camera` (mở camera hệ thống) lẫn `.gallery`, đủ cho use-case "chụp ảnh hoặc chọn từ thư viện" của FR-007.
- **Dọn khi hủy**: nếu người dùng thoát màn Thêm giao dịch mà không lưu giao dịch, ảnh đã copy vào `receipts/` phải bị xóa (dùng `ScanImageStore.delete`, đã có sẵn) — tránh rác file mồ côi, bám đúng nguyên tắc R12 đã áp dụng cho luồng quét OCR.

## 4. Màn chọn Tag (mới)

- **Quyết định**: Thêm 1 màn `TagPickerScreen` mới, theo đúng khuôn mẫu `CategoryPickerScreen` (Scaffold riêng app bar teal + back, danh sách chọn nhiều — checkbox/chip, ô nhập tạo tag mới ở cuối danh sách, nút xác nhận `pop(List<String>)`).
- **Lý do**: Chốt 2B trong hội thoại đặc tả (spec §Giả định) — màn riêng, không phải hộp thoại gõ tự do; tái dùng bố cục/khuôn mẫu đã có (app bar, list tile, style) để giữ nhất quán design system và giảm code mới.
- **Phương án khác đã xem xét**: Bottom sheet thay vì `Scaffold` toàn màn — cân nhắc nhưng chọn full-screen theo đúng pattern `CategoryPickerScreen` hiện có của cùng màn cha (Thêm giao dịch), tránh 2 kiểu điều hướng khác nhau cho 2 trường tương tự.

## 5. Ghi mở rộng `addTransaction`

- **Quyết định**: Thêm 2 tham số tùy chọn `tags` (String, default `''`) và `receiptImage` (String, default `''`) vào `WalletRepository.addTransaction` — ghi thẳng vào `TransactionsCompanion.insert(...)` cùng transaction atomic hiện có (không tách lệnh ghi riêng).
- **Lý do**: Cột đã tồn tại từ schema v3, `addScannedTransaction` đã minh họa cách ghi `receiptImage` — chỉ mở rộng chữ ký hàm hiện có, không cần hàm/API mới.
- **Phương án khác đã xem xét**: Hàm `addTransaction` riêng biệt có tag/ảnh — bị loại vì trùng lặp logic bù số dư + insert với bản gốc, vi phạm nguyên tắc tránh trùng lặp.
