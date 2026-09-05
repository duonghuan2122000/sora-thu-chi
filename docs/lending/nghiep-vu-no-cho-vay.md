# GIẢI PHÁP NGHIỆP VỤ: QUẢN LÝ NỢ & CHO VAY (DEBT & LENDING)

> Chi tiết hóa mục 7 trong tài liệu "Tính năng nghiệp vụ App Quản lý Thu Chi" — dùng làm tài liệu tham chiếu khi thiết kế DB, API và UI.

---

## 1. Mục tiêu & Phạm vi

- Cho phép người dùng ghi nhận và theo dõi **hai chiều công nợ**:
  - **Khoản tôi vay** (Borrow): mình vay tiền của người khác → mình là người **nợ**.
  - **Khoản tôi cho vay** (Lend): mình cho người khác vay → mình là người **được nợ**, cần thu hồi.
- Theo dõi tiến độ trả/thu theo từng phần (partial payment), không bắt buộc trả 1 lần.
- Liên kết chặt với **Ví** (số dư thay đổi khi phát sinh/thanh toán khoản nợ) và **Giao dịch** (sinh giao dịch tự động, có cờ riêng để không làm sai lệch báo cáo thu chi thường xuyên).
- Nhắc nhở đến hạn, cảnh báo quá hạn.
- **Ngoài phạm vi giai đoạn này:** tính lãi suất kép/lãi phạt tự động phức tạp, chia sẻ khoản nợ nhóm (thuộc mục "Chia sẻ & Cộng tác" — chưa triển khai).

---

## 2. Khái niệm & Thuật ngữ

| Thuật ngữ | Diễn giải |
|---|---|
| **Khoản vay (Borrow)** | Mình vay tiền của một người/đơn vị khác. Khi tạo → tiền **vào ví** mình. Khi trả → tiền **ra khỏi ví** mình. |
| **Khoản cho vay (Lend)** | Mình cho một người khác vay tiền. Khi tạo → tiền **ra khỏi ví** mình. Khi thu hồi → tiền **vào ví** mình. |
| **Đối tượng công nợ (Counterpart)** | Người/đơn vị liên quan đến khoản vay hoặc cho vay (không cần là user hệ thống — chỉ là tên tham chiếu, giống danh bạ). |
| **Số tiền gốc (Principal)** | Số tiền vay/cho vay ban đầu, không đổi trong suốt vòng đời khoản nợ. |
| **Số tiền còn lại (Remaining amount)** | `Principal − Tổng các khoản đã trả/thu`. Giảm dần theo thời gian. |
| **Kỳ thanh toán / Lịch sử thanh toán (Payment record)** | Mỗi lần trả góp hoặc thu hồi một phần được ghi lại thành 1 bản ghi riêng, có ngày, số tiền, ví áp dụng. |
| **Tất toán (Settle/Close)** | Đánh dấu khoản nợ đã kết thúc — hoặc vì đã trả/thu đủ, hoặc do người dùng chủ động đóng (xóa nợ, thỏa thuận miễn nợ...). |

---

## 3. Mô hình dữ liệu (Data Model)

### 3.1. Bảng `Debt` (Khoản vay / Khoản cho vay)

| Trường | Kiểu | Bắt buộc | Ghi chú |
|---|---|---|---|
| `id` | UUID | ✔ | Khóa chính |
| `type` | enum(`borrow`, `lend`) | ✔ | Loại khoản: mình vay / mình cho vay |
| `counterpart_name` | string | ✔ | Tên người vay/cho vay |
| `counterpart_phone` | string | — | Số điện thoại liên hệ (tùy chọn, hỗ trợ pick từ danh bạ) |
| `principal_amount` | decimal | ✔ | Số tiền gốc, > 0 |
| `currency` | string | ✔ | Mặc định theo tiền tệ của ví liên kết |
| `interest_enabled` | boolean | ✔ | Có tính lãi hay không (mặc định `false`) |
| `interest_rate` | decimal | — | %/tháng hoặc %/năm (chỉ hiện khi `interest_enabled = true`) |
| `interest_type` | enum(`simple_monthly`, `simple_yearly`) | — | Cách tính lãi đơn giản, tham khảo, không bắt buộc chính xác tuyệt đối |
| `wallet_id` | FK → Wallet | ✔ | Ví nhận tiền (borrow) hoặc ví xuất tiền (lend) khi tạo khoản |
| `start_date` | date | ✔ | Ngày phát sinh khoản vay/cho vay |
| `due_date` | date | — | Hạn tất toán dự kiến (không bắt buộc) |
| `note` | text | — | Ghi chú tự do |
| `attachment_url` | string | — | Ảnh giấy vay nợ/hợp đồng đính kèm |
| `status` | enum(`active`, `overdue`, `completed`, `cancelled`) | ✔ | Trạng thái hiện tại (xem mục 4) |
| `remaining_amount` | decimal (computed/cached) | ✔ | = `principal_amount − SUM(DebtPayment.amount)` |
| `created_at` / `updated_at` | datetime | ✔ | |

