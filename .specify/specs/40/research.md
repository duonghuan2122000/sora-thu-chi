# Nghiên cứu kỹ thuật: Nhân bản giao dịch (PBI 40)

## Quyết định 1: Cách truyền dữ liệu điền-sẵn vào `AddTransactionScreen`

- **Quyết định**: Thêm 4 tham số optional mới cho constructor `AddTransactionScreen` — `initialNote` (String?), `initialDate` (DateTime?), `initialTags` (String?), `initialReceiptImage` (String?) — song song với `initialCategory`/`initialWallet` đã có từ PBI 38. Khi `editing == null` (chế độ tạo mới), state khởi tạo đọc từ các tham số `initial*` này nếu có (fallback về mặc định hiện tại khi không truyền); khi `editing != null` (chế độ sửa, PBI 39), state vẫn đọc trực tiếp từ `editing` như hiện tại, không đổi hành vi.
- **Lý do**: `editing != null` vẫn là cờ DUY NHẤT quyết định `_save()` gọi `addTransaction` hay `updateTransaction` (`lib/screens/add_transaction_screen.dart` dòng 368-405) — không đổi cờ này thì không cần sửa logic lưu. Nhân bản chỉ cần đi qua nhánh tạo mới với dữ liệu điền sẵn, đúng yêu cầu FR-002/FR-006 (không lưu ngay, không cập nhật giao dịch gốc).
- **Phương án khác đã xem xét**:
  - Tạo constructor/factory riêng (`AddTransactionScreen.duplicate(...)`) — bị loại vì tăng bề mặt API không cần thiết, trong khi thêm tham số optional là đủ và nhất quán với `initialCategory`/`initialWallet` đã có.
  - Truyền cả object `Transaction` làm "duplicateFrom" riêng biệt với `editing` — bị loại vì trùng lặp dữ liệu, dễ nhầm lẫn với cờ `editing`.

## Quyết định 2: `WalletTransferScreen` — không cần sửa

- **Quyết định**: Tái dùng nguyên vẹn `WalletTransferScreen` hiện có. Nhân bản giao dịch Chuyển khoản truyền `destinationWallet`, `initialAmount`, `initialNote` từ giao dịch gốc, `initialDate: DateTime.now()`, và **không** truyền `editingTransferGroupId` (giữ `null`) để màn tự vào nhánh tạo mới (`WalletController.transfer`, không phải `updateTransfer`).
- **Lý do**: Constructor màn này (`lib/screens/wallet_transfer_screen.dart` dòng 26-54) đã tách sẵn cờ `editingTransferGroupId` (update) khỏi các tham số `initial*` (prefill) — đúng khớp với nhu cầu nhân bản mà không cần đổi code màn này.
- **Phương án khác đã xem xét**: Không có — cấu trúc hiện có đã khớp hoàn toàn với PBI 40.

## Quyết định 3: Nút "Nhân bản" ở màn Chi tiết giao dịch

- **Quyết định**: Thêm method `_duplicate(view)` trong `lib/screens/transaction_detail_screen.dart`, bám sát cấu trúc `_edit(view)` (dòng 167-255): tải lại `Transaction` gốc + `Category`/`Wallet` liên quan qua `ensureWalletRepository()`, rẽ nhánh theo `view.type == TxnType.transfer`. Khác biệt duy nhất so với `_edit`: **không** truyền `editing:`/`editingTransferGroupId:`, và ép ngày giờ = `DateTime.now()` thay vì giữ ngày gốc. Gán `onPressed: () => _duplicate(view)` cho nút phụ "Nhân bản" (dòng 123), thay `() {}`.
- **Lý do**: Tái dùng tối đa pattern đã kiểm chứng của PBI 39, giảm rủi ro hồi quy, code đối xứng dễ đọc.
- **Phương án khác đã xem xét**: Viết logic tải dữ liệu riêng cho nhân bản — bị loại vì trùng lặp không cần thiết với `_edit`.

## Quyết định 4: Giao dịch định kỳ (recurring)

- **Quyết định**: Không cần xử lý đặc biệt gì cho FR-007 (bản sao không gắn chuỗi định kỳ) — model `Transaction` (`lib/core/transaction/transaction.dart`) hiện **không có trường liên kết định kỳ nào**; nhân bản qua `addTransaction`/`WalletController.transfer` thông thường đã tự động tạo bản ghi độc lập.
- **Lý do**: Xác minh trực tiếp từ model, tránh giả định sai.
