# Kịch bản kiểm thử nhanh — PBI 24: Quét hóa đơn (AI)

**Mã PBI**: 24
**Liên kết**: [spec.md](./spec.md) · [plan.md](./plan.md) · [research.md](./research.md)

Mục đích: người khác (không phải người viết code) chạy được tính năng từ đầu và đối chiếu với 4 mockup + FR/SC. Chia **2 chặng**: nhóm **A–L** thuộc chặng 1 (chạy được ngay sau lượt thi công đầu); nhóm **M–N** thuộc chặng 2 (AI nâng cao). Phần tự động: `flutter test` (xem bảng test ở `plan.md`).

## Chuẩn bị

1. `cd app/sora_thu_chi && flutter pub get && flutter run` (emulator Android hoặc iOS; emulator không có AICore ⇒ luôn rơi vào **Tier C** — đó là nhánh cần kiểm ở chặng 1).
2. Đẩy sẵn **4 ảnh hóa đơn mẫu vào thư viện ảnh** của emulator (dùng nút **Thư viện** trong màn chụp để không phụ thuộc camera ảo):
   - `good.jpg` — hóa đơn in rõ, có dòng "TỔNG CỘNG 55.000" + ngày giờ, tên cửa hàng ở đầu (VD "CIRCLE K VIỆT NAM").
   - `no-total.jpg` — hóa đơn có chữ nhưng **không** có dòng tổng, nhiều con số (đơn giá/thành tiền).
   - `dark.jpg` — ảnh tối/mờ gần như không đọc được chữ.
   - `nondau.jpg` — hóa đơn chữ không dấu / tiếng nước ngoài.
3. Ghi lại số dư ví "Tiền mặt" (hoặc ví mặc định) trước mỗi ca để đối chiếu.

---

## A. Bottom sheet thêm giao dịch (FR-001, FR-002, FR-003, SC-001)

1. Vào **Cài đặt → Quét hóa đơn AI**, bật công tắc. Quay lại tab bất kỳ, chạm **FAB (+)**.
   → Sheet "Thêm giao dịch" hiện **4 hàng**: Khoản Thu / Khoản Chi / Chuyển khoản / **Quét hóa đơn (AI)** — hàng cuối có icon máy ảnh, dòng mô tả "Tự động đọc số tiền, ngày, cửa hàng" và nhãn **MỚI**.
2. Chạm **Khoản Thu** → mở form thêm giao dịch ở trạng thái **Thu** (hành vi như trước). Quay lại, chạm **Khoản Chi** → form ở trạng thái **Chi**. Chạm **Chuyển khoản** → vào **luồng chuyển khoản** (không mở form thêm).
3. Vào Cài đặt, **tắt** công tắc quét hóa đơn → mở lại sheet: hàng "Quét hóa đơn (AI)" **biến mất**, 3 hàng còn lại bình thường. Bật lại → hàng quay lại. Kiểm tra các giao dịch đã tạo bằng quét trước đó vẫn còn nguyên ảnh + không đổi.

## B. Màn kiểm tra cấu hình máy (FR-005, FR-006, FR-008, SC-010)

1. Xóa dữ liệu app (hoặc dùng máy chưa từng quét) → bật công tắc → chạm **Quét hóa đơn (AI)**.
   → Màn `scan-10`: app bar teal + nút back + tiêu đề "Kiểm tra cấu hình máy"; danh sách 4 mục (**Bộ nhớ RAM**, **Dung lượng trống**, **Hỗ trợ AI trên máy (AICore)**, **Phiên bản hệ điều hành**) mỗi mục có giá trị đo được và trạng thái **Đạt / Không đạt**; rồi **thẻ kết quả**.
