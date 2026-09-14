# Quickstart kiểm thử nhanh: Sao lưu & Khôi phục dữ liệu (PBI 35)

## 1. Chuẩn bị

- Máy/emulator đã có sẵn vài ví, danh mục, giao dịch (nếu DB trống, tạo tay vài giao dịch trước để thấy số liệu khác 0).
- Vào Cài đặt → mục mới **"Sao lưu & Khôi phục"**.

## 2. Sao lưu thủ công

1. Chạm **"Tạo bản sao lưu mới"** → thấy bottom sheet tóm tắt đúng số ví/danh mục/giao dịch hiện có.
2. Bỏ qua đặt mật khẩu, chạm **"Tạo & Chia sẻ"** → bảng chia sẻ hệ thống mở ra; chọn "Lưu vào máy"/hủy đều được, quay lại app thấy **màn thành công**.
3. Về màn chính, thẻ **"Sao lưu gần nhất"** đã cập nhật đúng thời điểm + số liệu vừa tạo.
4. Danh sách **"Các bản sao lưu"** có thêm 1 dòng mới, đúng tên file theo mẫu `thuchi_backup_YYYYMMDD_HHmmss.json`.

## 3. Sao lưu có mật khẩu

1. Lặp lại bước 2.1–2.2, lần này bật "Đặt mật khẩu bảo vệ file", nhập mật khẩu, tạo & chia sẻ.
2. Ghi lại file vừa tạo để dùng ở bước khôi phục bên dưới.

## 4. Tự động sao lưu

1. Bật công tắc **"Tự động sao lưu"**, chọn tần suất bất kỳ.
2. (Không cần chờ đúng lịch để QA tay) — xác nhận không có lỗi khi bật/tắt liên tục, cấu hình được giữ khi thoát vào lại màn.

## 5. Khôi phục — đường thành công

1. Chạm **"Chọn file khôi phục"**, chọn 1 file `.json` vừa tạo ở bước 2 (không mật khẩu).
2. Thấy bottom sheet xác nhận: tên file, thời điểm tạo, số liệu, **banner cảnh báo màu coral**.
3. Nút khôi phục **vô hiệu** khi chưa tick "Tôi hiểu và muốn tiếp tục" — xác nhận đúng.
4. Tick ô, nút bật, chạm khôi phục → thấy **màn thành công**, điều hướng về Tổng quan.
5. Đối chiếu dữ liệu trên Tổng quan khớp đúng số liệu đã sao lưu (không phải dữ liệu trước khi khôi phục).

## 6. Khôi phục — file có mật khẩu

1. Chọn file đã tạo ở bước 3.
2. Xác nhận hệ thống **yêu cầu nhập mật khẩu trước khi hiện bất kỳ số liệu nào**.
3. Nhập sai mật khẩu vài lần → vẫn cho thử lại, có độ trễ tăng dần.
4. Nhập đúng → tiếp tục luồng như bước 5.

## 7. File hỏng / không tương thích

1. Sửa tay 1 byte trong file `.json` đã tạo (làm sai checksum) rồi chọn khôi phục từ file đó → hệ thống chặn ngay, báo lỗi rõ ràng, **không** hiện bottom sheet xác nhận.
2. Sửa `meta.schema_version` trong file thành số lớn hơn hiện tại → chọn khôi phục → cảnh báo "không tương thích phiên bản", chặn khôi phục.

## 8. Safety-snapshot khi lỡ chọn nhầm file

1. Thực hiện lại bước 5 với một file backup **cũ hơn** dữ liệu hiện tại.
2. Sau khi khôi phục xong, kiểm tra thư mục nội bộ backup có thêm 1 bản "an toàn" chứa đúng dữ liệu **trước khi** ghi đè (đối chiếu số liệu).

## 9. Không đủ dung lượng khi tạo backup có ảnh

1. (Nếu có thể dựng môi trường gần đầy đĩa) tạo vài giao dịch có ảnh hóa đơn đính kèm, thử tạo backup khi máy gần hết dung lượng → xác nhận báo lỗi rõ ràng, **không** để lại file `.zip` dở dang trong danh sách.

## 10. English + theme Tối + màn hẹp

1. Đổi ngôn ngữ English, theme Tối — lặp lại nhanh bước 2 và bước 5, xác nhận nhãn dịch đúng, không tràn chữ ở cỡ chữ hệ thống lớn.
