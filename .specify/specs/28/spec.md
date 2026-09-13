# Đặc tả tính năng: Cài đặt Thông báo & nhắc nhở (màn Cài đặt)

**Mã PBI**: 28
**Ngày tạo**: 2026-09-13
**Trạng thái**: Đã làm rõ

## Mô tả tổng quan

App chưa có chỗ nào để người dùng **kiểm soát nhắc nhở**: doc nghiệp vụ thông báo (`docs/notification/notification-solution.md`) đã chốt 5 loại thông báo nhưng **chưa có màn hình nào** cho người dùng bật/tắt hay xem tham số. PBI này dựng **màn "Thông báo & nhắc nhở"** — trang con mở từ Cài đặt, theo mockup `docs/notification/01-cai-dat-thong-bao.svg`: **5 nhóm** (Nhắc nhở hàng ngày, Ngân sách, Giao dịch định kỳ, Mục tiêu tiết kiệm, Tổng kết tự động), **6 công tắc độc lập** và **2 hàng cấu hình chi tiết**; mỗi hàng có dòng phụ tóm tắt cấu hình đang áp dụng (VD "20:30 mỗi ngày · chỉ nhắc nếu chưa ghi").

Đợt này làm **phần cấu hình**: màn hình + lưu bền lựa chọn của người dùng. **Engine bắn thông báo thật chưa thuộc đợt này** (Q1 chọn A) — công tắc là **cấu hình đặt trước**, có hiệu lực khi engine ra đời; màn **không** xin quyền thông báo và **không** bắn gì.

Nguyên tắc nền: **mỗi loại thông báo có công tắc riêng, người dùng toàn quyền** — không có cơ chế "bật tất cả", tắt một loại không ảnh hưởng loại khác, và **việc ghi chép thu chi không bao giờ bị chặn** dù tắt hết thông báo.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính — Xem và đổi một công tắc

1. Người dùng vào tab **Cài đặt** → chạm hàng **"Thông báo & nhắc nhở"** → màn mở ra theo mockup `01`: app bar màu thương hiệu có nút back và tiêu đề **"Thông báo & nhắc nhở"**.
2. Màn hiện **5 nhóm** theo thứ tự mockup, mỗi nhóm có nhãn viết hoa mờ: **NHẮC NHỞ HÀNG NGÀY**, **NGÂN SÁCH**, **GIAO DỊCH ĐỊNH KỲ**, **MỤC TIÊU TIẾT KIỆM**, **TỔNG KẾT TỰ ĐỘNG**.
3. Mỗi hàng gồm: **icon tròn nền nhạt** bên trái, **tiêu đề**, **dòng phụ mô tả cấu hình**, và bên phải **hoặc** một **công tắc** **hoặc** một **mũi tên (chevron)** — không hàng nào có cả hai.
4. Dòng phụ phản ánh cấu hình đang áp dụng: nhắc hàng ngày ghi **"20:30 mỗi ngày · chỉ nhắc nếu chưa ghi"**; cảnh báo ngân sách ghi **"Khi đạt 80% và khi vượt 100%"**; nhắc hóa đơn ghi **"Tiền điện, tiền nhà, trả nợ..."**; nhắc đóng góp mục tiêu ghi **"Theo chu kỳ đã đặt cho từng mục tiêu"**; tổng kết tuần ghi **"Chủ nhật hằng tuần, 20:00"**; tổng kết tháng ghi **"Ngày cuối tháng, 20:00"**.
5. Người dùng chạm công tắc **"Nhắc đóng góp mục tiêu"** (mặc định **đang tắt**) → công tắc chuyển sang **bật** (nền màu thương hiệu, chấm trắng bên phải); các công tắc còn lại **giữ nguyên** trạng thái.
6. Người dùng chạm công tắc **"Cảnh báo vượt ngân sách"** để **tắt** → nền công tắc chuyển xám, chấm sang trái; dòng phụ và hàng cấu hình "Ngưỡng cảnh báo" **vẫn hiển thị** giá trị đang lưu (không bị xoá, không reset).
7. Người dùng chạm nút **back** → quay về màn **Cài đặt**; mở lại app sau đó, các công tắc **vẫn đúng trạng thái đã đặt**.

### Luồng phụ — Tắt hết thông báo rồi bật lại một loại

