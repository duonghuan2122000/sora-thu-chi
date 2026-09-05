# Nghiên cứu — PBI 11: Màn hình thêm giao dịch & chọn danh mục

Ngày: 2026-09-05

## Bối cảnh ràng buộc

- App offline (drift SQLite), không thêm dependency; state GetX ở màn chính, sub-form màn ví/transfer dùng `StatefulWidget` + repository.
- Hiện trạng: `add_transaction_screen.dart` là **stub rỗng** (SubPageScaffold chỉ tiêu đề), FAB "+" ở `app_shell.dart` push nó (no-op). Chưa có method ghi **1 giao dịch thu/chi** — chỉ có `performTransfer` (2 vế + bù balance 2 ví trong 1 `db.transaction()`). `transactions.category` là **chuỗi text** (schema v3), chưa có bảng `categories`.
- `balance` ví là **cột lưu** (`wallets.balance`), cập nhật giao dịch khi chuyển tiền (PBI 8) — ghi thu/chi mới phải bù balance cùng lúc insert.
- Seed ví/giao dịch chạy **trong drift** (`app_database.dart` `onCreate`/`onUpgrade`), 5 ví `WalletSource` + 11 dòng `TransactionSource`.
- Design system + mockup `docs/transaction/02-them-giao-dich.svg` + `03-chon-danh-muc.svg`; danh mục mặc định & mô hình bảng `categories` ở `docs/category/…md` §2–§3.
- **Quyết định người dùng (ask PBI 11)**: Tạo bảng `categories` + chuyển giao dịch sang `category_id` — **bump schema v3 → v4** trong đợt này (không chờ module Danh mục).

## R1 — Bảng `categories` + schema v4 (quyết định người dùng)

**Quyết định**: Thêm bảng drift `Categories` và bump `schemaVersion` 3 → **4**. Cột theo mô hình docs §2 phù hợp style repo (id int autoIncrement — repo dùng int, không UUID; bỏ timestamp không cần cho đợt này):
`id` int PK, `name` text, `type` `textEnum<CategoryType>()` (income|expense), `icon` text (khóa chuỗi → `IconData` qua map ở tầng UI), `color` int (ARGB, bắt buộc), `parent_id` int nullable (cha-con **2 cấp**), `sort_order` int default 0, `is_system` bool default false (seed mặc định true — không xóa được), `is_hidden` bool default false.

**Lý do**: User chốt dựng bảng ngay để giao dịch có tham chiếu danh mục đúng mô hình chuẩn docs; bảng `categories` là nguồn chân lý duy nhất cho picker. Vẫn **chưa** triển khai CRUD quản lý danh mục — thuộc module Danh mục (spec: tự tạo/quản lý "ngoài đợt này", ô "Thêm mới" no-op).

**Phương án khác**: (a) Giữ `category` text + catalog hằng trong code (không bảng) — được đề xuất nhưng user bác, chọn bảng. (c) Chờ module Danh mục tạo bảng — trái yêu cầu user.

## R2 — Giao dịch lưu danh mục: `category_id` + `category` (text snapshot)

**Quyết định**: Thêm cột nullable `transactions.category_id` (trỏ `categories.id`). **Giữ nguyên cột `category` text** và mọi giao dịch mới ghi **cả hai**: `category_id` = id danh mục đã chọn (cha đơn / con), `category` = **tên danh mục đã chọn** (con thì tên con, VD `'Ăn ngoài'` — khớp acceptance "trường Danh mục hiển thị 'Ăn ngoài'"). Giao dịch transfer ghi `category_id` null (không gắn danh mục).

**Lý do**: Mọi màn đọc hiện có (danh sách PBI 9, chi tiết PBI 10, nhóm ngày) đọc trực tiếp `category` text; chuyển toàn bộ sang join `category_id` = viết lại nhiều màn + test đã xanh ngoài phạm vi tính năng "thêm giao dịch" (FR-013 chỉ cần giao dịch mới xuất hiện đúng tên danh mục). Giữ text = **snapshot hiển thị** (additive, giống cách v3 thêm cột tùy chọn), `category_id` là tham chiếu cấu trúc — module Danh mục sau dùng để nhóm/đường dẫn cha·con mà không đụng màn cũ.

