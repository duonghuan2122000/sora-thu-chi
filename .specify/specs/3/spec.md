# Đặc tả tính năng: Khóa ứng dụng bằng mã PIN

**Mã PBI**: 3
**Ngày tạo**: 2026-09-03
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

App quản lý thu chi cá nhân **offline, không đăng nhập** — nên thứ duy nhất chặn người khác xem dữ liệu tài chính khi cầm máy là lớp **khóa ứng dụng** đặt ngay trên thiết bị. Tính năng này xây nhánh "Khóa ứng dụng bằng mã PIN": **ngay lần đầu mở app, người dùng phải thiết lập một mã PIN 4 số trước khi vào nội dung**; từ đó mỗi lần mở app phải nhập đúng mã PIN mới vào được, kèm cơ chế chống dò mã PIN bằng khóa tạm thời khi nhập sai liên tiếp. Đây là nhánh cốt lõi nhất của module bảo mật — sinh trắc học (vân tay/Face ID) là lớp "tiện lợi" bổ sung cho sau, không nằm trong đợt này.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị).

### Luồng chính

**1. Thiết lập mã PIN lần đầu mở app (bắt buộc)**

1. Người dùng mở app lần đầu trên thiết bị (chưa có mã PIN) → hệ thống đưa vào màn thiết lập mã PIN **trước khi hiển thị bất kỳ nội dung nào**, không có nút bỏ qua.
2. Người dùng nhập mã PIN 4 số (mỗi ký tự hiển thị dạng chấm tròn) bằng bàn phím số.
3. Hệ thống yêu cầu nhập lại lần hai để xác nhận; hai lần khớp nhau → mã PIN được lưu và kích hoạt, người dùng vào thẳng nội dung app (không bị hỏi lại ngay trong phiên vừa thiết lập).
4. Hai lần không khớp → báo lỗi và cho nhập lại từ đầu.
5. Kể từ đó, mỗi lần mở app người dùng phải nhập đúng mã PIN (xem luồng 2) mới vào được nội dung.

**2. Mở khóa mỗi lần vào app (các lần sau)**

1. Người dùng mở app khi khóa đang có hiệu lực → hệ thống hiện **màn hình khóa toàn màn hình** trước tiên: biểu tượng khóa, dòng "Nhập mã PIN" kèm nhãn nhắc, dãy 4 chấm tròn và bàn phím số.
2. Người dùng nhập mã PIN 4 số bằng bàn phím số.
3. Nhập đúng → màn hình khóa biến mất, vào thẳng nội dung app, đúng màn đang đứng trước khi khóa.
4. Nhập sai → báo lỗi, xóa các ký tự vừa nhập, cho nhập lại; nhập sai liên tiếp đạt ngưỡng → bị khóa tạm thời một khoảng thời gian tăng dần, hết thời gian chờ mới nhập tiếp được.

### Kịch bản chấp nhận

1. **Given** thiết bị chưa từng có mã PIN **When** người dùng mở app lần đầu **Then** hệ thống yêu cầu thiết lập mã PIN trước khi hiển thị bất kỳ nội dung nào, không thể bỏ qua.
2. **Given** người dùng đang ở màn thiết lập mã PIN lần đầu **When** nhập mã PIN 4 số hai lần giống nhau **Then** mã PIN được kích hoạt và người dùng vào được nội dung app.
3. **Given** người dùng đang ở màn thiết lập mã PIN **When** nhập lần hai không khớp lần một **Then** hệ thống báo lỗi, chưa kích hoạt mã PIN và cho nhập lại từ đầu.
4. **Given** khóa ứng dụng đang có hiệu lực **When** người dùng mở app **Then** màn hình khóa hiện ra trước; không thấy bất kỳ nội dung tài chính nào phía sau.
5. **Given** màn hình khóa đang hiện **When** người dùng nhập đúng mã PIN **Then** vào được nội dung app, đúng màn đang đứng trước khi khóa.
6. **Given** màn hình khóa đang hiện **When** người dùng nhập sai mã PIN 5 lần liên tiếp **Then** bị khóa tạm thời, không nhập tiếp được cho tới khi hết thời gian chờ.

### Trường hợp biên

