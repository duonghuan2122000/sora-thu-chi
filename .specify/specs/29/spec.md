# Đặc tả tính năng: Cấu hình nhắc nhập giao dịch hằng ngày (màn 02)

**Mã PBI**: 29
**Ngày tạo**: 2026-09-13
**Trạng thái**: Đã làm rõ

## Mô tả tổng quan

PBI 28 đã dựng màn **"Thông báo & nhắc nhở"** với 6 công tắc, nhưng hàng **"Nhắc nhập giao dịch hằng ngày"** mới chỉ **bật/tắt được** — giờ nhắc (20:30), cờ "chỉ nhắc nếu chưa ghi giao dịch" và **các ngày trong tuần** đều là giá trị cố định, người dùng không có chỗ nào chỉnh. Doc nghiệp vụ (`docs/notification/notification-solution.md` §2, loại 1) chốt nhắc hàng ngày bắn **"1 lần/ngày, theo các ngày trong tuần đã chọn"** — tức phải chọn được ngày.

PBI này dựng **màn `02` Cấu hình chi tiết: Nhắc nhập giao dịch hàng ngày** theo mockup `docs/notification/02-cau-hinh-nhac-nhap-giao-dich.svg`: **chọn giờ:phút**, **chọn các ngày trong tuần** (chip tròn T2→CN), **công tắc "chỉ nhắc nếu chưa ghi giao dịch"**, và **khối xem trước nội dung thông báo**.

Đợt này vẫn thuần **cấu hình**: **engine bắn thông báo chưa thuộc phạm vi** (đồng bộ Q1 của PBI 28) — màn **không** xin quyền thông báo, **không** bắn gì, cũng **không** lên lịch. Giá trị người dùng đặt có hiệu lực khi engine ra đời.

Nguyên tắc nền: màn này **chỉ sửa tham số của loại "nhắc nhập giao dịch hằng ngày"** — không chạm 5 loại nhắc còn lại, không chạm dữ liệu nghiệp vụ (giao dịch, ví, danh mục, ngân sách, báo cáo).

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính — Đổi giờ nhắc và ngày lặp

1. Người dùng vào **Cài đặt → Thông báo & nhắc nhở** (màn `01` của PBI 28).
2. Người dùng chạm vào **vùng tiêu đề/dòng phụ** của hàng **"Nhắc nhập giao dịch hằng ngày"** (chạm vào **công tắc** thì chỉ bật/tắt, **không** mở màn) → màn `02` mở ra: app bar **màu thương hiệu** có nút back và tiêu đề **"Nhắc nhập giao dịch"**; **không** có thanh điều hướng đáy và **không** có nút thêm giao dịch.
3. Màn hiện lần lượt theo mockup `02`: nhãn nhóm **THỜI GIAN NHẮC** + khối chọn **giờ : phút**; nhãn nhóm **LẶP LẠI VÀO CÁC NGÀY** + **7 chip tròn** T2 T3 T4 T5 T6 T7 CN; công tắc **"Chỉ nhắc nếu chưa ghi giao dịch"** kèm dòng phụ **"Bỏ qua nhắc nhở nếu hôm nay bạn đã nhập"**; nhãn nhóm **XEM TRƯỚC THÔNG BÁO** + thẻ xem trước; nút **"Lưu thay đổi"**.
4. Các giá trị hiển thị **đọc từ cấu hình đang lưu** (PBI 28): giờ **20:30**, cờ "chỉ nhắc nếu chưa ghi" **bật**, các ngày theo cấu hình đã chọn.
5. Người dùng **tăng giờ** lên **21** (chạm mũi tên trên của trục giờ hoặc cuộn trục) → số giờ ở giữa đổi thành **21**; **phút giữ nguyên** (30); **khối xem trước đổi ngay** thành **21:30**.
6. Người dùng **chạm chip CN** (đang không chọn) → chip **CN** chuyển sang **nền màu thương hiệu, chữ trắng**; các chip còn lại **giữ nguyên**.
7. Người dùng **chạm chip T7** (đang chọn) → chip **T7** về **nền trắng viền xám, chữ xám**; các chip khác **giữ nguyên**. Màn **không** báo lỗi, **không** chặn.
8. Người dùng **tắt** công tắc "Chỉ nhắc nếu chưa ghi giao dịch" → công tắc chuyển xám, chấm sang trái; dòng phụ vẫn hiển thị; khối xem trước **không** đổi nội dung.
9. Người dùng bấm **"Lưu thay đổi"** → giờ, ngày và cờ được ghi lại, màn quay về `01`; hàng **"Nhắc nhập giao dịch hằng ngày"** hiển thị **dòng phụ mới** phản ánh đúng giờ và ngày vừa đặt.
10. Mở lại app (kể cả khởi động lại thiết bị) → mở lại màn `02`: giờ, các ngày được chọn và cờ "chỉ nhắc nếu chưa ghi" **vẫn đúng giá trị đã đặt**.

