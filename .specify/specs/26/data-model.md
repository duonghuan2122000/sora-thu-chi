# Mô hình dữ liệu: So sánh kỳ (màn 03 Báo cáo)

**Mã PBI**: 26
**Liên kết spec**: [spec.md](./spec.md) · **Nghiên cứu**: [research.md](./research.md)
**Ngày tạo**: 2026-09-13

> **Không đổi schema drift** (giữ **v8**, PBI 24): không bảng mới, không cột mới,
> không migration, không chạy `build_runner`. Mọi thực thể dưới đây là **đại
> lượng tính toán** trong RAM, dựng lại mỗi lần mở màn (FR-019) — kế thừa PBI 22
> ("Không có bảng tổng hợp/cache số liệu").

---

## 1. Thực thể

### 1.1. `CompareMode` — chế độ chọn kỳ đối chiếu

| Giá trị | Nghĩa | Kỳ đối chiếu suy ra |
|---|---|---|
| `previous` | kỳ liền trước cùng loại kỳ (**mặc định**, FR-003) | `_previousStart(period, main.start)` → `reportPeriodRange(...)` |
| `lastYear` | cùng kỳ năm trước (FR-005) | dời `main.start` lùi 1 năm (kẹp 29/02 → 28/02) → `reportPeriodRange(...)` |

Là **state của màn** (R2), không phải dữ liệu lưu. Không xuất hiện trên giao diện
dưới dạng chữ — chỉ quyết định mốc kỳ đối chiếu. **Không** ảnh hưởng câu Nhận xét
(chữ `@ref` suy từ ngày — luật 20).

### 1.2. `CompareSide` — một vế của cặp so sánh

| Thuộc tính | Kiểu | Nguồn / ghi chú |
|---|---|---|
| `range` | `DateRange` | `reportPeriodRange(period, anchor)` — nửa mở `[start, end)` |
| `income` | `int` | `reportTotals(...).income` của kỳ (transfer/adjustment đã loại) |
| `expense` | `int` | `reportTotals(...).expense` của kỳ |
| `dailyExpense` | `List<int>` | `reportDailyExpense(...)` — độ dài = **số ngày** của kỳ |

Getter: `hasAnyTxn => income > 0 || expense > 0` (kỳ chỉ có transfer ⇒ `false`).

Không mang `label`: nhãn hiển thị dựng bằng `reportPeriodChipLabel(period, range)`
(**đã có** từ PBI 23) và `reportBarLabel(period, range.start)` (**đã có** từ
PBI 22) ⇒ hai màn Báo cáo không thể lệch chữ.

### 1.3. `CompareDelta` — chênh lệch một chỉ số

| Thuộc tính | Kiểu | Nghĩa |
|---|---|---|
| `percent` | `int?` | `((main − ref) / ref * 100).round()`; `null` ⇔ `ref == 0` (không chia 0) |
| `direction` | `int` | `1` tăng ▲ · `-1` giảm ▼ · `0` bằng (không mũi tên) |
| `isGood` | `bool?` | `true` tốt (màu thu) · `false` xấu (màu chi) · `null` **không tô màu** |

`isGood == null` ⇔ `percent == null` (kỳ đối chiếu không có dữ liệu) **hoặc**
`percent == 0` (chênh lệch bằng 0) — hai trường hợp này không được tô tốt/xấu.

### 1.4. `ReportComparison` — kết quả dựng toàn màn

| Thuộc tính | Kiểu | Nghĩa |
|---|---|---|
| `period` | `ReportPeriod` | loại kỳ — **hai vế luôn cùng loại** (FR-004) |
| `left` | `CompareSide` | **kỳ chính** — luôn ở **bên trái**, được tô đậm |
| `right` | `CompareSide` | **kỳ đối chiếu** — luôn ở **bên phải** |
| `incomeDelta` | `CompareDelta` | `higherIsGood = true` |
| `expenseDelta` | `CompareDelta` | `higherIsGood = false` |
| `insight` | `String` | câu Nhận xét **đã dịch**, dựng sẵn ở tầng thuần (R9) |

Getter:
- `isEmpty => !left.hasAnyTxn && !right.hasAnyTxn` → trạng thái rỗng toàn màn (FR-016).
- `hasExpense => left.expense > 0 || right.expense > 0` → thẻ xu hướng có vẽ được không.
- `dayCount => max(left.dailyExpense.length, right.dailyExpense.length)` → độ dài trục hoành.

### 1.5. `Delta.none` — không có `lastYear` rời rạc

