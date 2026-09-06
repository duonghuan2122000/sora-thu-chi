# Đặc tả tính năng: Tiện ích & Cá nhân hóa (màn danh sách)

**Mã PBI**: 17
**Ngày tạo**: 2026-09-06
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Người dùng cần **một nơi gom các tùy chỉnh hiển thị, trải nghiệm và dữ liệu** của app — giao diện sáng/tối, ngôn ngữ, định dạng ngày/tiền, widget màn hình chính, quyền riêng tư, máy tính nhập tiền, tìm kiếm, tag — thay vì rải rác. Tính năng này dựng **màn "Tiện ích & Cá nhân hóa"** theo đúng thiết kế `docs/tool/01-danh-sach-tien-ich.svg`: một màn con mở từ nhóm KHÁC của màn Cài đặt (PBI 2/shell), app bar thương hiệu tiêu đề "Tiện ích & Cá nhân hóa" + nút quay lại; thân màn liệt kê **3 nhóm — HIỂN THỊ (Giao diện, Ngôn ngữ, Định dạng & Tiền tệ), TRẢI NGHIỆM (Widget màn hình chính, Ẩn số dư, Máy tính khi nhập số tiền), DỮ LIỆU & TÌM KIẾM (Tìm kiếm toàn cục, Quản lý Tag)** — mỗi hàng gồm icon trong vòng nền nhạt, tên, dòng phụ, và phần cuối (giá trị hiện hành, công tắc, hoặc dấu sang phải). Đợt này chỉ dựng **màn danh sách điểm vào**: các màn con (02–07) và hiệu ứng thật của từng công tắc thuộc các PBI sau; các hàng điều hướng chạm chưa mở gì, hai công tắc "Ẩn số dư" và "Máy tính khi nhập số tiền" bật/tắt được và **nhớ trạng thái** giữa các lần mở.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app, đang ở tab Cài đặt của app shell.

### Luồng chính — Mở màn Tiện ích & Cá nhân hóa và thao tác công tắc

1. Người dùng ở tab Cài đặt, cuộn tới nhóm KHÁC, chạm hàng **"Tiện ích & Cá nhân hóa"** → màn con mở ra: app bar teal có nút quay lại (trái) và tiêu đề "Tiện ích & Cá nhân hóa"; **không** có thanh điều hướng đáy.
2. Thân màn hiện **3 nhóm** theo đúng mockup `01`: nhóm **HIỂN THỊ** gồm "Giao diện" (giá trị "Hệ thống", dấu sang phải), "Ngôn ngữ" (giá trị "Tiếng Việt", dấu sang phải), "Định dạng & Tiền tệ" (dòng phụ "Ngày, tiền tệ, tuần, kỳ tài chính", dấu sang phải); nhóm **TRẢI NGHIỆM** gồm "Widget màn hình chính" (công tắc đang bật), "Ẩn số dư (Privacy mode)" (dòng phụ "Che số tiền trên màn hình chính", công tắc đang tắt), "Máy tính khi nhập số tiền" (dòng phụ "Cho phép +, -, x, / khi nhập", công tắc đang bật); nhóm **DỮ LIỆU & TÌM KIẾM** gồm "Tìm kiếm toàn cục" (dòng phụ "Giao dịch, danh mục, ví", dấu sang phải), "Quản lý Tag" (dòng phụ mô tả tag, dấu sang phải). Mỗi hàng có vòng tròn nền nhạt chứa icon màu teal bên trái.
3. Người dùng chạm công tắc "Ẩn số dư" để bật, chạm công tắc "Máy tính khi nhập số tiền" để tắt → trạng thái đảo ngay; màn không báo lỗi, các hàng khác không đổi.
4. Người dùng rời màn (nút quay lại hoặc back hệ thống) rồi mở lại màn này → hai công tắc vẫn ở trạng thái vừa đổi; tắt hẳn app rồi mở lại cũng vẫn giữ.
5. Người dùng chạm hàng "Giao diện", "Ngôn ngữ", "Định dạng & Tiền tệ", "Tìm kiếm toàn cục", "Quản lý Tag" → màn không chuyển đi đâu (các màn con 02–07 chưa có trong đợt này), hàng chỉ phản hồi chạm bình thường.
6. Người dùng chạm hàng "Widget màn hình chính" → hiện **hướng dẫn cách ghim widget** cho nền tảng thiết bị (app không tự ghim được widget — hệ điều hành quản lý); hàng này không phải công tắc bật/tắt thật.

