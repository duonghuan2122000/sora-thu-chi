# Đặc tả tính năng: Báo cáo tổng quan (tab Báo cáo)

**Mã PBI**: 22
**Ngày tạo**: 2026-09-12
**Trạng thái**: Đã làm rõ

## Mô tả tổng quan

Tab **Báo cáo** hiện chỉ là một danh sách điểm vào (hàng "Ngân sách") — người dùng chưa có chỗ nào để **nhìn bức tranh tài chính của mình** mà không phải tự cộng trừ. PBI này dựng **màn Tổng quan Báo cáo** theo mockup `docs/report/man-hinh-01-bao-cao-tong-quan.svg`: chọn **kỳ xem** (Ngày/Tuần/Tháng/Năm), thấy ngay **tổng thu – tổng chi** của kỳ, **biểu đồ cột ghép đôi** dòng tiền 6 đơn vị thời gian gần nhất, **vòng tròn phân bổ chi tiêu theo danh mục**, và **danh sách top danh mục chi tiêu** — kèm lối chạm để đi tới danh sách giao dịch đã lọc theo danh mục đó.

Đợt này chỉ làm **màn 01 (Tổng quan)** — màn cấp tab, nằm trong app shell có thanh điều hướng đáy. Ba màn còn lại của module Báo cáo (Chi tiết theo Danh mục, So sánh Kỳ, Xuất Báo cáo) và **bộ lọc nâng cao** (ví/danh mục/tag/khoảng ngày tuỳ chỉnh) thuộc các PBI sau.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính — Xem báo cáo tổng quan theo tháng

1. Người dùng chạm tab **Báo cáo** ở thanh điều hướng đáy → màn **Tổng quan Báo cáo** mở ra theo mockup `01`: khu đầu màn nền màu thương hiệu với tiêu đề **"Báo cáo"**; bên dưới là **segmented control** 4 lựa chọn **Ngày | Tuần | Tháng | Năm**, mặc định chọn **"Tháng"**.
2. Ngay dưới segmented control là **2 số tổng** của tháng hiện tại: **"Tổng thu"** (kèm chỉ báo mũi tên tăng) và **"Tổng chi"** (kèm chỉ báo mũi tên giảm), mỗi số hiển thị cỡ lớn trên nền màu thương hiệu.
3. Người dùng cuộn xuống thẻ **"Dòng tiền 6 tháng gần đây"**: chú giải **Thu** (teal) / **Chi** (coral) và **biểu đồ cột ghép đôi** — mỗi tháng gần nhất (kết thúc ở tháng hiện tại) là một nhóm 2 cột thu/chi, dưới trục có nhãn tháng (VD T4…T9).
4. Người dùng chạm vào một cột → hiện **số tiền chính xác** của cột đó; chạm ra ngoài thì ẩn đi.
5. Cuộn tiếp là thẻ **"Phân bổ chi tiêu theo danh mục"**: **vòng tròn (donut)** chia theo các danh mục chi nhiều nhất trong tháng, giữa vòng tròn ghi **"Tổng chi"** kèm số tiền; bên phải là danh sách chú giải: chấm màu, tên danh mục, **%** trên tổng chi, sắp giảm dần.
6. Người dùng chạm vào một lát cắt (hoặc dòng chú giải) → mở màn **Giao dịch** đã **lọc sẵn theo danh mục đó và khoảng thời gian của tháng đang chọn**.
7. Cuộn tới thẻ cuối **"Top danh mục chi tiêu"**: danh sách các danh mục chi nhiều nhất trong tháng — mỗi dòng có biểu tượng danh mục, tên, số tiền, và **thanh tiến độ** thể hiện tỉ lệ trên tổng chi của kỳ.
8. Người dùng chạm **"Năm"** trên segmented control → **toàn bộ** nội dung màn tính lại theo **năm nay**: 2 số tổng là tổng thu/chi cả năm, tiêu đề thẻ biểu đồ đổi thành **"Dòng tiền 6 năm gần đây"** (6 năm kết thúc ở năm nay), vòng tròn phân bổ và top danh mục cũng theo cả năm.

### Kịch bản chấp nhận

