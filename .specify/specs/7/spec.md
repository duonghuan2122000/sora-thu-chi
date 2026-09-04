# Đặc tả tính năng: Thêm/sửa ví

**Mã PBI**: 7
**Ngày tạo**: 2026-09-04
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Người dùng cần tạo ví/tài khoản tiền mới (tiền mặt, ngân hàng, thẻ tín dụng, ví điện tử, sổ tiết kiệm) và chỉnh sửa thông tin ví đã có. Tính năng này dựng **một form dùng chung cho hai chế độ thêm và sửa ví** theo thiết kế `docs/wallet/wallet-add-edit-form.svg`: chọn loại ví dạng chip, nhập số dư ban đầu và tiền tệ, chọn biểu tượng & màu sắc, bật/tắt cờ ví mặc định, cùng các trường riêng hiển thị theo loại ví (hạn mức thẻ tín dụng, kỳ hạn sổ tiết kiệm, ngân hàng & số cuối...). Form mở từ nút "+ Thêm ví mới" của màn danh sách ví (PBI 5) và hành động nhanh "Sửa ví" của màn chi tiết ví (PBI 6). Đợt này gồm đúng nghiệp vụ tạo mới và sửa thông tin ví; việc ẩn/xóa ví nằm ở PBI riêng.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính — Thêm ví mới

1. Người dùng ở màn danh sách ví (PBI 5), chạm nút **"+ Thêm ví mới"** → màn form mở ra với tiêu đề "Thêm ví mới" (sub-page, app bar màu thương hiệu có nút quay lại, không có thanh điều hướng đáy).
2. Người dùng nhập **Tên ví** (bắt buộc), chọn **Loại ví** trong 5 lựa chọn dạng chip (Tiền mặt / Ngân hàng / Thẻ tín dụng / Ví điện tử / Sổ tiết kiệm). Khi đổi loại ví, các trường riêng phía dưới thay đổi theo đúng loại đang chọn.
3. Người dùng nhập **Số dư ban đầu** (bắt buộc khi tạo) và chọn **Tiền tệ** (mặc định theo cài đặt chung của app, có thể đổi).
4. Người dùng chọn **Biểu tượng & màu sắc** cho ví từ bộ lựa chọn có sẵn.
5. Với loại **Thẻ tín dụng**: nhập **Hạn mức tín dụng** (bắt buộc, lớn hơn 0), tùy chọn **ngày sao kê** và **ngày đến hạn thanh toán**. Với loại **Sổ tiết kiệm**: tùy chọn **kỳ hạn** và **ngày đáo hạn**. Với loại **Ngân hàng** hoặc **Ví điện tử**: nhập **ngân hàng/tổ chức** và **số cuối tài khoản** (chỉ hiển thị, không lưu số thật).
6. Người dùng bật/tắt **"Đặt làm ví mặc định"**. Nếu đây là ví đầu tiên của thiết bị → tự động được đặt làm mặc định.
7. Người dùng chạm **"Lưu ví"** → hệ thống tạo ví mới ở trạng thái đang hoạt động và quay về màn danh sách ví; ví mới xuất hiện trong danh sách với số dư đúng bằng số dư ban đầu, tổng số dư và số lượng ví được cập nhật.

### Luồng chính — Sửa ví

1. Người dùng ở màn chi tiết ví (PBI 6), chạm hành động nhanh **"Sửa ví"** → màn form mở ra với tiêu đề "Sửa ví", toàn bộ trường được nạp sẵn giá trị hiện tại của ví.
2. Người dùng chỉnh sửa các trường được phép: **Tên ví, biểu tượng & màu sắc, các trường riêng theo loại** (ví dụ hạn mức thẻ tín dụng) **và cờ ví mặc định**.
3. Nếu ví **chưa từng phát sinh giao dịch** → người dùng còn sửa được **số dư ban đầu, tiền tệ và loại ví**.
4. Nếu ví **đã có giao dịch** → các trường **số dư ban đầu, tiền tệ và loại ví** hiển thị ở trạng thái không chỉnh được, kèm ghi chú rằng muốn đổi số dư phải tạo giao dịch "Điều chỉnh số dư" (không sửa trực tiếp để tránh sai lệch lịch sử).
5. Người dùng chạm **"Lưu ví"** → thông tin ví được cập nhật, quay về màn chi tiết ví; dữ liệu hiển thị đổi theo ngay mà số dư và lịch sử giao dịch không bị ảnh hưởng.

### Kịch bản chấp nhận

