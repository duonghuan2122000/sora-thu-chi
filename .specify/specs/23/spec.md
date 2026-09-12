# Đặc tả tính năng: Chi tiết theo danh mục (màn 02 Báo cáo)

**Mã PBI**: 23
**Ngày tạo**: 2026-09-12
**Trạng thái**: Đã làm rõ

## Mô tả tổng quan

Màn **Tổng quan Báo cáo** (PBI 22) chỉ hiển thị **top 5** danh mục chi tiêu — người dùng muốn biết "tháng này mình chi những gì, mỗi thứ bao nhiêu" vẫn phải tự đoán phần còn lại. PBI này dựng **màn Chi tiết theo danh mục** theo mockup `docs/report/man-hinh-02-chi-tiet-danh-muc.svg`, mở từ liên kết **"Xem tất cả"** trên thẻ top danh mục: kế thừa **kỳ đang xem**, hiển thị **vòng tròn phân bổ** với **tổng chi ở giữa**, và **danh sách đầy đủ** các danh mục chi tiêu của kỳ (chấm màu, tên, số tiền, %, thanh tiến độ), chạm một danh mục để xem các giao dịch tạo nên số tiền đó.

Đợt này chỉ làm **màn con `02`** — trang đẩy từ màn Tổng quan, có app bar màu thương hiệu + nút back, **không** có thanh điều hướng đáy. Hai màn còn lại của module Báo cáo (So sánh Kỳ, Xuất Báo cáo) thuộc PBI sau.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính — Xem chi tiết chi tiêu theo danh mục của một kỳ

1. Người dùng đang ở **màn Tổng quan Báo cáo** với kỳ **Tháng** → thẻ **"Top danh mục chi tiêu"** hiển thị 5 danh mục chi nhiều nhất, có liên kết **"Xem tất cả"**.
2. Người dùng chạm **"Xem tất cả"** → màn **Chi tiết theo danh mục** mở ra theo mockup `02`: app bar teal có nút back và tiêu đề **"Chi tiêu theo danh mục"**, bên dưới là **chip kỳ** ghi **"Tháng 9/2026"**, rồi **vòng tròn phân bổ** với nhãn giữa vòng ghi **"Tổng chi tháng"** và số tiền **12.300.000 đ**.
3. Cuộn xuống: tiêu đề nhóm **"DANH MỤC (6)"** và **6 dòng danh mục** sắp giảm dần theo số tiền — mỗi dòng gồm **chấm màu**, **tên danh mục**, **số tiền** (căn phải), **%** trên tổng chi (căn phải, dưới số tiền) và **thanh tiến độ** chạy dưới tên; màu chấm và thanh tiến độ **trùng màu lát cắt** tương ứng trên vòng tròn.
4. Cuối danh sách có dòng gợi ý **"Chạm vào một danh mục để xem các giao dịch"**.
5. Người dùng chạm dòng **"Ăn uống"** (3.940.000 đ, 32%) → màn **Giao dịch** mở ra đã **lọc sẵn theo danh mục Ăn uống (kể cả danh mục con) trong đúng khoảng thời gian của tháng đang xem**; tổng tiền danh sách khớp 3.940.000 đ.
6. Người dùng chạm nút **back** ở app bar → quay về **màn Tổng quan Báo cáo**, vẫn ở kỳ **Tháng** như trước.

### Kịch bản chấp nhận

