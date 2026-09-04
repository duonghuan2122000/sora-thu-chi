# Đặc tả tính năng: Màn hình chi tiết ví

**Mã PBI**: 6
**Ngày tạo**: 2026-09-04
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Người dùng chạm một ví trong màn danh sách ví (PBI 5) thì cần một màn nhìn sâu vào riêng ví đó: số dư hiện tại nổi bật, loại ví, ba hành động nhanh (chuyển tiền, sửa ví, ẩn ví) và các giao dịch gần đây thuộc ví. Tính năng này dựng **màn hình chi tiết ví** — sub-page mở từ danh sách ví — theo đúng thiết kế `docs/wallet/wallet-detail-screen.svg`: vùng teal đầu màn hiển thị tên ví, biểu tượng, số dư lớn và loại ví; bên dưới là ba nút hành động nhanh rồi nhóm "GIAO DỊCH GẦN ĐÂY" liệt kê giao dịch của ví. Đợt này chỉ **xem thông tin**: ba hành động nhanh và chạm một dòng giao dịch là các điểm vào của PBI sau (thêm/sửa ví, chuyển tiền, chi tiết giao dịch), chưa kích hoạt luồng nào.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính

1. Người dùng đang ở màn danh sách ví (PBI 5), chạm một ví bất kỳ (cả ví đang ẩn hiển thị mờ) → màn chi tiết ví đó mở ra (sub-page, app bar màu thương hiệu có nút quay lại, không có thanh điều hướng đáy).
2. Đầu màn là vùng teal: tên ví (đồng thời là tiêu đề app bar), biểu tượng ví trong vòng tròn, số dư hiện tại cỡ lớn màu trắng và dòng phụ tên loại ví (ví dụ "Tài khoản ngân hàng").
3. Bên dưới là ba hành động nhanh dạng nút tròn teal nhạt kèm nhãn: **Chuyển tiền**, **Sửa ví**, **Ẩn ví** — đợt này chỉ hiển thị, chạm không mở luồng (là điểm vào của PBI tương ứng sau).
4. Nhóm "GIAO DỊCH GẦN ĐÂY" liệt kê giao dịch thuộc ví, sắp theo ngày mới nhất lên đầu. Mỗi dòng gồm: biểu tượng tròn màu theo loại giao dịch, tiêu đề, dòng phụ "danh mục · ngày" và số tiền căn phải tô màu theo loại (thu + teal, chi − coral, chuyển khoản trung tính).
5. Người dùng chạm một dòng giao dịch → đợt này chưa mở màn nào (điểm vào của PBI Giao dịch), không gây lỗi. Chạm nút quay lại → trở về màn danh sách ví đúng trạng thái như lúc rời đi.

### Kịch bản chấp nhận