### Kịch bản chấp nhận

1. **Given** người dùng ở tab Cài đặt, nhóm KHÁC **When** chạm hàng "Tiện ích & Cá nhân hóa" **Then** mở màn con đúng bố cục `01-danh-sach-tien-ich.svg`: app bar teal có nút quay lại, tiêu đề "Tiện ích & Cá nhân hóa"; thân màn cuộn được, không có thanh điều hướng đáy.
2. **Given** màn Tiện ích vừa mở **When** nhìn thân màn **Then** thấy đủ 3 nhóm theo đúng thứ tự và nội dung mockup: HIỂN THỊ (3 hàng), TRẢI NGHIỆM (3 hàng), DỮ LIỆU & TÌM KIẾM (2 hàng); mỗi hàng có vòng nền nhạt + icon teal, tên, dòng phụ và phần cuối tương ứng; tiêu đề nhóm viết hoa màu mờ.
3. **Given** "Ẩn số dư (Privacy mode)" đang tắt (mặc định theo mockup) **When** người dùng bật công tắc rồi quay lại và mở lại màn, tắt hẳn app rồi mở lại **Then** công tắc vẫn ở trạng thái bật; tương tự "Máy tính khi nhập số tiền" đang bật, tắt đi rồi mở lại màn/app vẫn giữ trạng thái tắt.
4. **Given** người dùng chạm công tắc "Ẩn số dư"/"Máy tính khi nhập số tiền" **When** nhìn các màn khác của app (Tổng quan, Giao dịch…) **Then** chưa có gì đổi — việc che số tiền thật và đổi bàn phím nhập tiền thuộc PBI sau; công tắc đợt này chỉ ghi nhớ lựa chọn.
5. **Given** người dùng chạm hàng "Widget màn hình chính" (công tắc hiển thị trạng thái bật theo mockup) **When** xem phản hồi **Then** công tắc KHÔNG đảo trạng thái; thay vào đó hiện hướng dẫn cách ghim widget cho nền tảng thiết bị.
6. **Given** người dùng chạm lần lượt các hàng "Giao diện", "Ngôn ngữ", "Định dạng & Tiền tệ", "Tìm kiếm toàn cục", "Quản lý Tag" **When** quan sát **Then** không có màn mới nào mở ra, app không lỗi; hàng "Giao diện"/"Ngôn ngữ" vẫn hiển thị giá trị "Hệ thống"/"Tiếng Việt" như cũ.
7. **Given** người dùng bật/tắt vài công tắc rồi chạm nút quay lại (hoặc back hệ thống) **When** trở về Cài đặt **Then** về đúng tab Cài đặt, trạng thái tab không mất; mở lại màn Tiện ích thấy các lựa chọn công tắc được giữ.
8. **Given** cỡ chữ lớn nhất, màn hình nhỏ, tên/giá trị dài **When** người dùng cuộn và nhìn từng hàng **Then** màn không vỡ bố cục, mỗi hàng hiển thị đầy đủ tên + dòng phụ + phần cuối (không cắt chữ, không tràn), cuộn được tới hàng cuối.

### Trường hợp biên

