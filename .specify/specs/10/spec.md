# Đặc tả tính năng: Màn hình chi tiết giao dịch

**Mã PBI**: 10
**Ngày tạo**: 2026-09-05
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Khi người dùng muốn xem lại một giao dịch đã ghi nhận, người ta cần thấy đầy đủ thông tin của nó (danh mục, số tiền, ví, ngày giờ, ghi chú, tag, ảnh hóa đơn, vị trí) trên một màn riêng, thay vì chỉ là dòng tóm tắt trong danh sách. Tính năng này dựng **màn hình "Chi tiết giao dịch"** theo đúng thiết kế `docs/transaction/04-chi-tiet-giao-dich.svg`: màn phụ có app bar thương hiệu và nút quay lại, khối tóm tắt ở đầu (icon danh mục, tên danh mục, số tiền lớn màu ngữ cảnh), bên dưới là danh sách chi tiết theo từng trường. Màn mở ra khi người dùng chạm vào một dòng giao dịch trong danh sách (điểm vào đã dựng ở PBI 9). Đợt này tập trung **hiển thị đúng toàn bộ dữ liệu của một giao dịch** thuộc mọi loại (thu / chi / chuyển khoản / điều chỉnh số dư); các hành động sửa, xóa, nhân bản chỉ xuất hiện làm điểm vào, chưa kích hoạt vì màn đích (thêm/sửa giao dịch) nằm ở PBI sau.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính

1. Người dùng mở app (đã qua màn khóa PIN), vào tab **"Giao dịch"** và chạm vào **một dòng giao dịch** trong danh sách → màn "Chi tiết giao dịch" mở ra: app bar teal có nút quay lại bên trái, tiêu đề "Chi tiết giao dịch", icon 3 chấm bên phải; khối tóm tắt ở đầu; bên dưới là danh sách chi tiết.
2. Người dùng nhìn khối tóm tắt để nhận biết ngay bản chất giao dịch: icon danh mục tròn trên nền teal nhạt, tên danh mục, số tiền lớn đặt màu theo loại — thu màu thương hiệu (teal), chi màu chi tiêu (coral), chuyển khoản / điều chỉnh số dư màu trung tính.
3. Người dùng cuộn đọc từng dòng chi tiết: Ví, Ngày giờ, Ghi chú (nếu có), Tag (nếu có), Ảnh hóa đơn (nếu có), Vị trí (nếu có) — mỗi dòng có nhãn và giá trị rõ ràng, ngăn cách bởi đường kẻ mảnh.
4. Khi cần thao tác tiếp, người dùng chạm **nút "Sửa"** (dưới cùng), **nút "Nhân bản"** hoặc **icon 3 chấm** (menu Sửa/Xóa) — các điểm vào này dẫn tới luồng thao tác được xây ở PBI sau, đợt này chạm vào không gây lỗi hay treo.
5. Người dùng chạm **nút quay lại** (hoặc cử chỉ back) để trở về danh sách giao dịch.

### Kịch bản chấp nhận

