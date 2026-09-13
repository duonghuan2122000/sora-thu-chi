# Đặc tả tính năng: So sánh kỳ (màn 03 Báo cáo)

**Mã PBI**: 26
**Ngày tạo**: 2026-09-13
**Trạng thái**: Đã làm rõ

## Mô tả tổng quan

Màn **Tổng quan Báo cáo** (PBI 22) cho biết một kỳ có bao nhiêu thu, bao nhiêu chi, nhưng **không** cho biết tình hình đang **tốt lên hay xấu đi** — người dùng muốn biết "tháng này mình tiêu nhiều hơn tháng trước không, hơn bao nhiêu" phải tự nhớ số cũ. PBI này dựng **màn So sánh kỳ** theo mockup `docs/report/man-hinh-03-so-sanh-ky.svg`, mở từ màn Tổng quan: đặt **hai kỳ cạnh nhau** (kỳ đang xem và kỳ liền trước), hiển thị **cặp cột so sánh** cho Thu nhập và Chi tiêu kèm **badge % chênh lệch** tô màu theo hướng tốt/xấu, **biểu đồ đường so sánh xu hướng chi tiêu theo ngày** của hai kỳ, và một **thẻ Nhận xét** tóm tắt chênh lệch bằng câu chữ tự nhiên (nêu cả danh mục tăng mạnh nhất).

Đợt này chỉ làm **màn con `03`** — trang đẩy từ màn Tổng quan, có app bar màu thương hiệu + nút back, **không** có thanh điều hướng đáy. Màn `04` Xuất báo cáo và bộ lọc báo cáo nâng cao thuộc PBI sau.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính — So sánh kỳ đang xem với kỳ liền trước

1. Người dùng đang ở **màn Tổng quan Báo cáo**, kỳ **Tháng** (mặc định), 2 số tổng ghi Thu **18.500.000 đ** / Chi **12.300.000 đ**.
2. Người dùng chạm **nút "So sánh"** trên màn Tổng quan → màn **So sánh kỳ** mở ra theo mockup `03`: app bar teal có nút back và tiêu đề **"So sánh kỳ"**.
3. Ngay dưới app bar là **cặp chip kỳ**: chip trái **"Tháng 9/2026"** (nền teal, chữ trắng — kỳ đang xem), **nút hoán đổi** ở giữa, chip phải **"Tháng 8/2026"** (nền nhạt, chữ xám — kỳ đối chiếu).
4. **Thẻ "Thu nhập"**: badge **▲ 8%** màu teal (tăng là tốt), hai cột cạnh nhau — cột T8 xám nhạt thấp hơn, cột T9 teal cao hơn — kèm hai dòng số: **T8: 17.100.000 đ** và **T9: 18.500.000 đ**.
5. **Thẻ "Chi tiêu"**: badge **▲ 15%** màu coral (chi tăng là xấu), cột T8 xám nhạt, cột T9 coral, hai dòng số **T8: 10.700.000 đ** / **T9: 12.300.000 đ**.
6. **Thẻ "Xu hướng chi tiêu theo ngày"**: biểu đồ đường hai đường — kỳ đang xem **liền màu teal**, kỳ đối chiếu **nét đứt màu xám**; có chú giải `T9` / `T8`; trục hoành là **ngày trong kỳ** (1 … 30).
7. **Thẻ "Nhận xét"** (nền cam rất nhạt, biểu tượng cảnh báo coral): câu **"Bạn chi nhiều hơn kỳ trước 15%, chủ yếu do danh mục Ăn uống tăng mạnh."**
8. Người dùng chạm **nút hoán đổi** → hai chip đổi chỗ: chip trái thành **"Tháng 8/2026"**, chip phải thành **"Tháng 9/2026"**; hai thẻ số liệu, biểu đồ và câu Nhận xét **cập nhật lại theo chiều so sánh mới** (chi của kỳ trái so với kỳ phải).
9. Người dùng chạm **chip "Tháng 8/2026"** (chip kỳ đối chiếu) → kỳ đối chiếu đổi sang **"Tháng 9/2025"** (so cùng kỳ năm trước); chạm lần nữa → quay về **"Tháng 8/2026"**. Kỳ chính không đổi.
10. Người dùng chạm nút **back** ở app bar → quay về **màn Tổng quan Báo cáo**, vẫn ở kỳ **Tháng** như trước.

### Kịch bản chấp nhận