- Vừa mở màn, chưa chạm gì đã quay lại → trở về Cài đặt bình thường, không hiện cảnh báo hay bước xác nhận.
- Người dùng bật/tắt nhanh liên tục một công tắc → trạng thái cuối cùng phản ánh đúng lần chạm cuối, không nhảy lung tung.
- Bật/tắt công tắc rồi **tắt hẳn app ngay** trước khi rời màn → khi mở lại, trạng thái vẫn được giữ đúng lựa chọn cuối.
- Module tag chưa được xây (PBI sau) → hàng "Quản lý Tag" vẫn xuất hiện với tên, dòng phụ và dấu sang phải; **không hiển thị con số tag giả** (mockup ghi "12 tag" chỉ là số minh họa), chỉ hiện số đếm khi có dữ liệu tag thật.
- Khóa app đang có hiệu lực → màn chỉ truy cập được sau khi mở khóa theo cơ chế chung; màn không chứa số tiền nên không phát sinh rủi ro lộ thêm.
- Rất nhiều hàng/cuộn dài với cỡ chữ lớn → danh sách cuộn mượt tới cuối, hàng cuối không bị che bởi mép dưới.

## Yêu cầu chức năng

- **FR-001**: Nhóm KHÁC của màn Cài đặt PHẢI có hàng **"Tiện ích & Cá nhân hóa"** với dấu sang phải; chạm hàng PHẢI mở màn con theo đúng bố cục `docs/tool/01-danh-sach-tien-ich.svg` — app bar thương hiệu có nút quay lại, tiêu đề "Tiện ích & Cá nhân hóa", KHÔNG có thanh điều hướng đáy.
- **FR-002**: Màn PHẢI liệt kê đúng **3 nhóm theo thứ tự**: **HIỂN THỊ** gồm Giao diện, Ngôn ngữ, Định dạng & Tiền tệ; **TRẢI NGHIỆM** gồm Widget màn hình chính, Ẩn số dư (Privacy mode), Máy tính khi nhập số tiền; **DỮ LIỆU & TÌM KIẾM** gồm Tìm kiếm toàn cục, Quản lý Tag — tổng **8 hàng**, tiêu đề nhóm viết hoa màu mờ.
- **FR-003**: Mỗi hàng PHẢI hiển thị: **vòng tròn nền nhạt chứa icon màu teal** đúng biểu tượng của mục (bên trái), **tên** mục, **dòng phụ** mô tả (những hàng mockup có) — đối chiếu trực quan với mockup `01`.
- **FR-004**: Hàng **Giao diện** và **Ngôn ngữ** PHẢI hiển thị giá trị hiện hành ở phần cuối ("Hệ thống" / "Tiếng Việt" — mặc định) kèm dấu sang phải; đây là giá trị phản ánh cài đặt hiện tại, không phải chỗ sửa trực tiếp.
- **FR-005**: Các hàng điều hướng — **Giao diện, Ngôn ngữ, Định dạng & Tiền tệ, Tìm kiếm toàn cục, Quản lý Tag** — PHẢI hiển thị đủ dấu sang phải theo mockup nhưng chạm KHÔNG mở màn mới (màn con 02–07 chưa tồn tại), KHÔNG gây lỗi.
- **FR-006**: Công tắc **Ẩn số dư (Privacy mode)** PHẢI mặc định tắt theo mockup; công tắc **Máy tính khi nhập số tiền** PHẢI mặc định bật theo mockup; người dùng PHẢI bật/tắt được và trạng thái PHẢI **được nhớ** khi quay lại màn và cả sau khi khởi động lại app.
- **FR-007**: Bật/tắt công tắc ở FR-006 **KHÔNG được** làm thay đổi hành vi hiển thị/hành vi chức năng ở bất kỳ màn nào khác trong đợt này (che số tiền thật, đổi bàn phím nhập tiền… là PBI sau) — chỉ ghi nhớ lựa chọn.
- **FR-008**: Hàng **Widget màn hình chính** KHÔNG phải công tắc bật/tắt thật: PHẢI hiển thị công tắc ở trạng thái bật theo mockup nhưng chạm không đảo trạng thái; chạm toàn hàng PHẢI hiện **hướng dẫn cách ghim widget** cho nền tảng thiết bị (hệ điều hành quản lý việc ghim, app không tự ghim được).
- **FR-009**: Hàng **Quản lý Tag** PHẢI hiển thị tên, dòng phụ mô tả và dấu sang phải; PHẢI KHÔNG hiển thị con số tag minh họa khi chưa có dữ liệu tag thật (chỉ hiện số đếm khi module tag cung cấp — PBI sau).
- **FR-010**: Màn PHẢI hiển thị đầy đủ, cuộn được và không vỡ bố cục trên các kích thước màn hình, vùng an toàn và cỡ chữ khác nhau; tên/giá trị dài không làm tràn/cắt icon, tên, dòng phụ hay phần cuối hàng.

