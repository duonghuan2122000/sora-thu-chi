# Nghiên cứu kỹ thuật — PBI 8: Chuyển tiền giữa các ví

Ngày: 2026-09-05

## Vấn đề

PBI 8 cần ghi nhận một lần chuyển tiền giữa hai ví: trừ số dư ví nguồn, cộng số dư ví đích, và tạo một bút toán chuyển **liên kết hai vế** xuất hiện trong "GIAO DỊCH GẦN ĐÂY" của cả hai ví (spec FR-012/014). Hiện codebase mới chỉ có bảng `wallets` trong drift (schemaVersion 1, PBI 7); mọi giao dịch hiển thị là bộ mẫu tĩnh `TransactionSource` (PBI 6) — chưa có nơi lưu bút toán thật. Quyết định lớn nhất: đưa giao dịch thật vào lưu trữ ở đợt nào và theo hình nào.

## Quyết định chính

### R1 — Giới thiệu bảng `transactions` (drift) ngay trong PBI 8; Transfer = 2 dòng liên kết bằng `transfer_group_id`

- **Quyết định**: Thêm bảng `transactions` (schemaVersion 1 → 2). Một lần chuyển tiền ghi **2 dòng**: vế nguồn `amount = −x`, vế đích `amount = +x`, cùng `transaction_date`, cùng `note`, liên kết bằng chung một `transfer_group_id`. Toàn bộ 4 thao tác ghi (2 dòng + trừ nguồn + cộng đích) chạy trong **một `db.transaction()`** — hoặc tất cả, hoặc không gì (FR-012/015, SC-006).
- **Lý do**: Đúng mô hình đã chốt trong docs — `docs/wallet` §4 "Sinh ra 2 bút toán liên kết (linked entries) trên 2 ví, xóa 1 bên phải xóa đồng thời bên còn lại", §7 mô hình drift có cột `transfer_group_id (nullable) -- liên kết 2 dòng của 1 lần Transfer`. Wiki [[Giao dịch]] tái xác nhận. Domain `Transaction` hiện có (vế-signed amount, mỗi dòng gắn một `walletId`) khớp chính xác kiểu lưu này — không cần đổi model hiển thị.
- **Phương án khác đã xem xét**: (a) bảng `transfers` riêng (`from_id/to_id/amount/date/note`) — **loại**: lệch schema đã chốt, khi PBI Giao dịch đến phải gộp về 2 dòng, làm lại; (b) chỉ đổi 2 cột `balance` không lưu bút toán — **loại**: vi phạm FR-012/014 (khoản chuyển phải còn thấy trong danh sách cả hai ví, có dấu vết để sửa/xóa đồng bộ sau).

### R2 — Seed bộ 11 giao dịch mẫu hiện tại vào DB khi tạo/migrate bảng `transactions`

- **Quyết định**: Khi migration lên schema 2 (và lần tạo DB mới), seed đúng 11 dòng giao dịch của `TransactionSource` vào bảng `transactions`, tham chiếu `wallet_id` 1..5 của bộ ví mẫu. `TransactionSource` giữ vai trò **hằng seed** (giống `WalletSource` ở PBI 7).
- **Lý do**: Màn chi tiết ví chuyển sang đọc danh sách giao dịch từ DB (R5). Không seed → nhóm "GIAO DỊCH GẦN ĐÂY" rỗng trong khi số dư ví (cột cache, khớp Σ mẫu) vẫn 14.800.000 đ — đứt liên tục demo PBI 5/6 và đối chiếu QA. Seed giữ màn hình không đổi về dữ liệu trước khi có khoản chuyển thật, và cho ta **một nguồn sự thật** (DB) thay vì gộp hai nguồn.
- **Phương án khác đã xem xét**: (a) giữ `TransactionSource` cho màn chi tiết và chỉ gộp thêm dòng transfer đọc từ DB — **loại**: hai nguồn rồi merge, dễ lệch thứ tự/trùng, xử lý sau phức tạp; (b) không seed, màn chi tiết chỉ hiện transfer thật — **loại**: mất bộ demo PBI 6, số dư lớn đứng sau danh sách trống, QA PBI 6/8 SC đứt.
- **Ghi chú nợ**: 11 dòng seed (kèm `category` chữ) là dữ liệu minh họa — gỡ cùng Quyết định mở #1 khi PBI Giao dịch có luồng xóa + dữ liệu thật (xem Rủi ro plan). Chạy một lần ở migration/onCreate; không chạy lại mỗi lần khởi động.

### R3 — Bảng `transactions`: tạo subset cột đủ cho PBI 8 + đợt Giao dịch kế tiếp; dùng cột `category` chữ tạm (chưa có bảng `categories`)