1. **Given** màn Tổng quan Báo cáo đang mở ở kỳ **Tháng 9/2026** **When** người dùng chạm nút **"So sánh"** **Then** màn **So sánh kỳ** mở ra bằng **đúng 1 lần chạm**, có app bar màu thương hiệu + nút back + tiêu đề "So sánh kỳ", **không** có thanh điều hướng đáy; kỳ đang xem trở thành **kỳ chính (bên trái)** của cặp so sánh và kỳ đối chiếu mặc định là **kỳ liền trước cùng loại** (Tháng 8/2026).
2. **Given** màn So sánh kỳ đang mở **When** người dùng chạm nút **back** **Then** quay về màn Tổng quan Báo cáo và màn Tổng quan **giữ nguyên kỳ đang chọn** (việc xem so sánh không làm đổi kỳ của màn Tổng quan).
3. **Given** hai kỳ đang so sánh **When** xem hai chip kỳ **Then** mỗi chip ghi rõ **loại kỳ + mốc kỳ** (VD "Tháng 9/2026", "Tuần 07/09–13/09/2026", "Năm 2026", "Ngày 12/09/2026"), hai kỳ **luôn cùng loại kỳ**, và chip của **kỳ chính** được làm nổi bật (nền màu thương hiệu, chữ trắng) trong khi chip kỳ đối chiếu dùng nền nhạt chữ xám; chip kỳ chính **không phản hồi khi chạm**, còn chip kỳ đối chiếu **bấm được** và có **chỉ báo thị giác** cho biết bấm được.
4. **Given** hai kỳ đang so sánh **When** người dùng chạm **nút hoán đổi** **Then** hai kỳ **đổi chỗ cho nhau**: chip, cặp cột trong hai thẻ số liệu, hai dòng số, hai đường của biểu đồ xu hướng và câu Nhận xét **cập nhật lại ngay** theo chiều so sánh mới; chạm hoán đổi **lần thứ hai** đưa màn về đúng trạng thái ban đầu.
5. **Given** kỳ **Tháng 9/2026** có Thu 18.500.000 đ và Tháng 8/2026 có Thu 17.100.000 đ **When** xem thẻ **"Thu nhập"** **Then** thẻ hiển thị **hai cột cạnh nhau** (cột kỳ đối chiếu tông nhạt, cột kỳ chính tô đậm màu thu) với **chiều cao tỉ lệ đúng** với hai số tiền, hai dòng số tiền của hai kỳ (dòng kỳ chính đậm hơn), và badge **▲ 8%** — tăng nên tô **màu thu (teal)**.
6. **Given** kỳ **Tháng 9/2026** có Chi 12.300.000 đ và Tháng 8/2026 có Chi 10.700.000 đ **When** xem thẻ **"Chi tiêu"** **Then** thẻ hiển thị hai cột (cột kỳ chính tô **màu chi (coral)**), hai dòng số tiền, và badge **▲ 15%** — chi **tăng** nên tô **coral** (cảnh báo).
7. **Given** một kỳ có chi tiêu **giảm** so với kỳ đối chiếu **When** xem thẻ số liệu tương ứng **Then** badge hiển thị **▼** với **% giảm**: với **Chi** giảm → tô **teal** (tốt); với **Thu** giảm → tô **coral** (xấu); quy tắc màu luôn theo **ý nghĩa tốt/xấu** chứ không theo chiều tăng/giảm.
8. **Given** hai kỳ đang so sánh **When** cộng tay từ sổ giao dịch **Then** **100%** số tiền hiển thị (số ở hai dòng của mỗi thẻ, chiều cao cột, điểm trên hai đường biểu đồ, và % trong câu Nhận xét) **khớp** với dữ liệu giao dịch thật, sai lệch **0 đ**; mọi giao dịch **chuyển khoản nội bộ** và **điều chỉnh số dư** bị **loại khỏi tất cả** các con số.
9. **Given** kỳ đối chiếu **không có phát sinh** (không có Thu/Chi nào) **When** xem hai thẻ số liệu **Then** **không** hiển thị badge % (không chia cho 0, không hiện ▲/▼ vô nghĩa) mà hiển thị ghi chú "Kỳ trước không có dữ liệu để so sánh" (hoặc câu tương ứng khi kỳ chính cũng rỗng), và cột của kỳ đối chiếu vẽ ở mức 0.
10. **Given** **cả hai kỳ** đều không có Thu/Chi nào **When** mở màn So sánh **Then** màn hiển thị **trạng thái rỗng** "Chưa có giao dịch nào trong hai kỳ này" — **không** vẽ cột 0, biểu đồ rỗng hay thẻ Nhận xét gây hiểu lầm là lỗi.
11. **Given** kỳ đang xem **chỉ có giao dịch chuyển khoản nội bộ** **When** mở màn So sánh **Then** kỳ đó được coi là **kỳ rỗng** (chuyển khoản không phải thu/chi), và màn xử lý theo cùng quy tắc của kịch bản 9 hoặc 10.
12. **Given** màn So sánh kỳ đang mở **When** xem thẻ **"Xu hướng chi tiêu theo ngày"** **Then** thẻ vẽ **hai đường** — kỳ chính **nét liền màu teal**, kỳ đối chiếu **nét đứt màu xám** — kèm **chú giải** ghi nhãn hai kỳ khớp với cặp chip; trục hoành đánh số **ngày trong kỳ** (1 … số ngày của kỳ dài hơn), mỗi điểm là **tổng chi của ngày đó** (không phải luỹ kế); khi hai kỳ **khác số ngày** thì đường của kỳ ngắn hơn **dừng ở ngày cuối của kỳ đó**, không kéo dài giả.
13. **Given** kỳ đang xem có chi tiêu và kỳ đối chiếu có chi tiêu **When** xem thẻ **"Nhận xét"** **Then** thẻ hiển thị **một câu** nêu **chiều và mức chênh lệch chi** giữa hai kỳ bằng chữ (VD "Bạn chi nhiều hơn kỳ trước 15%") **và** tên **danh mục cha có mức chi tăng nhiều nhất** giữa hai kỳ (VD "chủ yếu do danh mục Ăn uống tăng mạnh"); khi không có danh mục nào tăng, câu **không** nêu danh mục; khi chi **giảm**, câu nêu chiều "chi ít hơn".
14. **Given** kỳ đối chiếu **không có chi tiêu** mà kỳ chính **có** **When** xem thẻ Nhận xét **Then** câu nêu **số tiền chi của kỳ chính** và cho biết **kỳ đối chiếu chưa có chi tiêu** để so sánh (không hiện % chênh lệch vô nghĩa).
15. **Given** màn So sánh kỳ đang mở **When** người dùng chạm nút **back** rồi mở lại màn **Then** kỳ chính vẫn là **kỳ đang chọn của màn Tổng quan** và số liệu cập nhật theo **dữ liệu giao dịch hiện có** (giao dịch vừa thêm/sửa/xóa được phản ánh đúng).
16. **Given** người dùng vừa đổi kỳ ở màn Tổng quan sang **Tuần** rồi mở màn So sánh **When** màn So sánh mở ra **Then** hai kỳ so sánh là **hai tuần liền kề cùng loại kỳ** (tuần hiện tại và tuần trước, mỗi tuần bắt đầu **Thứ Hai**), và cách hiển thị mốc kỳ giống màn Chi tiết theo danh mục.
17. **Given** kỳ chính là **Ngày** hoặc **Năm** **When** mở màn So sánh **Then** kỳ đối chiếu là **ngày hôm trước** hoặc **năm trước** tương ứng, và biểu đồ xu hướng theo ngày dùng trục ngày trong kỳ như các loại kỳ khác.
18. **Given** app đang ở **English** (PBI 19) **When** mở màn So sánh **Then** toàn bộ nhãn tĩnh (tiêu đề app bar, nhãn hai chip kỳ, tiêu đề hai thẻ "Thu nhập"/"Chi tiêu", tiêu đề thẻ xu hướng, chú giải, tiêu đề "Nhận xét", câu nhận xét tự động, thông điệp rỗng/không có dữ liệu) hiển thị bằng **tiếng Anh**, **không** còn sót tiếng Việt; số tiền vẫn theo định dạng phân tách nghìn kèm đơn vị tiền tệ.
19. **Given** app đang ở **chế độ Tối** (PBI 18) **When** mở màn So sánh **Then** nền, chữ, app bar, màu hai cột, hai đường biểu đồ, thẻ Nhận xét và đường phân cách dùng đúng bộ màu của chế độ Tối, chữ và số vẫn đủ tương phản để đọc.
20. **Given** màn hình nhỏ và cỡ chữ lớn nhất **When** xem màn So sánh **Then** bố cục không vỡ: chip kỳ không tràn ra ngoài, số tiền hàng tỉ không tràn khỏi dòng hay khỏi cột, chú giải và câu Nhận xét xuống dòng gọn, và **cuộn tới được** thẻ cuối cùng.
21. **Given** màn So sánh kỳ đang mở với kỳ chính **Tháng 9/2026** và kỳ đối chiếu **Tháng 8/2026** (chế độ "kỳ liền trước") **When** người dùng chạm **chip kỳ đối chiếu** **Then** kỳ đối chiếu đổi sang **Tháng 9/2025** (chế độ "cùng kỳ năm trước") và **mọi** số liệu của màn — cặp cột, hai dòng số tiền, badge %, hai đường biểu đồ, chú giải, câu Nhận xét — cập nhật theo **cặp kỳ mới**; chạm lần nữa **quay về** Tháng 8/2026; việc đổi kỳ đối chiếu **không** làm đổi kỳ chính (chip trái và kỳ đang chọn của màn Tổng quan giữ nguyên).

