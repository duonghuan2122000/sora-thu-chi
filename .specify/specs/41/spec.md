# Đặc tả tính năng: Thông báo đường dẫn file xuất báo cáo

**Mã PBI**: 41
**Ngày tạo**: 2026-09-17
**Trạng thái**: Đã làm rõ

## Mô tả tổng quan

Sau khi người dùng xuất báo cáo (PDF/Excel/CSV) từ màn Xuất báo cáo, app lưu tệp vào thư mục Tải xuống (Downloads) công khai của thiết bị và hiển thị thông báo cho biết đường dẫn/tên tệp đã lưu, trước khi mở bảng chia sẻ hệ thống như hiện tại. Người dùng biết chắc file nằm ở đâu để tự tìm lại bằng trình quản lý tệp, kể cả khi không chia sẻ tiếp qua bảng chia sẻ.

## Kịch bản & luồng người dùng

### Luồng chính

1. Người dùng ở màn Xuất báo cáo, chọn bộ lọc + định dạng (PDF/Excel/CSV), chạm nút "Xuất báo cáo".
2. App dựng tệp báo cáo, ghi tệp vào thư mục Tải xuống công khai của thiết bị.
3. App hiện thông báo (dạng SnackBar) cho biết tệp đã lưu và đường dẫn/tên tệp.
4. App mở bảng chia sẻ hệ thống với tệp vừa lưu, như hành vi hiện có.
5. Người dùng chọn chia sẻ tiếp hoặc đóng bảng chia sẻ — thông báo đường dẫn đã hiển thị ở bước 3 không phụ thuộc vào việc này.

### Kịch bản chấp nhận

1. **Given** người dùng đã chọn bộ lọc và định dạng hợp lệ, **When** chạm "Xuất báo cáo" và app tạo tệp thành công, **Then** app hiện thông báo chứa đường dẫn (hoặc tên tệp + thư mục) nơi tệp được lưu, trước khi bảng chia sẻ hệ thống mở ra.
2. **Given** thông báo đường dẫn đã hiện, **When** người dùng đóng bảng chia sẻ hệ thống mà không chọn ứng dụng nào, **Then** tệp vẫn tồn tại ở đường dẫn đã thông báo (không bị xoá).
3. **Given** app chưa được cấp quyền lưu trữ cần thiết trên thiết bị, **When** người dùng chạm "Xuất báo cáo", **Then** app xin quyền; nếu người dùng từ chối, app hiện thông báo lỗi phù hợp và không xuất tệp (không có thông báo đường dẫn giả).
4. **Given** việc tạo tệp báo cáo thất bại (lỗi dựng nội dung), **When** người dùng chạm "Xuất báo cáo", **Then** app hiện thông báo lỗi hiện có ("Không tạo được tệp báo cáo") và không hiện thông báo đường dẫn.

### Trường hợp biên

- Tên tệp trùng với tệp đã tồn tại trong Downloads (do xuất lặp lại cùng bộ lọc) → app không ghi đè âm thầm; tự thêm hậu tố phân biệt (ví dụ số thứ tự) vào tên tệp và thông báo đúng tên tệp thực tế đã lưu.
- Thiết bị hết dung lượng lưu trữ khi ghi tệp → app hiện thông báo lỗi lưu tệp, không mở bảng chia sẻ, không hiện thông báo đường dẫn.
- Chế độ ẩn số dư (Privacy mode) đang bật → cảnh báo hiện có về việc file xuất ra không được che số vẫn giữ nguyên; thông báo đường dẫn là thông báo bổ sung, không thay thế cảnh báo này.

## Yêu cầu chức năng

- **FR-001**: Khi xuất báo cáo thành công, hệ thống PHẢI ghi tệp báo cáo vào thư mục Tải xuống (Downloads) công khai của thiết bị thay vì chỉ giữ trong bộ nhớ tạm.
- **FR-002**: Hệ thống PHẢI hiện thông báo cho người dùng biết đường dẫn (hoặc thư mục + tên tệp) nơi tệp báo cáo được lưu, ngay sau khi ghi tệp thành công và trước khi mở bảng chia sẻ hệ thống.
- **FR-003**: Thông báo đường dẫn PHẢI hiển thị độc lập với việc người dùng có thao tác tiếp trên bảng chia sẻ hệ thống hay không (đóng bảng chia sẻ không thu hồi hoặc xoá thông báo/tệp).
- **FR-004**: Nếu tên tệp trùng với tệp đã tồn tại trong thư mục Tải xuống, hệ thống PHẢI tự sinh tên tệp không trùng (không ghi đè tệp cũ) và thông báo đúng tên tệp thực tế đã lưu.
- **FR-005**: Hệ thống PHẢI xin quyền lưu trữ cần thiết (nếu nền tảng yêu cầu) trước khi ghi tệp; nếu quyền bị từ chối, hệ thống PHẢI dừng lại và hiện thông báo lỗi phù hợp, không hiện thông báo đường dẫn.
- **FR-006**: Nếu quá trình dựng nội dung tệp báo cáo thất bại, hệ thống PHẢI giữ nguyên hành vi báo lỗi hiện có và không ghi tệp, không hiện thông báo đường dẫn.
- **FR-007**: Bảng chia sẻ hệ thống mở sau đó PHẢI dùng chính tệp đã ghi ở FR-001 (không dựng lại bytes riêng cho việc chia sẻ).

## Tiêu chí thành công

- **SC-001**: Sau khi xuất báo cáo thành công, 100% trường hợp người dùng nhìn thấy thông báo nêu rõ tệp đã lưu ở đâu, không cần chia sẻ tiếp mới biết.
- **SC-002**: Người dùng có thể mở trình quản lý tệp của thiết bị và tìm thấy đúng tệp báo cáo vừa xuất tại đường dẫn đã thông báo, trong 100% lần xuất thành công.
- **SC-003**: Không có trường hợp tệp bị ghi đè mất dữ liệu cũ khi xuất trùng tên trong cùng một phiên sử dụng.

## Giả định

- Nền tảng đích là Android/iOS như phần còn lại của app; trên nền tảng mà khái niệm "thư mục Downloads công khai" không áp dụng theo cách giống nhau (ví dụ giới hạn của iOS), app dùng thư mục tương đương gần nhất mà người dùng có thể truy cập qua ứng dụng Tệp/File của hệ điều hành.
- Thông báo dùng lại kiểu SnackBar đã có trong màn Xuất báo cáo (nhất quán với thông báo lỗi hiện có), không cần màn hình xác nhận riêng.
- Không yêu cầu nút hành động thêm (mở tệp/sao chép đường dẫn) trong thông báo — chỉ cần hiển thị thông tin đường dẫn; có thể bổ sung sau nếu người dùng phản hồi cần.
- Việc chuyển từ "chỉ giữ bytes trong RAM" sang "ghi tệp ra Downloads trước khi chia sẻ" là thay đổi được chấp nhận so với quyết định thiết kế trước đó của PBI 27, vì đây chính là yêu cầu cốt lõi của tính năng này.

## Ngoài phạm vi

- Quản lý/xoá các tệp báo cáo đã xuất trước đó từ trong app (không có màn "Lịch sử xuất báo cáo").
- Cho phép người dùng tuỳ chỉnh thư mục lưu tệp xuất báo cáo.
- Thêm nút "Mở tệp"/"Sao chép đường dẫn" ngay trong thông báo (có thể xem xét ở PBI sau).
