# Đặc tả tính năng: Nội dung màn Tổng quan

**Mã PBI**: 33
**Ngày tạo**: 2026-09-13
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Màn Tổng quan hiện chỉ có vùng tiêu đề teal + chuông thông báo, phần thân bỏ trống. Bổ sung nội dung nghiệp vụ lõi: tổng số dư, thu/chi tháng này, danh sách giao dịch gần đây — để người dùng nắm tình hình tài chính ngay khi mở app, theo đúng thiết kế tham chiếu `docs/dashboard/man-hinh-tong-quan.svg`.

## Kịch bản & luồng người dùng

### Luồng chính

**Given** người dùng mở app và app đã qua màn khóa, **When** vào tab Tổng quan, **Then** thấy ngay tổng số dư tất cả ví đang hoạt động, số tiền thu/chi phát sinh trong tháng hiện tại, và tối đa 5 giao dịch gần nhất.

### Kịch bản chấp nhận

1. **Given** đã có giao dịch thu/chi/chuyển khoản trong tháng, **When** mở màn Tổng quan, **Then** thẻ "Thu tháng này" và "Chi tháng này" hiển thị đúng tổng số tiền thu/chi phát sinh từ đầu đến cuối tháng hiện tại (chuyển khoản không tính vào 2 thẻ này).
2. **Given** danh sách giao dịch gần đây đang hiển thị, **When** chạm vào 1 giao dịch, **Then** mở màn chi tiết giao dịch tương ứng.
3. **Given** danh sách giao dịch gần đây đang hiển thị, **When** chạm "Xem tất cả", **Then** chuyển sang tab Giao dịch (danh sách đầy đủ, không lọc riêng).
4. **Given** vừa thêm/sửa/xóa một giao dịch hoặc ví ở màn khác, **When** quay lại màn Tổng quan, **Then** số dư, thu/chi tháng này và danh sách gần đây phản ánh đúng thay đổi mới nhất.

### Trường hợp biên

- Chưa từng có giao dịch nào: tổng số dư = tổng `initial_balance` các ví đang hoạt động, thẻ thu/chi hiển thị `0 đ`, khu vực "Giao dịch gần đây" hiển thị trạng thái rỗng (không hiện danh sách trống trơn không rõ nghĩa).
- Không có ví nào đang hoạt động (tất cả đã ẩn): tổng số dư hiển thị `0 đ`.
- Giao dịch gần đây có cả thu/chi/chuyển khoản: phân biệt trực quan 3 loại (thu = teal, chi = coral, chuyển khoản = trung tính), giao dịch chuyển khoản không mang dấu `+`/`-`.
- Ít hơn 5 giao dịch: hiển thị đúng số lượng thực có, không độn dòng trống.

## Yêu cầu chức năng

- **FR-001**: Hệ thống PHẢI hiển thị tổng số dư tất cả ví đang hoạt động (không ẩn), quy đổi về tiền tệ mặc định, ở đầu màn Tổng quan.
- **FR-002**: Hệ thống PHẢI hiển thị 2 thẻ riêng biệt: tổng tiền thu và tổng tiền chi phát sinh trong tháng hiện tại (chuyển khoản nội bộ không tính vào 2 thẻ này).
- **FR-003**: Hệ thống PHẢI hiển thị danh sách tối đa 5 giao dịch gần nhất, sắp xếp mới nhất trước, phân biệt trực quan thu/chi/chuyển khoản.
- **FR-004**: Người dùng PHẢI có thể chạm "Xem tất cả" để chuyển sang tab Giao dịch.
- **FR-005**: Người dùng PHẢI có thể chạm vào 1 giao dịch trong danh sách gần đây để mở màn chi tiết giao dịch đó.
- **FR-006**: Khi chưa có giao dịch nào, hệ thống PHẢI hiển thị trạng thái rỗng thay cho danh sách giao dịch gần đây.
- **FR-007**: Hệ thống PHẢI cập nhật lại số dư, thu/chi tháng này và danh sách gần đây mỗi khi quay lại màn Tổng quan, không yêu cầu người dùng thao tác làm mới thủ công.

*Mỗi yêu cầu phải kiểm thử được (testable) và không mơ hồ.*

## Tiêu chí thành công

- **SC-001**: Người dùng nắm được tổng số dư và thu/chi tháng này ngay khi mở tab Tổng quan, không cần điều hướng thêm.
- **SC-002**: Người dùng tiếp cận được nội dung 1 giao dịch gần đây chỉ với 1 lần chạm từ màn Tổng quan.
- **SC-003**: 100% thay đổi giao dịch/ví mới nhất được phản ánh đúng trên màn Tổng quan ngay lần quay lại kế tiếp.

## Thực thể chính

- **Giao dịch**: dùng để tính thu/chi tháng này và liệt kê giao dịch gần đây — xem [[Giao dịch]] (wiki).
- **Ví**: dùng để tính tổng số dư (chỉ ví đang hoạt động, không ẩn) — xem [[Ví & Tài khoản]] (wiki).

## Giả định

- Giới hạn danh sách "giao dịch gần đây" là 5 mục, theo đúng quy ước top-N → "Xem tất cả" đã dùng ở màn Báo cáo (PBI 23).
- "Tháng này" tính theo tháng dương lịch hiện tại (đầu tháng 00:00 đến hiện tại), theo giờ thiết bị.
- Icon con mắt "che số dư" trong mockup tham chiếu thuộc module Chế độ riêng tư (Privacy mode) — mã hóa dữ liệu, trạng thái bền, tùy chọn re-auth (`docs/privacy/giai-phap-bao-mat-quyen-rieng-tu.md` §3.8) — là một tính năng lớn độc lập, không thuộc phạm vi PBI này.

## Ngoài phạm vi

- Chế độ riêng tư (Privacy mode) che số dư bằng icon con mắt.
- Biểu đồ/thống kê nâng cao trên Tổng quan (đã có ở màn Báo cáo — PBI 22/23/26).