### Trường hợp biên

- **Kỳ đối chiếu không có dữ liệu** (kỳ trước không có giao dịch, hoặc kỳ rỗng) → không tính % chênh lệch, hiển thị ghi chú giải thích thay vì chia cho 0 hay hiện ▲/▼ vô nghĩa (kịch bản 9).
- **Cả hai kỳ rỗng** → trạng thái rỗng toàn màn, không vẽ cột/đường rỗng.
- **Kỳ chỉ có chuyển khoản nội bộ** → coi như kỳ rỗng (kế thừa PBI 22).
- **Chênh lệch bằng 0** (hai kỳ bằng nhau) → badge hiển thị **0%** với dấu gạch ngang (không tô màu tốt/xấu) — không hiện ▲/▼.
- **Chi tiêu tăng nhưng không có danh mục nào tăng** (tăng rải đều hoặc do danh mục mới) → câu Nhận xét chỉ nêu % chênh lệch, không nêu danh mục.
- **Danh mục gây tăng đã bị ẩn** (module Danh mục) → vẫn được nêu tên trong câu Nhận xét (ẩn chỉ loại khỏi chọn nhanh, không xóa lịch sử).
- **Tiền chi không gắn danh mục** → phần chênh lệch này không ứng với danh mục nào; câu Nhận xét xử lý như trường hợp "không có danh mục nào tăng".
- **Danh mục con** → mức chi của danh mục con được gộp vào danh mục cha khi xác định danh mục tăng mạnh nhất (cùng cách gộp với màn Tổng quan/Chi tiết).
- **Hai kỳ khác số ngày** (tháng 31 ngày so với tháng 30 ngày, tuần đủ so với tuần có ngày lễ) → đường biểu đồ của kỳ ngắn hơn dừng ở ngày cuối kỳ đó; không nội suy, không kéo dài giả.
- **Tháng 2 / năm nhuận** → kỳ "tháng trước" giải đúng theo số học ngày, không cộng chu kỳ 30 ngày.
- **Giao dịch có ngày trong tương lai nhưng nằm trong kỳ** → vẫn được tính (kế thừa PBI 22).
- **Số tiền rất lớn** (hàng tỉ) → hiển thị đúng định dạng phân tách nghìn, badge % và nhãn cột không tràn.
- **Tên danh mục rất dài** trong câu Nhận xét → câu chữ xuống dòng gọn, không đẩy tràn màn hình.
- **Kỳ chính là Ngày và kỳ đối chiếu là ngày hôm trước** → biểu đồ xu hướng vẫn vẽ được (trục ngày có 1 điểm mỗi kỳ).
- **Không có mạng / offline** → màn hiển thị đầy đủ vì toàn bộ số liệu tính từ dữ liệu lưu trên thiết bị.
- **Ví có tiền tệ khác tiền tệ mặc định** → xem mục "Giả định" (đa tiền tệ chưa thuộc đợt này).