### Luồng phụ — Bật/tắt nhắc hàng ngày

1. Người dùng **tắt** công tắc "Nhắc nhập giao dịch hằng ngày" ở màn `01` → mở màn `02`: giờ, ngày và cờ **vẫn còn nguyên** giá trị cũ (không reset về mặc định).
2. Người dùng bật lại công tắc ở màn `01` → màn `02` vẫn thấy **đúng tham số cũ**.

### Luồng phụ — Bỏ chọn ngày cuối cùng

1. Người dùng lần lượt **tắt 6 chip**, còn lại **đúng 1 chip** đang bật.
2. Người dùng chạm **chip cuối cùng** đó → chip **vẫn ở trạng thái đang chọn** (không tắt được); màn **không** hiện lỗi, **không** hiện hộp thoại cảnh báo — chỉ đơn giản là không có trạng thái "0 ngày".

### Luồng phụ — Rời màn khi chưa lưu

1. Người dùng đổi giờ từ **20:30** sang **21:00** rồi bấm **nút back** (chưa bấm "Lưu thay đổi") → quay về màn `01`; **không** có hộp thoại hỏi lại, **không** có thông báo; dòng phụ của hàng vẫn ghi **20:30**.
2. Người dùng mở lại màn `02` → giờ hiển thị lại **20:30**; thay đổi đã **bị bỏ**.

### Kịch bản chấp nhận

