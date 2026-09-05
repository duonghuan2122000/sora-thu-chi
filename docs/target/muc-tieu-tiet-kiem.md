# NGHIỆP VỤ: MỤC TIÊU TIẾT KIỆM (SAVINGS GOALS)

> Tài liệu chi tiết hóa mục 6 trong "Tính năng nghiệp vụ app quản lý thu chi" — dùng làm tham chiếu khi triển khai backend, model dữ liệu và UI cho tính năng Mục tiêu tiết kiệm.

---

## 1. Cấu trúc dữ liệu

### Bảng `SavingsGoal`

| Trường | Kiểu | Mô tả |
|---|---|---|
| `id` | string/uuid | Định danh mục tiêu |
| `ten_muc_tieu` | string | Tên hiển thị (VD: "Mua xe máy") |
| `icon` | string | Icon đại diện |
| `mau_sac` | string | Mã màu (chọn từ bộ màu app hoặc tùy chỉnh) |
| `so_tien_muc_tieu` | decimal | Số tiền cần đạt (target amount) |
| `so_tien_da_tiet_kiem` | decimal | Tổng đã nạp — tính từ các bản ghi `SavingsContribution`, không lưu trực tiếp (derived field) |
| `han_chot` | date, optional | Hạn hoàn thành mục tiêu — có thể để trống nếu là quỹ dài hạn không hạn định |
| `vi_nguon_id` | reference, optional | Ví liên kết. Nếu có: tiền nạp bị "khóa", trừ khỏi số dư khả dụng của ví đó. Nếu không: mục tiêu ảo, chỉ theo dõi tiến độ, không ảnh hưởng số dư ví nào |
| `trang_thai` | enum | `dang_thuc_hien` / `hoan_thanh` / `qua_han` / `da_huy` |
| `nap_dinh_ky_goi_y` | object, optional | `{ so_tien, chu_ky: tuan/thang }` — dùng để tính tiến độ kỳ vọng và nhắc nhở |
| `ngay_tao` | datetime | |
| `ghi_chu` | string, optional | |

### Bảng `SavingsContribution` (lịch sử đóng góp)

| Trường | Kiểu | Mô tả |
|---|---|---|
| `id` | string/uuid | |
| `goal_id` | reference | Mục tiêu liên quan |
| `so_tien` | decimal | Dương = nạp tiền, âm = rút tiền |
| `vi_id` | reference | Ví nguồn (khi nạp) hoặc ví đích (khi rút) |
| `ngay_gio` | datetime | |
| `ghi_chu` | string, optional | |

---

## 2. Luồng nghiệp vụ chính

### 2.1. Tạo mục tiêu
- Nhập tên, chọn icon/màu
- Nhập số tiền mục tiêu
- Chọn hạn chót (tùy chọn)
- Chọn ví nguồn (tùy chọn — quyết định mục tiêu có "khóa tiền thật" hay chỉ là theo dõi ảo)
- Nhập số tiền ban đầu (tùy chọn — được ghi nhận như lần đóng góp đầu tiên)
- Thiết lập nạp định kỳ gợi ý (tùy chọn)

### 2.2. Nạp tiền vào mục tiêu
- **Thủ công:** nhập số tiền + chọn ví trừ tiền → tạo một bản ghi `SavingsContribution`, đồng thời tạo giao dịch loại **"Chuyển khoản nội bộ"** (không phải Expense) trừ từ ví nguồn
- **Tự động theo lịch:** cơ chế tương tự Recurring Transaction — đến kỳ, hệ thống tự tạo contribution (có thể yêu cầu xác nhận, hoặc tự động nếu người dùng đã bật)

### 2.3. Rút tiền khỏi mục tiêu
- Dùng khi cần tiền gấp — tạo contribution âm, hoàn tiền về ví nguồn (nếu mục tiêu có gắn ví)