### 3.2. Bảng `DebtPayment` (Lịch sử thanh toán từng phần)

| Trường | Kiểu | Bắt buộc | Ghi chú |
|---|---|---|---|
| `id` | UUID | ✔ | Khóa chính |
| `debt_id` | FK → Debt | ✔ | Khoản nợ liên quan |
| `amount` | decimal | ✔ | Số tiền trả/thu đợt này, > 0 |
| `payment_date` | date | ✔ | Ngày thanh toán |
| `wallet_id` | FK → Wallet | ✔ | Ví áp dụng cho đợt thanh toán này |
| `note` | text | — | Ghi chú riêng cho đợt trả |
| `transaction_id` | FK → Transaction | ✔ | Giao dịch tự động sinh ra tương ứng (xem mục 7) |
| `created_at` | datetime | ✔ | |

### 3.3. Bảng `DebtReminder` (tùy chọn — tái sử dụng engine nhắc nhở chung)

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `debt_id` | FK → Debt | |
| `remind_before_days` | int | Nhắc trước hạn bao nhiêu ngày (mặc định 3) |
| `is_enabled` | boolean | |

---

## 4. Trạng thái khoản nợ (State Machine)

```
[Tạo mới] ──► active ──(trả/thu đủ 100%)──► completed
                │                              ▲
                │ (quá due_date & chưa đủ)     │ (người dùng chủ động
                ▼                              │  "Đánh dấu đã tất toán")
             overdue ─────────────────────────┘
                │
                └──(người dùng hủy khoản, chưa phát sinh thanh toán)──► cancelled
```

- `active`: đang trong hạn, `remaining_amount > 0`.
- `overdue`: **tính toán động** mỗi lần hiển thị (không cần job nền bắt buộc): `due_date < today AND remaining_amount > 0`.
- `completed`: `remaining_amount <= 0` **hoặc** người dùng bấm "Đánh dấu đã tất toán" thủ công.
- `cancelled`: hủy khoản nợ vừa tạo do nhập nhầm, chưa có `DebtPayment` nào — cho phép xóa cứng; nếu đã có thanh toán thì không cho hủy, chỉ cho "tất toán".

---

## 5. Luồng nghiệp vụ chi tiết

### 5.1. Tạo mới khoản vay / cho vay
1. Người dùng chọn loại: **"Tôi vay nợ"** hoặc **"Tôi cho vay"**.
2. Nhập thông tin: người vay/cho vay (gõ tay hoặc chọn từ danh bạ máy), số tiền gốc, ví áp dụng, ngày bắt đầu (mặc định hôm nay), ngày đến hạn (tùy chọn), lãi suất (tùy chọn, mặc định tắt), ghi chú, ảnh đính kèm.
3. Khi lưu, hệ thống:
   - Tạo bản ghi `Debt` với `remaining_amount = principal_amount`, `status = active`.
   - Tự động sinh **1 giao dịch** gắn cờ đặc biệt `is_debt_related = true`:
     - Nếu `type = borrow`: giao dịch **Thu** vào ví đã chọn (tiền vay về).
     - Nếu `type = lend`: giao dịch **Chi** ra khỏi ví đã chọn (tiền cho vay đi).
   - Giao dịch này **cập nhật số dư ví** như bình thường nhưng **không tính vào danh mục thu/chi báo cáo mặc định** (giống cách xử lý `Transfer` — tách riêng để không làm sai lệch biểu đồ "thu nhập/chi tiêu thực tế").

