# Đặc tả tính năng: Sửa giao dịch

**Mã PBI**: 39
**Ngày tạo**: 2026-09-17
**Trạng thái**: Nháp

## Mô tả tổng quan

Cho phép người dùng chỉnh sửa một giao dịch (Thu/Chi/Chuyển khoản) đã ghi nhận, sửa lại các trường dữ liệu và lưu đè lên giao dịch cũ, thay vì phải xóa rồi nhập lại từ đầu. Nút "Sửa" ở màn Chi tiết giao dịch hiện đang là điểm vào chờ (no-op) — PBI này nối nó với luồng sửa thật.

## Kịch bản & luồng người dùng

### Luồng chính

1. Người dùng mở một giao dịch từ màn Danh sách hoặc Chi tiết giao dịch.
2. Chạm nút "Sửa" ở màn Chi tiết giao dịch.
3. Hệ thống mở lại màn nhập giao dịch, điền sẵn toàn bộ dữ liệu hiện có (loại, số tiền, danh mục/cặp ví chuyển khoản, ví, ngày giờ, ghi chú, tag, ảnh hóa đơn), tiêu đề đổi thành "Sửa giao dịch".
4. Người dùng chỉnh sửa một hoặc nhiều trường, chạm "Lưu".
5. Hệ thống kiểm tra hợp lệ như khi thêm mới, cập nhật giao dịch, quay lại màn Chi tiết giao dịch hiển thị dữ liệu đã sửa.

### Kịch bản chấp nhận

1. **Given** một giao dịch Chi đã có, **When** người dùng sửa số tiền và ghi chú rồi lưu, **Then** giao dịch được cập nhật với giá trị mới; số dư ví liên quan phản ánh đúng thay đổi (vì số dư là đại lượng suy ra từ giao dịch).
2. **Given** một giao dịch Chi, **When** người dùng đổi Ví áp dụng sang ví khác rồi lưu, **Then** giao dịch chuyển sang thuộc ví mới; số dư cả ví cũ lẫn ví mới được tính lại đúng.
3. **Given** một giao dịch Thu, **When** người dùng đổi loại sang Chi (hoặc ngược lại) rồi lưu, **Then** hệ thống lưu đúng loại mới cùng danh mục tương ứng loại đó.
4. **Given** một giao dịch Chuyển khoản nội bộ, **When** người dùng sửa số tiền hoặc đổi ví nguồn/đích rồi lưu, **Then** cả hai phía ghi nhận (ví nguồn, ví đích) được cập nhật nhất quán; validate ví nguồn ≠ ví đích vẫn áp dụng.
5. **Given** đang sửa giao dịch và đã thay đổi dữ liệu, **When** người dùng thoát màn mà chưa lưu, **Then** hệ thống hỏi xác nhận bỏ thay đổi trước khi thoát (nhất quán với màn Thêm giao dịch).
6. **Given** đang sửa giao dịch, **When** người dùng bỏ trống trường bắt buộc (số tiền, danh mục/ví hoặc cặp ví chuyển khoản) rồi chạm Lưu, **Then** hệ thống báo lỗi và không lưu, giữ nguyên giao dịch gốc.

### Trường hợp biên

- Sửa giao dịch mà không thay đổi gì rồi chạm Lưu: hệ thống vẫn lưu bình thường (coi như không đổi), không báo lỗi.
- Sửa giao dịch có đính kèm ảnh hóa đơn: giữ nguyên ảnh nếu không đổi; cho phép thay ảnh khác hoặc gỡ ảnh.
- Sửa giao dịch có nguồn gốc từ quét hóa đơn AI: vẫn sửa được như giao dịch nhập tay bình thường, không có ràng buộc thêm.
- Sửa số tiền giao dịch Chuyển khoản khiến ví nguồn âm quỹ: cảnh báo mềm, không chặn cứng (nhất quán quy tắc thêm mới).

## Yêu cầu chức năng