1. **Given** người dùng đang ở màn danh sách ví **When** chạm hàng của ví "Vietcombank" **Then** màn chi tiết ví mở ra đúng bố cục thiết kế `wallet-detail-screen.svg`: vùng teal tên ví + biểu tượng + số dư + loại ví, ba hành động nhanh, nhóm "GIAO DỊCH GẦN ĐÂY".
2. **Given** ví "Vietcombank" có số dư hiện tại 14.800.000 đ, loại tài khoản ngân hàng **When** xem màn chi tiết **Then** vùng teal hiển thị "Vietcombank", biểu tượng ví, "14.800.000 đ" cỡ lớn và dòng phụ "Tài khoản ngân hàng" — con số khớp 100% với số dư suy ra của ví trong dữ liệu.
3. **Given** ví có các giao dịch thu, chi và chuyển khoản nội bộ **When** xem nhóm "GIAO DỊCH GẦN ĐÂY" **Then** mỗi dòng hiển thị đúng màu ngữ cảnh: thu màu teal kèm dấu `+`, chi màu coral kèm dấu `−`, chuyển khoản màu trung tính; số tiền căn phải, đúng định dạng tiền tệ và không làm tròn sai.
4. **Given** một giao dịch chi có ghi chú "Siêu thị Coopmart", danh mục "Ăn uống", ngày hôm nay **When** xem màn chi tiết **Then** dòng đó hiển thị tiêu đề "Siêu thị Coopmart", dòng phụ "Ăn uống · Hôm nay" và giá trị chi màu coral.
5. **Given** ví là thẻ tín dụng đã dùng 6.500.000 trên hạn mức 20.000.000 **When** xem màn chi tiết **Then** vùng số dư hiển thị theo dạng sử dụng "Đã dùng 6.500.000 / 20.000.000 đ" và phần trăm sử dụng — không hiển thị như số dư dương thông thường.
6. **Given** ví chưa từng phát sinh giao dịch **When** xem màn chi tiết **Then** nhóm giao dịch hiển thị trạng thái rỗng rõ ràng (không lỗi, không vỡ bố cục), các phần còn lại của màn hiển thị bình thường.
7. **Given** một ví đã bị ẩn **When** chạm ví đó từ màn danh sách **Then** màn chi tiết vẫn mở ra và hiển thị đầy đủ thông tin ví như ví đang hoạt động (không chặn xem, không báo lỗi).
8. **Given** người dùng đang ở màn chi tiết ví **When** chạm lần lượt ba hành động nhanh và các dòng giao dịch **Then** không có màn hình mới mở ra và không phát sinh lỗi.
9. **Given** người dùng chạm nút quay lại **When** rời màn chi tiết ví **Then** trở về màn danh sách ví đúng trạng thái như lúc rời đi.
10. **Given** người dùng bật cỡ chữ lớn nhất hỗ trợ hoặc dùng màn hình có vùng an toàn **When** xem màn chi tiết ví **Then** mọi thành phần (vùng teal, ba hành động, danh sách giao dịch) hiển thị đầy đủ, không vỡ hay tràn khỏi màn hình.

### Trường hợp biên

- Ví có số dư âm (ví tiền mặt chi quá tay) → số dư hiển thị kèm dấu trừ rõ ràng, không gãy định dạng.
- Tên ví dài → cắt gọn hợp lý trên vùng teal, không đẩy vỡ bố cục.
- Giao dịch trong ví rất nhiều → danh sách "giao dịch gần đây" cuộn mượt, không bị đứng hay giật.
- Giao dịch chuyển khoản nội bộ (màu trung tính) đứng cạnh thu/chi → phân biệt rõ, không bị nhầm màu ngữ cảnh.
- Giao dịch điều chỉnh số dư (điều chỉnh ví) xuất hiện trong danh sách → hiển thị theo hướng tăng/giảm số dư tương ứng, không lẫn vào giao dịch thu/chi thường.
- Ví đã ẩn → vẫn xem được chi tiết; thông tin số dư hiển thị đầy đủ.
- Chạm nhanh liên tục vào các hành động / dòng giao dịch chưa có chức năng → không lỗi, không mở màn ngoài ý muốn.
- Khóa app đang có hiệu lực → màn chi tiết ví chỉ hiển thị sau khi mở khóa, không lộ nội dung qua màn hình khóa.

## Yêu cầu chức năng

