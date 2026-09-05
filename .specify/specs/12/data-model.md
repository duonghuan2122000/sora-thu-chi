# Mô hình dữ liệu & domain — PBI 12: Tìm kiếm & lọc giao dịch

Ngày: 2026-09-05

## Không đổi schema drift

Tính năng **chỉ đọc**: `schemaVersion` giữ **4**; không tạo/đổi bảng, không cột mới, **không chạy `build_runner`**. Bảng đọc nguồn (đã có):

- `transactions` — đối tượng lọc (loại, amount signed, `transactionDate`, `wallet_id`, `category_id?`, `category` text snapshot, `note`, `tags`, `transfer_group_id`).
- `categories` — cây cha-con cho lọc danh mục (`parent_id`, `is_hidden`; `repo.categories(type)` đã lọc hoạt động).
- `wallets` — tên ví (subtitle) & danh sách chọn ví (`is_hidden` giữ trong danh sách để xem lịch sử).

## Domain mới (Dart thuần — `core/transaction/transaction_filter.dart`)

### `enum TxnTypeFilter { all, income, expense, transfer }`
Nhãn tiếng Việt: `Tất cả / Thu / Chi / Chuyển khoản`. Map sang `TxnType` khi khớp (không có `adjustment` trong chip — chỉ xuất hiện dưới `all`). Ảnh hưởng danh sách danh mục trong picker (R7).

### `enum SortOption { dateNewest, dateOldest, amountAsc, amountDesc }`
Nhãn: `Ngày mới nhất / Ngày cũ nhất / Số tiền tăng dần / Số tiền giảm dần`. Mặc định `dateNewest`.

### `enum DatePreset { today, thisWeek, thisMonth, all, custom }`
Nhãn preset: `Hôm nay / Tuần này / Tháng này / Toàn bộ` + `custom` = khoảng tùy chỉnh.

### `class TxnSearchFilter` (bất biến — bản nháp & bộ lọc áp dụng dùng chung)

| Trường | Kiểu | Mặc định (Đặt lại / chưa áp dụng lần nào) | Nghĩa |
|---|---|---|---|
| `keyword` | `String` | `''` | so khớp note/category/tags, bỏ dấu (FR-002) |
| `type` | `TxnTypeFilter` | `all` | chip loại (FR-004) |
| `datePreset` | `DatePreset` | `thisMonth` | preset đã chọn (mockup `05` = tháng hiện tại, FR-005) |
| `dateStart` / `dateEnd` | `DateTime?` | ngày đầu/cuối tháng hiện tại | khoảng theo ngày lịch, 00:00 đầu & hết ngày `dateEnd` |
| `categoryIds` | `Set<int>` | rỗng | id danh mục đã chọn (cha hoặc con) |
| `walletId` | `int?` | `null` (tất cả) | một ví cụ thể (FR-007) |
| `amountMin` / `amountMax` | `int?` | `null` | biên độ giá trị tuyệt đối, bao gồm biên (FR-008) |
| `sort` | `SortOption` | `dateNewest` | thứ tự tập kết quả (FR-009) |

- `bool get hasAnyCondition` — khác mặc định toàn phần (có gì đó đang lọc), dùng cho chip trạng thái (không bắt buộc hiển thị).
- `TxnSearchFilter reset()` — trả filter mặc định (FR-014). `DatePreset` giải ra cặp ngày dựa vào **`now` anchor** của controller/màn lọc (deterministic test): `today` = [hôm nay, hôm nay]; `thisWeek` = [thứ Hai tuần này, chủ nhật]; `thisMonth` = [01, cuối tháng]; `all`/`custom` theo giá trị lưu.
- Helper: `(DateTime) → ({start, end})` giải preset thành khoảng `[start 00:00, start-of-sau-dateEnd)`.

### `class FilteredTxSummary { int count; int signedTotal; }` (R3)
`count` = số **dòng hiển thị** sau gộp transfer; `signedTotal` = `Σ income.amount − Σ expense.abs` (transfer/adjustment có trong count, không vào total).

## Luật khớp (phép hội — AND, FR-010)

Mỗi giao dịch `Transaction t` khớp **toàn bộ** điều kiện đang đặt:

