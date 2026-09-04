# Đặc tả tính năng: Màn hình danh sách ví

**Mã PBI**: 5
**Ngày tạo**: 2026-09-04
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Người dùng cần một nơi nhìn toàn cảnh các ví/tài khoản tiền của mình (tiền mặt, tài khoản ngân hàng, thẻ tín dụng, ví điện tử, sổ tiết kiệm) cùng tổng số dư. Tính năng này dựng **màn hình danh sách ví** — sub-page mở từ hàng "Quản lý ví" trong Cài đặt (đã dựng ở PBI 4) — theo đúng thiết kế `docs/wallet/wallet-list-screen.svg`: card tổng số dư ở đầu, bên dưới là danh sách từng ví kèm số dư hiện tại, loại ví, nhãn ví mặc định và trạng thái ẩn. Đợt này chỉ **hiển thị và điều hướng điểm vào**: luồng thêm/sửa/ẩn/xóa ví (form), xem chi tiết ví và chuyển tiền giữa ví nằm ở PBI riêng, mỗi mục là một điểm vào chưa kích hoạt.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính

1. Người dùng mở app, mở khóa bằng mã PIN, vào tab **Cài đặt**, chạm hàng **"Quản lý ví"** → màn danh sách ví mở ra (app bar màu thương hiệu có nút quay lại, không có thanh điều hướng đáy).
2. Đầu màn hiện card tổng số dư: nhãn "TỔNG SỐ DƯ TẤT CẢ VÍ", số tổng (định dạng tiền, đơn vị `đ`) và dòng phụ số lượng ví đang hoạt động (không tính ví ẩn).
3. Bên dưới là danh sách các ví đang hoạt động theo thứ tự hiển thị hiện có: mỗi ví một hàng gồm biểu tượng, tên ví, dòng phụ (loại ví / nhãn "Mặc định" / thông tin thẻ tín dụng), và số dư hiện tại căn phải. Ví được đánh dấu mặc định hiển thị nhãn "Mặc định".
4. Thẻ tín dụng hiển thị dưới dạng sử dụng: dòng phụ "Đã dùng X / hạn mức Y đ" và phần trăm sử dụng ở bên phải (ngữ cảnh chi tiêu).
5. Ví đã ẩn hiển thị cuối danh sách ở trạng thái mờ (xám), tên kèm "đã ẩn", dòng phụ "Không tính vào tổng"; số dư vẫn hiển thị nhưng không nằm trong card tổng.
6. Người dùng chạm một ví cụ thể hoặc nút "+ Thêm ví mới" → đợt này chưa mở luồng nào (là điểm vào của PBI sau), không gây lỗi. Nút quay lại đưa người dùng về màn Cài đặt.

### Kịch bản chấp nhận

1. **Given** người dùng đã mở khóa và đang ở Cài đặt **When** chạm hàng "Quản lý ví" **Then** màn danh sách ví mở ra đúng bố cục thiết kế: app bar tiêu đề "Quản lý ví" có nút quay lại, card tổng số dư, tiêu đề nhóm danh sách ví.
2. **Given** thiết bị có nhiều ví các loại (tiền mặt, ngân hàng, thẻ tín dụng, ví điện tử, sổ tiết kiệm ẩn) **When** xem màn danh sách ví **Then** mỗi ví hiển thị đúng biểu tượng, tên, dòng phụ và số dư; tổng số dư đúng bằng tổng số dư các ví đang hoạt động; ví ẩn hiển thị mờ cuối danh sách.
3. **Given** thẻ tín dụng đã dùng 6.500.000 trên hạn mức 20.000.000 **When** xem màn danh sách **Then** hàng thẻ tín dụng hiển thị "Đã dùng 6.500.000 / 20.000.000 đ" và "32%" — không hiển thị dưới dạng số dư dương thông thường.
4. **Given** một ví được đánh dấu là ví mặc định **When** xem màn danh sách **Then** ví đó hiển thị nhãn "Mặc định" và chỉ có đúng một ví mang nhãn này.
5. **Given** thiết bị chưa tạo ví nào **When** mở màn danh sách ví **Then** màn hiển thị trạng thái rỗng rõ ràng (không lỗi, không vỡ bố cục) và vẫn có nút "+ Thêm ví mới".
6. **Given** người dùng đang ở màn danh sách ví **When** chạm một ví hoặc nút "+ Thêm ví mới" **Then** không có màn mới mở ra và không phát sinh lỗi.
7. **Given** người dùng chạm nút quay lại **When** rời màn danh sách ví **Then** trở về màn Cài đặt đúng trạng thái như lúc rời đi.
8. **Given** người dùng bật cỡ chữ lớn nhất hỗ trợ hoặc dùng màn hình có vùng an toàn **When** xem màn danh sách ví **Then** nội dung hiển thị đầy đủ, không vỡ hay tràn khỏi màn hình.