1. Người dùng tắt **toàn bộ 6 công tắc** → màn không có thông báo lỗi, không chặn gì; app **vẫn ghi giao dịch bình thường**.
2. Người dùng bật lại **"Nhắc nhập giao dịch hằng ngày"** → công tắc về đúng trạng thái bật, **tham số cũ** (20:30, chỉ nhắc nếu chưa ghi) vẫn còn nguyên, **không** quay về giá trị mặc định.

### Kịch bản chấp nhận

1. **Given** người dùng đang ở tab **Cài đặt** **When** chạm hàng **"Thông báo & nhắc nhở"** **Then** màn **Thông báo & nhắc nhở** mở ra bằng **đúng 1 lần chạm**, có app bar màu thương hiệu + nút back + tiêu đề "Thông báo & nhắc nhở", **không** có thanh điều hướng đáy và **không** có nút thêm giao dịch.
2. **Given** màn Thông báo & nhắc nhở đang mở **When** người dùng chạm nút **back** **Then** quay về màn **Cài đặt**, các hàng khác của Cài đặt **không đổi** trạng thái.
3. **Given** màn vừa mở **When** đối chiếu với mockup `01` **Then** có **đủ 5 nhóm** đúng thứ tự và đúng nhãn nhóm (NHẮC NHỞ HÀNG NGÀY → NGÂN SÁCH → GIAO DỊCH ĐỊNH KỲ → MỤC TIÊU TIẾT KIỆM → TỔNG KẾT TỰ ĐỘNG), đủ **8 hàng**: 6 hàng có công tắc (Nhắc nhập giao dịch hằng ngày; Cảnh báo vượt ngân sách; Nhắc hóa đơn sắp đến hạn; Nhắc đóng góp mục tiêu; Tổng kết cuối tuần; Tổng kết cuối tháng) và 2 hàng có chevron (Ngưỡng cảnh báo; Nhắc trước).
4. **Given** màn vừa mở **When** xem từng hàng **Then** hàng nào cũng có **icon tròn nền nhạt + tiêu đề + dòng phụ**, và **hàng nhóm Ngân sách dùng sắc coral** cho icon (ngữ cảnh cảnh báo chi tiêu), các hàng còn lại dùng **sắc teal**.
5. **Given** màn vừa mở **When** xem bên phải mỗi hàng **Then** mỗi hàng có **đúng một** phần tử điều khiển: **công tắc** (6 hàng) **hoặc** **chevron** (2 hàng) — không hàng nào có cả hai, không hàng nào để trống.
6. **Given** app **mới cài, chưa từng đặt gì** **When** mở màn lần đầu **Then** trạng thái mặc định là: **Nhắc nhập giao dịch hằng ngày = bật (20:30 mỗi ngày, cờ "chỉ nhắc nếu chưa ghi giao dịch nào trong ngày" = bật)**, **Cảnh báo vượt ngân sách = bật (ngưỡng sớm 80%, vượt mức 100%)**, **Nhắc hóa đơn sắp đến hạn = bật (nhắc trước 3 ngày)**, **Nhắc đóng góp mục tiêu = tắt**, **Tổng kết cuối tuần = bật (Chủ nhật 20:00)**, **Tổng kết cuối tháng = bật (ngày cuối tháng 20:00)** — và các giá trị này **được lưu lại** ngay, không phải chờ người dùng thao tác.
7. **Given** một công tắc đang bật **When** người dùng tắt nó **Then** **chỉ** hàng đó đổi trạng thái; **mọi công tắc khác giữ nguyên**, **và** tham số cấu hình của loại vừa tắt **không bị xoá** (bật lại thấy đúng tham số cũ).
8. **Given** người dùng đã đổi vài công tắc **When** thoát app rồi mở lại (kể cả khởi động lại thiết bị) **Then** màn hiển thị **đúng** trạng thái đã đặt — cấu hình **không** mất khi đóng app.
9. **Given** cấu hình đang lưu có giá trị cụ thể (VD ngưỡng 80%/100%, nhắc trước 3 ngày, giờ 20:30) **When** mở màn **Then** **dòng phụ** của từng hàng hiển thị đúng các giá trị đó — dòng phụ **đọc lại cấu hình khi màn mở**, không giữ bản cứng trong màn.
10. **Given** hàng **"Ngưỡng cảnh báo"** (nhóm Ngân sách) đang hiển thị "Sớm: 80% · Vượt mức: 100%" **When** người dùng chạm hàng **Then** **không** có màn nào mở ra và **không** có thông báo lỗi/khung "sắp có" — hàng chỉ hiển thị giá trị đang lưu (điểm nối màn chỉnh ngưỡng để PBI sau).
11. **Given** hàng **"Nhắc trước"** (nhóm Giao dịch định kỳ) đang hiển thị "3 ngày trước hạn thanh toán" **When** người dùng chạm hàng **Then** hành xử **giống kịch bản 10** — hiển thị giá trị, chưa mở luồng chỉnh sửa.
12. **Given** người dùng bật hoặc tắt **bất kỳ** công tắc nào **When** dùng app tiếp trong ngày (thêm giao dịch, mở báo cáo, dùng app ở nền) **Then** **không** có thông báo nào được bắn ra và app **không** hỏi quyền thông báo — đợt này thao tác chỉ ghi nhận cấu hình.
13. **Given** người dùng cấp quyền hay chặn quyền thông báo ở cài đặt hệ điều hành **When** mở màn Thông báo & nhắc nhở **Then** màn hiển thị **giống nhau** trong cả hai trường hợp (không có dòng nào nhắc về quyền hệ thống trong đợt này).
14. **Given** người dùng **tắt toàn bộ** công tắc **When** sử dụng app **Then** mọi chức năng khác (thêm/sửa giao dịch, ví, danh mục, ngân sách, báo cáo) **không** bị ảnh hưởng hay chặn.
15. **Given** các module **Mục tiêu tiết kiệm (GĐ3)** và **Giao dịch định kỳ** **chưa tồn tại** trong app **When** người dùng xem và bật/tắt hai nhóm hàng tương ứng **Then** thao tác **vẫn thành công và được ghi nhớ** như mọi hàng khác; màn **không** ghi "sắp có"/"chưa hỗ trợ" và **không** vô hiệu hoá công tắc.
16. **Given** app đang ở **English** (PBI 19) **When** mở màn Thông báo & nhắc nhở **Then** toàn bộ **nhãn tĩnh** (tiêu đề app bar, 5 nhãn nhóm, 8 tiêu đề hàng, các dòng phụ dạng mô tả) hiển thị bằng **tiếng Anh**, **không** còn sót tiếng Việt; **giờ và định dạng ngày/số không đổi** theo ngôn ngữ.
17. **Given** app đang ở **chế độ Tối** (PBI 18) **When** mở màn **Then** nền, chữ, nhãn nhóm, icon, công tắc (bật/tắt) dùng đúng bộ màu của chế độ Tối và vẫn đủ tương phản.
18. **Given** màn hình nhỏ và cỡ chữ lớn nhất **When** xem màn **Then** bố cục không vỡ: tiêu đề hàng dài và dòng phụ dài **xuống dòng gọn**, không đè lên công tắc/chevron, và **cuộn tới được** hàng cuối cùng.
19. **Given** người dùng vừa đổi công tắc **When** so sánh với dữ liệu nghiệp vụ trước đó (danh sách giao dịch, ngân sách, ví, báo cáo) **Then** **không** có dữ liệu nào bị thay đổi hay thêm/xoá bởi màn này.

