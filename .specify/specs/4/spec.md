# Đặc tả tính năng: Màn hình Cài đặt

**Mã PBI**: 4
**Ngày tạo**: 2026-09-04
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Trong khung điều hướng (đã xây ở PBI 2), tab **Cài đặt** hiện chỉ là màn khung trống. Tính năng này dựng nội dung của tab Cài đặt thành một **màn trung tâm cài đặt** theo đúng thiết kế `docs/auth/04-ho-so-ca-nhan.svg`: hiển thị hồ sơ thiết bị (tên hiển thị, ảnh đại diện dạng chữ viết tắt, tiền tệ mặc định) cùng các nhóm mục cài đặt làm **điểm vào** cho những chức năng sẽ triển khai ở PBI riêng (đổi mã PIN, mở khóa sinh trắc học, quản lý ví…). Đợt này chỉ dựng cấu trúc màn hình và dữ liệu hiển thị; các luồng sửa đổi / điều hướng sâu của từng mục nằm ngoài phạm vi.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính

1. Người dùng mở app, mở khóa bằng mã PIN, chạm tab **Cài đặt** ở thanh điều hướng đáy → màn Cài đặt hiện ra: vùng tiêu đề, khối hồ sơ (avatar tròn + tên hiển thị + dòng phụ), nhóm **TÀI KHOẢN** và nhóm **KHÁC**; tab Cài đặt được làm nổi bật là đang chọn.
2. Khối hồ sơ hiển thị tên hiển thị và ảnh đại diện chữ viết tắt lấy từ hồ sơ thiết bị. Với người dùng lần đầu (chưa từng đặt tên) → hiển thị giá trị mặc định, không để trống.
3. Người dùng cuộn xem các mục. Hàng nào chưa có chức năng trong đợt này (Đổi mã PIN, Quản lý ví, chạm để đổi ảnh) → chạm không mở ra luồng nào, không gây lỗi. Công tắc "Mở khóa sinh trắc học" hiển thị ở trạng thái tắt và không bật được.
4. Người dùng chuyển sang tab khác rồi quay lại tab Cài đặt → trở về đúng vị trí cuộn và trạng thái hiển thị như lúc rời đi.

### Kịch bản chấp nhận

1. **Given** người dùng đã mở khóa và đang ở tab Cài đặt **When** màn hình hiển thị **Then** thấy đúng bố cục thiết kế: khối hồ sơ, nhóm **TÀI KHOẢN** (Tiền tệ mặc định, Đổi mã PIN, Mở khóa sinh trắc học), nhóm **KHÁC** (Quản lý ví); tab Cài đặt được làm nổi bật.
2. **Given** hồ sơ thiết bị mới (chưa đặt tên, tiền tệ mặc định chưa đổi) **When** vào tab Cài đặt **Then** khối hồ sơ hiển thị tên mặc định kèm chữ cái viết tắt, hàng "Tiền tệ mặc định" hiển thị giá trị VND — không có ô trống hay vỡ bố cục.
3. **Given** màn Cài đặt đang hiển thị **When** chạm hàng "Đổi mã PIN" hoặc "Quản lý ví" **Then** không có màn hình mới mở ra và không phát sinh lỗi.
4. **Given** hàng "Mở khóa sinh trắc học" hiển thị (sinh trắc chưa được hỗ trợ) **When** chạm vào công tắc **Then** công tắc giữ nguyên trạng thái tắt, không bật lên.
5. **Given** người dùng đang ở tab Cài đặt và đã cuộn xuống **When** chuyển sang tab khác rồi quay lại **Then** trở về đúng vị trí cuộn lúc rời đi, không bị đặt lại từ đầu.
6. **Given** người dùng bật cỡ chữ lớn nhất hỗ trợ hoặc dùng màn hình có vùng an toàn **When** xem tab Cài đặt **Then** nội dung hiển thị đầy đủ, không vỡ hay tràn khỏi màn hình.

### Trường hợp biên