## Tiêu chí thành công

- **SC-001**: Từ tab Cài đặt, chạm hàng "Tiện ích & Cá nhân hóa" và thấy màn hiển thị đủ 3 nhóm/8 hàng trong không quá 1 giây.
- **SC-002**: Đối chiếu trực quan với `01-danh-sach-tien-ich.svg`: app bar + nút quay lại + tiêu đề, thứ tự 3 nhóm, cấu trúc mỗi hàng (icon trong vòng nhạt trái, tên + dòng phụ, phần cuối) và trạng thái công tắc mặc định hiển thị đúng.
- **SC-003**: Bật "Ẩn số dư" (từ tắt → bật) và tắt "Máy tính khi nhập số tiền" (từ bật → tắt), quay lại rồi mở lại màn, và tắt hẳn app rồi mở lại — trạng thái giữ nguyên 100% ở mọi lần kiểm tra.
- **SC-004**: Các màn khác (Tổng quan, Giao dịch, nhập giao dịch) không thay đổi hành vi sau khi bật/tắt công tắc trong đợt này.
- **SC-005**: Chạm hàng "Widget màn hình chính" luôn hiện hướng dẫn ghim widget, công tắc không đảo; chạm 5 hàng điều hướng còn lại không mở màn lạ, app không lỗi, giá trị "Hệ thống"/"Tiếng Việt" không đổi.
- **SC-006**: Chạm nút quay lại hoặc back hệ thống từ màn Tiện ích đưa về đúng tab Cài đặt, không mất trạng thái; mở lại màn thấy đủ 8 hàng.
- **SC-007**: Với cỡ chữ lớn nhất, màn hình nhỏ và tên/giá trị dài, danh sách cuộn mượt, không vỡ bố cục, không cắt icon/tên/dòng phụ/phần cuối.
- **SC-008**: Hàng "Quản lý Tag" không hiện con số tag minh họa khi chưa có dữ liệu tag thật; không có chữ/số nào gây hiểu nhầm "đã có N tag".

## Thực thể chính

- **Cài đặt cá nhân hóa (lựa chọn tiện ích)**: tập các cờ bật/tắt và giá trị lựa chọn của người dùng cho nhóm Tiện ích — gồm công tắc "Ẩn số dư (Privacy mode)", công tắc "Máy tính khi nhập số tiền", cùng các giá trị hiển thị của hàng "Giao diện" (Hệ thống) và "Ngôn ngữ" (Tiếng Việt). Dữ liệu lưu trên thiết bị, đợt này chỉ cần lưu và đọc lại trạng thái hai công tắc; chưa có hiệu ứng chức năng nào tiêu thụ giá trị này ở màn khác. Các màn con 02–07 và module tag chưa tồn tại nên không phát sinh dữ liệu nghiệp vụ khác trong phạm vi này.

## Giả định