- **Quyết định**: Cột drift: `id`, `wallet_id`, `type (textEnum<TxnType>)`, `amount (int, signed)`, `category (text, default '')`, `note (text, default '')`, `transaction_date (dateTime)`, `transfer_group_id (int, nullable)`. Index đơn `wallet_id`.
- **Lý do**: Schema đầy đủ trong docs (`category_id`, `tags`, `receipt_image`, `location`, `exchange_rate`) giả định bảng `categories` và các tính năng (danh mục, tag, ảnh, định vị, đa tiền tệ) chưa tồn tại — đợt này đưa vào là mã chết. `category` dạng chữ giữ nguyên dữ liệu hiển thị của 11 dòng mẫu (subtitle "Lương", "Ăn uống"… đúng như PBI 6) mà không cần bảng danh mục.
- **Phương án khác đã xem xét**: (a) full 10 cột docs — **loại**: `category_id` cần FK bảng chưa có, tag/ảnh/location/exchange_rate là YAGNI; (b) bỏ hẳn cột `category` (chỉ note) — **loại**: làm mất subtitle danh mục của dòng mẫu, và khi Giao dịch thật tới vẫn phải thêm cột + backfill.
- **Ghi chú nợ**: khi PBI module Giao dịch đến → migration `category:text` → `category_id:FK categories`, bỏ tag/ảnh/location/tỷ giá là tách bảng khác; lúc đó seed mẫu cũng được gỡ.

### R4 — Số dư ví giữ là cột cache (`balance`), Transfer đổi đúng hai cột trong transaction; chưa chuyển sang "balance suy ra từ bảng giao dịch"