### Trường hợp biên

- Ví có số dư âm (ví tiền mặt bị chi quá tay) → số dư hiển thị kèm dấu âm, không gãy định dạng, không bị nhầm là dữ liệu lỗi.
- Tên ví dài hoặc nhiều ví trong danh sách → tên được cắt gọn không đẩy vỡ bố cục; danh sách cuộn được, nút "+ Thêm ví mới" không bị che.
- Ví mặc định nằm cuối danh sách → nhãn "Mặc định" vẫn hiển thị rõ, không bị cắt.
- Cả ví tiền mặt và ví thẻ tín dụng đều hiện diện → hai dạng hiển thị số (số dư dương thường / "đã dùng – hạn mức") phân biệt rõ, không lẫn.
- Ví đã ẩn có số dư lớn → vẫn hiển thị mờ và bị loại khỏi tổng số dư đúng.
- Chạm nhanh liên tục vào các hàng / nút chưa có chức năng → không lỗi, không mở màn ngoài ý muốn.
- Khóa app đang có hiệu lực → màn danh sách ví chỉ hiển thị sau khi mở khóa, không lộ nội dung qua màn hình khóa.
- Ví chưa từng phát sinh giao dịch → số dư hiện tại bằng số dư ban đầu khi tạo, hiển thị bình thường.

## Yêu cầu chức năng