- Nội dung màn dài hơn màn hình → cuộn được; thanh điều hướng đáy giữ nguyên và không che nội dung quan trọng.
- Tên hiển thị rất dài hoặc chứa nhiều ký tự → được cắt gọn, không đẩy vỡ bố cục khối hồ sơ.
- Chạm nhanh, liên tục vào các hàng / công tắc chưa có chức năng → không lỗi, không mở màn ngoài ý muốn.
- Khóa app đang có hiệu lực (đã xây ở PBI 3) → tab Cài đặt chỉ hiển thị sau khi mở khóa, không lộ nội dung phía sau màn khóa.
- Đang ở một màn khác mà có dữ liệu hồ sơ thay đổi trong tương lai → màn Cài đặt phản ánh đúng giá trị mới khi quay lại (đợt này chưa có luồng sửa đổi nên không phát sinh).

## Yêu cầu chức năng

- **FR-001**: Tab Cài đặt PHẢI hiển thị màn Cài đặt theo thiết kế tham chiếu `docs/auth/04-ho-so-ca-nhan.svg`, gồm: vùng tiêu đề (tiêu đề "Cài đặt"), khối hồ sơ (avatar tròn, tên hiển thị, dòng phụ), nhóm "TÀI KHOẢN" và nhóm "KHÁC".
- **FR-002**: Khối hồ sơ PHẢI hiển thị tên hiển thị và ảnh đại diện (dạng chữ cái viết tắt của tên) lấy từ hồ sơ thiết bị; khi chưa có tên do người dùng đặt PHẢI hiển thị giá trị mặc định, không để vùng trống.
- **FR-003**: Nhóm "TÀI KHOẢN" PHẢI liệt kê đúng các hàng theo thiết kế: "Tiền tệ mặc định" (hiển thị giá trị tiền tệ mặc định ở bên phải), "Đổi mã PIN", "Mở khóa sinh trắc học".
- **FR-004**: Hồ sơ thiết bị PHẢI có giá trị tiền tệ mặc định; lần đầu tạo hồ sơ giá trị này là "VND" và hàng "Tiền tệ mặc định" PHẢI hiển thị đúng giá trị đó.
- **FR-005**: Nhóm "KHÁC" PHẢI liệt kê hàng "Quản lý ví" theo thiết kế.
- **FR-006**: Các hàng thuộc chức năng chưa triển khai trong đợt này ("Đổi mã PIN", "Quản lý ví", "Chạm để đổi ảnh đại diện") PHẢI hiển thị đầy đủ nhưng khi chạm KHÔNG mở luồng chức năng và KHÔNG gây lỗi — đóng vai trò điểm vào cho PBI sau.
- **FR-007**: Hàng "Mở khóa sinh trắc học" PHẢI hiển thị công tắc ở trạng thái tắt; vì sinh trắc học chưa được hỗ trợ trong giai đoạn này, người dùng chạm công tắc KHÔNG được làm nó bật lên.
- **FR-008**: Màn Cài đặt PHẢI cuộn được khi nội dung dài; thanh điều hướng đáy PHẢI giữ nguyên và không che nội dung.
- **FR-009**: Trong cùng một phiên dùng app, rời tab Cài đặt rồi quay lại PHẢI giữ nguyên vị trí cuộn và trạng thái hiển thị như lúc rời đi.
- **FR-010**: Màn Cài đặt PHẢI hiển thị đúng, không vỡ hoặc bị che khuất trên các kích thước màn hình, vùng an toàn và thiết lập cỡ chữ khác nhau (điện thoại).
- **FR-011**: Màn Cài đặt PHẢI chỉ hiển thị khi app đã được mở khóa; không được để người dùng nhìn thấy nội dung màn này qua màn hình khóa.

## Tiêu chí thành công