1. **Given** người dùng đang ở màn `01` **When** chạm vào **vùng tiêu đề/dòng phụ** của hàng "Nhắc nhập giao dịch hằng ngày" **Then** màn `02` mở ra có app bar **màu thương hiệu** + nút back + tiêu đề **"Nhắc nhập giao dịch"**, **không** có thanh điều hướng đáy, **không** có nút thêm giao dịch; và **When** chạm vào **công tắc** của cùng hàng đó **Then** công tắc đổi trạng thái bật/tắt nhưng **màn `02` không mở ra** — hai vùng chạm **không** lẫn nhau.
2. **Given** màn `02` đang mở với vài giá trị vừa đổi **When** người dùng chạm nút **back** (chưa bấm "Lưu thay đổi") **Then** quay về màn `01`, **thay đổi bị bỏ** (dòng phụ giữ giá trị cũ; mở lại màn `02` thấy giá trị cũ), **không** hỏi lại và **không** hiện thông báo; trạng thái 6 công tắc và các hàng khác của màn `01` **không đổi**.
3. **Given** màn `02` vừa mở **When** đối chiếu mockup `02` **Then** có **đủ 4 khối** đúng thứ tự: **THỜI GIAN NHẮC** (khối nền nhạt bo góc chứa trục giờ : phút), **LẶP LẠI VÀO CÁC NGÀY** (7 chip tròn), hàng công tắc **"Chỉ nhắc nếu chưa ghi giao dịch"** + dòng phụ, **XEM TRƯỚC THÔNG BÁO** (thẻ nội dung) — và nút **"Lưu thay đổi"** ở cuối.
4. **Given** màn `02` vừa mở **When** xem khối thời gian **Then** giờ và phút hiển thị **hai trục riêng** ngăn bởi dấu **":"**; mỗi trục có **mũi tên tăng ở trên và mũi tên giảm ở dưới**; giá trị **đang chọn nằm giữa, cỡ lớn, màu thương hiệu**; giá trị **lân cận mờ hơn**; có **dải nền nhạt** đánh dấu hàng đang chọn.
5. **Given** giờ đang là 20:30 **When** người dùng chạm mũi tên **tăng** của trục giờ **Then** giờ thành **21**, **phút giữ nguyên 30**. Chạm mũi tên **giảm** đủ 21 lần từ 00 → giờ về **23** (quay vòng, không kẹt ở 0). Làm tương tự với trục phút: 59 → 00 và 00 → 59.
6. **Given** khối xem trước đang ghi **20:30** **When** người dùng đổi giờ thành **07:05** **Then** khối xem trước hiển thị **07:05** **ngay lập tức**, **không** cần bấm Lưu và **không** cần rời màn.
7. **Given** màn `02` vừa mở **When** xem 7 chip **Then** đủ **T2 T3 T4 T5 T6 T7 CN** theo thứ tự; chip **đang chọn** nền **màu thương hiệu** chữ **trắng**; chip **không chọn** nền **trắng** viền xám chữ xám; các chip **cách đều** nhau và **không** bị cắt trên màn hình hẹp.
8. **Given** chip **CN** đang không chọn **When** chạm vào **Then** chip CN chuyển sang **đang chọn**; **6 chip còn lại giữ nguyên** trạng thái.
9. **Given** chip **T7** đang chọn **When** chạm vào **Then** chip T7 về **không chọn**; **6 chip còn lại giữ nguyên** trạng thái.
10. **Given** chỉ còn **đúng 1 chip** đang chọn **When** chạm chip đó **Then** chip **vẫn đang chọn** (trạng thái "0 ngày" **không** tồn tại); màn **không** hiện lỗi, **không** hiện hộp thoại.
11. **Given** màn `02` vừa mở **When** xem hàng công tắc **Then** có tiêu đề **"Chỉ nhắc nếu chưa ghi giao dịch"**, dòng phụ **"Bỏ qua nhắc nhở nếu hôm nay bạn đã nhập"**, và công tắc bên phải phản ánh **đúng giá trị đang lưu** của cờ này.
12. **Given** cờ đang **bật** **When** người dùng tắt rồi bấm **"Lưu thay đổi"** **Then** mở lại màn `02` thấy cờ **tắt**; các giá trị giờ/ngày **không** bị ảnh hưởng.
13. **Given** người dùng đã đổi giờ/ngày rồi bấm **"Lưu thay đổi"** **When** quay về màn `01` **Then** dòng phụ của hàng "Nhắc nhập giao dịch hằng ngày" hiển thị **giờ mới** và **các ngày mới** (VD "21:30 T2–T7, CN · chỉ nhắc nếu chưa ghi" khi CN vừa được thêm).
14. **Given** người dùng đã lưu cấu hình **When** thoát app rồi mở lại (kể cả khởi động lại thiết bị) **Then** màn `02` hiển thị **đúng** giờ, đúng tập ngày, đúng cờ đã đặt — **0** giá trị quay về mặc định.
15. **Given** app **mới cài, chưa từng đặt gì** **When** mở màn `02` lần đầu **Then** hiển thị **giờ 20:30**, cờ "chỉ nhắc nếu chưa ghi" **bật**, và **cả 7 chip T2→CN đều đang chọn** (nghĩa "mỗi ngày"); dòng phụ ở màn `01` vẫn ghi dạng **"mỗi ngày"**.
16. **Given** app đã có cấu hình lưu từ trước PBI này (chưa từng có thông tin ngày trong tuần) **When** mở màn `02` **Then** màn hiển thị **đúng** giờ và cờ đang lưu (không mất dữ liệu cũ), và **cả 7 ngày** ở trạng thái đang chọn (mặc định Q3) — màn **không** trắng, **không** báo lỗi.
17. **Given** màn `02` đang mở **When** người dùng đổi giờ/ngày/cờ **Then** **chỉ** cấu hình của loại "nhắc nhập giao dịch hằng ngày" thay đổi; **5 loại nhắc còn lại** (ngân sách, giao dịch định kỳ, mục tiêu, tổng kết tuần, tổng kết tháng) và **trạng thái thêm giao dịch/ví/danh mục/ngân sách/báo cáo** **không** đổi.
18. **Given** người dùng dùng màn `02` trong ngày **When** dùng app tiếp (thêm giao dịch, mở báo cáo, để app ở nền) **Then** **0** thông báo được bắn ra và app **0** lần hỏi quyền thông báo — đợt này chỉ ghi nhận cấu hình.
19. **Given** app đang ở **English** (PBI 19) **When** mở màn `02` **Then** toàn bộ **nhãn tĩnh** (tiêu đề app bar, 3 nhãn nhóm, tiêu đề hàng công tắc, dòng phụ, nút "Lưu thay đổi", nội dung khối xem trước, **nhãn 7 chip ngày**) hiển thị bằng **tiếng Anh**, **không** còn sót tiếng Việt; **định dạng giờ HH:mm không đổi** theo ngôn ngữ.
20. **Given** app đang ở **chế độ Tối** (PBI 18) **When** mở màn `02` **Then** nền, chữ, nhãn nhóm, khối thời gian, chip, công tắc, thẻ xem trước, nút Lưu dùng đúng bộ màu chế độ Tối và vẫn đủ tương phản đọc được.
21. **Given** màn hình nhỏ và cỡ chữ lớn nhất **When** xem màn `02` **Then** bố cục không vỡ: 7 chip **không** bị tràn/cắt, trục giờ–phút và thẻ xem trước không đè nhau, và **cuộn tới được** nút "Lưu thay đổi".
22. **Given** màn `02` đang mở **When** người dùng bấm **"Lưu thay đổi"** mà **không** đổi giá trị nào **Then** màn quay về `01`, **không** hiện thông báo, **không** có giá trị nào bị đổi (nút luôn bấm được).

