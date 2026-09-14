# Đặc tả tính năng: Sao lưu & Khôi phục dữ liệu

**Mã PBI**: 35
**Ngày tạo**: 2026-09-14
**Trạng thái**: Đã làm rõ

## Mô tả tổng quan

Bổ sung màn hình "Sao lưu & Khôi phục" trong Cài đặt, cho phép người dùng xuất toàn bộ dữ liệu tài chính ra file để lưu trữ/chuyển máy, và khôi phục lại dữ liệu từ một file đã xuất trước đó. Vì app hoàn toàn offline (không tài khoản, không server), đây là cơ chế "đồng bộ thủ công qua file" duy nhất để tránh mất dữ liệu khi đổi máy, mất máy hoặc lỗi app.

## Kịch bản & luồng người dùng

### Luồng chính — Sao lưu thủ công

1. Người dùng vào Cài đặt → **Sao lưu & Khôi phục**.
2. Chạm **"Tạo bản sao lưu mới"** → hệ thống tổng hợp số liệu hiện có (số ví, danh mục, giao dịch, dung lượng ước tính) và hiển thị bottom sheet xác nhận.
3. Người dùng có thể tuỳ chọn đặt mật khẩu bảo vệ file, sau đó chạm **"Tạo & Chia sẻ"**.
4. Hệ thống tạo file backup, mở bảng chia sẻ của hệ điều hành để người dùng lưu/gửi file.
5. Hiển thị màn hình thành công; thời điểm sao lưu gần nhất được cập nhật và hiển thị lại trên màn chính của tính năng.

### Luồng chính — Khôi phục dữ liệu

1. Từ màn "Sao lưu & Khôi phục", người dùng chạm **"Chọn file khôi phục"** (mở trình chọn file) hoặc chọn trực tiếp một bản trong danh sách **"Các bản sao lưu"** có sẵn trên máy.
2. Hệ thống đọc thông tin tóm tắt của file (không cần đọc toàn bộ dữ liệu chi tiết) để kiểm tra file hợp lệ và tương thích.
3. Hiển thị bottom sheet xác nhận khôi phục: tên file, thời điểm tạo, số liệu tóm tắt, kèm cảnh báo rõ ràng rằng dữ liệu hiện tại trên máy sẽ **bị ghi đè hoàn toàn**.
4. Người dùng bắt buộc tick "Tôi hiểu và muốn tiếp tục" trước khi nút khôi phục được bật.
5. Khi xác nhận, hệ thống tự sao lưu an toàn dữ liệu hiện tại trước khi ghi đè, sau đó thay thế toàn bộ dữ liệu bằng nội dung file đã chọn.
6. Hiển thị màn hình thành công, điều hướng người dùng về màn Tổng quan.

### Kịch bản chấp nhận

1. **Given** người dùng đang ở màn "Sao lưu & Khôi phục", **When** chạm "Tạo bản sao lưu mới" và xác nhận, **Then** một file backup mới được tạo, bảng chia sẻ hệ thống mở ra, và "Sao lưu gần nhất" trên màn chính cập nhật đúng thời điểm/số liệu vừa tạo.
2. **Given** người dùng bật "Tự động sao lưu" và chọn tần suất, **When** đến thời điểm đã lên lịch, **Then** hệ thống tự tạo file backup lưu nội bộ trên máy (không mở bảng chia sẻ) và gửi thông báo nhẹ xác nhận đã sao lưu.
3. **Given** người dùng chọn một file backup hợp lệ để khôi phục, **When** xác nhận tick ô "Tôi hiểu và muốn tiếp tục" rồi chạm khôi phục, **Then** toàn bộ dữ liệu hiện tại bị thay thế bằng dữ liệu trong file, và ứng dụng điều hướng về Tổng quan với dữ liệu mới.
4. **Given** người dùng chọn file khôi phục nhưng chưa tick ô xác nhận, **When** nhìn vào bottom sheet, **Then** nút khôi phục ở trạng thái vô hiệu, không thể bấm.
5. **Given** file backup được bảo vệ bằng mật khẩu, **When** người dùng chọn khôi phục từ file đó, **Then** hệ thống yêu cầu nhập đúng mật khẩu trước khi hiển thị bất kỳ số liệu tóm tắt nào của file.

### Trường hợp biên

