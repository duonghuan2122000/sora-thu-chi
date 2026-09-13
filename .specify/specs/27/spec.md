# Đặc tả tính năng: Xuất báo cáo (màn 04 Báo cáo)

**Mã PBI**: 27
**Ngày tạo**: 2026-09-13
**Trạng thái**: Nháp

## Mô tả tổng quan

App đã có ba màn Báo cáo (Tổng quan, Chi tiết theo danh mục, So sánh kỳ) nhưng **dữ liệu chỉ nằm trong app** — người dùng không thể đưa số liệu ra ngoài để lưu trữ, gửi cho người khác hay đưa cho kế toán. PBI này dựng **màn Xuất báo cáo** theo mockup `docs/report/man-hinh-04-xuat-bao-cao.svg`: người dùng **chọn khoảng thời gian, ví, danh mục, tag** để lọc, **chọn định dạng xuất** (PDF có biểu đồ / Excel bảng dữ liệu / CSV dữ liệu thô), xem **hộp tóm tắt** cho biết bộ lọc đang khớp bao nhiêu giao dịch, rồi bấm **"Xuất báo cáo"** để tạo tệp và mở **bảng chia sẻ của hệ thống**.

Đợt này chỉ làm **màn con `04`** — trang đẩy từ màn Tổng quan Báo cáo, có app bar màu thương hiệu + nút back, **không** có thanh điều hướng đáy.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính — Xuất báo cáo tháng hiện tại ra PDF

1. Người dùng đang ở **màn Tổng quan Báo cáo**, kỳ **Tháng 9/2026**.
2. Người dùng chạm **biểu tượng Xuất báo cáo** trên vùng tiêu đề màn Tổng quan → màn **Xuất báo cáo** mở ra theo mockup `04`: app bar teal có nút back và tiêu đề **"Xuất báo cáo"**.
3. Màn hiện sẵn bộ lọc mặc định **kế thừa kỳ đang xem**: mục **KHOẢNG THỜI GIAN** ghi **Từ ngày 01/09/2026** / **Đến ngày 30/09/2026**; mục **VÍ** ở trạng thái **"Tất cả"**; mục **DANH MỤC** ở trạng thái **"Tất cả"**; ô **TAG** trống.
4. Mục **ĐỊNH DẠNG XUẤT** có 3 lựa chọn: **PDF** (chú thích "Có biểu đồ"), **Excel** ("Bảng dữ liệu"), **CSV** ("Dữ liệu thô"); mặc định **PDF** đang được chọn (viền teal + dấu chọn ở góc).
5. **Hộp tóm tắt** hiện **"128 giao dịch • 01/09/2026 – 30/09/2026"** và **"Định dạng: PDF (kèm biểu đồ)"**.
6. Người dùng chạm chip **"Tiền mặt"** ở mục VÍ → hộp tóm tắt cập nhật ngay thành **"42 giao dịch • 01/09/2026 – 30/09/2026"**.
7. Người dùng chạm nút **"Xuất báo cáo"** → hiện tiến trình trong lúc tạo tệp, rồi **bảng chia sẻ của hệ thống** mở ra với tệp PDF vừa tạo; người dùng chọn nơi nhận (lưu vào máy, gửi qua ứng dụng khác…).
8. Người dùng chạm nút **back** ở app bar → quay về **màn Tổng quan Báo cáo**, vẫn ở kỳ **Tháng 9/2026**.

### Luồng phụ — Bộ lọc không khớp giao dịch nào

1. Người dùng nhập tag **`#khongtontai`** vào ô TAG → hộp tóm tắt hiện **"0 giao dịch"**, nút **"Xuất báo cáo" bị vô hiệu hoá** kèm thông báo cho biết bộ lọc không có giao dịch nào.
2. Người dùng xoá tag → nút **"Xuất báo cáo"** bật lại, hộp tóm tắt trở về số giao dịch thật.

### Kịch bản chấp nhận

