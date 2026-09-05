# Đặc tả tính năng: Màn hình danh sách giao dịch

**Mã PBI**: 9
**Ngày tạo**: 2026-09-05
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Người dùng cần một màn trục chính nhìn toàn bộ giao dịch đã ghi nhận (thu / chi / chuyển khoản nội bộ) của thiết bị, sắp theo thời gian, kèm tổng thu và tổng chi trong tháng để theo dõi dòng tiền nhanh mà không phải mở từng báo cáo. Tính năng này dựng nội dung **màn hình "Giao dịch"** — một trong bốn tab chính của thanh điều hướng đáy (khung đã dựng ở PBI 2) — theo đúng thiết kế `docs/transaction/01-danh-sach-giao-dich.svg`: app bar thương hiệu có tiêu đề và điểm vào lọc, card thống kê nhanh "Thu/Chi tháng này", bên dưới là danh sách giao dịch nhóm theo ngày với màu sắc và định dạng tiền đúng quy ước thu/chi/chuyển khoản của app. Đợt này tập trung **hiển thị đúng dữ liệu giao dịch hiện có** và **dựng các điểm vào điều hướng** của màn (FAB thêm, icon lọc, chạm một dòng) — các luồng thao tác sâu (thêm/sửa/xóa, chi tiết giao dịch, tìm kiếm & lọc) chưa kích hoạt vì màn đích nằm ở PBI riêng.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính

1. Người dùng mở app (đã qua màn khóa PIN) và chạm tab **"Giao dịch"** ở thanh điều hướng đáy → màn danh sách giao dịch hiện ra: app bar teal tiêu đề "Giao dịch" và icon lọc bên phải; card thống kê nhanh hai khối "Thu tháng này" (teal, dấu mũi tên lên) và "Chi tháng này" (coral, mũi tên xuống); bên dưới là danh sách giao dịch nhóm theo ngày.
2. Người dùng đọc danh sách: mỗi nhóm có tiêu đề ngày (nhóm gần nhất ở trên), mỗi dòng giao dịch gồm icon danh mục, tên, dòng phụ và số tiền căn phải — thu màu teal kèm dấu `+`, chi màu coral kèm dấu `−`, chuyển khoản màu trung tính không dấu. Nhờ màu và dấu, người dùng phân biệt ngay dòng thu/chi mà không cần đọc kỹ.
3. Người dùng ghi nhận tổng thu/chi trong tháng từ card thống kê ở đầu màn; các con số này là tổng giao dịch thu/chi của thiết bị trong tháng hiện tại, không gồm chuyển khoản.
4. Khi cần thao tác tiếp: người dùng chạm **FAB "+" nổi giữa** để ghi giao dịch mới, chạm **icon lọc** để tìm kiếm/lọc, hoặc chạm một **dòng giao dịch** để xem chi tiết — đây là các điểm vào dẫn tới màn được xây ở PBI sau.

### Kịch bản chấp nhận

