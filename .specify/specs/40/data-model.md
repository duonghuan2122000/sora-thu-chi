# Mô hình dữ liệu: Nhân bản giao dịch (PBI 40)

Không thêm bảng/trường/schema drift mới. Tính năng chỉ đọc lại các trường hiện có của `Transaction` (`lib/core/transaction/transaction.dart`) để điền sẵn vào form tạo mới.

## Trường được sao chép (giữ nguyên giá trị)

| Trường | Ghi chú |
|---|---|
| `walletId` (và ví đích với transfer) | Ví/ví nguồn-đích |
| `type` | Thu/Chi/Chuyển khoản — quyết định mở màn nào |
| `category` / `categoryId` | Danh mục |
| `note` | Ghi chú |
| `amount` | Số tiền (giá trị tuyệt đối, dấu suy theo `type` khi lưu) |
| `tags` | Chuỗi tag phân tách `,` |
| `receiptImage` | Đường dẫn ảnh hóa đơn (dùng chung tham chiếu file cho tới khi người dùng đổi/xóa trên bản sao) |
| `location` | Vị trí |

## Trường KHÔNG sao chép

| Trường | Giá trị khi nhân bản |
|---|---|
| `id` | Không truyền — DB tự sinh id mới khi lưu |
| `date` | `DateTime.now()` (FR-003) |
| `transferGroupId` | Không truyền `editingTransferGroupId` → `WalletController.transfer` tự sinh group mới, độc lập khỏi giao dịch gốc |

## Ràng buộc bất biến

- Giao dịch gốc không bị đọc-ghi gì ngoài đọc để prefill — không có thao tác `update`/`delete` nào chạm tới bản ghi gốc trong luồng nhân bản (FR-005).
- Không lưu bản ghi nào cho tới khi người dùng bấm Lưu trên màn đã mở (FR-002, FR-006) — hành vi này kế thừa nguyên trạng từ nhánh "tạo mới" đã có của `AddTransactionScreen`/`WalletTransferScreen`, không đổi logic lưu.
