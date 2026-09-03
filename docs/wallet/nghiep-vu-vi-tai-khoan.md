# NGHIỆP VỤ CHI TIẾT: QUẢN LÝ VÍ/TÀI KHOẢN (Wallets & Accounts)

> Tài liệu bổ sung chi tiết cho mục "2. Quản lý Ví/Tài khoản" trong tài liệu tính năng nghiệp vụ chung, dùng làm tham chiếu khi triển khai app quản lý thu chi (Flutter Mobile).

---

## 1. Loại ví hỗ trợ

| Loại ví | Đặc thù xử lý |
|---|---|
| Tiền mặt | Không có số tài khoản/thẻ, số dư điều chỉnh tự do |
| Tài khoản ngân hàng | Có thể gắn nhãn ngân hàng (tên, logo tham chiếu), số cuối tài khoản (chỉ hiển thị, không lưu số thật) |
| Thẻ tín dụng | Có thêm: hạn mức tín dụng, ngày sao kê, ngày đến hạn thanh toán → số dư hiển thị dạng "đã dùng/hạn mức" thay vì số dư dương thông thường |
| Ví điện tử (Momo, ZaloPay...) | Tương tự tài khoản ngân hàng, gắn icon thương hiệu ví |
| Sổ tiết kiệm | Có thêm: kỳ hạn, ngày đáo hạn, lãi suất (tùy chọn) — không dùng để chi tiêu trực tiếp, chỉ để theo dõi |

---

## 2. Trường dữ liệu của một Ví

- Tên ví (bắt buộc), loại ví, icon, màu sắc
- Số dư ban đầu (bắt buộc khi tạo — dùng làm mốc, không sửa lại sau khi đã phát sinh giao dịch mà phải qua nghiệp vụ "điều chỉnh số dư")
- Số dư hiện tại (tính toán = số dư ban đầu + tổng thu − tổng chi ± chuyển khoản, không cho sửa tay trực tiếp)
- Tiền tệ của ví (mặc định theo cài đặt chung, có thể override riêng từng ví)
- Trạng thái: đang dùng / đã ẩn (ẩn không xóa — vẫn giữ lịch sử)
- Cờ "ví mặc định" (chỉ 1 ví được đánh dấu mặc định tại một thời điểm)
- Riêng thẻ tín dụng: hạn mức, ngày sao kê, ngày đến hạn
- Riêng sổ tiết kiệm: kỳ hạn, ngày đáo hạn

---

## 3. Nghiệp vụ tạo/sửa/xóa

- **Tạo mới**: bắt buộc Tên + Loại + Số dư ban đầu + Tiền tệ. Nếu là ví đầu tiên → tự động đặt làm mặc định.
- **Sửa**: cho sửa tên, icon, màu, hạn mức (thẻ tín dụng)... nhưng **không** cho sửa trực tiếp số dư hiện tại (tránh sai lệch dữ liệu lịch sử) — muốn điều chỉnh phải tạo giao dịch "Điều chỉnh số dư" (dạng thu/chi đặc biệt, có ghi chú lý do, ví dụ: đối soát thực tế).
- **Ẩn ví**: ví bị ẩn không hiển thị trong danh sách chọn ví khi nhập giao dịch mới, không tính vào "tổng số dư" hiển thị nhanh (có tùy chọn bật/tắt tính vào tổng), nhưng lịch sử giao dịch cũ vẫn giữ nguyên và xem được trong báo cáo.
- **Xóa**: chỉ cho xóa cứng nếu ví **chưa từng phát sinh giao dịch nào**; nếu đã có giao dịch → chỉ được ẩn, phải cảnh báo rõ và gợi ý ẩn thay vì xóa.
- Nếu xóa/ẩn ví đang là ví mặc định → hệ thống tự động chuyển ví mặc định sang ví khác (ưu tiên ví có số dư dương gần nhất được dùng).

---

## 4. Chuyển tiền giữa các ví (Transfer)