1. **Given** người dùng đang ở màn danh sách ví **When** chạm "+ Thêm ví mới" **Then** mở form tiêu đề "Thêm ví mới", đủ các phần: tên ví, loại ví dạng chip, số dư ban đầu + tiền tệ, biểu tượng & màu sắc, cờ mặc định, nút "Lưu ví"; các trường riêng theo loại chưa có giá trị mặc định trước khi chọn loại.
2. **Given** người dùng tạo một ví tiền mặt tên "Quỹ chi tiêu hàng ngày", số dư ban đầu 3.200.000 đ, chọn biểu tượng và màu, không bật mặc định **When** lưu **Then** ví được tạo ở trạng thái hoạt động, quay về màn danh sách và thấy ví mới với số dư đúng 3.200.000 đ; tổng số dư tăng tương ứng.
3. **Given** thiết bị chưa có ví nào **When** người dùng tạo ví đầu tiên **Then** ví đó tự động trở thành ví mặc định; sau khi lưu chỉ đúng một ví mang nhãn "Mặc định".
4. **Given** thiết bị đã có ví mặc định "A" **When** người dùng tạo ví "B" và bật "Đặt làm ví mặc định" **Then** ví "A" không còn là mặc định, ví "B" trở thành mặc định, và không bao giờ có quá một ví mặc định.
5. **Given** người dùng đang ở màn chi tiết ví "Vietcombank" **When** chạm "Sửa ví" **Then** mở form tiêu đề "Sửa ví" với tên, loại, biểu tượng, màu và các trường được nạp đúng giá trị hiện tại của ví.
6. **Given** ví "Vietcombank" đã có giao dịch **When** mở form sửa ví đó **Then** trường số dư ban đầu, tiền tệ và loại ví không chỉnh được và có giải thích; số dư hiện tại không xuất hiện dưới dạng trường nhập.
7. **Given** ví "Tiền mặt" chưa có giao dịch nào **When** mở form sửa và đổi số dư ban đầu từ 1.000.000 thành 2.000.000 đ **Then** lưu thành công và ví hiển thị số dư mới đúng 2.000.000 đ.
8. **Given** người dùng tạo thẻ tín dụng **When** nhập hạn mức 0 hoặc để trống và chạm "Lưu ví" **Then** việc lưu bị chặn, thông báo lỗi rõ tại trường hạn mức, không tạo ví; nhập hạn mức hợp lệ (ví dụ 20.000.000 đ) **Then** lưu được.
9. **Given** người dùng đang chỉnh sửa form **When** chạm nút quay lại chưa lưu **Then** không tạo/sửa gì, trở về màn trước (danh sách hoặc chi tiết ví) đúng trạng thái như lúc rời đi.
10. **Given** người dùng bật cỡ chữ lớn nhất hỗ trợ hoặc dùng màn hình có vùng an toàn **When** mở form thêm/sửa ví **Then** mọi trường và nút "Lưu ví" hiển thị đầy đủ, form cuộn được, không vỡ hay tràn khỏi màn hình.

### Trường hợp biên

- Bỏ trống tên ví hoặc chỉ nhập khoảng trắng → lưu bị chặn, báo lỗi tại trường tên.
- Số dư ban đầu để trống khi tạo (chưa nhập) → lưu bị chặn; số dư ban đầu bằng 0 là hợp lệ (ví mới chưa có tiền).
- Ví là ví mặc định duy nhất đang hoạt động, người dùng cố tắt "Đặt làm ví mặc định" → không cho tắt (giữ ví mặc định), có giải thích.
- Tắt mặc định cho ví đang là mặc định khi còn ví hoạt động khác → hệ thống tự chọn một ví khác làm mặc định thay thế.
- Đổi loại ví trong lúc nhập khi chưa lưu → các trường riêng đã nhập của loại cũ bị bỏ, form hiển thị trường riêng của loại mới (áp dụng khi ví chưa có giao dịch).
- Tên ví rất dài → trường nhập cuộn/co chữ hợp lý, không làm vỡ bố cục.
- Số lượng ví nhiều nhưng form thêm/sửa chỉ thao tác một ví → không ảnh hưởng thứ tự hiển thị và số dư các ví khác.
- Người dùng tạo ví nhưng tiền tệ chọn khác tiền tệ mặc định → lưu được, ví mang đúng tiền tệ đã chọn, không tự quy đổi.

## Yêu cầu chức năng

