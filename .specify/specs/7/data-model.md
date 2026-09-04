# Mô hình dữ liệu: Thêm/sửa ví

**Mã PBI**: 7

Đợt này là PBI **đặt bảng `wallets` trong drift** (lần đầu wire drift — xem `research.md` Q1/Q3/Q12). Giao dịch vẫn là mock (PBI 6), chưa có bảng `transactions`. `Wallet` giữ model thuần Dart; `DriftWalletRepository` map dòng DB ↔ `Wallet`.

## Bảng drift `wallets` (schemaVersion 1)

| Cột | Kiểu drift | Ràng buộc | Map field `Wallet` |
|---|---|---|---|
| `id` | `integer` autoIncrement | PK | `id` |
| `name` | `text` | bắt buộc (validate form) | `name` |
| `wallet_type` | `textEnum<WalletType>` | — | `type` |
| `icon` | `text` | mặc định theo loại | `icon` |
| `color` | `int` nullable (ARGB) | preset (research Q9) | `color` |
| `initial_balance` | `int` | bắt buộc khi tạo | `initialBalance` |
| `balance` | `int` | **cache số dư hiện tại** (xem §Số dư) | `balance` |
| `currency` | `text` | mặc định `'VND'` (research Q4) | `currency` |
| `is_default` | `boolean` | đúng 1 ví active (Q6) | `isDefault` |
| `is_hidden` | `boolean` | tạo luôn `false` (FR-012) | `isHidden` |
| `sort_order` | `int` | thứ tự hiển thị | `sortOrder` |
| `credit_limit` | `int` nullable | thẻ tín dụng | `creditLimit` |
| `credit_used` | `int` nullable | cache "đã dùng" thẻ (PBI 5/6) | `creditUsed` |
| `statement_date` | `dateTime` nullable | thẻ tín dụng — ngày sao kê | `statementDate` |
| `due_date` | `dateTime` nullable | thẻ tín dụng — ngày đến hạn | `dueDate` |
| `term_months` | `int` nullable | sổ tiết kiệm — kỳ hạn (tháng) | `termMonths` |
| `maturity_date` | `dateTime` nullable | sổ tiết kiệm — ngày đáo hạn | `maturityDate` |
| `institution_name` | `text` nullable | ngân hàng / tổ chức (eWallet) | `institutionName` |
| `last_digits` | `text` nullable | số cuối tài khoản, chỉ hiển thị | `lastDigits` |

**Không thêm đợt này** (doc §7 liệt kê nhưng chưa có consumer — YAGNI, thêm khi cần): `created_at`, `updated_at`.

