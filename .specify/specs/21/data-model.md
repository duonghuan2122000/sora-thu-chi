# Mô hình dữ liệu: PBI 21 — Chi tiết Ngân sách

**Mã PBI**: 21 · **Ngày**: 2026-09-12 · **Liên kết spec**: [spec.md](./spec.md) · **Nghiên cứu**: [research.md](./research.md)

Đợt này **không thêm bảng**: chỉ thêm **1 cột** vào bảng `budgets` (schema v6 → v7). Mọi số liệu trên màn Chi tiết là **đại lượng tính toán** (kế thừa R3 của PBI 20) — không bảng snapshot, không bản ghi kỳ.

## Bảng drift (schema v7)

### `budgets` — sửa (thêm 1 cột)

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | int, autoIncrement | như PBI 20 |
| `category_id` | int | danh mục Chi (cha hoặc con) |
| `amount` | int | giới hạn chi tiêu (VND, dương) |
| `period` | textEnum `BudgetPeriod` | `weekly` / `monthly` / `yearly` |
| `is_recurring` | bool, default `true` | lặp lại tự động mỗi kỳ |
| `start_date` | datetime | ngày bắt đầu áp dụng |
| **`is_archived`** | bool, **default `false`** | **MỚI (PBI 21)** — ngừng theo dõi, giữ nguyên dữ liệu giao dịch (FR-016/FR-017) |

- Migration `v6 → v7`: `addColumn(budgets, budgets.isArchived)` — cột có default nên mọi dòng cũ nhận `false` (bám nhánh v4 của `transactions`). **Không seed.**
- Sinh lại `app_database.g.dart` bằng `build_runner` (bắt buộc — Rủi ro 6).
- `budgets()` **giữ nguyên hợp đồng**: trả **cả** ngân sách đã lưu trữ (repository không lọc). Việc lọc thuộc tầng view (`buildBudgetOverview` bỏ qua dòng `isArchived`).
- Lưu trữ **không** thêm method repository: dùng `updateBudget(budget.copyWith(isArchived: true))` đã có.

## Thực thể logic (tầng `core/budget`, hàm thuần)

### 1. Ngân sách (`Budget`) — sửa

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `id`, `categoryId`, `amount`, `period`, `isRecurring`, `startDate` | như PBI 20 | |
| **`isArchived`** | bool, default `false` | Tham số có giá trị mặc định ⇒ mọi chỗ khởi tạo cũ **không đổi**. |

Bổ sung `Budget copyWith({int? amount, bool? isArchived, …})` — dùng cho thao tác **Lưu trữ** và cho test.

### 2. Kỳ tổng hợp (`BudgetPeriodSummary`) — mới

Một kỳ của ngân sách, tính lại từ dữ liệu giao dịch:

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `range` | `DateRange` | nửa mở `[start, end)` — dùng lại `DateRange` của PBI 20 |
| `spent` | int | tổng Chi trong kỳ thuộc phạm vi danh mục |
| `limit` | int | = `budget.amount` **hiện tại** (giả định spec: chưa lưu giới hạn theo thời điểm) |
| `percent` | double | `spent / limit × 100` |
| `level` | `ProgressLevel` | 3 dải của PBI 20 (màu cột "Thực tế") |
| `ended` | bool | `range.end <= now` |

### 3. Chi tiết ngân sách (`BudgetDetail`) — mới

Kết quả dựng toàn màn `03` cho **một kỳ đang xem**:

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `budget` | `Budget` | bản mới nhất đọc từ repository |
| `category` | `Category?` | `null` ⇒ **không hợp lệ** (FR-019) |
| `range` | `DateRange` | kỳ đang xem |
| `spent` | int | "Đã dùng" (FR-003) |
| `percent` | double | % đã dùng → huy hiệu + màu (FR-004/FR-005) |
| `level` | `ProgressLevel` | 3 dải màu |
| `overAmount` / `remainingAmount` | int | chỉ một trong hai khác 0: `>100%` → vượt, `<100%` → còn lại (FR-006) |
| `ended` | bool | kỳ đã kết thúc |
| `daysLeft` | int | sàn 0; `= 0` + `ended` ⇒ hiển thị "Đã kết thúc" (FR-006) |
| `elapsedPercent` | double | % số ngày đã qua (gồm hôm nay — R6) |
| `showPaceWarning` | bool | `!ended && percent > elapsedPercent` (FR-007) |
| `comparison` | `List<BudgetPeriodSummary>` | tối đa **3** kỳ gần nhất tính đến kỳ đang xem, kỳ đang xem **cuối cùng** (FR-008/FR-010) |
| `transactions` | `List<Transaction>` | **toàn bộ** giao dịch Chi trong kỳ, mới nhất trước (FR-011/FR-012); màn hiển thị 5 dòng đầu + "Xem tất cả" |
| `periodOptions` | `List<DateRange>` | kỳ chọn được ở bộ chọn kỳ (FR-023 — R5) |

