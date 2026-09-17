# Danh sách Task: Sửa giao dịch

**Mã PBI**: 39
**Nguồn**: plan.md, spec.md, research.md, data-model.md, quickstart.md

## Pha 1: Setup

Không cần task Setup riêng — không thêm dependency mới, không đổi schema, không có cấu trúc thư mục mới cần khởi tạo trước. Bắt đầu thẳng từ Pha 3.

## Pha 2: Foundational

Không có task nền tảng dùng chung bắt buộc trước mọi User Story — US1 (sửa Thu/Chi) và US2 (sửa Chuyển khoản) chạm 2 cặp method độc lập (`updateTransaction` vs `updateTransfer`) trên cùng file `wallet_repository.dart`/`wallet_repository_drift.dart`/`fake_wallet_repository.dart`, không phụ thuộc lẫn nhau. Nút "Sửa" ở `transaction_detail_screen.dart` được nối dần: nhánh Thu/Chi ở US1, nhánh Chuyển khoản ở US2.

## Pha 3: User Story 1 - Sửa giao dịch Thu/Chi (Ưu tiên: P1)

**Mục tiêu**: Người dùng sửa được số tiền/danh mục/ví/ngày giờ/ghi chú/tag/ảnh hóa đơn của giao dịch Thu hoặc Chi đã có, kể cả đổi Thu ⇄ Chi hoặc đổi ví áp dụng; số dư ví liên quan luôn đúng sau khi lưu (FR-001…007, FR-003 phần Thu/Chi).
**Tiêu chí kiểm thử độc lập**: Mở một giao dịch Chi từ màn Chi tiết → chạm "Sửa" → màn "Sửa giao dịch" mở với dữ liệu điền sẵn đúng → đổi số tiền/ví/loại → Lưu → quay lại Chi tiết hiển thị đúng dữ liệu mới → số dư ví cũ/mới đúng theo phép tính hoàn tác-rồi-áp-lại. Thoát màn khi đang dở dang → hỏi xác nhận; validate thiếu trường → không lưu, giữ bản gốc.

