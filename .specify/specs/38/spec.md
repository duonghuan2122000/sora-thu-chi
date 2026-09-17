# Đặc tả tính năng: Cập nhật giao diện màn Thêm giao dịch

**Mã PBI**: 38
**Ngày tạo**: 2026-09-17
**Trạng thái**: Nháp

## Mô tả tổng quan

Cập nhật giao diện màn "Thêm giao dịch" theo mockup mới (`02-them-giao-dich-v2.svg`): thay bàn phím số tùy chỉnh trong app bằng bàn phím số của thiết bị khi nhập Số tiền, bổ sung 2 trường tùy chọn mới — Tag và Ảnh hóa đơn — và mở rộng ô Ghi chú nhờ khoảng trống bàn phím tùy chỉnh đã bỏ.

## Kịch bản & luồng người dùng

### Luồng chính

Người dùng mở màn Thêm giao dịch (từ FAB) → chọn Chi/Thu → chạm ô Số tiền, bàn phím số của thiết bị hiện lên và gõ số tiền → chọn Danh mục/Ví/Ngày giờ như hiện tại → (tùy chọn) chạm dòng Tag → mở màn chọn tag, chọn tag có sẵn hoặc gõ tạo tag mới → quay lại màn Thêm giao dịch, dòng Tag hiển thị tag đã chọn → (tùy chọn) chạm dòng Ảnh hóa đơn → chụp ảnh mới hoặc chọn từ thư viện → ảnh xem trước hiện tại dòng đó → (tùy chọn) gõ Ghi chú vào ô đã rộng hơn → bấm "Lưu giao dịch".

### Kịch bản chấp nhận

1. Given màn Thêm giao dịch đang mở, when người dùng chạm ô Số tiền, then bàn phím số của thiết bị hiện lên (không phải bàn phím tùy chỉnh vẽ trong app).
2. Given người dùng chạm dòng Tag, when màn chọn tag mở ra và chưa có tag nào tồn tại, then người dùng vẫn gõ được tên tag mới và tạo ngay tại màn đó.
3. Given người dùng đã chọn một hoặc nhiều tag ở màn chọn tag, when quay lại màn Thêm giao dịch, then dòng Tag hiển thị các tag đã chọn thay cho gợi ý mặc định "Thêm tag (tùy chọn)".
4. Given người dùng chạm dòng Ảnh hóa đơn, when chọn "Chụp ảnh" hoặc "Chọn từ thư viện" và hoàn tất, then ảnh xem trước (thumbnail) hiện ngay tại dòng đó.
5. Given người dùng không nhập Tag lẫn Ảnh hóa đơn, when bấm "Lưu giao dịch" với các trường bắt buộc đã đủ, then giao dịch vẫn lưu thành công.
6. Given người dùng chọn tab "Chuyển khoản", when màn chuyển khoản nội bộ mở ra, then không xuất hiện dòng Tag/Ảnh hóa đơn — luồng chuyển khoản giữ nguyên như hiện tại.

### Trường hợp biên

- Từ chối quyền camera/thư viện ảnh khi đính kèm Ảnh hóa đơn → báo cho người dùng biết, không chặn việc lưu giao dịch (trường tùy chọn).
- Gõ tên tag trùng với tag đã có (khác hoa/thường, khác khoảng trắng thừa) → nhận diện là cùng một tag, không tạo bản trùng lặp.
- Tên tag rỗng hoặc chỉ toàn khoảng trắng → không cho tạo tag.
- Rời màn chọn tag mà không xác nhận lựa chọn (bấm back) → tag của giao dịch giữ nguyên như trước khi mở màn.
- Đã đính kèm ảnh hóa đơn rồi đổi ý → cho phép thay ảnh khác hoặc gỡ bỏ trước khi lưu.

## Yêu cầu chức năng

