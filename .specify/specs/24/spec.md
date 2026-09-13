# Đặc tả tính năng: Thêm giao dịch bằng quét hóa đơn (AI)

**Mã PBI**: 24
**Ngày tạo**: 2026-09-12
**Trạng thái**: Đã làm rõ

## Mô tả tổng quan

Nhập tay một hóa đơn tốn nhiều thao tác: gõ số tiền, chọn ngày, gõ tên cửa hàng, chọn danh mục, chọn ví. PBI này bổ sung lối vào **"Quét hóa đơn (AI)"** trên bottom sheet thêm giao dịch nhanh (mockup `docs/ai/scan-01-quick-add-sheet.svg`): người dùng **chụp hoặc chọn ảnh hóa đơn giấy** → app **đọc chữ và trích xuất ngay trên máy** ra **số tiền, ngày giờ, tên cửa hàng, danh mục gợi ý** → hiện **màn hình xác nhận** để người dùng đối chiếu, sửa nhẹ rồi lưu.

Toàn bộ xử lý chạy **trên thiết bị**, không gửi ảnh hay dữ liệu đi đâu — giữ nguyên nguyên tắc offline hoàn toàn của app. Bước trích xuất có **2 chế độ**: **chế độ cơ bản** (bộ luật từ khóa, luôn có sẵn, chạy được trên mọi máy) và **AI nâng cao** (mô hình ngôn ngữ chạy trên máy, chỉ bật khi thiết bị đủ cấu hình và người dùng đồng ý tải/kích hoạt). Dù ở chế độ nào, app **không bao giờ tự lưu** — luôn qua màn hình xác nhận.

Đợt này **chỉ nhận nguồn hóa đơn giấy**. Các nguồn khác (tin nhắn ngân hàng, thông báo ví điện tử, email sao kê, dán văn bản — doc nghiệp vụ §10) và các phần nâng cao (quét hàng loạt, lịch sử quét, học danh mục theo người dùng) thuộc PBI sau.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính — Chụp hóa đơn rồi lưu giao dịch

1. Ở tab bất kỳ, người dùng chạm **FAB (+)** giữa bottom nav → **bottom sheet "Thêm giao dịch"** trượt lên theo mockup `scan-01`, gồm 4 lựa chọn: **Khoản Thu · Khoản Chi · Chuyển khoản · Quét hóa đơn (AI)** (mục cuối có nhãn **"MỚI"**).
2. Chạm **"Quét hóa đơn (AI)"**. Lần đầu dùng tính năng (hoặc lần đầu sau khi bật trong Cài đặt), app **kiểm tra cấu hình máy** và hiện kết quả (màn `scan-10`): máy đủ điều kiện dùng **AI nâng cao** hay chỉ dùng **Chế độ cơ bản**. Người dùng chọn dùng tiếp; app **chỉ xin quyền camera/thư viện ảnh đúng lúc này**.
3. **Màn chụp hóa đơn** (`scan-02`) mở ra: khung ngắm nét đứt, nút **flash**, nút **thư viện** (chọn ảnh có sẵn), nút **chụp**, dòng gợi ý *"Đặt hóa đơn vừa khung, tránh bóng đổ"*.
4. Người dùng chụp (hoặc chọn ảnh từ thư viện) → **màn xử lý** (`scan-03`) hiện ảnh thu nhỏ có **vệt quét** chạy và 4 bước tiến trình: *Đọc & xử lý ảnh · Nhận diện chữ (trên máy) · Phân tích số tiền, ngày, danh mục · Chuẩn bị màn hình xác nhận*, kèm dòng *"Toàn bộ xử lý diễn ra ngay trên máy của bạn"*.
5. Xong → **màn xác nhận** (`scan-04`): app bar teal có nút back và tiêu đề **"Xác nhận hóa đơn"**; bên dưới là **ảnh hóa đơn thu nhỏ** + nút **"Xem ảnh gốc"**; rồi các trường đã điền sẵn: **Loại giao dịch** (Chi tiêu/Thu nhập), **Số tiền** (kèm nhãn độ tin cậy), **Ngày giờ**, **Cửa hàng / Ghi chú**, **Danh mục gợi ý**, **Ví áp dụng**; cuối màn là nút **"Lưu giao dịch"**.
6. Người dùng đối chiếu: chạm vào một trường → **khoanh vùng tương ứng trên ảnh gốc** (VD chạm "Số tiền" → khoanh đúng dòng "TỔNG CỘNG 55.000" trên ảnh); sửa trường nào thấy sai; trường bị đánh dấu **"Kiểm tra lại"** thì xác nhận lại giá trị.
7. Chạm **"Lưu giao dịch"** → giao dịch được tạo với **nguồn "AI Scan"**, gắn ảnh hóa đơn vừa quét, đúng ví đã chọn; màn xác nhận đóng lại; danh sách Giao dịch và số liệu Tổng quan/Báo cáo **làm mới ngay**.

### Luồng phụ — Máy chỉ đạt Chế độ cơ bản

Ở bước 2, kết quả kiểm tra là **chưa đủ điều kiện** (màn `scan-10` nêu rõ tiêu chí chưa đạt, VD *"RAM 3GB — cần tối thiểu 4GB"*) → app báo người dùng **vẫn dùng được tính năng ở Chế độ cơ bản**, không cần AI nâng cao; toàn bộ các bước 3–7 diễn ra y hệt, chỉ khác chất lượng đọc hiểu với nội dung phức tạp.

### Luồng phụ — Máy đủ điều kiện dùng AI nâng cao cần tải model

Kết quả kiểm tra là **đủ điều kiện (cần tải model)** → app hiện nút **"Tải model (~1.8GB) qua Wifi"** kèm khuyến nghị dùng Wifi; sau khi tải xong app báo sẵn sàng và tính năng dùng AI nâng cao từ lần quét kế tiếp. Người dùng có thể **"Dùng chế độ cơ bản"** thay vì tải.

### Luồng phụ — Không nhận diện được nội dung

Ảnh quá mờ/tối, app không đọc được chữ nào → màn xử lý kết thúc bằng thông báo **"Không nhận diện được nội dung hóa đơn. Vui lòng chụp lại hoặc nhập tay."** kèm 2 lựa chọn: **chụp lại** hoặc **"Nhập tay"** (mở form thêm giao dịch trống). Không có giao dịch nào được tạo.

### Kịch bản chấp nhận