## Yêu cầu chức năng

- **FR-001**: Màn **Tổng quan Báo cáo** PHẢI có **lối vào màn So sánh kỳ** dưới dạng **biểu tượng trên vùng tiêu đề** (cùng hàng với tiêu đề "Báo cáo"), mở được bằng **1 lần chạm**; lối vào PHẢI mang theo **kỳ đang xem** của màn Tổng quan làm **kỳ chính** của cặp so sánh.
- **FR-002**: Màn So sánh kỳ PHẢI là **trang con** theo mockup `03`: app bar **màu thương hiệu** có **nút back** và tiêu đề **"So sánh kỳ"**; **không** có thanh điều hướng đáy và **không** có nút thêm giao dịch.
- **FR-003**: Màn PHẢI hiển thị **cặp chip kỳ** ngay dưới app bar: chip **kỳ chính** ở **bên trái** (kế thừa từ màn Tổng quan) và chip **kỳ đối chiếu** ở **bên phải**, **ở giữa hai chip là nút hoán đổi**. Mặc định kỳ đối chiếu là **kỳ liền trước cùng loại kỳ** của kỳ chính (Ngày → hôm trước; Tuần → tuần trước, bắt đầu Thứ Hai; Tháng → tháng trước; Năm → năm trước).
- **FR-004**: Mỗi chip PHẢI ghi rõ **loại kỳ + mốc kỳ** đủ để người dùng biết đang so hai khoảng thời gian nào; hai kỳ PHẢI **luôn cùng loại kỳ**; chip **kỳ chính** PHẢI được phân biệt thị giác rõ với chip kỳ đối chiếu (nền màu thương hiệu/chữ trắng so với nền nhạt/chữ xám theo mockup).
- **FR-005**: **Chip kỳ đối chiếu PHẢI bấm được** để **luân chuyển giữa hai chế độ đối chiếu** của kỳ chính: **kỳ liền trước** ⇄ **cùng kỳ năm trước**; chip PHẢI có **chỉ báo thị giác** cho biết bấm được (khác biệt cố ý so với mockup `03` — xem "Quyết định đã chốt"). **Chip kỳ chính là nhãn tĩnh** kế thừa từ màn Tổng quan: **KHÔNG** bấm được, **KHÔNG** đổi được kỳ chính tại màn này (muốn đổi kỳ chính thì đổi kỳ ở màn Tổng quan rồi mở lại).
- **FR-006**: Nút **hoán đổi** PHẢI **đổi chỗ hai kỳ đang hiển thị** (kỳ đang ở bên trái sang bên phải và ngược lại); sau khi hoán đổi, **mọi** thành phần của màn (chip, hai thẻ số liệu, cặp cột, hai dòng số tiền, hai đường biểu đồ, chú giải, câu Nhận xét) PHẢI phản ánh **chiều so sánh mới** (kỳ bên trái so với kỳ bên phải); hoán đổi lần thứ hai PHẢI đưa màn về **đúng trạng thái ban đầu** (hoán đổi **không** tính lại kỳ đối chiếu theo chế độ đang chọn).
- **FR-007**: **Thẻ "Thu nhập"** PHẢI hiển thị: **hai cột** so sánh (cột kỳ đối chiếu tông nhạt, cột kỳ chính tô màu thu) với **chiều cao tỉ lệ** với hai số tiền; **hai dòng số tiền** đã định dạng (một dòng mỗi kỳ, dòng kỳ chính nổi bật hơn); và **badge % chênh lệch**.
- **FR-008**: **Thẻ "Chi tiêu"** PHẢI có cấu trúc như thẻ Thu nhập nhưng dùng **màu chi (coral)** cho cột kỳ chính, kèm badge % chênh lệch chi.
- **FR-009**: **Badge % chênh lệch** PHẢI là **chênh lệch tương đối** giữa hai kỳ (kỳ chính so với kỳ đối chiếu), **làm tròn tới %**, kèm **mũi tên chỉ chiều** (tăng ▲ / giảm ▼).
- **FR-010**: **Màu badge** PHẢI theo **ý nghĩa tốt/xấu**, không theo chiều tăng/giảm: **Thu tăng = tốt (màu thu/teal)**, **Thu giảm = xấu (coral)**; **Chi tăng = xấu (coral)**, **Chi giảm = tốt (teal)**. Chênh lệch **bằng 0** PHẢI hiển thị **0% không tô màu tốt/xấu**.
- **FR-011**: Khi **kỳ đối chiếu không có phát sinh** Thu/Chi PHẢI **không hiển thị badge %** (không chia cho 0) mà hiển thị **ghi chú** cho biết kỳ đối chiếu **không có dữ liệu để so sánh**; cột của kỳ đối chiếu PHẢI vẽ ở mức 0.
- **FR-012**: **Thẻ "Xu hướng chi tiêu theo ngày"** PHẢI vẽ **hai đường chi tiêu** trên cùng một biểu đồ: **kỳ chính nét liền màu teal**, **kỳ đối chiếu nét đứt màu xám**, kèm **chú giải** ghi nhãn hai kỳ khớp với cặp chip; trục hoành PHẢI đánh số **ngày trong kỳ** (1 … số ngày của kỳ dài hơn) và mỗi điểm PHẢI là **tổng chi của ngày đó** (không luỹ kế); đường của kỳ **ngắn hơn** PHẢI **dừng** ở ngày cuối của kỳ đó.
- **FR-013**: **Thẻ "Nhận xét"** PHẢI hiển thị **một câu tóm tắt tự động** nêu **chiều và mức chênh lệch chi tiêu** giữa hai kỳ; khi có ít nhất một danh mục chi **tăng**, câu PHẢI nêu **tên danh mục cha có mức chi tăng nhiều nhất**; khi **không** danh mục nào tăng, câu **không** nêu danh mục. Câu PHẢI có **biến thể cho chiều tăng và chiều giảm** và **biến thể cho trường hợp kỳ đối chiếu chưa có chi tiêu** (nêu số tiền chi của kỳ chính thay vì %).
- **FR-014**: **Danh mục tăng mạnh nhất** PHẢI xác định theo **chênh lệch tuyệt đối** về số tiền chi giữa hai kỳ, **gộp theo danh mục cha** (tiền của danh mục con tính vào cha — cùng cách gộp với màn Tổng quan/Chi tiết); danh mục **đã bị ẩn** vẫn được nêu tên.
- **FR-015**: **Chuyển khoản nội bộ** và **điều chỉnh số dư** PHẢI bị **loại khỏi mọi con số** của màn (số tiền hai kỳ, cặp cột, badge %, hai đường biểu đồ, câu Nhận xét), dùng **cùng một cách lọc** với màn Tổng quan và Chi tiết; kỳ chỉ có chuyển khoản được coi là **kỳ rỗng**.
- **FR-016**: Khi **cả hai kỳ đều không có** Thu/Chi nào, màn PHẢI hiển thị **trạng thái rỗng** với thông điệp cho biết hai kỳ chưa có giao dịch — **không** vẽ cột 0, biểu đồ rỗng hay thẻ Nhận xét rỗng.
- **FR-017**: Khi **kỳ đối chiếu không có dữ liệu để so sánh**, màn PHẢI **vẫn mở được** và giải thích rõ tình trạng đó (không chặn người dùng bằng màn trắng hay thông báo lỗi); lối vào ở màn Tổng quan PHẢI **vô hiệu hoá kèm giải thích** trong trường hợp người dùng **chưa từng có** giao dịch Thu/Chi nào trước kỳ đang xem (kịch bản "kỳ đầu tiên dùng app").
- **FR-018**: Kỳ PHẢI dùng **cùng quy ước** với màn Tổng quan (PBI 22): khoảng **nửa mở**, Tuần **bắt đầu Thứ Hai**, Tháng/Năm **dương lịch** giải bằng số học ngày (không cộng chu kỳ cố định); giao dịch được tính vào kỳ theo **ngày giao dịch** và **giao dịch có ngày trong tương lai nhưng thuộc kỳ vẫn được tính**.
- **FR-019**: Mọi số liệu trên màn PHẢI được **tính tại thời điểm mở màn** từ dữ liệu giao dịch hiện có, để giao dịch **thêm/sửa/xóa** sau đó được phản ánh đúng ở lần mở kế tiếp.
- **FR-020**: Quay về từ màn So sánh PHẢI **không làm đổi kỳ đang chọn** của màn Tổng quan.
- **FR-021**: Mọi **nhãn giao diện tĩnh** của màn (tiêu đề app bar, tiêu đề hai thẻ số liệu, tiêu đề thẻ xu hướng, chú giải, tiêu đề "Nhận xét", câu nhận xét tự động, ghi chú không có dữ liệu, thông điệp rỗng) PHẢI có bản dịch **Tiếng Việt / English** theo ngôn ngữ đang chọn (PBI 19); **số tiền** PHẢI theo định dạng phân tách nghìn kèm đơn vị tiền tệ.
- **FR-022**: Màn PHẢI hiển thị đúng bộ màu của **chế độ Sáng/Tối** đang chọn (PBI 18) — nền, chữ, app bar, màu hai cột, hai đường biểu đồ, thẻ Nhận xét — đảm bảo đủ tương phản.
- **FR-023**: Màn PHẢI hiển thị đúng thiết kế và **không vỡ bố cục** trên các kích thước màn hình, vùng an toàn và cỡ chữ khác nhau; nội dung PHẢI **cuộn được** tới thẻ cuối; chip kỳ, badge %, số tiền và câu Nhận xét PHẢI **không tràn/cắt chữ**.