1. **Given** người dùng đã mở khóa app và đang ở danh sách giao dịch có một giao dịch chi "Ăn uống · Ăn ngoài – 85.000 đ – ví Tiền mặt, ghi chú 'Ăn trưa cùng đồng nghiệp', tag #côngty, ngày 03/09/2026 12:15" **When** chạm vào dòng giao dịch đó **Then** màn chi tiết mở ra hiển thị đúng bố cục `04-chi-tiet-giao-dich.svg`: khối tóm tắt có icon danh mục trên nền teal nhạt, dòng "Ăn uống · Ăn ngoài", số tiền `−85.000 đ` màu coral; các dòng chi tiết hiển thị đúng Ví "Tiền mặt", Ngày giờ "03/09/2026 · 12:15", Ghi chú, tag "#côngty", Ảnh hóa đơn.
2. **Given** giao dịch được chọn là khoản thu "Lương 15.000.000 đ – Tài khoản ngân hàng" **When** mở chi tiết **Then** khối tóm tắt hiển thị tên danh mục và số tiền `+15.000.000 đ` màu thương hiệu (teal), phân biệt rõ với khoản chi màu coral.
3. **Given** giao dịch được chọn là một khoản chuyển khoản 500.000 đ từ ví "Tiền mặt" sang ví "Ngân hàng" **When** mở chi tiết **Then** khối tóm tắt hiển thị nhãn "Chuyển khoản" với biểu tượng trung tính (không màu thu/chi), số tiền `500.000 đ` không dấu `+`/`−`; vùng chi tiết cho thấy rõ "Ví nguồn: Tiền mặt" và "Ví đích: Ngân hàng".
4. **Given** một giao dịch không có ghi chú, tag, ảnh hay vị trí **When** mở chi tiết **Then** màn chỉ hiển thị các dòng có dữ liệu (Ví, Ngày giờ, danh mục ở tóm tắt), không xuất hiện dòng trống hay dấu phân cách thừa.
5. **Given** giao dịch thuộc danh mục con (ví dụ danh mục con "Ăn ngoài" của cha "Ăn uống") **When** mở chi tiết **Then** tên danh mục ở khối tóm tắt hiển thị dạng "cha · con" (không chỉ tên con).
6. **Given** một giao dịch vừa được ghi mới/sửa/xóa ở nơi khác trong app **When** chạm dòng của nó trong danh sách **Then** màn chi tiết phản ánh đúng dữ liệu mới nhất, không phải làm mới thủ công.
7. **Given** người dùng đang ở màn chi tiết **When** chạm nút quay lại hoặc dùng cử chỉ back **Then** trở về đúng danh sách giao dịch ở vị trí đã cuộn trước đó.
8. **Given** người dùng đang ở màn chi tiết **When** chạm nút "Sửa", "Nhân bản" hoặc icon 3 chấm **Then** không xảy ra lỗi hay treo; hành động không kích hoạt vì màn thao tác tương ứng nằm ở PBI sau.
9. **Given** người dùng bật cỡ chữ lớn nhất hỗ trợ hoặc dùng màn hình có vùng an toàn **When** mở chi tiết một giao dịch **Then** khối tóm tắt và mọi dòng chi tiết hiển thị đầy đủ, cuộn được, không vỡ hay tràn.

### Trường hợp biên

- Giao dịch là loại "điều chỉnh số dư" (sinh từ module ví) → hiển thị trung tính như chuyển khoản: không gắn danh mục thu/chi, không màu teal/coral; tên/giá trị hiển thị theo đúng dữ liệu điều chỉnh.
- Danh mục đã bị ẩn hoặc không còn trong lựa chọn nhanh → tên và màu danh mục trên màn chi tiết giao dịch cũ vẫn hiển thị đúng (lịch sử giữ nguyên).
- Ví đã bị ẩn → tên ví vẫn hiển thị ở dòng chi tiết, người dùng không bối rối.
- Giao dịch không có ghi chú / tag / ảnh / vị trí → các dòng tương ứng được ẩn, không để trống.
- Nhiều tag → hiển thị đủ các tag dạng chip, không bị cắt.
- Ghi chú dài nhiều dòng → hiển thị trọn văn bản, gói dòng, không cắt bớt.
- Số tiền rất lớn hoặc nhiều chữ số → hiển thị đúng định dạng phân tách nghìn, không tràn vượt vùng chứa.
- Ngày giờ giao dịch ở tương lai (đặt lịch) → vẫn hiển thị bình thường đúng ngày giờ ghi nhận.
- Khóa app có hiệu lực → màn chỉ hiển thị sau khi mở khóa, không lộ số tiền qua màn hình khóa.

## Yêu cầu chức năng

