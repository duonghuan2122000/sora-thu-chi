# Mô hình dữ liệu: PBI 20 — Tổng quan Ngân sách (ngân sách theo danh mục)

**Mã PBI**: 20 · **Ngày**: 2026-09-12 · **Liên kết spec**: [spec.md](./spec.md) · **Nghiên cứu**: [research.md](./research.md)

## Tóm tắt: schema **v5 → v6** (thêm 1 bảng, không sửa bảng cũ, không seed)

| Hạng mục | Thay đổi |
|---|---|
| Bảng mới | `budgets` (6 cột) — nghiệp vụ người dùng nhập |
| Bảng cũ | `wallets`, `categories`, `transactions`, `app_settings` **không đổi** |
| Migration | `onUpgrade`: `if (from < 6) await m.createTable(budgets);` — thuần tạo bảng, không `addColumn`, không seed |
| Seed | **Không** — spec đòi trạng thái rỗng ở lần mở đầu (khác ví/giao dịch có seed demo) |
| Sinh mã | chạy lại `build_runner` để cập nhật `app_database.g.dart` |

## Thực thể 1 — Ngân sách (bảng `budgets`, schema v6)

| Cột drift | Kiểu | Ghi chú |
|---|---|---|
| `id` | int autoIncrement | |
| `category_id` | int, **not null** | trỏ `categories.id`; danh mục **Chi** (cha hoặc con). Không FK drift (bám kiểu `transactions.category_id`) |
| `amount` | int (VND) | số tiền giới hạn, **luôn dương** (validate ở tầng luật) |
| `period` | text enum `BudgetPeriod` | `weekly` \| `monthly` \| `yearly` |
| `is_recurring` | bool, default `true` | bật = tự tiếp tục kỳ sau; tắt = chỉ kỳ chứa `start_date` rồi kết thúc |
| `start_date` | datetime | ngày bắt đầu áp dụng (tạo mới = hôm nay) |

**Không lưu** (chưa có hiệu lực đợt này / suy ra được — research R2): `scope`, `name`, `wallet_ids`, `currency`, `period_start_rule`, `end_date`, `alert_thresholds`, `rollover_unused`, `status`, `created_at/updated_at`.

**Thực thể domain** (`lib/core/budget/budget.dart`): `class Budget { int id; int categoryId; int amount; BudgetPeriod period; bool isRecurring; DateTime startDate; }` — bất biến, map 1-1 với dòng bảng.
`enum BudgetPeriod { weekly, monthly, yearly }` + extension `label` (`Tuần`/`Tháng`/`Năm`).

## Thực thể 2 — Kỳ ngân sách (đại lượng **tính toán**, không lưu)

`DateRange { DateTime start; DateTime end; }` — `end` **độc quyền** (`[start, end)`).

| Chu kỳ | Khoảng của kỳ chứa mốc `anchor` |
|---|---|
| `weekly` | Thứ Hai 00:00 của tuần chứa `anchor` → Thứ Hai kế tiếp |
| `monthly` | ngày 1 tháng của `anchor` → ngày 1 tháng kế tiếp |
| `yearly` | 01/01 năm của `anchor` → 01/01 năm kế tiếp |

Hàm thuần: `budgetPeriodRange(BudgetPeriod, DateTime anchor)`.

## Thực thể 3 — Dòng hiển thị màn Tổng quan (`BudgetRow`, tính toán)

| Trường | Nguồn |
|---|---|
| `budget` | dòng `budgets` |
| `category` | `categories.id == budget.categoryId` (tra trong **cả** danh mục ẩn); không thấy → `null` ⇒ **không hợp lệ** |
| `range` | bảng dưới |
| `spent` | tổng `-amount` của giao dịch `type == expense`, `categoryId ∈ {categoryId} ∪ con trực tiếp`, `transactionDate ∈ range` |
| `percent` | `spent / amount * 100` (double, giữ nguyên để sắp xếp; hiển thị làm tròn) |
| `status` | `active` \| `ended` \| `invalid` |
| `level` | `normal` (< 80%) \| `near` (80–99%) \| `over` (≥ 100%) — chỉ có nghĩa khi `status == active` |

### Kỳ hiển thị theo trạng thái