2. Trên emulator: kết quả là **Chưa đủ điều kiện — vẫn dùng được Chế độ cơ bản**, nêu rõ tiêu chí chưa đạt (VD "Hỗ trợ AI trên máy — Không"). Chạm **Dùng chế độ cơ bản** → vào thẳng **màn chụp**, không có bước tải gì, không cần mạng.
3. Back ra, mở lại tính năng → kiểm tra **không chạy lại** đo đạc đầy đủ (vào thẳng màn chụp).
4. Cài đặt → **Kiểm tra lại cấu hình máy** → màn `scan-10` chạy lại và cập nhật mốc "Lần kiểm tra gần nhất".
5. Đo thời gian lần kiểm tra đầu: **< 5 giây** (SC-010).

## C. Màn chụp hóa đơn (FR-013, FR-014, FR-016, SC-001)

1. Lần đầu vào màn chụp: app **xin quyền camera ngay lúc này** (không xin lúc mở app).
2. Màn `scan-02`: nền **tối**, tiêu đề "Quét hóa đơn", nút back, nút **flash**, **khung ngắm nét đứt 4 góc**, dòng gợi ý *"Đặt hóa đơn vừa khung, tránh bóng đổ"*, nút **Thư viện**, nút **chụp tròn** giữa màn. **Không** có nút "Quét nhiều" (FR-016).
3. Bật/tắt flash → icon/đèn đổi trạng thái tương ứng.
4. Từ chối quyền camera → app nhắc, vẫn còn đường **Thư viện**; từ chối cả hai → quay lại màn trước, **không** lưu gì.

## D. Màn xử lý (FR-017…FR-019, SC-007)

1. Chọn `good.jpg` từ **Thư viện** → màn `scan-03`: ảnh thu nhỏ, **vệt quét**, tiêu đề "Đang xử lý hóa đơn...", **4 bước** (Đọc & xử lý ảnh hóa đơn · Nhận diện chữ (OCR on-device) · Phân tích số tiền, ngày, danh mục · Chuẩn bị màn hình xác nhận) với bước đang chạy khác bước đã xong, và dòng *"Không gửi dữ liệu lên bất kỳ máy chủ nào"*.
2. Không có màn hình trắng, không bị hiểu là treo; đo thời gian tới màn xác nhận **< 3 giây** với ảnh rõ (SC-007).
3. Chụp trực tiếp bằng camera (ảnh hóa đơn in sẵn hoặc màn hình khác) → kết quả đi đúng cùng đường xử lý như chọn từ thư viện (FR-015).

## E. Không đọc được nội dung (FR-020, SC-012)

1. Chọn `dark.jpg` → màn xử lý kết thúc bằng thông báo **"Không nhận diện được nội dung hóa đơn. Vui lòng chụp lại hoặc nhập tay."** + 2 nút **Chụp lại** / **Nhập tay**.
2. **Chụp lại** → quay về màn chụp. **Nhập tay** → mở form thêm giao dịch **trống**.
3. Kiểm tra danh sách Giao dịch: **không** có giao dịch rác nào được tạo. Kiểm tra thư mục ảnh của app: **không** có file ảnh mới.

## F. Màn xác nhận — nội dung & đối chiếu mockup `scan-04` (FR-027, FR-028, SC-001)

1. Với `good.jpg`: app bar **teal** + nút back + tiêu đề **"Xác nhận hóa đơn"**, **không** có bottom nav.
2. Trên xuống: **ảnh hóa đơn thu nhỏ** + nút **"Xem ảnh gốc"**; dòng gợi ý "Chạm vào 1 trường bên dưới để khoanh vùng đối chiếu trên ảnh"; 6 trường **Loại giao dịch / Số tiền / Ngày giờ / Cửa hàng / Ghi chú / Danh mục gợi ý / Ví áp dụng**; dòng *"Nguồn: Quét hóa đơn (AI) • xử lý hoàn toàn trên máy"*; nút **"Lưu giao dịch"** ở cuối.
3. Số tiền = **55.000** (đúng dòng TỔNG CỘNG, không phải 25.000 của dòng mặt hàng) + nhãn **"Độ tin cậy cao"** (teal). Ngày giờ = ngày trên hóa đơn. Danh mục gợi ý = **Ăn uống** (Circle K). Ví áp dụng = **ví mặc định**.
4. Chạm **"Xem ảnh gốc"** → mở ảnh gốc xem được, đóng lại về màn xác nhận không mất dữ liệu đã sửa.

