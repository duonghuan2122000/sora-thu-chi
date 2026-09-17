# Đặc tả tính năng: Nhân bản giao dịch

**Mã PBI**: 40
**Ngày tạo**: 2026-09-17
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Cho phép người dùng tạo nhanh một giao dịch mới bằng cách sao chép toàn bộ dữ liệu từ một giao dịch đã có (trừ ngày giờ), thay vì nhập lại từ đầu. Phù hợp cho các khoản chi tiêu lặp lại không đủ đều đặn để đặt thành giao dịch định kỳ (VD: đổ xăng, đi chợ).

## Kịch bản & luồng người dùng

### Luồng chính

**Given** người dùng đang ở màn Chi tiết giao dịch của một giao dịch bất kỳ (Thu/Chi/Chuyển khoản)
**When** người dùng bấm nút "Nhân bản"
**Then** hệ thống mở màn nhập liệu tương ứng loại giao dịch gốc (màn Thêm giao dịch cho Thu/Chi, màn Chuyển tiền cho Chuyển khoản), điền sẵn toàn bộ dữ liệu từ giao dịch gốc ngoại trừ ngày giờ được đặt về thời điểm hiện tại, và người dùng có thể chỉnh sửa trước khi bấm Lưu để tạo bản ghi mới độc lập.

### Kịch bản chấp nhận

1. **Given** giao dịch gốc là khoản Chi "Đổ xăng" 100.000đ, ví "Tiền mặt", danh mục "Di chuyển", có tag "xăng" **When** người dùng bấm "Nhân bản" **Then** màn Thêm giao dịch mở ra ở chế độ Chi, điền sẵn số tiền 100.000đ, ví "Tiền mặt", danh mục "Di chuyển", tag "xăng", ngày giờ = hiện tại.
2. **Given** màn nhân bản đã mở với dữ liệu điền sẵn **When** người dùng bấm Lưu mà không sửa gì **Then** hệ thống tạo một giao dịch mới độc lập, giao dịch gốc không đổi, số dư ví cập nhật theo giao dịch mới.
3. **Given** màn nhân bản đã mở **When** người dùng sửa số tiền/danh mục/ví rồi Lưu **Then** bản ghi mới lưu theo giá trị đã sửa.
4. **Given** màn nhân bản đã mở **When** người dùng bấm back/hủy mà không Lưu **Then** không có giao dịch mới nào được tạo, giao dịch gốc không đổi.
5. **Given** giao dịch gốc là khoản Chuyển khoản giữa ví A → ví B **When** người dùng bấm "Nhân bản" **Then** màn Chuyển tiền mở ra, điền sẵn ví nguồn A, ví đích B, số tiền, ghi chú; ngày giờ = hiện tại.
6. **Given** giao dịch gốc thuộc một chuỗi giao dịch định kỳ **When** người dùng nhân bản **Then** bản ghi mới là giao dịch độc lập một lần, không gắn vào chuỗi định kỳ gốc.

### Trường hợp biên

- Giao dịch gốc có ảnh hóa đơn đính kèm: bản sao điền sẵn cùng ảnh (tham chiếu file có sẵn), người dùng có thể xóa/đổi ảnh trước khi lưu mà không ảnh hưởng ảnh của giao dịch gốc.
- Giao dịch gốc gắn với danh mục hoặc ví đã bị ẩn/xóa sau đó: áp dụng đúng hành vi hiện có của màn Thêm/Sửa giao dịch khi gặp danh mục/ví không còn khả dụng (không phát sinh quy tắc mới cho nhân bản).
- Người dùng nhân bản liên tiếp nhiều lần từ cùng một giao dịch gốc: mỗi lần tạo một bản ghi độc lập mới, không giới hạn số lần.

## Yêu cầu chức năng

- **FR-001**: Hệ thống PHẢI cho nút "Nhân bản" trên màn Chi tiết giao dịch hoạt động (không còn no-op) với mọi loại giao dịch (Thu/Chi/Chuyển khoản).
- **FR-002**: Khi bấm "Nhân bản", hệ thống PHẢI mở màn nhập liệu tương ứng loại giao dịch gốc ở chế độ tạo mới, KHÔNG được lưu bản ghi nào cho tới khi người dùng chủ động bấm Lưu.
- **FR-003**: Màn nhập liệu PHẢI được điền sẵn toàn bộ dữ liệu của giao dịch gốc (số tiền, ví/ví nguồn-đích, danh mục, ghi chú, tag, ảnh hóa đơn, vị trí), NGOẠI TRỪ ngày giờ được đặt về thời điểm hiện tại.
- **FR-004**: Người dùng PHẢI chỉnh sửa được mọi trường đã điền sẵn trước khi lưu, theo đúng hành vi và ràng buộc hiện có của màn Thêm giao dịch/Chuyển tiền.
- **FR-005**: Khi người dùng bấm Lưu, hệ thống PHẢI tạo một giao dịch mới độc lập; giao dịch gốc PHẢI giữ nguyên không đổi; số dư ví liên quan PHẢI cập nhật đúng theo giao dịch mới.
- **FR-006**: Nếu người dùng rời màn nhân bản mà không bấm Lưu, hệ thống KHÔNG được tạo bất kỳ bản ghi nào.
- **FR-007**: Nếu giao dịch gốc thuộc chuỗi giao dịch định kỳ, bản sao tạo ra PHẢI là giao dịch độc lập một lần, không gắn vào chuỗi định kỳ gốc.

## Tiêu chí thành công

- **SC-001**: Người dùng tạo được một giao dịch lặp lại từ giao dịch cũ mà không phải gõ lại số tiền/ví/danh mục/tag.
- **SC-002**: 100% trường dữ liệu của giao dịch gốc (trừ ngày giờ) được sao chép đúng sang màn nhân bản.
- **SC-003**: 0 trường hợp thao tác nhân bản (kể cả khi hủy giữa chừng) làm thay đổi dữ liệu hoặc số dư liên quan đến giao dịch gốc.

## Giả định

- Bản sao không kế thừa liên kết với chuỗi giao dịch định kỳ của giao dịch gốc — trở thành giao dịch độc lập, đúng tinh thần "phù hợp cho chi tiêu lặp lại không đủ đều đặn để làm giao dịch định kỳ" trong tài liệu nghiệp vụ gốc.
- Tính năng áp dụng cho cả 3 loại giao dịch (Thu/Chi/Chuyển khoản), tái dùng đúng màn nhập liệu theo loại đã có sẵn từ PBI 38 (Thêm giao dịch) và luồng Chuyển tiền hiện có, tương tự cách PBI 39 (Sửa giao dịch) đã tái dùng các màn này.
- Ảnh hóa đơn đính kèm khi nhân bản dùng chung tham chiếu file với giao dịch gốc cho tới khi người dùng đổi/xóa trên bản sao (không nhân bản vật lý file).

## Ngoài phạm vi

- Nhân bản hàng loạt nhiều giao dịch cùng lúc.
- Cho phép đặt ngày giờ khác ngày hiện tại ngay tại bước nhân bản (người dùng vẫn có thể tự sửa ngày giờ trong màn nhập liệu như một trường bình thường).
- Nhân bản kèm tạo giao dịch định kỳ tự động từ bản sao.