Không có thực thể "kỳ chính/kỳ đối chiếu" **độc lập** với vị trí: **vai trò gắn
với vị trí** (spec "Thực thể chính"). Nút hoán đổi **đổi chỗ hai vế** (FR-006):
sau khi hoán đổi, vế đang ở bên trái **trở thành** kỳ chính (được tô đậm, cột mang
màu loại giao dịch, là `main` trong mọi công thức chênh lệch).

---

## 2. Hàm thuần (thêm vào `lib/core/report/report_view.dart`)

| Chữ ký | Vai trò |
|---|---|
| `DateRange reportRefRange(ReportPeriod period, DateRange main, CompareMode mode)` | Kỳ đối chiếu theo chế độ (luật 2–4) |
| `List<int> reportDailyExpense(List<Transaction> transactions, DateRange range)` | Tổng **chi** từng ngày của kỳ, không luỹ kế (luật 12–13) |
| `CompareDelta compareDelta({required int main, required int ref, required bool higherIsGood})` | % chênh lệch + chiều + tốt/xấu (luật 5–9) |
| `ReportComparison reportComparison({required List<Transaction> transactions, required List<Category> categories, required ReportPeriod period, required DateTime leftAnchor, required DateTime rightAnchor})` | Dựng toàn bộ số liệu màn 03 |

`reportComparison` tái dùng nguyên các hàm **đã có**: `reportPeriodRange`,
`reportTotals`, `_breakdown` (private, cho câu Nhận xét — R8),
`reportPeriodChipLabel`, `reportBarLabel`, `_previousStart`.

`CompareMode` khai báo trong `report_view.dart` cạnh `ReportPeriod` (module thuần
đã là nơi ở của enum kỳ).

---

## 3. Luật bất biến

| # | Luật | Nguồn |
|---|---|---|
| 1 | Hai vế **luôn cùng loại kỳ** `period`; không có đường nào tạo ra cặp khác loại | FR-004 |
| 2 | `previous`: kỳ đối chiếu là **kỳ liền trước** giải bằng **số học ngày** (`_previousStart` + `reportPeriodRange`) — Tuần lùi **7 ngày** và vẫn bắt **Thứ Hai**; Tháng lùi 1 tháng theo mùng 1; Năm lùi 1 năm | FR-003/FR-018 |
| 3 | `lastYear`: dời mốc lùi **đúng 1 năm** rồi giải kỳ; 29/02 không tồn tại ở năm đích ⇒ **kẹp về 28/02** | FR-005/SC-016 |
| 4 | Tháng 2 / năm nhuận: kỳ "tháng trước" và "năm trước" **không** dùng chu kỳ 30/365 ngày | biên spec |
| 5 | `percent = ((main − ref) / ref * 100).round()`; sai số chỉ do làm tròn ⇒ `≤ 1` điểm % | FR-009/SC-005 |
| 6 | `ref == 0` ⇒ `percent = null`, `isGood = null` — **không** chia 0, không `NaN`, không `∞` | FR-011/SC-006 |
| 7 | Màu badge theo **ý nghĩa**: Thu tăng / Chi giảm ⇒ tốt (`tealOnNeutral`); Thu giảm / Chi tăng ⇒ xấu (`coralOnNeutral`); **không** theo chiều tăng/giảm | FR-010/SC-005 |
| 8 | `percent == 0` ⇒ `direction = 0`, **không** mũi tên, **không** tô màu | biên spec |
| 9 | Badge đánh giá **theo từng chỉ số**: kỳ đối chiếu có Thu nhưng không có Chi ⇒ thẻ Thu có badge, thẻ Chi hiện ghi chú | FR-011 (R5) |
| 10 | Mọi con số **loại** `transfer` + `adjustment` — dùng lại đúng phép lọc `reportTotals`/`_breakdown` của màn 01 | FR-015/SC-004 |
| 11 | Kỳ chỉ có chuyển khoản ⇒ `hasAnyTxn == false` ⇒ coi là kỳ rỗng | FR-015 |
| 12 | `dailyExpense[i]` = **tổng chi của riêng ngày thứ `i`** của kỳ, **không** luỹ kế | FR-012 |
| 13 | Trục hoành `1 … dayCount`; đường của kỳ **ngắn hơn** chỉ có điểm tới ngày cuối kỳ đó — **không** nội suy, **không** kéo dài, **không** đệm 0 | FR-012/biên spec |
| 14 | Cột so sánh: `maxBarHeight = 64`; cột lớn hơn chiếm trọn; cột kia `64 * value / max`; cả hai `0` ⇒ không vẽ cột | FR-007/R13 |
| 15 | Danh mục tăng mạnh nhất: chênh lệch **tuyệt đối** `chi_trái − chi_phải` **gộp theo danh mục cha**, chọn **max dương**; không có ⇒ câu không nêu danh mục | FR-013/FR-014 |
| 16 | Tiền chi **không gắn danh mục** không ứng với danh mục nào ⇒ không thể là "danh mục tăng mạnh nhất" | biên spec |
| 17 | Danh mục **đã ẩn** vẫn được tính và **được nêu tên** (nguồn `categoriesIncludingHidden`) | FR-014 |
| 18 | Đồng hạng chênh lệch ⇒ xếp theo **tên tăng dần** (chuẩn hoá bỏ dấu — nếp `_breakdown`) ⇒ kết quả tất định | R8 |
| 19 | Câu Nhận xét dựng ở **tầng thuần** (đã dịch) theo thứ tự ưu tiên: cả hai không có chi tiêu → kỳ phải không có chi tiêu → `0%` → tăng/giảm | R9 |
| 20 | Chữ `@ref` trong câu suy từ **so sánh ngày**: `right.start < left.start` ⇒ "kỳ trước", ngược lại ⇒ "kỳ sau"; **không** lấy từ `CompareMode` (sau hoán đổi chữ phải đổi theo) | R9 |
| 21 | `isEmpty` (cả hai vế rỗng) ⇒ màn hiện trạng thái rỗng, **không** vẽ 3 thẻ; **vẫn** hiện cặp chip + nút hoán đổi | FR-016/FR-017/R12 |
| 22 | Cả hai vế không có **chi tiêu** nhưng có Thu ⇒ thẻ xu hướng + câu Nhận xét có nhánh riêng, **không** vẽ hai đường phẳng 0 | R12 |
| 23 | Số liệu tính **một lần lúc mở màn** từ bản chụp RAM; không cập nhật đẩy khi dữ liệu đổi ở nơi khác | FR-019 |
| 24 | Hoán đổi **chỉ đổi chỗ** hai vế; hoán đổi lần hai trả về **đúng** trạng thái ban đầu (mọi số và màu badge trùng khớp) | FR-006/SC-007 |
| 25 | Đổi kỳ đối chiếu (chạm chip) **không** làm đổi kỳ chính và **không** đổi kỳ đang chọn của màn 01 | FR-005/FR-020 |
| 26 | Mốc "hôm nay" và kỳ chính lấy từ `ReportController.now` / `period` **lúc mở màn** ⇒ kế thừa nguyên quy ước PBI 22/23, không có múi giờ/định dạng riêng | FR-018 |
| 27 | Mọi màu đi qua token `SoraColors`/`AppColors`; **không** hex cứng trong widget ⇒ chế độ Tối đúng (FR-022) | SC-014 |
| 28 | Mọi nhãn **tĩnh** và câu Nhận xét có bản dịch EN; số tiền vẫn `formatMoney` (phân tách nghìn + `đ`) | FR-021/SC-013 |