1. **Given** người dùng đang ở bất kỳ tab nào **When** chạm FAB (+) **Then** bottom sheet "Thêm giao dịch" mở ra đúng mockup `scan-01`: tuỳ chọn **Khoản Thu**, **Khoản Chi**, **Chuyển khoản** (giữ nguyên hành vi hiện có) và tuỳ chọn mới **"Quét hóa đơn (AI)"** có icon máy ảnh, mô tả *"Tự động đọc số tiền, ngày, cửa hàng"* và nhãn **"MỚI"**.
2. **Given** bottom sheet đang mở **When** người dùng chạm **"Quét hóa đơn (AI)"** **Then** app mở luồng quét hóa đơn và **không** mở form thêm giao dịch thủ công; ngược lại chạm **Khoản Thu/Khoản Chi** vẫn mở form thêm giao dịch như trước, chạm **Chuyển khoản** vẫn vào luồng chuyển khoản như trước.
3. **Given** tính năng quét hóa đơn đang **tắt** trong Cài đặt **When** mở bottom sheet **Then** tuỳ chọn **"Quét hóa đơn (AI)"** **không xuất hiện** (3 tuỳ chọn còn lại vẫn hiển thị bình thường).
4. **Given** người dùng **chưa từng** dùng tính năng quét **When** chạm "Quét hóa đơn (AI)" lần đầu **Then** app chạy **kiểm tra cấu hình máy** và hiển thị kết quả theo mockup `scan-10`: danh sách mục đang kiểm tra (RAM, dung lượng trống, hỗ trợ AI trên máy, phiên bản hệ điều hành) kèm giá trị và trạng thái Đạt/Không đạt, rồi thẻ kết quả tương ứng **một trong ba** trường hợp: **đủ điều kiện dùng ngay**, **đủ điều kiện nhưng cần tải model**, hoặc **chưa đủ điều kiện — vẫn dùng được Chế độ cơ bản** (có nêu rõ tiêu chí chưa đạt).
5. **Given** kết quả kiểm tra là **chưa đủ điều kiện** **When** người dùng chọn dùng tiếp **Then** app vào thẳng màn chụp hóa đơn và toàn bộ luồng quét hoạt động bình thường ở **Chế độ cơ bản** (không có bước tải gì, không cần mạng).
6. **Given** kết quả kiểm tra là **đủ điều kiện nhưng cần tải model** **When** người dùng bấm **"Tải model"** **Then** app tải model (khuyến nghị Wifi), hiển thị tiến trình, và chỉ báo sẵn sàng dùng AI nâng cao **sau khi tải xong**; nếu người dùng chọn **"Dùng chế độ cơ bản"** thì không tải gì và app chuyển sang Chế độ cơ bản.
7. **Given** app đã có kết quả kiểm tra cấu hình **When** người dùng mở lại tính năng **Then** app **không chạy lại** kiểm tra đầy đủ (dùng kết quả đã lưu), **trừ khi** kết quả cũ đã quá **30 ngày** hoặc người dùng chủ động bấm **"Kiểm tra lại cấu hình máy"** trong Cài đặt.
8. **Given** màn chụp hóa đơn đang mở **When** người dùng quan sát **Then** màn có **khung ngắm** nét đứt (4 góc nhấn), tiêu đề **"Quét hóa đơn"**, nút **back**, nút **flash**, nút **thư viện ảnh**, nút **chụp** tròn ở giữa, và dòng gợi ý *"Đặt hóa đơn vừa khung, tránh bóng đổ"*; **không** có tuỳ chọn "quét nhiều hóa đơn" trong đợt này.
9. **Given** màn chụp hóa đơn đang mở **When** người dùng chọn ảnh có sẵn từ thư viện **Then** app bỏ qua camera và đưa đúng ảnh đó vào bước xử lý, kết quả xác nhận giống như khi chụp.
10. **Given** người dùng đã chụp/chọn ảnh **When** bước xử lý chạy **Then** màn xử lý (`scan-03`) hiển thị ảnh thu nhỏ, vệt quét, tiêu đề **"Đang xử lý hóa đơn..."**, 4 bước tiến trình thể hiện **bước đang chạy** khác bước đã xong/chưa tới, và dòng cam kết **"Không gửi dữ liệu lên bất kỳ máy chủ nào"**; người dùng không phải chờ màn hình trắng hay tưởng app treo.
11. **Given** xử lý xong **When** màn xác nhận mở ra **Then** màn đúng mockup `scan-04`: app bar teal + nút back + tiêu đề "Xác nhận hóa đơn"; ảnh hóa đơn thu nhỏ; nút **"Xem ảnh gốc"**; các trường **Loại giao dịch, Số tiền, Ngày giờ, Cửa hàng / Ghi chú, Danh mục gợi ý, Ví áp dụng** đã điền sẵn giá trị trích xuất; dòng chú thích *"Nguồn: Quét hóa đơn (AI) • xử lý hoàn toàn trên máy"* và nút **"Lưu giao dịch"** ở cuối màn.
12. **Given** màn xác nhận đang mở **When** người dùng chạm vào trường **"Số tiền"** **Then** app **khoanh vùng** trên ảnh gốc đúng vị trí dòng văn bản mà app đã đọc ra số tiền đó (và tương tự với các trường khác nếu xác định được vùng).
13. **Given** một trường được trích xuất với **độ tin cậy thấp** hoặc **để trống** **When** màn xác nhận hiển thị **Then** trường đó có **chỉ báo cảnh báo màu coral** kèm nhãn *"Kiểm tra lại"* / *"Vui lòng kiểm tra lại"*; trường có độ tin cậy cao có nhãn trung tính (VD *"Độ tin cậy cao"*) dùng màu thương hiệu.
14. **Given** màn xác nhận đang mở **When** **Số tiền** đang trống hoặc không hợp lệ **Then** nút **"Lưu giao dịch"** ở trạng thái **không bấm được**; ngay khi người dùng nhập số tiền hợp lệ, nút bật lên.
15. **Given** màn xác nhận đang mở **When** người dùng sửa **Loại giao dịch / Ngày giờ / Cửa hàng / Danh mục / Ví** (các trường không bắt buộc) **Then** app cho phép sửa và **cho phép lưu dù các trường này để trống**, riêng Số tiền vẫn bắt buộc.
16. **Given** màn xác nhận đang mở **When** người dùng bấm **"Lưu giao dịch"** **Then** app tạo **đúng 1 giao dịch** với: số tiền và ngày giờ như trên màn, ví đã chọn, danh mục đã chọn (nếu có), tên cửa hàng trong ghi chú, **nguồn = "AI Scan"**, **ảnh hóa đơn đính kèm**; sau đó màn xác nhận đóng và danh sách Giao dịch hiển thị giao dịch mới **ngay**, số dư ví và số liệu Tổng quan/Báo cáo cập nhật theo.
17. **Given** một hóa đơn có số tiền trùng **và** ngày giờ trùng với một giao dịch đã có trong app **trong vòng 24 giờ** **When** màn xác nhận hiển thị **Then** app hiện **cảnh báo nhẹ** (VD *"Có thể trùng với giao dịch đã nhập"*) nhưng **vẫn cho lưu** nếu người dùng muốn.
18. **Given** ảnh không đọc được chữ nào **When** bước xử lý kết thúc **Then** app hiển thị thông báo **"Không nhận diện được nội dung hóa đơn. Vui lòng chụp lại hoặc nhập tay."** kèm nút **"Chụp lại"** và **"Nhập tay"**; chọn "Nhập tay" mở form thêm giao dịch **trống**, và **không** giao dịch nào bị tạo tự động.
19. **Given** đọc được văn bản **nhưng không tìm ra số tiền** **When** màn xác nhận hiển thị **Then** trường Số tiền **để trống**, được đánh dấu bắt buộc nhập tay, các trường còn lại vẫn hiển thị giá trị (hoặc để trống) như bình thường.
20. **Given** người dùng đang ở giữa luồng quét **When** bấm back/thoát **Then** app **không lưu** giao dịch nào, **không** lưu ảnh vào thư viện đính kèm, và **không** để lại dữ liệu quét dở; lần quét sau bắt đầu lại từ đầu.
21. **Given** AI nâng cao đang bật **When** mô hình lỗi hoặc quá thời gian xử lý trong một lần quét **Then** app **tự chuyển sang Chế độ cơ bản cho riêng lần quét đó**, vẫn ra màn xác nhận bình thường, và lần quét đó được ghi nhận là do bộ luật cơ bản xử lý (người dùng không phải thao tác lại).
22. **Given** thiết bị **đang tắt mạng hoàn toàn** **When** người dùng quét một hóa đơn **Then** toàn bộ luồng (chụp → trích xuất → xác nhận → lưu) **chạy trọn vẹn**; chỉ bước **tải model** (nếu cần) mới đòi mạng.
23. **Given** app đang ở **English** (PBI 19) **When** đi qua toàn bộ luồng quét **Then** mọi nhãn tĩnh (bottom sheet, màn chụp, màn xử lý, màn xác nhận, màn kiểm tra cấu hình, mục Cài đặt) hiển thị bằng tiếng Anh, **không** còn sót tiếng Việt; số tiền vẫn định dạng phân tách nghìn kèm đơn vị tiền tệ.
24. **Given** app đang ở **chế độ Tối** (PBI 18) **When** đi qua toàn bộ luồng quét **Then** nền, chữ, app bar, khung ngắm, chỉ báo độ tin cậy và nút dùng đúng bộ màu của chế độ Tối; màn chụp giữ nền tối để nhìn rõ hóa đơn; chữ và số đủ tương phản.
25. **Given** màn hình nhỏ và cỡ chữ lớn nhất **When** mở màn xác nhận và màn kiểm tra cấu hình **Then** bố cục không vỡ, các trường và nút vẫn chạm được, nút "Lưu giao dịch" luôn tới được (màn cuộn được nếu nội dung dài), không trường nào bị che mất.
26. **Given** trong Cài đặt, người dùng **tắt** công tắc quét hóa đơn AI **When** mở lại bottom sheet **Then** tuỳ chọn "Quét hóa đơn (AI)" biến mất; **bật** lại thì tuỳ chọn xuất hiện trở lại, và các giao dịch đã tạo trước đó bằng quét **vẫn giữ nguyên** nguồn "AI Scan" và ảnh đính kèm.
27. **Given** Cài đặt đang mở **When** người dùng xem mục quét hóa đơn AI **Then** app hiển thị **công tắc bật/tắt** và **trạng thái AI hiện tại** (đang dùng AI nâng cao hay Chế độ cơ bản); với trường hợp đã tải model, hiển thị **dung lượng model đang chiếm** kèm nút **"Xoá model"** (giải phóng dung lượng, quay về Chế độ cơ bản, có thể tải lại sau) và nút **"Kiểm tra lại cấu hình máy"**.