## Tiêu chí thành công

- **SC-001**: Đối chiếu trực quan với `man-hinh-03-so-sanh-ky.svg`: **100%** thành phần (app bar teal + back + tiêu đề "So sánh kỳ", hai chip kỳ + nút hoán đổi, thẻ "Thu nhập" có badge + cặp cột + hai dòng số, thẻ "Chi tiêu" tương tự, thẻ xu hướng có hai đường + chú giải, thẻ "Nhận xét") hiển thị đúng vị trí, đúng nội dung và đúng màu ngữ nghĩa; **khác biệt đã chốt** so với mockup: chip kỳ đối chiếu **bấm được** (có chỉ báo thị giác) còn chip kỳ chính là **nhãn tĩnh**.
- **SC-002**: Từ màn Tổng quan, người dùng tới được màn So sánh bằng **đúng 1 lần chạm** và quay lại bằng **1 lần chạm** (back).
- **SC-003**: Với một cặp kỳ bất kỳ, **100%** số liệu hiển thị khớp dữ liệu giao dịch: số tiền hai dòng mỗi thẻ, chiều cao tương đối của cặp cột, điểm trên hai đường biểu đồ — sai lệch **0 đ** so với cộng tay từ sổ giao dịch.
- **SC-004**: **100%** giao dịch chuyển khoản nội bộ và điều chỉnh số dư bị loại khỏi mọi con số của màn — kiểm chứng trên dữ liệu có đủ thu, chi, chuyển khoản và điều chỉnh ở cả hai kỳ.
- **SC-005**: Badge % chênh lệch khớp **100%** với chênh lệch thật giữa hai kỳ (sai số chỉ do làm tròn **≤ 1 điểm %**), và **màu badge đúng ngữ nghĩa tốt/xấu ở 100% trường hợp**: Thu tăng/Chi giảm = màu thu; Thu giảm/Chi tăng = màu cảnh báo; chênh lệch 0 = không tô màu.
- **SC-006**: Khi kỳ đối chiếu không có phát sinh, **0** trường hợp hiển thị % chia cho 0, giá trị vô cực, "NaN" hay ▲/▼ vô nghĩa; **100%** trường hợp hiển thị ghi chú giải thích dễ hiểu.
- **SC-007**: Chạm nút hoán đổi → **100%** thành phần của màn cập nhật theo chiều so sánh mới; chạm lần hai đưa màn về **đúng** trạng thái ban đầu (mọi con số và màu badge trùng khớp).
- **SC-008**: Câu Nhận xét nêu **đúng** chiều chênh lệch chi và **đúng** danh mục cha tăng mạnh nhất ở **100%** trường hợp thử (kể cả khi danh mục tăng nằm ở danh mục con, khi không danh mục nào tăng, khi kỳ đối chiếu rỗng).
- **SC-009**: **100%** trường hợp hai kỳ khác số ngày (tháng 30 so với 31 ngày, tháng 2, năm nhuận) đều hiển thị đúng khoảng thời gian của từng kỳ; không kỳ nào bị lệch ngày.
- **SC-010**: Mở màn với dữ liệu vài năm giao dịch: nội dung hiển thị trong **dưới 1 giây**.
- **SC-011**: Thêm/sửa/xóa một giao dịch rồi mở lại màn So sánh → số liệu cập nhật đúng ngay lần mở đó, **100%** trường hợp thử.
- **SC-012**: Khi cả hai kỳ không có giao dịch, **100%** trường hợp hiển thị trạng thái rỗng kèm thông điệp dễ hiểu, **không** có cột 0 hay màn hình trắng gây hiểu lầm là lỗi.
- **SC-013**: Khi app ở English, **0** nhãn tĩnh tiếng Việt còn sót trên màn So sánh (kể cả câu Nhận xét tự động).
- **SC-014**: Ở chế độ Tối, **100%** chữ và số trên màn đạt tương phản đọc được (kiểm tra bằng công cụ đo tương phản trên ảnh chụp màn hình), bao gồm cả đường nét đứt của kỳ đối chiếu trên nền tối.
- **SC-015**: Với cỡ chữ lớn nhất và màn hình nhỏ, màn So sánh không vỡ bố cục, không cắt chữ, cuộn tới hết thẻ cuối ở **100%** lần kiểm tra.
- **SC-016**: Chạm chip kỳ đối chiếu → kỳ đối chiếu chuyển đúng sang **cùng kỳ năm trước** ở **100%** trường hợp thử (kể cả khi kỳ chính là Ngày/Tuần/Năm) và **toàn bộ** số liệu của màn cập nhật theo cặp kỳ mới; chạm lần nữa quay về đúng chế độ **kỳ liền trước** với số liệu trùng khớp trạng thái ban đầu.