**Seed (onCreate)**: khi DB mới tạo, nạp 5 ví mẫu (giá trị bằng hằng `WalletSource.all()` hiện tại — PBI 5) để giữ liên tục demo; `WalletSource` giữ nguyên vai trò hằng seed. Gỡ khi PBI Giao dịch (research Q3, Quyết định mở #1).

## Thực thể `Wallet` — bổ sung trường đợt này

Các trường thêm đều **optional có default** để không phá constructor/hằng hiện có; kèm `copyWith` (Wallet bất biến):

`initialBalance` (int, mặc định theo `balance`), `currency` ('VND'), `color` (int? ARGB), `statementDate`/`dueDate`/`maturityDate` (DateTime?), `termMonths` (int?), `institutionName`/`lastDigits` (String?). Giữ nguyên: `id, name, type, icon, balance, isDefault, isHidden, sortOrder, creditLimit, creditUsed` + getter (`creditUsedPercent`, `creditUsageLabel`, `hiddenName`, `typeLabel`, `typeLabel`).

## Số dư ví — ngữ nghĩa trong giai đoạn chưa có DB giao dịch

- Số dư **suy ra** thật = `initial_balance + Σthu − Σchi ± Σtransfer` ([[Nguyên tắc nghiệp vụ]]). Vì `transactions` chưa vào DB, lưu `balance` là **cache** (đúng tinh thần "số liệu tính toán/cache" của [[Stack kỹ thuật]]).
- Khi **tạo** ví mới: `initial_balance = balance` = giá trị nhập (chưa có giao dịch nào → chúng bằng nhau).
- Khi **sửa ví chưa có giao dịch** (FR-011): cho đổi số dư ban đầu → ghi **cả** `initial_balance` và `balance` bằng giá trị mới (acceptance 7).
- Khi **sửa ví đã có giao dịch** (FR-010): khóa `initial_balance`/`balance` — không phải trường nhập trong form; chỉ đổi tên/icon/màu/trường riêng/cờ mặc định. Ví mẫu seed mang `balance` sẵn (VD Vietcombank 14.800.000, `initial_balance` 1.200.000 — khớp bộ giao dịch mock PBI 6).
- Thẻ tín dụng: `balance` cache giữ nguyên ý nghĩa PBI 5 (`0`), hiển thị dạng "Đã dùng/Hạn mức" qua `creditLimit`/`creditUsed`.

## Trạng thái & bất biến

- Trạng thái ví: **hoạt động** (mặc định khi tạo — FR-012) ↔ **ẩn** (`is_hidden`, giữ lịch sử — PBI sau quản lý). Sửa thông tin **giữ nguyên** trạng thái ẩn (FR-012).
- **Ví mặc định — bất biến toàn cục** (FR-007/008): tại một thời điểm, trong số ví **hoạt động**, có **đúng 1** ví mang `is_default`. Vì seed luôn có ví mặc định (Tiền mặt) nên ràng buộc này được duy trì liên tục từ khi có DB.
  - Tạo ví trong trạng thái không có ví hoạt động nào → ép ví mới là default (acceptance 3).
  - Bật cờ mặc định cho ví B → gỡ cờ ví A đang default.
  - Tắt cờ của ví default: còn ví active khác → hệ thống tự chọn ví thay thế (active đầu theo thứ tự hiển thị — research Q6); **chỉ còn mình nó active → chặn tắt** (giữ default).
  - Logic thuần tại `core/wallet/wallet_rules.dart` (hàm thao tác `List<Wallet>`), controller gọi + ghi DB.

## Ma trận khóa trường (chế độ sửa — FR-009/010/011)

| Trường | Thêm mới | Sửa, chưa có giao dịch | Sửa, đã có giao dịch |
|---|---|---|---|
| Tên ví | nhập | sửa | sửa |
| Loại ví | chọn | đổi được | **khóa** (ghi chú) |
| Số dư ban đầu | bắt buộc | đổi được | **khóa** (nhắc "Điều chỉnh số dư") |
| Tiền tệ | VND (đọc-only) | VND (đọc-only) | VND (đọc-only) |
| Icon & màu | chọn | sửa | sửa |
| Trường riêng theo loại | theo loại | theo loại | theo loại |
| Cờ ví mặc định | bật/tắt | bật/tắt | bật/tắt |

- Cờ mặc định **bật** khi: ví đầu tiên (ép), hoặc người dùng bật & còn default khác (dời cờ). Cờ **không tắt được** khi là default duy nhất còn active.
- Giao dịch "Điều chỉnh số dư" (cách chính để đổi số dư ví đã có giao dịch) **ngoài phạm vi** — form sửa chỉ hiển thị ghi chú hướng dẫn.

## Quan hệ

- `Wallet` 1—n `Transaction` (mock PBI 6, theo `walletId`): nguồn tính `hasTransactions` khi mở form sửa từ màn chi tiết (research Q5). Chưa có khóa ngoại trong DB đợt này.
- Màn hình chạm đợt này: danh sách ví (PBI 5) → "+ Thêm ví mới"; chi tiết ví (PBI 6) → hành động nhanh "Sửa ví". Hai hành động còn lại của chi tiết (Chuyển tiền, Ẩn ví) là điểm vào PBI sau.

Xem thêm: [[Ví & Tài khoản]], [[Nguyên tắc nghiệp vụ]], [[Stack kỹ thuật]].
