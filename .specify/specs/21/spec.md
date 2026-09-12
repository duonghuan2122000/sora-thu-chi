# Đặc tả tính năng: Chi tiết Ngân sách (tiến độ, tốc độ chi tiêu, so sánh nhiều kỳ)

**Mã PBI**: 21
**Ngày tạo**: 2026-09-12
**Trạng thái**: Đã làm rõ

## Mô tả tổng quan

Sau PBI 20, người dùng đã tạo được ngân sách và thấy **% đã dùng** ở màn Tổng quan Ngân sách, nhưng khi một danh mục đã vượt giới hạn thì màn Tổng quan **cố tình không** cho biết vượt bao nhiêu, chi tiêu có đang nhanh hơn nhịp hay không, và xu hướng các kỳ trước ra sao. PBI này dựng **màn Chi tiết Ngân sách** theo đúng mockup `docs/budget/man-hinh-03-chi-tiet-ngan-sach.svg`: mở khi chạm một dòng ngân sách ở màn Tổng quan, cho thấy **số tiền đã dùng so với giới hạn**, **số tiền vượt** và **số ngày còn lại** của kỳ, **cảnh báo tốc độ chi tiêu** so với nhịp thời gian, **biểu đồ so sánh dự kiến – thực tế các kỳ gần nhất**, **danh sách giao dịch Chi thuộc ngân sách trong kỳ** (kèm lối mở rộng sang màn Giao dịch đã lọc sẵn), cùng 2 thao tác **Chỉnh sửa** và **Lưu trữ ngân sách**. Màn còn cho **đổi kỳ đang xem** qua nút ở góc phải app bar để xem lại số liệu và giao dịch của **các kỳ đã qua** của chính ngân sách đó.

Đợt này nối tiếp phạm vi **2a** đã chốt ở PBI 20 (ngân sách theo danh mục, áp dụng tất cả ví) và bổ sung phần **2c** ở mức tối thiểu: so sánh dự kiến–thực tế và tốc độ chi tiêu **tính lại từ dữ liệu giao dịch đã có**, không cần thêm dữ liệu người dùng nhập. Vẫn **chưa** có ngân sách tổng, ngân sách theo ví, cộng dồn phần chưa dùng, cảnh báo đẩy và sao chép kỳ trước.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính — Xem chi tiết một ngân sách đã vượt giới hạn

1. Người dùng ở màn **Tổng quan Ngân sách** (PBI 20), chạm vào dòng ngân sách **"Ăn uống"** → màn **Chi tiết Ngân sách** mở ra theo mockup `03`: app bar màu thương hiệu có nút quay lại, tiêu đề **"Ăn uống"** và dòng phụ **"Ngân sách tháng • Tháng 9, 2026"**, cùng nút **đổi kỳ đang xem** ở góc phải app bar; **không** có thanh điều hướng đáy (màn con đè shell).
2. Thân màn bắt đầu bằng **thẻ tiến độ**: nhãn "Đã dùng", số tiền đã chi hiển thị lớn bằng **màu coral**, dòng phụ **"trên 3.000.000 đ giới hạn"**; bên phải là nhãn "Trạng thái" kèm **huy hiệu "Vượt 107%"** trên nền coral nhạt.
3. Dưới huy hiệu là **thanh tiến độ** của kỳ (đầy và màu coral khi đã vượt), rồi một dòng hai đầu: bên trái **"Vượt 210.000 đ"**, bên phải **"18 ngày còn lại"**.
4. Ngay dưới thẻ tiến độ là **băng cảnh báo tốc độ chi tiêu** trên nền coral nhạt: biểu tượng cảnh báo, tiêu đề **"Tốc độ chi tiêu nhanh hơn dự kiến"**, dòng phụ **"Đã dùng 60% ngày nhưng chi 107% ngân sách"** — so nhịp chi tiêu với nhịp thời gian đã trôi qua của kỳ.
5. Tiếp theo là khối **"SO SÁNH DỰ KIẾN • THỰC TẾ"**: chú giải **Dự kiến** / **Thực tế**, một đường mốc giới hạn nét đứt ghi **"Dự kiến 3.000.000 đ"**, và **biểu đồ cột đôi cho 3 kỳ gần nhất** (VD T7, T8, T9) — mỗi kỳ có cột **Dự kiến** (màu trung tính) và cột **Thực tế** (teal nếu không vượt, coral nếu vượt; kỳ đang xem được nhấn đậm tên kỳ).
6. Tiếp theo là nhóm **"GIAO DỊCH TRONG KỲ"** với liên kết **"Xem tất cả"** ở bên phải, và danh sách các giao dịch **Chi** thuộc phạm vi ngân sách trong kỳ — mỗi dòng: biểu tượng danh mục, tên giao dịch, thời gian, số tiền Chi màu coral.
7. Cuối màn là 2 nút cao bằng nhau: **"Chỉnh sửa"** (viền) và **"Lưu trữ ngân sách"** (nền màu thương hiệu).
8. Người dùng chạm nút ở góc phải app bar → **bộ chọn kỳ** mở ra, liệt kê các kỳ của ngân sách **từ kỳ bắt đầu áp dụng đến kỳ hiện tại**; người dùng chọn **"Tháng 8, 2026"** → toàn màn Chi tiết chuyển sang kỳ đó: dòng phụ app bar, thẻ tiến độ, số tiền vượt/còn lại, huy hiệu trạng thái, biểu đồ và danh sách giao dịch đều tính cho **tháng 8**; kỳ đã kết thúc nên **không** hiển thị băng cảnh báo tốc độ chi tiêu và dòng ngày còn lại được thay bằng trạng thái **đã kết thúc**.
9. Người dùng chạm **"Xem tất cả"** → mở màn **Giao dịch** đã lọc sẵn theo danh mục của ngân sách và khoảng thời gian của **kỳ đang xem**.
10. Người dùng chạm **"Chỉnh sửa"** → mở màn **Sửa ngân sách** (PBI 20) với giá trị hiện tại điền sẵn; sửa số tiền rồi lưu → quay lại màn Chi tiết với số liệu tính theo giới hạn mới.
11. Người dùng chạm **"Lưu trữ ngân sách"** → hệ thống hỏi xác nhận; đồng ý → ngân sách được lưu trữ, quay về màn **Tổng quan Ngân sách** và dòng ngân sách đó **không còn** trong danh sách đang theo dõi; các giao dịch Chi đã ghi **vẫn còn nguyên** trong sổ giao dịch.