## Thực thể chính

- **Kỳ báo cáo** (đại lượng **tính toán**): loại kỳ (Ngày/Tuần/Tháng/Năm) + mốc kỳ; dùng **chung quy ước** với màn Tổng quan và Chi tiết theo danh mục (PBI 22/23).
- **Cặp kỳ so sánh** (đại lượng **tính toán**): **kỳ chính** — vai trò gắn với **vị trí bên trái**, kế thừa kỳ đang xem ở màn Tổng quan khi mở màn, được tô đậm trên cột/biểu đồ; và **kỳ đối chiếu** — **vị trí bên phải**, mặc định là kỳ liền trước cùng loại kỳ của kỳ chính, đổi được sang **cùng kỳ năm trước** bằng cách chạm chip; hai kỳ luôn cùng loại kỳ. Nút hoán đổi **đổi chỗ hai kỳ** giữa hai vị trí. Trạng thái này **chỉ sống trong phiên mở màn**, không ghi ngược về màn Tổng quan.
- **Chênh lệch kỳ** (đại lượng **tính toán**): với mỗi loại Thu/Chi, là **mức chênh tương đối** giữa hai kỳ (kèm chiều tăng/giảm) và **đánh giá tốt/xấu** theo loại; cộng thêm **danh mục cha tăng mạnh nhất** dùng cho câu Nhận xét.
- **Giao dịch Thu/Chi** (liên kết tới module Giao dịch): nguồn của mọi con số; giao dịch **chuyển khoản nội bộ** và **điều chỉnh số dư** bị loại khỏi mọi số liệu.