1. **Given** người dùng đã mở khóa app **When** chạm tab "Giao dịch" **Then** màn hiển thị đúng bố cục `01-danh-sach-giao-dich.svg`: app bar teal tiêu đề "Giao dịch" + icon lọc, card "Thu tháng này"/"Chi tháng này", danh sách giao dịch nhóm theo ngày, tab "Giao dịch" đang chọn tô màu thương hiệu.
2. **Given** thiết bị có giao dịch chi "Ăn uống – 85.000 đ – ví Tiền mặt, ghi chú 'Ăn trưa'" và giao dịch chi "Di chuyển – 42.000 đ – ví Momo, ghi chú 'Grab'" trong hôm nay **When** xem danh sách **Then** hai dòng nằm chung nhóm "HÔM NAY", mỗi dòng hiển thị icon danh mục, tên danh mục, phụ đề "Ví · ghi chú", số tiền `−85.000 đ` và `−42.000 đ` màu coral căn phải.
3. **Given** có một giao dịch thu "Lương 15.000.000 đ – Tài khoản ngân hàng" **When** xem danh sách **Then** dòng thu hiển thị số tiền `+15.000.000 đ` màu teal (thương hiệu), khác biệt rõ với dòng chi màu coral.
4. **Given** có một khoản chuyển 500.000 đ giữa ví "Tiền mặt" và "Ngân hàng" **When** xem danh sách **Then** hiển thị **một** dòng "Chuyển khoản", phụ đề "Tiền mặt → Ngân hàng", số tiền `500.000 đ` màu trung tính **không** có dấu `+`/`−`; khoản chuyển không xuất hiện thành hai dòng.
5. **Given** giao dịch thu/chi ghi trong tháng hiện tại **When** đối chiếu card thống kê **Then** "Thu tháng này" đúng tổng các khoản thu, "Chi tháng này" đúng tổng các khoản chi trong tháng; khoản chuyển khoản và khoản điều chỉnh số dư không làm thay đổi hai con số này.
6. **Given** một giao dịch vừa được ghi nhận/sửa/xóa ở nơi khác trong app **When** người dùng quay lại tab "Giao dịch" **Then** danh sách và card thống kê phản ánh đúng dữ liệu mới, không cần thao tác làm mới thủ công.
7. **Given** thiết bị có dữ liệu giao dịch **When** cuộn tới cuối danh sách **Then** danh sách được nạp tiếp lũy tiến, thao tác cuộn mượt, không treo/giật.
8. **Given** người dùng bật cỡ chữ lớn nhất hỗ trợ hoặc dùng màn hình có vùng an toàn **When** mở màn "Giao dịch" **Then** app bar, card thống kê, nhóm ngày và từng dòng giao dịch hiển thị đầy đủ, cuộn được, không vỡ hay tràn.

### Trường hợp biên

- Chưa có bất kỳ giao dịch nào → card thống kê hiển thị `0 đ` cho cả hai khối; vùng danh sách rỗng hiển thị trạng thái hướng dẫn ghi giao dịch đầu tiên, không báo lỗi.
- Thiết bị có giao dịch chuyển khoản nhưng chưa có thu/chi trong tháng → "Thu tháng này" và "Chi tháng này" hiển thị `0 đ`, danh sách vẫn có dòng chuyển khoản.
- Giao dịch ghi ở ngày tương lai (đặt lịch) → vẫn xuất hiện trong danh sách theo đúng thứ tự ngày giờ giảm dần, nhóm ngày của nó nằm trên các nhóm quá khứ; không bị ẩn hay tính nhầm vào card tháng.
- Hai giao dịch cùng thời điểm → thứ tự trong nhóm theo quy tắc ổn định (thứ tự được ghi nhận), không nhảy lung tung giữa các lần xem.
- Ví đã bị ẩn → giao dịch thuộc ví đó vẫn hiển thị trong danh sách (giữ lịch sử); người dùng không bối rối vì tên ví vẫn hiện ở dòng phụ.
- Danh mục đã bị ẩn hoặc không còn trong lựa chọn nhanh → tên và màu danh mục trên dòng giao dịch cũ vẫn hiển thị đúng (lịch sử giữ nguyên).
- Giao dịch không có ghi chú → dòng phụ chỉ hiển thị tên ví, không hiển thị dấu phân cách thừa.
- Số tiền rất lớn hoặc nhiều chữ số → hiển thị đúng định dạng phân tách nghìn, không tràn vượt vùng chứa của dòng.
- Giao dịch loại "điều chỉnh số dư" (sinh từ module ví, chưa có luồng tạo ở giai đoạn này) → nếu tồn tại trong dữ liệu thì hiển thị như dòng trung tính, không gắn danh mục thu/chi, không tính vào card thống kê.
- Khóa app có hiệu lực → màn chỉ hiển thị sau khi mở khóa, không lộ số tiền qua màn hình khóa.

## Yêu cầu chức năng