### Kịch bản chấp nhận

1. **Given** màn Tổng quan Ngân sách đang mở **When** chạm vào một dòng ngân sách **Then** màn Chi tiết Ngân sách mở đúng bố cục mockup `03`: app bar thương hiệu + nút quay lại + **tên danh mục làm tiêu đề** + dòng phụ nêu **chu kỳ và kỳ đang xem** + nút **đổi kỳ đang xem** ở góc phải, **không** có thanh điều hướng đáy; mặc định mở ở **kỳ hiện tại** của ngân sách.
2. **Given** màn Chi tiết đang ở kỳ hiện tại **When** người dùng chạm nút đổi kỳ và chọn một **kỳ đã qua** **Then** dòng phụ app bar đổi sang kỳ đó và **toàn bộ** số liệu (thẻ tiến độ, số tiền vượt/còn lại, huy hiệu trạng thái, biểu đồ, danh sách giao dịch) tính lại theo **kỳ đã chọn**; vì kỳ đã kết thúc nên **không** có băng cảnh báo tốc độ chi tiêu và dòng "… ngày còn lại" được thay bằng trạng thái **đã kết thúc**.
3. **Given** ngân sách bắt đầu áp dụng từ tháng 8 **When** mở bộ chọn kỳ **Then** danh sách kỳ **chỉ** gồm các kỳ từ **kỳ bắt đầu áp dụng đến kỳ hiện tại**, không có kỳ nào trước khi ngân sách bắt đầu.
4. **Given** một ngân sách có mức sử dụng từ 100% trở lên **When** xem thẻ tiến độ **Then** số tiền đã dùng hiển thị **màu coral**, dòng phụ ghi "trên {giới hạn} giới hạn", huy hiệu trạng thái ghi **"Vượt {…}%"**, thanh tiến độ đầy màu coral, và dòng dưới thanh ghi **số tiền vượt** ở bên trái cùng **số ngày còn lại** ở bên phải.
5. **Given** một ngân sách chưa vượt giới hạn (dưới 100%) **When** xem thẻ tiến độ **Then** số tiền đã dùng hiển thị theo **màu của dải tương ứng** (teal khi dưới 80%, coral khi từ 80% trở lên), huy hiệu trạng thái **không** dùng chữ "Vượt", và dòng dưới thanh ghi **số tiền còn lại** thay cho số tiền vượt.
6. **Given** nhịp chi tiêu nhanh hơn nhịp thời gian của kỳ (VD đã qua 60% số ngày nhưng đã dùng 107% ngân sách) **When** xem màn Chi tiết **Then** băng cảnh báo hiển thị với tiêu đề "Tốc độ chi tiêu nhanh hơn dự kiến" và dòng phụ nêu **% số ngày đã qua** và **% ngân sách đã dùng**; **Given** chi tiêu không nhanh hơn nhịp thời gian **Then** băng cảnh báo **không** hiển thị.
7. **Given** màn Chi tiết đang mở **When** xem khối so sánh **Then** thấy chú giải "Dự kiến"/"Thực tế", đường mốc giới hạn dạng nét đứt kèm số tiền giới hạn, và biểu đồ cột đôi của **3 kỳ gần nhất tính đến kỳ đang xem** (kỳ đang xem là cột cuối cùng), mỗi kỳ có nhãn kỳ ở dưới trục.
8. **Given** kỳ đang xem đã vượt giới hạn còn kỳ trước chưa vượt **When** xem biểu đồ **Then** cột "Thực tế" của kỳ vượt hiển thị **màu coral** và của kỳ chưa vượt hiển thị **màu teal**; cột "Dự kiến" của mọi kỳ hiển thị **cùng một màu trung tính**; nhãn kỳ đang xem được nhấn đậm hơn các kỳ còn lại.
9. **Given** ngân sách có giao dịch Chi trong kỳ **When** xem nhóm "Giao dịch trong kỳ" **Then** danh sách hiển thị các giao dịch **Chi** thuộc danh mục ngân sách (kể cả giao dịch ở **danh mục con**) trong kỳ đang xem, mới nhất trước, mỗi dòng có biểu tượng danh mục, tên, thời gian và số tiền màu coral; giao dịch **Thu** và **chuyển khoản nội bộ** **không** xuất hiện.
10. **Given** ngân sách có nhiều giao dịch Chi trong kỳ hơn số dòng hiển thị **When** xem nhóm giao dịch **Then** chỉ một số lượng giới hạn giao dịch gần nhất được liệt kê và liên kết **"Xem tất cả"** hiển thị ở tiêu đề nhóm; **Given** kỳ chưa có giao dịch Chi nào **Then** nhóm hiển thị trạng thái rỗng dễ hiểu thay vì danh sách trống trơ.
11. **Given** người dùng chạm **"Xem tất cả"** **When** màn Giao dịch mở **Then** màn này đã **lọc sẵn theo danh mục của ngân sách và khoảng thời gian của kỳ đang xem**, và số giao dịch liệt kê **khớp** với tổng số tiền đã chi hiển thị ở thẻ tiến độ.
12. **Given** màn Chi tiết đang mở **When** người dùng chạm **"Chỉnh sửa"** **Then** màn Sửa ngân sách mở với giá trị hiện tại điền sẵn; lưu thay đổi **Then** quay lại màn Chi tiết với thẻ tiến độ, huy hiệu trạng thái, biểu đồ và danh sách giao dịch **tính lại theo giới hạn mới**, các kỳ trước trên biểu đồ **không** bị thay đổi số thực tế, và màn vẫn đang ở **kỳ người dùng đã chọn trước đó**.
13. **Given** màn Chi tiết đang mở **When** người dùng chạm **"Lưu trữ ngân sách"** **Then** hệ thống hỏi xác nhận trước khi thực hiện; **When** xác nhận **Then** ngân sách không còn nằm trong danh sách đang theo dõi ở màn Tổng quan và màn Chi tiết đóng lại. Hai nút **"Chỉnh sửa"** và **"Lưu trữ ngân sách"** PHẢI hiển thị ở **mọi kỳ** đang xem, không chỉ kỳ hiện tại.
14. **Given** một ngân sách đã được lưu trữ **When** người dùng xem sổ giao dịch **Then** **mọi giao dịch Chi đã ghi trước đó vẫn còn nguyên**, không bị xóa hay sửa.
15. **Given** một giao dịch Chi thuộc ngân sách bị **sửa hoặc xóa** ở màn Giao dịch **When** người dùng mở lại màn Chi tiết **Then** số đã dùng, số tiền vượt/còn lại, huy hiệu trạng thái, biểu đồ và danh sách giao dịch đều phản ánh **số mới**.
16. **Given** danh mục của ngân sách đã bị **xóa** ở module Danh mục **When** mở màn Chi tiết **Then** màn thể hiện rõ ngân sách **không còn hợp lệ** kèm nhắc gán lại danh mục khác, **không** hiển thị số liệu/biểu đồ sai lệch, và ngân sách **không** bị tự động xóa.
17. **Given** ngân sách **không bật lặp lại** và kỳ của nó đã **kết thúc** **When** mở màn Chi tiết **Then** màn mở đúng **kỳ đã kết thúc đó** (kỳ chứa ngày bắt đầu áp dụng), thể hiện rõ trạng thái đã kết thúc, và không hiển thị cảnh báo tốc độ chi tiêu.
18. **Given** ngân sách chu kỳ **Tuần** hoặc **Năm** **When** mở màn Chi tiết **Then** dòng phụ ở app bar nêu đúng **chu kỳ và kỳ đang xem của chính nó**, bộ chọn kỳ liệt kê các **kỳ cùng chu kỳ đó**, và biểu đồ so sánh lấy **3 kỳ gần nhất theo đúng chu kỳ đó tính đến kỳ đang xem**.
19. **Given** ngân sách mới tạo, kỳ hiện tại là kỳ đầu tiên **When** xem biểu đồ so sánh **Then** biểu đồ vẫn hiển thị được với số kỳ hiện có (không lỗi, không đòi hỏi tối thiểu số kỳ).
20. **Given** app đang ở English (PBI 19) **When** mở màn Chi tiết **Then** toàn bộ nhãn tĩnh (tiêu đề, nhãn "Đã dùng"/"Trạng thái", huy hiệu trạng thái, nội dung băng cảnh báo, chú giải biểu đồ, nút đổi kỳ, tiêu đề nhóm, nút, thông báo xác nhận, trạng thái rỗng) hiển thị bằng tiếng Anh, không còn sót tiếng Việt; số tiền vẫn theo định dạng phân tách nghìn kèm đơn vị tiền tệ.
21. **Given** màn hình nhỏ và cỡ chữ lớn nhất **When** người dùng xem màn Chi tiết **Then** màn không vỡ bố cục, thẻ tiến độ và biểu đồ hiển thị đủ nội dung, và cuộn tới được 2 nút cuối màn.