### Trường hợp biên

- **Ảnh mờ / thiếu sáng / hóa đơn nhăn** → tỷ lệ đọc sai tăng; app vẫn cho qua màn xác nhận (không tự lưu) và đánh dấu độ tin cậy thấp để người dùng kiểm tra.
- **Hóa đơn có nhiều con số** (đơn giá, thành tiền từng món, tổng) → app ưu tiên dòng tổng/thanh toán và con số lớn nhất ở cuối hóa đơn; nếu vẫn nghi ngờ, số tiền được đánh dấu để kiểm tra lại.
- **Hóa đơn viết tay / chữ không dấu / tiếng nước ngoài** → app vẫn cố trích xuất; các trường không chắc chắn để trống hoặc đánh dấu kiểm tra lại; người dùng nhập tay.
- **Hóa đơn không phải VND** → đợt này app hiểu số tiền theo **đơn vị tiền tệ mặc định của app**; người dùng sửa lại số tiền nếu cần (đa tiền tệ xem mục "Giả định").
- **Ngày trên hóa đơn không tìm thấy** → dùng **thời điểm hiện tại** làm ngày giao dịch và đánh dấu trường ngày giờ để kiểm tra lại.
- **Ngày trên hóa đơn ở tương lai hoặc quá cũ** → vẫn nhận, hiển thị đúng, cho phép sửa; không chặn lưu.
- **Máy chưa cấp quyền camera** → app hiện lời nhắc xin quyền; nếu người dùng từ chối, vẫn còn đường **chọn ảnh từ thư viện**; từ chối cả hai → quay lại màn trước, không lưu gì.
- **Thiết bị không đủ dung lượng để tải model** → app báo không đủ dung lượng, đề nghị giải phóng hoặc dùng Chế độ cơ bản; tính năng vẫn dùng được.
- **Tải model bị ngắt giữa chừng** → không kích hoạt AI nâng cao; app vẫn ở Chế độ cơ bản, cho phép tải lại sau.
- **Người dùng xoá model sau khi đã dùng** → các lần quét sau chạy ở Chế độ cơ bản; giao dịch đã lưu không bị ảnh hưởng.
- **Không có ví mặc định** (mọi ví đều ẩn hoặc chưa đặt ví mặc định) → trường Ví áp dụng để trống/yêu cầu chọn ví trước khi lưu; app không tự bịa ví.
- **Ví đang chọn bị ẩn hoặc bị xóa ở nơi khác trong lúc màn xác nhận đang mở** → khi lưu app báo không lưu được và yêu cầu chọn lại ví.
- **Danh mục gợi ý bị ẩn hoặc bị xóa** → app gợi ý danh mục khác hoặc để trống, không tự tạo danh mục mới.
- **Người dùng sửa danh mục gợi ý** → đợt này app **không ghi nhớ** cặp cửa hàng → danh mục (học theo người dùng thuộc PBI sau); lần quét sau vẫn gợi ý theo từ điển.
- **Hóa đơn rất dài** (nhiều dòng mặt hàng) → đợt này app **không** trích danh sách mặt hàng, chỉ lấy số tiền/ngày/cửa hàng; nội dung còn lại không bị lưu vào giao dịch.
- **Ảnh quá lớn / chụp nhiều lần liên tiếp** → app không giữ ảnh của lần quét trước; chỉ ảnh của giao dịch đã lưu mới còn trong máy.
- **Quét khi pin yếu / máy nóng** → app không tự bật AI nâng cao nếu người dùng đã chọn Chế độ cơ bản; không có cơ chế tự đổi chế độ ngoài việc fallback khi AI lỗi.
- **Không có giao dịch nào trùng** → không hiện cảnh báo trùng (không hiện cảnh báo rỗng gây nhiễu).
- **Người dùng bấm "Lưu giao dịch" hai lần thật nhanh** → chỉ **một** giao dịch được tạo.
- **App bị đóng/điện thoại hết pin giữa lúc đang xử lý** → không có giao dịch nào được tạo và không có ảnh tạm nào còn lại.
- **Khoá app (PIN) đang bật** → luồng quét chỉ chạy sau khi đã mở khoá app (không có màn hình quét riêng ngoài khoá).

