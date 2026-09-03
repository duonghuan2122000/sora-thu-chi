# Đặc tả tính năng: Khung điều hướng ứng dụng

**Mã PBI**: 2
**Ngày tạo**: 2026-09-03
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

App mới dừng ở khung mặc định (màn hình counter demo), chưa có cấu trúc màn hình nào cho tính năng thật. Tính năng này dựng **khung điều hướng chung** của app: thanh điều hướng đáy 5 vị trí (gồm nút nổi "Thêm giao dịch" ở giữa), bốn màn hình chính đặt chỗ để các module nghiệp vụ (Tổng quan, Giao dịch, Báo cáo, Cài đặt) gắn nội dung vào sau. Đây là bộ xương điều hướng: sau khi xong, người dùng điều hướng được giữa các vùng chính, còn nội dung từng vùng được xây ở các PBI module riêng.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (mở app di động).

### Luồng chính
1. Người dùng mở app → vào thẳng màn **Tổng quan** (vùng chính đầu tiên).
2. Phía dưới màn hình hiện thanh điều hướng đáy với 5 vị trí: Tổng quan | Giao dịch | **nút nổi "Thêm giao dịch"** | Báo cáo | Cài đặt. Vị trí đang mở được làm nổi bật.
3. Người dùng chạm một vị trí (Tổng quan / Giao dịch / Báo cáo / Cài đặt) → vùng chính đổi sang màn tương ứng; nút nổi luôn hiện ở giữa, bất kể đang ở vùng nào.
4. Người dùng chạm nút nổi giữa → hệ thống mở màn phụ "Thêm giao dịch" dạng khung trống (chưa có biểu mẫu), có nút quay lại, không có thanh điều hướng đáy.
5. Người dùng chạm nút quay lại → trở về đúng màn chính trước đó, vị trí đang chọn được giữ nguyên.

### Kịch bản chấp nhận
1. **Given** app vừa mở lần đầu **When** màn hình sẵn sàng **Then** người dùng thấy màn Tổng quan cùng thanh điều hướng đáy 5 vị trí; vị trí Tổng quan được đánh dấu đang chọn.
2. **Given** đang ở màn Tổng quan **When** người dùng chạm "Giao dịch" **Then** vùng chính chuyển sang màn Giao dịch; vị trí Giao dịch được đánh dấu chọn.
3. **Given** người dùng đang ở màn Giao dịch **When** chạm lần lượt Báo cáo, rồi quay lại Giao dịch **Then** màn Giao dịch hiện đúng như lúc rời đi, không bị đặt lại về trạng thái ban đầu.
4. **Given** đang ở bất kỳ màn chính nào **When** người dùng chạm nút nổi giữa **Then** hệ thống mở màn phụ "Thêm giao dịch" dạng khung trống, có nút quay lại, không có thanh điều hướng đáy.
5. **Given** người dùng đang ở một màn chính (ví dụ Cài đặt) và mở màn phụ "Thêm giao dịch" **When** chạm nút quay lại **Then** trở về đúng màn chính lúc rời đi, vị trí đang chọn được giữ nguyên.

### Trường hợp biên
- Chuyển vị trí liên tục, nhanh → không bị treo, không hiển thị sai màn.
- Nội dung màn dài hơn màn hình → cuộn được; nút nổi không che phần nội dung cuối quan trọng.
- Người dùng bật cỡ chữ lớn (hỗ trợ tiếp cận) → thanh điều hướng và nút nổi không vỡ, chữ không tràn ra ngoài.
- Màn hình thiết bị khác nhau (vùng an toàn, tai thỏ, phím điều hướng hệ thống) → thanh điều hướng không bị che khuất.
- Đang ở màn phụ mà người dùng thao tác quay lại của hệ thống → về đúng màn chính trước đó; ở màn chính gốc mà quay lại → thoát app theo hành vi hệ điều hành.

## Yêu cầu chức năng