**Phương án khác**: Bỏ hẳn text, join toàn bộ → phình hồi quy (bác). Không thêm `category_id` → bảng tạo mà giao dịch không tham chiếu (vô nghĩa, bác).

## R3 — Hợp đồng repository mới (ghi thu/chi + đọc categories)

**Quyết định**: Thêm vào `WalletRepository` (interface + drift + fake):
- `Future<List<Category>> categories({required CategoryType type})` — trả danh mục **đang hoạt động** (`isHidden == false`) thuộc `type` (gồm cha & con; UI tự tách cha-con bằng `parentId`).
- `Future<void> addTransaction({required int walletId, required TxnType type, required int amount, required Category category, required DateTime date, String note = ''})` — chỉ nhận `type` = income/expense, `amount > 0`, `category.type` khớp `type`. Drift: trong 1 `db.transaction()` bù `wallets.balance` (`income` +, `expense` −) rồi insert 1 dòng `transactions` với `amount` **có dấu theo loại** (income `+x`, expense `−x` — khớp quy ước signed của seed/PBI 8), `category_id = category.id`, `category = category.name`, `note`, `transactionDate`; `transferGroupId/tags/receipt_image/location` mặc định rỗng/null.

**Lý do**: Bám `performTransfer` (ghi balance cùng insert trong `db.transaction()`, không lệch phía — FR-012/SC-003). Repository là seam duy nhất 3 impl đang giữ mọi ghi; không thêm layer.

**Phương án khác**: Method `insert` domain-agnostic bỏ validate type → cho phép ghi adjustment/transfer sai đường (bác). Cập nhật balance ở controller thay vì repo → rời 2 ghi, rủi ro nửa chừng (bác).

## R4 — Danh mục mặc định (seed) — nguồn chân lý cho picker

**Quyết định**: Seed bảng `categories` lúc tạo/upgrade DB với bộ mặc định của app (docs/category §3 + mockup 03 + acceptance PBI 11):

| Loại | Cha | Con |
|---|---|---|
| Chi | Ăn uống | Cà phê, Ăn ngoài, Đi chợ |
| Chi | Di chuyển, Nhà ở, Hóa đơn, Mua sắm, Giải trí, Sức khỏe, Giáo dục | — |
| Thu | Lương, Thưởng, Đầu tư, **Khác** | — |

Màu/icon: theo mockup `03` (cha) — mỗi danh mục một màu + khóa icon Material gần nghĩa; con thừa hưởng màu cha, icon riêng. Toàn bộ `is_system = true`, `is_hidden = false`. Nguồn seed: hằng `CategorySource` trong `core/category/` (pattern `WalletSource`); drift seed chèn cha trước → map `parent_id` theo tên cha → chèn con.

**Lý do**: Spec acceptance 3/4 liệt kê đúng bộ này (thu có "Khác" — docs seed §3 chỉ 3 nhưng mockup + acceptance có Khác, theo acceptance). Không màu/icon chuẩn trong docs ngoài mockup → bám mockup, dừng ở mức hợp lý (đã chốt không thêm icon-pack). Giao dịch seed 11 dòng cũ có tên không nằm bộ mặc định (`'Xăng xe'`, `'Thu nhập khác'`, `'Bán đồ cũ'`) → `category_id` null, text giữ nguyên — danh sách/chi tiết không đổi (R2).

**Phương án khác**: (a) Chỉ 8 chi + 3 thu theo docs — thiếu "Khác" acceptance 4 (bác). (b) Thêm danh mục ẩn cho tên lạ của seed → thêm dòng "chìm" không cần thiết (bác).