- **FR-001**: Hệ thống PHẢI hiển thị màn "Giao dịch" khi người dùng chạm tab "Giao dịch" trong thanh điều hướng đáy; màn là màn chính theo đúng bố cục `docs/transaction/01-danh-sach-giao-dich.svg`: app bar thương hiệu có tiêu đề "Giao dịch" và icon lọc, card thống kê nhanh, danh sách giao dịch nhóm theo ngày; tab "Giao dịch" hiển thị trạng thái đang chọn.
- **FR-002**: Card thống kê PHẢI có hai khối cạnh nhau: "Thu tháng này" (mũi tên lên, màu teal) và "Chi tháng này" (mũi tên xuống, màu coral), mỗi khối hiển thị tổng tiền tương ứng của tháng hiện tại, định dạng đúng chuẩn tiền tệ của app (phân tách nghìn, đơn vị `đ`).
- **FR-003**: "Thu tháng này" PHẢI là tổng số tiền của các giao dịch **thu**, "Chi tháng này" PHẢI là tổng của các giao dịch **chi**, tính trong khoảng **từ ngày đầu tháng dương lịch hiện tại đến thời điểm xem**, gồm giao dịch của **mọi ví kể cả ví đã ẩn**; giao dịch chuyển khoản và giao dịch điều chỉnh số dư KHÔNG được tính vào hai con số này.
- **FR-004**: Danh sách PHẢI liệt kê giao dịch của toàn bộ ví (kể cả ví đã ẩn), sắp theo ngày giờ giảm dần và PHẢI nhóm chúng theo ngày; nhóm có ngày mới nhất nằm trên cùng.
- **FR-005**: Tiêu đề mỗi nhóm ngày PHẢI hiển thị nhãn ngày rõ ràng kèm ngày đầy đủ; ngày là hôm nay/hôm qua PHẢI dùng nhãn tương đối tương ứng ("HÔM NAY", "HÔM QUA").
- **FR-006**: Mỗi dòng giao dịch thu/chi PHẢI hiển thị: icon tròn nền theo màu danh mục, tên danh mục, dòng phụ gồm tên ví (kèm ghi chú sau dấu phân cách nếu có), và số tiền căn phải — giao dịch thu PHẢI hiển thị màu teal kèm dấu `+`, giao dịch chi PHẢI hiển thị màu coral kèm dấu `−`.
- **FR-007**: Một khoản chuyển khoản (2 bút toán liên kết trên hai ví) PHẢI được biểu diễn bằng **đúng một dòng** trong danh sách: nhãn "Chuyển khoản", dòng phụ dạng "ví nguồn → ví đích", số tiền hiển thị màu trung tính **không** có dấu `+`/`−`; KHÔNG được xuất hiện thành hai dòng.
- **FR-008**: Giao dịch loại "điều chỉnh số dư" nếu có trong dữ liệu PHẢI hiển thị thành dòng trung tính không thuộc thu/chi (không gắn màu teal/coral, không gắn danh mục thu/chi) và KHÔNG được tính vào "Thu/Chi tháng này".
- **FR-009**: Số tiền PHẢI căn phải trong dòng, phân tách nghìn bằng dấu chấm kèm đơn vị tiền tệ; số tiền rất lớn PHẢI hiển thị đầy đủ, không tràn vượt vùng chứa hay bị cắt.
- **FR-010**: Khi thiết bị chưa có giao dịch nào, hệ thống PHẢI hiển thị trạng thái danh sách rỗng có hướng dẫn rõ ràng (gợi ý ghi giao dịch đầu tiên) và card thống kê hiển thị giá trị `0` hợp lệ, không xảy ra lỗi.
- **FR-011**: Danh sách và card thống kê PHẢI phản ánh đúng dữ liệu hiện có; sau khi giao dịch được ghi mới/sửa/xóa ở nơi khác, khi người dùng quay lại tab này dữ liệu PHẢI hiển thị đã cập nhật, không yêu cầu thao tác làm mới thủ công.
- **FR-012**: Danh sách dài (nhiều giao dịch) PHẢI nạp thêm lũy tiến theo thao tác cuộn của người dùng, thao tác cuộn mượt, không treo hay giật; dữ liệu hiển thị không bị trùng lặp hay bỏ sót giữa các lần nạp.
- **FR-013**: Màn hình PHẢI hiển thị đầy đủ, cuộn được và không vỡ bố cục trên các kích thước màn hình, vùng an toàn và thiết lập cỡ chữ khác nhau (điện thoại).
- **FR-014**: Màn PHẢI thể hiện rõ ba điểm vào tương tác theo đúng mockup: **FAB** "thêm giao dịch" (giữa thanh điều hướng), **icon lọc** (app bar) và **dòng giao dịch** có thể chạm. Đợt này các điểm vào chưa kích hoạt luồng sâu vì màn đích (thêm giao dịch, chi tiết giao dịch, tìm kiếm & lọc) nằm ở PBI riêng; người dùng chạm vào KHÔNG được gây lỗi hay treo.
- **FR-015**: Màn "Giao dịch" PHẢI chỉ hiển thị khi app đã được mở khóa; không được để người dùng nhìn thấy số tiền qua màn hình khóa.