- **FR-001**: Hệ thống PHẢI mở form "Thêm ví mới" khi người dùng chạm "+ Thêm ví mới" ở màn danh sách ví, và mở form "Sửa ví" khi chạm hành động nhanh "Sửa ví" ở màn chi tiết ví; cả hai là sub-page có nút quay lại, không có thanh điều hướng đáy.
- **FR-002**: Form PHẢI có các trường: Tên ví, Loại ví (5 lựa chọn chip), Số dư ban đầu, Tiền tệ, Biểu tượng & màu sắc, cờ "Đặt làm ví mặc định", và nút "Lưu ví".
- **FR-003**: Khi chọn loại ví, hệ thống PHẢI hiển thị các trường riêng tương ứng: Thẻ tín dụng → hạn mức tín dụng, ngày sao kê, ngày đến hạn; Sổ tiết kiệm → kỳ hạn, ngày đáo hạn; Ngân hàng và Ví điện tử → ngân hàng/tổ chức, số cuối tài khoản; Tiền mặt → không có trường riêng.
- **FR-004**: Khi tạo ví mới, hệ thống PHẢI yêu cầu nhập bắt buộc: tên ví, số dư ban đầu, tiền tệ và — nếu chọn Thẻ tín dụng — hạn mức tín dụng lớn hơn 0. Các trường riêng khác là tùy chọn.
- **FR-005**: Hệ thống PHẢI chặn lưu và hiển thị thông báo lỗi rõ ràng tại đúng trường khi dữ liệu bắt buộc thiếu hoặc không hợp lệ; không tạo/cập nhật ví trong trường hợp đó.
- **FR-006**: Hệ thống PHẢI mặc định tiền tệ của ví mới theo tiền tệ cài đặt chung của app, và cho phép người dùng đổi sang tiền tệ khác trong danh sách có sẵn.
- **FR-007**: Hệ thống PHẢI tự đặt ví đầu tiên được tạo làm ví mặc định, và PHẢI bảo đảm chỉ có đúng một ví mặc định tại một thời điểm: bật cờ mặc định cho một ví PHẢI gỡ cờ đó khỏi ví đang là mặc định.
- **FR-008**: Hệ thống PHẢI không cho tắt cờ mặc định khi ví đang là mặc định duy nhất trong số các ví hoạt động; khi còn ví hoạt động khác, việc tắt cờ PHẢI kích hoạt chọn một ví khác làm mặc định thay thế.
- **FR-009**: Ở chế độ sửa, hệ thống PHẢI nạp sẵn giá trị hiện tại của ví vào các trường.
- **FR-010**: Ở chế độ sửa, khi ví đã có giao dịch, hệ thống PHẢI khóa không cho chỉnh: số dư ban đầu, tiền tệ và loại ví, kèm ghi chú rằng muốn đổi số dư phải tạo giao dịch điều chỉnh; người dùng chỉ sửa được tên, biểu tượng & màu sắc, trường riêng của loại ví và cờ mặc định.
- **FR-011**: Ở chế độ sửa, khi ví chưa có giao dịch, hệ thống PHẢI cho phép sửa toàn bộ trường, gồm số dư ban đầu, tiền tệ và loại ví.
- **FR-012**: Hệ thống PHẢI tạo ví mới luôn ở trạng thái đang hoạt động (không ẩn) và PHẢI giữ nguyên trạng thái ẩn của ví khi sửa thông tin.
- **FR-013**: Sau khi lưu thành công (thêm hoặc sửa), hệ thống PHẢI quay về màn gọi (danh sách hoặc chi tiết ví) và dữ liệu hiển thị ở màn đó được cập nhật ngay theo giá trị mới; số dư ví suy ra từ giao dịch không bị thay đổi khi chỉ sửa tên/biểu tượng/màu/hạn mức.
- **FR-014**: Nếu việc lưu thất bại, hệ thống PHẢI báo lỗi và giữ nguyên dữ liệu người dùng đã nhập trên form để không phải gõ lại.

## Tiêu chí thành công

- **SC-001**: Người dùng mới (chưa có ví) tạo được ví đầu tiên trong chưa đầy 2 phút và ví đó tự động là ví mặc định, đúng một ví mang nhãn "Mặc định" trên toàn app.
- **SC-002**: Mọi loại ví đều tạo được bằng đúng form này; với thẻ tín dụng người dùng bắt buộc nhập hạn mức lớn hơn 0 — không tạo được thẻ tín dụng thiếu hạn mức.
- **SC-003**: Sau khi lưu, số dư ban đầu người dùng nhập khớp 100% với số dư hiển thị của ví ở màn danh sách/chi tiết, không làm tròn hay lệch số.
- **SC-004**: Sửa tên/biểu tượng/màu/hạn mức của ví đã có giao dịch không làm thay đổi số dư hiện tại và lịch sử giao dịch của ví.
- **SC-005**: Người dùng không thể tạo tình huống có hai ví mặc định, kể cả khi thao tác liên tiếp thêm/sửa ví; luôn có đúng một ví mặc định khi có ít nhất một ví đang hoạt động.
- **SC-006**: Mọi thao tác sai (thiếu trường bắt buộc, hạn mức không hợp lệ) đều được chặn và báo lỗi rõ ràng tại đúng vị trí; người dùng tự sửa được mà không cần trợ giúp.
- **SC-007**: Với cỡ chữ lớn nhất hỗ trợ hoặc màn hình có vùng an toàn, form hiển thị đầy đủ, cuộn mượt, nút "Lưu ví" luôn với tới được, không vỡ bố cục.