1. **Given** màn Tổng quan Báo cáo đang mở ở kỳ **Tháng 9/2026** **When** người dùng chạm **biểu tượng Xuất báo cáo** **Then** màn **Xuất báo cáo** mở ra bằng **đúng 1 lần chạm**, có app bar màu thương hiệu + nút back + tiêu đề "Xuất báo cáo", **không** có thanh điều hướng đáy và **không** có nút thêm giao dịch; khoảng thời gian mặc định là **đúng kỳ đang xem** (Từ ngày = ngày đầu kỳ, Đến ngày = ngày cuối kỳ).
2. **Given** màn Xuất báo cáo đang mở **When** người dùng chạm nút **back** **Then** quay về màn Tổng quan Báo cáo và màn Tổng quan **giữ nguyên kỳ đang chọn**.
3. **Given** người dùng đã đổi kỳ ở màn Tổng quan sang **Năm 2026** rồi mở màn Xuất báo cáo **When** màn mở ra **Then** khoảng thời gian mặc định là **01/01/2026 – 31/12/2026** (kỳ Năm); với kỳ **Tuần** là **Thứ Hai → Chủ Nhật** của tuần đó; với kỳ **Ngày** là đúng ngày đó ở cả hai trường.
4. **Given** màn Xuất báo cáo đang mở **When** người dùng chạm vào trường **"Từ ngày"** hoặc **"Đến ngày"** **Then** mở ra bộ chọn ngày để đổi; sau khi chọn, hộp tóm tắt cập nhật theo khoảng mới.
5. **Given** người dùng đang chọn ngày **"Đến ngày"** **When** họ mở bộ chọn ngày **Then** hệ thống **không cho** chọn ngày **trước** "Từ ngày" (và ngược lại, **"Từ ngày" không cho chọn ngày sau "Đến ngày"**) — không phát sinh trạng thái khoảng thời gian vô lý, không cần thông báo lỗi.
6. **Given** mục **VÍ** đang ở trạng thái **"Tất cả"** **When** người dùng chạm một ví **Then** chỉ giao dịch thuộc (các) ví đã chọn được tính; chạm thêm ví khác → **chọn được nhiều ví cùng lúc**; chạm **"Tất cả"** → **xoá hết** lựa chọn và trở về không giới hạn theo ví.
7. **Given** mục **DANH MỤC** đang ở trạng thái **"Tất cả"** **When** người dùng chạm một **danh mục cha** **Then** giao dịch của **cả danh mục cha lẫn các danh mục con** của nó được tính (cùng cách gộp với bộ lọc ở màn Giao dịch); chọn được **nhiều danh mục** cùng lúc; chạm **"Tất cả"** → xoá hết lựa chọn.
8. **Given** số danh mục nhiều hơn chỗ hiển thị của hàng chip **When** xem mục DANH MỤC **Then** các chip vượt chỗ được gộp thành **một chip "+N khác"**; chạm chip đó **Then** mở ra danh sách **đầy đủ** danh mục để chọn.
9. **Given** người dùng nhập một tag vào ô **TAG** **When** hộp tóm tắt cập nhật **Then** chỉ các giao dịch có tag khớp mới được tính, **không phân biệt chữ hoa/chữ thường** và **không phân biệt dấu** (gõ `dulich` khớp `#dulich`).
10. **Given** người dùng đã chọn nhiều nhóm lọc (khoảng ngày + ví + danh mục + tag) **When** xem hộp tóm tắt **Then** kết quả là giao dịch thoả **tất cả** các nhóm đang chọn (kiểu VÀ), còn trong **cùng một nhóm** nhiều lựa chọn thì lấy **hợp** (kiểu HOẶC); nhóm không chọn gì nghĩa là **không giới hạn** nhóm đó.
11. **Given** màn Xuất báo cáo đang mở **When** xem mục **ĐỊNH DẠNG XUẤT** **Then** có **3 lựa chọn loại trừ nhau** — **PDF** ("Có biểu đồ"), **Excel** ("Bảng dữ liệu"), **CSV** ("Dữ liệu thô") — mỗi lựa chọn là một thẻ có biểu tượng, tên định dạng và dòng chú thích; lựa chọn **đang chọn** được phân biệt bằng **viền màu thương hiệu + dấu chọn**, lựa chọn còn lại dùng viền xám; **chỉ chọn được một** định dạng tại một thời điểm.
12. **Given** người dùng đổi **bất kỳ** thành phần nào của bộ lọc (ngày, ví, danh mục, tag) hoặc đổi định dạng **When** thao tác hoàn tất **Then** **hộp tóm tắt** cập nhật ngay: **số giao dịch khớp bộ lọc** + **khoảng thời gian** ở dòng trên, **định dạng đang chọn kèm chú thích nội dung** ở dòng dưới.
13. **Given** bộ lọc đang khớp **128 giao dịch** và định dạng chọn là **PDF** **When** người dùng chạm nút **"Xuất báo cáo"** **Then** hệ thống tạo tệp PDF gồm **phần tổng hợp + ảnh các biểu đồ đang có ở màn Tổng quan Báo cáo + bảng top danh mục + danh sách giao dịch**, rồi **mở bảng chia sẻ của hệ thống** để người dùng chọn nơi nhận; app **không tự** gửi tệp đi đâu và **không** tự lưu vào một thư mục cố định mà người dùng không biết.
14. **Given** định dạng chọn là **Excel** **When** xuất **Then** tệp có **trang danh sách giao dịch chi tiết** (cùng các cột như CSV) **và** một **trang tổng hợp** (tổng thu, tổng chi, chênh lệch, phân bổ chi theo danh mục).
15. **Given** định dạng chọn là **CSV** **When** xuất **Then** tệp là **danh sách giao dịch thô** khớp bộ lọc — **mỗi dòng một giao dịch**, có **dòng tiêu đề cột** (tối thiểu: ngày, loại, danh mục, ví, số tiền, ghi chú, tag), **không** kèm phần tổng hợp hay hình ảnh.
16. **Given** bất kỳ tệp nào vừa xuất **When** đối chiếu với app **Then** **phần danh sách giao dịch** chứa **đúng và đủ 100%** giao dịch khớp bộ lọc — **kể cả giao dịch chuyển khoản nội bộ và điều chỉnh số dư** (tệp phải khớp sổ giao dịch, không giấu dòng nào); **ngược lại, mọi con số TỔNG HỢP trong tệp** (tổng thu, tổng chi, chênh lệch, phân bổ theo danh mục) **loại** chuyển khoản nội bộ và điều chỉnh, **gộp danh mục con vào danh mục cha** — tức **khớp đúng** số liệu đang hiển thị ở màn Tổng quan Báo cáo với cùng khoảng thời gian.
17. **Given** bộ lọc cho ra **0 giao dịch** **When** xem màn Xuất báo cáo **Then** nút **"Xuất báo cáo" bị vô hiệu hoá** kèm thông báo cho biết bộ lọc hiện không có giao dịch nào — **không** tạo ra tệp rỗng hay tệp chỉ có dòng tiêu đề.
18. **Given** kỳ đang xem ở màn Tổng quan **hoàn toàn không có giao dịch nào** **When** người dùng mở màn Xuất báo cáo **Then** màn **vẫn mở được** và giải thích rõ tình trạng không có dữ liệu (không chặn bằng màn trắng hay thông báo lỗi); lối vào ở màn Tổng quan **không** bị vô hiệu hoá.
19. **Given** người dùng bấm **"Xuất báo cáo"** trên tập dữ liệu **nhiều năm** **When** quá trình tạo tệp đang chạy **Then** màn hiển thị **trạng thái đang xử lý** và **vẫn phản hồi** thao tác (không đứng hình, không khoá cứng); khi xong thì mở bảng chia sẻ.
20. **Given** quá trình tạo tệp **thất bại** (hết dung lượng, lỗi ghi tệp) hoặc người dùng **huỷ** bảng chia sẻ **When** quay lại màn **Then** màn **không bị treo**, **giữ nguyên** bộ lọc và định dạng đã chọn, và hiển thị thông báo dễ hiểu khi có lỗi.
21. **Given** app đang ở **English** (PBI 19) **When** mở màn Xuất báo cáo **Then** toàn bộ nhãn tĩnh (tiêu đề app bar, tiêu đề 5 mục, nhãn hai trường ngày, tên 3 định dạng + dòng chú thích, nút "Xuất báo cáo", hộp tóm tắt, thông báo không có giao dịch) hiển thị bằng **tiếng Anh**, **không** còn sót tiếng Việt; **định dạng ngày và số tiền không đổi** theo ngôn ngữ.
22. **Given** app đang ở **chế độ Tối** (PBI 18) **When** mở màn Xuất báo cáo **Then** nền, chữ, app bar, chip, thẻ định dạng, hộp tóm tắt và nút xuất dùng đúng bộ màu của chế độ Tối, chữ và số vẫn đủ tương phản.
23. **Given** màn hình nhỏ và cỡ chữ lớn nhất **When** xem màn Xuất báo cáo **Then** bố cục không vỡ: hàng chip ví/danh mục xuống dòng gọn, tên ví/danh mục dài không tràn, 3 thẻ định dạng không bị cắt chữ, và **cuộn tới được** nút "Xuất báo cáo".
24. **Given** người dùng đã lọc + chọn định dạng rồi chạm back **When** mở lại màn Xuất báo cáo **Then** màn trở về **mặc định kế thừa kỳ đang xem** — bộ lọc của lần trước **không** được ghi nhớ.
25. **Given** màn Xuất báo cáo đang mở **When** người dùng xem màn **trước khi** bấm xuất **Then** họ **thấy sẵn** một dòng cảnh báo cho biết **tệp xuất ra không còn được app bảo vệ** (ai có tệp thì đọc được số tiền), và việc xuất vẫn có **số tiền thật** trong tệp (không bị che) — cảnh báo không chặn thao tác, không thêm bước xác nhận.