## R5 — Màn "Chọn danh mục": lưới cha + khoan xuống con ngay trong màn (không route con)

**Quyết định**: Một route `CategoryPickerScreen(type)` đọc `categories(type)` từ repo. Bố cục bám mockup `03`: app bar teal + back, tiêu đề "Chọn danh mục"; thân cuộn:
- Lưới **4 cột** danh mục **cha** của `type`: mỗi ô icon tròn nền `category.color` + glyph `categoryIcon(icon)` trắng + tên dưới.
- Chạm cha **có con** → **bật vùng "DANH MỤC CON: <TÊN CHA>"** (nhãn viết hoa xám + đường kẻ `#EFEFEF`, đúng mockup) hiện các con dạng cell chọn được ngay bên dưới lưới cha (cùng màn, cuộn được); chạm con → chọn.
- Chạm cha **không con** → chọn luôn.
- Ô cuối lưới **"Thêm mới"** (nét đứt, dấu +) → **no-op không lỗi/treo** (module Danh mục sau).
- Chọn → `Navigator.pop(context, Category)` (cha đơn hoặc con); màn thêm nhận Category, trường Danh mục hiển thị `category.name`.

**Lý do**: Mockup `03` minh họa vùng "DANH MỤC CON: ĂN UỐNG" nằm **cùng màn** dưới lưới; spec acceptance nói "chạm cha → hiện con, chạm con → chọn & quay về" — inline 1 màn khớp cả hai, ít điều hướng, đúng quy ước cha-con **2 cấp**. Trạng thái rỗng (không danh mục loại đang chọn): hiện thông báo ngắn + nút "Thử lại"/quay về, không lỗi (edge spec). `categoryGlyph` cũ (theo tên) giữ cho dòng lịch sử chưa có id.

**Phương án khác**: (a) Push route con cho mỗi cấp — thêm điều hướng, mockup không gợi ý (bác). (b) Drone theo nhãn cha·con hiển thị trên picker — acceptance yêu cầu field hiện tên con, không cần (bác).

## R6 — Nhập số tiền: numpad tùy chỉnh, VND số nguyên, phím `,` vô hiệu

**Quyết định**: Màn thêm dùng **numpad tùy chỉnh** (widget mới trong `core/widgets/`) bám mockup `02`: lưới 4×3 phím tròn viền `#E0E0E0`, hàng cuối trái phím **`,`** (màu nhạt **no-op** — VND số nguyên, phần thập phân là quyết định sau), giữa `0`, phải **backspace** (icon). Số tiền là **trạng thái `int _amount`** (không TextField), khởi đầu `0`, hiển thị `formatMoney` căn giữa + gạch chân mảnh **coral** khi Chi / **teal** khi Thu (accent theo loại — mockup Chi coral; Thu đối xứng teal). Hàm thuần để test: `int appendAmountDigit(int current, int digit, {int maxDigits = 12})` (bỏ số 0 đầu, giới hạn ≤ 12 chữ số — tránh tràn int, số VND thực tế), `int backspaceAmount(int current)` = `current ~/ 10`. Hiển thị số lớn co lại khi tràn (scale-down/FittedBox) không cắt số (edge spec).

**Lý do**: Mockup quy định numpad + số tiền không phải ô text; `parseAmount` hiện có phục vụ text field (transfer), không dùng cho luồng gõ phím. Không thêm thư viện keypad — widget 1 file.

**Phương án khác**: Dùng `TextFormField` + bàn phím hệ thống (như transfer) — lệch mockup (bác). Tái dùng thẳng `pin_keypad` — nằm `pin/`, style khác + hàng 4 lệch (bọc lại không đáng, R6).

## R7 — Bố cục & trạng thái màn "Thêm giao dịch"