## G. Khoanh vùng & độ tin cậy (FR-026, FR-029, SC-011)

1. Chạm trường **Số tiền** → ảnh gốc **khoanh vùng** đúng dòng "TỔNG CỘNG 55.000". Chạm **Ngày giờ** → khoanh đúng dòng ngày.
2. Trường Cửa hàng (suy theo cỡ chữ) hiện **coral + "Kiểm tra lại"**. Số tiền (khớp từ khoá) hiện nhãn teal. Danh mục gợi ý hiện nhãn trung tính.
3. Với `no-total.jpg`: số tiền **để trống** + coral "Kiểm tra lại"; các trường khác vẫn hiện giá trị (hoặc trống) bình thường.
4. Với `nondau.jpg`: app vẫn cố trích xuất; trường nào không chắc để trống/đánh dấu — không crash, không hiện giá trị bịa.

## H. Sửa trường & nút lưu (FR-030, FR-031, FR-032)

1. Số tiền trống (ca `no-total.jpg`) → nút **"Lưu giao dịch" không bấm được**. Nhập số tiền hợp lệ (bàn phím số hiện ra) → nút **bật lên**.
2. Sửa được: Loại giao dịch (Chi tiêu ⇄ Thu nhập), Ngày giờ (date + time picker), Cửa hàng/Ghi chú (gõ tự do), Danh mục (mở picker danh mục), Ví (chọn trong danh sách ví hoạt động).
3. Xóa trắng Cửa hàng/Ngày/Danh mục/Ví → vẫn **cho lưu** miễn Số tiền hợp lệ; riêng Ví trống ⇒ bắt chọn ví trước khi lưu (FR-030).
4. Ẩn hết ví hoặc không có ví mặc định → màn xác nhận yêu cầu chọn ví, **không** tự bịa ví.

## I. Lưu giao dịch (FR-033, FR-034, FR-038, SC-004, SC-005, SC-015)

1. Chạm **"Lưu giao dịch"** → màn xác nhận đóng; danh sách **Giao dịch** hiện giao dịch mới **ngay** (không cần mở lại app): số tiền đúng, cửa hàng nằm ở ghi chú, đúng ví đã chọn.
2. Mở **chi tiết giao dịch** đó → có hàng **"Ảnh hóa đơn"** mở xem được đúng ảnh vừa quét (SC-005).
3. Số dư ví trong **Tổng quan** giảm đúng bằng số tiền (sai lệch **0 đ**); số liệu **Báo cáo** cập nhật theo (SC-015).
4. Kiểm tra DB (hoặc bằng công cụ debug): giao dịch có `source = aiScan`; có **1 dòng** `scan_sessions` với `raw_text`, `parsed_json`, `engine = ruleBased`, `transaction_id` trỏ đúng giao dịch.
5. Bấm **"Lưu giao dịch" hai lần thật nhanh** → chỉ **một** giao dịch được tạo (FR-032).
6. Quét lại chính hóa đơn đó (cùng số tiền, cùng ngày) → màn xác nhận hiện **cảnh báo nhẹ** "Có thể trùng với giao dịch đã nhập" nhưng **vẫn lưu được**. Ca không trùng → **không** hiện cảnh báo.

## J. Huỷ giữa luồng (FR-036, SC-004)

1. Đang ở màn xác nhận (đã sửa vài trường) → bấm **back**.
2. Kiểm tra: **không** có giao dịch mới; **không** có file ảnh mới trong kho đính kèm; **không** có bản ghi `scan_sessions` mới. Mở lại luồng quét → bắt đầu từ đầu, không có dữ liệu quét dở.
3. Làm lại với các điểm thoát khác: back ở màn chụp, đóng app (kill) giữa lúc màn xử lý đang chạy → không có gì được lưu.

