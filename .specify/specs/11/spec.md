# Đặc tả tính năng: Màn hình thêm giao dịch & chọn danh mục

**Mã PBI**: 11
**Ngày tạo**: 2026-09-05
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Người dùng cần ghi nhận một khoản thu hoặc chi mới (mua sắm, ăn uống, nhận lương...) vào app một cách nhanh chóng, đúng nghiệp vụ giao dịch của app: chọn loại Thu/Chi, nhập số tiền, chọn danh mục, ví và ngày giờ. Tính năng này dựng **màn hình "Thêm giao dịch"** theo đúng thiết kế `docs/transaction/02-them-giao-dich.svg`: màn hình toàn màn hình tập trung một tác vụ (app bar thương hiệu, không có thanh điều hướng đáy) với segmented tab Chi/Thu, bàn phím số tùy chỉnh để nhập số tiền, danh sách trường Danh mục – Ví – Ngày giờ – Ghi chú và nút "Lưu giao dịch"; kèm luồng con **"Chọn danh mục"** theo `docs/transaction/03-chon-danh-muc.svg` mở ra khi người dùng chạm trường Danh mục. Màn mở từ FAB "thêm giao dịch" ở danh sách giao dịch (điểm vào đã dựng ở PBI 9). Đợt này tập trung **ghi nhận giao dịch thu/chi mới**; sửa/xóa/nhân bản giao dịch cũ và nhập các trường tùy chọn mở rộng (tag, ảnh hóa đơn, vị trí) nằm ngoài phạm vi.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính

1. Người dùng ở danh sách giao dịch (PBI 9), chạm **FAB "+"** → màn "Thêm giao dịch" mở ra (màn toàn màn hình, app bar teal tiêu đề "Thêm giao dịch", icon đóng X bên trái, icon check bên phải; không có bottom nav). Segmented tab mở mặc định ở **"Chi"**.
2. Người dùng chạm phím số trên **bàn phím số tùy chỉnh** → số tiền hiển thị lớn, căn giữa, tự động phân tách nghìn bằng dấu chấm kèm đơn vị `đ` (ví dụ gõ `1250000` → `1.250.000 đ`). Có phím xóa lùi để sửa.
3. Người dùng chạm trường **Danh mục** → mở màn con "Chọn danh mục" (`03`): lưới 4 cột các danh mục thuộc đúng loại đang chọn (đang ở Chi thì hiện danh mục chi, đang ở Thu thì hiện danh mục thu), mỗi ô gồm icon tròn nền màu riêng và tên. Chạm một danh mục cha có con → hiện các danh mục con để chọn; chạm một danh mục (con hoặc không có con) → chọn danh mục đó và quay về màn thêm, trường Danh mục hiển thị tên đã chọn.
4. Người dùng chạm trường **Ví** → chọn một ví đang hoạt động của thiết bị (mặc định là ví mặc định của app); trường Ví hiển thị tên ví đã chọn.
5. Người dùng chạm trường **Ngày giờ** → chọn ngày và giờ của giao dịch (mặc định là thời điểm hiện tại, có thể đổi về quá khứ hoặc tương lai). **Ghi chú** là trường tùy chọn, người dùng nhập khi cần.
6. Người dùng chạm **"Lưu giao dịch"** (hoặc icon check ở app bar) → hệ thống kiểm tra dữ liệu; nếu đủ số tiền (> 0), danh mục, ví và ngày giờ → ghi nhận giao dịch đúng loại (thu làm tăng, chi làm giảm số dư suy ra của ví tại ngày giờ đó), đóng màn và quay về danh sách giao dịch — giao dịch mới xuất hiện trong danh sách, card "Thu/Chi tháng này" cập nhật theo.
7. Khi cần ghi khoản chuyển tiền giữa hai ví, người dùng chạm tab **"Chuyển khoản"** → hệ thống mở luồng chuyển tiền giữa ví (đã có sẵn từ PBI 8), không nhập chuyển khoản ngay trong màn này.

### Kịch bản chấp nhận