### 2.4. Theo dõi tiến độ
- `% hoàn thành = so_tien_da_tiet_kiem / so_tien_muc_tieu`
- Số tiền còn thiếu = `so_tien_muc_tieu - so_tien_da_tiet_kiem`
- Số ngày còn lại đến hạn chót
- Tốc độ nạp trung bình/tháng (tính từ lịch sử `SavingsContribution`)
- Dự đoán ngày hoàn thành dựa trên tốc độ hiện tại
- Nếu tốc độ dự đoán chậm hơn hạn chót → cảnh báo "Cần nạp thêm X đ/tháng để kịp hạn"

### 2.5. Hoàn thành mục tiêu
- Khi `so_tien_da_tiet_kiem >= so_tien_muc_tieu` → tự động chuyển `trang_thai = hoan_thanh`
- Gửi thông báo chúc mừng
- Cho phép chọn: "Rút toàn bộ về ví" hoặc "Giữ nguyên, tiếp tục làm quỹ"

### 2.6. Nhắc nhở
- Theo lịch nạp định kỳ đã đặt (VD: mỗi tháng ngày 5 nhắc nạp 2 triệu)
- Khi gần hạn chót mà tiến độ chậm hơn kỳ vọng
- Khi hoàn thành mục tiêu

### 2.7. Lịch sử & quản lý
- Xem danh sách các lần nạp/rút: ngày, số tiền, ví nguồn/đích
- Sắp xếp/lọc danh sách mục tiêu theo: hạn chót gần nhất, % hoàn thành, trạng thái

---

## 3. Edge case cần xử lý

| Tình huống | Xử lý |
|---|---|
| Hạn chót đã qua nhưng chưa đủ tiền | Chuyển `trang_thai = qua_han`; cho phép gia hạn hạn chót ngay tại màn chi tiết |
| Xóa mục tiêu đang có tiền | Hỏi rõ "Hoàn tiền đã nạp về ví nguồn?" trước khi xóa |
| Mục tiêu không gắn ví (ảo) | Không ảnh hưởng số dư ví nào, chỉ để theo dõi tiến độ cá nhân |
| Mục tiêu có gắn ví | Tiền nạp thực sự bị cô lập, trừ khỏi số dư khả dụng của ví |

---

## 4. Ảnh hưởng đến Báo cáo & Thống kê

- Khoản đóng góp vào mục tiêu tiết kiệm **không được tính là "chi tiêu" (expense)** trong báo cáo thu/chi theo danh mục — bản chất là chuyển khoản nội bộ (giống Transfer giữa các ví), tránh làm méo biểu đồ chi tiêu theo danh mục
- Nên có mục riêng **"Tiết kiệm"** trong màn Tổng quan/Báo cáo, tách biệt khỏi luồng thu/chi thông thường

---

## 5. Giai đoạn triển khai

Theo lộ trình chung của app, "Mục tiêu tiết kiệm" thuộc **Giai đoạn 3** (sau MVP và Giai đoạn 2 gồm Ngân sách, Giao dịch định kỳ, Nhắc nhở, Xuất báo cáo).

---

## 6. Màn hình thiết kế (tham chiếu file SVG đính kèm)

| File | Mô tả |
|---|---|
| `01-danh-sach-muc-tieu.svg` | Danh sách mục tiêu — header hiển thị tổng đã tiết kiệm, card từng mục tiêu với thanh tiến độ, % và số ngày còn lại, FAB thêm mới |
| `02-chi-tiet-muc-tieu.svg` | Chi tiết mục tiêu — vòng tròn tiến độ, các chỉ số (hạn chót, còn thiếu, tốc độ nạp TB), nút Nạp tiền/Rút tiền, lịch sử đóng góp |
| `03-tao-muc-tieu-moi.svg` | Form tạo mục tiêu mới — icon, tên, số tiền mục tiêu, hạn chót, ví nguồn, số tiền ban đầu |
| `04-nap-tien-bottom-sheet.svg` | Bottom sheet nạp tiền — nhập số tiền, chọn ví nguồn dạng chip, bàn phím số theo style PIN keypad của design system |

Tất cả màn hình tuân thủ design system chung của app: màu thương hiệu teal `#0F6E56`, coral `#D85A30` cho ngữ cảnh chi tiêu/cảnh báo, bo góc card `10px`, khung màn hình `28px`, font Roboto (Material Design).
