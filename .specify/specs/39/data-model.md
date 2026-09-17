# Mô hình dữ liệu: Sửa giao dịch (PBI 39)

Không đổi schema drift (giữ nguyên v10) — chỉ thêm 2 thao tác ghi mới trên bảng `transactions`/`wallets` đã có.

## Entity: Transaction (không đổi)

Giữ nguyên `lib/core/transaction/transaction.dart` — PBI này chỉ **cập nhật** dòng hiện có (`UPDATE`), không thêm cột.

## Thao tác mới trên `WalletRepository`

### `updateTransaction` — sửa giao dịch Thu/Chi

```
Future<void> updateTransaction({
  required Transaction original,   // dòng đang sửa — dùng để hoàn tác số dư cũ
  required int walletId,           // ví áp dụng mới (có thể trùng ví cũ)
  required TxnType type,           // income | expense (không nhận transfer/adjustment — R4)
  required int amount,             // > 0
  required Category category,      // category.type phải khớp type
  required DateTime date,
  String note = '',
  String tags = '',
  String receiptImage = '',
});
```

- **Bất biến**: một `db.transaction()` — hoàn tác `original.amount` (đã có dấu) khỏi `original.walletId`, áp `signedAmount` mới (`+` income / `−` expense) vào `walletId`, ghi đè dòng `transactions.id == original.id` (walletId/type/amount có dấu/category/categoryId/note/date/tags/receiptImage). `transferGroupId`/`location`/`source` giữ nguyên giá trị cũ (không phải trường sửa được ở màn này).
- **Đầu vào không hợp lệ** (không tự chặn ở repository, validate ở tầng UI/module thuần như `addTransaction`): `amount <= 0`, `category.type` không khớp `type`.

### `updateTransfer` — sửa giao dịch Chuyển khoản

```
Future<void> updateTransfer({
  required int transferGroupId,  // = id vế nguồn, bất biến
  required int fromWalletId,
  required int toWalletId,
  required int amount,           // > 0
  required DateTime date,
  String note = '',
});
```

- **Bất biến**: một `db.transaction()` — đọc 2 dòng hiện có (`id == transferGroupId` là vế nguồn, `transferGroupId == transferGroupId && id != transferGroupId` là vế đích), hoàn tác số dư cũ (`+|amount cũ|` vào ví nguồn cũ, `−|amount cũ|` khỏi ví đích cũ), áp số dư mới (`−amount` vào `fromWalletId`, `+amount` vào `toWalletId`), rồi ghi đè `walletId`/`amount` (có dấu)/`date`/`note` của cả 2 dòng. `id` và `transfer_group_id` của 2 dòng không đổi.
- **Đầu vào không hợp lệ**: `amount <= 0`, `fromWalletId == toWalletId` — validate ở UI (bám `transfer_rules.dart` hiện có), repository không tự chặn.

## Thay đổi tham số màn hình (không phải entity, ghi chú cho tasks)

- `AddTransactionScreen`: thêm tham số tùy chọn ở chế độ sửa — `Transaction? editing`, `Category? initialCategory`, `Wallet? initialWallet` (null cả 3 = chế độ thêm mới, hành vi không đổi).
- `WalletTransferScreen`: thêm tham số tùy chọn ở chế độ sửa — `int? editingTransferGroupId`, `Wallet? destinationWallet`, `int? initialAmount`, `DateTime? initialDate`, `String? initialNote`.
- `TransactionDetailScreen`: nút "Sửa" tự tải lại `Transaction`/`Wallet`/`Category` gốc từ repository rồi điều hướng đúng màn theo `view.type`.