---

## 4. Vòng đời — khi nào số liệu đổi

| Sự kiện | `period` | `left` | `right` | `mode` | Số liệu |
|---|---|---|---|---|---|
| Mở màn từ Tổng quan | kế thừa từ màn 01 | kỳ đang xem của màn 01 | kỳ liền trước | `previous` | tính lại lúc mở |
| Chạm **nút hoán đổi** | không đổi | ⇄ `right` cũ | ⇄ `left` cũ | **không đổi** (FR-006) | dựng lại từ 2 mốc mới |
| Chạm **chip kỳ đối chiếu** | không đổi | không đổi | tính lại theo `mode` mới | ⇄ đảo | dựng lại |
| Back về màn 01 | **không đổi** | — | — | mất (state cục bộ) | — |
| Mở lại màn 03 | kế thừa màn 01 | kỳ đang xem | kỳ liền trước | `previous` (**luôn** về mặc định) | tính lại từ dữ liệu hiện có (KB-15) |
| Thêm/sửa/xoá giao dịch khi màn 03 **đang mở** | — | — | — | — | **không** đổi (FR-019/KB-19 của PBI 22) |
| Đổi kỳ ở màn 01 rồi mở màn 03 | **kỳ mới** | kỳ mới | liền trước của kỳ mới | `previous` | tính lại (KB-16/KB-17) |

---

## 5. Không đổi so với trước PBI 26

- Bảng drift: `wallets`, `transactions`, `categories`, `budgets`, `app_settings`,
  `scan_sessions` — **giữ nguyên schema v8**.
- `WalletRepository`: **không** thêm/sửa method (màn 03 dùng bản chụp RAM).
- `ReportView`, `buildReportView`, `reportBreakdown`, `reportTopCategories`,
  `reportCategoryDetail`, `ReportCategoryRow`, `ReportCategoryDetail`: **không sửa
  chữ ký** ⇒ màn 01/02 và test PBI 22/23 không đổi.
- `SoraColors`: **không** thêm/bớt token (dùng đủ token đã có — R10).