## Luật hợp lệ & bất biến

1. **Phạm vi danh mục**: `budgetScopeCategoryIds(categoryId, categories)` = bản thân + **con trực tiếp** (đã có ở PBI 20, dùng lại nguyên).
2. **Khớp giao dịch**: `type == expense` ∧ `categoryId ∈ phạm vi` ∧ `date ∈ [start, end)`; "đã dùng" = `−Σ amount` (amount có dấu). Một phép lọc duy nhất dùng chung cho **số đã dùng** và **danh sách giao dịch** (R11) ⇒ không thể lệch số (SC-005).
3. **Thu và chuyển khoản nội bộ bị loại hoàn toàn** khỏi mọi số liệu và khỏi danh sách (FR-011).
4. **Kỳ đang xem mặc định**: kỳ chứa `now`; nếu `!isRecurring` → kỳ chứa `startDate` (FR-020/FR-023).
5. **Danh sách kỳ**: bước theo đúng chu kỳ, từ kỳ chứa `startDate` đến cận trên = kỳ hiện tại (lặp lại) hoặc kỳ chứa `startDate` (không lặp lại) — **không** có kỳ trước khi ngân sách bắt đầu (kịch bản 3).
6. **Chuỗi so sánh**: đi lùi từ kỳ đang xem theo bước chu kỳ, **dừng trước kỳ chứa `startDate`**; ngân sách mới có 1–2 kỳ ⇒ biểu đồ hiển thị đúng 1–2 cặp cột (FR-010, kịch bản 19).
7. **Cột "Dự kiến" = giới hạn hiện tại của ngân sách** cho **mọi** kỳ; số **thực tế** của kỳ trước không hồi tố khi sửa giới hạn (giả định spec).
8. **Phạm vi "Xem tất cả"** = `type = Chi` ∧ `categoryIds = phạm vi danh mục (gồm con)` ∧ `date ∈ kỳ đang xem` — khớp đúng tập của danh sách trong màn (FR-014, SC-005).
9. **Ngân sách đã lưu trữ**: không xuất hiện ở màn Tổng quan (bị loại ở `buildBudgetOverview`), **không** xóa/sửa giao dịch nào, số dư ví bất biến (FR-016/FR-017, SC-007).
10. **Danh mục bị xóa**: `category == null` ⇒ trạng thái **không hợp lệ**, ẩn thẻ tiến độ/biểu đồ/danh sách giao dịch, **không** tự xóa ngân sách; hai nút "Chỉnh sửa"/"Lưu trữ" vẫn hiện để gán lại danh mục (FR-019/FR-024).

## Chuyển trạng thái

| Từ | Sự kiện | Đến | Ghi chú |
|---|---|---|---|
| đang theo dõi (`isArchived = false`) | chạm "Lưu trữ ngân sách" + xác nhận | **đã lưu trữ** (`isArchived = true`) | Một chiều trong đợt này; chưa có phục hồi (ngoài phạm vi) |
| đã lưu trữ | — | — | Không có đường quay lại, không có nơi xem lại (quyết định đã chốt 2026-09-12) |

Không có chuyển trạng thái nào khác: `active / ended / invalid` của màn `01` và `ended` của màn `03` đều là **đại lượng suy ra** khi nạp màn, không lưu cột.

## Hợp đồng nội bộ (repository) — không đổi chữ ký

| Method | Thay đổi |
|---|---|
| `budgets()` | Không đổi — trả cả ngân sách đã lưu trữ |
| `insertBudget` / `updateBudget` | Không đổi chữ ký; map thêm trường `isArchived` ↔ cột `is_archived` (2 chiều) |

Không tạo `contracts/`: app thuần nội bộ, không API/CLI/endpoint lộ ra ngoài (đồng nhất PBI 19/20).
