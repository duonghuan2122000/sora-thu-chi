# Mô hình dữ liệu — PBI 11: Màn hình thêm giao dịch & chọn danh mục

Ngày: 2026-09-05

## Phạm vi thay đổi

**Bump schema drift 3 → 4** (quyết định người dùng — research R1/R2):
1. **Tạo bảng `Categories`** — danh mục mặc định + cha-con 2 cấp (nguồn chân lý cho picker).
2. **Thêm cột `transactions.category_id`** (int nullable, trỏ `categories.id`).
3. Giữ nguyên cột `transactions.category` (text) = **snapshot tên hiển thị** — màn danh sách/chi tiết (PBI 9/10) không đổi, không hồi quy.

## Bảng drift mới: `Categories`

```dart
@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn   get id        => integer().autoIncrement()();
  TextColumn  get name      => text()();
  TextColumn  get type      => textEnum<CategoryType>()();   // income | expense
  TextColumn  get icon      => text()();                     // khóa → IconData (UI map)
  IntColumn   get color     => integer()();                  // ARGB, bắt buộc
  IntColumn   get parentId  => integer().nullable()();       // null = cha; con = id cha
  IntColumn   get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn  get isSystem  => boolean().withDefault(const Constant(false))();
  BoolColumn  get isHidden  => boolean().withDefault(const Constant(false))();
}
```

- Không tạo quan hệ FK drift (bám `transfer_group_id` — plain int), max 2 cấp do seed & UI đảm bảo.
- Không index unique cho đợt này (không có CRUD người dùng; module Danh mục sau quyết định).
- `schemaVersion`: `3` → `4`.

## Thay đổi drift: `Transactions` thêm `category_id`

| Cột thêm | Kiểu | Yêu cầu | Ghi chú |
|---|---|---|---|
| `category_id` | int | nullable | Tham chiếu `categories.id`; transfer/adjustment & dòng seed không khớp → null |

Các cột cũ (`wallet_id`, `type`, `amount`, `category` text, `note`, `transaction_date`, `transfer_group_id`, `tags/receipt_image/location`) giữ nguyên — không đổi hành vi PBI 8/9/10.

## Domain `Category` (file mới `core/category/category.dart`)

```dart
enum CategoryType { income, expense }   // + label tiếng Việt? chỉ dùng nội bộ (không hiển thị trực tiếp)

class Category {
  final int id;            // id thật (seed/DB) — CategorySource dùng id tạm 0
  final String name;
  final CategoryType type;
  final String icon;       // khóa chuỗi (VD 'restaurant')
  final int color;         // ARGB
  final int? parentId;     // null = cha
  final int sortOrder;
  final bool isHidden;
  final bool isSystem;
  bool get isParent => parentId == null;
}
```

Map từ `CategoryRow` ở drift (`_toCategory`); list dẹt từ `categories(type)`. UI tách cha (parentId null, sắp theo sortOrder) & nhóm con theo cha.

## Seed danh mục mặc định (`CategorySource`, `core/category/category_source.dart`)

Hằng (pattern `WalletSource`), `is_system = true`, `is_hidden = false`. Cha sắp `sortOrder` 0..n trong từng type; con `sortOrder` trong cha. Màu/icon bám mockup `03-chon-danh-muc.svg`:

| Type | Cha | sort | Màu (ARGB) | Icon key |
|---|---|---|---|---|
| chi | Ăn uống | 0 | `#3D8C77` | restaurant |
| chi | Di chuyển | 1 | `#0F6E56` | directions_car |
| chi | Nhà ở | 2 | `#5F5E5A` | home |
| chi | Hóa đơn | 3 | `#D85A30` | receipt |
| chi | Mua sắm | 4 | `#3D8C77` | shopping_bag |
| chi | Giải trí | 5 | `#0F6E56` | sports_esports |
| chi | Sức khỏe | 6 | `#5F5E5A` | medical_services |
| chi | Giáo dục | 7 | `#D85A30` | school |
| thu | Lương | 0 | `#0F6E56` | payments |
| thu | Thưởng | 1 | `#3D8C77` | redeem |
| thu | Đầu tư | 2 | `#5F5E5A` | show_chart |
| thu | Khác | 3 | `#9B9B9B` | category |