1. **Given** màn Tổng quan Báo cáo đang mở ở kỳ **Tháng 9/2026** **When** người dùng chạm liên kết **"Xem tất cả"** trên thẻ "Top danh mục chi tiêu" **Then** màn **Chi tiết theo danh mục** mở ra đúng bố cục mockup `02`: app bar màu thương hiệu có nút back + tiêu đề "Chi tiêu theo danh mục"; **không** có thanh điều hướng đáy; nội dung gồm chip kỳ → vòng tròn phân bổ (có tổng chi ở giữa) → tiêu đề nhóm "DANH MỤC (n)" → danh sách danh mục → dòng gợi ý chạm.
2. **Given** màn Chi tiết theo danh mục đang mở **When** người dùng chạm nút **back** **Then** quay về màn Tổng quan Báo cáo và màn Tổng quan **giữ nguyên kỳ đang chọn** trước đó (việc xem chi tiết không làm đổi kỳ của màn Tổng quan).
3. **Given** kỳ đang xem có giao dịch Chi **When** mở màn Chi tiết **Then** chip kỳ ghi rõ **loại kỳ + mốc kỳ** đang xem (VD "Tháng 9/2026", "Tuần 07/09–13/09/2026", "Năm 2026", "Ngày 12/09/2026") và nhãn giữa vòng tròn ghi **"Tổng chi"** kèm **đơn vị kỳ** (VD "Tổng chi tháng") cùng **tổng số tiền chi** của kỳ đó; chip **không phản hồi khi chạm** (muốn xem kỳ khác thì đổi kỳ ở màn Tổng quan).
4. **Given** kỳ đang xem có giao dịch Chi **When** xem danh sách **Then** danh sách liệt kê **mọi danh mục có chi tiêu trong kỳ**, sắp **giảm dần theo số tiền**, mỗi dòng có **chấm màu**, **tên danh mục**, **số tiền**, **%** trên tổng chi, và **thanh tiến độ** thể hiện đúng % đó; tiêu đề nhóm ghi **"DANH MỤC (n)"** với **n = số dòng**.
5. **Given** danh sách đang hiển thị **When** so màu từng dòng với vòng tròn **Then** **chấm màu và thanh tiến độ** của mỗi dòng **trùng màu lát cắt** của chính danh mục đó trên vòng tròn; màu **gán cố định theo thứ hạng** nên mở lại màn không đổi màu; **không** dùng màu coral cho bất kỳ danh mục nào.
6. **Given** danh sách đang hiển thị **When** cộng các **%** của mọi dòng **Then** tổng bằng **100%**; tổng **số tiền** các dòng bằng **đúng tổng chi** của kỳ ghi giữa vòng tròn.
7. **Given** một danh mục có cả giao dịch ở **danh mục con** **When** xem danh sách **Then** tiền của các danh mục con được **gộp vào danh mục cha**, tên hiển thị là tên danh mục cha (cùng cách gộp với màn Tổng quan).
8. **Given** danh sách đang hiển thị **When** người dùng chạm một dòng danh mục **Then** màn **Giao dịch** mở ra đã lọc sẵn theo **danh mục đó (bao gồm danh mục con) trong đúng khoảng thời gian của kỳ đang xem**; số lượng và tổng tiền giao dịch trong danh sách **khớp 0 sai lệch** với số tiền của dòng vừa chạm.
9. **Given** trong kỳ có **tiền chi không gắn danh mục** **When** xem danh sách **Then** khoản tiền này nằm ở dòng **"Khác"**, và dòng "Khác" **không phản hồi khi chạm** (không có danh sách giao dịch để mở).
10. **Given** kỳ đang xem **không có giao dịch Thu/Chi nào** **When** mở màn Chi tiết **Then** màn hiển thị **trạng thái rỗng** với thông điệp "Chưa có giao dịch nào trong kỳ này" — **không** vẽ vòng tròn rỗng, không hiện tiêu đề nhóm rỗng gây hiểu lầm là lỗi.
11. **Given** kỳ đang xem **chỉ có giao dịch Thu** (không có Chi) **When** mở màn Chi tiết **Then** màn hiển thị **trạng thái rỗng** với thông điệp "Chưa có chi tiêu nào trong kỳ này" (màn này chỉ nói về chi tiêu) và **không** hiển thị vòng tròn/danh sách.
12. **Given** kỳ đang xem **chỉ có giao dịch chuyển khoản nội bộ** **When** mở màn Chi tiết **Then** màn hiển thị **trạng thái rỗng** như kỳ không có giao dịch (chuyển khoản không phải thu/chi).
13. **Given** người dùng vừa **thêm/sửa/xóa** một giao dịch ở màn Giao dịch **When** mở lại màn Chi tiết **Then** tổng chi, vòng tròn, danh sách, số tiền và % đều phản ánh **số liệu mới** ngay lần mở đó.
14. **Given** app đang ở **English** (PBI 19) **When** mở màn Chi tiết **Then** toàn bộ nhãn tĩnh (tiêu đề app bar, nhãn chip kỳ, nhãn "Tổng chi" giữa vòng, tiêu đề nhóm "DANH MỤC", "Khác", dòng gợi ý, thông điệp rỗng) hiển thị bằng tiếng Anh, **không** còn sót tiếng Việt; số tiền vẫn theo định dạng phân tách nghìn kèm đơn vị tiền tệ.
15. **Given** app đang ở **chế độ Tối** (PBI 18) **When** mở màn Chi tiết **Then** nền, chữ, app bar, màu vòng tròn, thanh tiến độ và đường phân cách dùng đúng bộ màu của chế độ Tối, chữ và số vẫn đủ tương phản để đọc.
16. **Given** màn hình nhỏ và cỡ chữ lớn nhất **When** xem màn Chi tiết **Then** bố cục không vỡ, tên danh mục dài được cắt gọn chứ không đẩy số tiền ra ngoài, số tiền không tràn khỏi dòng, và cuộn tới được dòng cuối cùng của danh sách.
17. **Given** màn Chi tiết theo danh mục đang mở **When** người dùng chạm danh mục để sang màn Giao dịch rồi quay lại **Then** màn Chi tiết vẫn hiển thị **đúng kỳ đang xem** và số liệu **không đổi** so với trước khi rời màn (trừ khi dữ liệu giao dịch đã thay đổi).
18. **Given** kỳ đang xem có **nhiều danh mục chi hơn số màu của bảng màu** **When** xem vòng tròn và danh sách **Then** **mọi** danh mục đều có **lát cắt riêng** và **dòng riêng** (không danh mục nào bị gộp lại), màu **lặp lại theo chu kỳ** ở các hạng vượt quá bảng màu, và dòng "Khác" **không** xuất hiện vì mọi khoản chi đều đã gắn danh mục.