### Trường hợp biên

- Ngân sách **vừa đúng 100%** (đã dùng = giới hạn) → huy hiệu trạng thái thể hiện đã đạt giới hạn; số tiền vượt là 0; thanh tiến độ đầy màu coral.
- Ngân sách **chưa có giao dịch Chi nào** trong kỳ → thẻ tiến độ hiển thị đã dùng 0, thanh tiến độ rỗng, không có số tiền vượt, nhóm giao dịch hiển thị trạng thái rỗng, không có băng cảnh báo.
- **Kỳ vừa bắt đầu** → số ngày còn lại bằng toàn bộ độ dài kỳ; % số ngày đã qua rất nhỏ nên băng cảnh báo chỉ hiện khi chi tiêu thực sự vượt nhịp.
- **Ngày cuối kỳ** → số ngày còn lại là 0 (hoặc 1), không hiển thị số âm.
- **Kỳ đã kết thúc** (kỳ cũ hoặc ngân sách không lặp lại đã hết kỳ) → dòng "… ngày còn lại" được thay bằng trạng thái **đã kết thúc**, và **không** hiển thị băng cảnh báo tốc độ chi tiêu (cảnh báo nhịp chỉ có nghĩa với kỳ đang diễn ra).
- Ngân sách **mới bắt đầu trong kỳ hiện tại** → bộ chọn kỳ chỉ có **một** lựa chọn là kỳ hiện tại; biểu đồ chỉ có một cặp cột.
- Người dùng đang xem **kỳ cũ**, chạm "Xem tất cả" → màn Giao dịch lọc theo **khoảng thời gian của kỳ cũ đó**, không phải kỳ hiện tại.
- Người dùng đang xem **kỳ cũ**, chạm "Chỉnh sửa" rồi lưu → quay lại màn Chi tiết vẫn ở **kỳ cũ đang xem**, số liệu tính theo giới hạn mới (giới hạn áp dụng cho kỳ hiện tại của ngân sách) và số thực tế các kỳ **không** bị hồi tố.
- Giao dịch Chi **phát sinh ở danh mục con** của danh mục ngân sách → vẫn tính vào đã dùng và vẫn xuất hiện trong danh sách giao dịch trong kỳ.
- Giao dịch Chi có **số tiền rất lớn** hoặc số tiền vượt lớn → số tiền hiển thị đúng định dạng phân tách nghìn, không tràn/cắt chữ trong thẻ tiến độ.
- Ngân sách **bật lặp lại** đang ở kỳ thứ N → biểu đồ lấy 3 kỳ gần nhất; nếu ngân sách chỉ mới có 1–2 kỳ dữ liệu thì biểu đồ hiển thị đúng số kỳ đó.
- **Sửa giới hạn ngân sách** giữa kỳ → đường mốc "Dự kiến" và cột "Dự kiến" trên biểu đồ dùng **giới hạn hiện tại**; số thực tế các kỳ trước **không** đổi.
- Ngân sách đã **lưu trữ** → không còn trong danh sách theo dõi ở màn Tổng quan, không tính vào thẻ tổng; dữ liệu giao dịch vẫn nguyên.
- Danh mục bị xóa rồi người dùng **gán lại danh mục khác** qua "Chỉnh sửa" → màn Chi tiết tính lại theo danh mục mới và hiển thị bình thường.
- **Không có mạng / offline** → màn Chi tiết vẫn hiển thị đầy đủ vì toàn bộ số liệu tính từ dữ liệu lưu trên thiết bị.

