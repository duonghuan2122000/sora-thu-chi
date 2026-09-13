# Danh sách Task: Nội dung màn Tổng quan

**Mã PBI**: 33
**Nguồn**: spec.md, plan.md, research.md, data-model.md, quickstart.md

Quy ước đường dẫn: tương đối `app/sora_thu_chi/`. Test file phẳng trong `test/`
(đúng cấu trúc hiện có của repo — không tạo `test/core/...`/`test/screens/...`).

## Pha 1: Setup

Không có setup riêng — không thêm dependency, không đổi schema drift (giữ v10).

## Pha 2: Foundational (chặn mọi User Story)

- [X] T001 Thêm trường `walletTotal` (kiểu `int`, mặc định `0`) vào `TransactionView` tại `lib/core/transaction/transaction_controller.dart`; sửa `TransactionController.load()` để tính `walletTotal: activeTotal(wallets)` (import `activeTotal` từ `lib/core/wallet/wallet.dart`) ngay sau dòng `final wallets = await _repository.loadAll();`, không đọc DB thêm lần nào.
- [X] T002 [P] Tạo `lib/core/widgets/txn_row_tile.dart`: tách `_TransactionRow`/`_RowBubble` từ `lib/screens/transaction_screen.dart` (dòng 433–552) thành widget public `TxnRowTile` (nhận `TxnRow row`), giữ nguyên toàn bộ hành vi (màu teal/coral/trung tính theo `TxnType`, icon bubble qua `categoryGlyph`, dấu `+`/`-` qua `formatSignedMoney`/`formatMoney`, `onTap` mở `TransactionDetailScreen` theo `detailGroupId`/`detailTransactionId`).
- [X] T003 [P] Tạo `lib/core/widgets/month_stat_row.dart`: tách `_MonthStatCard`/`_StatBlock` từ `lib/screens/transaction_screen.dart` (dòng 343–429) thành widget public `MonthStatRow` (nhận `MonthStat stat`), giữ nguyên layout 2 khối cạnh nhau + màu/mũi tên/format tiền.
- [X] T004 Sửa `lib/screens/transaction_screen.dart`: xoá `_TransactionRow`, `_RowBubble`, `_MonthStatCard`, `_StatBlock`; thay mọi chỗ dùng bằng `TxnRowTile(row: ...)` và `MonthStatRow(stat: ...)` (import từ `core/widgets/txn_row_tile.dart` và `core/widgets/month_stat_row.dart`); chạy `flutter test test/transaction_screen_test.dart` đảm bảo xanh nguyên trạng trước khi sang Pha 3.

## Pha 3: User Story 1 — Xem nội dung Tổng quan khi mở app (Ưu tiên: P1)

**Mục tiêu**: Tab Tổng quan hiển thị tổng số dư, thẻ thu/chi tháng này, 5 giao dịch gần nhất; chạm mở chi tiết hoặc "Xem tất cả"; tự làm mới khi quay lại tab (FR-001 → FR-007).
**Tiêu chí kiểm thử độc lập**: Mở app → thấy đủ 3 khối nội dung không cần thao tác thêm; chạm 1 giao dịch → mở đúng chi tiết; chạm "Xem tất cả" → sang tab Giao dịch; thêm/sửa/xoá giao dịch rồi quay lại Tổng quan → số liệu mới.