- **FR-001**: Màn danh sách ví PHẢI mở được từ hàng "Quản lý ví" trong Cài đặt (PBI 4); sau khi tính năng này hoàn tất, chạm hàng đó PHẢI điều hướng sang màn này thay vì đứng im.
- **FR-002**: Màn danh sách ví PHẢI là sub-page theo thiết kế `docs/wallet/wallet-list-screen.svg`: app bar tiêu đề "Quản lý ví" màu thương hiệu có nút quay lại, không có thanh điều hướng đáy.
- **FR-003**: Đầu màn PHẢI hiển thị card tổng số dư gồm: nhãn "TỔNG SỐ DƯ TẤT CẢ VÍ", giá trị tổng số dư và dòng phụ "N ví đang hoạt động" (N là số ví đang hoạt động, không đếm ví ẩn).
- **FR-004**: Giá trị tổng số dư PHẢI bằng tổng số dư hiện tại của các ví đang hoạt động; ví đã ẩn KHÔNG được tính vào tổng.
- **FR-005**: Màn PHẢI liệt kê toàn bộ ví hiện có trên thiết bị, mỗi ví một hàng hiển thị: biểu tượng ví, tên ví, dòng phụ và số dư hiện tại căn phải theo định dạng tiền tệ (phân tách nghìn, đơn vị `đ`).
- **FR-006**: Dòng phụ của mỗi ví PHẢI hiển thị loại ví; ví được đánh dấu mặc định PHẢI hiển thị nhãn "Mặc định", và tại mọi thời điểm chỉ có đúng một ví mang nhãn này.
- **FR-007**: Thẻ tín dụng PHẢI hiển thị theo dạng sử dụng: dòng phụ "Đã dùng X / hạn mức Y đ" và phần trăm sử dụng (tỷ lệ đã dùng trên hạn mức) ở phía phải, dùng ngữ cảnh màu chi tiêu; không hiển thị dưới dạng số dư dương thông thường.
- **FR-008**: Ví đã ẩn PHẢI hiển thị trong danh sách ở cuối, làm mờ (xám), tên kèm ghi chú "đã ẩn" và dòng phụ "Không tính vào tổng"; số dư hiển thị nhưng KHÔNG đóng góp vào card tổng.
- **FR-009**: Khi thiết bị chưa có ví nào, màn PHẢI hiển thị trạng thái rỗng rõ ràng, không báo lỗi và không vỡ bố cục.
- **FR-010**: Chạm một hàng ví bất kỳ hoặc nút "+ Thêm ví mới" PHẢI không gây lỗi; đợt này chưa mở luồng chức năng (điểm vào cho PBI chi tiết ví / thêm-sửa ví sau).
- **FR-011**: Giá trị số tiền trên màn PHẢI căn phải và đúng định dạng tiền tệ đã chốt trong design system (dấu chấm phân tách nghìn, đơn vị `đ`); số dư âm hiển thị kèm dấu trừ rõ ràng.
- **FR-012**: Màn danh sách ví PHẢI phản ánh đúng dữ liệu ví hiện tại mỗi lần mở (thêm/sửa/ẩn ví ở PBI sau làm thay đổi nguồn dữ liệu → danh sách hiển thị đúng).
- **FR-013**: Màn danh sách ví PHẢI cuộn được khi nội dung dài; nút "+ Thêm ví mới" PHẢI luôn hiển thị và không bị che.
- **FR-014**: Màn danh sách ví PHẢI hiển thị đúng, không vỡ hoặc bị che khuất trên các kích thước màn hình, vùng an toàn và thiết lập cỡ chữ khác nhau (điện thoại).
- **FR-015**: Màn danh sách ví PHẢI chỉ hiển thị khi app đã được mở khóa; không được để người dùng nhìn thấy nội dung màn này qua màn hình khóa.

## Tiêu chí thành công

- **SC-001**: Vào được màn danh sách ví từ hàng "Quản lý ví" trong Cài đặt chỉ trong không quá 1 thao tác chạm sau khi đã ở tab Cài đặt.
- **SC-002**: Đối chiếu trực quan với thiết kế `wallet-list-screen.svg`: card tổng số dư, tiêu đề nhóm danh sách và từng hàng ví hiển thị đủ, đúng thứ tự, đúng màu ngữ cảnh (thu/chi) khi dữ liệu đầu vào tương ứng.
- **SC-003**: Với bộ dữ liệu mẫu gồm 5 ví (3 ví thường, 1 thẻ tín dụng, 1 ví ẩn), tổng số dư hiển thị khớp 100% với tổng thủ công các ví đang hoạt động; ví ẩn không làm lệch tổng.
- **SC-004**: Số dư / "đã dùng – hạn mức" / phần trăm / tổng số dư hiển thị chính xác từng giá trị (không làm tròn sai, không sai đơn vị `đ`) khi đối chiếu với số liệu gốc.
- **SC-005**: Chạm lần lượt toàn bộ các hàng ví và nút "+ Thêm ví mới" trong một lượt dùng → 0 lỗi phát sinh, không có màn hình không mong muốn mở ra.
- **SC-006**: Mở màn danh sách ví trên bản cài đặt chưa có ví nào → hiển thị trạng thái rỗng rõ ràng, không lỗi, nút thêm ví vẫn còn.
- **SC-007**: Bật cỡ chữ lớn nhất hỗ trợ và xem trên màn hình có vùng an toàn → mọi thành phần (app bar, card tổng, hàng ví, nút thêm) hiển thị đầy đủ, không vỡ hay tràn.
- **SC-008**: Không tồn tại thao tác nào trên màn danh sách ví đợt này làm thay đổi dữ liệu ví (thêm/sửa/ẩn/xóa) — xác nhận màn ở chế độ chỉ hiển thị (đánh giá định tính).

## Thực thể chính