### Trường hợp biên

- **Bộ lọc ra 0 giao dịch** (khoảng ngày không có gì, ví không phát sinh, tag không khớp, hoặc tổ hợp các nhóm lọc) → khoá nút xuất kèm thông báo (kịch bản 17), không tạo tệp rỗng.
- **Kỳ/khoảng thời gian chỉ có giao dịch chuyển khoản nội bộ** → danh sách giao dịch xuất ra **vẫn có** các dòng đó; nhưng phần **tổng hợp** của tệp ghi tổng thu/tổng chi là **0** (chuyển khoản không là thu/chi) — tệp không được hiểu là "có phát sinh".
- **Khoảng thời gian rất dài** (nhiều năm) → vẫn xuất được; có trạng thái đang xử lý, không chặn giao diện (kịch bản 19).
- **Tag gõ sai chính tả / có dấu `#` hoặc không** → khớp theo cùng quy tắc bỏ dấu, không phân biệt hoa/thường; không khớp thì ra 0 giao dịch, không báo lỗi.
- **Tên ví/danh mục rất dài** → chip cắt gọn có dấu ellipsis, không đẩy tràn hàng chip.
- **Danh mục đã bị ẩn** (module Danh mục) → **không** xuất hiện trong hàng chip để chọn nhanh, nhưng giao dịch của nó **vẫn** nằm trong tệp khi không lọc theo danh mục (ẩn chỉ loại khỏi chọn nhanh, không xoá lịch sử).
- **Danh mục đã bị xoá** mà giao dịch cũ còn trỏ tới → giao dịch vẫn được xuất; cột danh mục ghi giá trị trống/rõ ràng là không có danh mục.
- **Số tiền hàng tỉ** → định dạng phân tách nghìn đúng ở phần hiển thị; trong CSV ghi **số thuần** để bảng tính đọc được, không kèm ký hiệu tiền tệ.
- **Ghi chú chứa dấu phân cách cột, dấu xuống dòng hoặc dấu nháy kép** → tệp phải ghi đúng chuẩn để mở ra không bị lệch cột.
- **Tên danh mục/ví chứa dấu tiếng Việt** → tệp giữ đúng chữ có dấu, mở bằng bảng tính không bị lỗi font.
- **Không có ứng dụng nào nhận tệp** khi mở bảng chia sẻ hoặc người dùng huỷ → màn giữ nguyên trạng thái, không mất lựa chọn.
- **Ví có tiền tệ khác tiền tệ mặc định** → xem mục "Giả định" (đa tiền tệ chưa thuộc đợt này).
- **Tệp xuất ra nằm ngoài app** → không còn được app bảo vệ (khoá app, mã hoá local); xem FR-020 và "Điểm cần làm rõ" Q3.
- **Không có mạng / offline** → xuất báo cáo vẫn chạy đầy đủ vì toàn bộ số liệu tính từ dữ liệu trên thiết bị.
- **Không có giao dịch nào trong toàn bộ app** → màn vẫn mở được, giải thích không có dữ liệu (kịch bản 18).