1. **Given** người dùng đã mở khóa app và đang ở danh sách giao dịch **When** chạm FAB "+" **Then** mở màn "Thêm giao dịch" đúng bố cục `02-them-giao-dich.svg`: app bar teal tiêu đề + icon X và icon check, segmented tab mở ở "Chi", vùng số tiền hiển thị `0 đ`, bàn phím số tùy chỉnh, danh sách trường Danh mục/Ví/Ngày giờ/Ghi chú và nút "Lưu giao dịch"; màn không có thanh điều hướng đáy.
2. **Given** người dùng ở màn thêm giao dịch, tab "Chi" đang chọn **When** chạm các phím `1`,`2`,`5`,`0` rồi ba số `0` **Then** vùng số tiền hiển thị `1.250.000 đ` (phân tách nghìn tự động bằng dấu chấm, kèm đơn vị `đ`).
3. **Given** người dùng ở màn thêm giao dịch đang chọn loại "Chi" **When** chạm trường Danh mục **Then** mở màn "Chọn danh mục" hiển thị các danh mục **chi** (ăn uống, di chuyển, nhà ở, hóa đơn, mua sắm, giải trí, sức khỏe, giáo dục...) dạng lưới; danh mục thu như Lương/Thưởng không xuất hiện; chạm danh mục "Ăn uống" **Then** hiện các danh mục con (Cà phê, Ăn ngoài, Đi chợ); chạm "Ăn ngoài" **Then** chọn "Ăn ngoài" và quay về màn thêm, trường Danh mục hiển thị "Ăn ngoài".
4. **Given** người dùng ở màn thêm giao dịch **When** chuyển segmented sang "Thu" rồi chạm trường Danh mục **Then** màn chọn danh mục hiển thị các danh mục **thu** (Lương, Thưởng, Đầu tư, Khác...), không hiện danh mục chi.
5. **Given** người dùng đã chọn loại, số tiền, danh mục, ví và ngày giờ hợp lệ **When** chạm "Lưu giao dịch" **Then** giao dịch được ghi nhận đúng loại/số tiền/danh mục/ví/ngày giờ; màn đóng về danh sách giao dịch; giao dịch mới xuất hiện trong nhóm ngày tương ứng và card "Thu/Chi tháng này" cập nhật đúng.
6. **Given** người dùng ở màn thêm giao dịch **When** chạm "Lưu giao dịch" mà số tiền trống/bằng 0, hoặc chưa chọn danh mục, hoặc chưa chọn ví, hoặc ngày giờ thiếu **Then** lưu bị chặn, hệ thống báo rõ trường nào đang thiếu/không hợp lệ để người dùng bổ sung; không tạo giao dịch.
7. **Given** người dùng đang ở màn thêm giao dịch **When** chạm tab "Chuyển khoản" **Then** mở luồng chuyển tiền giữa ví (PBI 8) để ghi khoản chuyển; màn thêm thu/chi này không chứa form chuyển khoản.
8. **Given** người dùng đã nhập/sửa dữ liệu trong màn thêm nhưng chưa lưu **When** chạm icon X hoặc dùng cử chỉ back **Then** hệ thống hỏi xác nhận trước khi rời màn; nếu xác nhận rời → không tạo giao dịch nào; nếu hủy → tiếp tục ở lại màn, dữ liệu đã nhập không mất.
9. **Given** người dùng bật cỡ chữ lớn nhất hỗ trợ hoặc dùng màn hình có vùng an toàn **When** mở màn thêm giao dịch và màn chọn danh mục **Then** app bar, segmented tab, vùng số tiền, bàn phím số, danh sách trường, nút "Lưu giao dịch" và lưới danh mục hiển thị đầy đủ, cuộn được, không vỡ hay tràn.

### Trường hợp biên

- Thiết bị chưa có ví nào đang hoạt động → không thể ghi giao dịch: màn thêm thông báo rõ cần tạo ví trước, không để người dùng "kẹt" ở trường Ví trống.
- Chỉ có một ví hoạt động → trường Ví nạp sẵn ví đó, người dùng không cần mở danh sách.
- Ví đã bị ẩn → không xuất hiện trong danh sách chọn ví khi ghi giao dịch mới.
- Chưa có danh mục nào thuộc loại đang chọn → màn chọn danh mục hiển thị trạng thái rỗng kèm gợi ý, không lỗi.
- Số tiền nhập rất lớn (nhiều chữ số) → hiển thị đầy đủ đúng định dạng phân tách nghìn, không tràn/tràn số.
- Ngày giờ chọn ở tương lai (đặt lịch) → giao dịch vẫn lưu được, xuất hiện trong danh sách theo đúng ngày giờ đó; số dư ví và thống kê tính theo cùng quy tắc giao dịch như mọi giao dịch.
- Ghi chú dài/nhiều dòng → lưu và hiển thị trọn văn bản.
- Chạm nút "Lưu giao dịch" hai lần liên tiếp nhanh → chỉ tạo đúng một giao dịch, không tạo trùng.
- Ứng dụng bị ngắt/vòng đời bị hủy giữa chừng sau khi xác nhận lưu → giao dịch hoặc được lưu đầy đủ, hoặc không lưu gì; không xảy ra trạng thái lưu nửa chừng.
- Khóa app đang có hiệu lực → màn thêm giao dịch chỉ hiển thị sau khi mở khóa, không lộ số tiền qua màn hình khóa.