### Trường hợp biên

- **Kỳ chỉ có 1 danh mục chi** → vòng tròn là một vòng tròn khép kín một màu, danh sách có 1 dòng với **100%**; màn vẫn hiển thị bình thường (không coi là lỗi).
- **Có tiền chi không gắn danh mục** (dữ liệu cũ) → gộp vào dòng **"Khác"** để tổng danh sách vẫn bằng tổng chi của kỳ; dòng này không chạm được.
- **Danh mục bị ẩn** (module Danh mục) → giao dịch cũ vẫn được tính và tên danh mục vẫn hiển thị bình thường.
- **Danh mục con trỏ tới cha không còn tồn tại** → nhóm theo chính nó (không dồn vào "Khác"), giống màn Tổng quan.
- **Hai danh mục cùng số tiền** → thứ tự ổn định (xếp theo tên) để mở lại màn không đổi chỗ; màu theo thứ hạng cũng không đổi.
- **Số tiền rất lớn** (hàng tỉ) → hiển thị đúng định dạng phân tách nghìn, không tràn hay cắt chữ trong dòng danh sách và ở giữa vòng tròn.
- **Tên danh mục rất dài** → cắt gọn bằng dấu ba chấm, số tiền và % vẫn hiển thị đủ, không bị đẩy khỏi màn hình.
- **Kỳ đang xem là Ngày/Tuần/Năm** → màn dùng đúng khoảng thời gian của kỳ đó khi lọc giao dịch, nhãn chip kỳ và nhãn giữa vòng tròn đổi theo đơn vị kỳ tương ứng.
- **Giao dịch rơi đúng ngày đầu/cuối kỳ** → được tính vào kỳ đó (khoảng thời gian bao gồm cả hai đầu); không giao dịch nào bị tính hai lần ở hai kỳ liền kề.
- **Giao dịch có ngày trong tương lai nhưng nằm trong kỳ đang xem** → vẫn được tính.
- **Không có mạng / offline** → màn hiển thị đầy đủ vì toàn bộ số liệu tính từ dữ liệu lưu trên thiết bị.
- **Số danh mục chi trong kỳ nhiều hơn số màu của bảng màu** → mọi danh mục vẫn có lát cắt và dòng riêng, màu **lặp lại theo chu kỳ**; các danh mục trùng màu phân biệt với nhau bằng **tên** và **thứ tự** trong danh sách.
- **Ví có tiền tệ khác tiền tệ mặc định** → xem mục "Giả định" (đa tiền tệ chưa thuộc đợt này).

## Yêu cầu chức năng