1. **Given** app đang mở **When** người dùng chạm tab **Báo cáo** **Then** màn **Tổng quan Báo cáo** hiển thị đúng bố cục mockup `01`: khu đầu màn màu thương hiệu có tiêu đề "Báo cáo" + segmented control 4 lựa chọn (mặc định **"Tháng"**) + 2 số tổng; ngay dưới khu đầu màn là hàng điều hướng **"Ngân sách"**, rồi tới 3 thẻ theo thứ tự: biểu đồ cột dòng tiền → phân bổ chi tiêu theo danh mục → top danh mục chi tiêu; màn **có** thanh điều hướng đáy với tab Báo cáo đang được chọn; **không** có nút biểu tượng lịch ở góc phải (để PBI sau).
2. **Given** màn Tổng quan đang mở ở kỳ **Tháng** **When** người dùng chọn **Tuần** (hoặc **Ngày**, **Năm**) **Then** **toàn bộ** nội dung tính lại theo kỳ mới: 2 số tổng, biểu đồ cột (6 tuần/6 ngày/6 năm gần nhất kết thúc ở kỳ hiện tại), vòng tròn phân bổ, danh sách top và khoảng thời gian dùng khi chạm để lọc giao dịch; tiêu đề thẻ biểu đồ đổi theo đơn vị thời gian tương ứng.
3. **Given** kỳ đang chọn có cả giao dịch Thu và Chi **When** xem 2 số tổng **Then** "Tổng thu" bằng **tổng tiền các giao dịch Thu** trong kỳ và "Tổng chi" bằng **tổng tiền các giao dịch Chi** trong kỳ; các giao dịch **chuyển khoản nội bộ** KHÔNG được cộng vào bất kỳ số nào trong hai số này.
4. **Given** kỳ đang chọn có dữ liệu **When** xem thẻ biểu đồ **Then** biểu đồ hiển thị **6 đơn vị thời gian liên tiếp gần nhất kết thúc ở kỳ đang chọn**, mỗi đơn vị có **2 cột** (thu màu teal, chi màu coral) và **nhãn đơn vị** ở dưới trục; đơn vị chưa có giao dịch vẫn hiển thị với cột giá trị 0.
5. **Given** biểu đồ đang hiển thị **When** người dùng chạm vào một cột **Then** màn hiển thị **số tiền chính xác** của cột đó (không điều hướng sang màn khác, không mở chi tiết giao dịch).
6. **Given** kỳ đang chọn có giao dịch Chi **When** xem thẻ phân bổ **Then** vòng tròn chia theo **tối đa 5 danh mục chi nhiều nhất** cộng thêm nhóm **"Khác"** gộp phần còn lại (chỉ xuất hiện khi còn danh mục ngoài top 5 hoặc khi có tiền chi không gắn danh mục); danh sách chú giải sắp **giảm dần theo số tiền**, mỗi dòng có chấm màu, tên danh mục và **% trên tổng chi**; tổng các % hiển thị bằng **100%**.
7. **Given** một danh mục chi có cả giao dịch ở **danh mục con** **When** xem phân bổ **Then** tiền của các danh mục con được **gộp vào danh mục cha** (mặc định xem theo danh mục cha), tên hiển thị là tên danh mục cha.
8. **Given** thẻ phân bổ đang hiển thị **When** người dùng chạm một lát cắt hoặc một dòng chú giải **Then** màn **Giao dịch** mở ra đã **lọc sẵn theo danh mục đó (bao gồm cả danh mục con của nó) và khoảng thời gian của kỳ đang chọn**; tổng số tiền của danh sách hiển thị **khớp 100%** với số tiền của danh mục đó trên thẻ phân bổ.
9. **Given** kỳ đang chọn có giao dịch Chi **When** xem thẻ "Top danh mục chi tiêu" **Then** danh sách hiển thị **tối đa 5 danh mục chi nhiều nhất** trong kỳ, mỗi dòng gồm biểu tượng danh mục, tên, **số tiền**, và **thanh tiến độ** thể hiện tỉ lệ số tiền đó trên tổng chi của kỳ; thứ tự giảm dần theo số tiền.
10. **Given** trong kỳ **không có bất kỳ giao dịch Thu/Chi nào** **When** mở màn Tổng quan **Then** 2 số tổng hiển thị **0** kèm đơn vị tiền tệ, và các thẻ biểu đồ/phân bổ/top hiển thị **trạng thái rỗng dễ hiểu** ("Chưa có giao dịch nào trong kỳ này") thay vì biểu đồ trống gây hiểu lầm là lỗi.
11. **Given** trong kỳ **chỉ có giao dịch Thu** (không có Chi) **When** xem màn **Then** "Tổng chi" bằng 0, biểu đồ vẫn vẽ đủ 6 đơn vị với cột chi bằng 0, và **riêng** thẻ phân bổ cùng thẻ top danh mục hiển thị **trạng thái rỗng** (phân bổ theo danh mục chỉ nói về chi tiêu).
12. **Given** người dùng vừa **thêm/sửa/xóa** một giao dịch ở màn Giao dịch **When** quay lại màn Tổng quan Báo cáo **Then** 2 số tổng, biểu đồ, phân bổ và top danh mục đều phản ánh **số liệu mới** ngay trong lần mở đó.
13. **Given** trong kỳ có giao dịch **chuyển khoản nội bộ** giữa hai ví **When** xem màn Tổng quan **Then** các giao dịch này **không** xuất hiện trong 2 số tổng, không có cột riêng trên biểu đồ, và không có dòng/lát cắt nào trong phân bổ theo danh mục.
14. **Given** app đang ở **English** (PBI 19) **When** mở màn Tổng quan Báo cáo **Then** toàn bộ nhãn tĩnh (tiêu đề màn, nhãn segmented control, "Tổng thu"/"Tổng chi", tiêu đề và chú giải các thẻ, nhãn "Tổng chi" giữa vòng tròn, trạng thái rỗng, nhãn đơn vị thời gian) hiển thị bằng tiếng Anh, **không** còn sót tiếng Việt; số tiền vẫn theo định dạng phân tách nghìn kèm đơn vị tiền tệ.
15. **Given** app đang ở **chế độ Tối** (PBI 18) **When** mở màn Tổng quan Báo cáo **Then** nền, chữ, thẻ và màu biểu đồ dùng đúng bộ màu của chế độ Tối, số tiền và nhãn vẫn đủ tương phản để đọc.
16. **Given** màn hình nhỏ và cỡ chữ lớn nhất **When** người dùng xem màn Tổng quan **Then** bố cục không vỡ, không cắt chữ, số tiền không tràn khỏi thẻ, và cuộn tới được hết 3 thẻ nội dung.
17. **Given** màn Tổng quan Báo cáo đang mở **When** người dùng chạm hàng **"Ngân sách"** ngay dưới khu đầu màn **Then** màn **Tổng quan Ngân sách** mở ra đúng như trước PBI này (kèm thanh điều hướng đáy), và khi quay lại thì màn Tổng quan Báo cáo vẫn giữ **kỳ đang chọn** trước đó.