## Yêu cầu chức năng

### Lối vào & cấu hình

- **FR-001**: FAB (+) ở bottom nav PHẢI mở **bottom sheet "Thêm giao dịch"** theo mockup `scan-01` gồm 4 tuỳ chọn: **Khoản Thu**, **Khoản Chi**, **Chuyển khoản** (giữ nguyên hành vi hiện có) và **"Quét hóa đơn (AI)"** (icon máy ảnh, mô tả *"Tự động đọc số tiền, ngày, cửa hàng"*, nhãn **"MỚI"**).
- **FR-002**: Chạm **"Quét hóa đơn (AI)"** PHẢI mở luồng quét hóa đơn; chạm 3 tuỳ chọn còn lại PHẢI giữ đúng hành vi hiện tại (mở form thêm giao dịch / luồng chuyển khoản).
- **FR-003**: Cài đặt PHẢI có **công tắc bật/tắt** tính năng quét hóa đơn AI; khi tắt, tuỳ chọn "Quét hóa đơn (AI)" PHẢI **không xuất hiện** ở bottom sheet nhưng **không** làm mất dữ liệu các giao dịch đã tạo bằng quét.
- **FR-004**: Cài đặt PHẢI hiển thị **trạng thái AI hiện tại** (AI nâng cao đang dùng model nào, hoặc **Chế độ cơ bản**) và nút **"Kiểm tra lại cấu hình máy"**; với trường hợp đã tải model PHẢI có **dung lượng model đang chiếm**, nút **"Xoá model"** và nút **"Kiểm tra cập nhật model"**.

### Kiểm tra cấu hình & chế độ trích xuất

- **FR-005**: Trước lần quét đầu tiên (và sau khi người dùng bật công tắc trong Cài đặt), app PHẢI **kiểm tra cấu hình thiết bị** và phân loại thành **một trong ba** kết quả: **đủ điều kiện dùng AI trên máy không cần tải** (model do hệ điều hành quản lý) · **đủ điều kiện nhưng phải tải model** · **chưa đủ điều kiện — dùng Chế độ cơ bản**.
- **FR-006**: Màn kiểm tra cấu hình PHẢI theo mockup `scan-10`: app bar teal + nút back + tiêu đề "Kiểm tra cấu hình máy"; danh sách mục kiểm tra (bộ nhớ trong, dung lượng trống, khả năng hỗ trợ AI trên máy, phiên bản hệ điều hành) với **giá trị đo được** và trạng thái **Đạt / Không đạt / Đang kiểm tra**; rồi **thẻ kết quả** tương ứng kết quả phân loại, nêu **tiêu chí chưa đạt cụ thể** khi không đủ điều kiện.
- **FR-007**: Với kết quả **đủ điều kiện nhưng phải tải model**, app PHẢI hiện dung lượng cần tải, khuyến nghị **dùng Wifi**, có nút **"Tải model"** và lựa chọn **"Dùng chế độ cơ bản"**; AI nâng cao **chỉ được kích hoạt sau khi tải xong**.
- **FR-008**: Kết quả kiểm tra PHẢI được **lưu lại trên máy** và **tái sử dụng** cho các lần mở tính năng sau; app chỉ kiểm tra lại khi kết quả cũ **quá 30 ngày** hoặc khi người dùng **chủ động** bấm "Kiểm tra lại cấu hình máy".
- **FR-009**: Ở **Chế độ cơ bản**, việc trích xuất PHẢI chạy bằng **bộ luật từ khóa/danh sách có sẵn trong app** — không cần tải gì, không cần mạng, chạy được trên mọi thiết bị.
- **FR-010**: Khi **AI nâng cao** đang bật, app PHẢI gửi **toàn bộ văn bản đã đọc được** cho mô hình trên máy **một lần duy nhất** cho mỗi lần quét (mô hình tự nhận loại nội dung và trả về đầy đủ các trường kèm độ tin cậy).
- **FR-011**: Nếu AI nâng cao **lỗi hoặc quá thời gian** trong một lần quét, app PHẢI **tự chuyển sang bộ luật cơ bản cho riêng lần quét đó**, vẫn đưa ra màn xác nhận bình thường, và **ghi nhận** lần quét đó là do chế độ cơ bản xử lý.
- **FR-012**: Người dùng PHẢI có thể **"Xoá model"** đã tải để giải phóng dung lượng; sau khi xoá, app quay về **Chế độ cơ bản** và vẫn dùng được tính năng; các giao dịch đã lưu **không** bị ảnh hưởng.