### Trường hợp biên

- **Chưa từng mở màn bao giờ** → màn dùng đúng bộ giá trị mặc định ở kịch bản 6 (không có trạng thái "chưa cấu hình" nào hiển thị ra cho người dùng); các giá trị mặc định được ghi lại trong lần mở đầu.
- **Tắt một hàng rồi xem hàng cấu hình của nó** (VD tắt "Cảnh báo vượt ngân sách") → hàng "Ngưỡng cảnh báo" **không** bị vô hiệu hoá hay xoá giá trị: người dùng vẫn xem được ngưỡng đang lưu.
- **Tắt hết 6 công tắc rồi khởi động lại app** → tất cả **vẫn tắt** (không tự bật lại về mặc định).
- **Người dùng chạm liên tục vào hàng chevron** → không mở gì, không lỗi, không treo.
- **Cấu hình bị sửa ở nơi khác trong lúc màn đang mở** → không xảy ra trong app một người dùng; màn đọc lại cấu hình mỗi lần mở, không có cập nhật đẩy.
- **Người dùng mong chờ thông báo bắn ra** sau khi bật công tắc → đợt này **không** có thông báo nào (xem "Ngoài phạm vi" và "Giả định"); màn **không** hứa hẹn gì thêm ngoài trạng thái công tắc.
- **Tiêu đề hàng / dòng phụ dài** → xuống dòng gọn, không đẩy tràn công tắc hay chevron.
- **Không có mạng** → màn hoạt động đầy đủ, cấu hình vẫn lưu và khôi phục bình thường.
- **Thiết bị đổi múi giờ hoặc đổi ngôn ngữ** → trạng thái công tắc và tham số **không** đổi; chỉ nhãn hiển thị đổi theo ngôn ngữ.