### Trường hợp biên

- **Trong kỳ chỉ có giao dịch chuyển khoản nội bộ** → coi như kỳ **không có thu/chi**: 2 số tổng bằng 0 và các thẻ hiển thị trạng thái rỗng (transfer không phải thu/chi).
- **Kỳ chỉ có 1–5 danh mục chi** → vòng tròn **không** có nhóm "Khác"; các lát cắt chiếm trọn 100%.
- **Có tiền chi nhưng không gắn danh mục** (dữ liệu cũ) → phần tiền này gộp vào nhóm **"Khác"** để tổng phân bổ vẫn bằng tổng chi của kỳ.
- **Hai danh mục cùng số tiền** → thứ tự hiển thị ổn định (xếp theo tên) để lần mở sau không đổi chỗ.
- **Danh mục bị ẩn** (module Danh mục) → giao dịch cũ vẫn được tính vào phân bổ và vẫn hiển thị tên danh mục bình thường.
- **Kỳ Năm khi app mới dùng vài tháng** → biểu đồ vẫn hiển thị đủ 6 năm gần nhất, các năm chưa có dữ liệu là cột 0; 2 số tổng và phân bổ chỉ tính dữ liệu thực có.
- **Giao dịch có ngày trong tương lai nhưng nằm trong kỳ đang chọn** (VD giao dịch định kỳ đã ghi trước) → vẫn được tính vào kỳ đó vì kỳ được xác định theo **khoảng ngày**.
- **Giao dịch rơi đúng ngày đầu/cuối kỳ** → được tính vào kỳ đó (khoảng ngày **bao gồm cả hai đầu**); không có giao dịch nào bị tính hai lần ở hai kỳ liền kề.
- **Tuần** → tuần bắt đầu **Thứ Hai**, kết thúc Chủ Nhật; kỳ "Tuần" đang xem là tuần chứa **hôm nay**.
- **Số tiền rất lớn** (hàng tỉ) → hiển thị đúng định dạng phân tách nghìn, không tràn hay cắt chữ trong khu đầu màn, thẻ và nhãn biểu đồ.
- **Kỳ không có giao dịch nào ở một vài đơn vị trên biểu đồ nhưng các đơn vị khác có** → các đơn vị trống vẫn có nhãn và cột 0, biểu đồ không co giãn sai tỉ lệ.
- **Ví có tiền tệ khác tiền tệ mặc định** → xem mục "Giả định" (đa tiền tệ chưa thuộc đợt này).
- **Không có mạng / offline** → màn Tổng quan vẫn hiển thị đầy đủ vì toàn bộ số liệu tính từ dữ liệu lưu trên thiết bị.
- **Người dùng đổi kỳ liên tục** → màn không bị treo, không hiển thị số liệu của kỳ cũ lẫn kỳ mới.

