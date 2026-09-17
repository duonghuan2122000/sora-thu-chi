# Quickstart kiểm thử tay: Sửa giao dịch (PBI 39)

Chạy `flutter run` trong `app/sora_thu_chi`, đăng nhập PIN nếu có bật khóa app.

## A. Sửa giao dịch Chi
1. Tab "Giao dịch" → chạm một giao dịch Chi bất kỳ → màn Chi tiết giao dịch.
2. Chạm "Sửa" → màn mở với tiêu đề "Sửa giao dịch", đủ dữ liệu cũ điền sẵn (số tiền, danh mục, ví, ngày giờ, ghi chú, tag, ảnh nếu có).
3. Đổi số tiền + ghi chú → chạm Lưu → quay lại màn Chi tiết, hiển thị đúng dữ liệu mới.
4. Vào Tổng quan/Danh sách ví áp dụng → số dư đã cập nhật đúng theo số tiền mới (không lệch, không nhân đôi).

## B. Đổi ví khi sửa
1. Mở lại giao dịch vừa sửa → Sửa → đổi trường Ví sang ví khác → Lưu.
2. Kiểm tra: ví cũ tăng lại đúng số tiền giao dịch cũ (hoàn tác), ví mới giảm đúng số tiền giao dịch hiện tại.

## C. Đổi loại Thu ⇄ Chi
1. Sửa một giao dịch Chi → đổi tab sang "Thu" → chọn lại danh mục Thu → Lưu.
2. Kiểm tra: giao dịch hiển thị đúng là Thu (dấu +, màu teal) ở danh sách/chi tiết; số dư ví cộng đúng thay vì trừ.

## D. Hủy khi đang sửa
1. Sửa một giao dịch → đổi 1 trường bất kỳ → bấm nút đóng (X) → hộp thoại "Hủy giao dịch?" xuất hiện.
2. Chọn "Hủy" ở hộp thoại → ở lại màn sửa, dữ liệu vừa đổi còn nguyên.
3. Mở lại, đổi trường rồi chọn "Thoát" → quay lại Chi tiết, dữ liệu **không** đổi (giữ bản gốc).

## E. Validate khi sửa
1. Sửa một giao dịch → xóa hết số tiền (còn 0) → Lưu → báo thiếu trường, không lưu, giao dịch gốc giữ nguyên.

## F. Sửa giao dịch Chuyển khoản
1. Mở một giao dịch Chuyển khoản (ví A → ví B) → Chi tiết giao dịch → Sửa.
2. Màn "Chuyển tiền giữa ví" mở với Từ ví/Đến ví/Số tiền/Ngày giờ/Ghi chú đã điền sẵn đúng giao dịch cũ.
3. Đổi số tiền → Xác nhận → quay lại Chi tiết, số tiền mới hiển thị đúng.
4. Kiểm tra số dư cả ví A lẫn ví B đều đúng (không lệch một phía).
5. Đổi Đến ví sang ví C → Xác nhận → kiểm tra ví B (đích cũ) trả lại đúng số tiền, ví C (đích mới) nhận đúng số tiền, ví A trừ đúng theo số tiền hiện tại.

## G. Không thoái lui giao dịch Thu/Chi thành Chuyển khoản
1. Sửa một giao dịch Chi bất kỳ → xác nhận tab "Chuyển khoản" không chọn được (ẩn hoặc khóa) trong lúc sửa.