## Yêu cầu chức năng

- **FR-001**: Màn **Tổng quan Báo cáo** PHẢI có **lối vào màn Xuất báo cáo** dưới dạng **biểu tượng trên vùng tiêu đề** (cùng hàng với tiêu đề "Báo cáo", cạnh lối vào So sánh kỳ), mở được bằng **đúng 1 lần chạm**; lối vào PHẢI mang theo **kỳ đang xem** của màn Tổng quan làm **khoảng thời gian mặc định** của bộ lọc. Lối vào PHẢI **luôn bấm được** (màn tự giải thích khi không có dữ liệu — FR-016/FR-017).
- **FR-002**: Màn Xuất báo cáo PHẢI là **trang con** theo mockup `04`: app bar **màu thương hiệu** có **nút back** và tiêu đề **"Xuất báo cáo"**; **không** có thanh điều hướng đáy và **không** có nút thêm giao dịch.
- **FR-003**: Màn PHẢI có mục **KHOẢNG THỜI GIAN** gồm hai trường **"Từ ngày"** và **"Đến ngày"**, mặc định đúng bằng **kỳ đang xem** ở màn Tổng quan (Ngày → 1 ngày; Tuần → Thứ Hai đến Chủ Nhật; Tháng → ngày đầu đến ngày cuối tháng; Năm → 01/01 đến 31/12). Chạm vào một trường PHẢI **mở được bộ chọn ngày** để đổi.
- **FR-004**: Khoảng thời gian PHẢI **bao gồm cả ngày đầu và ngày cuối** (theo ngày lịch) và PHẢI **luôn hợp lệ**: hệ thống **không cho** chọn "Đến ngày" trước "Từ ngày" (và ngược lại) — không phát sinh khoảng âm, không cần thông báo lỗi.
- **FR-005**: Mục **VÍ** PHẢI hiển thị các **chip**: chip **"Tất cả"** (mặc định đang chọn) + **một chip cho mỗi ví**. Người dùng PHẢI **chọn được nhiều ví** cùng lúc; chạm chip **"Tất cả"** PHẢI **xoá toàn bộ** lựa chọn ví (trở về không giới hạn theo ví). Chip đang chọn PHẢI được phân biệt thị giác rõ (nền màu thương hiệu/chữ trắng).
- **FR-006**: Mục **DANH MỤC** PHẢI hiển thị các **chip**: chip **"Tất cả"** (mặc định) + chip danh mục; khi số danh mục vượt chỗ hiển thị, phần vượt PHẢI được gộp thành **một chip "+N khác"** mà khi chạm sẽ mở **danh sách đầy đủ** để chọn. Người dùng PHẢI **chọn được nhiều danh mục**; chọn **danh mục cha** PHẢI bao gồm **cả danh mục con** của nó (cùng quy tắc với bộ lọc ở màn Giao dịch).
- **FR-007**: Màn PHẢI có mục **TAG** là **ô nhập văn bản** để lọc theo tag của giao dịch, có **gợi ý định dạng** khi ô trống (VD "Nhập tag để lọc (VD: #dulich)"); việc khớp tag PHẢI **không phân biệt chữ hoa/thường** và **không phân biệt dấu tiếng Việt**.
- **FR-008**: Các nhóm lọc PHẢI kết hợp theo kiểu **VÀ** (khoảng ngày ∧ ví ∧ danh mục ∧ tag); trong **cùng một nhóm**, nhiều lựa chọn kết hợp theo kiểu **HOẶC**. Nhóm **không có lựa chọn nào** nghĩa là **không giới hạn** theo nhóm đó.
- **FR-009**: Màn PHẢI có mục **ĐỊNH DẠNG XUẤT** với **3 lựa chọn loại trừ nhau**: **PDF** (chú thích "Có biểu đồ"), **Excel** ("Bảng dữ liệu"), **CSV** ("Dữ liệu thô"). Mỗi lựa chọn PHẢI là **một thẻ có biểu tượng + tên định dạng + dòng chú thích**; thẻ **đang chọn** PHẢI được phân biệt bằng **viền màu thương hiệu + dấu chọn**; chỉ **một** định dạng được chọn tại một thời điểm. Mặc định là **PDF**.
- **FR-010**: Màn PHẢI có **hộp tóm tắt** hiển thị **số giao dịch khớp bộ lọc** và **khoảng thời gian** ở dòng trên, **định dạng đang chọn kèm chú thích nội dung** ở dòng dưới; hộp tóm tắt PHẢI **cập nhật ngay** mỗi khi bộ lọc hoặc định dạng thay đổi.
- **FR-011**: Màn PHẢI có nút **"Xuất báo cáo"** cỡ lớn, nhãn rõ, màu thương hiệu; khi bấm PHẢI **tạo tệp theo định dạng đã chọn** rồi **mở bảng chia sẻ của hệ thống** để người dùng chọn nơi nhận. App **KHÔNG** tự gửi tệp đi đâu và **KHÔNG** tự lưu vào một thư mục cố định mà người dùng không biết.
- **FR-012**: Tệp **PDF** PHẢI gồm: phần **tổng hợp** (tổng thu, tổng chi, chênh lệch tương ứng khoảng thời gian đã lọc), **ảnh các biểu đồ** đang có ở màn Tổng quan Báo cáo với cùng khoảng thời gian (biểu đồ dòng tiền + phân bổ chi theo danh mục), **bảng top danh mục chi tiêu**, và **danh sách giao dịch** khớp bộ lọc.
- **FR-013**: Tệp **Excel** PHẢI gồm **trang danh sách giao dịch chi tiết** (cùng bộ cột với CSV) **và** một **trang tổng hợp** (tổng thu, tổng chi, chênh lệch, phân bổ chi theo danh mục).
- **FR-014**: Tệp **CSV** PHẢI là **danh sách giao dịch thô** khớp bộ lọc — **mỗi dòng một giao dịch**, có **dòng tiêu đề cột**, tối thiểu các cột: **ngày, loại (thu/chi/chuyển khoản/điều chỉnh), danh mục, ví, số tiền, ghi chú, tag**; **không** kèm phần tổng hợp hay hình ảnh.
- **FR-015**: **Danh sách giao dịch** trong mọi định dạng PHẢI chứa **đúng và đủ** mọi giao dịch khớp bộ lọc — **kể cả giao dịch chuyển khoản nội bộ và điều chỉnh số dư** (tệp phải khớp sổ giao dịch).
- **FR-016**: Mọi **con số tổng hợp** trong tệp (tổng thu, tổng chi, chênh lệch, phân bổ theo danh mục) PHẢI dùng **đúng quy tắc của màn Báo cáo**: **loại** giao dịch chuyển khoản nội bộ và điều chỉnh số dư, **gộp danh mục con vào danh mục cha** — nhờ đó tệp khớp **đúng** số liệu đang hiển thị ở màn Tổng quan Báo cáo với cùng khoảng thời gian.
- **FR-017**: Khi bộ lọc cho ra **0 giao dịch**, nút **"Xuất báo cáo" PHẢI bị vô hiệu hoá** kèm **thông báo** cho biết bộ lọc không có giao dịch nào; hệ thống **KHÔNG** được tạo tệp rỗng hay tệp chỉ có dòng tiêu đề.
- **FR-018**: Khi **toàn bộ** khoảng đang chọn không có giao dịch nào, màn PHẢI hiển thị **trạng thái rỗng** với thông điệp dễ hiểu và **vẫn mở được** (không chặn người dùng bằng màn trắng hay thông báo lỗi).
- **FR-019**: Số tiền PHẢI theo định dạng **phân tách nghìn kèm đơn vị tiền tệ** ở những chỗ **hiển thị cho người đọc** (màn hình, phần tổng hợp trong PDF/Excel); **riêng CSV** PHẢI ghi **số thuần** (không ký hiệu tiền tệ) để bảng tính đọc được thành số.
- **FR-020**: Mọi **nhãn giao diện tĩnh** của màn (tiêu đề app bar, tiêu đề 5 mục, nhãn hai trường ngày, tên 3 định dạng + dòng chú thích, nút xuất, hộp tóm tắt, các thông báo rỗng/lỗi) PHẢI có bản dịch **Tiếng Việt / English** theo ngôn ngữ đang chọn (PBI 19). **Định dạng ngày và số tiền KHÔNG** đổi theo ngôn ngữ.
- **FR-021**: Màn PHẢI hiển thị đúng bộ màu của **chế độ Sáng/Tối** đang chọn (PBI 18) — nền, chữ, app bar, chip, thẻ định dạng, hộp tóm tắt, nút xuất — đảm bảo đủ tương phản.
- **FR-022**: Màn PHẢI hiển thị đúng thiết kế và **không vỡ bố cục** trên các kích thước màn hình, vùng an toàn và cỡ chữ khác nhau; nội dung PHẢI **cuộn được** tới nút "Xuất báo cáo"; tên ví/danh mục dài, số giao dịch hàng nghìn và nhãn định dạng PHẢI **không tràn/cắt chữ**.
- **FR-023**: Trong lúc tạo tệp (đặc biệt với khoảng thời gian nhiều năm), màn PHẢI hiển thị **trạng thái đang xử lý** và **vẫn phản hồi** thao tác; giao diện **KHÔNG** được đứng hình trong suốt quá trình.
- **FR-024**: Tệp xuất ra PHẢI có **tên tệp nêu rõ** khoảng thời gian và định dạng, **không** chứa ký tự không hợp lệ cho tên tệp; **nội dung tệp PHẢI ghi đúng chuẩn** để mở bằng ứng dụng phổ thông (trình đọc PDF, bảng tính) không bị lệch cột hoặc lỗi font tiếng Việt.
- **FR-025**: Khi tạo tệp **thất bại** (hết dung lượng, lỗi ghi tệp) hoặc người dùng **huỷ** bảng chia sẻ, màn PHẢI **không bị treo**, **giữ nguyên** bộ lọc và định dạng đã chọn, và hiển thị **thông báo dễ hiểu** khi có lỗi.
- **FR-026**: Mọi số liệu của hộp tóm tắt PHẢI được tính **tại thời điểm màn đang mở** từ dữ liệu giao dịch hiện có, để giao dịch **thêm/sửa/xóa** trước đó được phản ánh đúng; **đổi bộ lọc KHÔNG** được đọc lại toàn bộ dữ liệu giao dịch từ nơi lưu trữ.
- **FR-027**: Quay về từ màn Xuất báo cáo PHẢI **không làm đổi kỳ đang chọn** của màn Tổng quan Báo cáo. Bộ lọc của màn Xuất báo cáo **CHỈ thuộc màn này**: nó **KHÔNG** áp sang các màn Báo cáo khác, **KHÔNG** đổi kỳ đang chọn của màn Tổng quan và **KHÔNG** đụng bộ lọc ở màn Giao dịch; bộ lọc **chỉ sống trong phiên mở màn** (đóng màn là mất, mở lại luôn về mặc định kế thừa kỳ đang xem), **KHÔNG** được ghi nhớ giữa các lần mở.
- **FR-028**: Màn PHẢI **cảnh báo rõ** rằng **tệp xuất ra nằm ngoài phạm vi bảo vệ của app** (khoá app và mã hoá dữ liệu local không còn tác dụng với tệp sau khi chia sẻ), và cảnh báo PHẢI **hiển thị sẵn trong màn, đọc được trước khi người dùng bấm xuất** (không bắt người dùng mở thêm chỗ nào mới thấy). **Số tiền trong tệp xuất ra vẫn là số thật** — đợt này **KHÔNG** che số tiền trong tệp và **KHÔNG** thay đổi hiệu lực của công tắc "Ẩn số dư" (PBI 17).