## Yêu cầu chức năng

- **FR-001**: Tab **Báo cáo** PHẢI mở ra màn **Tổng quan Báo cáo** theo mockup `01` — đây là **màn cấp tab**, nằm trong app shell và **có** thanh điều hướng đáy với tab Báo cáo đang được chọn.
- **FR-002**: Khu đầu màn PHẢI có nền **màu thương hiệu**, tiêu đề **"Báo cáo"**, và **segmented control 4 lựa chọn Ngày | Tuần | Tháng | Năm** với lựa chọn đang chọn được làm nổi bật; mặc định khi mở màn là **"Tháng"**. Đợt này KHÔNG hiển thị nút biểu tượng lịch của mockup `01` (dành cho bộ lọc khoảng thời gian tuỳ chỉnh ở PBI sau — xem "Ngoài phạm vi" và "Quyết định đã chốt").
- **FR-003**: Chọn một lựa chọn trên segmented control PHẢI **tính lại toàn bộ** nội dung màn theo kỳ đó: 2 số tổng, biểu đồ cột, vòng tròn phân bổ, danh sách top danh mục, và khoảng thời gian dùng khi mở danh sách giao dịch đã lọc.
- **FR-004**: Màn PHẢI hiển thị **2 số tổng** của kỳ đang chọn: **"Tổng thu"** kèm chỉ báo mũi tên tăng và **"Tổng chi"** kèm chỉ báo mũi tên giảm, mỗi số cỡ lớn; cả hai PHẢI **loại trừ hoàn toàn** giao dịch chuyển khoản nội bộ.
- **FR-005**: Màn PHẢI có thẻ **biểu đồ cột ghép đôi** với tiêu đề nêu rõ **6 đơn vị thời gian gần đây** theo đơn vị của kỳ đang chọn (6 ngày / 6 tuần / 6 tháng / 6 năm) và **chú giải Thu (teal) – Chi (coral)**; mỗi đơn vị gồm **2 cột** (thu, chi) cùng **nhãn đơn vị** ở dưới trục.
- **FR-006**: Sáu đơn vị trên biểu đồ PHẢI là **6 đơn vị liên tiếp kết thúc ở kỳ đang chọn** (kỳ đang chọn là đơn vị cuối cùng); đơn vị không có giao dịch vẫn PHẢI hiển thị (cột giá trị 0) để trục thời gian liên tục.
- **FR-007**: Chạm vào một cột trên biểu đồ PHẢI hiển thị **số tiền chính xác** của cột đó và KHÔNG được điều hướng sang màn khác.
- **FR-008**: Màn PHẢI có thẻ **"Phân bổ chi tiêu theo danh mục"** gồm **vòng tròn (donut)** và **danh sách chú giải** (chấm màu, tên danh mục, **% trên tổng chi**), sắp xếp **giảm dần theo số tiền**; giữa vòng tròn PHẢI ghi nhãn **tổng chi** kèm số tiền của kỳ.
- **FR-009**: Vòng tròn PHẢI chia theo **tối đa 5 danh mục chi nhiều nhất** trong kỳ, phần còn lại (nếu có) gộp vào nhóm **"Khác"**; nhóm "Khác" **không** xuất hiện khi kỳ chỉ có từ 5 danh mục trở xuống. Tổng % hiển thị PHẢI bằng **100%** và tổng tiền các phần PHẢI bằng **tổng chi** của kỳ.
- **FR-010**: Phân bổ theo danh mục PHẢI **gộp theo danh mục cha**: tiền của mọi **danh mục con** được tính vào danh mục cha của nó; đợt này **không** có chế độ xem tách theo danh mục con.
- **FR-011**: Bộ màu của vòng tròn PHẢI là **bộ màu định tính riêng** (teal, teal đậm nhạt, hổ phách, xanh lam nhạt, xám) **không** dùng coral — coral chỉ dành cho ngữ cảnh chi tiêu/cảnh báo theo Design System; màu PHẢI gán **cố định theo thứ hạng** danh mục để lần mở sau không đổi màu.
- **FR-012**: Chạm vào một **lát cắt** hoặc một **dòng chú giải** PHẢI mở màn **Giao dịch** đã **lọc sẵn theo danh mục đó (bao gồm danh mục con) và khoảng thời gian của kỳ đang chọn**; danh sách hiển thị PHẢI khớp với con số của danh mục đó trên thẻ phân bổ.
- **FR-013**: Màn PHẢI có thẻ **"Top danh mục chi tiêu"** liệt kê **tối đa 5 danh mục chi nhiều nhất** trong kỳ, mỗi dòng gồm **biểu tượng danh mục**, **tên**, **số tiền** và **thanh tiến độ** thể hiện tỉ lệ trên tổng chi của kỳ; thứ tự **giảm dần** theo số tiền.
- **FR-014**: Khi kỳ đang chọn **không có giao dịch Thu/Chi nào**, màn PHẢI hiển thị **2 số tổng bằng 0** và **trạng thái rỗng** rõ ràng ở các thẻ nội dung thay vì biểu đồ trống.
- **FR-015**: Khi kỳ có giao dịch Thu nhưng **không có giao dịch Chi**, thẻ phân bổ và thẻ top danh mục PHẢI hiển thị **trạng thái rỗng** (hai thẻ này chỉ nói về chi tiêu) trong khi biểu đồ vẫn hiển thị bình thường.
- **FR-016**: Mọi số liệu trên màn (2 số tổng, cột biểu đồ, %, số tiền phân bổ, top danh mục) PHẢI được **tính lại tại thời điểm mở màn và tại thời điểm đổi kỳ** từ dữ liệu giao dịch hiện có, để giao dịch **thêm/sửa/xóa** sau đó được phản ánh đúng.
- **FR-017**: Màn Tổng quan PHẢI giữ **lối vào module Ngân sách** hiện có: một hàng điều hướng "Ngân sách" (biểu tượng, tên, dòng phụ mô tả, mũi tên) đặt **ngay dưới khu đầu màn, trước thẻ biểu đồ dòng tiền**; chạm vào hàng này PHẢI mở màn **Tổng quan Ngân sách** như trước PBI này.
- **FR-018**: Mọi **nhãn giao diện tĩnh** của màn (tiêu đề, nhãn segmented control, nhãn 2 số tổng, tiêu đề và chú giải các thẻ, nhãn giữa vòng tròn, nhãn đơn vị thời gian, trạng thái rỗng) PHẢI có bản dịch **Tiếng Việt / English** theo ngôn ngữ đang chọn (PBI 19); **số tiền** PHẢI theo định dạng phân tách nghìn kèm đơn vị tiền tệ.
- **FR-019**: Màn PHẢI hiển thị đúng bộ màu của **chế độ Sáng/Tối** đang chọn (PBI 18) — nền, chữ, thẻ và màu biểu đồ theo token của chế độ tương ứng, đảm bảo đủ tương phản.
- **FR-020**: Màn PHẢI hiển thị đúng thiết kế và **không vỡ bố cục** trên các kích thước màn hình, vùng an toàn và cỡ chữ khác nhau; nội dung dài PHẢI **cuộn được** tới hết thẻ cuối; số tiền PHẢI **không tràn/cắt chữ**.
- **FR-021**: Kỳ xem PHẢI được xác định theo **mốc dương lịch**: Ngày = một ngày; Tuần = tuần **bắt đầu Thứ Hai** chứa hôm nay; Tháng = tháng dương lịch; Năm = năm dương lịch. Khoảng thời gian của kỳ PHẢI **bao gồm cả ngày đầu và ngày cuối**; đợt này **không** hỗ trợ kỳ tài chính lệch ngày.
- **FR-022**: Giao dịch PHẢI được tính vào kỳ theo **ngày giao dịch**; giao dịch có ngày trong tương lai nhưng nằm trong kỳ đang chọn vẫn được tính.