**Quyết định**: `AddTransactionScreen` **Stateful**, khung riêng đúng mockup `02` (màn toàn màn hình, **không bottom nav**): AppBar teal — **leading X** (đóng, có xác nhận khi dirty), **actions check** (lưu), tiêu đề "Thêm giao dịch". Thân là `Column` cuộn linh hoạt (trên `SingleChildScrollView`/ListView theo chiều cao còn lại) gồm: segmented `Chi | Thu | Chuyển khoản` → vùng số tiền (lớn, accent màu theo loại — R6) → dòng trường bắt buộc **Danh mục / Ví / Ngày giờ** + **Ghi chú** (tùy chọn), mỗi dòng = icon tròn `tealLightBg` + nhãn phụ + value + chevron (mockup). Numpad cố định dưới (R6), nút chính **"Lưu giao dịch"** (bo 8, cao 44) cố định chân qua cơ chế tương tự `bottomNavigationBar` của `SubPageScaffold`. Segmented: **Material `SegmentedButton`** tùy chỉnh (chosen teal/chữ trắng, unchosen nền trắng viền `#E0E0E0` chữ `listLabel`) — track bo pill như mockup; **default "Chi"**.

Cờ trạng thái & chống lỗi: `_saving` chặn gọi lưu lần 2 (FR-012 edge "bấm 2 lần") — khi `_saving`, hai điểm lưu (check + nút) vô hiệu; lưu qua repository (R3) trong `try`; thành công → `Navigator.pop(true)`; lỗi repository → `SnackBar` (giữ dữ liệu, như transfer). Không tạo trùng/không nửa chừng vì repo ghi trong 1 `db.transaction()`.

**Lý do**: Đúng mockup (màn tác vụ đơn, không nav đáy — FR-001), layout linh hoạt cỡ chữ/safe-area (FR-015/SC-008: vùng trường cuộn được, nút không bị cắt). `SubPageScaffold` thiếu `leading` thay back → màn này dùng `Scaffold` riêng (AppBar teal + leading X) khỏi sửa khung dùng chung.

## R8 — Trường Ví: mặc định, chỉ ví hoạt động, biên

**Quyết định**: Khi mở màn, nạp `repository.loadAll()` → lọc **ví hoạt động** (`!isHidden`), **gồm thẻ tín dụng** (thu/chi bằng thẻ là giao dịch thường — spec, khác luồng transfer PBI 8). **Ví mặc định** (`isDefault`) được chọn sẵn (chỉ đúng 1 theo nghiệp vụ ví); nếu ví mặc định đang ẩn/không tồn tại → chọn ví hoạt động đầu tiên theo `sortOrder`. Chạm trường Ví → `showModalBottomSheet` danh sách ví hoạt động (pattern `_DestinationSheet` của PBI 8). Biên:
- **Không có ví hoạt động nào** → không thể lưu: hiện thông báo rõ "Chưa có ví hoạt động — hãy tạo ví trong Quản lý ví" (coral, đầu vùng trường), chặn Lưu, vẫn cho X/back (edge spec — không "kẹt").
- **Chỉ 1 ví hoạt động** → nạp sẵn, không cần mở danh sách.

**Lý do**: Bám luật ví docs §3/§6 (ẩn loại khỏi chọn, default pre-select, 1 default); spec biên yêu cầu rõ 2 trường hợp. Tái dùng bottom-sheet có sẵn.

## R9 — Xác nhận rời màn & báo lỗi trường

**Quyết định**:
- **Rời khi đang nhập dở** (FR-014): chạm X hoặc back → nếu **dirty** (số tiền > 0, hoặc đã chọn danh mục, hoặc note khác rỗng, hoặc ngày giờ đổi khỏi mặc định, hoặc đổi loại Chi/Thu) → `showDialog` xác nhận "Hủy giao dịch? / Hủy / Thoát" — Thoát → pop **không tạo giao dịch**; sạch → pop thẳng. Khi `_saving` → chặn rời (chờ lưu xong).
- **Báo lỗi tại đúng trường** (FR-011/SC-005): bấm Lưu/check với thiếu dữ liệu → highlight dòng + caption coral ngay dưới trường thiếu ("Chưa chọn danh mục", "Chưa chọn ví", "Chưa chọn ngày giờ") và dưới vùng số tiền ("Vui lòng nhập số tiền lớn hơn 0"). Danh mục/Ví/Ngày giờ yêu cầu rõ từng thiếu — không chặn mơ hồ.

