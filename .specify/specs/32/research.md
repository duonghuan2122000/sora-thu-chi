# Nghiên cứu: Loại bỏ dữ liệu mẫu khi cài mới

**Mã PBI**: 32

## Điểm cần làm rõ

### 1. Seed ví/giao dịch mẫu nằm ở đâu?

- **Quyết định**: Gỡ 2 lệnh gọi `_seedSampleWallets()` / `_seedSampleTransactions()` trong `onCreate` của [app_database.dart](../../../app/sora_thu_chi/lib/data/db/app_database.dart:210-216), xoá luôn nhánh `_seedSampleTransactions()` trong `onUpgrade` (`from < 2`, dòng 227-229 — DB v1 cũ chưa từng có bảng `transactions`). Xoá hẳn 2 hàm `_seedSampleWallets`/`_seedSampleTransactions` và import `WalletSource`/`TransactionSource` (không còn nơi nào khác trong `lib/` dùng tới — file `wallet_source.dart`/`transaction_source.dart` giữ nguyên, vẫn được `test/` tham chiếu làm fixture).
- **Lý do**: Đây là toàn bộ nguồn phát sinh 5 ví + 11 giao dịch mẫu (FR-001/FR-002). `_seedCategories()` (danh mục mặc định) giữ nguyên (FR-003) — đã tự chống trùng bằng check bảng rỗng, không đụng tới.
- **Phương án khác đã xem xét**: Thêm cờ bật/tắt seed (config/flag) — bị loại vì spec không cần tuỳ chọn, thêm cờ là phức tạp thừa (YAGNI) trong khi xoá thẳng lệnh gọi đã đủ và không phá schema.

### 2. Nâng cấp app từ bản cũ có bị ảnh hưởng không?

- **Quyết định**: Không đụng tới `onUpgrade` nhánh nào khác ngoài việc xoá seed giao dịch ở `from < 2`. Toàn bộ logic tạo bảng (`createTable`, `addColumn`) cho các schema v2→v10 giữ nguyên 100%.
- **Lý do**: FR-006 chỉ yêu cầu không tự ý xoá dữ liệu đã có — migration hiện tại không có bước xoá nào, chỉ tạo bảng/cột mới, nên không cần sửa gì thêm để thoả FR-006. Nhánh `from < 2` xoá seed vì đó vẫn là chèn "giao dịch mẫu" (không phải dữ liệu thật của người dùng) vào đúng những máy hiếm hoi chưa từng lên schema v2 — thoả cả FR-002 lẫn FR-006 (không xoá gì, chỉ ngừng chèn thêm dữ liệu giả).
- **Phương án khác đã xem xét**: Giữ seed cho riêng nhánh `from < 2` (coi là "máy cũ, không phải cài mới") — bị loại vì FR-002 áp dụng chung, không phân biệt onCreate/onUpgrade, và về bản chất nhánh này cũng đang tạo dữ liệu giả không phải của người dùng.

### 3. Màn hình có cần sửa để xử lý trạng thái rỗng không?

- **Quyết định**: Không sửa code màn hình ở bước plan này. Rà nhanh cho thấy các màn phụ thuộc ví/giao dịch (Tổng quan, Ví, Giao dịch, Báo cáo, Ngân sách, thêm giao dịch...) đã có nhánh xử lý danh sách rỗng (guard `wallets.isEmpty`/hiển thị rỗng có sẵn) từ các PBI trước. Việc còn lại là **xác nhận bằng QA thủ công** trên thiết bị cài mới thật (SC-003) — không giả định trước, để dành cho `/sora-task` lập task QA riêng theo từng màn nếu phát hiện lỗi thì mới sửa.
- **Lý do**: Tránh đoán trước lỗi chưa xác nhận (spec không mô tả lỗi cụ thể ở màn nào) — tuân theo nguyên tắc chỉ sửa cái đã biết cần sửa.
- **Phương án khác đã xem xét**: Audit code từng màn ngay ở bước plan — bị loại vì tốn công đọc lại toàn bộ 5+ màn trong khi QA tay trên app thật (nhanh, chính xác hơn) sẽ làm ở bước implement/QA.

### 4. Test hiện có phụ thuộc seed mẫu — ảnh hưởng gì?

- **Quyết định**: Các test sau đang giả định "onCreate/onUpgrade luôn có sẵn 5 ví + 11 giao dịch" và sẽ đỏ ngay khi gỡ seed — phải sửa lại trong `/sora-implement`:
  - `test/wallets_dao_test.dart` (dòng 24, 34, 89, 99, 140-157): test seed ví/giao dịch ban đầu — chuyển sang tự `insert` dữ liệu test thay vì trông cậy seed, hoặc đổi assertion sang "0 ví/0 giao dịch sau onCreate".
  - `test/budgets_dao_test.dart` (dòng 140-157, 342-349): assertion `loadAll().length == 5` / `allTransactions().length == 11` sau migration — sửa tương tự.
  - Rà thêm các test drift khác tham chiếu `AppDatabase()` mới tạo có ngầm định ví/giao dịch sẵn có (tìm bằng cách chạy `flutter test` sau khi gỡ seed, sửa theo lỗi đỏ thực tế — không đoán trước toàn bộ danh sách).
- **Lý do**: Đổi seed là đổi hành vi test đã "chốt cứng" theo dữ liệu mẫu cũ — phải cập nhật cùng lúc để không phá CI, nhưng nội dung nghiệp vụ các test này (đúng ràng buộc số dư, đúng migration cột...) không đổi, chỉ đổi cách chuẩn bị dữ liệu test.
- **Phương án khác đã xem xét**: Giữ một "seed test-only" riêng (chỉ chạy trong test harness) để test cũ không phải sửa — bị loại vì tạo đường code riêng cho test/production (phân kỳ hành vi, rủi ro che lỗi thật), và spec yêu cầu app thật không seed, nên test nên phản ánh đúng hành vi đó bằng cách tự chuẩn bị fixture.