### Chụp / chọn ảnh & xử lý

- **FR-013**: App PHẢI **chỉ xin quyền camera/thư viện ảnh khi người dùng thực sự vào luồng quét** (không xin lúc mở app).
- **FR-014**: Màn chụp PHẢI theo mockup `scan-02`: nền tối, tiêu đề "Quét hóa đơn", nút back, nút **flash**, **khung ngắm** nét đứt có 4 góc nhấn, dòng gợi ý *"Đặt hóa đơn vừa khung, tránh bóng đổ"*, nút **thư viện ảnh** và nút **chụp** tròn ở giữa.
- **FR-015**: Người dùng PHẢI có thể **chụp ảnh trực tiếp** hoặc **chọn ảnh có sẵn từ thư viện**; cả hai đường PHẢI dẫn tới cùng bước xử lý và cùng chất lượng kết quả.
- **FR-016**: Ở đợt này **KHÔNG** có chế độ quét nhiều hóa đơn liên tiếp; nút "Quét nhiều" trong mockup `scan-02` **không hiển thị**.
- **FR-017**: App PHẢI **tiền xử lý ảnh tự động** trước khi đọc chữ (chỉnh chiều ảnh, tăng độ tương phản) nhằm tăng độ chính xác; nếu không phát hiện được biên hóa đơn thì dùng nguyên ảnh.
- **FR-018**: App PHẢI **đọc chữ ngay trên thiết bị** từ ảnh, thu được **văn bản thô** và **vị trí (vùng) của từng dòng chữ** trên ảnh — vùng này dùng cho bước đối chiếu ở màn xác nhận.
- **FR-019**: Trong lúc xử lý, app PHẢI hiển thị màn `scan-03`: ảnh thu nhỏ, vệt quét, tiêu đề **"Đang xử lý hóa đơn..."**, **4 bước tiến trình** (*Đọc & xử lý ảnh hóa đơn · Nhận diện chữ (OCR on-device) · Phân tích số tiền, ngày, danh mục · Chuẩn bị màn hình xác nhận*) thể hiện bước đang chạy, và dòng cam kết **"Không gửi dữ liệu lên bất kỳ máy chủ nào"**.
- **FR-020**: Nếu app **không đọc được chữ nào**, PHẢI dừng với thông báo **"Không nhận diện được nội dung hóa đơn. Vui lòng chụp lại hoặc nhập tay."** kèm nút **"Chụp lại"** và **"Nhập tay"** (mở form thêm giao dịch trống); **KHÔNG** tạo giao dịch nào.

### Trích xuất thông tin

- **FR-021**: App PHẢI trích xuất **Số tiền** bằng cách ưu tiên các dòng chứa từ khóa tổng thanh toán ("TỔNG CỘNG", "TỔNG TIỀN", "THANH TOÁN", "TOTAL") và con số lớn nhất ở phần cuối hóa đơn; nếu **không tìm ra số tiền**, trường này PHẢI **để trống** và bắt buộc người dùng nhập tay trước khi lưu.
- **FR-022**: App PHẢI trích xuất **Ngày giờ** từ các định dạng ngày thường gặp (ngày/tháng/năm, năm-tháng-ngày, kèm giờ phút); nếu không tìm thấy, PHẢI mặc định là **thời điểm hiện tại** và đánh dấu trường này để người dùng kiểm tra lại.
- **FR-023**: App PHẢI trích xuất **Tên cửa hàng** (ưu tiên dòng chữ lớn nhất ở phần đầu hóa đơn hoặc dòng chứa "Cửa hàng"/"Chi nhánh") và điền vào trường **Cửa hàng / Ghi chú**; trường này **chỉ mang tính gợi ý**, luôn sửa được và có thể để trống.
- **FR-024**: App PHẢI **gợi ý Danh mục** bằng cách đối chiếu tên cửa hàng với một **từ điển cửa hàng → danh mục có sẵn trong app** (VD cửa hàng tiện lợi/quán cà phê → Ăn uống; cây xăng/hãng xe → Di chuyển; siêu thị/điện máy → Mua sắm); nếu không khớp, trường Danh mục **để trống** và người dùng tự chọn. App **KHÔNG** tự tạo danh mục mới và **KHÔNG** ghi nhớ lựa chọn sửa của người dùng trong đợt này.
- **FR-025**: App PHẢI gán **Loại giao dịch** mặc định là **Chi tiêu** (hóa đơn mua hàng) và cho người dùng **đổi sang Thu nhập** ngay trên màn xác nhận.
- **FR-026**: Mỗi trường trích xuất PHẢI kèm **mức độ tin cậy** (cao / trung bình / thấp) và màn xác nhận PHẢI thể hiện mức này bằng **chỉ báo** tương ứng: nhãn trung tính cho độ tin cậy cao, **cảnh báo màu coral + "Kiểm tra lại"** cho độ tin cậy thấp hoặc trường để trống.

### Màn xác nhận & lưu