## Tiêu chí thành công

- **SC-001**: Đối chiếu trực quan với `man-hinh-04-xuat-bao-cao.svg`: **100%** thành phần (app bar teal + back + tiêu đề "Xuất báo cáo", mục KHOẢNG THỜI GIAN với 2 trường ngày, mục VÍ có chip "Tất cả" đang chọn, mục DANH MỤC có chip "Tất cả" + chip "+N khác", ô TAG có gợi ý, mục ĐỊNH DẠNG XUẤT với 3 thẻ PDF/Excel/CSV, hộp tóm tắt, nút "Xuất báo cáo") hiển thị đúng vị trí, đúng nội dung và đúng màu ngữ nghĩa; bổ sung **cố ý** so với mockup: **một dòng cảnh báo** về việc tệp ra khỏi app không còn được bảo vệ (FR-028).
- **SC-002**: Từ màn Tổng quan, người dùng tới được màn Xuất báo cáo bằng **đúng 1 lần chạm** và quay lại bằng **1 lần chạm** (back).
- **SC-003**: Với mọi bộ lọc thử nghiệm, **số giao dịch ở hộp tóm tắt khớp 100%** với số dòng giao dịch trong tệp xuất ra (sai lệch **0 dòng**).
- **SC-004**: **100%** con số tổng hợp trong tệp (tổng thu, tổng chi, chênh lệch, phân bổ theo danh mục) **khớp** số liệu hiển thị ở màn Tổng quan Báo cáo với cùng khoảng thời gian — sai lệch **0 đ**; **100%** giao dịch chuyển khoản nội bộ và điều chỉnh số dư bị loại khỏi các con số đó nhưng **vẫn có mặt** trong danh sách giao dịch.
- **SC-005**: **100%** tệp xuất ra mở được bằng ứng dụng phổ thông tương ứng (trình đọc PDF, bảng tính cho Excel/CSV) **không** lỗi định dạng, không lệch cột, chữ tiếng Việt có dấu hiển thị đúng.
- **SC-006**: Bộ lọc cho ra 0 giao dịch → **0 trường hợp** tạo tệp rỗng hoặc tệp chỉ có dòng tiêu đề; **100%** trường hợp nút xuất bị vô hiệu hoá kèm thông báo dễ hiểu.
- **SC-007**: Đổi bất kỳ thành phần bộ lọc → hộp tóm tắt cập nhật trong **dưới 1 giây**, và thao tác **vẫn mượt** khi dữ liệu có vài năm giao dịch.
- **SC-008**: Với dữ liệu **hàng nghìn giao dịch**, tệp sẵn sàng để chia sẻ trong **dưới 5 giây**; trong suốt quá trình, màn **vẫn phản hồi** thao tác (100% lần thử không bị đứng hình).
- **SC-009**: **100%** trường hợp thử bộ lọc (chỉ ngày, chỉ ví, chỉ danh mục, chỉ tag, và tổ hợp nhiều nhóm) cho ra danh sách giao dịch **đúng** theo quy tắc VÀ giữa các nhóm / HOẶC trong nhóm.
- **SC-010**: Chọn một **danh mục cha** → tệp chứa **100%** giao dịch của cả cha lẫn các con; chọn **nhiều ví** → tệp chứa giao dịch của **tất cả** các ví đã chọn và **không** chứa giao dịch của ví không chọn.
- **SC-011**: Ở **English**, **0** nhãn tĩnh tiếng Việt còn sót trên màn Xuất báo cáo; ở **chế độ Tối**, **100%** chữ và số đạt tương phản đọc được (đo trên ảnh chụp màn hình).
- **SC-012**: Với **cỡ chữ lớn nhất** và **màn hình nhỏ**, màn Xuất báo cáo không vỡ bố cục, không cắt chữ, và cuộn tới được nút "Xuất báo cáo" ở **100%** lần kiểm tra.
- **SC-013**: **0** trường hợp tệp chứa dữ liệu ngoài bộ lọc (giao dịch ngoài khoảng ngày, ví không chọn, danh mục không chọn, tag không khớp) — kiểm chứng bằng đối chiếu ngẫu nhiên **100 dòng** trong tệp.
- **SC-014**: **100%** lần huỷ bảng chia sẻ hoặc gặp lỗi tạo tệp: màn vẫn dùng được, bộ lọc và định dạng đã chọn còn nguyên.