### Trường hợp biên

- **Chỉ còn 1 ngày được chọn rồi người dùng bỏ chọn** → chip **không tắt**; không có trạng thái "không nhắc ngày nào" trong khi công tắc vẫn bật (kịch bản 10).
- **Quay vòng trục giờ/phút** → 23 → 00 và 00 → 23; 59 → 00 và 00 → 59; không kẹt, không lỗi (kịch bản 5).
- **Rời màn `02` bằng nút back sau khi đã đổi giá trị nhưng chưa lưu** → thay đổi **bị bỏ**, quay về màn `01` với giá trị cũ; **không** hỏi lại, **không** hiện thông báo (Q2 chọn A).
- **Bấm "Lưu thay đổi" khi không đổi gì** → quay về màn `01`, không thông báo, không ghi thêm gì ngoài giá trị hiện có.
- **Cấu hình lưu từ trước PBI này** (thiếu thông tin ngày trong tuần) → màn vẫn mở bình thường, ngày dùng mặc định Q3, giờ và cờ giữ nguyên giá trị cũ (kịch bản 16).
- **Cấu hình lưu bị hỏng/thiếu trường** → màn dùng giá trị mặc định của **từng trường** sai lệch, không làm trắng cả màn (đồng bộ cách xử lý tolerant của PBI 28).
- **Múi giờ thiết bị đổi** → giờ nhắc và tập ngày **không** đổi giá trị; cách engine diễn giải múi giờ là quyết định mở đã biết của dự án, không giải quyết ở đây.
- **Người dùng chạm liên tục vào mũi tên/trục** → giá trị thay đổi mượt, không lỗi, không treo, không nhảy giá trị ngoài miền 0–23 / 0–59.
- **Người dùng mong chờ thông báo bắn ra** sau khi lưu → đợt này **không** có thông báo nào (xem "Ngoài phạm vi"); màn **không** hứa hẹn gì thêm ngoài giá trị cấu hình.
- **Cỡ chữ lớn / màn hẹp** → chip xuống hàng hoặc thu nhỏ khoảng cách nhưng **không** cắt nhãn; khối xem trước xuống dòng gọn.
- **Không có mạng** → màn hoạt động đầy đủ, cấu hình vẫn lưu và khôi phục bình thường.

## Yêu cầu chức năng