## K. Ngoại tuyến hoàn toàn (FR-037, SC-006)

1. Bật **chế độ máy bay** (tắt Wifi + dữ liệu di động) → chạy trọn luồng: chụp/chọn ảnh → xử lý → xác nhận → lưu. **Tất cả** phải hoàn tất, không có cảnh báo mạng, không màn hình chờ mạng.

## L. Ngôn ngữ, giao diện tối, cỡ chữ lớn (FR-039, FR-040, FR-041, SC-013, SC-014)

1. Đổi sang **English** (Tiện ích → Ngôn ngữ) → đi qua **toàn bộ** luồng (sheet, màn chụp, màn xử lý, màn xác nhận, màn kiểm tra cấu hình, mục Cài đặt): **0** nhãn tiếng Việt còn sót; số tiền vẫn định dạng `55.000 đ`.
2. Đổi sang **chế độ Tối** → mọi màn dùng đúng bộ màu tối; **màn chụp vẫn nền tối** bất kể chế độ màu; chữ/số đủ tương phản; coral chỉ xuất hiện ở cảnh báo/chi tiêu.
3. Đặt **cỡ chữ lớn nhất** (Cài đặt hệ thống) + màn hình nhỏ → màn xác nhận và màn kiểm tra cấu hình **không vỡ bố cục**, không trường/nút nào bị che, cuộn được tới nút "Lưu giao dịch" và tới thẻ kết quả.
4. Kiểm tra thêm với bàn phím số đang mở ở trường Số tiền (bàn phím không che nút lưu).

---

## Chặng 2 — chỉ chạy trên thiết bị thật đủ điều kiện

## M. Tier A — máy có Gemini Nano (Pixel 8+/S24+ có AICore) (FR-005, FR-007, FR-010, SC-009)

1. Mở luồng quét lần đầu → màn `scan-10` báo **Đủ điều kiện — Tier A**, mô tả "Model do hệ thống Android quản lý — không cần tải thêm", nút **Kích hoạt Gemini Nano**.
2. Kích hoạt → quét `good.jpg` → màn xác nhận có kết quả; phiên quét ghi `engine = geminiNano`.
3. Ép model lỗi/timeout (hoặc tắt AICore nếu được) → app **tự chuyển sang bộ luật cơ bản cho riêng lần quét đó**, vẫn ra màn xác nhận, người dùng **không** phải chụp lại, **không** thấy thông báo lỗi kỹ thuật; phiên quét ghi `engine = ruleBased` (SC-009).
4. Đo thời gian xử lý: **< 10 giây**, màn xử lý luôn hiện tiến trình.

## N. Tier B — tải/xoá model (~1.8GB) (FR-004, FR-007, FR-012, SC-009)

1. Máy đủ điều kiện nhưng không có AICore → màn `scan-10` báo **Đủ điều kiện dùng Gemma 3n E2B**, dung lượng cần tải, khuyến nghị Wifi, 2 lựa chọn **Tải model (1.8GB)** / **Dùng chế độ cơ bản**.
2. Chọn **Dùng chế độ cơ bản** → không tải gì, vào màn chụp, luồng chạy bình thường; Cài đặt hiện "Chế độ cơ bản".
3. Chọn **Tải model** → có tiến trình tải; ngắt mạng giữa chừng → app vẫn ở Chế độ cơ bản, tải lại được sau. Tải xong → báo sẵn sàng; lần quét kế tiếp dùng AI nâng cao (phiên quét ghi `engine = gemma3nE2b`).
4. Cài đặt → khối trạng thái hiện **dung lượng model đang chiếm** + **Xoá model** + **Kiểm tra cập nhật model**. Xoá model → giải phóng dung lượng, quay về Chế độ cơ bản, tính năng vẫn dùng được; **giao dịch đã lưu không bị ảnh hưởng**.
5. Thiết bị không đủ dung lượng để tải → app báo không đủ dung lượng, đề nghị giải phóng hoặc dùng Chế độ cơ bản.