- Nhập chưa đủ 4 chữ số → hệ thống chưa kiểm tra, chờ nhập tiếp hoặc cho xóa bớt.
- Nhập sai rồi sửa giữa chừng bằng phím xóa → bộ đếm số lần sai chỉ tính khi một lần thử 4 chữ số sai hoàn chỉnh.
- Đang ở màn hình khóa mà app bị đưa xuống nền rồi quay lại → vẫn ở màn hình khóa, không lộ nội dung.
- Người dùng dùng nút quay lại / cử chỉ quay lại của hệ thống ngay tại màn hình khóa hoặc màn thiết lập → không được vượt qua để vào nội dung.
- Người dùng thoát/thoát hẳn app giữa chừng khi đang thiết lập lần đầu (chưa nhập xong 2 lần khớp) → mã PIN chưa được kích hoạt; lần mở app sau vẫn phải hoàn tất thiết lập trước khi vào nội dung (không lách được bằng cách thoát app).
- Vừa hoàn tất thiết lập mã PIN trong phiên hiện tại → không ép người dùng nhập lại mã PIN ngay; khóa có hiệu lực từ lần vào app sau.
- Thiết bị hết pin/khởi động lại trong khi khóa đang có hiệu lực → mở lại vẫn phải nhập mã PIN.
- Đang bị khóa tạm thời do nhập sai mà người dùng thoát hẳn app rồi mở lại → thời gian chờ vẫn còn hiệu lực, không nhập được cho tới khi hết giờ.
- Bật độ lớn cỡ chữ / màn hình nhỏ → bàn phím số và chấm mã PIN hiển thị đầy đủ, không vỡ bố cục.

## Yêu cầu chức năng

- **FR-001**: Khi mở app lần đầu trên một thiết bị chưa từng có mã PIN, hệ thống PHẢI đưa người dùng vào luồng thiết lập mã PIN trước khi hiển thị bất kỳ nội dung nào và KHÔNG được phép bỏ qua.
- **FR-002**: Trong luồng thiết lập, hệ thống PHẢI yêu cầu người dùng nhập mã PIN mới rồi nhập lại lần hai để xác nhận; chỉ kích hoạt khi hai lần nhập khớp nhau.
- **FR-003**: Mã PIN PHẢI gồm đúng 4 chữ số (0–9); mỗi ký tự khi nhập PHẢI hiển thị dạng chấm tròn, KHÔNG hiển thị chữ số thật.
- **FR-004**: Hai lần nhập không khớp → hệ thống PHẢI báo lỗi rõ ràng và cho nhập lại từ đầu; nếu người dùng thoát hẳn app khi chưa hoàn tất, mã PIN PHẢI không được kích hoạt và lần mở sau vẫn phải hoàn tất thiết lập.
- **FR-005**: Khi mã PIN đã được thiết lập, mỗi lần khởi động app hoặc trở về app từ nền, hệ thống PHẢI hiện màn hình khóa toàn màn hình chặn trước toàn bộ nội dung; người dùng chỉ vào được nội dung khi nhập đúng mã PIN.
- **FR-006**: Người dùng PHẢI xóa được ký tự vừa nhập (phím xóa) để sửa trước khi hoàn tất một lần thử.
- **FR-007**: Nhập đúng mã PIN → hệ thống PHẢI mở khóa và đưa người dùng về đúng màn đang đứng trước khi khóa, không đặt lại về màn đầu.
- **FR-008**: Nhập sai mã PIN → hệ thống PHẢI báo lỗi, xóa các ký tự vừa nhập và cho nhập lại.
- **FR-009**: Nhập sai 5 lần liên tiếp → hệ thống PHẢI chặn việc nhập trong 30 giây; mỗi lần tái phạm (một chuỗi chưa mở khóa thành công) thời gian chặn PHẢI tăng dần theo bậc 30 giây → 1 phút → 5 phút → 15 phút (trần); nhập đúng thì bộ đếm về 0. Thời gian chặn còn lại PHẢI được giữ nguyên kể cả khi người dùng thoát hẳn app.
- **FR-010**: Màn hình khóa và màn thiết lập mã PIN PHẢI không cho phép người dùng vượt qua để vào nội dung bằng nút quay lại / cử chỉ quay lại của hệ thống.
- **FR-011**: Mã PIN PHẢI được lưu an toàn trên thiết bị, không hiển thị hoặc ghi lại ở dạng đọc được.
- **FR-012**: Màn hình khóa và màn thiết lập mã PIN PHẢI hiển thị đúng, không vỡ hoặc bị che khuất trên các kích thước màn hình, vùng an toàn và thiết lập cỡ chữ khác nhau (điện thoại).

## Tiêu chí thành công