## Yêu cầu chức năng

- **FR-001**: Chạm vào một dòng ngân sách ở màn **Tổng quan Ngân sách** PHẢI mở màn **Chi tiết Ngân sách** theo mockup `03` (thay cho hành vi mở thẳng màn Sửa ngân sách của PBI 20); màn này là **màn con đè shell** — app bar màu thương hiệu có **nút quay lại**, KHÔNG có thanh điều hướng đáy.
- **FR-002**: App bar màn Chi tiết PHẢI hiển thị **tên danh mục** của ngân sách làm tiêu đề và dòng phụ nêu **chu kỳ + kỳ đang xem** (VD "Ngân sách tháng • Tháng 9, 2026"); với ngân sách chu kỳ Tuần/Năm, dòng phụ PHẢI nêu **kỳ hiện tại của chính ngân sách đó**. App bar PHẢI có nút **đổi kỳ đang xem** ở góc phải theo mockup (FR-023).
- **FR-003**: Thẻ tiến độ PHẢI hiển thị: nhãn "Đã dùng", **số tiền đã chi** cỡ lớn, dòng phụ **"trên {giới hạn} giới hạn"**, nhãn "Trạng thái" kèm **huy hiệu % đã dùng**, **thanh tiến độ** của kỳ, và dòng cuối gồm **số tiền vượt hoặc còn lại** ở bên trái cùng **số ngày còn lại** ở bên phải.
- **FR-004**: Màu của số tiền đã dùng, huy hiệu trạng thái và thanh tiến độ PHẢI theo đúng 3 dải đã chốt ở PBI 20 và mockup `03`: **dưới 80%** → teal; **80% đến dưới 100%** → coral nhạt cho thanh và coral cho chữ; **từ 100% trở lên** → coral đậm cho thanh và coral cho chữ.
- **FR-005**: Huy hiệu trạng thái PHẢI thể hiện đúng mức sử dụng: **"Vượt {…}%"** khi đã dùng từ 100% trở lên; với mức dưới 100% PHẢI dùng cách diễn đạt **không** mang nghĩa "vượt" (VD "Sắp đạt {…}%" ở dải 80–99% và "Bình thường {…}%" ở dải dưới 80%).
- **FR-006**: Khi mức sử dụng **từ 100% trở lên**, dòng dưới thanh tiến độ PHẢI hiển thị **số tiền đã vượt giới hạn** (= đã chi − giới hạn); khi **dưới 100%**, dòng đó PHẢI hiển thị **số tiền còn lại** (= giới hạn − đã chi). Số ngày còn lại của kỳ PHẢI hiển thị ở đầu còn lại của dòng này và **không** bao giờ là số âm; với **kỳ đã kết thúc**, vị trí đó PHẢI hiển thị trạng thái **đã kết thúc** thay cho số ngày còn lại.
- **FR-007**: Màn Chi tiết PHẢI hiển thị **băng cảnh báo tốc độ chi tiêu** khi **% ngân sách đã dùng lớn hơn % số ngày đã trôi qua của kỳ**, gồm tiêu đề "Tốc độ chi tiêu nhanh hơn dự kiến" và dòng phụ nêu **% số ngày đã qua** và **% ngân sách đã dùng**; khi chi tiêu **không** nhanh hơn nhịp thời gian, băng này PHẢI **ẩn**. Băng cảnh báo này chỉ áp dụng cho **kỳ đang diễn ra**: khi kỳ đang xem **đã kết thúc**, băng PHẢI **ẩn**.
- **FR-008**: Màn Chi tiết PHẢI có khối **"SO SÁNH DỰ KIẾN • THỰC TẾ"** gồm **chú giải** "Dự kiến"/"Thực tế", **đường mốc giới hạn** dạng nét đứt kèm số tiền giới hạn, và **biểu đồ cột đôi** cho **3 kỳ gần nhất tính đến kỳ đang xem** (kỳ đang xem là **cột cuối cùng**) — mỗi kỳ có cột "Dự kiến" và cột "Thực tế" cùng **nhãn kỳ** ở dưới trục.
- **FR-009**: Trên biểu đồ, cột **"Dự kiến"** PHẢI dùng **một màu trung tính** cho mọi kỳ; cột **"Thực tế"** PHẢI dùng **teal** khi kỳ đó không vượt giới hạn và **coral** khi kỳ đó vượt giới hạn; **kỳ đang xem** PHẢI được nhấn mạnh (nhãn đậm hơn) so với các kỳ còn lại.
- **FR-010**: Biểu đồ PHẢI lấy kỳ so sánh **theo đúng chu kỳ của ngân sách** (Tháng → 3 tháng gần nhất; Tuần → 3 tuần gần nhất; Năm → 3 năm gần nhất) và PHẢI hiển thị được khi ngân sách mới có **1 hoặc 2 kỳ** dữ liệu, không đòi hỏi số kỳ tối thiểu; khi người dùng xem một **kỳ đã qua**, biểu đồ PHẢI lấy 3 kỳ gần nhất **tính đến kỳ đang xem** (kỳ đang xem là cột cuối).
- **FR-011**: Màn Chi tiết PHẢI có nhóm **"GIAO DỊCH TRONG KỲ"** với liên kết **"Xem tất cả"** ở bên phải tiêu đề; danh sách gồm các giao dịch **Chi** thuộc phạm vi ngân sách trong **kỳ đang xem** — khớp khi giao dịch thuộc **chính danh mục đó hoặc danh mục con** của nó; giao dịch **Thu** và **chuyển khoản nội bộ** PHẢI bị loại hoàn toàn.
- **FR-012**: Mỗi dòng giao dịch PHẢI hiển thị biểu tượng danh mục, **tên giao dịch**, **thời gian**, và **số tiền Chi** ở dạng màu coral; danh sách PHẢI sắp xếp **mới nhất trước** và chỉ liệt kê một **số lượng giới hạn** giao dịch gần nhất (VD 5), phần còn lại xem qua "Xem tất cả".
- **FR-013**: Khi kỳ chưa có giao dịch Chi nào thuộc ngân sách, nhóm giao dịch PHẢI hiển thị **trạng thái rỗng** dễ hiểu thay vì danh sách trống trơ.
- **FR-014**: Liên kết **"Xem tất cả"** PHẢI mở màn **Giao dịch** đã **lọc sẵn theo danh mục của ngân sách (bao gồm danh mục con) và khoảng thời gian của kỳ đang xem**, sao cho tổng các giao dịch hiển thị **khớp** với số tiền đã dùng ở thẻ tiến độ.
- **FR-015**: Màn Chi tiết PHẢI có nút **"Chỉnh sửa"** mở màn Sửa ngân sách (PBI 20) với giá trị hiện tại điền sẵn; sau khi lưu, màn Chi tiết PHẢI **tính lại toàn bộ số liệu** (thẻ tiến độ, huy hiệu, biểu đồ, danh sách giao dịch) theo giới hạn mới.
- **FR-016**: Màn Chi tiết PHẢI có nút **"Lưu trữ ngân sách"**; trước khi thực hiện PHẢI **hỏi xác nhận**, và sau khi xác nhận PHẢI quay về màn **Tổng quan Ngân sách** với ngân sách đó **không còn** trong danh sách đang theo dõi, **không** tính vào thẻ tổng.
- **FR-017**: Lưu trữ ngân sách KHÔNG được xóa hay sửa bất kỳ **giao dịch** nào; sổ giao dịch và số dư ví PHẢI giữ nguyên trước và sau khi lưu trữ.
- **FR-018**: Mọi số liệu trên màn Chi tiết (đã dùng, vượt/còn lại, % đã dùng, ngày còn lại, % ngày đã qua, số thực tế từng kỳ trên biểu đồ, danh sách giao dịch) PHẢI được **tính lại tại thời điểm mở màn** từ dữ liệu giao dịch hiện có, để phản ánh đúng các giao dịch **được thêm/sửa/xóa** sau đó.
- **FR-019**: Với ngân sách có danh mục **đã bị xóa**, màn Chi tiết PHẢI thể hiện trạng thái **không hợp lệ** kèm nhắc gán lại danh mục khác, KHÔNG hiển thị số liệu/biểu đồ sai lệch và KHÔNG tự xóa ngân sách.
- **FR-020**: Với ngân sách **không bật lặp lại** và kỳ **đã kết thúc**, màn Chi tiết PHẢI **mở mặc định ở chính kỳ đã kết thúc đó** (kỳ chứa ngày bắt đầu áp dụng), hiển thị số liệu của kỳ đó, nêu rõ trạng thái đã kết thúc, và KHÔNG hiển thị băng cảnh báo tốc độ chi tiêu.
- **FR-021**: Toàn bộ **nhãn giao diện tĩnh** của màn Chi tiết (tiêu đề, nhãn "Đã dùng"/"Trạng thái", nội dung huy hiệu trạng thái, nội dung băng cảnh báo, chú giải biểu đồ, tiêu đề nhóm, nút, hộp thoại xác nhận lưu trữ, trạng thái rỗng) PHẢI có bản dịch **Tiếng Việt / English** theo ngôn ngữ đang chọn (PBI 19); số tiền PHẢI theo định dạng phân tách nghìn kèm đơn vị tiền tệ.
- **FR-022**: Màn Chi tiết PHẢI hiển thị đúng thiết kế và **không vỡ bố cục** trên các kích thước màn hình, vùng an toàn và cỡ chữ khác nhau; nội dung dài PHẢI cuộn được tới **2 nút ở cuối màn**.
- **FR-023**: Màn Chi tiết PHẢI cho **đổi kỳ đang xem** qua nút ở góc phải app bar: mặc định mở ở **kỳ hiện tại** của ngân sách (hoặc kỳ chứa ngày bắt đầu áp dụng với ngân sách đã kết thúc); bộ chọn kỳ PHẢI liệt kê các kỳ **cùng chu kỳ** của ngân sách, từ **kỳ bắt đầu áp dụng đến kỳ hiện tại** (không có kỳ nào trước khi ngân sách bắt đầu). Chọn một kỳ PHẢI tính lại **toàn bộ** nội dung màn theo kỳ đó: dòng phụ app bar, thẻ tiến độ, số tiền vượt/còn lại, huy hiệu trạng thái, biểu đồ, danh sách giao dịch và phạm vi lọc của "Xem tất cả".
- **FR-024**: Hai nút **"Chỉnh sửa"** và **"Lưu trữ ngân sách"** PHẢI hiển thị và hoạt động ở **mọi kỳ đang xem** (kể cả kỳ đã qua); sau khi chỉnh sửa và lưu, màn Chi tiết PHẢI giữ nguyên **kỳ người dùng đang xem** thay vì nhảy về kỳ hiện tại.