Con của **Ăn uống** (cha sort 0), thừa hưởng màu cha `#3D8C77`, icon riêng:

| Type | Con | parent | Màu | Icon key |
|---|---|---|---|---|
| chi | Cà phê | Ăn uống | `#3D8C77` | local_cafe |
| chi | Ăn ngoài | Ăn uống | `#3D8C77` | restaurant_menu |
| chi | Đi chợ | Ăn uống | `#3D8C77` | shopping_cart |

> Màu/icon không nằm docs ngoài mockup; bảng này là lựa chọn tối thiểu hợp mockup. Module Danh mục sau cho phép đổi/CRUD.

**Seed drift**: trong `AppDatabase` — chèn cha trước, lấy id theo tên, chèn con với `parent_id`. Chạy trước khi seed giao dịch (giao dịch cần `category_id`).

## Map icon: `categoryIcon(String key)` (tầng UI)

Map khóa → `IconData` Material (restaurant, directions_car, home, receipt, shopping_bag, sports_esports, medical_services, school, payments, redeem, show_chart, category, local_cafe, restaurant_menu, shopping_cart) + fallback `Icons.category`. Đặt gần `categoryGlyph` hiện có; `categoryGlyph(name)` (PBI 9, theo tên) giữ nguyên cho dòng lịch sử chưa có `category_id`.

## Seed giao dịch cũ (`TransactionSource`, 11 dòng)

- Giữ nguyên số lượng/giá trị/`category` text (không hồi quy PBI 6/8/9/10 test).
- Gán thêm `category_id` khi tên `category` trùng danh mục mặc định cùng type (VD `'Ăn uống'`, `'Mua sắm'`, `'Lương'`, `'Hóa đơn'`…); tên không có trong bộ mặc định (`'Xăng xe'`, `'Thu nhập khác'`, `'Bán đồ cũ'`) → `null`. Hiển thị không đổi (đọc text — R2).
- Transfer (2 vế) → `category_id` null.

## Repository (`WalletRepository`) — method mới

- `Future<List<Category>> categories({required CategoryType type})` — `is_hidden = false` & đúng type, sắp sortOrder. Drift: `select` filter `type` + `isHidden false`. Fake: trả từ seed.
- `Future<void> addTransaction({required int walletId, required TxnType type, required int amount, required Category category, required DateTime date, String note = ''})`:
  - Đầu vào hợp lệ: `type` ∈ income/expense, `amount > 0`, `category.type` khớp `type`, `category.id > 0`.
  - Drift: `db.transaction { ... }`: đọc ví `wallet_id` → update `wallets.balance` ± `amount` (`income` +, `expense` −) → insert `transactions` với `amount` = `+amount` (income) / `−amount` (expense), `category_id` = `category.id`, `category` = `category.name`, `note`, `transaction_date`; `transfer_group_id` null; `tags/receipt_image/location` mặc định `''`.
  - Fake: thêm dòng vào list đang giữ + bù balance ví fake (parity với drift).

## Migration (3 → 4) & seed trong `AppDatabase`

- `schemaVersion` → 4; chạy `build_runner` tái sinh `.g.dart`.
- `onCreate`: `createAll()` → `_seedCategories()` → `_seedSampleWallets()` → `_seedSampleTransactions()`.
- `onUpgrade(from, to)`:
  - `from < 2`: (giữ) `createTable(transactions)`.
  - `from < 3`: (giữ) `addColumn` tags/receipt_image/location.
  - `from < 4`: `createTable(categories)` (DB cũ <4 chưa có bảng) → `addColumn(transactions, transactions.categoryId)` → `_seedCategories()` (chỉ chèn nếu bảng rỗng, kiểm đếm) → nếu `from < 2` đã tạo `transactions` mới thì `_seedSampleTransactions()` gán luôn `category_id`.
  - Với DB `from ≥ 2` (đã có giao dịch): không chạy lại seed giao dịch — dòng cũ giữ `category_id` null (hoặc được backfill tay sau); hiển thị text không đổi.
