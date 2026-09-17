# Quickstart kiểm thử tay: PBI 43 — Chọn hành động cho bản sao lưu cũ

Chuẩn bị: máy/emulator đã có ít nhất 1 bản sao lưu thủ công và 1 bản tự động trong danh sách (Cài đặt → Sao lưu & Khôi phục → tạo 1 bản thủ công; bật tự động sao lưu hoặc chèn tay 1 file vào thư mục `backups/auto/`).

## A. Menu hành động hiện đúng, không tự làm gì

1. Mở màn "Sao lưu & Khôi phục", chạm vào 1 bản bất kỳ trong "CÁC BẢN SAO LƯU".
2. Kỳ vọng: bottom sheet hiện đúng 2 dòng "Chia sẻ file" và "Khôi phục từ bản này" — **không** có hành động nào chạy ngay lúc mở sheet.
3. Chạm ra ngoài sheet (hoặc vuốt xuống đóng) → sheet đóng, dữ liệu/danh sách không đổi.

## B. Chia sẻ bản thủ công

1. Mở lại menu hành động của bản thủ công → chọn "Chia sẻ file".
2. Kỳ vọng: khay chia sẻ hệ thống (share sheet) mở, đúng tên file của bản đã chọn.
3. Đóng khay chia sẻ → quay lại màn, dữ liệu ví/giao dịch không đổi.

## C. Chia sẻ bản tự động

1. Mở menu hành động của **bản tự động** (dòng có hiện đường dẫn nội bộ) → chọn "Chia sẻ file".
2. Kỳ vọng: khay chia sẻ vẫn mở bình thường như bản thủ công (không bị chặn vì là bản tự động).

## D. Khôi phục từ danh sách vẫn đủ bước bảo vệ

1. Mở menu hành động của 1 bản → chọn "Khôi phục từ bản này".
2. Kỳ vọng: hiện đúng bottom sheet xác nhận khôi phục đã có — tên file, ngày tạo, số liệu, banner cảnh báo coral, checkbox "Tôi hiểu và muốn tiếp tục" bắt buộc tick mới bật được nút khôi phục.
3. Xác nhận khôi phục → màn thành công, dữ liệu trên máy đã đổi theo file đã chọn.

## E. File bị thiếu

1. Xoá thủ công 1 file backup khỏi bộ nhớ máy (qua trình quản lý file) nhưng chưa mở lại màn để danh sách tự làm mới.
2. Mở menu hành động của đúng bản đó → chọn "Chia sẻ file" hoặc "Khôi phục từ bản này".
3. Kỳ vọng: hiện thông báo lỗi rõ ràng kiểu "Không tìm thấy file" (SnackBar/label lỗi có sẵn), app **không crash**, có thể quay lại thao tác khác bình thường.