- **FR-001**: Màn **Tổng quan Báo cáo** PHẢI có liên kết **"Xem tất cả"** trên thẻ **"Top danh mục chi tiêu"**; chạm liên kết này PHẢI mở màn **Chi tiết theo danh mục** mang theo **kỳ đang xem** (loại kỳ + mốc kỳ) của màn Tổng quan.
- **FR-002**: Màn Chi tiết theo danh mục PHẢI là **trang con** theo mockup `02`: app bar **màu thương hiệu** có **nút back** và tiêu đề **"Chi tiêu theo danh mục"**; **không** có thanh điều hướng đáy.
- **FR-003**: Màn PHẢI hiển thị **chip kỳ** ngay dưới app bar, ghi rõ **kỳ đang xem**; nội dung chip PHẢI nêu được **loại kỳ và mốc kỳ** đủ để người dùng biết mình đang xem khoảng thời gian nào. Chip là **nhãn tĩnh** kế thừa từ màn Tổng quan: **KHÔNG** bấm được, **KHÔNG** hiển thị mũi tên/menu chọn kỳ (khác mockup — xem "Quyết định đã chốt"); muốn xem kỳ khác thì đổi kỳ ở màn Tổng quan rồi mở lại.
- **FR-004**: Màn PHẢI hiển thị **vòng tròn phân bổ chi tiêu** của kỳ đang xem — chia theo **mọi danh mục có chi tiêu trong kỳ** — có **nhãn ở giữa vòng tròn** gồm chữ **"Tổng chi"** kèm **đơn vị kỳ** (tháng/tuần/ngày/năm) và **tổng số tiền chi** của kỳ.
- **FR-005**: Dưới vòng tròn PHẢI có **tiêu đề nhóm danh mục** ghi **"DANH MỤC (n)"** với **n = số dòng** đang liệt kê (số danh mục có chi tiêu, cộng thêm dòng "Khác" nếu có).
- **FR-006**: Màn PHẢI liệt kê **mọi danh mục có chi tiêu trong kỳ** (không giới hạn 5 dòng như thẻ trên màn Tổng quan), sắp xếp **giảm dần theo số tiền**; mỗi dòng PHẢI gồm **chấm màu**, **tên danh mục**, **số tiền**, **% trên tổng chi** và **thanh tiến độ** thể hiện đúng % đó.
- **FR-007**: **Màu** của chấm và thanh tiến độ mỗi dòng PHẢI **trùng màu lát cắt** của chính danh mục đó trên vòng tròn, lấy từ **bộ màu định tính riêng** và **gán cố định theo thứ hạng**; khi kỳ có **nhiều hơn số màu của bảng màu**, màu **lặp lại theo chu kỳ** ở các hạng tiếp theo (tên danh mục là thứ phân biệt). **Không** dùng màu coral (coral chỉ dành cho ngữ cảnh chi tiêu/cảnh báo theo Design System) và không dùng màu riêng của danh mục.
- **FR-008**: **%** mỗi dòng PHẢI tính trên **tổng chi của kỳ**; tổng các % hiển thị PHẢI bằng **100%** và tổng số tiền các dòng PHẢI bằng **đúng tổng chi** của kỳ.
- **FR-009**: Phân bổ và danh sách PHẢI **gộp theo danh mục cha**: tiền của mọi **danh mục con** được tính vào danh mục cha; đợt này **không** có chế độ xem tách theo danh mục con.
- **FR-010**: Tiền chi **không gắn danh mục** PHẢI được gộp vào **một dòng "Khác"** (xếp cuối danh sách, có lát cắt riêng trên vòng tròn, dùng màu xám của bảng màu) để tổng danh sách luôn bằng tổng chi của kỳ. Dòng "Khác" **chỉ** đại diện cho phần tiền chi không gắn danh mục — mọi danh mục có chi tiêu đều có dòng riêng, **không** bị gộp vào "Khác".
- **FR-011**: Chạm một **dòng danh mục** PHẢI mở màn **Giao dịch** đã **lọc sẵn theo danh mục đó (bao gồm danh mục con) và khoảng thời gian của kỳ đang xem**; danh sách hiển thị PHẢI khớp **0 sai lệch** về số lượng và tổng tiền với số tiền của dòng vừa chạm.
- **FR-012**: Dòng **"Khác"** (và mọi dòng không gắn với một danh mục thật) **KHÔNG** được phản hồi khi chạm, vì không có danh mục để lọc.
- **FR-013**: Khi kỳ đang xem **không có giao dịch Thu/Chi nào** (kể cả kỳ chỉ có chuyển khoản nội bộ), màn PHẢI hiển thị **trạng thái rỗng** "Chưa có giao dịch nào trong kỳ này" thay vì vòng tròn rỗng/tiêu đề nhóm rỗng.
- **FR-014**: Khi kỳ đang xem **chỉ có giao dịch Thu**, màn PHẢI hiển thị **trạng thái rỗng** "Chưa có chi tiêu nào trong kỳ này".
- **FR-015**: Mọi số liệu trên màn (tổng chi, vòng tròn, danh sách, số tiền, %) PHẢI được **tính lại tại thời điểm mở màn** từ dữ liệu giao dịch hiện có, để giao dịch **thêm/sửa/xóa** sau đó được phản ánh đúng.
- **FR-016**: Kỳ đang xem PHẢI dùng **cùng quy ước** với màn Tổng quan: Ngày = một ngày; Tuần = tuần **bắt đầu Thứ Hai** chứa hôm nay; Tháng = tháng dương lịch; Năm = năm dương lịch; khoảng thời gian **bao gồm cả ngày đầu và ngày cuối**. Giao dịch được tính vào kỳ theo **ngày giao dịch**.
- **FR-017**: Quay về từ màn Chi tiết PHẢI **không làm đổi kỳ đang chọn** của màn Tổng quan.
- **FR-018**: Mọi **nhãn giao diện tĩnh** của màn (tiêu đề, nhãn chip kỳ, nhãn giữa vòng tròn, tiêu đề nhóm, "Khác", dòng gợi ý, thông điệp rỗng) PHẢI có bản dịch **Tiếng Việt / English** theo ngôn ngữ đang chọn (PBI 19); **số tiền** PHẢI theo định dạng phân tách nghìn kèm đơn vị tiền tệ.
- **FR-019**: Màn PHẢI hiển thị đúng bộ màu của **chế độ Sáng/Tối** đang chọn (PBI 18) — nền, chữ, app bar, màu vòng tròn và thanh tiến độ theo token của chế độ tương ứng, đảm bảo đủ tương phản.
- **FR-020**: Màn PHẢI hiển thị đúng thiết kế và **không vỡ bố cục** trên các kích thước màn hình, vùng an toàn và cỡ chữ khác nhau; danh sách PHẢI **cuộn được** tới dòng cuối; tên dài PHẢI **cắt gọn** và số tiền **không tràn/cắt chữ**.