## Thực thể chính

- **Ví (Wallet)**: thùng chứa tiền gắn đúng một loại và một tiền tệ. Tính năng này quản lý các thuộc tính: tên ví, loại ví (tiền mặt/ngân hàng/thẻ tín dụng/ví điện tử/sổ tiết kiệm), biểu tượng, màu sắc, số dư ban đầu, tiền tệ, cờ ví mặc định (chỉ 1 ví), cờ ẩn (luôn "không ẩn" khi tạo), và các trường riêng theo loại (hạn mức tín dụng, ngày sao kê, ngày đến hạn cho thẻ tín dụng; kỳ hạn, ngày đáo hạn cho sổ tiết kiệm; ngân hàng/tổ chức và số cuối cho ngân hàng/ví điện tử).
- Số dư hiện tại của ví là đại lượng suy ra (số dư ban đầu + tổng thu − tổng chi ± chuyển khoản) — không phải trường nhập trong form này; ví đã có giao dịch không cho đổi số dư ban đầu trực tiếp.

## Giả định

- Một form dùng chung cho hai chế độ; khác biệt duy nhất là tiêu đề, dữ liệu nạp sẵn và tập trường được khóa tùy ví đã có giao dịch hay chưa.
- "Đã có giao dịch" nghĩa là có ít nhất một giao dịch (thu, chi, chuyển khoản hoặc điều chỉnh) gắn với ví.
- Bộ thiết kế `wallet-add-edit-form.svg` vẽ đúng chế độ thêm ví mới ở loại "Tiền mặt"; các trường riêng theo loại khác (hạn mức thẻ tín dụng, kỳ hạn sổ tiết kiệm, ngân hàng & số cuối) được mở rộng theo đặc tả nghiệp vụ `docs/wallet/nghiep-vu-vi-tai-khoan.md`, hiển thị động tùy loại đang chọn.
- "Biểu tượng & màu sắc" gồm danh sách biểu tượng ví có sẵn và bảng màu để chọn, có giá trị mặc định hợp lý; mockup chưa vẽ chi tiết bảng màu nên bố cục phần này lấy theo thiết kế khi triển khai.
- Danh sách tiền tệ là danh sách cố định có sẵn trong app (offline, không gọi dịch vụ bên ngoài); tiền tệ cài đặt chung được dùng làm giá trị mặc định.
- Với loại ví điện tử, trường "ngân hàng/tổ chức" hiểu là tên tổ chức (ví dụ Momo, ZaloPay); số cuối tài khoản chỉ để hiển thị đối chiếu, không lưu số tài khoản thật.
- Khi ví đang là mặc định bị tắt cờ (còn ví hoạt động khác) hoặc khi không còn ví nào mang cờ, hệ thống tự chọn ví hoạt động khác làm mặc định, ưu tiên ví có số dư dương và được dùng gần nhất; nếu không xác định được thì chọn ví đứng đầu danh sách hiển thị.
- Sổ tiết kiệm và thẻ tín dụng vẫn cho phép đặt làm ví mặc định như các loại khác (không phân biệt trong phạm vi form này).
- Tên ví không bắt buộc duy nhất giữa các ví (chưa có ràng buộc loại trừ).

## Ngoài phạm vi

- Ẩn ví, hiện lại ví và xóa ví (kể cả chuyển ví mặc định khi xóa/ẩn) — là nghiệp vụ đi cùng hành động nhanh "Ẩn ví" ở màn chi tiết ví (PBI riêng).
- Tạo giao dịch "Điều chỉnh số dư" để thay đổi số dư ví đã có giao dịch — thuộc module Giao dịch; form sửa chỉ nhắc hướng dẫn, không thực hiện.
- Chuyển tiền giữa các ví và nhập tỷ giá quy đổi.
- Kéo-thả sắp xếp thứ tự hiển thị danh sách ví.
- Chế độ riêng tư (ẩn số dư).
