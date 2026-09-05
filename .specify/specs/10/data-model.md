# Mô hình dữ liệu — PBI 10: Màn hình chi tiết giao dịch

Ngày: 2026-09-05

## Phạm vi thay đổi

**Bump schema drift 2 → 3**: bảng `transactions` thêm **3 cột text tùy chọn** `tags`, `receipt_image`, `location` (default `''`) — đúng cột đã định ở `docs/wallet/nghiep-vu-vi-tai-khoan.md` §7 (research R3). Bảng `wallets` giữ nguyên. Chưa tạo bảng `categories`; cột `category` vẫn là chữ tạm.

Domain `Transaction` thêm 3 field `String` mặc định `''` (additive — không phá constructor/sort/helper hiện có).

## Thay đổi trên drift (`app_database.dart`)

| Cột thêm | Kiểu | Yêu cầu | Ghi chú |
|---|---|---|---|
| `tags` | text | default `''` | Nhiều tag phân tách dấu phẩy, không `#` (research R4) |
| `receipt_image` | text | default `''` | Đường dẫn ảnh hóa đơn (tạm trống mọi dòng seed — R3) |
| `location` | text | default `''` | Text địa chỉ rút gọn (tùy chọn) |

- `schemaVersion`: `2` → `3`.
- `onCreate` (DB mới): `createAll()` (drift tự tạo cột mới).
- `onUpgrade(from<3)`: `m.addColumn(transactions.tags)`, `m.addColumn(transactions.receiptImage)`, `m.addColumn(transactions.location)` — drift thêm cột có default → an toàn với dữ liệu cũ.
- Chạy `flutter pub run build_runner build --delete-conflicting-outputs` để tái sinh `app_database.g.dart`.

## Thay đổi trên domain (`core/transaction/transaction.dart`)

`Transaction` thêm (constructor mặc định `''`):

| Thuộc tính | Kiểu | Ghi chú |
|---|---|---|
| `tags` | String | Chuỗi raw; phân tích thành list qua `parseTags` (xem view hiển thị) |
| `receiptImage` | String | Rỗng = không có ảnh → ẩn hàng |
| `location` | String | Rỗng = không có vị trí → ẩn hàng |

Map 1-1 từ `TransactionsRow` (`_toTransaction` trong `wallet_repository_drift.dart`). `performTransfer` giữ mặc định `''` (chuyển khoản không gắn tag/ảnh/vị trí ở luồng PBI 8).

## Seed (`core/transaction/transaction_source.dart` + seed drift)

- Bộ 11 dòng giữ nguyên số lượng & giá trị (không thêm/bớt dòng, không đổi `category`/`note`) — tránh hồi quy test PBI 6/8/9.
- Làm giàu **row 1** (chi `85.000` Tiền mặt, note 'Ăn trưa văn phòng') để QA đối chiếu mockup 04:
  - `tags: 'côngty'` → chip `#côngty`.
  - `location: '123 Láng Hạ, Đống Đa, Hà Nội'`.
  - `receiptImage: ''` (giữ trống — R3).
- Domain/fake/seed-drift cùng dùng `TransactionSource.all()` → thêm field cho row 1 ở đó, seed drift ghi kèm (giữ parity giữa fake & DB).

## Thực thể & nguồn hiển thị

### Giao dịch (transaction) — đọc theo ref khi mở chi tiết (FR-010)

| Thuộc tính domain | Nguồn drift | Vai trò trên màn chi tiết |
|---|---|---|
| `id` / `transferGroupId` | `transactions.id` / `transfer_group_id` | Xác định đối tượng mở: mở theo `id` (thu/chi/adjustment/vế lẻ) hoặc theo `transfer_group_id` (transfer đã gộp — lấy đủ 2 vế) |
| `type` | `transactions.type` | Màu/dấu/khối tóm tắt: thu teal `+`, chi coral `−`, transfer/adjustment trung tính không dấu (FR-002/004) |
| `amount` | `transactions.amount` (signed) | Số tiền lớn ở tóm tắt; transfer/adjustment hiển thị `abs` |
| `category` | `transactions.category` (chữ) | Nhãn tóm tắt (đường dẫn cha·con khi dữ liệu mang chuỗi có ` · `); rỗng → `typeLabel` |
| `note` | `transactions.note` | Hàng Ghi chú (khi rỗng → ẩn) |
| `tags` (mới) | `transactions.tags` | Hàng Tag — dãy chip (khi rỗng → ẩn) |
| `receiptImage` (mới) | `transactions.receipt_image` | Hàng Ảnh hóa đơn — thumbnail (khi rỗng → ẩn) |
| `location` (mới) | `transactions.location` | Hàng Vị trí (khi rỗng → ẩn) |
| `date` | `transactions.transaction_date` | Hàng Ngày giờ `'dd/MM/yyyy · HH:mm'` |

