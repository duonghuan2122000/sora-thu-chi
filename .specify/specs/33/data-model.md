# Mô hình dữ liệu — PBI 33 (Nội dung màn Tổng quan)

Không có bảng `drift` mới, không đổi schema (giữ **v10**). Chỉ mở rộng 1 view-model thuần đã có.

## `TransactionView` (mở rộng — `lib/core/transaction/transaction_controller.dart`)

| Trường | Kiểu | Trước PBI 33 | Sau PBI 33 |
|---|---|---|---|
| `groups` | `List<DayGroup>` | có | giữ nguyên |
| `stat` | `MonthStat` | có | giữ nguyên |
| `walletTotal` | `int` | — | **mới**: tổng số dư ví đang hoạt động (`activeTotal(wallets)`), tính trong `TransactionController.load()` từ danh sách ví đã đọc sẵn |

- `walletTotal` mặc định `0` khi chưa nạp lần nào (test dựng `TransactionView` cũ không truyền → cần cập nhật lời gọi kèm giá trị, hoặc đặt tham số có default `0` để không phá test hiện có).
- Không có `TxnRow`/`DayGroup`/`MonthStat` mới — dùng nguyên `core/transaction/transaction_list.dart`.

## Widget dữ liệu dẫn xuất (không phải bảng, chỉ trong bộ nhớ lúc build)

- **5 dòng gần đây**: `groups.expand((g) => g.rows).take(5).toList()` — không có kiểu dữ liệu mới, tái dùng `TxnRow`.

## Không có

- Không có entity/bảng mới.
- Không có API/contract bên ngoài (app offline, không có phần "Giao diện hợp đồng" — bỏ `contracts/`).