- **SC-001**: Trên một bản cài đặt sạch (chưa đặt tên), vào tab Cài đặt → khối hồ sơ hiển thị tên mặc định kèm chữ cái viết tắt và hàng tiền tệ mặc định hiển thị "VND"; không có vùng trống (đánh giá định tính trên lần dùng đầu tiên).
- **SC-002**: Đối chiếu trực quan với thiết kế tham chiếu: màn hiển thị đủ khối hồ sơ và 2 nhóm với tổng 4 hàng đúng tên, đúng thứ tự.
- **SC-003**: Chạm lần lượt toàn bộ các hàng/công tắc chưa có chức năng trong một lượt dùng → 0 lỗi phát sinh, không có màn hình không mong muốn mở ra, công tắc sinh trắc học giữ nguyên trạng thái tắt.
- **SC-004**: Chuyển tab qua lại ít nhất 5 lần sau khi đã cuộn tab Cài đặt → vị trí cuộn được giữ nguyên, không bị đặt lại từ đầu.
- **SC-005**: Bật cỡ chữ lớn nhất hỗ trợ và xem trên màn hình có vùng an toàn → mọi thành phần (tên, hàng, nhóm, thanh điều hướng) hiển thị đầy đủ, không vỡ hay tràn.
- **SC-006**: Không tồn tại thao tác nào trên màn Cài đặt đợt này làm thay đổi dữ liệu hồ sơ thiết bị (đánh giá định tính) — xác nhận màn hiện ở chế độ chỉ hiển thị.

## Thực thể chính

- **Hồ sơ thiết bị (device profile)**: duy nhất một hồ sơ cho mỗi bản cài đặt app trên một thiết bị, được tạo với giá trị mặc định khi người dùng lần đầu vào nội dung app. Các giá trị màn Cài đặt hiển thị trong đợt này: tên hiển thị (mặc định khi chưa đặt), ảnh đại diện dạng chữ cái viết tắt của tên, tiền tệ mặc định (mặc định "VND"). Độc lập với dữ liệu ví/giao dịch; về sau được mở rộng thêm trường và luồng sửa đổi.

## Giả định

- Đợt này chỉ dựng **màn trung tâm Cài đặt** theo mockup `04-ho-so-ca-nhan.svg`. Luồng con của từng hàng là PBI riêng: Đổi mã PIN (`05-doi-pin.svg`), Mở khóa sinh trắc học (`03-sinh-trac-hoc.svg`), Quản lý ví (module Ví), sửa hồ sơ và đổi tiền tệ mặc định. Khi PBI tương ứng hoàn tất, hàng đó chuyển từ "chưa kích hoạt" sang điều hướng thật mà không phá cấu trúc màn.
- Hồ sơ thiết bị khởi tạo lần đầu với **tên hiển thị mặc định** (chuỗi cụ thể chốt khi lập kế hoạch) vì chưa có màn Onboarding/đặt tên; ảnh đại diện dùng chữ cái viết tắt của tên đang hiển thị, chưa hỗ trợ chọn/chụp ảnh.
- Tiền tệ mặc định lần đầu là "VND" (khớp mockup). Quy tắc "đổi tiền tệ mặc định không hồi tố ví đã tạo" (trong tài liệu nghiệp vụ) chỉ áp dụng khi có luồng đổi tiền tệ — ngoài đợt này.
- Dòng phụ "Chạm để đổi ảnh đại diện" hiển thị theo thiết kế; đợt này chạm vào không có phản hồi (tính năng đổi ảnh nằm ở PBI sau).
- Màn Cài đặt hiện chỉ liệt kê các mục đã có trong thiết kế tham chiếu; các mục khác sẽ xuất hiện ở giai đoạn sau (quản lý danh mục, sao lưu/khôi phục, quyền riêng tư…) khi module tương ứng được triển khai.
- App dùng chủ yếu theo chiều dọc trên điện thoại; tablet/đa cửa sổ chưa phải mục tiêu đợt này. Ngôn ngữ giao diện trong đợt này là tiếng Việt.

## Ngoài phạm vi

- Luồng Đổi mã PIN (xác thực mã cũ → nhập/xác nhận mã mới) và cơ chế xử lý quên mã PIN.
- Mở khóa bằng sinh trắc học: bật/tắt, cấu hình, quy tắc quản lý trạng thái sinh trắc.
- Nội dung chức năng Quản lý ví — hàng chỉ là điểm vào.
- Sửa hồ sơ: đặt/đổi tên hiển thị, chọn hoặc chụp ảnh đại diện.
- Đổi tiền tệ mặc định và các ràng buộc kèm theo (không hồi tố, quy đổi).
- Các mục cài đặt của module chưa triển khai (danh mục, sao lưu/khôi phục, quyền riêng tư, múi giờ, định dạng, đa ngôn ngữ, chủ đề…).
- Hiển thị múi giờ trong hồ sơ — chưa có màn/consumer sử dụng.
