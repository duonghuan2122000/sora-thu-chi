# Nghiên cứu kỹ thuật — PBI 33 (Nội dung màn Tổng quan)

## Quyết định 1 — Nguồn dữ liệu: dùng lại `TransactionController`, không tạo controller riêng

- **Quyết định**: Màn Tổng quan đọc dữ liệu qua `TransactionController` (singleton `ensureTransactionController()`) đã có sẵn cho màn Giao dịch — `data.value.stat` (thu/chi tháng này) và `data.value.groups` (đã nhóm ngày, mới nhất trước) cho danh sách gần đây.
- **Lý do**: `TransactionController.load()` đã đọc `allTransactions()` + `loadAll()` (ví) và tính sẵn `MonthStat` (`monthlyIncomeExpense`) + `List<DayGroup>` (`buildDisplayRows`/`groupDisplayRows`, đã gộp 2 vế transfer). Tự dựng controller riêng nghĩa là đọc DB 2 lần cho cùng một tập dữ liệu và chép lại logic gộp transfer đã có.
- **Phương án khác đã xem xét**: Controller/repository riêng cho Dashboard — bỏ, vì trùng lặp không cần thiết (YAGNI); 2 tab cùng nhìn 1 tập giao dịch mới nhất, không có lý do tách state.

## Quyết định 2 — Tổng số dư: thêm `walletTotal` vào `TransactionView`, tính cùng lúc `load()`

- **Quyết định**: `TransactionController.load()` đã gọi `_repository.loadAll()` để lấy tên ví cho dòng hiển thị — tận dụng luôn danh sách ví đó để tính `activeTotal(wallets)` (hàm thuần có sẵn ở `core/wallet/wallet.dart`), lưu vào trường mới `TransactionView.walletTotal`.
- **Lý do**: Không cần thêm lệnh đọc DB nào — ví đã có trong bộ nhớ ngay tại `load()`. `activeTotal()` đã đúng định nghĩa "tổng ví đang hoạt động, không ẩn" theo [[Ví & Tài khoản]].
- **Phương án khác đã xem xét**: Dashboard tự gọi `ensureWalletRepository().loadAll()` riêng — bỏ, vì đọc trùng bảng `wallets` lần thứ 2 trong cùng một lần vào màn.

## Quyết định 3 — Dùng lại widget dòng giao dịch & card thống kê, tách khỏi `transaction_screen.dart`

- **Quyết định**: Tách `_TransactionRow`/`_RowBubble` → `core/widgets/txn_row_tile.dart` (`TxnRowTile`, public) và `_MonthStatCard`/`_StatBlock` → `core/widgets/month_stat_row.dart` (`MonthStatRow`, public). Cả `TransactionScreen` lẫn `DashboardScreen` cùng dùng 2 widget này.
- **Lý do**: Thiết kế tham chiếu (`docs/dashboard/man-hinh-tong-quan.svg`) vẽ đúng cùng kiểu dòng giao dịch (icon bubble theo danh mục, teal/coral/trung tính, mở chi tiết khi chạm) và đúng cùng kiểu 2 thẻ thu/chi đã có ở màn Giao dịch — chép lại ~150 dòng logic màu/định dạng/điều hướng là vi phạm DRY không cần thiết.
- **Phương án khác đã xem xét**: Viết widget dòng/thẻ riêng cho Dashboard — bỏ, vì trùng lặp thị giác + hành vi 1:1 với màn Giao dịch, khác biệt duy nhất là Dashboard hiển thị **tối đa 5 dòng phẳng** thay vì nhóm theo ngày.

## Quyết định 4 — Danh sách gần đây: lấy 5 dòng đầu sau khi làm phẳng `groups`, không nhóm theo ngày

- **Quyết định**: Từ `TransactionView.groups` (đã sắp mới nhất trước theo ngày, trong ngày theo `sortId`), nối các `DayGroup.rows` liên tiếp rồi lấy `take(5)` — không hiển thị tiêu đề nhóm ngày trên Dashboard (khác màn Giao dịch).
- **Lý do**: Đúng thiết kế tham chiếu (danh sách phẳng, không tiêu đề ngày) và đúng giả định trong spec.md (top 5, quy ước đã dùng ở Báo cáo).
- **Phương án khác đã xem xét**: Thêm hàm thuần mới `recentRows(transactions, now, {limit})` tính riêng — bỏ, vì `groups` đã đúng thứ tự cần, làm phẳng + cắt là đủ, không cần hàm tính toán mới.

## Quyết định 5 — Làm mới dữ liệu khi quay lại màn Tổng quan

- **Quyết định**: Dashboard là tab mặc định lúc khởi động (không qua sự kiện chọn tab) → tự gọi `ensureTransactionController().load()` trong `initState`. Khi người dùng rời rồi quay lại tab Tổng quan, `AppShell._onTabSelected` thêm nhánh `index == 0` gọi lại `load()` — bám đúng mẫu đã có cho tab Giao dịch (`index == 1`) và Báo cáo (`index == 2`).
- **Lý do**: `TransactionController.load()` đã đọc lại cả giao dịch lẫn ví mỗi lần gọi ⇒ số dư + thu/chi tháng này + danh sách gần đây tự động mới theo đúng FR-007, không cần cơ chế theo dõi thay đổi (stream/listener) phức tạp hơn.
- **Phương án khác đã xem xét**: `StreamBuilder` lắng nghe thay đổi bảng `transactions`/`wallets` real-time — bỏ, over-engineering cho app single-user offline; load-lại-khi-vào-màn đã đủ và đúng mẫu toàn bộ codebase hiện có (research R6 các PBI trước).

## Quyết định 6 — Chế độ riêng tư (icon con mắt) — ngoài phạm vi

- **Quyết định**: Không triển khai trong PBI này (đã chốt ở spec.md mục "Ngoài phạm vi").
- **Lý do**: Privacy mode kéo theo mã hóa SQLCipher toàn DB + trạng thái bền `privacy.hide_balance` + tùy chọn re-auth (`docs/privacy/giai-phap-bao-mat-quyen-rieng-tu.md` §3.8/3.10) — một module độc lập lớn, chưa có PBI nào implement, không phù hợp gộp vào PBI "bổ sung nội dung Dashboard".
- **Phương án khác đã xem xét**: Không có — quyết định đã chốt tại bước spec, giữ nguyên ở bước plan.