## Tiêu chí thành công

- **SC-001**: Từ màn Tổng quan Ngân sách, người dùng mở được màn Chi tiết Ngân sách trong **1 lần chạm**.
- **SC-002**: Đối chiếu trực quan với `man-hinh-03-chi-tiet-ngan-sach.svg`: **100%** các thành phần (app bar + nút quay lại + tiêu đề + dòng phụ, nút góc phải, thẻ tiến độ với huy hiệu trạng thái, thanh tiến độ, dòng vượt/ngày còn lại, băng cảnh báo tốc độ, chú giải + đường mốc + biểu đồ 3 kỳ, tiêu đề nhóm + liên kết "Xem tất cả", 3 dòng giao dịch, 2 nút cuối màn) hiển thị đúng vị trí và nội dung.
- **SC-003**: Với một ngân sách đã vượt giới hạn, **100%** số liệu hiển thị khớp dữ liệu giao dịch: đã dùng, số tiền vượt, % đã dùng và số ngày còn lại sai lệch **0 đ / 0 ngày** so với tính tay từ sổ giao dịch.
- **SC-004**: **100%** trường hợp thử, băng cảnh báo tốc độ chi tiêu hiển thị **đúng** (hiện khi % ngân sách đã dùng > % số ngày đã qua, ẩn khi ngược lại), kiểm chứng ở các mức đại diện (VD 60% ngày – 107% ngân sách; 90% ngày – 40% ngân sách).
- **SC-005**: Tổng số tiền của danh sách giao dịch trong kỳ **khớp 100%** với số tiền đã dùng ở thẻ tiến độ; và sau khi chạm "Xem tất cả", màn Giao dịch hiển thị **đúng cùng tập giao dịch đó** (0 sai lệch về số lượng và tổng tiền).
- **SC-006**: Biểu đồ so sánh hiển thị **đúng 3 kỳ gần nhất** (hoặc ít hơn khi ngân sách mới có ít kỳ) với cột Dự kiến/Thực tế và nhãn kỳ; màu cột Thực tế đúng theo kết quả từng kỳ ở **100%** trường hợp thử.
- **SC-007**: Sau khi lưu trữ một ngân sách, **100%** giao dịch Chi liên quan vẫn còn nguyên trong sổ giao dịch và số dư ví **không đổi** (so sánh trước/sau: 0 khác biệt).
- **SC-008**: Một giao dịch Chi thuộc ngân sách bị sửa hoặc xóa → mở lại màn Chi tiết thấy số liệu cập nhật ngay trong lần mở đó, **100%** trường hợp thử.
- **SC-009**: Khi app ở English, **0** nhãn tĩnh tiếng Việt còn sót trên màn Chi tiết Ngân sách.
- **SC-010**: Với cỡ chữ lớn nhất và màn hình nhỏ, màn Chi tiết không vỡ bố cục, không cắt chữ, cuộn tới được 2 nút cuối màn ở **100%** lần kiểm tra.
- **SC-011**: Người dùng nhận ra ngay "vượt bao nhiêu tiền" và "còn bao nhiêu ngày" mà không cần chạm thêm chỗ nào — kiểm chứng bằng **100%** người thử nêu đúng 2 thông tin này sau khi mở màn (khảo sát nhỏ, 5 người).
- **SC-012**: Đổi kỳ đang xem ở màn Chi tiết sang một kỳ đã qua → **100%** số liệu (đã dùng, vượt/còn lại, % đã dùng, biểu đồ, danh sách giao dịch) khớp với dữ liệu giao dịch **của kỳ đó**, sai lệch **0 đ / 0 giao dịch**; "Xem tất cả" mở màn Giao dịch lọc đúng **khoảng thời gian của kỳ đã chọn**.