- **FR-001**: Màn chi tiết ví PHẢI mở được khi chạm một ví bất kỳ trong màn danh sách ví (PBI 5); sau khi tính năng này hoàn tất, chạm hàng ví đó PHẢI điều hướng sang màn chi tiết của đúng ví được chạm.
- **FR-002**: Màn chi tiết ví PHẢI là sub-page theo thiết kế `docs/wallet/wallet-detail-screen.svg`: vùng teal đầu màn có nút quay lại và tên ví, không có thanh điều hướng đáy.
- **FR-003**: Vùng teal đầu màn PHẢI hiển thị đủ: tên ví, biểu tượng ví, số dư hiện tại cỡ chữ lớn màu trắng và dòng phụ tên loại ví (tiền mặt / tài khoản ngân hàng / thẻ tín dụng / ví điện tử / sổ tiết kiệm).
- **FR-004**: Số dư hiện tại hiển thị trên màn chi tiết PHẢI bằng số dư suy ra của ví tại thời điểm xem (số dư ban đầu + tổng thu − tổng chi ± chuyển khoản), đúng định dạng tiền tệ (phân tách nghìn bằng dấu chấm, đơn vị `đ`); số dư âm PHẢI hiển thị kèm dấu trừ rõ ràng.
- **FR-005**: Với ví loại thẻ tín dụng, vùng số dư PHẢI hiển thị theo dạng sử dụng: "Đã dùng X / hạn mức Y đ" và phần trăm sử dụng (tỷ lệ đã dùng trên hạn mức), dùng ngữ cảnh màu chi tiêu; không hiển thị dưới dạng số dư dương thông thường.
- **FR-006**: Màn PHẢI hiển thị ba hành động nhanh gồm nhãn và biểu tượng: **Chuyển tiền**, **Sửa ví**, **Ẩn ví**; vị trí và hình thức theo đúng thiết kế.
- **FR-007**: Chạm bất kỳ hành động nhanh nào (Chuyển tiền / Sửa ví / Ẩn ví) PHẢI không gây lỗi; đợt này chưa mở luồng chức năng (điểm vào cho PBI chuyển tiền / thêm-sửa ví / ẩn-xóa ví sau).
- **FR-008**: Nhóm "GIAO DỊCH GẦN ĐÂY" PHẢI liệt kê các giao dịch thuộc ví đang xem, sắp theo ngày giờ mới nhất lên đầu; giao dịch của ví khác KHÔNG được xuất hiện.
- **FR-009**: Mỗi dòng giao dịch PHẢI hiển thị: biểu tượng tròn, tiêu đề, dòng phụ "danh mục · ngày" và số tiền căn phải theo định dạng tiền tệ.
- **FR-010**: Màu ngữ cảnh mỗi dòng giao dịch PHẢI theo loại: thu màu teal kèm dấu `+` trước số tiền, chi màu coral kèm dấu `−`, chuyển khoản nội bộ màu trung tính (không nhầm với thu/chi); giao dịch điều chỉnh số dư hiển thị theo hướng tăng/giảm số dư của ví.
- **FR-011**: Chạm một dòng giao dịch PHẢI không gây lỗi; đợt này chưa mở màn chi tiết giao dịch (điểm vào cho PBI Giao dịch sau).
- **FR-012**: Khi ví chưa có giao dịch nào, nhóm "GIAO DỊCH GẦN ĐÂY" PHẢI hiển thị trạng thái rỗng rõ ràng, không báo lỗi và không vỡ bố cục.
- **FR-013**: Màn chi tiết ví PHẢI phản ánh đúng dữ liệu ví và giao dịch hiện tại mỗi lần mở (thay đổi số dư / giao dịch từ PBI sau làm màn hiển thị đúng khi mở lại).
- **FR-014**: Màn PHẢI cuộn được khi danh sách giao dịch dài; ba hành động nhanh và nội dung không bị che, không vỡ bố cục.
- **FR-015**: Màn chi tiết ví PHẢI hiển thị đúng, không vỡ hoặc bị che khuất trên các kích thước màn hình, vùng an toàn và thiết lập cỡ chữ khác nhau (điện thoại).
- **FR-016**: Màn chi tiết ví PHẢI chỉ hiển thị khi app đã được mở khóa; không được để người dùng nhìn thấy nội dung màn này qua màn hình khóa.

## Tiêu chí thành công