### Ví (wallet) — đọc qua `loadAll()`
Cung cấp `name`: hàng "Ví" (thu/chi/adjustment) hoặc 2 hàng "Ví nguồn"/"Ví đích" (transfer — lấy theo `wallet_id` 2 vế). Gồm cả ví ẩn (giữ lịch sử — FR-011 edge).

## Bất biến hiển thị (đối chiếu mockup 04)

1. Transfer → **1 màn chi tiết duy nhất**, vùng chi tiết tách rõ "Ví nguồn"/"Ví đích" (FR-006, SC-005); tóm tắt trung tính không dấu (FR-004).
2. Điều chỉnh số dư → trung tính như transfer: không danh mục thu/chi, không màu teal/coral; giá trị theo dữ liệu điều chỉnh.
3. Hàng không có dữ liệu (ghi chú/tag/ảnh/vị trí) → **ẩn hẳn**, không dòng trống/thừa phân cách (FR-007, edge).
4. Ghi chú dài → gói dòng, không cắt; nhiều tag → đủ chip, không cắt.
5. Số tiền lớn → phân tách nghìn chuẩn, không tràn (summary dùng scale-down nếu cần — FR-009).
6. Ngày tương lai (đặt lịch) → hiển thị bình thường.
7. Danh mục/ví đã ẩn → tên/màu trên giao dịch cũ vẫn hiển thị (lịch sử giữ nguyên — FR-011).
8. Màn chỉ mở sau màn khóa (PBI 3) — không lộ số tiền qua màn hình khóa (FR-015).

## View hiển thị (derived, tính trong bộ nhớ — KHÔNG lưu DB)

`transaction_detail.dart` (thuần):

- **`TransactionDetailView`** (bất biến): `type`, `summaryTitle` (nhãn), `summaryGlyph`, `amount` (signed/abs theo type), `singleWalletName?`, `sourceWalletName?/destWalletName?`, `date`, `note`, `tags (List<String>)`, `receiptImage`, `location`.
- **`buildTransactionDetail({all, walletName, ref})`**: chọn bút toán theo `ref`:
  - `ref.transactionId` → tìm `Transaction` theo `id`; dựng view đơn.
  - `ref.transferGroupId` → lọc các dòng `transfer` chung nhóm; vế `amount<0` = nguồn, vế `amount>0` = đích; `amount` hiển thị = `abs(vế nguồn)`; nhóm thiếu vế → fallback view đơn không crash.
  - Không tìm thấy → null (màn báo trạng thái không có dữ liệu / lỗi — tình huống bất thường khi ref lỗi thời).
- **`parseTags(String) → List<String>`**: split `,`, trim, lọc rỗng (R4).
- `formatDateTimeDetailLabel` đặt ở `core/date_label.dart` (R8).

## Trạng thái chuyển đổi
Không phải máy trạng thái dữ liệu. UI: `đang nạp (spinner)` → `view | không có dữ liệu/lỗi đọc (thông báo + Thử lại)`.

## Migration
- `schemaVersion` 2 → 3; thêm 3 cột có default (an toàn, không mất dữ liệu cũ).
- Không đổi `wallets`, không chạm `transfer_group_id`/`amount` hiện có.
- Test DAO (drift `NativeDatabase.memory()`, skip-guard nếu host thiếu sqlite): map 3 cột mới từ row lên domain; seed row 1 mang tags/location; không phá case PBI 8 (`performTransfer` / migration v1→v2).