- **FR-001**: Hệ thống PHẢI mở màn "Chi tiết giao dịch" khi người dùng chạm vào một dòng giao dịch trong danh sách giao dịch; màn là màn phụ theo đúng bố cục `docs/transaction/04-chi-tiet-giao-dich.svg`: app bar thương hiệu tiêu đề "Chi tiết giao dịch", nút quay lại bên trái, icon 3 chấm bên phải.
- **FR-002**: Khối tóm tắt ở đầu màn PHẢI hiển thị: icon danh mục tròn trên nền teal nhạt, tên danh mục, số tiền lớn — giao dịch **thu** hiển thị số tiền màu thương hiệu (teal) kèm dấu `+`; giao dịch **chi** hiển thị màu coral kèm dấu `−`.
- **FR-003**: Tên danh mục ở khối tóm tắt PHẢI hiển thị đường dẫn đầy đủ "tên cha · tên con" khi giao dịch gắn danh mục con; chỉ tên danh mục khi giao dịch gắn danh mục cấp cao nhất.
- **FR-004**: Giao dịch **chuyển khoản** và **điều chỉnh số dư** PHẢI hiển thị khối tóm tắt trung tính: nhãn loại giao dịch (không tên danh mục thu/chi), biểu tượng và số tiền màu trung tính, số tiền KHÔNG có dấu `+`/`−`; không được dùng màu teal/coral cho hai loại này.
- **FR-005**: Vùng chi tiết PHẢI hiển thị tối thiểu các dòng: **Ví** và **Ngày giờ** (định dạng ngày tháng năm đầy đủ kèm giờ phút, ví dụ "03/09/2026 · 12:15").
- **FR-006**: Giao dịch chuyển khoản PHẢI hiển thị ở vùng chi tiết **hai** dòng phân biệt "ví nguồn" và "ví đích", để người dùng xác định đúng chiều chuyển.
- **FR-007**: Vùng chi tiết PHẢI hiển thị thêm từng dòng sau đây **chỉ khi giao dịch có dữ liệu tương ứng**: Ghi chú (trọn văn bản, gói dòng), Tag (dạng chip, đủ tất cả tag), Ảnh hóa đơn (thumbnail), Vị trí (dạng text). Giao dịch không có trường nào thì không hiển thị dòng đó.
- **FR-008**: Các dòng chi tiết PHẢI có nhãn (label) và giá trị rõ ràng, ngăn cách bằng đường kẻ mảnh, có thể cuộn khi nội dung vượt quá một màn hình.
- **FR-009**: Số tiền PHẢI hiển thị theo chuẩn tiền tệ của app (phân tách nghìn bằng dấu chấm, đơn vị `đ`), căn phải trong vùng chứa, không tràn hay bị cắt với số tiền rất lớn.
- **FR-010**: Màn PHẢI hiển thị đúng dữ liệu mới nhất của giao dịch sau khi nó được ghi mới/sửa/xóa ở nơi khác trong app, không yêu cầu thao tác làm mới thủ công.
- **FR-011**: Tên và màu danh mục, tên ví của giao dịch cũ PHẢI hiển thị đúng ngay cả khi danh mục hoặc ví đó đã bị ẩn.
- **FR-012**: Màn PHẢI thể hiện đúng các điểm vào tương tác theo mockup: **nút "Sửa"** và **nút "Nhân bản"** cạnh nhau dưới cùng ("Nhân bản" là nút phụ, "Sửa" là nút chính), **icon 3 chấm** ở app bar. Đợt này các điểm vào chưa kích hoạt luồng sâu vì màn đích (thêm/sửa giao dịch) nằm ở PBI riêng; người dùng chạm vào KHÔNG được gây lỗi hay treo.
- **FR-013**: Nút quay lại ở app bar và cử chỉ back PHẢI đưa người dùng trở về đúng danh sách giao dịch ở vị trí đã xem.
- **FR-014**: Màn hình PHẢI hiển thị đầy đủ, cuộn được và không vỡ bố cục trên các kích thước màn hình, vùng an toàn và thiết lập cỡ chữ khác nhau (điện thoại).
- **FR-015**: Màn "Chi tiết giao dịch" PHẢI chỉ hiển thị khi app đã được mở khóa; không được để người dùng nhìn thấy số tiền qua màn hình khóa.