- **FR-001**: Hàng **"Nhắc nhập giao dịch hằng ngày"** ở màn `01` PHẢI có **hai vùng chạm tách biệt**: chạm **vùng tiêu đề/dòng phụ** mở màn `02` bằng **đúng 1 lần chạm**; chạm **công tắc** chỉ bật/tắt loại nhắc đó và **KHÔNG** mở màn `02`; chạm vùng tiêu đề **KHÔNG** làm đổi trạng thái công tắc. [Q1 chọn B]
- **FR-002**: Màn `02` PHẢI là **trang con** theo mockup `02`: app bar **màu thương hiệu** có **nút back** và tiêu đề **"Nhắc nhập giao dịch"**; **không** có thanh điều hướng đáy và **không** có nút thêm giao dịch.
- **FR-003**: Màn PHẢI có khối **THỜI GIAN NHẮC** cho chọn **giờ (0–23)** và **phút (0–59)**; mỗi trục có **mũi tên tăng ở trên, giảm ở dưới**, giá trị đang chọn **nổi bật bằng màu thương hiệu** ở giữa, giá trị lân cận **mờ hơn**, có **dải nền nhạt** đánh dấu hàng đang chọn; trục PHẢI **quay vòng** ở hai đầu (không kẹt ở 0 hoặc giá trị lớn nhất).
- **FR-004**: Màn PHẢI có khối **LẶP LẠI VÀO CÁC NGÀY** gồm **đúng 7 chip tròn** thứ tự **T2 → CN**; chip **đang chọn** nền **màu thương hiệu** chữ **trắng**, chip **không chọn** nền **trắng** viền xám chữ xám; **chạm là đổi trạng thái ngay**.
- **FR-005**: Màn PHẢI có hàng công tắc **"Chỉ nhắc nếu chưa ghi giao dịch"** kèm dòng phụ **"Bỏ qua nhắc nhở nếu hôm nay bạn đã nhập"**; công tắc phản ánh **đúng** cờ đang lưu và đổi **chỉ** cờ đó.
- **FR-006**: Màn PHẢI có khối **XEM TRƯỚC THÔNG BÁO** mô phỏng một thông báo hệ thống: **icon tròn nền nhạt + tên app "Sora Thu Chi" + dòng nội dung "Đừng quên ghi lại thu chi hôm nay nhé!" + giờ ở góc phải**; **giờ trong khối xem trước PHẢI cập nhật ngay** khi người dùng đổi giờ nhắc (chưa cần bấm Lưu).
- **FR-007**: Màn `02` PHẢI có nút **"Lưu thay đổi"** ở cuối màn; giờ, tập ngày và cờ **CHỈ** được ghi khi bấm nút này. Rời màn bằng **back** khi chưa lưu PHẢI **bỏ** thay đổi và **KHÔNG** hiện hộp thoại hỏi lại hay thông báo. Nút PHẢI **luôn bấm được**, kể cả khi chưa đổi giá trị nào. [Q2 chọn A]
- **FR-008**: Khi **chưa từng cấu hình**, màn PHẢI hiển thị giờ **20:30**, cờ "chỉ nhắc nếu chưa ghi" **bật**, và tập ngày mặc định là **cả 7 ngày T2→CN** (nghĩa "mỗi ngày"). [Q3 chọn A]
- **FR-009**: Hệ thống PHẢI **luôn giữ ít nhất 1 ngày** được chọn: chạm vào chip **đang chọn cuối cùng** KHÔNG làm nó tắt; KHÔNG tồn tại trạng thái "0 ngày".
- **FR-010**: Màn PHẢI **chỉ** đọc/ghi cấu hình của loại **"nhắc nhập giao dịch hằng ngày"** (giờ, phút, tập ngày, cờ "chỉ nhắc nếu chưa ghi") — **KHÔNG** chạm tham số hay trạng thái của **5 loại nhắc còn lại**, và **KHÔNG** có cơ chế "bật/tắt tất cả".
- **FR-011**: **Dòng phụ** của hàng "Nhắc nhập giao dịch hằng ngày" ở màn `01` PHẢI phản ánh **cấu hình đang lưu** (giờ, tập ngày, cờ) và PHẢI được **đọc lại mỗi lần màn mở** — không giữ bản cứng; khi tập ngày là **đủ 7 ngày** dòng phụ ghi dạng **"mỗi ngày"**, khi thiếu ngày nào thì liệt kê các ngày đang chọn.
- **FR-012**: Cấu hình PHẢI **lưu bền trên thiết bị** và khôi phục đúng sau khi đóng/mở lại app hay khởi động lại thiết bị; **tắt rồi bật lại** công tắc nhắc hàng ngày ở màn `01` KHÔNG được reset giờ/ngày/cờ về mặc định.
- **FR-013**: Cấu hình lưu từ **trước PBI này** (chưa có thông tin ngày trong tuần) PHẢI đọc ra dùng được: giờ và cờ giữ **đúng giá trị cũ**, tập ngày dùng **mặc định cả 7 ngày**; cấu hình **hỏng/thiếu trường** PHẢI rơi về mặc định **của riêng trường đó**, KHÔNG làm trắng màn và KHÔNG báo lỗi.
- **FR-014**: Đợt này màn PHẢI **chỉ ghi nhận cấu hình**: đổi giờ/ngày/cờ KHÔNG bắn thông báo nào, KHÔNG lên lịch, KHÔNG xin quyền thông báo; màn KHÔNG hiển thị nhắc nhở gì về quyền thông báo của hệ điều hành.
- **FR-015**: Mọi **nhãn tĩnh** của màn (tiêu đề app bar, 3 nhãn nhóm, tiêu đề hàng công tắc, dòng phụ, nút "Lưu thay đổi", nội dung khối xem trước, **nhãn 7 chip ngày**) PHẢI có bản dịch **Tiếng Việt / English** theo ngôn ngữ đang chọn (PBI 19); **định dạng giờ HH:mm KHÔNG** đổi theo ngôn ngữ.
- **FR-016**: Màn PHẢI hiển thị đúng bộ màu của **chế độ Sáng/Tối** đang chọn (PBI 18) — nền, chữ, nhãn nhóm, khối thời gian, chip, công tắc, thẻ xem trước, nút Lưu — đảm bảo đủ tương phản.
- **FR-017**: Màn PHẢI **không vỡ bố cục** trên các kích thước màn hình, vùng an toàn và cỡ chữ khác nhau: 7 chip không bị tràn/cắt, khối thời gian và thẻ xem trước không đè nhau, nội dung **cuộn được** tới nút "Lưu thay đổi".
- **FR-018**: Màn KHÔNG được làm thay đổi dữ liệu nghiệp vụ (giao dịch, ví, danh mục, ngân sách) — nó chỉ đọc/ghi cấu hình thông báo của chính nó.