- **SC-001**: Từ màn danh sách ví, mở được màn chi tiết của một ví chỉ trong không quá 1 thao tác chạm.
- **SC-002**: Đối chiếu trực quan với thiết kế `wallet-detail-screen.svg`: vùng teal tên ví + số dư + loại ví, ba hành động nhanh và nhóm "GIAO DỊCH GẦN ĐÂY" hiển thị đủ, đúng vị trí và đúng màu ngữ cảnh khi dữ liệu đầu vào tương ứng.
- **SC-003**: Với bộ dữ liệu mẫu một ví có 3 khoản thu, 2 khoản chi và 1 lần chuyển khoản, số dư hiển thị trên màn khớp 100% với số dư suy ra tính thủ công; thứ tự các dòng giao dịch đúng ngày mới nhất lên đầu.
- **SC-004**: Số tiền và phần trăm hiển thị chính xác từng giá trị (không làm tròn sai, không sai dấu `+`/`−`, không sai đơn vị `đ`) khi đối chiếu với số liệu gốc của từng giao dịch và ví.
- **SC-005**: Chạm lần lượt ba hành động nhanh và toàn bộ các dòng giao dịch hiển thị trong một lượt dùng → 0 lỗi phát sinh, không có màn hình không mong muốn mở ra.
- **SC-006**: Mở màn chi tiết của ví chưa từng phát sinh giao dịch → nhóm giao dịch hiển thị trạng thái rỗng rõ ràng, không lỗi, phần còn lại của màn bình thường.
- **SC-007**: Bật cỡ chữ lớn nhất hỗ trợ và xem trên màn hình có vùng an toàn → mọi thành phần (vùng teal, ba hành động, danh sách giao dịch) hiển thị đầy đủ, không vỡ hay tràn.
- **SC-008**: Không tồn tại thao tác nào trên màn chi tiết ví đợt này làm thay đổi dữ liệu ví hay giao dịch (thêm/sửa/ẩn/xóa, chuyển tiền) — xác nhận màn ở chế độ chỉ xem (đánh giá định tính).

## Thực thể chính

- **Ví / tài khoản (wallet)**: đối tượng của màn chi tiết. Mỗi ví có: tên, loại ví, biểu tượng, màu, tiền tệ, số dư ban đầu và số dư hiện tại (số dư suy ra từ giao dịch, không sửa tay), cờ "ví mặc định", cờ "đã ẩn". Riêng thẻ tín dụng có thêm hạn mức, ngày sao kê, ngày đến hạn. Đợt này chỉ đọc dữ liệu ví để hiển thị.
- **Giao dịch (transaction)**: nguồn cho nhóm "GIAO DỊCH GẦN ĐÂY". Mỗi giao dịch thuộc đúng một ví và có: loại (thu / chi / chuyển khoản / điều chỉnh số dư), số tiền, danh mục, ghi chú, ngày giờ; giao dịch chuyển khoản là bút toán liên kết giữa hai ví. Đợt này chỉ đọc giao dịch thuộc ví đang xem để hiển thị danh sách.

## Giả định

