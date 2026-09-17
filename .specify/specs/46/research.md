# Nghiên cứu: Chuẩn hoá điều hướng giữa màn hình (PBI 46)

Rà soát toàn bộ 53 điểm dùng `MaterialPageRoute` trong `lib/`. 32 điểm đã khai báo generic tường minh (`MaterialPageRoute<void>`, sẵn đúng chuẩn — không đổi). 21 điểm còn thiếu, chia làm 2 nhóm.

## Quyết định 1 — Cách chuẩn hoá 21 điểm thiếu generic

**Quyết định**: thêm `<T>` vào `MaterialPageRoute<T>(...)` khớp đúng kiểu `T` mà lời gọi `Navigator.of(context).push<T>(...)` bao ngoài đã khai báo (hoặc khớp kiểu biến nhận kết quả `await push(...)` nếu `push` cũng chưa có generic).

**Lý do**: 21/21 điểm đã kiểm tra, kiểu mong đợi luôn suy được trực tiếp từ cách dùng giá trị trả về (gán biến, so sánh, truyền tham số) hoặc từ việc không dùng kết quả (`void`). Không cần đổi cấu trúc code, không rủi ro hành vi.

**Phương án khác đã xem xét**: dùng route đặt tên (named routes) toàn app — loại vì FR-046 xác định named routes ngoài phạm vi (không có nhu cầu deep-link, chi phí đổi lớn hơn giá trị).

## Quyết định 2 — Danh sách 21 điểm & kiểu áp dụng

| File | Dòng | Kiểu | Cơ sở |
|---|---|---|---|
| `core/widgets/txn_row_tile.dart` | 38 | `<void>` | Push không `await`/không gán, bấm-rồi-quên |
| `screens/budget_overview_screen.dart` | 129 | `<bool>` | Gán `saved`, so sánh `saved != true` (từ `BudgetFormScreen`) |
| `screens/budget_overview_screen.dart` | 145 | `<void>` | `await` nhưng không gán, chỉ check `mounted` (từ `BudgetDetailScreen`) |
| `screens/budget_overview_screen.dart` | 162 | `<bool>` | Gán `saved`, so sánh `!= true` (từ `AddTransactionScreen`) |
| `screens/budget_form_screen.dart` | 111 | `<Category>` | Gán `picked` (`Category?`) từ `CategoryPickerScreen` |
| `screens/budget_detail_screen.dart` | 156 | `<bool>` | Gán `saved`, so sánh `!= true` (từ `BudgetFormScreen`) |
| `core/app_shell.dart` | 148 | `<bool>` | Hàm trả `Future<bool?>`, dùng `saved == true` (từ `AddTransactionScreen`) |
| `screens/add_transaction_screen.dart` | 275 | `<bool>` | Gán `transferred`, so sánh `== true` (từ `WalletTransferScreen`) |
| `screens/add_transaction_screen.dart` | 311 | `<Category>` | Gán `picked`, check `!= null` (từ `CategoryPickerScreen`) |
| `screens/add_transaction_screen.dart` | 363 | `<List<String>>` | Gán `picked` → `_tags` (từ `TagPickerScreen`) |
| `screens/transaction_screen.dart` | 30 | `<TxnSearchFilter>` | Gán `filter`, truyền `controller.setFilter` (từ `SearchFilterScreen`) |
| `screens/transaction_detail_screen.dart` | 204 | `<bool>` | Gán `saved`, `if (saved == true)` (từ `WalletTransferScreen`) |
| `screens/transaction_detail_screen.dart` | 236 | `<bool>` | Cùng mẫu `saved == true` (từ `AddTransactionScreen`) |
| `screens/transaction_detail_screen.dart` | 299 | `<bool>` | Cùng mẫu `saved == true` (từ `WalletTransferScreen`) |
| `screens/transaction_detail_screen.dart` | 330 | `<bool>` | Cùng mẫu `saved == true` (từ `AddTransactionScreen`) |
| `screens/wallet_detail_screen.dart` | 75 | `<Wallet>` | Gán `edited`, check `!= null` → `_wallet` (từ `WalletFormScreen`) |
| `screens/wallet_detail_screen.dart` | 113 | `<bool>` | Gán `transferred`, `== true` (từ `WalletTransferScreen`) |
| `screens/scan/scan_confirm_screen.dart` | 176 | `<Category>` | Gán `picked`, check `!= null` (từ `CategoryPickerScreen`) |
| `screens/scan/scan_processing_screen.dart` | 124 | `<bool>` | Gán `saved`, `saved == true ? ...` (từ `ScanConfirmScreen`) |
| `core/scan/scan_flow.dart` | 39 | `<bool>` | Gán `proceed`, check `!= true` (từ `DeviceCheckScreen`) |
| `core/scan/scan_flow.dart` | 49 | `<String>` | Gán `imagePath`, check `== null` (từ `ScanCameraScreen`) |
| `core/scan/scan_flow.dart` | 56 | `<ScanStepResult>` | Gán `step`, `switch (step)` (từ `ScanProcessingScreen`) |
| `core/scan/scan_flow.dart` | 77 | `<bool>` | Gán `saved`, trả `saved == true` (từ `AddTransactionScreen`) |

Nguồn: agent đọc trực tiếp 22 vị trí kèm 15-20 dòng ngữ cảnh quanh mỗi điểm (2026-09-17).

## Quyết định 3 — Cơ chế `popUntil` + `onSelectTab`

**Quyết định**: giữ nguyên, không đưa vào phạm vi sửa.

**Lý do**: dùng nhất quán ở 5 màn (`ReportScreen`, `BudgetOverviewScreen`, `BudgetDetailScreen`, `ReportCategoryDetailScreen`, `NotificationCenterScreen`), có comment "research R1" xác nhận chủ đích thiết kế — không phải lệch chuẩn như audit gốc mô tả.

**Phương án khác đã xem xét**: đổi sang trả kết quả qua `Navigator.pop(context, value)` như audit gốc đề xuất — loại vì đây là điều hướng liên-tab qua `AppShell` (pop về root rồi đổi `IndexedStack`), không phải quan hệ cha-con đơn giữa 2 route nên cơ chế trả-giá-trị-qua-pop không áp dụng được.