## Tiêu chí thành công

- **SC-001**: Đối chiếu trực quan với `02-cau-hinh-nhac-nhap-giao-dich.svg`: **100%** thành phần (app bar teal + back + tiêu đề, khối thời gian 2 trục + dấu ":", 7 chip ngày, hàng công tắc + dòng phụ, thẻ xem trước, nút "Lưu thay đổi") hiển thị đúng vị trí, đúng nội dung, đúng màu ngữ nghĩa (màu thương hiệu chỉ dùng cho giá trị đang chọn, chip đang chọn và nút chính).
- **SC-002**: Từ màn `01`, người dùng tới màn `02` bằng **đúng 1 lần chạm** và quay lại bằng **1 lần chạm**.
- **SC-003**: **100%** lần đổi giờ hoặc phút cho kết quả đúng miền 0–23 / 0–59 và **quay vòng** đúng ở hai đầu (0 sai lệch sau khi thử cả hai chiều ở cả hai đầu mút).
- **SC-004**: Khối xem trước cập nhật giờ **trong cùng một nhịp chạm** — độ trễ cảm nhận **0 giây**, **0** trường hợp phải bấm Lưu mới thấy giờ mới.
- **SC-005**: **100%** lần chạm chip chỉ ảnh hưởng **đúng chip đó** — đổi từng chip một và đối chiếu 6 chip còn lại (0 sai lệch); **0** trường hợp tắt được chip cuối cùng.
- **SC-006**: Sau khi đặt cấu hình rồi **khởi động lại app (và thiết bị)**, **100%** giá trị (giờ, tập ngày, cờ) hiển thị **đúng** đã đặt.
- **SC-007**: Tắt rồi bật lại công tắc nhắc hàng ngày ở màn `01`: **100%** trường hợp màn `02` còn **đúng tham số cũ** (0 trường hợp reset mặc định).
- **SC-008**: Với cấu hình lưu từ bản trước (thiếu thông tin ngày), màn `02` mở được **100%** trường hợp, giờ và cờ **không** đổi giá trị, **0** màn trắng.
- **SC-009**: Sau khi dùng màn `02`: **0** thông báo được bắn, **0** lần app hỏi quyền thông báo, **0** lịch nhắc được tạo.
- **SC-010**: **100%** giá trị của 5 loại nhắc còn lại và của dữ liệu nghiệp vụ (giao dịch, ví, danh mục, ngân sách) **không đổi** sau khi dùng màn `02` (0 sai lệch khi đối chiếu trước/sau).
- **SC-011**: Ở **English**, **0** nhãn tĩnh tiếng Việt còn sót trên màn (kể cả 7 nhãn chip ngày); ở **chế độ Tối**, **100%** chữ và phần tử điều khiển đạt tương phản đọc được.
- **SC-012**: Với **cỡ chữ lớn nhất** và **màn hình nhỏ**, màn không vỡ bố cục, 7 chip không bị cắt, và cuộn tới được nút "Lưu thay đổi" ở **100%** lần kiểm tra.
- **SC-013**: Người dùng hoàn tất việc đổi giờ nhắc và ngày lặp trong **dưới 30 giây**, không cần hướng dẫn.
- **SC-014**: **100%** thay đổi chỉ được ghi khi bấm "Lưu thay đổi": rời màn bằng back sau khi đã đổi giá trị → mở lại thấy **đúng giá trị cũ** (0 trường hợp ghi ngầm, 0 hộp thoại hỏi lại).

