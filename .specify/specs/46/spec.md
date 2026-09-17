# Đặc tả tính năng: Chuẩn hoá điều hướng giữa màn hình

**Mã PBI**: 46
**Ngày tạo**: 2026-09-17
**Trạng thái**: Đã làm rõ

## Mô tả tổng quan

Dựa trên audit `docs/ra-soat-nhat-quan-giao-dien.md` (mục 3 — Điều hướng gượng gạo), rà soát lại 27 điểm chuyển màn (`Navigator.push`) trong toàn app. Đối chiếu với code hiện tại: cơ chế "quay về màn gốc rồi đổi tab" (`popUntil` + callback `onSelectTab`) không phải lệch riêng của một màn như audit ghi — nó đã là quy ước dùng chung nhất quán ở 5 màn (Báo cáo, Tổng quan ngân sách, Chi tiết ngân sách, Chi tiết theo danh mục, Trung tâm thông báo), theo đúng chủ đích thiết kế đã ghi trong code (research R1). Điểm còn tồn tại thật sự là: khai báo kiểu dữ liệu trả về của `MaterialPageRoute` không nhất quán — một số nơi khai báo tường minh (`MaterialPageRoute<bool>`, `MaterialPageRoute<void>`...), một số nơi bỏ trống kiểu, khiến giá trị trả về ngầm định là `dynamic` và dễ bị dùng sai mà không có cảnh báo lúc biên dịch.

## Kịch bản & luồng người dùng

### Luồng chính

Không có luồng người dùng mới — hành vi điều hướng hiển thị (màn nào mở màn nào, nút back ở đâu, quay tab nào) giữ nguyên 100% như hiện tại. Đây là việc dọn nội bộ để giảm rủi ro lỗi ẩn khi đội phát triển mở rộng thêm màn hình sau này (ví dụ: quên đọc giá trị trả về từ màn con, hoặc gán nhầm kiểu).

### Kịch bản chấp nhận

1. **Given** người dùng đang dùng bất kỳ luồng điều hướng nào hiện có (mở form sửa, xem chi tiết, quay lại rồi đổi tab...), **When** thao tác điều hướng qua lại giữa các màn, **Then** trải nghiệm (màn hiện ra, dữ liệu trả về, tab được chọn) không đổi so với trước khi chuẩn hoá.
2. **Given** một điểm `Navigator.push` mở màn con có trả kết quả về (ví dụ: form Sửa trả `true`/`false` khi lưu thành công), **When** kiểm tra code, **Then** kiểu dữ liệu trả về được khai báo tường minh, khớp với kiểu mà nơi gọi thực sự dùng.
3. **Given** một điểm `Navigator.push` mở màn con không cần trả kết quả (điều hướng xem/nhập liệu thuần), **When** kiểm tra code, **Then** khai báo tường minh kiểu trả về là "không có giá trị".

### Trường hợp biên

- Màn nào đang dùng đúng pattern "quay về gốc + đổi tab" (popUntil + `onSelectTab`) → giữ nguyên, không đổi thành cơ chế trả-kết-quả-qua-pop (vì đây là điều hướng liên-tab qua `AppShell`, không phải điều hướng cha-con đơn thuần).
- Màn bảo mật (`pin_lock_screen`, `pin_setup_screen`) và màn kiểu modal dùng icon đóng ("X") — đã được audit xác nhận là chủ đích, không thuộc phạm vi PBI này.

## Yêu cầu chức năng

- **FR-001**: Toàn bộ điểm `Navigator.push`/`MaterialPageRoute` trong `lib/` PHẢI khai báo tường minh kiểu dữ liệu trả về (không để trống/ngầm định `dynamic`).
- **FR-002**: Nơi gọi mỗi điểm push ở FR-001 PHẢI xử lý giá trị trả về đúng với kiểu đã khai báo (không ép kiểu ngầm, không bỏ qua giá trị có ý nghĩa).
- **FR-003**: Hành vi điều hướng hiện có (thứ tự màn, nút back, popUntil + đổi tab) PHẢI được giữ nguyên — không đổi UX, không đổi route stack.
- **FR-004**: Việc chuẩn hoá PHẢI bao phủ toàn bộ danh sách 27 điểm push đã liệt kê trong audit, không bỏ sót màn nào.

## Tiêu chí thành công

- **SC-001**: 100% điểm chuyển màn trong app có khai báo kiểu dữ liệu trả về rõ ràng (đo bằng rà soát code, không còn điểm nào thiếu khai báo).
- **SC-002**: Toàn bộ kịch bản điều hướng hiện có (mở/đóng màn, quay lại đổi tab, form trả kết quả) hoạt động y hệt trước khi thay đổi — 0 hồi quy phát hiện qua kiểm thử.
- **SC-003**: Bộ kiểm thử tự động của app chạy qua không phát sinh lỗi mới liên quan điều hướng.

## Giả định

- Cơ chế `popUntil` + `onSelectTab` (điều hướng liên-tab qua `AppShell`) là thiết kế chủ đích, đã dùng nhất quán ở nhiều màn — không nằm trong phạm vi sửa của PBI này, dù audit gốc có nhắc tới.
- "Chuẩn hoá kiểu trả về" là thay đổi thuần nội bộ (an toàn kiểu dữ liệu lúc biên dịch), không phát sinh màn hình, nút bấm, hay luồng nghiệp vụ mới.
- Không cần route đặt tên (named routes) hay khả năng deep-link — audit liệt vào mục "tiểu tiết không gấp" và app hiện chưa có nhu cầu deep-link.

## Ngoài phạm vi

- Đổi cơ chế `popUntil` + `onSelectTab` sang cơ chế khác.
- Thêm route đặt tên (named routes) / deep-link.
- Sửa nút back / app bar (đã xử lý ở PBI 44) và dọn màn Tiện ích (đã xử lý ở PBI 45).