## Yêu cầu chức năng

- **FR-001**: Màn **Cài đặt** PHẢI có **hàng điểm vào "Thông báo & nhắc nhở"** (nhóm KHÁC, kèm chevron) mở màn này bằng **đúng 1 lần chạm**.
- **FR-002**: Màn PHẢI là **trang con** theo mockup `01`: app bar **màu thương hiệu** có **nút back** và tiêu đề **"Thông báo & nhắc nhở"**; **không** có thanh điều hướng đáy và **không** có nút thêm giao dịch.
- **FR-003**: Màn PHẢI có **đúng 5 nhóm** theo thứ tự mockup — **NHẮC NHỞ HÀNG NGÀY**, **NGÂN SÁCH**, **GIAO DỊCH ĐỊNH KỲ**, **MỤC TIÊU TIẾT KIỆM**, **TỔNG KẾT TỰ ĐỘNG** — mỗi nhóm có **nhãn viết hoa** phân biệt được với tiêu đề hàng.
- **FR-004**: Mỗi hàng PHẢI gồm **icon tròn nền nhạt + tiêu đề + dòng phụ mô tả cấu hình**; các hàng **nhóm Ngân sách** PHẢI dùng **sắc coral** cho icon (ngữ cảnh cảnh báo chi tiêu), các hàng còn lại dùng **sắc teal**.
- **FR-005**: Mỗi hàng PHẢI có **đúng một** phần tử điều khiển ở bên phải: **công tắc** hoặc **chevron**. Màn PHẢI có **6 công tắc độc lập** (Nhắc nhập giao dịch hằng ngày; Cảnh báo vượt ngân sách; Nhắc hóa đơn sắp đến hạn; Nhắc đóng góp mục tiêu; Tổng kết cuối tuần; Tổng kết cuối tháng) và **2 hàng cấu hình có chevron** (Ngưỡng cảnh báo; Nhắc trước).
- **FR-006**: Công tắc PHẢI **độc lập hoàn toàn**: đổi trạng thái một công tắc **KHÔNG** được làm đổi trạng thái bất kỳ công tắc nào khác; **KHÔNG** có công tắc "bật/tắt tất cả".
- **FR-007**: Trạng thái 6 công tắc **và** mọi tham số cấu hình PHẢI được **lưu bền trên thiết bị** và khôi phục đúng sau khi đóng/mở lại app hay khởi động lại thiết bị. Giá trị mặc định PHẢI được ghi lại ngay trong lần mở màn đầu tiên.
- **FR-008**: Giá trị **mặc định khi chưa từng cấu hình** PHẢI là: nhắc nhập giao dịch hằng ngày — **bật**, **20:30** mỗi ngày, cờ **"chỉ nhắc nếu chưa ghi giao dịch nào trong ngày"** = **bật**; cảnh báo vượt ngân sách — **bật**, ngưỡng **sớm 80%** và **vượt mức 100%**; nhắc hóa đơn sắp đến hạn — **bật**, nhắc trước **3 ngày**; nhắc đóng góp mục tiêu — **tắt**; tổng kết cuối tuần — **bật**, **Chủ nhật 20:00**; tổng kết cuối tháng — **bật**, **ngày cuối tháng 20:00**.
- **FR-009**: **Dòng phụ** của mỗi hàng PHẢI phản ánh **cấu hình đang lưu** (giờ nhắc, ngưỡng, số ngày nhắc trước, chu kỳ) và PHẢI được **đọc lại mỗi lần màn mở** — không giữ bản cứng trong màn.
- **FR-010**: **Tắt** một công tắc PHẢI **chỉ** đổi trạng thái của loại đó; tham số cấu hình của loại đó PHẢI **được giữ nguyên**, **KHÔNG** reset về mặc định khi bật lại.
- **FR-011**: Hai hàng cấu hình chi tiết (**Ngưỡng cảnh báo**, **Nhắc trước**) PHẢI hiển thị **giá trị đang lưu**; đợt này chạm vào hàng **KHÔNG** mở luồng nào (điểm nối màn chỉnh tham số để PBI sau) và **KHÔNG** hiển thị thông báo lỗi hay khung "sắp có"/"chưa hỗ trợ". [Q2 chọn A]
- **FR-012**: Đợt này màn PHẢI **chỉ ghi nhận cấu hình**: thao tác công tắc **KHÔNG** bắn thông báo nào và app **KHÔNG** xin quyền thông báo; màn **KHÔNG** hiển thị nhắc nhở gì về quyền thông báo của hệ điều hành (giống nhau dù quyền được cấp hay bị chặn). [Q1 chọn A]
- **FR-013**: **Tắt toàn bộ** thông báo PHẢI **không** ảnh hưởng tới bất kỳ chức năng nào khác của app (ghi chép giao dịch, ví, danh mục, ngân sách, báo cáo) và **không** hiện cảnh báo, không chặn thao tác.
- **FR-014**: Hai nhóm **Mục tiêu tiết kiệm** và **Giao dịch định kỳ** PHẢI hiển thị **đúng như mockup** (hàng + công tắc, nhắc mục tiêu mặc định tắt) và trạng thái của chúng PHẢI **được lưu như mọi hàng khác**; màn **KHÔNG** được ghi "sắp có"/"chưa hỗ trợ" hay vô hiệu hoá công tắc. [Q3 chọn A]
- **FR-015**: Mọi **nhãn tĩnh** của màn (tiêu đề app bar, 5 nhãn nhóm, 8 tiêu đề hàng, các dòng phụ dạng mô tả) PHẢI có bản dịch **Tiếng Việt / English** theo ngôn ngữ đang chọn (PBI 19); **giờ và định dạng ngày/số KHÔNG** đổi theo ngôn ngữ.
- **FR-016**: Màn PHẢI hiển thị đúng bộ màu của **chế độ Sáng/Tối** đang chọn (PBI 18) — nền, chữ, nhãn nhóm, icon, công tắc bật/tắt, đường phân cách — đảm bảo đủ tương phản.
- **FR-017**: Màn PHẢI **không vỡ bố cục** trên các kích thước màn hình, vùng an toàn và cỡ chữ khác nhau; tiêu đề hàng/dòng phụ dài PHẢI xuống dòng gọn và **không** đè lên công tắc/chevron; nội dung PHẢI **cuộn được** tới hàng cuối.
- **FR-018**: Màn **KHÔNG** được làm thay đổi dữ liệu nghiệp vụ (giao dịch, ví, danh mục, ngân sách) — nó chỉ đọc/ghi cấu hình thông báo của chính nó.