## Tiêu chí thành công

- **SC-001**: Từ bất kỳ tab nào, chạm tab "Giao dịch" và thấy danh sách + card thống kê hiển thị đầy đủ trong không quá 1 giây với bộ dữ liệu lên tới 1.000 giao dịch.
- **SC-002**: Với bộ dữ liệu mẫu khớp mockup (thu 15.000.000 đ, chi 85.000 đ và 42.000 đ, chuyển khoản 500.000 đ...), tổng "Thu/Chi tháng này" và từng dòng hiển thị khớp 100% với đối chiếu thủ công; khoản chuyển khoản và điều chỉnh không làm đổi hai con số tổng.
- **SC-003**: Người dùng mới nhìn danh sách phân biệt được ngay dòng thu (teal, `+`), dòng chi (coral, `−`) và dòng chuyển khoản (trung tính, không dấu) mà không cần giải thích.
- **SC-004**: Mỗi giao dịch trong dữ liệu xuất hiện đúng một lần, đúng nhóm ngày và đúng thứ tự thời gian; số dòng đếm được khớp 100% với số giao dịch hiện có.
- **SC-005**: Sau khi ghi mới/sửa/xóa giao dịch ở nơi khác, quay lại tab "Giao dịch" thấy dữ liệu và thống kê đã đúng — người dùng không phải thực hiện bất kỳ thao tác làm mới thủ công nào.
- **SC-006**: Đối chiếu trực quan với `01-danh-sach-giao-dich.svg`: vị trí app bar, card thống kê, tiêu đề nhóm ngày, cấu trúc dòng (icon/tên/phụ đề/số tiền) và màu thu/chi/chuyển khoản hiển thị đúng khi dữ liệu đầu vào tương ứng.
- **SC-007**: Cuộn qua danh sách dài (nhiều nghìn giao dịch) mượt, không treo; không xuất hiện lỗi hay dữ liệu trùng lặp tại bất kỳ điểm cuộn nào.

## Thực thể chính

- **Giao dịch (transaction)**: dữ liệu nguồn của từng dòng và từng nhóm ngày. Mỗi giao dịch gồm loại (thu / chi / chuyển khoản / điều chỉnh), số tiền, ngày giờ, ví chứa, danh mục (với thu/chi) hoặc cặp ví nguồn–đích (với chuyển khoản), ghi chú. Một khoản chuyển khoản được lưu bằng hai bút toán liên kết nhưng hiển thị thành một dòng duy nhất.
- **Danh mục (category)**: cung cấp tên, icon và màu để nhận diện dòng giao dịch thu/chi; không áp dụng cho chuyển khoản. Danh mục đã ẩn vẫn giữ tên/màu trên giao dịch cũ.
- **Ví (wallet)**: cung cấp tên hiển thị ở dòng phụ của mọi giao dịch và nhãn "ví nguồn → ví đích" của chuyển khoản. Ví đã ẩn vẫn hiện tên trên giao dịch lịch sử của nó.

## Giả định