## Tiêu chí thành công

- **SC-001**: Đối chiếu trực quan với `man-hinh-02-chi-tiet-danh-muc.svg`: **100%** thành phần (app bar teal + back + tiêu đề, chip kỳ, vòng tròn có nhãn tổng chi ở giữa, tiêu đề nhóm "DANH MỤC (n)", các dòng danh mục có chấm màu + tên + số tiền + % + thanh tiến độ, dòng gợi ý) hiển thị đúng vị trí và nội dung; **đầy đủ** các dòng danh mục của kỳ, không cắt còn 5 dòng như màn Tổng quan; **khác biệt đã chốt** so với mockup: chip kỳ là **nhãn tĩnh** (không có mũi tên/menu chọn kỳ).
- **SC-002**: Từ màn Tổng quan, người dùng tới được màn Chi tiết bằng **đúng 1 lần chạm** ("Xem tất cả") và quay lại bằng **1 lần chạm** (back).
- **SC-003**: Với một kỳ bất kỳ, **100%** số liệu hiển thị khớp dữ liệu giao dịch: tổng chi giữa vòng tròn, số tiền và % từng dòng — sai lệch **0 đ** so với cộng tay từ sổ giao dịch.
- **SC-004**: Tổng các **%** trên danh sách bằng **100%** và tổng tiền các dòng bằng **đúng** tổng chi của kỳ ở **100%** trường hợp thử (kể cả dữ liệu có danh mục con, có tiền chi không gắn danh mục, chỉ có 1 danh mục).
- **SC-005**: **100%** giao dịch chuyển khoản nội bộ bị loại khỏi mọi con số của màn Chi tiết — kiểm chứng trên dữ liệu có cả thu, chi và chuyển khoản.
- **SC-006**: Chạm một dòng danh mục → màn Giao dịch liệt kê **đúng cùng tập giao dịch** tạo nên số tiền của dòng đó (0 sai lệch về số lượng và tổng tiền), đúng khoảng thời gian của kỳ đang xem.
- **SC-007**: Màu chấm/thanh tiến độ của mỗi danh mục **trùng khớp** màu lát cắt của nó trên vòng tròn ở **100%** dòng; mở lại màn nhiều lần không đổi màu.
- **SC-008**: Mở màn với dữ liệu vài năm giao dịch: nội dung hiển thị trong **dưới 1 giây**; số danh mục của kỳ hiển thị **đầy đủ**, không bị cắt bớt.
- **SC-009**: Thêm/sửa/xóa một giao dịch rồi mở lại màn Chi tiết → số liệu cập nhật đúng ngay lần mở đó, **100%** trường hợp thử.
- **SC-010**: Khi kỳ không có chi tiêu, **100%** trường hợp hiển thị trạng thái rỗng kèm thông điệp dễ hiểu, **không** có vòng tròn rỗng hay màn hình trắng gây hiểu lầm là lỗi.
- **SC-011**: Khi app ở English, **0** nhãn tĩnh tiếng Việt còn sót trên màn Chi tiết.
- **SC-012**: Ở chế độ Tối, **100%** chữ và số trên màn đạt tương phản đọc được (kiểm tra bằng công cụ đo tương phản trên ảnh chụp màn hình).
- **SC-013**: Với cỡ chữ lớn nhất và màn hình nhỏ, màn Chi tiết không vỡ bố cục, không cắt chữ, cuộn tới hết dòng cuối ở **100%** lần kiểm tra.
- **SC-014**: Kỳ có **hơn 6 danh mục chi**: danh sách hiển thị **đủ** mọi danh mục (0 danh mục bị gộp hay bỏ sót ngoài phần tiền chi không gắn danh mục), mỗi danh mục có dòng riêng và lát cắt riêng; thứ tự **giảm dần** đúng và tổng % vẫn bằng **100%**.

