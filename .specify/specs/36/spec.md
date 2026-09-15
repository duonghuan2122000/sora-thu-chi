# Đặc tả tính năng: Quét ảnh thông báo giao dịch ngân hàng

**Mã PBI**: 36
**Ngày tạo**: 2026-09-15
**Trạng thái**: Đã làm rõ

## Mô tả tổng quan

Mở rộng tính năng quét AI hiện có (PBI 24, vốn chỉ hiểu hóa đơn cửa hàng) để nhận diện đúng **ảnh chụp/chụp màn hình thông báo giao dịch ngân hàng** (tin nhắn SMS biến động số dư, thông báo app ngân hàng, email thông báo giao dịch). Với loại ảnh này, hệ thống PHẢI tự suy ra đúng **loại giao dịch (thu/chi)** theo ghi nợ/ghi có, và lấy đúng **số tiền giao dịch** — không nhầm với số dư tài khoản còn lại, thay vì luôn mặc định là khoản chi như hiện nay.

## Kịch bản & luồng người dùng

### Luồng chính

1. Người dùng chạm nút quét (FAB) như luồng quét hiện có, chụp hoặc chọn một ảnh thông báo ngân hàng (không phải hóa đơn cửa hàng).
2. Hệ thống chạy OCR, sau đó tự nhận diện đây là ảnh thông báo ngân hàng (không phải hóa đơn) dựa trên nội dung nhận dạng được (từ khóa ghi nợ/ghi có, số dư, tên ngân hàng...).
3. Hệ thống trích: loại giao dịch (thu nếu ghi có/cộng tiền, chi nếu ghi nợ/trừ tiền), số tiền giao dịch thực tế (không phải số dư còn lại), ngày giờ giao dịch, và nội dung/người nhận-gửi (nếu đọc được) điền sẵn vào ghi chú.
4. Người dùng được đưa tới màn xác nhận đã có sẵn (giống luồng hóa đơn) với các trường điền sẵn, có thể sửa trước khi lưu.
5. Nếu hệ thống không tự tin đây là ảnh ngân hàng, hoặc không đọc được đủ thông tin, hệ thống rơi về hành vi hiện có (coi như hóa đơn, mặc định khoản chi) — người dùng vẫn luôn có màn xác nhận để tự sửa.

### Kịch bản chấp nhận

1. **Given** ảnh thông báo ngân hàng có nội dung "Ghi nợ"/"Debit"/dấu trừ trước số tiền, **When** quét xong, **Then** loại giao dịch được điền sẵn là **chi**, số tiền là số tiền giao dịch (không phải số dư).
2. **Given** ảnh thông báo ngân hàng có nội dung "Ghi có"/"Credit"/dấu cộng trước số tiền, **When** quét xong, **Then** loại giao dịch được điền sẵn là **thu**, số tiền là số tiền giao dịch (không phải số dư).
3. **Given** ảnh có cả số tiền giao dịch và số dư còn lại xuất hiện trong cùng ảnh, **When** hệ thống chọn số tiền để điền, **Then** số được chọn PHẢI là số tiền giao dịch, không phải số dư — kể cả khi số dư lớn hơn hoặc nằm gần dòng có từ khóa dễ gây nhầm (VD: dòng nội dung giao dịch chứa cụm trùng với từ khóa "thanh toán" nhưng không mang số tiền).
4. **Given** ảnh thông báo ngân hàng đọc được nội dung/tên người nhận-gửi, **When** quét xong, **Then** nội dung đó được điền sẵn vào ô ghi chú của giao dịch (người dùng có thể sửa/xóa).
5. **Given** ảnh không phải hóa đơn cũng không phải thông báo ngân hàng, hoặc ảnh thông báo ngân hàng nhưng không đọc rõ (mờ, thiếu thông tin), **When** quét xong, **Then** hệ thống vẫn đưa ra kết quả tốt nhất có thể (rơi về hành vi hóa đơn hiện có nếu cần) và luôn hiển thị màn xác nhận, không bao giờ tự lưu giao dịch mà không cho người dùng xem lại.
6. **Given** người dùng đang ở màn xác nhận với dữ liệu điền sẵn từ ảnh ngân hàng, **When** người dùng thấy sai, **Then** người dùng sửa được mọi trường (số tiền, loại GD, ngày, danh mục, ghi chú) giống hệt luồng hóa đơn hiện tại.

### Trường hợp biên

- Ảnh có nhiều số tiền dễ nhầm (số tiền giao dịch, số dư khả dụng, phí giao dịch, hạn mức) → chỉ số tiền giao dịch chính được chọn; các số khác không được dùng làm số tiền giao dịch.
- Ảnh thông báo giao dịch **chuyển khoản** cho người/đơn vị khác (không phải chuyển giữa các ví do người dùng quản lý trong app) → phân loại theo chiều tiền ra/vào tài khoản ngân hàng đó (ghi nợ ⇒ chi), **không** tự gán loại "chuyển khoản nội bộ" của app (loại đó chỉ dành cho chuyển tiền giữa các ví do chính người dùng quản lý trong app).
- Không đọc được rõ ghi nợ/ghi có (ảnh mờ, ngân hàng dùng thuật ngữ lạ) → không đoán bừa loại giao dịch; để mức tin cậy thấp, người dùng tự chọn ở màn xác nhận.
- Ảnh thông báo ngân hàng nhưng không có ngày giờ giao dịch rõ ràng → dùng thời điểm hiện tại, độ tin cậy thấp, giống hành vi hóa đơn hiện tại.
- Ảnh chụp từ nhiều loại nguồn khác nhau của cùng một thông báo (SMS, push notification, email) với bố cục khác nhau → hệ thống không phụ thuộc vào bố cục cố định của riêng một nguồn.

