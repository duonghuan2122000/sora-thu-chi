# Đặc tả tính năng: Loại bỏ dữ liệu mẫu khi cài mới

**Mã PBI**: 32
**Ngày tạo**: 2026-09-13
**Trạng thái**: Nháp

## Mô tả tổng quan

Hiện tại lần đầu cài app, hệ thống tự động nạp sẵn 5 ví mẫu và 11 giao dịch mẫu (dữ liệu demo còn sót lại từ giai đoạn thi công PBI 5/6, trước khi module Giao dịch có dữ liệu thật). Người dùng thật cài app lần đầu thấy ngay dữ liệu giả này lẫn với dữ liệu của mình, gây hiểu lầm và phải tự tay xoá. Tính năng này loại bỏ hoàn toàn việc nạp ví/giao dịch mẫu, để lần đầu mở app là trạng thái sạch — chỉ có danh mục mặc định (không phải dữ liệu "mẫu", mà là cấu hình nghiệp vụ cần thiết để dùng app).

## Kịch bản & luồng người dùng

### Luồng chính

1. Người dùng cài app lần đầu (hoặc xoá app cũ rồi cài lại — dữ liệu local đã mất) và mở app.
2. App khởi tạo cơ sở dữ liệu local lần đầu: chỉ tạo sẵn danh mục thu/chi mặc định (Ăn uống, Di chuyển, Lương...). **Không** tạo sẵn bất kỳ ví hay giao dịch nào.
3. Màn Tổng quan / Ví / Giao dịch hiển thị đúng trạng thái rỗng (chưa có ví nào, chưa có giao dịch nào), có hướng dẫn/CTA để người dùng tự tạo ví đầu tiên.
4. Người dùng tự tạo ví và nhập giao dịch của chính mình — không còn dữ liệu giả nào lẫn vào.

### Kịch bản chấp nhận

1. **Given** người dùng cài app lần đầu tiên trên thiết bị sạch, **When** mở app, **Then** danh sách ví trống, danh sách giao dịch trống, danh mục thu/chi mặc định vẫn đầy đủ như thiết kế.
2. **Given** app đã cài lần đầu và ở trạng thái rỗng, **When** người dùng vào màn Tổng quan/Báo cáo, **Then** các màn hiển thị đúng trạng thái không có dữ liệu (không lỗi, không hiển thị số liệu/biểu đồ từ dữ liệu mẫu cũ).
3. **Given** người dùng nâng cấp app từ một bản đã cài trước đó (đã có ví/giao dịch thật hoặc mẫu tồn tại sẵn trong dữ liệu local), **When** app chạy migration cơ sở dữ liệu, **Then** dữ liệu hiện có của người dùng được giữ nguyên — bản nâng cấp không tự ý xoá ví/giao dịch đã tồn tại trên máy.

### Trường hợp biên

- Danh mục mặc định vẫn phải được nạp bình thường (không thuộc phạm vi "dữ liệu mẫu" cần loại bỏ) để người dùng có thể chọn danh mục ngay khi tạo giao dịch đầu tiên.
- App không còn ví nào → mọi luồng yêu cầu chọn ví (thêm giao dịch, chuyển khoản...) phải dẫn người dùng đến bước tạo ví trước, không được crash hay chọn ví rỗng ngầm định.

## Yêu cầu chức năng

- **FR-001**: Hệ thống KHÔNG ĐƯỢC tự động tạo sẵn bất kỳ ví mẫu nào khi khởi tạo cơ sở dữ liệu lần đầu (cài mới).
- **FR-002**: Hệ thống KHÔNG ĐƯỢC tự động tạo sẵn bất kỳ giao dịch mẫu nào khi khởi tạo cơ sở dữ liệu lần đầu (cài mới).
- **FR-003**: Hệ thống PHẢI tiếp tục nạp bộ danh mục thu/chi mặc định khi khởi tạo lần đầu (không thay đổi hành vi này).
- **FR-004**: Các màn hình phụ thuộc dữ liệu ví/giao dịch (Tổng quan, Giao dịch, Báo cáo, Ngân sách...) PHẢI hiển thị đúng trạng thái rỗng, hợp lý khi chưa có ví hoặc chưa có giao dịch nào, thay vì lỗi hoặc để trống không rõ nghĩa.
- **FR-005**: Luồng thêm giao dịch/chuyển khoản khi chưa có ví nào PHẢI hướng người dùng tạo ví trước, không cho phép thao tác vào trạng thái không hợp lệ.
- **FR-006**: Với thiết bị đã cài app từ bản trước (đã có dữ liệu local, kể cả dữ liệu mẫu cũ đã sẵn trong DB), việc nâng cấp app KHÔNG ĐƯỢC tự động xoá ví hoặc giao dịch đã tồn tại trên máy.

*Mỗi yêu cầu phải kiểm thử được (testable) và không mơ hồ.*

## Tiêu chí thành công

- **SC-001**: Cài app lần đầu trên thiết bị sạch → 0 ví, 0 giao dịch ngay sau khi mở app lần đầu.
- **SC-002**: Không còn màn hình nào tham chiếu tới bộ dữ liệu ví/giao dịch mẫu cũ (5 ví, 11 giao dịch) trong toàn bộ luồng cài mới.
- **SC-003**: 100% màn hình có phụ thuộc dữ liệu ví/giao dịch xử lý được trạng thái rỗng mà không phát sinh lỗi khi QA thủ công trên thiết bị cài mới.
- **SC-004**: Thiết bị nâng cấp từ bản cũ giữ nguyên toàn bộ ví/giao dịch đã có trước khi nâng cấp (không mất, không tự xoá).

## Giả định

- "Lần đầu cài app" áp dụng cho thiết bị cài mới hoàn toàn (chưa từng có cơ sở dữ liệu local) — không bao gồm việc chủ động dọn dữ liệu mẫu đã tồn tại sẵn trên các máy đã cài bản cũ trước đó.
- Danh mục mặc định (Ăn uống, Lương...) không thuộc phạm vi "dữ liệu mẫu" của PBI này — đây là cấu hình nghiệp vụ cần thiết, đã được xác định trong docs Danh mục, giữ nguyên.
- Trạng thái rỗng (0 ví, 0 giao dịch) là trạng thái hợp lệ của app cần được các màn hình hiện có xử lý đúng, không phải lỗi cần sửa riêng ở module khác.

## Ngoài phạm vi

- Xoá/dọn dữ liệu mẫu đã tồn tại sẵn trên các thiết bị đã cài app từ bản trước đó (đã có 5 ví/11 giao dịch mẫu trong DB) — không tự động can thiệp vào dữ liệu người dùng đang có.
- Thiết kế lại UI trạng thái rỗng theo hướng mới — chỉ đảm bảo màn hình hiện có xử lý đúng, không lỗi; không yêu cầu thêm minh hoạ/CTA mới ngoài phạm vi đã có.