| Trạng thái | Điều kiện | `range` dùng để tính `spent` | Vào thẻ tổng? |
|---|---|---|---|
| `active` | lặp lại, hoặc không lặp lại mà `now` nằm trong kỳ chứa `startDate` | `monthly` → **tháng đang xem**; `weekly`/`yearly` → kỳ chứa `now` (không đổi theo bộ chọn tháng) | ✅ |
| `ended` | **không** lặp lại và `now` **ngoài** kỳ chứa `startDate` | kỳ chứa `startDate` (cố định) | ❌ (FR-020) |
| `invalid` | không tìm thấy danh mục trong bảng `categories` | kỳ theo luật trên (không có ý nghĩa) | ❌ (không tính được đã chi) |

### Thẻ tổng (tính toán)

`totalLimit` = Σ `amount` của các dòng `active`; `totalSpent` = Σ `spent` của các dòng `active`; `totalPercent = totalSpent / totalLimit`; `daysLeft` = `max(0, range.end - hôm nay)` theo ngày của **tháng đang xem** (FR-003).

### Thứ tự danh sách (FR-022)

1. Dòng `active` — giảm dần `percent` (bằng nhau → tăng dần theo tên danh mục, để ổn định).
2. Dòng `ended` — sau cùng; trong nhóm sắp theo tên.
3. Dòng `invalid` — cuối cùng; trong nhóm sắp theo tên.

## Luật hợp lệ (`lib/core/budget/budget_rules.dart`, hàm thuần)

| Luật | Điều kiện | Thông báo |
|---|---|---|
| Danh mục bắt buộc | `category == null` | "Vui lòng chọn danh mục." |
| Số tiền > 0 | `amount <= 0` | "Vui lòng nhập số tiền lớn hơn 0." |
| Không chồng lấn (FR-016) | `budgetOverlaps(candidate, existing)` với mọi ngân sách khác `id` | "Đã có ngân sách cho danh mục này trong kỳ. Hãy sửa ngân sách đang có." |

`budgetOverlaps(a, b)` = `a.categoryId == b.categoryId && a.period == b.period && khoảng hiệu lực giao nhau`, trong đó khoảng hiệu lực = `startDate → ∞` nếu `isRecurring`, ngược lại = kỳ chứa `startDate` (research R10).

## Chuyển trạng thái

Không có cột `status` — trạng thái **suy ra mỗi lần nạp màn**:

- `active → ended`: ngân sách không lặp lại, thời gian trôi qua khỏi kỳ chứa `startDate` (mở app ở kỳ sau — FR-020). Không sinh bản ghi kỳ mới, không sửa dòng.
- `active → invalid`: danh mục bị xoá/không còn trong bảng `categories` (FR-021). Ngân sách **không** bị xoá; người dùng chạm dòng để mở màn sửa và gán danh mục khác.
- Không có `ended/invalid → active` tự động ngoài việc người dùng sửa (`isRecurring` / `startDate` / `categoryId`).

## Seam dữ liệu

`WalletRepository` (mở rộng — research R11):

```dart
Future<List<Budget>> budgets();                     // toàn bộ, không lọc
Future<Budget> insertBudget(Budget budget);          // bỏ qua id, DB sinh
Future<Budget> updateBudget(Budget budget);          // ghi theo id
```

`DriftWalletRepository` map dòng `budgets` ↔ `Budget`; `FakeWalletRepository` (test) giữ map trong bộ nhớ + 3 method tương ứng. Repository **không** tự validate chồng lấn (thuộc `budget_rules` + UI, bám nếp `addTransaction`/`insertCategory`).

## Ngoài mô hình dữ liệu (đợt này không tạo)

- `budget_period_snapshots` — bỏ hẳn, tính lại khi nạp màn (research R3).
- Ngân sách tổng (`scope = total`), ngân sách theo ví (`wallet_ids`), cộng dồn (`rollover_unused`), ngưỡng cảnh báo động, lưu trữ/xoá (`status`), kỳ tài chính lệch ngày, đa tiền tệ — ngoài phạm vi PBI (2a).
- Không có thực thể "bản sao kỳ trước": liên kết "Sao chép tháng trước" hiển thị nhưng chưa hoạt động.