- **FR-001**: App PHẢI hiển thị thanh điều hướng đáy cố định gồm 5 vị trí theo thứ tự: Tổng quan | Giao dịch | nút nổi "Thêm giao dịch" | Báo cáo | Cài đặt.
- **FR-002**: Khi mở app, vùng chính PHẢI vào màn Tổng quan; vị trí tương ứng PHẢI được đánh dấu là đang chọn.
- **FR-003**: Người dùng PHẢI chuyển được giữa 4 vùng chính (Tổng quan, Giao dịch, Báo cáo, Cài đặt) bằng cách chạm vị trí tương ứng; màn nào đang mở thì vị trí đó PHẢI được làm nổi bật khác biệt với các vị trí còn lại.
- **FR-004**: Khi chuyển khỏi rồi quay lại một vùng chính, trạng thái vùng đó PHẢI được giữ nguyên (không tự khởi động lại từ đầu) trong cùng phiên dùng app.
- **FR-005**: Nút nổi "Thêm giao dịch" PHẢI luôn hiển thị cố định ở giữa thanh điều hướng trên cả 4 màn chính; người dùng chạm vào PHẢI dẫn tới màn phụ "Thêm giao dịch".
- **FR-006**: Màn phụ "Thêm giao dịch" mở từ nút nổi PHẢI là màn khung trống (chưa có biểu mẫu tạo giao dịch), có nút quay lại, KHÔNG hiển thị thanh điều hướng đáy.
- **FR-007**: Bốn màn chính trong đợt này PHẢI là màn khung đặt chỗ tối thiểu: vùng tiêu đề (tên màn) + vùng nội dung trống, sẵn sàng để module sau gắn nội dung vào; KHÔNG nhúng số liệu minh họa giả.
- **FR-008**: Cơ chế màn phụ PHẢI cho phép mở từ bất kỳ màn chính nào, có nút quay lại, KHÔNG hiển thị thanh điều hướng đáy; quay lại trở về đúng màn chính trước đó. Đợt này áp dụng cho màn phụ "Thêm giao dịch"; khi Cài đặt có mục điều hướng thật (PBI sau) sẽ tái dùng cơ chế này.
- **FR-009**: Giao diện khung PHẢI hiển thị đúng, không vỡ hoặc bị che khuất trên các kích thước màn hình và vùng an toàn thiết bị khác nhau (điện thoại).
- **FR-010**: Việc điều hướng giữa các vùng PHẢI không gây lỗi, không hiển thị sai màn, không mất vị trí đang chọn khi thao tác liên tục.

## Tiêu chí thành công

- **SC-001**: Người dùng mở app và chuyển đủ 4 vùng chính, không gặp lỗi hay màn hình sai trong lần dùng đầu tiên.
- **SC-002**: Nút nổi "Thêm giao dịch" hiển thị và hoạt động ở đúng vị trí giữa trên cả 4 màn chính — kiểm tra 4/4 trường hợp đạt.
- **SC-003**: Chuyển vị trí qua lại ít nhất 5 lần liên tục → vị trí cuối đúng màn người dùng chọn, không treo.
- **SC-004**: Trên màn hình có vùng an toàn (tai thỏ, phím hệ thống) → thanh điều hướng đáy không bị che, đủ chạm.
- **SC-005**: Bật cỡ chữ lớn nhất hỗ trợ → nhãn vị trí và nút nổi không bị vỡ hay tràn khỏi màn hình.
- **SC-006**: Mở màn phụ từ một màn chính rồi quay lại → trở về đúng màn đó, đúng vị trí đang chọn; màn phụ không hiển thị thanh điều hướng đáy (đánh giá định tính, không yêu cầu số liệu).

## Giả định

- Đợt này chỉ dựng **khung điều hướng**; nội dung nghiệp vụ thật của Tổng quan, Giao dịch, Báo cáo, Cài đặt được xây ở các PBI module riêng và gắn vào các màn khung này (đã chốt: 4 màn chính đặt chỗ tối thiểu, không dữ liệu mẫu).
- Đã chốt: nút nổi "Thêm giao dịch" mở màn phụ khung trống tạm thời; biểu mẫu tạo giao dịch thật sẽ thay khung này khi module Giao dịch được xây.
- Cách trình bày thanh điều hướng, nút nổi, màu vị trí chọn/chưa chọn tuân theo thiết kế chuẩn của app (đã chốt trong tài liệu thiết kế).
- Màn khóa app (PIN/sinh trắc) và luồng hướng dẫn đầu tiên (Onboarding) thuộc module bảo mật/tài khoản, PBI riêng — không nằm đợt này; PBI này chỉ đảm bảo khung điều hướng không chặn việc gắn các màn đó về sau.
- App dùng chủ yếu theo chiều dọc trên điện thoại; tablet/đa cửa sổ chưa phải mục tiêu đợt này.
- Ngôn ngữ giao diện trong đợt này là tiếng Việt.

## Ngoài phạm vi

- Nội dung chức năng thật của 4 màn chính (số dư ví, danh sách giao dịch, biểu đồ báo cáo, các mục cài đặt).
- Luồng tạo/sửa/xóa giao dịch hoàn chỉnh (chỉ có điểm vào từ nút nổi).
- Màn khóa app (PIN, vân tay, Face ID), Onboarding, hồ sơ cá nhân, đổi/quên PIN.
- Đa ngôn ngữ, chủ đề tối.
- Tablet, giao diện xoay ngang, đa cửa sổ.