## Giả định

- **Lối vào màn So sánh nằm ở biểu tượng trên vùng tiêu đề màn Tổng quan Báo cáo** — doc nghiệp vụ §4 vẽ luồng "chạm icon So sánh (app bar) → Màn So sánh kỳ"; mockup `01` không vẽ biểu tượng này (cũng không vẽ biểu tượng Xuất báo cáo), nên vị trí cụ thể đã được chốt trong "Quyết định đã chốt".
- **Kỳ đối chiếu mặc định là kỳ liền trước cùng loại kỳ** — doc nghiệp vụ §3.3: "kỳ hiện tại vs kỳ liền trước, hoặc cùng kỳ năm trước"; chọn kỳ liền trước làm mặc định vì đó là cách so sánh mockup `03` thể hiện (Tháng 9 vs Tháng 8 cùng năm), và **cùng kỳ năm trước** là chế độ thứ hai chọn được bằng cách chạm chip kỳ đối chiếu.
- **Thẻ "Nhận xét" nằm trong phạm vi đợt này** (mockup `03` vẽ rõ), nhưng **chỉ hiển thị trong màn** — việc **tái sử dụng insight cho thông báo cuối tuần/cuối tháng** (doc nghiệp vụ §3.3 + §9) **không** thuộc đợt này.
- **Biểu đồ xu hướng so sánh là biến thể so sánh của biểu đồ xu hướng** (doc nghiệp vụ §3.4): hai đường của **hai kỳ**, **không** có đường trung bình động và **không** có chế độ "Xu hướng" riêng ở màn Tổng quan.
- **Nút hoán đổi chỉ đổi chỗ hai kỳ** — không tự đổi loại kỳ, không đổi kỳ này sang kỳ khác ngoài cặp đang có.
- **Không có trạng thái "cặp kỳ" nào được lưu lại**: mở lại màn luôn bắt đầu từ kỳ đang xem ở màn Tổng quan và kỳ liền trước (giống nếp PBI 22/23 khi sang màn khác).
- **Số liệu tính lại khi mở màn, không có cập nhật đẩy**: màn không tự đổi số khi dữ liệu thay đổi ở nơi khác trong lúc màn đang mở (kế thừa PBI 22).
- **Danh mục đã bị ẩn vẫn được tính và hiển thị tên bình thường** trong câu Nhận xét: ẩn chỉ loại khỏi chọn nhanh, không xóa lịch sử (nguyên tắc nghiệp vụ xuyên module).
- **Đa tiền tệ chưa thuộc đợt này**: doc nghiệp vụ §2.2 yêu cầu quy đổi theo tỷ giá tại thời điểm giao dịch, nhưng nguồn tỷ giá offline vẫn là quyết định mở. Đợt này cộng theo **số tiền ghi trên giao dịch** và giả định dữ liệu dùng **một tiền tệ mặc định**.
- **Kỳ tài chính lệch ngày chưa thuộc đợt này**: dùng mốc dương lịch, tuần bắt đầu Thứ Hai (kế thừa PBI 20/21/22).
- **Công tắc "Ẩn số dư" (PBI 17) chưa áp dụng**: chưa có hiệu ứng che số tiền ở bất kỳ màn nào.
- **Không có bảng tổng hợp/cache số liệu**: kế thừa PBI 22 — mọi số liệu tính lại từ dữ liệu giao dịch khi mở màn (ngưỡng đo ở SC-010).
- **Không có bộ lọc báo cáo** áp cho màn này: hai kỳ so sánh là **toàn bộ** giao dịch trong kỳ, không lọc theo ví/danh mục/tag (doc nghiệp vụ §3.8 thuộc PBI sau).
- **Khoá app (PIN) không ảnh hưởng màn này**: màn chỉ mở được sau khi đã mở khóa app (PBI 3) và nằm trong luồng của tab Báo cáo.