- Đợt này dựng **màn xem chi tiết một ví** theo mockup `wallet-detail-screen.svg`, đóng vai trò màn con của danh sách ví (PBI 5). Các luồng thao tác phát sinh từ màn này là PBI riêng, đợt này chỉ để điểm vào chưa kích hoạt: chuyển tiền giữa ví (`wallet-transfer-screen.svg`), thêm/sửa ví (`wallet-add-edit-form.svg` — nút "Sửa ví" sẽ mở form này khi PBI thêm/sửa ví hoàn tất), ẩn/xóa ví, và chi tiết giao dịch (module Giao dịch).
- Khi PBI 6 hoàn tất, hàng ví ở màn danh sách ví (PBI 5 đang để chưa kích hoạt) sẽ điều hướng thật sang màn này — đây là điểm nối giữa hai PBI.
- Màn chi tiết hỗ trợ mọi loại ví. Với thẻ tín dụng, vùng số dư dùng dạng "Đã dùng / Hạn mức" + phần trăm như đã thiết lập ở PBI 5; với sổ tiết kiệm hiển thị số dư và dòng phụ "Sổ tiết kiệm" như ví thường (thông tin kỳ hạn, ngày đáo hạn chưa hiển thị trong đợt này). Mockup chỉ minh họa ví tài khoản ngân hàng nên cách thể hiện cụ thể các loại còn lại được đối chiếu với quy tắc loại ví trong tài liệu nghiệp vụ.
- Tiêu đề mỗi dòng giao dịch lấy từ ghi chú của giao dịch (mockup ví dụ "Siêu thị Coopmart"); giao dịch không có ghi chú thì hiển thị tên danh mục. Dòng phụ là "tên danh mục · ngày"; cách trình bày ngày thân thiện ("Hôm nay", "03/09"...) theo mockup, định dạng cụ thể chốt khi lập kế hoạch.
- Nhóm "GIAO DỊCH GẦN ĐÂY" liệt kê giao dịch của đúng ví đang xem, sắp ngày mới nhất lên đầu; khi số lượng nhiều màn cuộn được. Chưa có luồng "xem tất cả" hay lọc trong đợt này — thuộc module Giao dịch.
- Giao dịch chuyển khoản hiển thị trên ví nguồn lẫn ví đích với giá trị tương ứng; màu trung tính để không nhầm thu/chi.
- Các ví đợt này dùng chung tiền tệ mặc định của thiết bị (mặc định VND) nên số dư từng ví hiển thị trực tiếp; quy đổi đa tiền tệ theo tỷ giá nằm ngoài đợt này.
- Con số "14.800.000 đ", "Vietcombank", các giao dịch mẫu trong mockup mang tính minh họa; giá trị thật được đọc từ dữ liệu thiết bị.
- App dùng chủ yếu theo chiều dọc trên điện thoại; tablet/đa cửa sổ chưa phải mục tiêu. Ngôn ngữ giao diện đợt này là tiếng Việt.

## Ngoài phạm vi

- Tạo / sửa / ẩn / xóa ví (form thêm-sửa `wallet-add-edit-form.svg`) và các quy tắc kèm theo (số dư ban đầu bất biến, cảnh báo khi ẩn ví đã có giao dịch, chuyển ví mặc định khi xóa/ẩn ví đang mặc định) — nút "Sửa ví" chỉ là điểm vào.
- Chuyển tiền giữa các ví (`wallet-transfer-screen.svg`) và toàn bộ ràng buộc liên quan (tỷ giá, phí, hai bút toán liên kết) — nút "Chuyển tiền" chỉ là điểm vào.
- Màn chi tiết / sửa / xóa một giao dịch, danh sách giao dịch đầy đủ với lọc và "xem tất cả" (module Giao dịch) — chạm dòng giao dịch chỉ là điểm vào.
- Hiển thị thông tin định danh mở rộng của tài khoản (nhãn ngân hàng, số cuối tài khoản) và thông tin sổ tiết kiệm (kỳ hạn, ngày đáo hạn, lãi suất).
- Chế độ Privacy "ẩn số dư" (`••••••`) — chưa có module quyền riêng tư trong lộ trình hiện tại.
- Quy đổi tổng theo đa tiền tệ và nguồn tỷ giá offline.

## Quyết định đã chốt

- Ba hành động nhanh (Chuyển tiền / Sửa ví / Ẩn ví) và chạm dòng giao dịch đợt này **chỉ hiển thị, chưa kích hoạt luồng** — là điểm vào của PBI sau (chuyển tiền, thêm-sửa ví, chi tiết giao dịch).
- Vùng số dư đầu màn hiển thị **theo đặc thù loại ví**: thẻ tín dụng dùng dạng "Đã dùng X / Hạn mức Y đ" + phần trăm sử dụng; các loại còn lại hiển thị số dư hiện tại như ví thường.