## Thực thể chính

- **Bộ lọc xuất báo cáo** (đại lượng **tính toán**, không ghi vào dữ liệu): **khoảng thời gian** (từ ngày – đến ngày, mặc định kế thừa kỳ đang xem ở màn Tổng quan), **danh sách ví** (rỗng = tất cả), **danh sách danh mục** (rỗng = tất cả; chọn cha bao gồm con) và **tag**. Bộ lọc **chỉ sống trong phiên mở màn**, không lưu lại.
- **Định dạng xuất**: một trong ba — **PDF** (kèm biểu đồ), **Excel** (bảng dữ liệu), **CSV** (dữ liệu thô); chọn **một** tại một thời điểm, mặc định PDF.
- **Tệp báo cáo**: sản phẩm sinh ra khi bấm "Xuất báo cáo" — gồm **danh sách giao dịch** khớp bộ lọc (đủ mọi loại giao dịch) và, tuỳ định dạng, **phần tổng hợp/biểu đồ** theo quy tắc báo cáo; có **tên tệp** nêu khoảng thời gian; được trao cho **bảng chia sẻ của hệ thống** và **không** được app bảo vệ sau khi rời app.
- **Giao dịch Thu/Chi/Chuyển khoản/Điều chỉnh** (liên kết tới module Giao dịch): nguồn dữ liệu của cả danh sách lẫn phần tổng hợp; **chuyển khoản nội bộ** và **điều chỉnh số dư** có mặt trong danh sách nhưng bị loại khỏi mọi con số tổng hợp.
- **Ví** và **Danh mục** (liên kết tới module Ví/Danh mục): nguồn của hai nhóm bộ lọc; danh mục con thuộc về danh mục cha khi gộp số liệu.