## Tiêu chí thành công

- **SC-001**: Từ danh sách giao dịch, chạm một dòng và thấy màn chi tiết hiển thị đầy đủ trong không quá 1 giây với bộ dữ liệu lên tới 1.000 giao dịch.
- **SC-002**: Với giao dịch mẫu khớp mockup `04-chi-tiet-giao-dich.svg` (chi 85.000 đ, Ăn uống · Ăn ngoài, ví Tiền mặt, ghi chú, tag, ảnh hóa đơn, vị trí...), từng trường hiển thị khớp 100% với dữ liệu gốc khi đối chiếu thủ công; không sai lệch giá trị hay định dạng.
- **SC-003**: Người dùng nhìn khối tóm tắt phân biệt được ngay loại giao dịch qua màu sắc và dấu: thu (teal, `+`), chi (coral, `−`), chuyển khoản / điều chỉnh (trung tính, không dấu), không cần giải thích.
- **SC-004**: Mọi loại giao dịch hiện có (thu, chi, chuyển khoản, điều chỉnh số dư) khi được chạm trong danh sách đều mở đúng màn chi tiết tương ứng, không xảy ra lỗi hoặc màn trống.
- **SC-005**: Giao dịch chuyển khoản hiển thị đúng chiều "ví nguồn → ví đích" ở vùng chi tiết; đối chiếu 100% với dữ liệu hai bút toán liên kết của khoản chuyển.
- **SC-006**: Giao dịch thiếu các trường tùy chọn (ghi chú/tag/ảnh/vị trí) hiển thị màn gọn gàng, chỉ đúng các dòng có dữ liệu, không có dòng trống hay lỗi.
- **SC-007**: Đối chiếu trực quan với `04-chi-tiet-giao-dich.svg`: vị trí app bar, khối tóm tắt (icon/tên/số tiền), cấu trúc từng dòng chi tiết và hai nút dưới cùng hiển thị đúng khi dữ liệu đầu vào tương ứng.
- **SC-008**: Sau khi quay lại từ màn chi tiết, danh sách giao dịch giữ nguyên vị trí cuộn; thao tác mở/đóng màn chi tiết nhiều lần mượt, không treo hay rò rỉ bộ nhớ rõ rệt.
- **SC-009**: Với cỡ chữ lớn nhất và vùng an toàn khác nhau, màn chi tiết vẫn hiển thị đầy đủ, cuộn được, không vỡ bố cục hay cắt mất nút dưới cùng.

## Thực thể chính

- **Giao dịch (transaction)**: dữ liệu nguồn toàn bộ nội dung màn. Mỗi giao dịch gồm loại (thu / chi / chuyển khoản / điều chỉnh số dư), số tiền, ngày giờ, ví (hoặc cặp ví nguồn–đích với chuyển khoản), danh mục (với thu/chi), ghi chú, tag, ảnh hóa đơn, vị trí. Khoản chuyển khoản được lưu bằng hai bút toán liên kết nhưng trình bày trên một màn chi tiết duy nhất.
- **Danh mục (category)**: cung cấp tên (kèm đường dẫn cha · con), icon và màu cho khối tóm tắt của giao dịch thu/chi; không áp dụng cho chuyển khoản và điều chỉnh số dư. Danh mục đã ẩn vẫn giữ tên/màu trên giao dịch cũ.
- **Ví (wallet)**: cung cấp tên hiển thị ở dòng "Ví" (hoặc "Ví nguồn"/"Ví đích" với chuyển khoản). Ví đã ẩn vẫn hiện tên trên giao dịch lịch sử của nó.

## Giả định