- **SC-001**: Người dùng mở app lần đầu và hoàn tất thiết lập mã PIN (hai lần khớp) trong dưới 2 phút, không cần trợ giúp.
- **SC-002**: Kiểm tra 10 lần khởi động/resume app khi mã PIN đã thiết lập → cả 10 lần màn hình khóa xuất hiện trước và không lộ bất kỳ nội dung tài chính nào phía sau (đạt 10/10).
- **SC-003**: Nhập đúng mã PIN ngay lần đầu → vào được nội dung trong dưới 3 giây kể từ khi gõ đủ ký tự thứ 4.
- **SC-004**: Nhập sai 5 lần liên tiếp → người dùng không nhập tiếp được ít nhất 30 giây; hết thời gian, nhập đúng → mở khóa bình thường.
- **SC-005**: Không tồn tại đường thao tác (nút/cử chỉ quay lại, thoát rồi mở lại app) giúp vào nội dung mà không thiết lập hoặc nhập đúng mã PIN (đánh giá định tính).
- **SC-006**: Người dùng thoát app giữa chừng lúc thiết lập (chưa xong) → lần mở sau vẫn phải hoàn tất thiết lập, không vào được nội dung (đánh giá định tính).
- **SC-007**: Bật cỡ chữ lớn nhất hỗ trợ và trên màn hình có vùng an toàn → bàn phím số, chấm mã PIN và thông báo hiển thị đầy đủ, không vỡ bố cục.

## Thực thể chính

- **Mã PIN thiết bị**: gắn với 1 bản cài đặt app trên 1 thiết bị. Thuộc tính chính: giá trị mã PIN 4 số (bảo mật), cờ đã thiết lập, dữ liệu chống dò (số lần sai liên tiếp, thời điểm hết thời gian chặn). Quan hệ: độc lập với dữ liệu ví/giao dịch — thiết lập/mở khóa bằng mã PIN không làm thay đổi dữ liệu tài chính.

## Giả định

- Mã PIN được thiết lập **bắt buộc ngay lần đầu mở app** và khóa ứng dụng luôn có hiệu lực trong đợt này (không có luồng tắt khóa). **Quyết định này lệch tài liệu nghiệp vụ** `chi-tiet-quan-ly-tai-khoan-nguoi-dung.md` §2.1 (vốn: "bật/tắt khóa app tùy chọn, không bắt buộc") — người dùng đã chốt bắt buộc cho giai đoạn này; khi nghiệp vụ chốt chính thức cần cập nhật tài liệu + wiki (Hồ sơ & Bảo mật, Lộ trình phát triển).
- Vì Onboarding hoàn chỉnh (chọn tiền tệ, tạo ví...) chưa tồn tại, luồng thiết lập mã PIN lần đầu đứng độc lập ngay sau khi mở app; Onboarding về sau sẽ gắn vào trước/sau luồng này.
- Thời điểm khóa: mỗi lần khởi động app và mỗi lần trở về từ nền, bất kể thời gian vắng mặt. Cơ chế "tự khóa sau khoảng thời gian không thao tác trong lúc app mở" là tùy chỉnh nâng cao, để đợt sau.
- Chính sách chống dò (chốt đợt này): sai 5 lần liên tiếp → chặn 30 giây; tái phạm tăng dần 30 giây → 1 phút → 5 phút → 15 phút; nhập đúng → đếm về 0; thời gian chặn giữ nguyên khi thoát app.
- Độ dài mã PIN **cố định 4 số** trong đợt này (khớp mockup `02-khoa-pin.svg` minh họa 4 chấm); hỗ trợ chọn độ dài 4/6 là nâng cấp để đợt sau.
- Mã PIN gồm chữ số; không chứa ký tự khác. Người dùng đặt mã dễ đoán (ví dụ `0000`, `1234`) → hệ thống nhắc cảnh báo nhưng vẫn cho phép nếu người dùng xác nhận tiếp (đã chốt trong tài liệu nghiệp vụ — không chặn cứng).
- Thông báo khi nhập sai chỉ nhắc chung "mã PIN không đúng", không tiết lộ ký tự nào đúng/sai.
- Trong đợt này chưa có sinh trắc học (PBI riêng) → bàn phím số không hiển thị nút mở khóa bằng vân tay; vị trí tương ứng để trống theo thiết kế.
- Hành vi "quên mã PIN" và "đổi mã PIN" có quy trình riêng → không nằm đợt này.
- "Xóa toàn bộ dữ liệu sau nhiều lần sai" không được bật mặc định (rủi ro mất dữ liệu tài chính) → ngoài đợt này.

## Ngoài phạm vi

- Mở khóa bằng sinh trắc học (vân tay, Face ID) và các quy tắc quản lý trạng thái sinh trắc.
- Đổi mã PIN (khi còn nhớ mã cũ) và cơ chế xử lý quên mã PIN.
- Tắt khóa ứng dụng, và tùy chọn "tự khóa sau thời gian không thao tác".
- Màn Onboarding hoàn chỉnh (chọn tiền tệ, tạo ví...) và hồ sơ cá nhân.
- Tùy chọn "tự xóa dữ liệu sau nhiều lần nhập sai" và chọn độ dài mã PIN 4/6.
- Backup/khôi phục dữ liệu (liên quan khi quên mã PIN hoặc đổi máy).
- Mã hóa toàn bộ dữ liệu local và chế độ ẩn số dư (Privacy mode).