### 5.2. Ghi nhận thanh toán / thu hồi từng phần
1. Từ màn hình chi tiết khoản nợ, người dùng bấm **"Ghi nhận thanh toán"**.
2. Nhập: số tiền, ngày thanh toán, ví áp dụng, ghi chú.
3. Validate: `amount > 0` và `amount <= remaining_amount` (nếu vượt → cảnh báo "Số tiền vượt quá số còn lại, bạn có muốn ghi nhận trả dư?" cho phép xác nhận tiếp tục nếu người dùng cố ý).
4. Hệ thống:
   - Tạo bản ghi `DebtPayment`.
   - Sinh 1 giao dịch tương ứng gắn cờ `is_debt_related = true`:
     - `type = borrow` → giao dịch **Chi** (mình trả nợ).
     - `type = lend` → giao dịch **Thu** (mình thu hồi nợ).
   - Cập nhật `remaining_amount -= amount`.
   - Nếu `remaining_amount <= 0` → tự động chuyển `status = completed`, hiển thị thông báo chúc mừng hoàn tất khoản nợ.

### 5.3. Tất toán thủ công
- Cho phép đánh dấu **"Đã tất toán"** dù `remaining_amount > 0` (trường hợp được xóa nợ, tha nợ, thỏa thuận miệng...).
- Bắt buộc xác nhận qua dialog, ghi log: *"Đã tất toán, xóa phần còn lại: {remaining_amount} đ"* lưu vào `note` hệ thống của khoản nợ để tra cứu sau.
- Không hoàn lại/không tạo giao dịch điều chỉnh số dư ví cho phần bị xóa (vì đây không phải dòng tiền thực).

### 5.4. Sửa / Xóa
- **Sửa**: cho sửa thông tin mô tả (tên, ghi chú, hạn, lãi suất, ảnh). Số tiền gốc chỉ cho sửa khi **chưa có bất kỳ `DebtPayment` nào**, để tránh sai lệch số liệu đã phát sinh.
- **Xóa**: yêu cầu xác nhận rõ ràng; xóa khoản nợ sẽ xóa toàn bộ `DebtPayment` liên quan và **hỏi người dùng** có muốn xóa luôn các giao dịch (`Transaction`) đã sinh ra hay chỉ gỡ liên kết (giữ giao dịch nhưng bỏ cờ `is_debt_related`).

### 5.5. Nhắc nhở & Thông báo
- Nhắc trước hạn `due_date` theo số ngày cấu hình (mặc định 3 ngày), tái sử dụng engine `flutter_local_notifications` đã có.
- Nếu quá hạn mà `remaining_amount > 0`: đẩy thông báo định kỳ (VD: 3 ngày/lần) cho đến khi được xử lý hoặc tất toán.
- Khi hoàn tất 100%: thông báo tổng kết "Bạn đã tất toán khoản vay với {counterpart_name}".

---

## 6. Quy tắc tính toán

| Công thức | Diễn giải |
|---|---|
| `remaining_amount = principal_amount − Σ(DebtPayment.amount)` | Luôn tính lại (hoặc cache + đồng bộ mỗi khi có payment mới) |
| `progress_percent = Σ(DebtPayment.amount) / principal_amount × 100` | Hiển thị thanh tiến độ |
| `is_overdue = due_date < today AND remaining_amount > 0` | Tính động lúc hiển thị, không lưu cứng trạng thái `overdue` vào DB trừ khi cần lọc nhanh (có thể có job nền cập nhật cache hằng ngày) |
| `estimated_interest = principal_amount × interest_rate × (số kỳ đã trôi qua)` | Chỉ mang tính tham khảo hiển thị, **không** tự động cộng dồn vào `remaining_amount` trong MVP — người dùng tự cộng thủ công nếu muốn thu thêm lãi |

---

## 7. Liên kết với các module khác

