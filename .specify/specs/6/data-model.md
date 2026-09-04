# Mô hình dữ liệu: Màn hình chi tiết ví

**Mã PBI**: 6

Đợt này chỉ **đọc**. Màn chi tiết đọc 1 `Wallet` (đã có PBI 5) + các giao dịch thuộc ví đó. `Transaction` là thực thể mới được thêm ở đây (bộ mẫu trong bộ nhớ); chưa wire drift (xem `research.md` Q1/Q2).

## Lưu trữ — ĐỢT NÀY: bộ mẫu trong bộ nhớ

- `Wallet`: giữ nguyên `WalletSource.all()` của PBI 5 (không sửa ví mẫu — tránh vỡ test/tổng `19.450.000 đ`).
- `Transaction`: hằng `TransactionSource.all()` trả bộ giao dịch mẫu gắn `walletId` của các ví mẫu; `TransactionSource.forWallet(walletId)` lọc đúng ví + sắp mới nhất lên đầu. Khi PBI Giao dịch (drift) đến → thay nguồn bằng đọc bảng `transactions`, giữ interface trả `List<Transaction>`.

## Thực thể `Transaction` (subset cho màn hình này)

| Thuộc tính | Kiểu | Ghi chú |
|---|---|---|
| `id` | `int` | Định danh bộ mẫu |
| `walletId` | `int` | Ví chứa dòng này — FR-008: chỉ hiển thị dòng `walletId == ví đang xem` |
| `type` | `TxnType` | `income / expense / transfer / adjustment` (label: Thu / Chi / Chuyển khoản / Điều chỉnh số dư) |
| `category` | `String` | Tên danh mục (thu/chi). Transfer & điều chỉnh: **rỗng** — dòng phụ fallback về `type.label` |
| `note` | `String` | Ghi chú — làm **tiêu đề** dòng nếu có; không có → dùng `category` (→ `type.label`) |
| `amount` | `int` | **Signed** (VND): `+` cho tác động tăng số dư ví chứa dòng, `-` cho giảm. income ≥ 0; expense ≤ 0; transfer: dòng trên ví nguồn `< 0`, ví đích `> 0`; adjustment dấu tuỳ hướng. Không phải magnitude |
| `date` | `DateTime` | Ngày giờ giao dịch — sắp mới nhất lên đầu |

**Không đưa vào đợt này** (thuộc PBI Giao dịch khi có DB): `category_id` (chỉ lưu tên), `tags`, `receipt_image`, `location`, `transfer_group_id` (2 vế của 1 lần transfer chưa liên kết — mỗi vế là 1 `Transaction` độc lập, cùng giá trị `note`), `exchange_rate`.

## Giá trị suy dẫn (hàm thuần, không lưu)

- **Lọc đúng ví**: `transactionsForWallet(List<Transaction>, int walletId)` → các dòng `walletId ==` đang xem (FR-008).
- **Sắp xếp**: giao dịch sắp theo `date` **giảm dần** (mới nhất lên đầu); trùng ngày ổn định theo `id` (FR-008).
- **Dòng phụ ngày**: `relativeDayLabel(date, {now})` → `'Hôm nay'` / `'Hôm qua'` / `'dd/MM'` (`core/date_label.dart`).
- **Chuỗi tiền dòng giao dịch**: `formatSignedMoney(amount)` → `'+18.000.000 đ'` / `'-450.000 đ'` / `'0 đ'` (`core/money_format.dart`).
- **Màu & icon dòng theo type** (không theo dấu): thu → teal/↑ trên tròn `tealLightBg`; chi → coral/↓ trên tròn `coralLightBg`; transfer/adjust → trung tính `listLabel` trên tròn `softCardBg` (FR-010, bảng màu wiki Giao dịch).
- **Số dư hero**: đọc trực tiếp `wallet.balance` (đại lượng suy ra, nguồn cấp thẳng từ PBI 5 — xem `research.md` Q7 & "Quyết định mở #2"). Không tính lại từ giao dịch ở đợt này.

## Luật & ràng buộc (đợt này)

- **Chỉ đọc**: không thao tác nào trên màn làm đổi dữ liệu ví/giao dịch (SC-008). Màn đọc lại nguồn mỗi lần mở → phản ánh dữ liệu hiện tại (FR-013).
- **Transfer hiện trên cả hai ví**: 1 lần chuyển khoản = 2 dòng (nguồn `-X`, đích `+X`); màu trung tính cả hai phía, không nhầm thu/chi (FR-010).
- **`amount` signed tự nhất quán với balance**: bộ mẫu giao dịch của ví Vietcombank (id 2) được dàn sao cho `nền + Σ signed = balance` (`14.800.000 đ`) — "nền" là số dư giả định trước giao dịch đầu tiên, ghi trong `quickstart.md` để QA đối chiếu thủ công SC-003. Đây là thuộc tính của **bộ mẫu**, không phải logic app.
- **Tên dòng**: tiêu đề = `note` nếu khác rỗng, ngược lại `category`; dòng phụ = `category · <nhãn ngày>`, transfer/adjust không category → dùng `type.label · <nhãn ngày>`.

## Quan hệ

- Màn chi tiết là **trung tâm điều hướng** module Ví: 3 hành động nhanh + dòng giao dịch là điểm vào của PBI sau (chuyển tiền, thêm-sửa ví, chi tiết giao dịch) — đợt này treo, không mở (FR-007/011).
- `Wallet.transactions` (1–n): nguồn danh sách "GIAO DỊCH GẦN ĐÂY"; transfer liên hệ 2 ví qua cặp dòng (đợt này chưa có `transfer_group_id`). Số dư ví ở đời thật = `initial_balance + Σ amount signed` (PBI Giao dịch). Xem [[Ví & Tài khoản]] + [[Giao dịch]].