- **FR-001**: Nút "Sửa" ở màn Chi tiết giao dịch PHẢI mở màn nhập giao dịch với toàn bộ dữ liệu hiện tại của giao dịch được điền sẵn.
- **FR-002**: Tiêu đề màn nhập liệu PHẢI hiển thị "Sửa giao dịch" khi ở chế độ sửa (phân biệt với "Thêm giao dịch").
- **FR-003**: Người dùng PHẢI sửa được tất cả các trường đã có ở màn thêm giao dịch: loại giao dịch, số tiền, danh mục (hoặc cặp ví nguồn/đích nếu là chuyển khoản), ví áp dụng, ngày giờ, ghi chú, tag, ảnh hóa đơn.
- **FR-004**: Hệ thống PHẢI áp dụng đúng các quy tắc kiểm tra hợp lệ hiện có của màn thêm giao dịch (số tiền > 0, danh mục/ví bắt buộc, ví nguồn ≠ ví đích khi chuyển khoản) khi lưu sửa.
- **FR-005**: Khi lưu, hệ thống PHẢI cập nhật đúng giao dịch đã chọn (không tạo thêm giao dịch mới), và số dư các ví liên quan (cũ và mới nếu đổi ví) PHẢI được tính lại chính xác.
- **FR-006**: Nếu người dùng thoát màn sửa khi đã có thay đổi chưa lưu, hệ thống PHẢI hỏi xác nhận trước khi bỏ thay đổi.
- **FR-007**: Sau khi lưu thành công, hệ thống PHẢI quay lại màn Chi tiết giao dịch và hiển thị đúng dữ liệu vừa sửa.
- **FR-008**: Sửa giao dịch Chuyển khoản PHẢI cập nhật nhất quán cả hai chiều ghi nhận (ví nguồn và ví đích) trong cùng một lần lưu.

## Tiêu chí thành công

- **SC-001**: Người dùng sửa xong và lưu một giao dịch trong dưới 30 giây kể từ khi mở màn Chi tiết giao dịch.
- **SC-002**: 100% giao dịch sau khi sửa hiển thị đúng dữ liệu mới ở cả màn Chi tiết lẫn màn Danh sách giao dịch, không phát sinh giao dịch trùng lặp.
- **SC-003**: Số dư ví liên quan luôn khớp chính xác với tổng giao dịch sau khi sửa (không lệch số học) trong mọi trường hợp đổi ví/đổi số tiền/đổi loại giao dịch.

## Thực thể chính

- **Giao dịch**: bản ghi thu/chi/chuyển khoản đã tồn tại — PBI này chỉ cập nhật (update) bản ghi hiện có, không đổi cấu trúc dữ liệu.

## Giả định

- Tái sử dụng nguyên màn "Thêm giao dịch" hiện có cho cả hai chế độ (thêm/sửa), chỉ khác dữ liệu điền sẵn và tiêu đề — theo đúng mô tả nghiệp vụ mục 3.2 ("Sửa: mở lại đúng màn Thêm giao dịch với dữ liệu điền sẵn").
- Loại giao dịch (Thu/Chi/Chuyển khoản) được phép đổi khi sửa, vì màn nhập liệu dùng chung segmented tab với màn thêm mới và tài liệu nghiệp vụ không cấm việc này.
- Chưa có tính năng giao dịch định kỳ trong app hiện tại, nên phần "hỏi phạm vi áp dụng chuỗi định kỳ" trong tài liệu gốc chưa áp dụng ở PBI này.
- Giao dịch có nguồn gốc từ quét hóa đơn AI (aiScan) sửa như giao dịch nhập tay thường, không cần giữ ràng buộc riêng với phiên quét gốc.

## Ngoài phạm vi

- Xóa giao dịch (nút 3 chấm ở màn Chi tiết giao dịch) — vẫn giữ nguyên trạng thái no-op, thuộc PBI riêng.
- Nhân bản giao dịch — đã có nút riêng, vẫn no-op, không thuộc PBI này.
- Undo sau khi sửa (mục 3.9 tài liệu gốc) — chưa triển khai ở PBI này.
- Sửa/xóa giao dịch định kỳ và hỏi phạm vi áp dụng chuỗi — chưa có tính năng giao dịch định kỳ nên chưa áp dụng.