- Chạm dòng giao dịch trong danh sách (PBI 9) là điểm vào đã dựng sẵn; đợt này kích hoạt điều hướng từ dòng đó sang màn chi tiết.
- Màn chi tiết hiển thị được mọi loại giao dịch hiện có trong dữ liệu (thu, chi, chuyển khoản, điều chỉnh số dư); không chỉ giới hạn thu/chi.
- "Sửa" và "Nhân bản" trên màn chi tiết về bản chất mở lại màn thêm/sửa giao dịch với dữ liệu điền sẵn; màn đó chưa tồn tại nên đợt này chỉ dựng điểm vào, chưa kích hoạt luồng sâu — nhất quán convention "mỗi PBI = một màn" của module Giao dịch.
- Xóa giao dịch (dialog xác nhận + Undo) thuộc luồng thao tác gắn với màn thêm/sửa giao dịch, chưa làm trong đợt này.
- Các con số trong mockup chỉ mang tính minh họa; số hiển thị lấy trực tiếp từ dữ liệu của thiết bị.
- App dùng một đơn vị tiền tệ thống nhất giai đoạn hiện tại; định dạng tiền theo chuẩn của app. Quy đổi đa tiền tệ thuộc đợt sau.
- Giai đoạn này chưa sinh giao dịch định kỳ nên chưa có nguồn gốc "định kỳ" để thể hiện riêng; khi module định kỳ được làm, màn chi tiết bổ sung theo quy tắc chung.
- Xem phóng to ảnh hóa đơn và mở bản đồ từ vị trí giao dịch là thao tác mở rộng, để cùng đợt gắn ảnh/vị trí (màn thêm/sửa giao dịch); đợt này chỉ hiển thị thumbnail và text.
- App dùng chủ yếu theo chiều dọc trên điện thoại, giao diện tiếng Việt; tablet/đa ngôn ngữ chưa phải mục tiêu đợt này.

## Quyết định đã chốt

- **Phạm vi đợt này = hiển thị (xem) + kích hoạt điểm vào từ danh sách, chưa kích hoạt hành động sửa/xóa/nhân bản** — theo lựa chọn của người dùng. Màn "Chi tiết giao dịch" đúng vai trò "xem lại thông tin một giao dịch"; nút Sửa/Nhân bản và menu 3 chấm hiển thị đúng mockup nhưng là điểm vào cho PBI thêm/sửa giao dịch (module Giao dịch, làm sau), chạm vào không lỗi, không treo.
- **Khối tóm tắt và vùng chi tiết phân loại màu theo đúng nguyên tắc nhóm Giao dịch** (docs §5): thu teal `+`, chi coral `−`, chuyển khoản và điều chỉnh số dư trung tính không dấu.
- **Tên danh mục ở chi tiết hiển thị đường dẫn "cha · con"** (mockup ghi "Ăn uống · Ăn ngoài"), khác quy ước dòng danh sách chỉ hiển thị tên con — vì chi tiết là nơi đọc thông tin đầy đủ.
- **Chuyển khoản trình bày trên một màn duy nhất**, vùng chi tiết phân hai dòng "Ví nguồn"/"Ví đích" cho rõ chiều chuyển.
- **Ẩn các dòng chi tiết không có dữ liệu** (ghi chú/tag/ảnh/vị trí) — nhất quán cách danh sách PBI 9 ẩn dòng phụ thừa.

## Ngoài phạm vi

- Hành động sửa, xóa (dialog xác nhận + Undo), nhân bản giao dịch và màn thêm/sửa giao dịch (`02-them-giao-dich.svg`, `03-chon-danh-muc.svg`).
- Xem phóng to ảnh hóa đơn, mở bản đồ từ vị trí giao dịch.
- Màn tìm kiếm & lọc (`05-tim-kiem-loc.svg`) và giao dịch định kỳ (`06-giao-dich-dinh-ky.svg`).
- Nghiệp vụ ví: ẩn/xóa ví, điều chỉnh số dư, chuyển tiền giữa ví (đã xử lý ở các PBI ví).
- Hiển thị và quy đổi đa tiền tệ, kỳ tài chính tùy chỉnh, dark mode, chế độ riêng tư che số tiền.