## Giả định

- **Lối vào màn Xuất báo cáo là biểu tượng trên vùng tiêu đề màn Tổng quan Báo cáo** (cùng hàng tiêu đề "Báo cáo", cạnh biểu tượng So sánh kỳ) — doc nghiệp vụ §4 vẽ luồng "chạm icon Xuất báo cáo (app bar) → Màn Xuất báo cáo"; mockup `01` không vẽ biểu tượng này, nên vị trí được chốt theo cùng cách đã chốt cho PBI 26. Màn Tổng quan vì vậy có **2 biểu tượng** ở vùng tiêu đề.
- **Khoảng thời gian mặc định = đúng kỳ đang xem ở màn Tổng quan** — mockup `04` hiển thị 01/09–30/09/2026, tức trọn tháng đang xem; đây cũng là cách để màn Xuất báo cáo **không** cần bộ chọn kỳ riêng.
- **Định dạng mặc định là PDF** — mockup `04` vẽ thẻ PDF ở trạng thái đang chọn; PDF cũng là định dạng "đầy đủ" nhất (có biểu đồ) nên là mặc định hợp lý.
- **Cả ba định dạng (PDF/Excel/CSV) thuộc đợt này** — mockup `04` vẽ cả ba như ba lựa chọn ngang hàng, không đánh dấu "sắp có"; không chia chặng.
- **Bộ lọc của màn Xuất báo cáo là bộ lọc riêng của màn này** — nó **không** thay đổi kỳ đang chọn của màn Tổng quan, **không** áp sang màn Chi tiết/So sánh và **không** ảnh hưởng bộ lọc ở màn Giao dịch (ba màn Báo cáo đã QA giữ nguyên hành vi).
- **Danh sách giao dịch xuất ra gồm cả chuyển khoản nội bộ và điều chỉnh** — tệp là bản sao sổ giao dịch theo bộ lọc, phải khớp những gì người dùng thấy ở tab Giao dịch; còn **phần tổng hợp** trong tệp theo đúng quy tắc báo cáo (loại hai loại giao dịch đó) để khớp màn Tổng quan.
- **Số liệu tính lại khi mở màn và khi đổi bộ lọc, không có cập nhật đẩy** — màn không tự đổi số khi dữ liệu thay đổi ở nơi khác trong lúc màn đang mở (kế thừa PBI 22/26).
- **Không có bảng tổng hợp/cache số liệu** — kế thừa PBI 22: mọi số liệu tính từ dữ liệu giao dịch đã nạp (ngưỡng đo ở SC-007).
- **Không có bước "xem trước tệp" trong app** — người dùng kiểm tra tệp ở ứng dụng nhận tệp sau khi chia sẻ.
- **Việc mở tệp/gửi tệp do hệ điều hành lo** — app chỉ tạo tệp và mở bảng chia sẻ; đợt này **không** có tuỳ chọn "lưu vào thư mục do người dùng chọn", **không** in trực tiếp, **không** gửi email tự động.
- **Bộ lọc danh mục chỉ hiển thị danh mục đang dùng** (danh mục đã ẩn không nằm trong hàng chip chọn nhanh, theo nguyên tắc "ẩn chỉ loại khỏi chọn nhanh"); giao dịch của danh mục ẩn **vẫn** được xuất khi không lọc theo danh mục.
- **Đa tiền tệ chưa thuộc đợt này**: doc nghiệp vụ §2.2 yêu cầu quy đổi theo tỷ giá tại thời điểm giao dịch, nhưng nguồn tỷ giá offline vẫn là quyết định mở. Đợt này tệp ghi **số tiền đúng như trên giao dịch** và giả định dữ liệu dùng **một tiền tệ mặc định**.
- **Kỳ tài chính lệch ngày chưa thuộc đợt này**: khoảng thời gian dùng **ngày dương lịch** (kế thừa PBI 20/21/22).
- **Không có công tắc "Ẩn số dư" tác động** trong đợt này: công tắc (PBI 17) vẫn chưa có hiệu ứng ở bất kỳ màn nào, kể cả với số tiền trong tệp xuất.
- **Khoá app (PIN) không ảnh hưởng màn này**: màn chỉ mở được sau khi đã mở khóa app (PBI 3) và nằm trong luồng của tab Báo cáo.
- **Cảnh báo trước khi xuất** (doc nghiệp vụ §8) là **một dòng ghi chú hiển thị sẵn trong màn** (đọc được trước khi bấm xuất), **không** phải hộp thoại xác nhận — tránh thêm một lần chạm cho mọi lần xuất.