- **FR-027**: Màn xác nhận PHẢI là **trang con đầy đủ** theo mockup `scan-04`: app bar **màu thương hiệu** + nút back + tiêu đề **"Xác nhận hóa đơn"**; **không** có thanh điều hướng đáy.
- **FR-028**: Màn xác nhận PHẢI hiển thị **ảnh hóa đơn đã quét** (thu nhỏ) kèm nút **"Xem ảnh gốc"**, và các trường có thể sửa: **Loại giao dịch**, **Số tiền**, **Ngày giờ**, **Cửa hàng / Ghi chú**, **Danh mục**, **Ví áp dụng**.
- **FR-029**: Chạm vào một trường PHẢI **khoanh vùng tương ứng trên ảnh gốc** (theo vùng chữ đã lưu ở bước đọc chữ) để người dùng đối chiếu; trường không xác định được vùng thì không khoanh.
- **FR-030**: Trường **Ví áp dụng** PHẢI mặc định là **ví mặc định** đã cấu hình trong app; nếu không có ví mặc định hợp lệ, PHẢI yêu cầu người dùng chọn ví trước khi lưu.
- **FR-031**: Trường **Cửa hàng / Ghi chú** PHẢI đổ vào **ghi chú** của giao dịch khi lưu (cùng quy ước với màn thêm giao dịch hiện có).
- **FR-032**: Nút **"Lưu giao dịch"** PHẢI **chỉ bấm được khi Số tiền hợp lệ**; các trường khác được phép để trống. Một lần bấm PHẢI tạo **đúng một** giao dịch (chống tạo trùng khi bấm nhanh nhiều lần).
- **FR-033**: Giao dịch tạo qua quét PHẢI được gắn **nguồn "AI Scan"** (phân biệt với "Thủ công") để về sau lọc/thống kê được, và PHẢI gắn **ảnh hóa đơn gốc** vào đúng trường ảnh đính kèm của giao dịch (hiển thị được ở màn chi tiết giao dịch).
- **FR-034**: Mỗi lần quét PHẢI lưu lại **bản ghi phiên quét** gồm: ảnh gốc, văn bản thô đã đọc, kết quả trích xuất (kèm độ tin cậy), **chế độ xử lý đã dùng** (AI nâng cao hay cơ bản — kể cả trường hợp bị chuyển sang cơ bản do lỗi), và giao dịch đã tạo (nếu có).
- **FR-035**: Nếu hóa đơn có **số tiền và ngày giờ trùng** với một giao dịch đã có **trong vòng 24 giờ**, màn xác nhận PHẢI hiện **cảnh báo nhẹ** nhưng **không chặn** việc lưu.
- **FR-036**: Huỷ giữa luồng (back/thoát) PHẢI **không lưu giao dịch**, **không** lưu ảnh vào kho đính kèm, và **không** để lại dữ liệu quét dở.

### Quyền riêng tư, dữ liệu & hiển thị

- **FR-037**: Toàn bộ ảnh hóa đơn, văn bản đọc được và kết quả phân tích PHẢI được xử lý và lưu **chỉ trên thiết bị**; app **KHÔNG** được gửi ảnh/nội dung hóa đơn tới bất kỳ máy chủ hay dịch vụ ngoài nào. Ngoại lệ duy nhất là **tải model** (khi người dùng chọn AI nâng cao cần tải) — sau khi tải xong, xử lý vẫn hoàn toàn ngoại tuyến.
- **FR-038**: Sau khi lưu, danh sách Giao dịch và các số liệu phụ thuộc (số dư ví, Tổng quan, Báo cáo) PHẢI **làm mới ngay** — không cần người dùng mở lại app.
- **FR-039**: Mọi **nhãn giao diện tĩnh** của luồng quét (bottom sheet, màn chụp, màn xử lý, màn xác nhận, màn kiểm tra cấu hình, mục Cài đặt) PHẢI có bản dịch **Tiếng Việt / English** theo ngôn ngữ đang chọn (PBI 19); **số tiền** PHẢI theo định dạng phân tách nghìn kèm đơn vị tiền tệ.
- **FR-040**: Luồng quét PHẢI hiển thị đúng bộ màu của **chế độ Sáng/Tối** đang chọn (PBI 18) — teal cho hành động chính, **coral chỉ dùng cho cảnh báo/chi tiêu**; màn chụp ảnh PHẢI giữ nền tối để nhìn rõ hóa đơn bất kể chế độ màu.
- **FR-041**: Màn xác nhận và màn kiểm tra cấu hình PHẢI **không vỡ bố cục** trên các kích thước màn hình, vùng an toàn và cỡ chữ khác nhau; nút "Lưu giao dịch" và thẻ kết quả PHẢI luôn tới được (cuộn được khi nội dung dài).

## Tiêu chí thành công

- **SC-001**: Đối chiếu trực quan với 4 mockup `scan-01`, `scan-02`, `scan-03`, `scan-04`: **100%** thành phần (4 tuỳ chọn bottom sheet + nhãn "MỚI"; khung ngắm + flash + thư viện + nút chụp + dòng gợi ý; ảnh thu nhỏ + vệt quét + 4 bước + dòng cam kết; app bar + ảnh + 6 trường + nút "Xem ảnh gốc" + dòng nguồn + nút lưu) hiển thị đúng vị trí và nội dung; **khác biệt đã chốt**: mockup `scan-02` có nút "Quét nhiều" nhưng đợt này **không hiển thị**.
- **SC-002**: Từ FAB tới lưu xong một hóa đơn: người dùng đi hết luồng với **tối đa 6 lần chạm** (FAB → Quét hóa đơn → chụp → [kiểm tra/xác nhận trường nghi ngờ] → Lưu) và **không phải gõ tay** bất kỳ trường nào khi kết quả đọc đúng.
- **SC-003**: Với ảnh hóa đơn rõ nét, in rõ số tiền: **≥ 90%** lần quét trích xuất đúng **số tiền** và **ngày giờ** (kiểm chứng trên bộ ≥ 20 ảnh hóa đơn mẫu đa dạng cửa hàng, so với số ghi trên hóa đơn).
- **SC-004**: **100%** trường hợp, app **không tự tạo giao dịch** khi chưa qua màn xác nhận — kể cả khi kết quả đọc hoàn hảo (kiểm chứng bằng cách thoát ở màn xác nhận và kiểm tra danh sách giao dịch).
- **SC-005**: **100%** giao dịch tạo qua quét có **nguồn "AI Scan"** và **có ảnh hóa đơn đính kèm mở xem được** ở màn chi tiết giao dịch.
- **SC-006**: **Ngắt mạng hoàn toàn** trên thiết bị: **100%** luồng quét (chụp ảnh/chọn ảnh → trích xuất → xác nhận → lưu) chạy trọn vẹn ở cả Chế độ cơ bản và AI nâng cao đã cài sẵn; chỉ bước tải model mới cần mạng.
- **SC-007**: Thời gian từ lúc chụp tới lúc màn xác nhận hiện ra: **Chế độ cơ bản dưới 3 giây**; **AI nâng cao dưới 10 giây** trên thiết bị đạt điều kiện — trong suốt thời gian đó màn xử lý luôn hiển thị tiến trình (không màn hình trắng, không bị hiểu là treo).
- **SC-008**: Trên một thiết bị **không đủ điều kiện AI nâng cao**: **100%** lần quét vẫn hoàn tất bằng Chế độ cơ bản, người dùng **không** bị chặn ở bất kỳ bước nào và **không** bị yêu cầu cài thêm gì.
- **SC-009**: Khi AI nâng cao gặp lỗi/quá thời gian: **100%** trường hợp app vẫn ra màn xác nhận có kết quả (nhờ chuyển sang Chế độ cơ bản), người dùng **không** phải chụp lại và **không** thấy thông báo lỗi kỹ thuật.
- **SC-010**: Lần quét đầu tiên của người dùng đạt kết quả kiểm tra cấu hình trong **dưới 5 giây**, và các lần mở tính năng sau **không** chạy lại kiểm tra (0 giây chờ) trừ khi quá 30 ngày hoặc người dùng chủ động kiểm tra.
- **SC-011**: **100%** trường được đánh dấu độ tin cậy thấp/để trống hiển thị **cảnh báo coral + nhắc kiểm tra lại**; **0** trường hợp app cho lưu khi Số tiền trống hoặc không hợp lệ.
- **SC-012**: Ảnh không đọc được nội dung: **100%** trường hợp hiện đúng thông báo + 2 lựa chọn "Chụp lại"/"Nhập tay", **0** giao dịch rác được tạo.
- **SC-013**: Khi app ở English: **0** nhãn tĩnh tiếng Việt còn sót trong toàn bộ luồng quét; ở chế độ Tối: **100%** chữ và số đạt tương phản đọc được (kiểm tra bằng công cụ đo tương phản trên ảnh chụp màn hình).
- **SC-014**: Với cỡ chữ lớn nhất và màn hình nhỏ: màn xác nhận và màn kiểm tra cấu hình không vỡ bố cục, không trường/nút nào bị che, ở **100%** lần kiểm tra.
- **SC-015**: Sau khi lưu một giao dịch quét: danh sách Giao dịch và số dư ví hiển thị giao dịch mới **ngay** (không cần thao tác thêm), sai lệch số tiền **0 đ**.