- [X] T001 [US1] Thêm khai báo `Future<void> updateTransaction({required Transaction original, required int walletId, required TxnType type, required int amount, required Category category, required DateTime date, String note = '', String tags = '', String receiptImage = ''})` vào interface `app/sora_thu_chi/lib/data/wallet_repository.dart` (docblock nêu rõ hoàn tác `original.amount` khỏi `original.walletId` rồi áp `amount` mới vào `walletId`, bám mẫu `addTransaction`).
- [X] T002 [US1] Impl `updateTransaction` tại `app/sora_thu_chi/lib/data/wallet_repository_drift.dart`: một `_db.transaction()` — đọc ví cũ (`original.walletId`) và ví mới (`walletId`, có thể là cùng dòng nếu trùng id), hoàn tác `original.amount` (đã có dấu) khỏi ví cũ, áp `signedAmount` mới (`type == income ? amount : -amount`) vào ví mới, rồi `UPDATE transactions` đủ cột (`walletId`/`type`/`amount`/`category`/`categoryId`/`note`/`transactionDate`/`tags`/`receiptImage`) theo `id == original.id`.
- [X] T003 [US1] Thêm `updateTransaction` vào `app/sora_thu_chi/test/fakes/fake_wallet_repository.dart` — cập nhật danh sách in-memory + số dư ví theo đúng logic hoàn tác-rồi-áp-lại như T002.
- [X] T004 [P] [US1] Thêm case cho `updateTransaction` vào `app/sora_thu_chi/test/transactions_dao_test.dart` (dùng `DriftWalletRepository` thật): sửa số tiền cùng ví (số dư đúng), đổi ví áp dụng (cả 2 ví đúng), đổi loại Thu↔Chi (dấu số dư đảo đúng), sửa category/note/tags/receiptImage được ghi đè đúng.
- [X] T005 [US1] Mở rộng `isDirty` tại `app/sora_thu_chi/lib/core/transaction/add_form.dart`: thêm tham số tùy chọn `int initialAmount = 0, Category? initialCategory, String initialNote = '', DateTime? initialDate, TxnType initialType = TxnType.expense, bool initialHasTags = false, bool initialHasReceiptImage = false`, so sánh state hiện tại với baseline này thay vì hằng số cố định (giữ mặc định y hệt hành vi cũ khi không truyền).
- [X] T006 [P] [US1] Thêm case vào `app/sora_thu_chi/test/add_form_test.dart`: `isDirty` trả `false` khi state hiện tại trùng khớp baseline tùy chỉnh (không phải baseline mặc định "form trống"), trả `true` khi lệch một trường bất kỳ so với baseline đó.
- [X] T007 [US1] Sửa `app/sora_thu_chi/lib/screens/add_transaction_screen.dart`: thêm tham số constructor tùy chọn `Transaction? editing`, `Category? initialCategory`, `Wallet? initialWallet`; khi `editing != null` — seed `_type/_amountCtrl/_category/_wallet/_date/_noteCtrl/_tags/_receiptImagePath` từ dữ liệu truyền vào, tiêu đề app bar đổi "Sửa giao dịch".tr, ẩn/khóa mục "Chuyển khoản" trên segmented tab (R4), `_isDirty` truyền baseline từ `editing`, `_save()` gọi `_repository.updateTransaction(original: editing!, ...)` thay vì `addTransaction` khi đang sửa.
- [X] T008 [US1] Sửa `app/sora_thu_chi/lib/screens/transaction_detail_screen.dart`: nút "Sửa" (nhánh giao dịch Thu/Chi, `view.type != TxnType.transfer`) — tải `Transaction` gốc qua `repository.allTransactions()`, danh mục qua `repository.categoriesIncludingHidden(type:)` khớp `categoryId`, ví qua `repository.loadAll()` khớp `walletId`; `Navigator.push` `AddTransactionScreen(editing: ..., initialCategory: ..., initialWallet: ...)`; kết quả `true` → gọi lại `_load()`.
- [X] T009 [US1] Thêm case vào `app/sora_thu_chi/test/add_transaction_screen_test.dart`: mở màn với `editing` set sẵn → các trường hiển thị đúng dữ liệu cũ, tiêu đề "Sửa giao dịch", tab "Chuyển khoản" không chọn được; đổi số tiền/ví/loại rồi Lưu → gọi đúng `updateTransaction` với tham số mới; bỏ trống số tiền rồi Lưu → báo thiếu trường, không gọi repository; đổi 1 trường rồi bấm đóng → hộp thoại xác nhận xuất hiện.
- [X] T010 [US1] Thêm case vào `app/sora_thu_chi/test/transaction_detail_screen_test.dart`: chạm "Sửa" trên giao dịch Chi → mở đúng `AddTransactionScreen` với dữ liệu điền sẵn khớp giao dịch; sau khi màn sửa pop `true` → màn Chi tiết nạp lại và hiển thị đúng dữ liệu mới.

**Checkpoint**: `flutter analyze` sạch, `flutter test` pass — sửa giao dịch Thu/Chi hoạt động đầu-cuối (mở/điền sẵn/đổi/lưu/hủy/validate), giao dịch Chuyển khoản vẫn no-op (US2 xử lý tiếp).

## Pha 4: User Story 2 - Sửa giao dịch Chuyển khoản (Ưu tiên: P2)

**Mục tiêu**: Người dùng sửa được số tiền/ví nguồn/ví đích/ngày giờ/ghi chú của một giao dịch Chuyển khoản đã có; số dư cả hai ví liên quan luôn đúng sau khi lưu (FR-001…008 phần Chuyển khoản).
**Tiêu chí kiểm thử độc lập**: Mở một giao dịch Chuyển khoản từ màn Chi tiết → chạm "Sửa" → màn "Chuyển tiền giữa ví" mở với Từ ví/Đến ví/Số tiền/Ngày giờ/Ghi chú điền sẵn đúng → đổi số tiền hoặc đổi ví đích → Xác nhận → quay lại Chi tiết hiển thị đúng → số dư cả ví nguồn/đích cũ và mới đều đúng.