## Ngoài phạm vi

- **Áp bộ lọc nâng cao cho các màn Báo cáo khác** (doc nghiệp vụ §3.8: "áp dụng xuyên suốt mọi màn hình con") — màn `01`/`02`/`03` giữ nguyên hành vi hiện có (Q1 chọn A).
- **Ghi nhớ bộ lọc giữa các lần mở màn / giữa các màn báo cáo** (doc nghiệp vụ §3.8).
- **Hiệu ứng che số tiền của công tắc "Ẩn số dư"** (PBI 17) — cả trên màn hình lẫn trong tệp xuất (Q3 chọn A).
- **Xuất báo cáo tự động định kỳ, gửi email, in trực tiếp, đăng lên dịch vụ ngoài.**
- **Xuất từ màn Giao dịch** hoặc từ màn Chi tiết theo danh mục/So sánh kỳ (chỉ có một lối vào ở màn Tổng quan).
- **Import CSV/Excel** vào app (chiều ngược lại).
- **Báo cáo dòng tiền theo từng ví** (doc nghiệp vụ §3.6) — tệp không có mục số dư đầu kỳ/cuối kỳ theo ví.
- **Biểu đồ xu hướng (line) cho một kỳ và đường trung bình động** ở màn Tổng quan.
- **Toggle "Xem theo danh mục con"** (doc nghiệp vụ §3.2) — phân bổ trong tệp luôn gộp theo danh mục cha.
- **Đa tiền tệ và quy đổi tỷ giá**; **kỳ tài chính lệch ngày**.
- **Xem trước tệp trong app, tuỳ chỉnh mẫu bố cục PDF/Excel**, chèn logo/thương hiệu vào tệp.
- **Bảng tổng hợp/cache số liệu báo cáo** và tính toán nền cho dữ liệu nhiều năm.

## Quyết định đã chốt

- **Lối vào màn Xuất báo cáo là biểu tượng trên vùng tiêu đề màn Tổng quan Báo cáo** (cùng hàng với tiêu đề "Báo cáo"), theo luồng doc nghiệp vụ §4 — đồng bộ với cách đã chốt cho màn So sánh kỳ (PBI 26). (chốt 2026-09-13)
- **Lối vào luôn bấm được**, kể cả khi kỳ đang xem rỗng — màn Xuất báo cáo tự giải thích tình trạng không có dữ liệu; chỉ **nút xuất trong màn** bị vô hiệu hoá khi bộ lọc cho ra 0 giao dịch (doc nghiệp vụ §8). (chốt 2026-09-13)
- **Danh sách giao dịch trong tệp gồm cả chuyển khoản nội bộ và điều chỉnh số dư**, còn **con số tổng hợp** trong tệp loại hai loại giao dịch này — tệp vừa khớp sổ giao dịch (danh sách) vừa khớp màn Tổng quan Báo cáo (tổng hợp). (chốt 2026-09-13)
- **Không cho chọn khoảng thời gian vô lý** thay vì cho chọn rồi báo lỗi: bộ chọn ngày tự giới hạn miền chọn. (chốt 2026-09-13)
- **Định dạng mặc định là PDF** (mockup `04` vẽ PDF đang được chọn). (chốt 2026-09-13)
- **App chỉ tạo tệp rồi mở bảng chia sẻ của hệ thống**, không tự gửi và không tự chọn thư mục lưu. (chốt 2026-09-13)
- **Bộ lọc nâng cao chỉ thuộc màn Xuất báo cáo (Q1 — chọn A)**: doc nghiệp vụ §3.8 nói bộ lọc "áp dụng xuyên suốt mọi màn hình con" + ghi nhớ trong phiên, nhưng đợt này **không** đụng ba màn Báo cáo đã triển khai/QA (PBI 22/23/26) và **không** ghi nhớ bộ lọc — bộ lọc sống trong phiên mở màn. Muốn áp xuyên suốt thì làm PBI riêng. (chốt 2026-09-13)
- **Cả ba định dạng PDF/Excel/CSV làm trong một đợt (Q2 — chọn A)**, không chia chặng. (chốt 2026-09-13)
- **Chỉ cảnh báo, không che số (Q3 — chọn A)**: màn Xuất báo cáo có **dòng cảnh báo hiển thị sẵn** rằng tệp ra khỏi app không còn được bảo vệ, nhưng **tệp vẫn chứa số tiền thật** và **công tắc "Ẩn số dư" (PBI 17) giữ nguyên chưa có hiệu lực** — hiệu ứng che số (trên màn Báo cáo lẫn trong tệp) là việc của PBI khác. (chốt 2026-09-13)