- Khung điều hướng đáy 5 vị trí với tab "Giao dịch" và FAB đã dựng ở PBI 2; đợt này gắn nội dung đúng vào vị trí đó.
- Chạm dòng giao dịch, FAB và icon lọc là các **điểm vào** dẫn tới màn được xây ở PBI sau (chi tiết giao dịch, thêm giao dịch, tìm kiếm & lọc); đợt này chỉ dựng điểm vào, chưa kích hoạt luồng sâu (màn đích chưa tồn tại).
- Tổng hợp thống kê hiển thị bằng một đơn vị tiền tệ thống nhất; giai đoạn hiện tại mọi ví là cùng tiền tệ nên hiển thị trực tiếp, định dạng tiền theo chuẩn của app. Quy đổi giữa nhiều tiền tệ thuộc đợt đa tiền tệ sau.
- Tên danh mục trên dòng hiển thị trực tiếp danh mục gắn với giao dịch (nếu là danh mục con thì hiển thị tên con), không ghép thêm tên cha.
- Dòng phụ của thu/chi = tên ví, thêm ghi chú sau dấu phân cách khi có ghi chú; dòng phụ của chuyển khoản = "ví nguồn → ví đích".
- Giao dịch loại "điều chỉnh số dư" chưa có luồng tạo ở giai đoạn này nhưng có thể tồn tại trong dữ liệu; đợt này chỉ quy ước cách hiển thị trung tính như nêu ở yêu cầu.
- Các con số trong mockup chỉ mang tính minh họa; số hiển thị lấy trực tiếp từ dữ liệu của thiết bị.
- Chưa áp dụng chế độ riêng tư che số tiền (privacy mode) cho màn này; khi module che số tiền được làm, màn áp dụng theo quy tắc chung của app.
- App dùng chủ yếu theo chiều dọc trên điện thoại, giao diện tiếng Việt; tablet/đa ngôn ngữ chưa phải mục tiêu đợt này.

## Quyết định đã chốt

- **Phạm vi đợt này = hiển thị + dựng điểm vào, chưa kích hoạt luồng sâu** — nhất quán convention "mỗi PBI = một màn" đã dùng ở PBI 5/6/7. FAB / icon lọc / chạm dòng là điểm vào cho PBI thêm giao dịch, chi tiết giao dịch và tìm kiếm & lọc (module Giao dịch, làm sau); đợt này chạm vào không lỗi, không treo.
- **Card "Thu/Chi tháng này" tính theo tháng dương lịch, từ ngày đầu tháng đến thời điểm xem, gồm giao dịch của mọi ví kể cả ví đã ẩn** — nhất quán nguyên tắc "ẩn giữ lịch sử & báo cáo" ([[Nguyên tắc nghiệp vụ]]); loại trừ chuyển khoản và điều chỉnh số dư. Kỳ tài chính tùy chỉnh sẽ xử khi module hồ sơ làm.
- **Không thêm bộ điều hướng tháng trên màn danh sách** — bám đúng mockup `01-danh-sach-giao-dich.svg`; danh sách cuộn toàn bộ theo ngày giờ giảm dần, nạp lũy tiến; muốn khoanh thời đoạn → dùng màn Tìm kiếm & Lọc (PBI sau).

## Ngoài phạm vi

- Luồng ghi nhận giao dịch mới (FAB), màn thêm/sửa giao dịch (`02-them-giao-dich.svg`, `03-chon-danh-muc.svg`) và ghi nhập nhanh.
- Màn chi tiết giao dịch (`04-chi-tiet-giao-dich.svg`) gồm sửa, xóa (kèm Undo), nhân bản, chuỗi định kỳ.
- Màn tìm kiếm & lọc (`05-tim-kiem-loc.svg`) và giao dịch định kỳ (`06-giao-dich-dinh-ky.svg`).
- Bộ điều hướng duyệt lịch sử theo tháng/năm ngay trên màn danh sách (không có trong mockup).
- Nghiệp vụ ví: ẩn/xóa ví, điều chỉnh số dư, chuyển tiền giữa ví (đã xử lý ở các PBI ví).
- Hiển thị và quy đổi đa tiền tệ, kỳ tài chính tùy chỉnh, dark mode, chế độ riêng tư che số tiền.