- [X] T011 [US2] Thêm khai báo `Future<void> updateTransfer({required int transferGroupId, required int fromWalletId, required int toWalletId, required int amount, required DateTime date, String note = ''})` vào interface `app/sora_thu_chi/lib/data/wallet_repository.dart` (docblock nêu rõ `transferGroupId` = id vế nguồn bất biến, hoàn tác số dư 2 vế cũ rồi áp lại theo ví/tiền mới, ghi đè tại chỗ 2 dòng — không xóa/insert).
- [X] T012 [US2] Impl `updateTransfer` tại `app/sora_thu_chi/lib/data/wallet_repository_drift.dart`: một `_db.transaction()` — đọc vế nguồn (`id == transferGroupId`) và vế đích (`transferGroupId == transferGroupId && id != transferGroupId`), hoàn tác số dư cũ (`+|amount cũ|` vào ví nguồn cũ, `−|amount cũ|` khỏi ví đích cũ), áp số dư mới (`−amount` vào `fromWalletId`, `+amount` vào `toWalletId`), `UPDATE` cả 2 dòng (`walletId`/`amount` có dấu/`transactionDate`/`note`), giữ nguyên `id`/`transfer_group_id`.
- [X] T013 [US2] Thêm `updateTransfer` vào `app/sora_thu_chi/test/fakes/fake_wallet_repository.dart` — cập nhật 2 dòng in-memory + số dư 2 ví theo đúng logic hoàn tác-rồi-áp-lại như T012.
- [X] T014 [P] [US2] Thêm case cho `updateTransfer` vào `app/sora_thu_chi/test/transactions_dao_test.dart`: sửa số tiền giữ nguyên 2 ví (số dư đúng), đổi ví đích sang ví thứ 3 (ví đích cũ hoàn tác, ví đích mới nhận đúng, ví nguồn không đổi thêm), `id`/`transfer_group_id` của 2 dòng không đổi sau khi sửa.
- [X] T015 [US2] Thêm `Future<void> updateTransfer({required int transferGroupId, required int fromId, required int toId, required int amount, required DateTime date, String note = ''})` vào `app/sora_thu_chi/lib/core/wallet/wallet_controller.dart`, mirror `transfer()` (gọi `_repository.updateTransfer` + nạp lại `_wallets`, giữ nguyên phần thông báo đẩy fire-and-forget như `transfer()`).
- [X] T016 [US2] Sửa `app/sora_thu_chi/lib/screens/wallet_transfer_screen.dart`: thêm tham số constructor tùy chọn `int? editingTransferGroupId`, `Wallet? destinationWallet`, `int? initialAmount`, `DateTime? initialDate`, `String? initialNote`; khi `editingTransferGroupId != null` — seed `_destination/_amountCtrl/_date/_noteCtrl` từ dữ liệu truyền vào, tiêu đề đổi "Sửa chuyển khoản".tr, nhãn nút chính đổi "Lưu thay đổi".tr; `_confirm()` gọi `_controller.updateTransfer(transferGroupId: ..., ...)` thay vì `transfer` khi đang sửa; thêm `PopScope`/hộp thoại xác nhận khi rời màn có thay đổi so với dữ liệu gốc (so sánh trực tiếp `_source.id`/`_destination?.id`/`_amount`/`_date`/`_noteCtrl.text` với giá trị khởi tạo, bám mẫu `_confirmDiscard` của `add_transaction_screen.dart`).
- [X] T017 [US2] Sửa `app/sora_thu_chi/lib/screens/transaction_detail_screen.dart`: nút "Sửa" nhánh giao dịch Chuyển khoản (`view.type == TxnType.transfer`) — tải 2 vế qua `repository.allTransactions()` lọc theo `transferGroupId` của `widget.ref`, ví nguồn/đích qua `repository.loadAll()`; `Navigator.push` `WalletTransferScreen(sourceWallet: ..., destinationWallet: ..., editingTransferGroupId: ..., initialAmount: ..., initialDate: ..., initialNote: ..., controller: ensureWalletController())`; kết quả `true` → gọi lại `_load()`.
- [X] T018 [P] [US2] Thêm case vào `app/sora_thu_chi/test/wallet_transfer_screen_test.dart`: mở màn ở chế độ sửa → các trường hiển thị đúng dữ liệu cũ, tiêu đề/nút đổi nhãn; đổi số tiền hoặc đổi Đến ví rồi Xác nhận → gọi đúng `updateTransfer`; đổi 1 trường rồi rời màn → hộp thoại xác nhận xuất hiện.
- [X] T019 [US2] Thêm case vào `app/sora_thu_chi/test/transaction_detail_screen_test.dart`: chạm "Sửa" trên giao dịch Chuyển khoản → mở đúng `WalletTransferScreen` với dữ liệu điền sẵn khớp 2 vế; sau khi màn sửa pop `true` → màn Chi tiết nạp lại và hiển thị đúng dữ liệu mới.