## Thực thể chính

- **Kỳ báo cáo** (đại lượng **tính toán**): loại kỳ (Ngày/Tuần/Tháng/Năm) + mốc kỳ đang xem, kế thừa từ màn Tổng quan khi mở màn Chi tiết; quyết định khoảng thời gian dùng cho mọi số liệu và cho bộ lọc khi chạm một danh mục.
- **Phân bổ theo danh mục** (đại lượng **tính toán**): với kỳ đang xem, là danh sách **mọi danh mục cha** có chi tiêu (đã gộp danh mục con) kèm số tiền và % trên tổng chi, sắp giảm dần, cộng một dòng **"Khác"** cho phần tiền chi không gắn danh mục. Mỗi phần tử gắn một **màu định tính theo thứ hạng**.
- **Giao dịch Chi** (liên kết tới module Giao dịch): nguồn của mọi con số trên màn; mỗi giao dịch đóng góp vào đúng một danh mục cha. Giao dịch **chuyển khoản nội bộ** bị loại khỏi mọi số liệu.

## Giả định

- **Lối vào duy nhất là liên kết "Xem tất cả" trên thẻ "Top danh mục chi tiêu"** của màn Tổng quan — doc nghiệp vụ §3.5 nêu đúng lối này ("Xem tất cả" → màn Chi tiết theo danh mục); mockup `01` không vẽ liên kết nên PBI 22 đã để lại, đợt này bổ sung.
- **Danh sách trên màn Chi tiết không giới hạn số dòng** — doc nghiệp vụ §3.5: "liệt kê đầy đủ, không giới hạn 5 dòng"; đây là khác biệt chính so với thẻ top trên màn Tổng quan. **Vòng tròn cũng chia đủ mọi danh mục** (không cắt ở top 5 + "Khác"), và khi vượt quá số màu của bảng màu thì màu **lặp lại theo chu kỳ** — hệ quả đã chấp nhận: hai danh mục khác hạng có thể trùng màu, phân biệt bằng tên (đã chốt 2026-09-12).
- **Chip kỳ là nhãn tĩnh** — kế thừa kỳ từ màn Tổng quan, không đổi kỳ được tại màn này (đã chốt 2026-09-12); mockup `02` có vẽ mũi tên xuống nhưng đợt này không hiển thị.
- **Chấm màu của mỗi dòng là màu định tính theo thứ hạng (trùng màu lát cắt), không phải màu riêng của danh mục** — mockup `02` vẽ chấm màu trùng đúng bộ màu lát cắt và thanh tiến độ cùng màu (khác thẻ top ở màn `01`, nơi bubble dùng màu của danh mục).
- **Dòng gợi ý ở cuối màn** ("Chạm vào một danh mục để xem các giao dịch") là chữ tĩnh, không phải nút.
- **Màn Chi tiết không ghi ngược trạng thái về màn Tổng quan**: kỳ đang chọn của màn Tổng quan vẫn là kỳ lúc rời màn (giống nếp PBI 22 khi sang màn Ngân sách).
- **Màu và thứ tự gán theo thứ hạng** (danh mục chi nhiều nhất = màu đầu bảng) để mở lại màn không đổi màu; đồng hạng xếp theo tên như màn Tổng quan.
- **Danh mục đã bị ẩn vẫn được tính và hiển thị tên bình thường**: ẩn chỉ loại khỏi chọn nhanh, không xóa lịch sử (nguyên tắc nghiệp vụ xuyên module).
- **Số liệu tính lại khi mở màn, không có cập nhật đẩy**: màn không tự đổi số khi dữ liệu thay đổi ở nơi khác trong lúc màn đang mở (kế thừa hành vi PBI 22).
- **Chạm danh mục mở màn Giao dịch với bộ lọc điền sẵn**: màn Giao dịch đã cho mở kèm bộ lọc điền sẵn và lọc danh mục bao gồm danh mục con (PBI 12/21/22); ràng buộc khớp số được chốt ở FR-011/SC-006.
- **Đa tiền tệ chưa thuộc đợt này**: doc nghiệp vụ §2.2 yêu cầu quy đổi theo tỷ giá tại thời điểm giao dịch, nhưng nguồn tỷ giá offline vẫn là quyết định mở. Đợt này cộng theo **số tiền ghi trên giao dịch** và giả định dữ liệu dùng **một tiền tệ mặc định**.
- **Kỳ tài chính lệch ngày chưa thuộc đợt này**: dùng mốc dương lịch, tuần bắt đầu Thứ Hai (kế thừa PBI 20/21/22).
- **Công tắc "Ẩn số dư" (PBI 17) chưa áp dụng**: chưa có hiệu ứng che số tiền ở bất kỳ màn nào.
- **Không có bảng tổng hợp/cache số liệu**: kế thừa PBI 22 — mọi số liệu tính lại từ dữ liệu giao dịch khi mở màn (ngưỡng đo được ở SC-008).
- **Khoá app (PIN) không ảnh hưởng màn này**: màn Chi tiết chỉ mở được sau khi đã mở khóa app (PBI 3) và nằm trong luồng của tab Báo cáo.