## Yêu cầu chức năng

- **FR-001**: Hệ thống PHẢI mở màn "Thêm giao dịch" khi người dùng chạm FAB "+" ở danh sách giao dịch (điểm vào đã dựng ở PBI 9); màn là màn toàn màn hình tập trung một tác vụ theo đúng bố cục `docs/transaction/02-them-giao-dich.svg`: app bar thương hiệu tiêu đề "Thêm giao dịch" với icon đóng (X) bên trái và icon check bên phải, **không** có thanh điều hướng đáy.
- **FR-002**: Màn PHẢI có segmented tab **Chi | Thu | Chuyển khoản** theo đúng thiết kế: tab mở mặc định ở **"Chi"**; tab đang chọn tô màu thương hiệu, các tab còn lại nền trắng có viền; trạng thái đang chọn chỉ dùng một màu thương hiệu.
- **FR-003**: Khi người dùng chạm tab **"Chuyển khoản"**, hệ thống PHẢI chuyển sang luồng ghi khoản chuyển tiền giữa hai ví (đã có từ PBI 8); màn thêm giao dịch này KHÔNG nhập trực tiếp khoản chuyển khoản.
- **FR-004**: Vùng nhập số tiền PHẢI hiển thị số tiền lớn, căn giữa, theo chuẩn tiền tệ của app: phân tách nghìn bằng dấu chấm và đơn vị `đ` (ví dụ `1.250.000 đ`); số tiền được gõ qua bàn phím số tùy chỉnh (phím `0–9`, phím xóa lùi) đúng phong cách bàn phím của app.
- **FR-005**: Trường **Danh mục** PHẢI là bắt buộc; khi chạm, hệ thống PHẢI mở màn con "Chọn danh mục" theo `docs/transaction/03-chon-danh-muc.svg` (app bar thương hiệu có nút quay lại, tiêu đề "Chọn danh mục").
- **FR-006**: Màn chọn danh mục PHẢI hiển thị các danh mục **thuộc đúng loại giao dịch đang chọn** (đang ghi Chi thì hiện danh mục chi, đang ghi Thu thì hiện danh mục thu) dạng lưới: mỗi ô gồm icon tròn nền màu riêng theo danh mục và tên danh mục bên dưới; chọn một danh mục PHẢI đưa người dùng về màn thêm và điền tên danh mục đó vào trường Danh mục.
- **FR-007**: Danh mục có danh mục con PHẢI cho phép người dùng xem và chọn danh mục con trước khi xác nhận (ví dụ cha "Ăn uống" có con "Cà phê", "Ăn ngoài", "Đi chợ"); giao dịch lưu PHẢI gắn đúng danh mục con người dùng chọn.
- **FR-008**: Trường **Ví** PHẢI là bắt buộc; hệ thống PHẢI để sẵn ví mặc định của app và cho phép người dùng đổi sang một ví khác trong danh sách các ví **đang hoạt động** (không bao gồm ví đã ẩn) của thiết bị.
- **FR-009**: Trường **Ngày giờ** PHẢI là bắt buộc; hệ thống PHẢI mặc định là thời điểm hiện tại và cho phép người dùng chọn lại ngày/giờ khác (quá khứ hoặc tương lai).
- **FR-010**: Trường **Ghi chú** PHẢI là tùy chọn; người dùng có thể để trống, ghi chú dài nhiều dòng PHẢI được lưu trọn vẹn.
- **FR-011**: Hệ thống PHẢI chặn lưu và báo rõ tại đúng trường khi: số tiền trống hoặc không lớn hơn 0, thiếu danh mục, thiếu ví, hoặc ngày giờ thiếu/không hợp lệ; không tạo giao dịch khi chưa hợp lệ.
- **FR-012**: Khi dữ liệu hợp lệ và người dùng chạm nút chính **"Lưu giao dịch"** (hoặc icon check ở app bar), hệ thống PHẢI ghi nhận đúng một giao dịch thu/chi với loại, số tiền, danh mục, ví, ngày giờ và ghi chú đã nhập: giao dịch **thu** làm tăng số dư suy ra của ví, giao dịch **chi** làm giảm — theo đúng ngày giờ giao dịch; không tạo giao dịch trùng khi chạm nút lặp lại.
- **FR-013**: Sau khi lưu thành công, hệ thống PHẢI đóng màn thêm và đưa người dùng về màn xuất phát (danh sách giao dịch); danh sách và card "Thu/Chi tháng này" PHẢI phản ánh giao dịch mới ngay, không cần làm mới thủ công.
- **FR-014**: Khi người dùng đã nhập hoặc thay đổi dữ liệu trong màn thêm nhưng chưa lưu rồi chạm icon X hoặc cử chỉ back, hệ thống PHẢI hỏi xác nhận trước khi rời màn để tránh mất dữ liệu nhập; nếu người dùng xác nhận rời, KHÔNG được tạo giao dịch nào.
- **FR-015**: Màn thêm giao dịch và màn chọn danh mục PHẢI hiển thị đầy đủ, cuộn được và không vỡ bố cục trên các kích thước màn hình, vùng an toàn và thiết lập cỡ chữ khác nhau (điện thoại).
- **FR-016**: Hai màn trên PHẢI chỉ hiển thị khi app đã được mở khóa; không được để người dùng nhìn thấy số tiền qua màn hình khóa.