**Checkpoint**: `flutter analyze` sạch, `flutter test` pass — sửa giao dịch Chuyển khoản hoạt động đầu-cuối, không phá US1.

## Pha cuối: Polish & Cross-cutting

- [X] T020 Cập nhật docblock đầu `add_transaction_screen.dart` và `wallet_transfer_screen.dart` — phản ánh chế độ sửa mới (điểm vào từ `transaction_detail_screen.dart`, tham số `editing`/`editingTransferGroupId`).
- [X] T021 Chạy `flutter analyze` + `flutter test` toàn bộ, xác nhận không có test đỏ mới phát sinh ngoài baseline đã biết.
- [X] T022 Đồng bộ wiki: cập nhật `wiki-knowledge/entity/Giao dịch.md` (nút "Sửa" ở màn Chi tiết giao dịch chuyển từ no-op sang hoạt động thật, PBI 39) + `wiki-knowledge/concept/Lộ trình phát triển.md` + append `wiki-knowledge/log.md` (dùng skill `sora-wiki`).

## Sơ đồ phụ thuộc

- US1 và US2 độc lập về code (khác method repository, khác màn hình) — có thể triển khai theo thứ tự bất kỳ, nhưng cùng sửa `transaction_detail_screen.dart` nên nên làm tuần tự (US1 trước, US2 sau) để tránh xung đột merge trên cùng file.
- T001→T002→T003→T004 tuần tự trong US1 (cùng thay đổi chữ ký `updateTransaction` lan xuống fake + test). T005→T006 tuần tự (hàm rồi test). T007 phụ thuộc T001/T005 (dùng cả `updateTransaction` lẫn `isDirty` mới). T008 phụ thuộc T007 (cần `AddTransactionScreen` đã có tham số `editing`). T009/T010 chạy cuối US1, phụ thuộc toàn bộ task trước trong story.
- T011→T012→T013→T014 tuần tự trong US2 (như T001-T004). T015 phụ thuộc T011. T016 phụ thuộc T011/T015. T017 phụ thuộc T016 (và T008 đã tồn tại — chỉnh cùng file). T018/T019 chạy cuối US2.

## Chiến lược triển khai

- **MVP đề xuất**: User Story 1 (Sửa giao dịch Thu/Chi) — chiếm phần lớn tần suất sử dụng thực tế, đã đủ giá trị để phát hành độc lập (giao dịch Chuyển khoản tạm thời vẫn qua nút "Sửa" no-op như hiện tại nếu dừng ở đây).
- **Thứ tự giao hàng tăng dần**: US1 (P1) → US2 (P2) → Polish (đồng bộ wiki + rà soát cuối). Mỗi story kết thúc ở một checkpoint `flutter analyze`/`flutter test` sạch, có thể dừng an toàn giữa 2 story nếu cần ưu tiên việc khác.