## Tiêu chí thành công

- **SC-001**: Từ lúc chạm tab Báo cáo, người dùng thấy **tổng thu, tổng chi và biểu đồ dòng tiền** mà không cần chạm thêm chỗ nào (mặc định kỳ "Tháng").
- **SC-002**: Đối chiếu trực quan với `man-hinh-01-bao-cao-tong-quan.svg`: **100%** thành phần (khu đầu màn + tiêu đề + segmented control + 2 số tổng có chỉ báo mũi tên, hàng điều hướng "Ngân sách", thẻ biểu đồ với chú giải và 6 nhóm cột, thẻ phân bổ với vòng tròn có số tổng chi ở giữa + 5 dòng chú giải kèm %, thẻ top danh mục với các dòng có thanh tiến độ) hiển thị đúng vị trí và nội dung; **khác biệt đã chốt** so với mockup: không có nút biểu tượng lịch, có thêm hàng "Ngân sách".
- **SC-003**: Với một kỳ bất kỳ, **100%** số liệu hiển thị khớp dữ liệu giao dịch: 2 số tổng, tổng chi giữa vòng tròn, % từng danh mục và số tiền từng dòng top — sai lệch **0 đ** so với cộng tay từ sổ giao dịch.
- **SC-004**: **100%** giao dịch chuyển khoản nội bộ bị loại khỏi mọi con số của màn Tổng quan (2 số tổng, cột biểu đồ, phân bổ, top danh mục) — kiểm chứng trên dữ liệu có cả thu, chi và chuyển khoản.
- **SC-005**: Tổng các % trên vòng tròn phân bổ bằng **100%** và tổng tiền các lát cắt bằng **đúng** tổng chi của kỳ ở **100%** trường hợp thử (kể cả dữ liệu có danh mục con, có tiền chi không gắn danh mục).
- **SC-006**: Chạm một danh mục trên thẻ phân bổ → màn Giao dịch liệt kê **đúng cùng tập giao dịch** tạo nên số tiền của danh mục đó (0 sai lệch về số lượng và tổng tiền), đúng khoảng thời gian của kỳ đang chọn.
- **SC-007**: Chuyển đổi giữa 4 lựa chọn kỳ **10 lần liên tiếp** không có lần nào hiển thị sai kỳ hoặc treo màn; mỗi lần chuyển nội dung được cập nhật trong **dưới 1 giây** với dữ liệu vài năm giao dịch.
- **SC-008**: Thêm/sửa/xóa một giao dịch rồi mở lại màn Tổng quan → số liệu cập nhật đúng ngay lần mở đó, **100%** trường hợp thử.
- **SC-009**: Khi kỳ không có giao dịch, **100%** trường hợp hiển thị trạng thái rỗng kèm thông điệp dễ hiểu, **không** có biểu đồ trống hay màn hình trắng gây hiểu lầm là lỗi.
- **SC-010**: Khi app ở English, **0** nhãn tĩnh tiếng Việt còn sót trên màn Tổng quan Báo cáo.
- **SC-011**: Ở chế độ Tối, **100%** chữ và số trên màn đạt tương phản đọc được (kiểm tra bằng công cụ đo tương phản trên ảnh chụp màn hình).
- **SC-012**: Với cỡ chữ lớn nhất và màn hình nhỏ, màn Tổng quan không vỡ bố cục, không cắt chữ, cuộn tới hết thẻ cuối ở **100%** lần kiểm tra.
- **SC-013**: Người dùng trả lời đúng "tháng này tôi thu bao nhiêu, chi bao nhiêu, chi nhiều nhất vào việc gì" **ngay sau khi mở màn, không chạm gì thêm** — kiểm chứng bằng khảo sát nhỏ (5 người, 100% trả lời đúng).