1. **Loại**: `type == all` → mọi loại (gồm adjustment); ngược lại khớp `t.type` ánh xạ.
2. **Ngày**: khớp nếu `t.date >= dateStart` và `t.date < endExclusive` (endExclusive = hôm sau `dateEnd`, 00:00); không đặt đầu nào → bỏ ràng buộc đó.
3. **Danh mục** (`categoryIds` rỗng → bỏ qua): tập hiệu lực `ids = chọn ∪ {con của cha được chọn}`. Khớp nếu `t.categoryId ∈ ids`, **hoặc** `t.categoryId == null && normalized(t.category) ∈ normalized(∅ tên danh mục trong ids)` (fallback tên — giữ lịch sử dòng chưa nối id, R7). Không áp dụng khi chip là `transfer` (transfer/adjustment không danh mục).
4. **Ví**: `walletId == null` → bỏ qua; ngược lại khớp `t.walletId == walletId`.
5. **Tiền**: `abs(t.amount) >= amountMin` (nếu đặt) và `<= amountMax` (nếu đặt). Giao dịch transfer amount hai vế ± cùng độ lớn → abs như nhau.
6. **Từ khóa**: chuỗi cần tìm = `note` + `category` + `tags` (dạng thô). Khớp nếu `normalizeSearch(từ khóa)` là substring của `normalizeSearch(chuỗi cần tìm)`.

**Bất biến group-keep (R2)**: giao dịch `transfer` có `transferGroupId` được giữ trong tập kết quả nếu **chính nó khớp hoặc một vế cùng nhóm khớp**; khi một vế khớp → giữ **cả 2 vế** của nhóm để `buildDisplayRows` gộp thành 1 dòng. (Chỉ các tiêu chí theo dòng — ví/tiền/từ khóa — có thể làm lệch hai vế; giữ nguyên nhóm bảo toàn "1 dòng/1 lần" — SC-010.)

## Sinh mô hình hiển thị (tái dùng `transaction_list.dart`)

Sau khi lọc raw list (kèm group-keep) + `buildDisplayRows(rows, walletNames)` → `List<TxnRow>`:

- **Sort theo ngày** (`dateNewest`/`dateOldest`): `groupDisplayRows` như PBI 9 — nhóm header `HÔM NAY/dd/MM/yyyy` (R4); đảo hướng nhóm & dòng cho `dateOldest`.
- **Sort theo tiền** (`amountAsc`/`amountDesc`): danh sách **phẳng** — sắp toàn bộ theo `row.amount.abs()` đúng hướng; trùng → ngày mới nhất trước, trùng tiếp → `sortId` tăng (ổn định). Không header ngày (R4).
- Dòng thu/chi giữ dấu/`formatSignedMoney` (màu teal/coral), transfer/adjustment dương/trung tính — **không đổi** cấu trúc `TxnRow`/màu (FR-012).

**Thống kê tháng** (`monthlyIncomeExpense`, card "Thu/Chi tháng này") chỉ dùng khi **không** có filter; đang lọc → card ẩn, thay bằng thanh chỉ báo `N kết quả · Tổng: X đ` + "Bỏ lọc" (R5, FR-013). `count`/`signedTotal` lấy từ `FilteredTxSummary` trên cùng tập `TxnRow` (R3).

## Bất biến & trạng thái

1. Chỉ đọc — không ghi DB, không đổi bất kỳ `Transaction` (SC-010).
2. Mọi tiêu chí kết hợp **AND** (FR-010); không có "hoặc" giữa các dòng lọc.
3. `count` = dòng hiển thị (transfer gộp = 1); `signedTotal` = thu − chi; transfer/adjustment không vào total (FR-011).
4. Giao dịch ví ẩn/danh mục ẩn vẫn nằm trong tập khi lọc "Tất cả"/không lọc theo chúng — giữ lịch sử (FR-007, giả định spec); chỉ không **chọn được** danh mục ẩn trong picker (`repo.categories` lọc hoạt động).
5. Trạng thái không-lọc: `activeFilter == null` → danh sách = toàn bộ (hành vi PBI 9). Mặc định khi **mở màn lọc** (chưa áp dụng) = filter "Tháng này" (FR-005) — khác với "không lọc" ở danh sách; Áp dụng mới khiến danh sách lọc.
6. `min > max` (tiền) hoặc custom ngày bắt đầu > kết thúc → UI chặn, không tạo filter sai (FR-008).
7. Filter sống trong `TransactionController` — hiệu lực qua ra/vào tab & mở lại màn lọc, không nhân đôi (SC-007); quay lại màn lọc không Áp dụng → giữ nguyên tập cũ (FR-015).
8. `now` anchor: bộ lọc nhạy thời gian (preset) tính theo `now` của lần nạp/khung nhìn; test inject để deterministic.
9. Sort ổn định (tie-break id) — không đổi thứ tự khi dữ liệu tĩnh (SC-010).