## Tiêu chí thành công

- **SC-001**: Đối chiếu trực quan với `01-cai-dat-thong-bao.svg`: **100%** thành phần (app bar teal + back + tiêu đề, 5 nhãn nhóm, 8 hàng với icon/tiêu đề/dòng phụ, 6 công tắc, 2 chevron) hiển thị đúng vị trí, đúng nội dung, đúng màu ngữ nghĩa (coral chỉ ở nhóm Ngân sách).
- **SC-002**: Từ màn Cài đặt, người dùng tới được màn Thông báo & nhắc nhở bằng **đúng 1 lần chạm** và quay lại bằng **1 lần chạm**.
- **SC-003**: **100%** thao tác bật/tắt công tắc chỉ ảnh hưởng **đúng hàng đó** — kiểm chứng bằng cách đổi từng công tắc một và đối chiếu 5 công tắc còn lại (0 sai lệch).
- **SC-004**: Sau khi đặt cấu hình rồi **khởi động lại app (và thiết bị)**, **100%** công tắc hiển thị **đúng** giá trị đã đặt, **kể cả trường hợp tắt hết** (0 trường hợp tự bật lại).
- **SC-005**: Một công tắc đang **tắt** rồi bật lại: **100%** trường hợp thấy **đúng tham số cũ** của loại đó (0 trường hợp bị reset về mặc định).
- **SC-006**: **100%** dòng phụ hiển thị đúng giá trị cấu hình đang lưu (VD 20:30, 80%/100%, 3 ngày, Chủ nhật 20:00) sau khi mở lại app.
- **SC-007**: Sau khi bật/tắt công tắc và dùng app trong ngày: **0** thông báo được bắn ra, **0** lần app hỏi quyền thông báo.
- **SC-008**: Chạm vào 2 hàng chevron: **0** màn hình mới được mở, **0** thông báo lỗi hoặc khung "sắp có" xuất hiện.
- **SC-009**: Tắt **cả 6** công tắc → app vẫn thêm/sửa giao dịch, xem ví/danh mục/ngân sách/báo cáo bình thường, **0** thông báo lỗi.
- **SC-010**: Ở **English**, **0** nhãn tĩnh tiếng Việt còn sót trên màn; ở **chế độ Tối**, **100%** chữ và phần tử điều khiển đạt tương phản đọc được.
- **SC-011**: Với **cỡ chữ lớn nhất** và **màn hình nhỏ**, màn không vỡ bố cục, không cắt chữ, không đè công tắc, và cuộn tới được hàng cuối ở **100%** lần kiểm tra.
- **SC-012**: Sau khi dùng màn này, **0** thay đổi về số lượng bản ghi giao dịch/ví/danh mục/ngân sách so với trước.