| Module | Cách liên kết |
|---|---|
| **Ví (Wallets)** | Mỗi khoản vay/cho vay và mỗi lần thanh toán đều gắn với 1 ví cụ thể, ảnh hưởng trực tiếp số dư ví — xử lý tương tự cơ chế `Transfer` (không phải Thu/Chi thường). |
| **Giao dịch (Transactions)** | Mọi phát sinh tiền (tạo khoản, thanh toán từng phần) đều tự động sinh giao dịch có cờ `is_debt_related = true` + liên kết `debt_id`, giúp truy vết 2 chiều: từ khoản nợ xem ra giao dịch, và từ lịch sử giao dịch biết giao dịch nào thuộc về khoản nợ nào. |
| **Báo cáo (Reports)** | Có khối riêng "Tổng nợ phải trả" / "Tổng nợ phải thu" ở màn Tổng quan hoặc Báo cáo; **loại trừ** các giao dịch `is_debt_related` khỏi biểu đồ thu/chi theo danh mục mặc định để không làm sai lệch bức tranh chi tiêu thực tế. |
| **Danh mục (Categories)** | Có thể gán ngầm định danh mục hệ thống "Vay/Nợ" cho các giao dịch tự sinh, ẩn khỏi bộ lọc danh mục thông thường nhưng vẫn xem được khi lọc riêng "Tất cả giao dịch nợ vay". |
| **Thông báo (Notifications)** | Dùng chung hạ tầng nhắc nhở định kỳ với "Giao dịch định kỳ" (mục 3 tài liệu gốc). |

---

## 8. Validate & Edge case

- `principal_amount` phải > 0; không cho lưu nếu để trống hoặc = 0.
- Khi tạo khoản **cho vay (lend)**: nếu ví áp dụng không đủ số dư, hiển thị cảnh báo mềm (không chặn cứng — tùy chọn cho phép số dư âm, đồng bộ với hành vi Chi tiêu thông thường trong app).
- Số tiền thanh toán từng phần > 0 và nên ≤ `remaining_amount`; nếu vượt, yêu cầu xác nhận rõ ràng (tránh nhập nhầm số 0 thừa).
- Không cho sửa `principal_amount` sau khi đã có `DebtPayment` (tránh lệch số liệu lịch sử).
- Xóa khoản nợ đã có giao dịch liên kết → luôn hỏi rõ có xóa giao dịch liên quan hay không.
- Khoản nợ khác tiền tệ với ví mặc định của app → cần quy đổi tỷ giá khi gộp vào "Tổng nợ phải trả/thu" ở Tổng quan (dùng chung cơ chế quy đổi đa tiền tệ đã có ở mục 2 tài liệu gốc).
- Một khoản nợ `cancelled` không được phép có `DebtPayment` — nếu đã phát sinh thanh toán, chặn thao tác hủy, chỉ cho phép tất toán.

---

## 9. Danh sách màn hình cần thiết

1. **Danh sách Nợ & Cho vay** — 2 tab (Tôi cho vay / Tôi vay nợ), tổng quan 2 số liệu lớn, danh sách từng khoản kèm tiến độ và trạng thái.
2. **Chi tiết khoản vay/cho vay** — thông tin đối tượng, số tiền còn lại, tiến độ, thông tin chi tiết, lịch sử thanh toán, hành động Ghi nhận thanh toán / Tất toán.
3. **Form Thêm mới khoản vay/cho vay** — chọn loại, nhập thông tin, đính kèm ảnh.
4. **Form Ghi nhận thanh toán/thu hồi** — nhập số tiền, ngày, ví áp dụng.
5. *(Bổ sung, không thiết kế trong đợt này)*: Dialog xác nhận tất toán/xóa; màn hình lọc/tìm kiếm công nợ.

---

## 10. Đề xuất mở rộng (giai đoạn sau)

- Tự động cộng dồn lãi suất vào số tiền còn lại theo chu kỳ (thay vì chỉ hiển thị tham khảo).
- Xuất báo cáo công nợ riêng (PDF/Excel) — danh sách ai đang nợ mình, mình đang nợ ai.
- Gắn khoản nợ với danh bạ thật (đồng bộ contact), gợi ý counterpart đã từng nhập trước đó.
- Khi tính năng "Chia sẻ & Cộng tác" được triển khai: cho phép 2 người dùng cùng xác nhận 1 khoản nợ (đối chiếu 2 chiều), giảm sai lệch số liệu.