- **Ví / tài khoản (wallet)**: nguồn dữ liệu cho danh sách. Mỗi ví có: tên, loại ví (tiền mặt, tài khoản ngân hàng, thẻ tín dụng, ví điện tử, sổ tiết kiệm), biểu tượng, tiền tệ, số dư ban đầu và số dư hiện tại (số dư hiện tại là đại lượng suy ra từ giao dịch, không sửa tay). Trạng thái liên quan đến hiển thị đợt này: cờ "ví mặc định" (tối đa một ví), cờ "đã ẩn" (giữ lịch sử, không xóa), thứ tự hiển thị. Riêng thẻ tín dụng có thêm hạn mức, ngày sao kê, ngày đến hạn. Chưa có luồng tạo/sửa ví trong đợt này nên dữ liệu ví được cấp bởi nguồn dữ liệu cục bộ khi phát triển.

## Giả định

- Đợt này chỉ dựng **màn danh sách ví** theo mockup `wallet-list-screen.svg` — màn đầu tiên của module Ví, đóng vai trò trung tâm điều hướng. Luồng con là PBI riêng: thêm/sửa ví (`wallet-add-edit-form.svg`), chi tiết một ví (`wallet-detail-screen.svg`), chuyển tiền giữa ví (`wallet-transfer-screen.svg`). Khi PBI tương ứng hoàn tất, hàng đó chuyển từ "chưa kích hoạt" sang điều hướng thật mà không phá cấu trúc màn.
- Khi PBI 5 hoàn tất, hàng "Quản lý ví" ở Cài đặt (PBI 4 đang để chưa kích hoạt) sẽ điều hướng thật sang màn này — đây là điểm nối giữa hai PBI.
- Ví chưa từng có giao dịch → số dư hiện tại bằng số dư ban đầu khi tạo. Số dư ban đầu được khởi tạo bởi luồng tạo ví (PBI sau); nguồn dữ liệu trong đợt này phải cấp được dữ liệu ví mẫu để kiểm chứng hiển thị.
- Trạng thái "chưa có ví nào" sẽ xảy ra trên bản cài đặt mới vì chưa có luồng tạo ví; thiết kế tham chiếu không kèm mockup trạng thái rỗng nên cách hiển thị cụ thể được chốt khi lập kế hoạch, miễn đạt SC-006.
- Con số "5 ví đang hoạt động" và "28.450.000 đ" trong mockup mang tính minh họa; giá trị thật được tính từ dữ liệu thiết bị. Màn hiển thị ví ẩn theo đúng mockup (mờ, cuối danh sách) để người dùng nhận biết ví vẫn tồn tại dù đã ẩn.
- Các ví đợt này dùng chung tiền tệ mặc định của thiết bị (mặc định "VND") nên tổng số dư cộng trực tiếp. Quy đổi đa tiền tệ theo tỷ giá (nguồn tỷ giá offline chưa chốt) nằm ngoài đợt này.
- App dùng chủ yếu theo chiều dọc trên điện thoại; tablet/đa cửa sổ chưa phải mục tiêu. Ngôn ngữ giao diện đợt này là tiếng Việt.

## Ngoài phạm vi

- Tạo / sửa / ẩn / xóa ví (form thêm-sửa) và các quy tắc kèm theo (số dư ban đầu bất biến, cảnh báo khi ẩn ví đã có giao dịch, chuyển ví mặc định khi xóa/ẩn ví đang mặc định).
- Màn chi tiết một ví (số dư lớn, hành động nhanh, giao dịch gần đây).
- Chuyển tiền giữa các ví (transfer) và toàn bộ ràng buộc liên quan (tỷ giá, phí, hai bút toán liên kết).
- Sắp xếp danh sách ví bằng kéo-thả và quản lý thứ tự hiển thị thủ công.
- Chế độ Privacy "ẩn số dư" (`••••••`) — chưa có module quyền riêng tư trong lộ trình hiện tại.
- Hiển thị nhãn ngân hàng / số cuối tài khoản và các thông tin định danh tài khoản.