## Thực thể chính

- **Cấu hình thông báo** (bản ghi đã có từ PBI 28, lưu bền trên thiết bị; PBI này **bổ sung** phần tham số của loại "nhắc nhập giao dịch hằng ngày"): **giờ** (0–23), **phút** (0–59), **cờ "chỉ nhắc nếu chưa ghi giao dịch trong ngày"**, và **tập ngày trong tuần được chọn** (tập con **khác rỗng** của 7 ngày, mặc định **cả 7 ngày**). Các tham số của 5 loại nhắc còn lại (ngưỡng ngân sách, số ngày nhắc trước, giờ tổng kết tuần/tháng...) **giữ nguyên**, không bị màn này chạm tới. Đợt này **chỉ ghi và hiển thị** — chưa có thành phần nào đọc chúng để bắn thông báo.

## Giả định

- **Tên PBI "màn hình cấu hình nhắc nhập giao dịch"** được hiểu là **màn `02`** đã được PBI 28 liệt kê trong "Ngoài phạm vi" (Q2 chọn A khi đó) — phạm vi lấy đúng mockup `02-cau-hinh-nhac-nhap-giao-dich.svg`; **màn `03` Trung tâm thông báo** và **engine bắn thông báo** vẫn **không** thuộc PBI này.
- **Màn `02` KHÔNG có công tắc bật/tắt "Nhắc nhập giao dịch hằng ngày"**: mockup không vẽ; việc bật/tắt vẫn nằm ở hàng công tắc của màn `01` (PBI 28), màn `02` chỉ sửa **tham số**.
- **Khối xem trước là mô phỏng tĩnh một thông báo** (tên app + một câu nội dung) — nội dung câu **không** đổi theo cờ "chỉ nhắc nếu chưa ghi" hay theo tập ngày, chỉ **giờ** đổi theo lựa chọn.
- **Thời gian trong ngày, ngày trong tuần bắt đầu từ Thứ Hai** (đồng bộ quy ước tuần của module Báo cáo) — thứ tự chip là T2 → CN.
- **Chọn giờ/phút theo bước 1 đơn vị** trên trục cuộn (đủ 0–59 phút); mockup chỉ vẽ vài giá trị lân cận để minh hoạ trục, không phải giới hạn bước nhảy.
- **Nhãn chip ngày** hiển thị dạng ngắn (T2…CN ở tiếng Việt; Mon…Sun ở tiếng Anh) — mockup chỉ có bản tiếng Việt.
- **Điểm vào màn `02` là vùng tiêu đề/dòng phụ của hàng công tắc** (Q1 chọn B): mockup `01` **không** phải sửa, hàng vẫn là hàng công tắc, và màn `02` **không** có thêm công tắc bật/tắt loại nhắc này. Vùng chạm mở màn là **cả hàng trừ công tắc** (chạm icon, tiêu đề hay dòng phụ đều mở màn); đây là affordance ngầm nên màn `01` **không** thêm chỉ dấu chevron (giữ đúng mockup `01`).
- **Màn `02` không dùng hộp thoại chọn giờ của hệ điều hành** — mockup vẽ trục cuộn tại chỗ, nên màn tự dựng khối chọn giờ/phút theo mockup.
- **Khoá app (PIN) không ảnh hưởng màn này**: màn chỉ mở được sau khi đã mở khóa app (PBI 3).
- **Không có đồng bộ/tài khoản**: cấu hình chỉ nằm trên thiết bị này, không đi kèm backup/restore JSON (GĐ3).
- **Trạng thái công tắc nhắc hàng ngày ở màn `01` không bị màn `02` thay đổi** — kể cả khi người dùng đổi giờ/ngày, công tắc vẫn giữ nguyên trạng thái bật/tắt.