## Ngoài phạm vi

- **Màn `04` Xuất báo cáo** (PDF/Excel/CSV) và việc chia sẻ file ra ngoài app.
- **Bộ lọc báo cáo nâng cao** (doc nghiệp vụ §3.8): khoảng thời gian tuỳ chỉnh (nút biểu tượng lịch của mockup `01`), lọc theo **ví**, theo **danh mục**, theo **tag**, và việc ghi nhớ bộ lọc giữa các màn báo cáo — màn So sánh **không** có bộ lọc riêng.
- **Biểu đồ xu hướng ở màn Tổng quan** (doc nghiệp vụ §3.4): chế độ "Xu hướng" dạng line chart cho một kỳ và **đường trung bình động**.
- **Báo cáo dòng tiền theo từng ví** (doc nghiệp vụ §3.6).
- **Insight tự động dùng lại cho thông báo cuối tuần/cuối tháng** (doc nghiệp vụ §3.3 + §9) — đợt này insight chỉ hiển thị trong màn.
- **Toggle "Xem theo danh mục con"** (doc nghiệp vụ §3.2): câu Nhận xét luôn gộp theo danh mục cha.
- **Đa tiền tệ và quy đổi tỷ giá**; **kỳ tài chính lệch ngày**; **hiệu ứng công tắc "Ẩn số dư"**.
- **Bảng tổng hợp/cache số liệu báo cáo** và tính toán nền cho dữ liệu nhiều năm.
- **Kéo/vuốt biểu đồ quá 6 đơn vị** ở màn Tổng quan (không đụng tới đợt này).

## Quyết định đã chốt

- **Lối vào màn So sánh là biểu tượng trên vùng tiêu đề màn Tổng quan Báo cáo** (cùng hàng với tiêu đề "Báo cáo"), theo luồng doc nghiệp vụ §4. Không dùng hàng điều hướng kiểu mục "Ngân sách" và không nhét nút vào thẻ biểu đồ. (chốt 2026-09-13)
- **Thẻ "Xu hướng chi tiêu theo ngày" (hai đường so sánh) thuộc đợt này**, bám mockup `03` — đây là biến thể so sánh của biểu đồ xu hướng doc §3.4, **không** kèm đường trung bình động. (chốt 2026-09-13)
- **Chip kỳ đối chiếu bấm được và luân chuyển giữa hai chế độ "kỳ liền trước" ⇄ "cùng kỳ năm trước"** (theo câu chữ doc §3.3); **chip kỳ chính là nhãn tĩnh** kế thừa từ màn Tổng quan — muốn đổi kỳ chính thì đổi kỳ ở màn Tổng quan rồi mở lại. Không dựng màn/bottom sheet chọn kỳ tự do (bộ lọc báo cáo nâng cao vẫn là PBI sau). Chip kỳ đối chiếu vì vậy cần **chỉ báo thị giác** cho biết bấm được — khác biệt cố ý so với mockup `03`. (chốt 2026-09-13)
- **Nút hoán đổi chỉ đổi chỗ hai kỳ đang hiển thị** (trái ↔ phải), **không** tính lại kỳ đối chiếu theo chế độ đang chọn — nhờ vậy hoán đổi hai lần luôn đưa màn về đúng trạng thái ban đầu. (chốt 2026-09-13)