**Lý do**: Mockup/docs chưa chuẩn dialog/xác nhận & lỗi (agent docs) → chốt theo pattern transfer: lỗi inline tại trường + snackbar cho lỗi hệ thống. Dialog ngắn phù hợp đặc tả FR-014 (chống mất dữ liệu vô thức).

## R10 — Tab "Chuyển khoản" & làm mới sau lưu

**Quyết định**:
- Chạm tab **"Chuyển khoản"** → chuyển sang luồng PBI 8: nếu form dirty → xác nhận bỏ (R9) rồi `Navigator.push(WalletTransferScreen(sourceWallet: ví đang chọn, controller: ensureWalletController()))`. Transfer là **luồng riêng** — không nhập chuyển khoản trên màn này (FR-003, spec). Khi transfer xong (`pop(true)`) → AddTransactionScreen tự `pop(true)` để shell làm mới (dưới đây); transfer hủy → quay lại màn thêm tiếp tục.
- **Làm mới FR-013/SC-006**: `AppShell._openAddTransaction` đổi thành `await push<bool>`; kết quả `true` (lưu thu/chi hoặc xong transfer) → gọi `ensureTransactionController().load()` — cập nhật danh sách + card "Thu/Chi tháng này" ngay không cần quay lại tab.

**Lý do**: Spec chốt tab chuyển khoản là **điểm vào mở luồng PBI 8** (không duplicate form). Refresh gom 1 chỗ (shell) — mọi đường lưu (thu/chi, transfer qua tab) đều pop `true` tới shell.

## R11 — Kiến trúc màn, seam & test (không phình GetX, không sqlite native)

**Quyết định**: `AddTransactionScreen`/`CategoryPickerScreen` là `StatefulWidget` **không controller GetX**: nhận `WalletRepository? repository` (constructor, default null → `ensureWalletRepository()` trong `initState`). Test bơm `AddTransactionScreen(repository: fake)` / picker `(repository: fake)` — không cần sqlite (pattern `WalletTransferScreen`). Numpad + bộ chọn = widget con. Màn chính test qua `FakeWalletRepository` mở rộng (`categories`, `addTransaction` — ghi vào list + bù balance như drift). Các hàm thuần (`appendAmountDigit`, `backspaceAmount`, build view cho màn thêm/chọn) nằm `core/transaction/` để unit test. DAO drift dùng `NativeDatabase.memory()` + skip-guard host thiếu sqlite.

**Lý do**: Màn thêm là màn tác vụ một-lần, không cần Rx theo sự kiện (giống transfer/detail). Giữ fake là nguồn test chính (PBI 7–10).

## R12 — Điểm mở liên quan (không chặn)

- Không làm: sửa/xóa/nhân bản giao dịch (PBI sau dùng lại màn — spec); quản lý danh mục CRUD + ô "Thêm mới"; Tag/Ảnh/Vị trí ở màn thêm; "Lưu & tiếp tục thêm"; số lẻ tiền; i18n multi-lang (GetX Translations đã sẵn sàng, UI màn mới dùng hằng tiếng Việt như toàn repo hiện tại — mọi màn khác cũng chưa i18n).
- Seed demo vẫn còn (quyết định mở #1); PBI 11 **thêm** seed `categories` (mặc định) nhưng không thêm giao dịch seed mới.

## Tổng kết

Mọi điểm nghiên cứu chốt xong, không còn `NEEDS CLARIFICATION`. Thay đổi schema v4 (bảng `categories` + `transactions.category_id`) do người dùng chốt (R1/R2).