## Thực thể chính

- **Cấu hình thông báo** (một bản ghi cho mỗi loại nhắc, lưu bền trên thiết bị): **loại nhắc** (nhắc nhập giao dịch hằng ngày / cảnh báo ngân sách / nhắc giao dịch định kỳ / nhắc mục tiêu tiết kiệm / tổng kết cuối tuần / tổng kết cuối tháng), **trạng thái bật–tắt**, và **tham số riêng theo loại**: giờ + phút + các ngày trong tuần + cờ "chỉ nhắc nếu chưa ghi giao dịch" (nhắc hàng ngày); ngưỡng sớm % + ngưỡng vượt mức % (cảnh báo ngân sách); số ngày nhắc trước (giao dịch định kỳ); chu kỳ đóng góp + các mốc % (mục tiêu); thời điểm tổng kết tuần và tháng. Đợt này **chỉ ghi và hiển thị** các giá trị này — chưa có thành phần nào đọc chúng để bắn thông báo.

## Giả định

- **Tên PBI "thông báo ẩn"** được hiểu là **màn cài đặt thông báo còn thiếu của app** — đợt này lấy đúng phạm vi mockup `01-cai-dat-thong-bao.svg`; doc nghiệp vụ §4 còn 3 mockup khác (`02` cấu hình nhắc nhập giao dịch, `03` Trung tâm thông báo, `04` mẫu thông báo đẩy) **không** thuộc PBI này.
- **Hàng điểm vào nằm trong nhóm "KHÁC" của màn Cài đặt** (ngay sau "Tiện ích & Cá nhân hóa"), dạng hàng có chevron — mockup `01` không vẽ màn Cài đặt nên vị trí được chốt theo cách xếp hàng hiện có.
- **Giá trị mặc định lấy đúng theo mockup `01` và doc nghiệp vụ §2**: 20:30 hằng ngày (có cờ "chỉ nhắc nếu chưa ghi"), ngưỡng 80%/100%, nhắc trước 3 ngày, tổng kết Chủ nhật 20:00 và ngày cuối tháng 20:00; **nhắc đóng góp mục tiêu mặc định tắt** (mockup vẽ công tắc này ở trạng thái tắt trong khi các công tắc khác đang bật).
- **Màn KHÔNG có công tắc tổng "bật/tắt toàn bộ thông báo"** — mockup không vẽ và doc nghiệp vụ §2 chốt nguyên tắc "mỗi loại thông báo có switch bật/tắt độc lập".
- **Màn KHÔNG có nút "Lưu"**: mọi thay đổi công tắc được ghi nhận ngay, không có bước xác nhận (đồng bộ với cách các màn cài đặt hiện có đang hành xử).
- **Công tắc là cấu hình đặt trước, chưa có tác dụng trong đợt này** (Q1 chọn A): engine bắn thông báo (lên lịch theo giờ, bắn cảnh báo sau khi lưu giao dịch, chống bắn trùng, nội dung nhắc, deep link) là **PBI sau**; màn **không** nói gì với người dùng về việc này (giữ đúng mockup).
- **Ngưỡng cảnh báo ngân sách là cấu hình dùng chung** cho mọi ngân sách (mockup `01` chỉ có **một** hàng "Ngưỡng cảnh báo" ở cấp màn, không phải cấu hình riêng từng ngân sách); việc gắn ngưỡng riêng cho từng ngân sách (doc ngân sách `alertThresholds`) **không** thuộc đợt này.
- **Trạng thái 2 nhóm chưa có module** (Mục tiêu tiết kiệm — GĐ3; Giao dịch định kỳ — GĐ2 chưa làm) vẫn hiển thị và lưu được: đây là cấu hình đặt trước, có hiệu lực khi module tương ứng ra đời; màn **không** lộ chi tiết "chưa hỗ trợ" (Q3 chọn A).
- **Trung tâm thông báo trong app (mockup `03`) không thuộc đợt này** — kể cả việc lưu lịch sử thông báo để xem lại.
- **Múi giờ dùng theo thiết bị**; thay đổi múi giờ ảnh hưởng thế nào tới lịch nhắc là **quyết định mở đã biết** của dự án, không giải quyết trong PBI này.
- **Khoá app (PIN) không ảnh hưởng màn này**: màn chỉ mở được sau khi đã mở khóa app (PBI 3).
- **Không có đồng bộ/tài khoản**: cấu hình chỉ nằm trên thiết bị này, không đi kèm backup/restore JSON (GĐ3).