- **Phạm vi đợt này chỉ là màn danh sách (mockup `01`)** — nơi gom điểm vào. Tám màn con (02 giao diện, 03 ngôn ngữ, 04 định dạng & tiền tệ, 05 máy tính, 06 tìm kiếm, 07 quản lý tag) và hiệu ứng thật của từng công tắc là các PBI sau, đúng hướng đã chốt ở tài liệu giải pháp.
- **Hai công tắc "Ẩn số dư" và "Máy tính khi nhập số tiền" là công tắc thật**: bật/tắt được và nhớ trạng thái giữa các lần mở/app; trạng thái mặc định lấy theo mockup (Ẩn số dư = tắt, Máy tính = bật). Hiệu ứng (che `••••••`, đổi bàn phím nhập tiền) để PBI sau.
- **Hàng "Widget màn hình chính" không phải công tắc thật** — theo nghiệp vụ đã chốt (mục 3.4 giải pháp), việc ghim widget do hệ điều hành quản lý nên hàng chỉ mang tính thông tin/nhắc nhở: hiển thị công tắc trạng thái "bật" theo mockup, chạm mở hướng dẫn ghim widget; trạng thái này không lưu.
- **Năm hàng điều hướng (Giao diện, Ngôn ngữ, Định dạng & Tiền tệ, Tìm kiếm toàn cục, Quản lý Tag) là điểm vào no-op** — chạm chưa mở màn con; vẫn giữ đủ hàng, dòng phụ và dấu sang phải theo mockup, nhất quán pattern "màn danh sách chưa kích hoạt điểm vào" đã dùng ở PBI 13.
- **Giá trị "Hệ thống" / "Tiếng Việt" ở phần cuối hàng Giao diện / Ngôn ngữ** phản ánh cài đặt mặc định hiện hành; khi các màn con (PBI sau) cho phép đổi, giá trị này sẽ do cài đặt thật cung cấp. Đợt này hiển thị giá trị mặc định.
- **Con số "12 tag" và dòng phụ "#dulich, #congty, #giadinh…" trong mockup là dữ liệu minh họa**, không phải yêu cầu hiển thị. Hàng Quản lý Tag đợt này hiển thị tên + dòng phụ mô tả; chỉ hiện số đếm tag khi có dữ liệu thật (module tag — PBI sau).
- Hàng "Tiện ích & Cá nhân hóa" được thêm vào **nhóm KHÁC của màn Cài đặt, ngay dưới hàng "Danh mục"** — màn Cài đặt hiện chưa có hàng này.
- Màn này là màn con thuộc shell, không chứa số tiền nên không có rủi ro lộ thông tin thêm; khóa app tuân theo cơ chế chung.

## Quyết định đã chốt

- **Công tắc tương tác thật, nhớ trạng thái, chưa kéo hiệu ứng chức năng** — riêng hai công tắc Ẩn số dư và Máy tính; Widget màn hình chính là ngoại lệ (xem dưới). (đã chốt với người dùng)
- **Hàng "Widget màn hình chính" theo nghiệp vụ §3.4**: không phải công tắc bật/tắt, chạm mở hướng dẫn ghim widget. (đã chốt với người dùng)
- **Năm hàng điều hướng giữ đủ hàng + trailing/chevron theo mockup, chạm không mở gì** — no-op chờ màn con. (đã chốt với người dùng)

## Ngoài phạm vi

- Dựng các **màn con 02–07** (chọn giao diện, ngôn ngữ, định dạng & tiền tệ, máy tính nhập tiền, tìm kiếm toàn cục, quản lý tag) — PBI riêng sau.
- **Hiệu ứng chức năng của công tắc**: Ẩn số dư thật sự che số tiền (`••••••`) ở các màn có số tiền, Máy tính thay bàn phím khi nhập số tiền ở màn thêm giao dịch, Widget ghim/đồng bộ dữ liệu ra home screen.
- Cài đặt **Light/Dark mode** (đổi theme thật), **đa ngôn ngữ** (đổi ngôn ngữ thật), **định dạng ngày/tiền/đầu tuần/kỳ tài chính** — các màn con này khi được dựng sẽ cập nhật giá trị hiển thị ở màn 01.
- **Quản lý tag** (tạo/sửa/xóa/gán tag, đếm tag thật), tìm kiếm toàn cục theo dữ liệu.
- Duy trì/cập nhật giá trị hiển thị của hàng Giao diện/Ngôn ngữ khi người dùng đổi cài đặt — chưa có màn đổi nên chưa phát sinh.
- Dark mode cho chính màn này, giao diện thiết bị lớn/tablet.