## Tiêu chí thành công

- **SC-001**: Từ danh sách giao dịch, mở màn thêm giao dịch và hoàn tất ghi một khoản thu/chi trong chưa đầy 30 giây với người dùng đã quen.
- **SC-002**: Với bộ số liệu mẫu khớp mockup (nhập `1250000` → hiển thị `1.250.000 đ`), số tiền hiển thị khớp 100% với đối chiếu thủ công về giá trị, phân tách nghìn và đơn vị `đ`; sau khi lưu, dữ liệu giao dịch đối chiếu khớp 100% với những gì người dùng đã nhập trên màn.
- **SC-003**: Một giao dịch chi ghi xong làm giảm đúng số dư của ví được chọn, một giao dịch thu làm tăng đúng — kiểm tra đối chiếu trước/sau khi ghi; khoản giao dịch thu/chi đúng danh mục và xuất hiện đúng trong tổng "Thu/Chi tháng này".
- **SC-004**: Người dùng chọn danh mục chi và danh mục thu đúng theo loại giao dịch đang ghi: khi ở "Chi" không thể chọn nhầm danh mục thu và ngược lại; danh mục cha-con chọn đúng danh mục con mong muốn.
- **SC-005**: Không thể lưu giao dịch khi thiếu một trong các trường bắt buộc (số tiền, danh mục, ví, ngày giờ) hoặc số tiền không hợp lệ; mọi lỗi đều báo rõ tại đúng trường, người dùng tự sửa được không cần trợ giúp.
- **SC-006**: Sau khi lưu giao dịch, danh sách giao dịch hiển thị ngay giao dịch mới ở đúng nhóm ngày và thống kê cập nhật đúng mà không cần thao tác làm mới thủ công.
- **SC-007**: Đối chiếu trực quan với `02-them-giao-dich.svg` và `03-chon-danh-muc.svg`: app bar, segmented tab, vùng số tiền, bàn phím số, từng dòng trường, nút "Lưu giao dịch" và lưới danh mục (icon + tên, danh mục cha-con) hiển thị đúng vị trí, đúng màu thương hiệu và đúng định dạng tiền tệ khi dữ liệu đầu vào tương ứng.
- **SC-008**: Với cỡ chữ lớn nhất và vùng an toàn khác nhau, cả hai màn vẫn hiển thị đầy đủ, cuộn được, không vỡ bố cục hay cắt mất nút "Lưu giao dịch" hoặc ô danh mục cuối.
- **SC-009**: Không tồn tại thao tác nào trên màn tạo giao dịch trùng khi chạm nút liên tiếp, hoặc làm mất dữ liệu người dùng đã nhập mà không có xác nhận.

## Thực thể chính

- **Giao dịch (transaction)**: dữ liệu được tạo mới trong luồng này. Gồm loại (thu / chi), số tiền (> 0), ngày giờ, ví chứa, danh mục và ghi chú tùy chọn. Giao dịch thu làm tăng, giao dịch chi làm giảm số dư suy ra của ví; không liên quan cặp ví nguồn–đích (chuyển khoản không ghi ở màn này).
- **Danh mục (category)**: đối tượng người dùng chọn ở màn chọn danh mục. Gồm tên, icon, màu và có thể có danh mục con; được phân nhóm theo loại giao dịch (danh mục chi / danh mục thu). Cung cấp nhận diện (tên, icon, màu) cho dòng giao dịch và màn chi tiết.
- **Ví (wallet)**: ví chứa giao dịch mới — phải là ví đang hoạt động của thiết bị (không gồm ví ẩn). Số dư ví là đại lượng suy ra, thay đổi khi giao dịch thu/chi được ghi.

## Giả định