## Ngoài phạm vi

- **Toàn bộ engine bắn thông báo thật** (đồng bộ Q1 của PBI 28): lên lịch nhắc theo giờ, kiểm tra "hôm nay đã ghi giao dịch chưa" trước khi bắn, quay vòng theo ngày trong tuần đã chọn, chống bắn trùng, nội dung nhắc kèm số liệu, deep link khi tap thông báo.
- **Mọi thứ liên quan tới quyền thông báo của hệ điều hành**: xin quyền, soft-ask trong onboarding, cảnh báo khi bị chặn quyền, notification channel riêng theo loại, hướng dẫn autostart.
- **Chỉnh tham số của các loại nhắc khác**: ngưỡng cảnh báo ngân sách, số ngày nhắc trước giao dịch định kỳ, giờ tổng kết tuần/tháng (2 hàng chevron của màn `01` vẫn là điểm nối no-op — Q2 của PBI 28).
- **Màn `03` Trung tâm thông báo trong app** (lịch sử thông báo, chấm chưa đọc, nhóm theo thời gian) và **mockup `04` mẫu thông báo đẩy**.
- **Tuỳ chọn "nhắc thêm lần hai trong ngày", nhiều khung giờ cho cùng một ngày, hay nhắc theo khoảng (VD mỗi 2 giờ)** — doc nghiệp vụ §2 chốt **1 lần/ngày**.
- **Sửa nội dung thông báo / đổi tên app trong thông báo** — nội dung vẫn theo mẫu của doc và mockup.
- **Âm thanh, rung, kiểu hiển thị thông báo** (màn `04` chỉ là mẫu minh hoạ).
- **Hộp thoại xác nhận "bỏ thay đổi chưa lưu"** khi rời màn `02` — Q2 chọn A nên back **bỏ** thay đổi luôn, không hỏi lại (điểm nối nếu sau này muốn thêm).
- **Ghi nhớ cấu hình vào file backup/restore JSON** (GĐ3).

## Quyết định đã chốt

- **Q1 — chọn B: điểm vào màn `02` là chạm vùng tiêu đề/dòng phụ của hàng công tắc "Nhắc nhập giao dịch hằng ngày"** — công tắc giữ nguyên chức năng bật/tắt, mockup `01` **không** đổi (không thêm hàng chevron, không thêm chỉ dấu chevron vào hàng). (chốt 2026-09-13)
- **Q2 — chọn A: màn `02` có nút "Lưu thay đổi" như mockup** — giờ/ngày/cờ **chỉ** ghi khi bấm; back khi chưa lưu **bỏ** thay đổi, không hỏi lại, không thông báo. (chốt 2026-09-13)
- **Q3 — chọn A: tập ngày mặc định là cả 7 ngày (T2→CN)** — giữ đúng nghĩa "20:30 mỗi ngày" của PBI 28 và không làm máy đã cài mất nhắc Chủ nhật khi engine ra đời; chip CN ở trạng thái tắt trong mockup `02` là **minh hoạ trạng thái**, không phải giá trị mặc định. (chốt 2026-09-13)