## Thực thể chính

- **Ngân sách** (đã có từ PBI 20, bổ sung **trạng thái lưu trữ**): giới hạn chi tiêu gắn với một danh mục Chi và một chu kỳ (Tuần/Tháng/Năm), cờ lặp lại tự động, ngày bắt đầu áp dụng. Đợt này thêm khả năng **đưa một ngân sách vào trạng thái đã lưu trữ** để ngừng theo dõi mà không mất dữ liệu giao dịch; ngân sách đã lưu trữ không còn xuất hiện trong danh sách theo dõi.
- **Kỳ ngân sách** (đại lượng **tính toán**, không phải dữ liệu người dùng nhập): khoảng thời gian cụ thể của một ngân sách, với **giới hạn**, **đã chi**, **số tiền vượt/còn lại**, **% đã dùng**, **số ngày còn lại** và **% số ngày đã qua**. Đợt này bổ sung việc tính **các kỳ trước** (tối đa 3 kỳ gần nhất) để dựng biểu đồ so sánh — mỗi kỳ trước có giới hạn (theo giới hạn hiện tại của ngân sách) và số thực tế tính từ giao dịch Chi của kỳ đó. **Kỳ đang xem** là một lựa chọn của người dùng (mặc định là kỳ hiện tại; với ngân sách đã kết thúc là kỳ chứa ngày bắt đầu áp dụng) và quyết định toàn bộ số liệu hiển thị trên màn.
- **Giao dịch Chi thuộc ngân sách** (liên kết tới module Giao dịch): các giao dịch Chi trong kỳ, thuộc danh mục ngân sách hoặc danh mục con của nó; là nguồn của mọi số liệu trên màn Chi tiết và là nội dung của danh sách "Giao dịch trong kỳ" cũng như màn Giao dịch đã lọc sẵn.