## Ngoài phạm vi

- **Toggle "Xem theo danh mục con"** (doc nghiệp vụ §3.2): mockup `02` không vẽ; đợt này danh sách và vòng tròn luôn gộp theo danh mục cha.
- **2 màn còn lại của module Báo cáo**: So sánh Kỳ (mockup `03`), Xuất Báo cáo PDF/Excel/CSV (mockup `04`).
- **Bộ lọc báo cáo nâng cao**: khoảng thời gian tuỳ chỉnh, lọc theo **ví**, theo **tag**, và việc ghi nhớ bộ lọc giữa các màn báo cáo (doc nghiệp vụ §3.8).
- **Biểu đồ xu hướng (line chart) và đường trung bình động** (doc nghiệp vụ §3.4).
- **Báo cáo dòng tiền theo từng ví** (doc nghiệp vụ §3.6).
- **Insight tự động bằng ngôn ngữ tự nhiên** (doc nghiệp vụ §3.3).
- **Đa tiền tệ và quy đổi tỷ giá**; **kỳ tài chính lệch ngày**; **hiệu ứng công tắc "Ẩn số dư"**.
- **Bảng tổng hợp/cache số liệu báo cáo** và tính toán nền cho dữ liệu nhiều năm.

## Quyết định đã chốt

- **Vòng tròn và danh sách đều liệt kê đầy đủ mọi danh mục chi của kỳ**, không cắt ở top 5 + "Khác"; màu định tính **lặp lại theo chu kỳ** khi kỳ có nhiều danh mục hơn số màu của bảng màu. Dòng "Khác" chỉ còn dành cho tiền chi **không gắn danh mục**. (chốt 2026-09-12)
- **Chip kỳ trên màn Chi tiết là nhãn tĩnh** — chỉ hiển thị kỳ kế thừa từ màn Tổng quan, không bấm được, không có mũi tên/menu chọn kỳ (khác mockup `02`); đổi kỳ thực hiện ở màn Tổng quan. Bộ lọc thời gian vẫn để PBI sau (doc nghiệp vụ §3.8). (chốt 2026-09-12)