## Thực thể chính

- **Kỳ báo cáo** (đại lượng **tính toán**, không phải dữ liệu người dùng nhập): đơn vị thời gian đang xem (Ngày/Tuần/Tháng/Năm) cùng **khoảng ngày tương ứng**, và 6 kỳ liền trước dùng cho biểu đồ dòng tiền. Kỳ đang xem quyết định toàn bộ số liệu hiển thị trên màn.
- **Giao dịch Thu/Chi** (liên kết tới module Giao dịch): nguồn của 2 số tổng và của biểu đồ dòng tiền; mỗi giao dịch đóng góp vào **một** kỳ duy nhất theo ngày giao dịch. Giao dịch **chuyển khoản nội bộ** bị loại khỏi mọi số liệu của màn này.
- **Phân bổ theo danh mục** (đại lượng **tính toán**): với kỳ đang xem, là danh sách các **danh mục cha** (đã gộp danh mục con) kèm số tiền chi và tỉ lệ % trên tổng chi, sắp giảm dần, kèm nhóm "Khác" cho phần ngoài top 5 và phần tiền chi không gắn danh mục.

## Giả định

- **2 số tổng và thẻ phân bổ tính cho "kỳ đang chọn", biểu đồ tính cho 6 kỳ gần nhất**: mockup `01` cho thấy "Tổng chi" ở khu đầu màn (12.300.000 đ) **trùng khớp** với số "Tổng chi" ghi giữa vòng tròn phân bổ, trong khi biểu đồ vẽ 6 tháng → kỳ đang chọn là đơn vị phân tích, còn biểu đồ là 6 đơn vị gần nhất kết thúc ở kỳ đó.
- **Số đơn vị trên biểu đồ = 6**, đúng mockup (T4…T9). Đợt này **không** có thao tác kéo/vuốt để xem thêm kỳ ngoài 6 đơn vị (doc nghiệp vụ §3.1 có nhắc "chạm giữ để kéo xem nhiều kỳ hơn" — để PBI sau).
- **Thẻ "Top danh mục chi tiêu" hiển thị tối đa 5 dòng**: mockup vẽ 3 dòng minh hoạ, doc nghiệp vụ §3.5 cho phép 3–5 dòng; chọn **5** cho nhất quán với top 5 của vòng tròn. Đợt này **không** có liên kết "Xem tất cả" trên thẻ này (mockup `01` không vẽ, và màn đích — Chi tiết theo Danh mục — thuộc PBI sau).
- **Vòng tròn mặc định gộp theo danh mục cha**: doc nghiệp vụ §3.2 có nhắc toggle "Xem theo danh mục con"; mockup `01` không vẽ toggle nên đợt này **không** làm.
- **Danh mục đã bị ẩn vẫn được tính và hiển thị tên bình thường**: ẩn chỉ loại khỏi chọn nhanh, không xóa lịch sử (nguyên tắc nghiệp vụ xuyên module).
- **Đa tiền tệ chưa thuộc đợt này**: doc nghiệp vụ §2.2 yêu cầu quy đổi theo tỷ giá tại thời điểm giao dịch, nhưng nguồn tỷ giá offline vẫn là **quyết định mở** chưa chốt. Đợt này màn Tổng quan cộng theo **số tiền ghi trên giao dịch** và giả định dữ liệu dùng **một tiền tệ mặc định**; nếu người dùng có ví tiền tệ khác thì số tổng có thể lệch — cần PBI riêng cho quy đổi tỷ giá.
- **Chế độ ẩn số dư chưa áp dụng cho màn này**: công tắc "Ẩn số dư" (PBI 17) hiện chưa có hiệu ứng thật ở bất kỳ màn nào; doc nghiệp vụ §8 có nhắc che số tiền khi bật — để PBI làm hiệu ứng công tắc.
- **Kỳ tài chính lệch ngày chưa thuộc đợt này**: doc nghiệp vụ §2.2 nhắc "đầu tháng tài chính" tuỳ chỉnh; màn con `04` của nhóm Tiện ích chưa dựng nên đợt này dùng mốc dương lịch, tuần bắt đầu Thứ Hai (kế thừa quy ước PBI 20/21).
- **Không có bảng tổng hợp lưu sẵn**: kế thừa cách làm PBI 20/21 — mọi số liệu tính lại khi mở màn/đổi kỳ từ dữ liệu giao dịch, không lưu bản ghi tổng hợp (doc nghiệp vụ §2.2 và §7 đề xuất bảng tổng hợp + cache; đó là tối ưu kỹ thuật, sẽ cân nhắc khi đo thấy chậm — SC-007 đặt ngưỡng dưới 1 giây).
- **Màn Tổng quan không tự cập nhật khi dữ liệu đổi trong lúc màn đang mở** (không có thông báo đẩy/lắng nghe liên tục): số liệu đúng tại thời điểm mở màn hoặc đổi kỳ; quay lại màn là thấy số mới.
- **Chạm danh mục mở màn Giao dịch với bộ lọc điền sẵn**: màn Giao dịch hiện đã cho mở kèm bộ lọc điền sẵn và lọc danh mục đã gộp danh mục con (PBI 12/21); nếu thiếu phần nào thì bổ sung, nếu không hai màn sẽ lệch số — SC-006 chốt ràng buộc khớp.
- **Khoá app (PIN) không ảnh hưởng màn này**: màn Báo cáo nằm trong app shell, chỉ hiển thị sau khi đã mở khóa app (PBI 3).