## Yêu cầu chức năng

- **FR-001**: Hệ thống PHẢI tự nhận diện, trong cùng luồng quét hiện có, khi một ảnh là thông báo giao dịch ngân hàng thay vì hóa đơn cửa hàng, dựa trên nội dung nhận dạng được từ ảnh — không cần người dùng chọn loại ảnh thủ công.
- **FR-002**: Khi nhận diện là thông báo ngân hàng, hệ thống PHẢI xác định loại giao dịch là **chi** nếu nội dung thể hiện ghi nợ/trừ tiền, hoặc **thu** nếu nội dung thể hiện ghi có/cộng tiền.
- **FR-003**: Hệ thống PHẢI trích đúng số tiền của giao dịch phát sinh, phân biệt với các số tiền khác có thể xuất hiện trong cùng ảnh (số dư khả dụng, số dư sau giao dịch, hạn mức, phí).
- **FR-004**: Hệ thống PHẢI KHÔNG được tự động gán loại giao dịch là "chuyển khoản nội bộ" của app cho giao dịch ngân hàng đọc từ ảnh — chỉ gán thu hoặc chi theo chiều tiền ra/vào tài khoản.
- **FR-005**: Hệ thống PHẢI trích ngày giờ giao dịch từ ảnh khi đọc được; không đọc được thì dùng thời điểm hiện tại kèm mức tin cậy thấp.
- **FR-006**: Khi đọc được nội dung giao dịch hoặc tên người nhận/gửi, hệ thống PHẢI điền các thông tin đó vào ghi chú của giao dịch.
- **FR-007**: Khi hệ thống không đủ tin cậy để xác định đây là ảnh thông báo ngân hàng, hệ thống PHẢI rơi về hành vi trích xuất hóa đơn hiện có (không được để trống hoàn toàn hay báo lỗi chặn luồng).
- **FR-008**: Mọi kết quả trích xuất từ ảnh thông báo ngân hàng PHẢI đi qua màn xác nhận đã có, cho phép người dùng sửa mọi trường trước khi lưu — không tự động lưu giao dịch.
- **FR-009**: Việc nhận diện và trích xuất PHẢI hoạt động tổng quát cho nhiều định dạng thông báo ngân hàng khác nhau (không cứng theo mẫu của riêng một ngân hàng cụ thể).

*Mỗi yêu cầu phải kiểm thử được (testable) và không mơ hồ.*

## Tiêu chí thành công

- **SC-001**: Với ảnh thông báo ngân hàng có ghi rõ ghi nợ/ghi có, loại giao dịch (thu/chi) được điền sẵn đúng trong ít nhất 90% trường hợp thử nghiệm.
- **SC-002**: Với ảnh thông báo ngân hàng có nhiều số tiền (giao dịch + số dư), số tiền giao dịch được chọn đúng (không phải số dư) trong ít nhất 90% trường hợp thử nghiệm.
- **SC-003**: 100% kết quả quét từ ảnh thông báo ngân hàng đều dừng ở màn xác nhận cho người dùng sửa trước khi lưu, không có trường hợp tự động lưu thẳng.
- **SC-004**: Người dùng xác nhận (sửa nếu cần) và lưu một giao dịch từ ảnh thông báo ngân hàng trong thời gian tương đương luồng hóa đơn hiện tại (dưới 30 giây kể từ khi thấy màn xác nhận, không tính thời gian đọc lại số liệu).

## Thực thể chính

- **Kết quả trích xuất giao dịch (mở rộng)**: tái sử dụng cấu trúc kết quả trích xuất hiện có của tính năng quét (số tiền, ngày, loại giao dịch, danh mục gợi ý, độ tin cậy từng trường); bổ sung khả năng điền loại giao dịch là **thu** (trước đây luôn cố định là chi) và điền ghi chú từ nội dung/người nhận-gửi đọc được.

## Giả định

- Phạm vi chỉ gồm ảnh chụp màn hình thông báo ngân hàng (SMS, thông báo app, email) — không gồm ảnh chụp máy ATM, sao kê giấy in, hay ảnh chụp màn hình ví điện tử/ứng dụng thanh toán không phải ngân hàng.
- "Chuyển khoản nội bộ" trong nghiệp vụ app chỉ áp dụng cho giao dịch giữa các ví do chính người dùng quản lý trong app; giao dịch chuyển tiền tới bên thứ ba đọc từ ảnh ngân hàng luôn được coi là thu hoặc chi, không phải chuyển khoản nội bộ.
- Việc nhận diện "đây là ảnh ngân hàng hay hóa đơn" dùng chung engine trích xuất hiện có (bộ luật + AI on-device theo tier, có fallback) của PBI 24 — không giới thiệu engine/model mới.
- Không giới hạn hay tối ưu riêng theo một ngân hàng cụ thể; độ chính xác dựa trên từ khóa/mẫu câu tiếng Việt phổ biến (ghi nợ/ghi có/số dư/GD...) áp dụng chung.
- Danh mục gợi ý cho giao dịch ngân hàng có thể để trống nếu không đủ cơ sở suy luận (không có tên cửa hàng rõ ràng như hóa đơn) — người dùng tự chọn ở màn xác nhận.

## Ngoài phạm vi

- Kết nối trực tiếp API ngân hàng / Open Banking để lấy giao dịch tự động (app vẫn hoàn toàn offline, không kết nối ngân hàng).
- Tối ưu độ chính xác riêng cho từng ngân hàng cụ thể (đợt đầu chỉ tổng quát).
- Tự động đối chiếu/khớp giao dịch trùng giữa nhiều ảnh thông báo của cùng một giao dịch.
- Đọc ảnh sao kê giấy in hoặc ảnh chụp máy ATM.