- [X] T005 [US1] Sửa `lib/screens/dashboard_screen.dart`: `_DashboardScreenState` tự gọi `ensureTransactionController().load()` trong `initState` (song song với `_refresh()` chuông thông báo đã có; import `ensureTransactionController` từ `data/transaction_deps.dart`).
- [X] T006 [US1] Sửa `lib/screens/dashboard_screen.dart`: bọc `Expanded` hiện tại (đang là `SizedBox()` rỗng, dòng 76) bằng `Obx` đọc `ensureTransactionController().data.value` — `null` (đang nạp/lỗi/chưa nạp) giữ `SizedBox.expand()` như màn Giao dịch đang xử lý, có dữ liệu thì dựng nội dung ở các task sau.
- [X] T007 [US1] Trong `lib/screens/dashboard_screen.dart`, truyền `ScreenHeader.bottom` = widget hiển thị tổng số dư (`formatMoney(view.walletTotal)`, chữ trắng lớn, theo bố cục `docs/dashboard/man-hinh-tong-quan.svg`) — đặt trong vùng teal, không phải trong `Expanded`.
- [X] T008 [US1] Trong nội dung `Expanded` (từ T006), thêm `MonthStatRow(stat: view.stat)` ngay đầu (dùng lại widget từ T003) hiển thị 2 thẻ "Thu tháng này"/"Chi tháng này" (FR-002).
- [X] T009 [US1] Trong `lib/screens/dashboard_screen.dart`, tính "5 giao dịch gần nhất" bằng `view.groups.expand((g) => g.rows).take(5).toList()` (không nhóm ngày, theo data-model + Quyết định 4/research.md); render bằng `TxnRowTile` (từ T002) cho từng dòng, có tiêu đề khu vực "Giao dịch gần đây" + nút văn bản "Xem tất cả" gọi `widget.onSelectTab?.call(1)` (FR-003/FR-004/FR-005).
- [X] T010 [US1] Trong `lib/screens/dashboard_screen.dart`, khi danh sách 5 dòng gần đây rỗng (chưa từng có giao dịch, FR-006), hiển thị trạng thái rỗng thay cho danh sách (icon + text theo phong cách `_EmptyState` đã có ở `transaction_screen.dart`, không copy y nguyên vì Dashboard không cần nút hướng dẫn FAB riêng — chỉ cần thông báo "Chưa có giao dịch nào").
- [X] T011 [US1] Sửa `lib/core/app_shell.dart`, hàm `_onTabSelected`: thêm nhánh `if (index == 0) { ensureTransactionController().load(); }` (đặt cạnh nhánh `index == 1`/`index == 2` đã có, dòng 79–86) để làm mới Dashboard mỗi lần quay lại tab (FR-007).
- [X] T012 [US1] Tạo `test/dashboard_screen_test.dart`: dựng `TransactionController` + `FakeWalletRepository` (theo mẫu `_pumpScreen` ở `test/transaction_screen_test.dart`) rồi pump `DashboardScreen`, kiểm: (a) số dư = tổng ví seed đang hoạt động hiển thị đúng định dạng; (b) 2 thẻ "Thu tháng này"/"Chi tháng này" đúng số; (c) đúng 5 dòng gần nhất, đúng thứ tự mới nhất trước; (d) chạm 1 dòng → `Navigator` push `TransactionDetailScreen`; (e) chạm "Xem tất cả" → gọi `onSelectTab(1)`; (f) không có giao dịch nào → hiện trạng thái rỗng, số dư vẫn = tổng `initial_balance`, 2 thẻ hiện `0 đ`; (g) tất cả ví ẩn → số dư hiển thị `0 đ`; (h) có dòng chuyển khoản trong 5 dòng gần đây → màu trung tính, không dấu `+`/`-`.
- [X] T013 [US1] Chạy `flutter analyze` và `flutter test` toàn bộ tại `app/sora_thu_chi/`; xác nhận không có test đỏ mới phát sinh ngoài baseline đã biết.

## Pha cuối: Polish & Cross-cutting

- [X] T014 [P] Rà lại `docs/dashboard/man-hinh-tong-quan.svg` so với `DashboardScreen` đã dựng — đối chiếu khoảng cách/màu/kích thước card đúng `docs/design-system-app-thu-chi.md` (card `10px`, số tiền căn phải phân cách nghìn `đ`).
- [X] T015 QA tay theo `quickstart.md` (8 kịch bản) trên emulator/thiết bị thật.

## Sơ đồ phụ thuộc

- Pha 2 (T001–T004) chặn toàn bộ Pha 3 — Dashboard cần `walletTotal` (T001) và `TxnRowTile`/`MonthStatRow` (T002/T003) đã tách + `transaction_screen.dart` đã chuyển sang dùng chúng (T004) để tránh 2 nguồn xử lý dòng giao dịch song song.
- Trong Pha 2: T002 và T003 độc lập nhau (khác file) → chạy song song; cả hai phải xong trước T004.
- Trong Pha 3: T005 → T006 → T007/T008/T009/T010 (đều sửa cùng file `dashboard_screen.dart`, làm tuần tự tránh xung đột) → T011 (khác file, có thể làm song song với T007–T010) → T012 (cần toàn bộ UI đã dựng xong) → T013.
- Pha cuối chạy sau khi Pha 3 xong.

## Ví dụ chạy song song

- Pha 2: T002 (`txn_row_tile.dart`) và T003 (`month_stat_row.dart`) — 2 dev/2 phiên làm cùng lúc, không đụng file nhau.
- Pha 3: T011 (`app_shell.dart`) có thể làm song song với T007–T010 (`dashboard_screen.dart`) vì khác file, miễn T005/T006 đã xong.

## Chiến lược triển khai

- MVP đề xuất: toàn bộ User Story 1 (PBI này chỉ có 1 story — không chia P1/P2/P3 vì spec.md mô tả một luồng nghiệp vụ liền mạch, không có tính năng phụ tách rời được).
- Thứ tự giao hàng: Pha 2 (nền tảng dùng chung với màn Giao dịch) → Pha 3 (nội dung Dashboard) → Pha cuối (đối chiếu design + QA tay).