## Giả định

- **Số kỳ trên biểu đồ = 3 (2 kỳ trước + kỳ đang xem)**: đúng như mockup `03` (T7, T8, T9). Kỳ so sánh lấy theo **chu kỳ của chính ngân sách**; nếu ngân sách mới có 1–2 kỳ thì hiển thị đúng số kỳ đó.
- **Đường/cột "Dự kiến" dùng giới hạn hiện tại của ngân sách cho mọi kỳ**: đợt này không lưu lại giới hạn tại thời điểm từng kỳ, nên nếu người dùng sửa số tiền giới hạn thì mốc "Dự kiến" trên biểu đồ đổi theo (số **thực tế** của các kỳ trước vẫn đúng, không bị hồi tố).
- **Băng cảnh báo tốc độ chi tiêu** dùng ngưỡng đơn giản "% ngân sách đã dùng > % số ngày đã qua của kỳ" (tài liệu nghiệp vụ §4.6 gọi là "tốc độ tiêu", dự đoán tuyến tính); mockup `03` không vẽ trường hợp chi **chậm** hơn nhịp nên đợt này **không** có băng "chi chậm hơn dự kiến".
- **Danh sách "Giao dịch trong kỳ" giới hạn 5 giao dịch gần nhất**: mockup `03` vẽ 3 dòng kèm liên kết "Xem tất cả", cho thấy danh sách chỉ là bản rút gọn.
- **"Xem tất cả" lọc theo danh mục bao gồm danh mục con**: để màn Giao dịch hiển thị khớp với số tiền đã dùng của ngân sách (vốn gộp cả danh mục con). Nếu bộ lọc hiện có không hỗ trợ gộp danh mục con, cần bổ sung — nếu không, hai màn sẽ lệch số.
- **Chỉ có "Lưu trữ", chưa có xóa cứng ngân sách**: tài liệu nghiệp vụ §4.7 ưu tiên lưu trữ và chỉ cho xóa cứng khi ngân sách chưa ghi nhận chi tiêu; mockup `03` chỉ vẽ nút "Lưu trữ".
- **Ngân sách đã lưu trữ chưa có nơi xem lại trong đợt này**: dữ liệu được giữ nguyên (không mất giao dịch, có thể phục vụ báo cáo sau này) nhưng chưa có màn/danh sách riêng để mở lại (đã chốt 2026-09-12 — xem mục "Quyết định đã chốt").
- **Thẻ tiến độ hiển thị "số tiền vượt" thay cho "còn lại"** khi đã vượt giới hạn (mockup `03` chỉ vẽ trường hợp vượt); khi chưa vượt thì hiển thị "còn lại", giữ đúng tinh thần "còn lại … đ" của màn Tổng quan (PBI 20).
- **Chưa có cảnh báo đẩy (push notification)**: module Thông báo chưa dựng; toàn bộ cảnh báo đợt này chỉ thể hiện trên giao diện.
- **Ngân sách vẫn áp dụng cho tất cả ví, một tiền tệ**: kế thừa PBI 20 (ngân sách theo ví và đa tiền tệ thuộc 2b).
- **Không có cài đặt kỳ tài chính lệch ngày (`periodStartRule`)**: kỳ tính theo mốc mặc định (tháng/năm dương lịch, tuần bắt đầu Thứ Hai).
- **Mọi số liệu tính lại khi mở màn**: kế thừa cách làm PBI 20 (không lưu bản ghi kỳ), nên sửa/xóa giao dịch sau đó tự động được phản ánh đúng.