## Thực thể chính

- **Phiên quét (bản ghi mới)**: một lần quét hóa đơn — ảnh gốc (đường dẫn trong máy), văn bản thô đã đọc, kết quả trích xuất kèm độ tin cậy từng trường, **chế độ xử lý đã dùng** (AI nâng cao / cơ bản, kể cả khi bị chuyển sang cơ bản do lỗi), thời điểm quét, và giao dịch đã tạo nếu có (không có khi người dùng huỷ hoặc không đọc được nội dung).
- **Kết quả trích xuất** (đại lượng **tạm**, sinh ra cho mỗi lần quét): số tiền, ngày giờ, tên cửa hàng, danh mục gợi ý, loại giao dịch (Chi tiêu mặc định), **độ tin cậy từng trường**; và **vùng chữ trên ảnh** tương ứng từng trường để đối chiếu.
- **Hồ sơ năng lực thiết bị** (lưu trên máy): kết quả kiểm tra cấu hình — mức phân loại (dùng được AI ngay / phải tải model / chế độ cơ bản), các giá trị đo được (bộ nhớ, dung lượng trống, khả năng hỗ trợ AI, phiên bản hệ điều hành) và **thời điểm kiểm tra** (để quyết định kiểm tra lại sau 30 ngày).
- **Giao dịch** (mở rộng thực thể đã có): bổ sung **nguồn** phân biệt "AI Scan" với "Thủ công"; các thuộc tính khác dùng đúng thực thể giao dịch hiện có (ví, danh mục, số tiền, ngày, ghi chú, ảnh đính kèm).
- **Từ điển cửa hàng → danh mục** (dữ liệu **tĩnh trong app**, không phải dữ liệu người dùng): dùng để gợi ý danh mục; đợt này **không** học thêm từ hành vi sửa của người dùng.
- **Cấu hình tính năng** (mở rộng bảng cài đặt hiện có): công tắc bật/tắt quét hóa đơn AI và chế độ AI đang dùng.

## Giả định

- **Phạm vi đợt này = phần "MVP AI Scan" của doc nghiệp vụ** (§7, dòng MVP): chụp/chọn ảnh → đọc chữ trên máy → trích xuất cơ bản → màn xác nhận sửa tay → lưu. Các nguồn khác (§10) và các phần nâng cao (quét hàng loạt, lịch sử quét, học danh mục, danh sách mặt hàng) thuộc PBI sau.
- **Cài đặt ở mức tối thiểu (đã chốt 2026-09-12)**: chỉ thêm **công tắc bật/tắt** + **khối trạng thái AI** (mức phân loại, model đang dùng, dung lượng, nút kiểm tra lại/xoá model) vào màn Cài đặt hiện có. **Không** dựng màn Cài đặt quét hóa đơn riêng theo mockup `scan-05` (ngôn ngữ đọc ưu tiên, tự tăng nét ảnh, xem/xoá danh sách ánh xạ) và **không** có màn **Scan History** trong đợt này.
- **Lối vào chính là FAB → bottom sheet (mockup `scan-01`)** — đây là lối vào được chọn cho đợt này. Hai lối vào còn lại mà doc §3.1 nêu (icon máy ảnh cạnh ô ảnh đính kèm trong form thêm giao dịch; menu "..." trong danh sách Giao dịch) **chưa có sẵn UI trong app** nên để PBI sau — xem "Ngoài phạm vi".
- **Dùng AI nâng cao là lựa chọn có điều kiện**: doc §1/§2 nói AI là "engine chính" nhưng bắt buộc luôn có nhánh dự phòng bằng bộ luật cho máy yếu; đợt này thực hiện đúng cả hai nhánh theo cơ chế phân loại cấu hình ở doc §11, cả hai nhánh cho **cùng một định dạng kết quả** nên màn xác nhận dùng chung.
- **Danh mục gợi ý theo từ điển có trong đợt này** (mockup `scan-04` vẽ trường "DANH MỤC GỢI Ý: Ăn uống"), nhưng **học theo người dùng** (doc §3.5, §4 — bảng ánh xạ cửa hàng → danh mục) là **GĐ2** theo doc §7 nên chưa làm; do đó **chưa cần** bảng ánh xạ.
- **Chưa thêm trường loại nguồn vào phiên quét** (doc §10.5 `source_type`): đợt này chỉ có một nguồn duy nhất là hóa đơn giấy nên trường này chưa mang thông tin; sẽ thêm cùng PBI mở rộng nguồn.
- **Một phiên quét gắn tối đa một giao dịch**: hóa đơn giấy luôn cho 1 giao dịch (doc §10.1); cơ chế một phiên quét liên kết nhiều giao dịch (doc §10.5, dành cho email sao kê) chưa thuộc đợt này.
- **Ảnh hóa đơn lưu theo cùng cơ chế mã hóa/lưu trữ cục bộ đã áp dụng cho file đính kèm khác của app** (doc §6) — đợt này không đổi cơ chế đó.
- **Chọn đơn vị tiền tệ tại màn xác nhận chưa thuộc đợt này** (doc §3.8 có nêu cho hóa đơn ngoại tệ/viết tay): đa tiền tệ và quy đổi tỷ giá vẫn là **quyết định mở** của app (kế thừa PBI 22/23); đợt này hiểu số tiền theo **đơn vị tiền tệ mặc định** của app.
- **Số dư ví vẫn là đại lượng suy ra**: giao dịch quét cộng vào ví đã chọn theo đúng nguyên tắc xuyên module (số dư ban đầu + thu − chi ± chuyển khoản); màn xác nhận **không** sửa số dư trực tiếp.
- **Ngày giao dịch do người dùng chốt trên màn xác nhận** là ngày dùng để tính kỳ báo cáo/ngân sách (kế thừa quy ước các PBI trước), không dùng thời điểm quét.
- **Kiểm tra cấu hình chỉ mang tính cục bộ và ước lệ**: các ngưỡng (bộ nhớ, dung lượng trống, khả năng hỗ trợ AI) lấy theo doc §11.2; kết quả chỉ dùng để chọn chế độ, không phải cam kết chất lượng.
- **Khoá app (PIN) không ảnh hưởng luồng này**: luồng quét chỉ chạy sau khi đã mở khóa app (PBI 3); không có màn hình quét nào nằm ngoài khoá.
- **Công tắc "Ẩn số dư" (PBI 17) chưa áp dụng**: chưa có hiệu ứng che số tiền ở bất kỳ màn nào, kể cả màn xác nhận.
- **Không có xử lý nền**: phiên quét không chạy tiếp khi người dùng rời màn; đóng app giữa lúc xử lý thì không có gì được lưu.