- **Quyết định**: Giữ nguyên mô hình PBI 7 — `wallets.balance` + `initial_balance` là cache; lần transfer trừ `balance` ví nguồn và cộng `balance` ví đích, cùng lúc ghi 2 dòng (R1), trong một transaction. Không tính lại balance từ bảng `transactions`.
- **Lý do**: Bộ mẫu không nhất quán để suy ra — ví "Tiền mặt" seed `balance = 3.200.000` nhưng Σ giao dịch mẫu chỉ 2.995.000 (2 khoản chi mẫu không được cộng dồn vào lúc seed), "Sổ tiết kiệm" có giao dịch rỗng; suy ra sẽ làm lệch mọi con số QA PBI 5/6/8. Số dư suy ra thực sự phải đợi module Giao dịch ghi đủ mọi giao dịch (Quyết định mở #1).
- **Phương án khác đã xem xét**: tính balance = `initial_balance + Σ signed` từ bảng `transactions` ngay — **loại** vì lý do trên; hạ tầng đúng rule suy ra đã được chuẩn bị sẵn (cột `initial_balance` + dòng signed) để PBI sau bật một cách an toàn.

### R5 — Vòng đọc "GIAO DỊCH GẦN ĐÂY" của màn chi tiết ví chuyển về đọc DB qua repository

- **Quyết định**: Màn chi tiết ví nạp danh sách giao dịch đúng ví từ repository (bảng `transactions`, lọc `wallet_id`, sắp mới nhất trước) thay vì `TransactionSource`. Giữ tham số `transactions` làm seam cho widget test (bơm thẳng list như PBI 6); khi không bơm thì đọc DB. Sau khi một lần chuyển thành công (pop về), màn nạp lại để vế chuyển xuất hiện ngay.
- **Lý do**: FR-014 — khoản chuyển mới phải hiện trong cả hai ví; không thể nếu list vẫn là hằng tĩnh `TransactionSource`.
- **Phương án khác đã xem xét**: màn chi tiết giữ list tĩnh + tự chèn dòng vừa tạo bằng tay — **loại**: chỉ đúng một ví, sơ hở trùng/thiếu, không bền khi PBI sau sửa/xóa.

### R6 — Mở rộng seam hiện có: thêm method giao dịch vào `WalletRepository` (interface + `DriftWalletRepository` + `FakeWalletRepository`), orchestrate trong `WalletController`

- **Quyết định**: `WalletRepository` nhận thêm:
  - `Future<List<Transaction>> transactionsOf(int walletId)` — sắp mới nhất trước, trả domain `Transaction`;
  - `Future<void> performTransfer({required int fromWalletId, required int toWalletId, required int amount, required DateTime date, String note})` — ghi atomic (R1/R4).
  `WalletController` thêm `Future<void> transfer(...)` gọi repository rồi `_reload()` cache ví. Màn chuyển tiền nhận controller (như `WalletFormScreen` PBI 7).
- **Lý do**: Transfer là thao tác domain **ví** chạm hai bảng (`wallets` + `transactions`) trong một DB — đặt cùng một seam ghi, một drift impl, một fake cho test, đúng mẫu "1 repo/1 db" của PBI 7. `FakeWalletRepository` bắt buộc phải bổ sung hai method (nếu không test cũ không compile) — mọi test màn/controller chạy fake, không cần sqlite native.
- **Phương án khác đã xem xét**: tạo `TransactionRepository` riêng song song — **loại**: hai seam cùng chạm hai bảng, wiring thừa; module Giao dịch (danh sách toàn app, lọc theo nhiều tiêu chí) khi đến sẽ mở rộng/tách repository theo nhu cầu, không phải làm từ bây giờ.

### R7 — Sinh `transfer_group_id`: lấy id của vế ghi trước làm group, cập nhật lại vế đó

- **Quyết định**: Trong một `db.transaction()`: insert vế nguồn (`transfer_group_id = null`) → lấy `id` sinh ra → insert vế đích với `transfer_group_id = id` đó → update vế nguồn set cùng giá trị. (2 insert + 1 update, cùng transaction).
- **Lý do**: Không cần nguồn id phụ; group đảm bảo unique vì là khóa chính thật của một vế; an toàn offline một người dùng.
- **Phương án khác đã xem xét**: (a) tự sinh group bằng `MAX(transfer_group_id)+1` — **loại**: lý thuyết đụng độ, thêm truy vấn; (b) timestamp+random — **loại**: cần thêm nguồn entropy, khó đọc.

### R8 — Bộ lọc ví nguồn/đích và xác nhận là hàm thuần `transfer_rules.dart` (đúng tinh thần `wallet_rules.dart` PBI 7)

- **Quyết định**: Hàm thuần `core/wallet/transfer_rules.dart`:
  - `eligibleDestinations(List<Wallet> wallets, int sourceId)` — ví đang hoạt động (không ẩn), `currency` khớp ví nguồn, `type != credit`, `id != sourceId`;
  - `bool canTransferFromWallet(Wallet w)` — `type != credit` (FR-018); nguồn ẩn đang đứng ở màn chi tiết vẫn chuyển được (spec §Giả định);
  - nhóm helper phòng khi màn chi tiết cần: có ví đích nào không (FR-019).
- **Lý do**: spec đặc tả rõ tập loại trừ (credit, ẩn, khác tiền tệ, trùng nguồn) — tách thuần để unit test thẳng, không bơm widget; bám tiền lệ `wallet_rules`.
- **Phương án khác**: viết filter rải trong screen — **loại**: khó test biên (một ví / chỉ còn credit / ẩn…).

### R9 — Giao diện chuyển tiền: sub-page `SubPageScaffold`, không thêm thư viện; formatter phân tách nghìn là helper thuần + `TextEditingController` local

- **Quyết định**: Màn `wallet_transfer_screen.dart` là `StatefulWidget` trên `SubPageScaffold` (app bar teal + back, không bottom nav) — đúng mockup `wallet-transfer-screen.svg`. Số tiền nhập có phân tách nghìn sống (gõ `2000000` → hiện `2.000.000`, FR-005): thêm hàm thuần `parseAmount(String)` (bỏ ký tự không phải số) đặt gần `money_format.dart`, trên mỗi `onChanged` hiển thị lại bằng `formatAmount` sẵn có + đặt con trỏ cuối. Ngày giờ dùng `showDatePicker` + `showTimePicker` Material (mặc định hiện tại). Chọn ví đích bằng modal bottom sheet liệt kê dòng (icon + tên + số dư) lọc bởi R8. Không thêm package.
- **Lý do**: Form ví hiện chỉ nhập số trần `digitsOnly` — chưa đáp ứng "phân tách nghìn tự động"; bổ sung đúng chỗ. Native picker đủ, không cần `intl`/date lib (đúng Ponytail: stdlib/platform first).
- **Phương án khác**: thêm package `intl` / text-mask — **loại**: một hàm thuần là đủ.

### R10 — Chống trùng lặp & lỗi nửa chừng phía giao diện

- **Quyết định**: Nút "Xác nhận chuyển tiền" vô hiệu khi: thiếu ví đích, số tiền ≤ 0, hoặc đang lưu (ngăn chạm hai lần — spec biên "chạm liên tiếp"); khi lưu bật trạng thái saving. Lỗi validate hiển thị đúng trường (số tiền / ngày giờ). Dòng "Số dư sau chuyển" chỉ hiển thị khi đủ nguồn + đích + tiền; cảnh báo mềm dùng token `coral` khi số dư nguồn sau chuyển âm (coral dành cho cảnh báo theo design system), không chặn xác nhận. Khoản chuyển được ghi trong một `db.transaction()` nên lỗi giữa chừng → rollback toàn bộ (FR-015).
- **Lý do**: chống tạo trùng (SC-006) và trạng thái lệch một phía — spec yêu cầu cứng.
- **Phương án khác**: tin tưởng transaction cho việc chống double-tap — **loại**: chạm đúp vẫn gọi hai lần; phải vô hiệu nút + cờ saving ở UI.

## Các điểm mở cần người dùng chốt (nếu có)

Không — toàn bộ mục `NEEDS CLARIFICATION` ban đầu (nơi lưu bút toán, số dư cache hay suy ra, mức độ seed, cột bảng transactions) đã được giải quyết ở R1–R4 theo đúng mô hình docs đã chốt và tiền lệ PBI 7. Các quyết định đáng chú ý nhất (R1 giới thiệu bảng giao dịch sớm, R2 seed dữ liệu mẫu) được nêu lý do + phương án thay thế đầy đủ để người duyệt cân nhắc trước khi `/sora-task`.