- File backup bị hỏng hoặc sai định dạng → chặn ngay, báo lỗi rõ ràng, không hiển thị bottom sheet xác nhận.
- File backup được tạo từ phiên bản app mới hơn (không tương thích) → cảnh báo rõ ràng, chặn khôi phục, gợi ý cập nhật app.
- Nhập sai mật khẩu file backup nhiều lần → vẫn cho thử lại nhưng có độ trễ tăng dần giữa các lần.
- Không đủ dung lượng trống trên máy khi tạo file backup (đặc biệt khi có ảnh hóa đơn đính kèm) → báo lỗi trước khi bắt đầu ghi file, không để lại file dở dang.
- Ứng dụng bị tắt/gặp lỗi giữa lúc đang khôi phục → dữ liệu hiện tại không bị mất một phần; người dùng có thể mở lại app và thử khôi phục lại.
- File backup có đính kèm ảnh hóa đơn nhưng một số ảnh bị thiếu/lỗi → vẫn khôi phục phần dữ liệu giao dịch, hiển thị sau khi xong số lượng giao dịch bị thiếu ảnh.
- File backup rất cũ, thuộc cấu trúc dữ liệu phiên bản trước → hệ thống tự nâng cấp cấu trúc trước khi ghi vào dữ liệu hiện tại, người dùng không cần thao tác thêm.
- Chưa từng có bản sao lưu nào trên máy → khối "Các bản sao lưu" hiển thị trạng thái rỗng, không có danh sách.

## Yêu cầu chức năng

- **FR-001**: Hệ thống PHẢI cung cấp màn hình "Sao lưu & Khôi phục" truy cập được từ Cài đặt.
- **FR-002**: Người dùng PHẢI có thể tạo một bản sao lưu thủ công chứa toàn bộ dữ liệu (ví, danh mục, giao dịch, ngân sách, mục tiêu tiết kiệm, khoản vay/nợ, cài đặt) tại bất kỳ thời điểm nào.
- **FR-003**: Trước khi tạo bản sao lưu thủ công, hệ thống PHẢI hiển thị tóm tắt số liệu (số ví/danh mục/giao dịch, dung lượng ước tính) để người dùng xác nhận.
- **FR-004**: Người dùng PHẢI có thể tuỳ chọn đặt mật khẩu bảo vệ cho file sao lưu; việc đặt mật khẩu là không bắt buộc.
- **FR-005**: Sau khi tạo file sao lưu thủ công, hệ thống PHẢI cho phép người dùng chia sẻ/lưu file đó thông qua cơ chế chia sẻ của hệ điều hành.
- **FR-006**: Người dùng PHẢI có thể bật/tắt tính năng tự động sao lưu và chọn tần suất (hàng ngày, hàng tuần, hàng tháng).
- **FR-007**: Khi tự động sao lưu chạy, hệ thống PHẢI lưu file vào bộ nhớ nội bộ ứng dụng mà không tự mở bảng chia sẻ, và PHẢI tự xoá các bản cũ vượt quá số lượng tối đa giữ lại.
- **FR-008**: Hệ thống PHẢI hiển thị thời điểm và số liệu tóm tắt của lần sao lưu gần nhất trên màn hình chính của tính năng.
- **FR-009**: Hệ thống PHẢI hiển thị danh sách các bản sao lưu hiện có trên máy (tên file, dung lượng, loại thủ công/tự động, có/không ảnh đính kèm).
- **FR-010**: Người dùng PHẢI có thể khởi động khôi phục bằng cách chọn file từ bộ nhớ máy hoặc chọn trực tiếp một bản trong danh sách sao lưu cục bộ.
- **FR-011**: Trước khi khôi phục, hệ thống PHẢI kiểm tra tính hợp lệ và khả năng tương thích của file (định dạng đúng, không hỏng, phiên bản cấu trúc dữ liệu được hỗ trợ).
- **FR-012**: Hệ thống PHẢI chặn khôi phục và báo lỗi rõ ràng nếu file không hợp lệ, bị hỏng, hoặc thuộc phiên bản không tương thích.
- **FR-013**: Trước khi ghi đè dữ liệu, hệ thống PHẢI hiển thị xác nhận nêu rõ dữ liệu hiện tại sẽ bị **thay thế hoàn toàn** (không gộp/merge), và PHẢI yêu cầu người dùng xác nhận rõ ràng (tick ô đồng ý) trước khi cho phép thực hiện.
- **FR-014**: Hệ thống PHẢI tự tạo một bản sao lưu an toàn của dữ liệu hiện tại ngay trước khi ghi đè, để có thể khôi phục lại nếu người dùng chọn nhầm file.
- **FR-015**: Việc ghi dữ liệu khôi phục vào hệ thống PHẢI là toàn phần-hoặc-không (nếu xảy ra lỗi giữa chừng, dữ liệu hiện tại không bị mất một phần).
- **FR-016**: Nếu file khôi phục có đặt mật khẩu, hệ thống PHẢI yêu cầu nhập đúng mật khẩu trước khi hiển thị bất kỳ thông tin nào trích từ file (kể cả số liệu tóm tắt).
- **FR-017**: Sau khi khôi phục thành công, hệ thống PHẢI hiển thị xác nhận thành công và đưa người dùng về màn Tổng quan với dữ liệu đã cập nhật.
- **FR-018**: Sau khi sao lưu thủ công thành công, hệ thống PHẢI hiển thị màn hình xác nhận thành công kèm tuỳ chọn chia sẻ lại file.