## Ngoài phạm vi

- **3 nguồn trích xuất còn lại của doc §10**: tin nhắn SMS ngân hàng, thông báo ví điện tử/app ngân hàng, email sao kê/bảng nhiều giao dịch (kèm màn chọn & nhập hàng loạt, tự phát hiện trùng theo ngày + số tiền, nhãn "Có thể đã tồn tại").
- **"Dán văn bản" (Paste text)** — màn `scan-07` và bottom sheet chọn nguồn `scan-06`: nhập văn bản copy sẵn để phân tích, bỏ qua bước ảnh/OCR.
- **Quét hàng loạt nhiều hóa đơn liên tiếp** (doc §3.2, §7 GĐ2) — nút "Quét nhiều" trong mockup `scan-02` không hiển thị đợt này.
- **Học theo người dùng (merchant → danh mục)** và bảng ánh xạ cục bộ (doc §3.5, §4).
- **Scan History** — màn xem lịch sử các lần quét kể cả lần huỷ (doc §5, §7 GĐ2), và màn Cài đặt quét hóa đơn đầy đủ theo mockup `scan-05` / `scan-11`.
- **Tuỳ chọn ngôn ngữ đọc ưu tiên (Việt/Anh/Tự động)** và **công tắc tự tăng độ nét/tương phản** trong Cài đặt (doc §5) — đợt này tiền xử lý ảnh chạy tự động theo mặc định.
- **Trích xuất danh sách mặt hàng (line items)** và **mã số thuế/VAT** (doc §3.5, §7 GĐ3).
- **Trường loại nguồn trong phiên quét** (doc §10.5 `source_type`) và **liên kết một phiên quét với nhiều giao dịch**.
- **2 lối vào còn lại của doc §3.1**: icon máy ảnh trong form thêm giao dịch (quét bổ sung vào giao dịch đang tạo) và menu "..." trong danh sách Giao dịch.
- **Tự động phát hiện biên hóa đơn + cho người dùng tự kéo 4 góc crop thủ công** (doc §3.3): đợt này chỉ có tiền xử lý tự động, không có màn crop tay.
- **Chọn đơn vị tiền tệ tại màn xác nhận** cho hóa đơn ngoại tệ/viết tay; **đa tiền tệ và quy đổi tỷ giá**.
- **Chế độ "AI nâng cao" dùng model lớn hơn cho hóa đơn phức tạp/viết tay** (doc §7 GĐ3) — đợt này chỉ có đúng các mức theo cơ chế phân loại cấu hình ở doc §11.
- **Hiệu ứng công tắc "Ẩn số dư"** (PBI 17) trong luồng quét.

## Quyết định đã chốt

- **Đợt này chỉ nhận nguồn hóa đơn giấy** (màn `scan-01`–`scan-04`); các nguồn ở doc §10 (SMS ngân hàng, thông báo ví, email sao kê, dán văn bản) để PBI sau. (chốt 2026-09-12)
- **Trích xuất gồm cả nhánh AI nâng cao có kiểm tra cấu hình máy** theo doc §11 (phân loại 3 mức, tải model khi cần, xoá model, tự chuyển sang bộ luật cơ bản khi AI lỗi) — không chỉ dừng ở bộ luật cơ bản của dòng MVP. (chốt 2026-09-12)
- **Cài đặt ở mức tối thiểu**: công tắc bật/tắt + khối trạng thái AI trong màn Cài đặt hiện có; **không** dựng màn `scan-05`/`scan-11` đầy đủ và **không** có Scan History trong đợt này. (chốt 2026-09-12)
- **Nút "Quét nhiều" trong mockup `scan-02` không hiển thị** — quét hàng loạt là GĐ2 theo doc §7. (chốt 2026-09-12)
- **Trường "Danh mục gợi ý" có trong đợt này** (theo mockup `scan-04`), nhưng **chỉ dựa trên từ điển có sẵn**, chưa học theo người dùng. (chốt 2026-09-12)
- **Lối vào chính: FAB → bottom sheet "Thêm giao dịch"** (mockup `scan-01`) — thay cho hành vi hiện tại là FAB mở thẳng form thêm giao dịch; 3 tuỳ chọn Thu/Chi/Chuyển khoản giữ nguyên hành vi cũ. (chốt 2026-09-12)
