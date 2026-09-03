# Đặc tả tính năng: Hạ tầng thư viện nền tảng

**Mã PBI**: 1
**Ngày tạo**: 2026-09-03
**Trạng thái**: Nháp

## Mô tả tổng quan

App hiện mới chỉ là khung chương trình mặc định (màn hình counter demo) — chưa có bất kỳ thư viện hỗ trợ nào cho tính năng nghiệp vụ. Tính năng này cài đặt bộ thư viện nền tảng đã được quyết định trong tài liệu kiến trúc, đúng phiên bản tương thích, sao cho dự án build và chạy ổn định trên thiết bị di động. Đây là bước nền tảng: sau khi hoàn tất, đội phát triển có thể bắt đầu dựng các module nghiệp vụ (ví, giao dịch, danh mục, báo cáo, khóa app) mà không gặp trở ngại về môi trường.

## Kịch bản & luồng người dùng

Tác nhân: nhà phát triển (người thi công dự án). Không phải luồng người dùng cuối.

### Luồng chính
- Nhà phát triển thêm bộ thư viện nền tảng cho các năng lực: lưu trữ dữ liệu cục bộ, quản lý trạng thái/điều hướng màn hình, vẽ biểu đồ báo cáo, lưu bí mật an toàn (mã PIN, khóa) và xác thực sinh trắc học.
- Mỗi thư viện được chọn phiên bản tương thích với công cụ phát triển hiện tại và được khóa phiên bản để cài đặt lặp lại được.
- Phần cấu hình riêng cho nền tảng di động (nếu thư viện yêu cầu) được chỉnh tối thiểu đủ để thư viện hoạt động.
- Sau khi cài đặt, dự án được kiểm chứng: biên dịch thành công, ứng dụng khởi động bình thường trên thiết bị/máy ảo, màn hình hiện có không vỡ.

### Kịch bản chấp nhận
1. Cho một dự án Flutter mới chỉ có khung mặc định → sau khi áp dụng tính năng này, dự án có đủ thư viện nền tảng theo danh sách đã quyết định và khởi động bình thường.
2. Cho một lệnh xây dựng lại dự án từ đầu (máy mới) → quy trình cài đặt ghi lại được thực hiện lại được, không bước nào phụ thuộc thao tác tay bí mật.
3. Cho một thiết bị/máy ảo chạy nền tảng đang hỗ trợ → ứng dụng mở màn hình mặc định, không báo lỗi do thư viện gây ra.

### Trường hợp biên
- Có thư viện yêu cầu cấu hình nền tảng (quyền, dịch vụ hệ thống) → phần cấu hình được bổ sung tối thiểu, không triển khai logic nghiệp vụ.
- Nền tảng iOS không có sẵn trên máy phát triển (cần máy macOS) → kết quả kiểm chứng iOS được ghi nhận riêng, không chặn tiến độ.
- Hai thư viện xung đột phiên bản/transitive → chọn bộ phiên bản cùng hoạt động, ghi lại lý do.

## Yêu cầu chức năng

- **FR-001**: Dự án PHẢI có sẵn thư viện nền tảng phục vụ các năng lực nghiệp vụ trong phạm vi MVP: lưu trữ & truy vấn dữ liệu cục bộ, quản lý trạng thái/điều hướng màn hình, vẽ biểu đồ cho báo cáo, lưu trữ bí mật an toàn và xác thực sinh trắc học.
- **FR-002**: Mỗi thư viện trong danh sách PHẢI được ghi với phiên bản cụ thể, đã khóa (không để "bản mới nhất trôi nổi").
- **FR-003**: Dự án PHẢI biên dịch thành công sau khi thêm toàn bộ thư viện, không có lỗi kiểm tra mã nguồn mới phát sinh do thư viện.
- **FR-004**: Ứng dụng PHẢI khởi động bình thường trên nền tảng di động đang hỗ trợ; màn hình mặc định hiện có vẫn chạy được.
- **FR-005**: Cấu hình nền tảng cần thiết cho thư viện PHẢI được bổ sung tối thiểu, đúng nơi quy định.
- **FR-006**: Quy trình cài đặt PHẢI được ghi lại đầy đủ để một máy phát triển khác làm theo được từ đầu.

## Tiêu chí thành công

- **SC-001**: Làm theo đúng quy trình ghi lại trên một bản sao dự án sạch → cài đặt & biên dịch thành công, không lỗi.
- **SC-002**: Ứng dụng chạy trên thiết bị/máy ảo không bị treo hoặc báo lỗi lúc khởi động do thư viện.
- **SC-003**: Mỗi thư viện được kiểm chứng bằng một đoạn mã nhỏ gọi được vào đối tượng chính của thư viện → kết quả chạy đúng như dự kiến, chứng tỏ thư viện nạp & hoạt động được.
- **SC-004**: Không có lỗi phân tích mã nguồn (analyze) phát sinh từ việc thêm thư viện.
- **SC-005**: Trên nền tảng có sẵn để kiểm chứng (Android), kết quả đạt đầy đủ; nền tảng chưa kiểm chứng được thì ghi rõ trạng thái và lý do, không bỏ ngang.

## Giả định

- "Cần thiết theo nghiệp vụ đã quyết" = bộ thư viện phục vụ tính năng trong **phạm vi MVP** (khóa app, quản lý ví, giao dịch, danh mục, báo cáo cơ bản). Thư viện phục vụ tính năng giai đoạn sau (thông báo định kỳ, sao lưu/khôi phục) **chưa cài trong đợt này** để tránh thư viện chết/nhỡ phiên bản; sẽ bổ sung đúng giai đoạn phát triển.
- Danh sách thư viện cụ thể, phiên bản và xử lý nền tảng chi tiết nằm ở tài liệu kỹ thuật (kế hoạch triển khai), đặc tả này không liệt kê.
- Nền tảng kiểm chứng chính: Android. Kiểm chứng iOS thực hiện nếu máy phát triển là macOS.
- Mọi thư viện chọn phiên bản tương thích với bộ công cụ Flutter/Dart hiện có của dự án.

## Ngoài phạm vi

- Dựng logic nghiệp vụ của từng module (bảng dữ liệu, màn hình, xử lý thu/chi…) — các PBI riêng.
- Thư viện cho tính năng giai đoạn 2/3.
- Mã hóa toàn bộ dữ liệu, sao lưu/khôi phục dữ liệu thật.