- Là một loại giao dịch riêng biệt (không phải Thu/Chi) → **không** tính vào tổng thu/tổng chi trong báo cáo, chỉ ảnh hưởng số dư từng ví.
- Trường dữ liệu: Ví nguồn, Ví đích, số tiền, ngày giờ, phí chuyển khoản (tùy chọn — nếu có phí thì phí đó được ghi nhận như một khoản Chi riêng, danh mục "Phí giao dịch").
- Ràng buộc: Ví nguồn ≠ Ví đích.
- Nếu 2 ví khác loại tiền tệ → yêu cầu nhập tỷ giá quy đổi tại thời điểm chuyển (lưu lại tỷ giá đã dùng, không tính lại về sau).
- Không chặn chuyển khi ví nguồn không đủ số dư (ví tiền mặt có thể âm tạm thời), nhưng hiển thị cảnh báo mềm "Số dư sau chuyển sẽ âm".
- Sinh ra 2 bút toán liên kết (linked entries) trên 2 ví, xóa 1 bên phải xóa đồng thời bên còn lại.

---

## 5. Tính toán & hiển thị số dư

- Số dư ví = Σ(Thu) − Σ(Chi) ± Σ(Chuyển khoản liên quan) + số dư ban đầu, tính real-time mỗi khi có giao dịch mới/sửa/xóa.
- Tổng số dư toàn bộ ví = tổng các ví đang hoạt động (không ẩn), quy đổi về tiền tệ mặc định theo tỷ giá cấu hình (tỷ giá nhập tay hoặc lấy theo bảng tỷ giá lưu sẵn, offline nên không gọi API tỷ giá real-time).
- Thẻ tín dụng: hiển thị "Đã dùng / Hạn mức" và % sử dụng, đồng thời cảnh báo nếu gần chạm hạn mức.
- Chế độ Privacy: khi bật "ẩn số dư", toàn bộ số tiền trong màn hình ví thay bằng "••••••".

---

## 6. Sắp xếp & ví mặc định

- Danh sách ví có thể kéo-thả sắp xếp thứ tự hiển thị thủ công.
- Ví mặc định dùng để pre-select khi vào màn hình "Thêm giao dịch nhanh", giảm thao tác cho người dùng.

---

## 7. Gợi ý mô hình dữ liệu (Flutter — drift)

```
wallets
  id, name, wallet_type (enum), icon, color
  initial_balance, currency
  is_default (bool), is_hidden (bool), sort_order
  credit_limit, statement_date, due_date        -- chỉ dùng cho thẻ tín dụng
  term_months, maturity_date                    -- chỉ dùng cho sổ tiết kiệm
  created_at, updated_at

transactions
  id, wallet_id, type (income/expense/transfer/adjustment)
  amount, category_id, note, tags, receipt_image, location
  transaction_date
  transfer_group_id (nullable)   -- liên kết 2 dòng của 1 lần Transfer
  exchange_rate (nullable)       -- lưu tỷ giá dùng khi transfer khác tiền tệ
```

**Lưu ý triển khai:**
- Tách `initial_balance` khỏi `current_balance` (số dư hiện tại tính toán/cache), tránh sửa tay gây sai lệch lịch sử.
- Giao dịch Transfer lưu 2 dòng liên kết bằng `transfer_group_id` để đảm bảo xóa/sửa đồng bộ cả hai vế.
- Component "% sử dụng hạn mức" của thẻ tín dụng nên tách thành widget dùng chung, tái sử dụng được cho màn Ngân sách sau này.

---

## 8. Danh sách màn hình đính kèm (SVG)

| File | Mô tả |
|---|---|
| `wallet-list-screen.svg` | Danh sách ví — sub-page từ Cài đặt, card tổng số dư + ListTile từng ví |
| `wallet-add-edit-form.svg` | Form thêm/sửa ví — chọn loại ví dạng chip, số dư ban đầu, icon/màu, toggle mặc định |
| `wallet-detail-screen.svg` | Chi tiết 1 ví — số dư lớn, 3 hành động nhanh, giao dịch gần đây trong ví |
| `wallet-transfer-screen.svg` | Chuyển tiền giữa ví — chọn ví nguồn/đích, số tiền, số dư sau chuyển |
