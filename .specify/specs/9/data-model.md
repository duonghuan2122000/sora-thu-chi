# Mô hình dữ liệu — PBI 9: Màn hình danh sách giao dịch

Ngày: 2026-09-05

## Phạm vi thay đổi

**Không đổi schema drift** (giữ `schemaVersion 2`: bảng `wallets` 18 cột PBI 7 + `transactions` 8 cột PBI 8). PBI 9 chỉ **đọc & trình bày** dữ liệu giao dịch đã có trên toàn thiết bị.

Thay đổi tối thiểu trên **domain** để màn có thể dựng:
- `Transaction` thêm field **`transferGroupId` (int?, nullable)** — map từ cột `transfer_group_id` (bảng đã có), phục vụ ghép cặp 2 vế transfer thành 1 dòng (FR-007).

## Thực thể tham chiếu

### Giao dịch (transaction) — đọc, không ghi

| Thuộc tính domain | Nguồn drift | Vai trò trên màn danh sách |
|---|---|---|
| `id` | `transactions.id` | Thứ tự ổn định khi trùng ngày giờ |
| `walletId` | `transactions.wallet_id` | Tra tên ví ở dòng phụ; nguồn/đích khi gộp transfer |
| `type` | `transactions.type` (`income/expense/transfer/adjustment`) | Quyết định màu/dấu/nhóm: thu/chi vào card tháng; transfer/adjustment không vào card |
| `amount` | `transactions.amount` (signed) | Hiển thị: thu `+` teal, chi `−` coral, transfer không dấu trung tính, adjustment trung tính |
| `category` | `transactions.category` (chữ tạm) | Tên danh mục (tiêu đề dòng thu/chi); rỗng → fallback `typeLabel` |
| `note` | `transactions.note` | Ghi chú sau dấu phân cách ở dòng phụ (nếu có) |
| `date` | `transactions.transaction_date` | Sắp giảm dần + nhóm theo ngày; mốc card tháng |
| `transferGroupId` (mới) | `transactions.transfer_group_id` | Nối 2 vế transfer để hiển thị 1 dòng |

### Ví (wallet) — đọc qua `loadAll()`
Cung cấp `name` cho dòng phụ mọi giao dịch (kể cả ví ẩn — giữ lịch sử) và nhãn "ví nguồn → ví đích" khi gộp transfer. Không dùng `balance` trên màn này (số dư thuộc màn ví).

## Quan hệ & phạm vi đọc
- `transactions.wallet_id → wallets.id` (nhiều-nhất). Màn đọc **toàn bộ** bảng `transactions` (không lọc `wallet_id`, không lọc ví ẩn — FR-004) + toàn bộ `wallets` qua `loadAll()`.
- Không khai FK cứng (bám hiện trạng drift).

## View hiển thị (derived, tính trong bộ nhớ — KHÔNG lưu DB)

Đầu ra của controller sau khi gộp:
- **`MonthStat`**: `incomeTotal` (Σ `income.amount`) và `expenseTotal` (= −Σ `expense.amount`, dương) của dòng có `transaction_date ∈ [ngày 1 tháng dương lịch hiện tại, thời điểm xem]`. Loại trừ `transfer` + `adjustment` bằng `type` (FR-003/FR-008).
- **`List<DayGroup>`**: nhóm theo ngày lịch, mới nhất trên; mỗi nhóm: `day`, `header` (`HÔM NAY - dd/MM/yyyy`, `HÔM QUA - dd/MM/yyyy`, còn lại `dd/MM/yyyy`), `rows` xếp theo ngày giờ giảm dần, trùng ngày giờ theo `id` tăng (ổn định).

### Bất biến hiển thị
1. Một khoản **chuyển khoản = đúng 1 dòng**: 2 dòng `type=transfer` chung `transferGroupId` → 1 item: tiêu đề "Chuyển khoản", phụ đề "tên ví nguồn → tên ví đích" (nguồn = vế `amount<0`, đích = vế `amount>0`), số tiền `|amount|`, trung tính, không dấu. KHÔNG thành 2 dòng (FR-007).
2. **Điều chỉnh số dư**: dòng trung tính, không gắn danh mục thu/chi, không tính vào card tháng (FR-008).
3. Giao dịch **ngày tương lai** (đặt lịch): vẫn xuất hiện, nhóm nằm trên các nhóm quá khứ; KHÔNG tính vào card tháng (cận trên = thời điểm xem).
4. Giao dịch thuộc **ví ẩn / danh mục đã ẩn hoặc hết trong lựa chọn**: vẫn hiển thị đầy đủ tên (giữ lịch sử).
5. Giao dịch **không ghi chú**: dòng phụ chỉ hiển thị tên ví, không dấu phân cách thừa.
6. Mỗi giao dịch xuất hiện **đúng 1 lần**, đúng nhóm ngày, đúng thứ tự thời gian (SC-004).

## Trạng thái chuyển đổi
Không phải máy trạng thái dữ liệu. Máy trạng thái **UI**: `chưa nạp (spinner)` → `nội dung | rỗng (hướng dẫn ghi đầu tiên, card `0 đ`) | lỗi đọc (thông báo + thử lại)`.

## Migration
Không có. Không đụng `schemaVersion`/onCreate/onUpgrade.
