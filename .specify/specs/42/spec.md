# Đặc tả tính năng: Đường dẫn file tự động sao lưu

**Mã PBI**: 42
**Ngày tạo**: 2026-09-17
**Trạng thái**: Đã làm rõ

## Mô tả tổng quan

Màn "Sao lưu & Khôi phục" hiện chỉ hiển thị tên file, thời điểm và dung lượng của các bản sao lưu tự động — không cho người dùng biết file thực sự nằm ở thư mục nào trên máy. Bổ sung hiển thị đường dẫn (thư mục lưu) của file sao lưu tự động, ở mục "Sao lưu gần nhất" và trong danh sách "Các bản sao lưu", để người dùng biết chắc dữ liệu tự động sao lưu đang được giữ ở đâu.

## Kịch bản & luồng người dùng

### Luồng chính

1. Người dùng vào Cài đặt → "Sao lưu & Khôi phục".
2. Tại mục "Sao lưu gần nhất" (khi bản gần nhất là bản tự động), người dùng thấy thêm dòng đường dẫn/thư mục nơi file đó được lưu, cạnh thời điểm và số liệu tóm tắt đã có.
3. Trong danh sách "Các bản sao lưu", với mỗi bản gắn nhãn "Tự động", người dùng thấy thêm đường dẫn/thư mục lưu file đó cùng tên file, thời điểm, dung lượng đã có.

### Kịch bản chấp nhận

1. **Given** đã từng có ít nhất một bản sao lưu tự động, **When** người dùng mở màn "Sao lưu & Khôi phục", **Then** mục "Sao lưu gần nhất" hiển thị đường dẫn/thư mục của file sao lưu gần nhất nếu bản đó là tự động.
2. **Given** danh sách "Các bản sao lưu" có bản tự động, **When** người dùng nhìn vào từng mục trong danh sách, **Then** mỗi bản tự động hiển thị kèm đường dẫn/thư mục lưu file, không chỉ tên file.
3. **Given** bản sao lưu gần nhất là bản thủ công (không phải tự động), **When** người dùng mở màn hình, **Then** hành vi hiển thị của mục "Sao lưu gần nhất" giữ nguyên như hiện có (không bắt buộc thêm đường dẫn cho bản thủ công vì luồng thủ công đã qua bảng chia sẻ để người dùng tự chọn nơi lưu).
4. **Given** chưa từng có bản sao lưu tự động nào, **When** người dùng mở màn hình, **Then** không hiển thị đường dẫn nào (giữ nguyên trạng thái rỗng hiện có).

### Trường hợp biên

- Đường dẫn quá dài không vừa một dòng trên màn hình nhỏ → rút gọn hiển thị (ví dụ ở giữa) nhưng vẫn giữ đủ thông tin phần đầu/cuối để nhận diện thư mục.
- Bản sao lưu tự động đã bị dọn (xoay vòng do vượt số lượng tối đa giữ lại) → không còn xuất hiện trong danh sách, do đó không còn hiển thị đường dẫn của bản đó (đúng theo hành vi dọn dẹp hiện có).

## Yêu cầu chức năng

- **FR-001**: Khi mục "Sao lưu gần nhất" đang hiển thị thông tin của một bản sao lưu tự động, hệ thống PHẢI hiển thị thêm đường dẫn/thư mục nơi file đó được lưu trên máy.
- **FR-002**: Với mỗi bản sao lưu tự động trong danh sách "Các bản sao lưu", hệ thống PHẢI hiển thị đường dẫn/thư mục lưu file đó cùng các thông tin đã có (tên file, thời điểm, dung lượng).
- **FR-003**: Hệ thống KHÔNG được thay đổi hành vi hiển thị hiện có đối với bản sao lưu thủ công (không bắt buộc thêm đường dẫn cho bản thủ công).
- **FR-004**: Hệ thống PHẢI xử lý hợp lý trường hợp đường dẫn dài (rút gọn có kiểm soát) để không phá vỡ bố cục màn hình trên thiết bị màn hình nhỏ.

## Tiêu chí thành công

- **SC-001**: 100% bản sao lưu tự động hiển thị trong màn "Sao lưu & Khôi phục" (ở mục "Sao lưu gần nhất" và trong danh sách) đều kèm đường dẫn/thư mục lưu file.
- **SC-002**: Người dùng xác định được thư mục chứa file sao lưu tự động ngay trên màn hình, không cần thao tác thêm (không cần chạm vào từng mục để xem chi tiết).

## Giả định

- File sao lưu tự động hiện đang lưu trong bộ nhớ riêng (private) của ứng dụng (`app_documents/backups/auto/`), không phải thư mục công khai — trên phần lớn thiết bị Android/iOS, người dùng không thể duyệt tới thư mục này bằng ứng dụng Quản lý tệp thông thường của hệ điều hành. Mục tiêu của PBI này là **hiển thị đúng đường dẫn nội bộ** để người dùng biết/đối chiếu (ví dụ khi cần hỗ trợ kỹ thuật hoặc debug), không cam kết đường dẫn đó duyệt được từ ngoài app.
- Không đổi vị trí lưu file thực tế của tính năng tự động sao lưu (PBI 35) — chỉ bổ sung phần hiển thị thông tin đường dẫn đã có sẵn trong dữ liệu (`LocalBackupEntry.path`), không cần logic ghi file mới.
- Đường dẫn hiển thị là đường dẫn tuyệt đối đầy đủ tới file (bao gồm tên file), nhất quán với cách PBI 41 hiển thị đường dẫn file xuất báo cáo.

## Ngoài phạm vi

- Đổi nơi lưu file sao lưu tự động sang thư mục công khai (Downloads) — đây là quyết định thiết kế riêng của PBI 35 (lưu nội bộ, không mở bảng chia sẻ), không thay đổi ở PBI này.
- Thêm nút "Sao chép đường dẫn" hoặc "Mở thư mục chứa file".
- Thông báo (notification) đường dẫn ngay sau khi tự động sao lưu chạy xong — PBI này chỉ bổ sung hiển thị trong màn "Sao lưu & Khôi phục", không đụng tới cơ chế thông báo nền.