## Ngoài phạm vi

- **Toàn bộ engine bắn thông báo thật** (Q1 chọn A — PBI sau): lên lịch nhắc theo giờ cố định (nhắc hàng ngày, nhắc hạn định kỳ, tổng kết tuần/tháng), bắn cảnh báo ngay sau khi lưu giao dịch chi tiêu vượt ngưỡng, cơ chế chống bắn trùng theo tần suất tối đa, quy tắc "không bắn khi đang ở đúng màn liên quan", nội dung nhắc kèm số liệu cụ thể, **deep link khi tap thông báo**.
- **Mọi thứ liên quan tới quyền thông báo của hệ điều hành**: xin quyền (kể cả soft-ask trong onboarding), cảnh báo khi bị chặn quyền, notification channel riêng theo từng loại trên Android, hướng dẫn autostart cho máy bị tối ưu pin.
- **Màn `02` Cấu hình chi tiết nhắc nhập giao dịch hàng ngày** (time picker + chip ngày trong tuần + khối xem trước nội dung) và **việc chỉnh tham số** nói chung: ngưỡng cảnh báo, số ngày nhắc trước, giờ nhắc — đợt này 2 hàng chevron chỉ hiển thị giá trị (Q2 chọn A).
- **Màn `03` Trung tâm thông báo trong app** (lịch sử thông báo, chấm chưa đọc, nhóm theo thời gian).
- **Mockup `04` mẫu thông báo đẩy** — chỉ là hình minh hoạ mẫu, không phải màn hình cần dựng.
- **Ngưỡng cảnh báo riêng cho từng ngân sách** (doc ngân sách `alertThresholds` + `lastAlertTriggered`) — đợt này chỉ có ngưỡng dùng chung ở màn cài đặt.
- **Nhắc theo loại "tốc độ tiêu nhanh hơn dự kiến"** của module Ngân sách (2c còn lại).
- **Bất kỳ loại thông báo nào khác ngoài 5 loại** trong doc nghiệp vụ §2 (VD thông báo nợ đến hạn trả/thu — module Quản lý nợ GĐ3; nhắc backup định kỳ).
- **Widget màn hình chính / Quick Add từ notification** (quyết định mở #6 của dự án).
- **Ghi nhớ cấu hình vào file backup/restore JSON** (GĐ3).

## Quyết định đã chốt

- **Q1 — chọn A: đợt này chỉ làm màn cài đặt + lưu cấu hình, chưa làm engine bắn thông báo.** Công tắc là cấu hình đặt trước; engine (lên lịch, bắn cảnh báo ngân sách, chống trùng, nội dung, deep link, quyền thông báo) là PBI sau. (chốt 2026-09-13)
- **Q2 — chọn A: hai hàng cấu hình chi tiết (Ngưỡng cảnh báo, Nhắc trước) chỉ hiển thị giá trị, chạm chưa mở luồng nào** (điểm nối để PBI sau); **chưa dựng màn `02`** cấu hình nhắc nhập giao dịch — đồng bộ tiền lệ các PBI 13/17 (hàng no-op chờ PBI sau). (chốt 2026-09-13)
- **Q3 — chọn A: hiện đủ 5 nhóm như mockup**, hai nhóm chưa có module (Giao dịch định kỳ, Mục tiêu tiết kiệm) vẫn hiển thị và lưu được trạng thái công tắc; **không** ghi "sắp có"/"chưa hỗ trợ", **không** vô hiệu hoá công tắc. (chốt 2026-09-13)