## Ngoài phạm vi

- **Ngân sách tổng** (`scope = total`), **ngân sách theo ví**, **cộng dồn phần chưa dùng hết**, tùy chỉnh **ngưỡng cảnh báo**, **sao chép ngân sách kỳ trước**.
- **Cảnh báo đẩy / thông báo hệ thống**, badge trên app, tổng kết cuối kỳ (phụ thuộc module Thông báo — chưa dựng).
- **Xóa cứng ngân sách**, **phục hồi** ngân sách đã lưu trữ, và **mọi nơi xem lại ngân sách đã lưu trữ** (màn Tổng quan giữ nguyên mockup `01`, không thêm nhóm "Đã lưu trữ") — dữ liệu đã lưu trữ vẫn được giữ nguyên trong máy để phục vụ báo cáo sau này.
- **Dự đoán số tiền chi tới hết kỳ** (con số dự báo cụ thể) — mockup `03` chỉ có băng cảnh báo so nhịp % ngày/% ngân sách.
- **Kỳ tài chính lệch ngày**, **đa tiền tệ / quy đổi tỷ giá**.
- Nội dung còn lại của tab **Báo cáo** (biểu đồ thu/chi, phân bổ danh mục, xuất báo cáo Excel/PDF).
- Hiệu ứng của công tắc **"Ẩn số dư"** (PBI 17) đối với số tiền ngân sách.

## Quyết định đã chốt

- **Chỉ lưu trữ, không có nơi xem lại trong đợt này** — dữ liệu vẫn giữ nguyên trong máy; màn Tổng quan giữ đúng mockup `01` (không thêm nhóm "Đã lưu trữ"). (chốt 2026-09-12)
- **Nút góc phải app bar của mockup `03` = đổi kỳ đang xem** (icon lịch), mở bộ chọn kỳ của chính ngân sách đó. (chốt 2026-09-12)
- **Màn Chi tiết xem được các kỳ đã qua**: mặc định mở ở kỳ hiện tại (hoặc kỳ chứa ngày bắt đầu áp dụng với ngân sách đã kết thúc), người dùng đổi được sang kỳ cũ để xem số liệu và giao dịch của kỳ đó; biểu đồ luôn lấy 3 kỳ gần nhất tính đến kỳ đang xem. (chốt 2026-09-12)
- **Kỳ đã kết thúc không có cảnh báo tốc độ chi tiêu** và thay "… ngày còn lại" bằng trạng thái đã kết thúc (cảnh báo nhịp chỉ có nghĩa với kỳ đang diễn ra). (chốt 2026-09-12)
- **Bộ chọn kỳ chỉ liệt kê từ kỳ bắt đầu áp dụng đến kỳ hiện tại** — không có kỳ trước khi ngân sách tồn tại. (chốt 2026-09-12)