- `_seedSampleTransactions` sửa để nhận map `tên → id` (category cùng type) và gán `category_id` khi khớp.

## View hiển thị màn thêm (derived — KHÔNG lưu DB)

### `AddTransactionScreen` (`screens/add_transaction_screen.dart`, Stateful, R7/R11)
Trạng thái form (in-memory):
- `TxnType _type` (income/expense), default **expense** (Chi).
- `int _amount` (≥ 0, ≤ 12 chữ số), `String _note`, `DateTime _date = DateTime.now()`.
- `Category? _category` (chọn xong), `Wallet? _wallet` (default ví hoạt động — R8).
- `bool _saving`, `Set<String> _missing` (trường thiếu sau lần bấm Lưu — R9).
- Các danh mục cho loại đang chọn nạp từ `repository.categories(type)` mỗi khi đổi Chi/Thu (hoặc nạp lần đầu).

Hàm thuần (unit test) trong `core/transaction/add_form.dart`:
- `int appendAmountDigit(int current, int digit, {int maxDigits = 12})` — bỏ số 0 đầu, chặn tràn.
- `int backspaceAmount(int current)`.
- `List<String> missingRequiredFields({required int amount, Category? category, Wallet? wallet, DateTime? date})` — trả tên trường thiếu (rỗng = hợp lệ).
- `bool isDirty(...)` — số tiền > 0 / có category / note khác rỗng / ngày ≠ hiện tại / type khác expense.

### `CategoryPickerScreen` (`screens/category_picker_screen.dart`, Stateful)
- Nhận `CategoryType type` + `WalletRepository? repository`.
- Danh sách cha của type (active); khi chọn cha có con → hiện vùng con; chọn → `pop(Category)`.

## Bất biến hiển thị & nghiệp vụ (đối chiếu mockup 02/03)

1. Giao dịch **thu** (+balance, số `+` teal), **chi** (−balance, số `−` coral) — theo `type`, đúng ngày giờ giao dịch (FR-012, SC-003); ghi trong 1 `db.transaction()` — không nửa chừng.
2. Danh mục phải thuộc **đúng loại** giao dịch đang ghi (Chi→danh mục chi, Thu→danh mục thu) — không chọn chéo (FR-006/SC-004).
3. Danh mục có con → phải chọn **con** mới lưu được (cha có con không phải lá); giao dịch mang `category_id` con + text tên con.
4. Ví chọn từ **ví đang hoạt động** (không ẩn), **gồm thẻ tín dụng**; đúng 1 ví mặc định pre-select.
5. Giao dịch **chuyển khoản** không gắn danh mục; tab "Chuyển khoản" mở luồng PBI 8 — màn này không có form chuyển.
6. Ghi chú & category là chuỗi; số tiền, loại, ngày giờ có cấu trúc.
7. Ngày giờ mặc định hiện tại, cho phép quá khứ/tương lai (lưu bình thường, số dư cập nhật ngay theo cơ chế eager balance hiện có — khớp `performTransfer`, đánh dấu `ponytail:` ceiling: số dư chuẩn "suy ra theo ngày" là việc module ví sau nếu cần).
8. Không tạo giao dịch trùng khi bấm Lưu 2 lần (cờ `_saving`); không lộ số tiền qua màn khóa (màn trong shell sau boot-gate PBI 3).

## Trạng thái chuyển đổi

Không phải máy trạng thái dữ liệu. UI màn thêm: nạp dữ liệu nền (wallets + categories) → form sẵn sàng | lỗi đọc → thông báo + Thử lại. Lưu: idle → `_saving` (nút vô hiệu) → thành công `pop(true)` | thất bại `SnackBar` giữ form. Rời khi dirty → dialog xác nhận.