*Mỗi yêu cầu phải kiểm thử được (testable) và không mơ hồ.*

## Tiêu chí thành công

- **SC-001**: Người dùng hoàn tất một lượt tạo & chia sẻ bản sao lưu thủ công trong dưới 30 giây (không tính thời gian thao tác trên bảng chia sẻ hệ thống).
- **SC-002**: Người dùng hoàn tất một lượt khôi phục dữ liệu hợp lệ (từ lúc chọn file đến khi thấy màn Tổng quan mới) trong dưới 1 phút.
- **SC-003**: 100% trường hợp chọn file backup hỏng/không tương thích được chặn với thông báo lỗi rõ ràng, không có trường hợp app treo hoặc dữ liệu hiện tại bị hỏng.
- **SC-004**: 100% lượt khôi phục đều yêu cầu người dùng xác nhận rõ ràng (tick + bấm nút) trước khi ghi đè — không có đường tắt bỏ qua bước xác nhận.
- **SC-005**: Sau khi bật tự động sao lưu, người dùng luôn thấy đúng thời điểm sao lưu gần nhất được cập nhật trên màn chính mà không cần mở lại app thủ công.

## Thực thể chính

- **Bản sao lưu (Backup)**: file chứa metadata (thời điểm tạo, phiên bản cấu trúc dữ liệu, số liệu tóm tắt, có mật khẩu hay không, có ảnh đính kèm hay không) và toàn bộ dữ liệu nghiệp vụ (ví, danh mục, giao dịch, ngân sách, mục tiêu tiết kiệm, khoản vay/nợ, cài đặt). Có thể ở dạng file đơn (không ảnh) hoặc gói nén (có ảnh đính kèm).
- **Cấu hình tự động sao lưu**: trạng thái bật/tắt, tần suất (ngày/tuần/tháng), số lượng bản giữ lại tối đa nội bộ.
- **Trạng thái sao lưu gần nhất**: thời điểm, số liệu tóm tắt của lần sao lưu (thủ công hoặc tự động) gần nhất, hiển thị trên màn chính.

## Giả định

- Không có đồng bộ cloud tự động (Google Drive/iCloud API) ở tính năng này — việc lưu file ra ngoài app hoàn toàn dựa vào bảng chia sẻ hệ thống do người dùng tự chọn nơi lưu.
- Chiến lược khôi phục là "ghi đè toàn bộ" (replace-only), không hỗ trợ gộp (merge) dữ liệu hai chiều.
- Số bản sao lưu tự động giữ lại nội bộ mặc định là 5 bản gần nhất, xoay vòng theo nguyên tắc bản cũ nhất bị xoá trước.
- Việc đặt mật khẩu bảo vệ file sao lưu là tuỳ chọn, không bắt buộc, và độc lập hoàn toàn với mã PIN khoá ứng dụng.
- Định dạng file (đơn thuần hay gói nén kèm ảnh) được hệ thống tự quyết định dựa trên việc dữ liệu có ảnh hóa đơn đính kèm hay không, người dùng không cần chọn định dạng thủ công.

## Ngoài phạm vi

- Đồng bộ dữ liệu tự động qua nhiều thiết bị (real-time, hai chiều).
- Tích hợp trực tiếp API của các dịch vụ lưu trữ đám mây (Google Drive, iCloud...).
- Gộp (merge) dữ liệu giữa file backup và dữ liệu hiện tại trên máy.
- Chia sẻ dữ liệu giữa nhiều người dùng/nhiều tài khoản.