- **FR-001**: Hệ thống PHẢI cho người dùng nhập Số tiền bằng bàn phím số của thiết bị, thay cho bàn phím số tùy chỉnh vẽ riêng trong app.
- **FR-002**: Ô Số tiền PHẢI tiếp tục thể hiện màu sắc theo ngữ cảnh loại giao dịch (Thu/Chi) như quy tắc màu hiện có.
- **FR-003**: Hệ thống PHẢI cho phép người dùng gắn một hoặc nhiều tag cho giao dịch thông qua một màn chọn tag riêng.
- **FR-004**: Màn chọn tag PHẢI hiển thị danh sách tag đã từng tạo để người dùng chọn nhanh, tránh gõ lại.
- **FR-005**: Màn chọn tag PHẢI cho phép tạo tag mới ngay tại chỗ khi tag cần dùng chưa tồn tại.
- **FR-006**: Hệ thống PHẢI lưu các tag đã chọn vào giao dịch khi người dùng bấm "Lưu giao dịch".
- **FR-007**: Hệ thống PHẢI cho phép đính kèm một ảnh hóa đơn cho giao dịch bằng cách chụp ảnh mới hoặc chọn ảnh có sẵn từ thư viện.
- **FR-008**: Sau khi đính kèm, hệ thống PHẢI hiển thị ảnh xem trước tại dòng Ảnh hóa đơn, và cho phép thay đổi hoặc gỡ ảnh trước khi lưu giao dịch.
- **FR-009**: Trường Tag và Ảnh hóa đơn PHẢI là tùy chọn — không nhập vẫn lưu giao dịch được bình thường.
- **FR-010**: Ô Ghi chú PHẢI cho không gian nhập rộng hơn (nhiều dòng hơn) so với hiện tại, tận dụng khoảng trống do bỏ bàn phím số tùy chỉnh.
- **FR-011**: Các dòng Tag và Ảnh hóa đơn CHỈ áp dụng cho giao dịch loại Chi/Thu; luồng Chuyển khoản nội bộ giữ nguyên như hiện tại, không có 2 trường này.

## Tiêu chí thành công

- **SC-001**: Người dùng nhập số tiền bằng thao tác bàn phím quen thuộc của thiết bị, không cần học cách dùng bàn phím riêng của app.
- **SC-002**: Người dùng gắn được tag cho một giao dịch chỉ qua 2 bước chạm (mở màn chọn tag → chọn hoặc tạo tag).
- **SC-003**: Người dùng đính kèm ảnh hóa đơn ngay trong lúc thêm giao dịch, không phải quay lại sửa sau đó.
- **SC-004**: Toàn bộ giao dịch Thu/Chi tạo mới có thể mang theo tag và/hoặc ảnh hóa đơn khi người dùng chọn nhập, và được lưu đúng như đã chọn.

## Thực thể chính

- **Tag**: tên tag (chuỗi ký tự người dùng đặt), dùng để gắn nhãn tự do cho giao dịch; một giao dịch có thể mang nhiều tag; tag được tái sử dụng giữa các giao dịch (không tạo trùng khi tên giống nhau, không phân biệt hoa/thường).
- **Giao dịch**: bổ sung khả năng ghi nhận Tag và Ảnh hóa đơn ngay tại thời điểm tạo mới (trước đây 2 trường này trong dữ liệu chỉ được hiển thị/lọc, chưa có nơi nhập).

## Giả định

- Ảnh hóa đơn dùng lại cơ chế chụp ảnh/chọn ảnh thư viện đã có sẵn trong app (từng dùng cho tính năng quét hóa đơn); không chạy nhận diện/OCR khi đính kèm ở màn này.
- Trước đây app chưa có nơi quản lý danh sách tag tập trung — danh sách tag gợi ý ở màn chọn tag lấy từ toàn bộ tag đã từng dùng trong các giao dịch.
- Vị trí (GPS) của giao dịch không đổi — vẫn ghi tự động khi có quyền, không thêm ô nhập tay ở màn này.
- Giao diện mới áp dụng cho màn Thêm giao dịch hiện tại; khi luồng "Sửa giao dịch" được xây ở PBI khác, nó sẽ dùng chung giao diện này.

## Ngoài phạm vi

- Xây mới nút/luồng "Sửa giao dịch" (mở màn này với dữ liệu có sẵn từ màn Chi tiết) — thuộc PBI riêng.
- Màn quản lý Tag độc lập (đổi tên, xóa, gộp tag đã tạo).
- Thêm ô nhập tay vị trí giao dịch.
- Thay đổi luồng Chuyển khoản nội bộ giữa các ví.