## Ngoài phạm vi

- **3 màn còn lại của module Báo cáo**: Chi tiết theo Danh mục (mockup `02`), So sánh Kỳ (`03`), Xuất Báo cáo PDF/Excel/CSV (`04`) — thuộc PBI sau.
- **Bộ lọc báo cáo nâng cao**: chọn khoảng thời gian tuỳ chỉnh (**tức nút biểu tượng lịch của mockup `01`** — đợt này không hiển thị), lọc theo **ví**, theo **danh mục**, theo **tag**, và việc ghi nhớ bộ lọc khi chuyển giữa các tab báo cáo (doc nghiệp vụ §3.8).
- **Biểu đồ xu hướng (line chart) và đường trung bình động**, chế độ tab phụ "Xu hướng" (doc nghiệp vụ §3.4).
- **Báo cáo dòng tiền theo từng ví** (số dư đầu kỳ/cuối kỳ, chuyển vào/chuyển ra) — doc nghiệp vụ §3.6.
- **Insight tự động bằng ngôn ngữ tự nhiên** và việc tái sử dụng nó cho thông báo cuối tuần/cuối tháng (doc nghiệp vụ §3.3).
- **Toggle "Xem theo danh mục con"** trên thẻ phân bổ; **liên kết "Xem tất cả"** trên thẻ top danh mục.
- **Kéo/vuốt biểu đồ để xem thêm kỳ ngoài 6 đơn vị**.
- **Đa tiền tệ và quy đổi tỷ giá**; **kỳ tài chính lệch ngày**.
- **Hiệu ứng của công tắc "Ẩn số dư"** (PBI 17) đối với số tiền trên màn Báo cáo.
- **Bảng tổng hợp/cache số liệu báo cáo** và **tính toán nền** cho dữ liệu nhiều năm.

## Quyết định đã chốt

- **Lối vào "Ngân sách" giữ trong tab Báo cáo** — hàng điều hướng "Ngân sách" nằm **ngay dưới khu đầu màn, trước thẻ biểu đồ dòng tiền** (mockup `01` không vẽ hàng này, nhưng chuyển nó sang Cài đặt sẽ lệch quyết định PBI 20 và làm ngân sách khó tìm hơn). (chốt 2026-09-12)
- **Nút biểu tượng lịch (khoảng thời gian tuỳ chỉnh) để PBI sau** — đợt này màn Tổng quan chỉ có 4 lựa chọn kỳ trên segmented control; nút lịch không hiển thị. (chốt 2026-09-12)
- **Chạm danh mục trên thẻ phân bổ mở màn Giao dịch đã lọc sẵn** trong đợt này (danh mục gồm cả danh mục con + khoảng thời gian của kỳ đang chọn) — tận dụng khả năng lọc sẵn đã có ở màn Giao dịch. (chốt 2026-09-12)
