# Mô hình dữ liệu — PBI 8: Chuyển tiền giữa các ví

Ngày: 2026-09-05

## Phạm vi thay đổi

Thêm **1 bảng drift** (`transactions`, schemaVersion 1 → 2). Bảng `wallets` giữ nguyên 18 cột (PBI 7). Chưa tạo bảng `categories`/danh mục — cột `category` đợt này là chữ tạm (research R3).

## Thực thể

### 1. Ví (wallet) — không đổi schema

Như data-model PBI 7. Trong phạm vi PBI 8, một ví đóng vai trò **nguồn** hoặc **đích** của khoản chuyển.

| Thuộc tính | Kiểu | Ghi chú |
|---|---|---|
| `id` | int | PK autoincrement |
| `balance` | int | Cache số dư (đại lượng suy ra ở đời thật — đợt này là cột cache, PBI 7). Transfer trừ nguồn / cộng đích đúng số tiền (R4) |
| `initial_balance` | int | Nền số dư, bất biến khi đã có giao dịch |
| `currency` | text | Chuyển chỉ hợp lệ giữa hai ví cùng giá trị (đợt này `'VND'`) |
| `wallet_type` | enum | `credit` **loại trừ** khỏi nguồn/đích; `savings` chuyển như ví thường |
| `is_hidden` | bool | Ví ẩn không vào danh sách chọn đích; ví ẩn đang đứng ở màn chi tiết vẫn làm được nguồn |

**Luật ràng buộc áp cho ví (PBI 8):**
- Nguồn ≠ đích, cùng `currency`, cùng người dùng.
- Nguồn/đích không phải thẻ tín dụng (FR-018). Sổ tiết kiệm được chuyển như ví thường.
- Chuyển vượt số dư nguồn **không chặn** — chỉ cảnh báo mềm (số dư nguồn có thể âm tạm thời).

### 2. Giao dịch (transactions) — bảng mới

Biểu diễn thu/chi/điều chỉnh/chuyển khoản. PBI 8 chỉ **ghi** loại chuyển khoản; 11 dòng mẫu (thu/chi/chuyển) được seed để giữ liên tục demo (R2).

| Cột drift | Kiểu | Yêu cầu | Ghi chú |
|---|---|---|---|
| `id` | int | PK autoincrement | |
| `wallet_id` | int | NOT NULL | Ví chứa dòng; index đơn |
| `type` | textEnum`<TxnType>` | NOT NULL | `income`/`expense`/`transfer`/`adjustment` |
| `amount` | int | NOT NULL | **Signed** — tác động ròng lên ví chứa dòng: thu `+`, chi `−`; transfer vế nguồn `−x`, vế đích `+x` |
| `category` | text | default `''` | Tạm (R3): tên danh mục chữ cho dòng mẫu; khi module Danh mục đến → thay bằng `category_id` FK |
| `note` | text | default `''` | Ghi chú người dùng (tùy chọn, FR-007); transfer ghi ở cả hai vế |
| `transaction_date` | dateTime | NOT NULL | Ngày giờ người dùng chọn (mặc định hiện tại); dùng để sắp "gần đây" |
| `transfer_group_id` | int | nullable | Liên kết 2 vế của 1 lần Transfer; null với thu/chi. Nhóm = id vế ghi trước (R7) |

**Quan hệ:** `transactions.wallet_id` → `wallets.id` (nhiều-nhất: một ví nhiều giao dịch). Không khai FK cứng trong drift (bám mẫu bảng `wallets` hiện tại).

**Luật hợp lệ & bất biến (chỉ chuyển khoản trong PBI 8):**
- Một khoản chuyển sinh **đúng 2 dòng** `type=transfer`: vế nguồn `wallet_id = from`, `amount = −x`; vế đích `wallet_id = to`, `amount = +x`; cùng `transaction_date`, cùng `note`, cùng `transfer_group_id`.
- Hai vế **đi cùng nhau** khi ghi — một `db.transaction()` duy nhất (4 ghi: 2 dòng + trừ `balance` nguồn + cộng `balance` đích). Không bao giờ tồn tại trạng thái chỉ một vế (FR-012/015).
- Transfer **không** có danh mục (`category=''`), không vào tổng thu/chi/báo cáo/ngân sách (FR-013) — phân biệt bằng `type=transfer`.
- `amount ≠ 0` cho dòng chuyển (screen chặn `≤ 0`).
- `transaction_date` không null trước khi xác nhận.
- Domain `Transaction` hiện có (signed `amount`, `walletId`, `type`, `category`, `note`, `date`) map 1-1 từ dòng; không đổi model.

### 3. Khoản chuyển (Transfer) — khái niệm, không phải bảng riêng

| Thuộc tính | Kiểu | Ghi chú |
|---|---|---|
| `from_wallet_id` / `to_wallet_id` | int | Hai ví tham gia |
| `amount` | int | > 0; không phí (đợt này không có phí) |
| `date` | dateTime | Mặc định hiện tại, đổi được |
| `note` | String | Tùy chọn |

Không phải thu/chi: không gắn danh mục, không vào báo cáo. Được **vật chất hóa thành 2 dòng `transactions`** như trên. Không có bảng `transfers`.

## Trạng thái chuyển đổi

Không phải máy trạng thái. Luồng UI: soạn → xác nhận (ghi atomic) → xong; hủy/quay lại = không ghi gì. Sửa/xóa/hủy khoản chuyển đã tạo nằm ngoài phạm vi (module Giao dịch), cấu trúc `transfer_group_id` sẵn sàng cho việc đó.

## Migration

- `schemaVersion`: 1 → 2.
- `onCreate` (DB mới): tạo `wallets` + `transactions`, seed 5 ví mẫu + 11 giao dịch mẫu.
- `onUpgrade(v1→v2)`: tạo bảng `transactions` + seed 11 dòng mẫu (tham chiếu `wallet_id` 1..5 đã có sẵn từ seed PBI 7 — chưa có luồng xóa ví nên luôn tồn tại).
- Seed dùng chính `TransactionSource.all()` (bộ 11 dòng PBI 6), bỏ qua `id` domain (DB tự sinh).
- Không cột mới trên `wallets` → test DAO migration PBI 7 giữ nguyên, thêm kiểm tra v2.