- Điểm vào của màn này là FAB "+" ở danh sách giao dịch (PBI 9) — luồng ghi giao dịch mới. Các nút "Sửa"/"Nhân bản" trên màn chi tiết giao dịch (PBI 10) trỏ về màn thêm/sửa giao dịch nhưng **chưa kích hoạt ở đợt này**: PBI 11 chỉ ghi giao dịch **mới** (chốt cùng người dùng); sửa/xóa/nhân bản là PBI sau dùng lại cùng màn (đổi tiêu đề "Sửa giao dịch", điền sẵn dữ liệu).
- Tab "Chuyển khoản" của segmented là **điểm vào mở luồng chuyển tiền giữa ví đã có (PBI 8)** — màn thêm thu/chi không nhập chuyển khoản, không duplicate form chuyển tiền (chốt cùng người dùng). Phạm vi PBI 8 đã ghi nhận nhánh "Chuyển khoản" trong màn thêm giao dịch là điểm vào khác của cùng nghiệp vụ chuyển tiền.
- Trường nhập đợt này bám **đúng mockup `02`**: chỉ Danh mục, Ví, Ngày giờ và Ghi chú (chốt cùng người dùng). Các trường tùy chọn mở rộng Tag, Ảnh hóa đơn, Vị trí (đã có trong màn chi tiết PBI 10) **chưa nhập ở màn này** — để PBI sau mở rộng; giao dịch mới tạo có các trường này rỗng.
- Bàn phím số tùy chỉnh có phím số, phím xóa lùi (mockup có phím `,` theo phong cách numpad); giai đoạn hiện tại tiền tệ là VND, giao dịch nhập theo số nguyên đồng — hỗ trợ phần thập phân (nếu cần) là quyết định sau. Số tiền luôn lớn hơn 0.
- Ví mặc định được nạp sẵn cho trường Ví (chỉ một ví mặc định tồn tại theo nghiệp vụ ví); danh sách chọn ví gồm các ví đang hoạt động (không gồm ví ẩn), kể cả thẻ tín dụng — vì thu/chi bằng thẻ là giao dịch thường, khác ràng buộc loại trừ thẻ tín dụng của riêng luồng chuyển tiền (PBI 8).
- Danh sách danh mục hiển thị trên màn chọn danh mục là bộ danh mục mặc định của app (cha-con, được phân nhóm thu/chi). Việc **tự tạo/quản lý danh mục** ("Thêm mới" trên lưới `03`) là module Danh mục riêng, chưa nằm trong đợt này.
- Sau khi lưu, màn đóng về màn xuất phát (danh sách giao dịch); không triển khai "Lưu & tiếp tục thêm" (doc §3.1) ở đợt này vì không có trong mockup `02`.
- Ghi chú và danh mục là chuỗi ký tự; số tiền, loại và ngày giờ là dữ liệu có cấu trúc. Mọi con số trong mockup chỉ mang tính minh họa; dữ liệu lưu lấy từ nhập liệu của người dùng.
- Ứng dụng dùng chủ yếu theo chiều dọc trên điện thoại, giao diện tiếng Việt; tablet/đa ngôn ngữ chưa phải mục tiêu đợt này.

## Ngoài phạm vi

- Ghi khoản chuyển khoản nội bộ ngay trên màn thêm giao dịch — tab "Chuyển khoản" chỉ mở luồng chuyển tiền giữa ví (PBI 8); chuyển tiền có màn riêng đã làm.
- Sửa, xóa (dialog xác nhận + Undo), nhân bản một giao dịch đã có và việc kích hoạt nút "Sửa"/"Nhân bản" từ màn chi tiết (PBI 10).
- Nhập các trường tùy chọn mở rộng: Tag, Ảnh hóa đơn (chụp/chọn ảnh), Vị trí GPS — giao dịch mới chỉ ghi 4 trường chính theo mockup; màn chi tiết (PBI 10) vẫn hiển thị các trường này khi dữ liệu có sẵn.
- "Lưu & tiếp tục thêm" và "Nhập nhanh (Quick Add)" (doc §3.1) — không có trong mockup `02`.
- Tự tạo/quản lý danh sách danh mục ngay trong màn chọn danh mục (ô "Thêm mới") — thuộc module Danh mục riêng; đợt này ô này là điểm vào chưa kích hoạt, chạm vào không lỗi/không treo.
- Tìm kiếm & lọc (`05-tim-kiem-loc.svg`), giao dịch định kỳ (`06-giao-dich-dinh-ky.svg`), nhập liệu hàng loạt, quét OCR, đa tiền tệ, dark mode, chế độ riêng tư che số tiền.
