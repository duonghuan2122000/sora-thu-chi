# Kế hoạch triển khai: Nội dung màn Tổng quan

**Mã PBI**: 33
**Liên kết spec**: `.specify/specs/33/spec.md`
**Ngày tạo**: 2026-09-13

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart / Flutter (mobile Android/iOS), theo `app/sora_thu_chi/` hiện có |
| Framework / Thư viện chính | GetX (state) — dùng lại `TransactionController` sẵn có; không thêm dependency mới |
| Lưu trữ dữ liệu | `drift` (SQLite) qua `WalletRepository`/`DriftWalletRepository` — **không đổi schema**, giữ v10 |
| Kiểm thử | `flutter_test` — widget test cho `DashboardScreen`, unit test cho `TransactionView.walletTotal`/`TransactionController` |
| Nền tảng triển khai | Android/iOS, offline hoàn toàn — không có thay đổi liên quan mạng/server |
| Ràng buộc hiệu năng | Không đọc DB thêm lần nào ngoài lần `TransactionController.load()` đã có (research quyết định 1/2) |
| Ràng buộc khác | Giữ đúng design system (`docs/design-system-app-thu-chi.md`): thẻ `10px`, teal/coral đúng ngữ nghĩa thu/chi, số tiền phân cách nghìn + đơn vị `đ` |

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md` trong dự án — không có nguyên tắc bắt buộc riêng để đối chiếu. Áp dụng nguyên tắc chung trong `CLAUDE.md` (tái sử dụng thay vì trùng lặp, không lệch design system, không thêm dependency khi không cần) — kế hoạch dưới đây tuân thủ đầy đủ, không có ngoại lệ cần biện minh.

## Giai đoạn 0 — Kết quả nghiên cứu

Xem `research.md`. Tóm tắt các quyết định chính:

- **Quyết định**: Dùng lại `TransactionController` làm nguồn dữ liệu duy nhất cho Dashboard. **Lý do**: đã tính sẵn `MonthStat` + `List<DayGroup>` gộp transfer, tránh đọc DB 2 lần. **Phương án khác**: controller riêng — bỏ (trùng lặp).
- **Quyết định**: Thêm `walletTotal` vào `TransactionView`, tính trong `load()` từ danh sách ví đã đọc sẵn. **Lý do**: không tốn lệnh đọc DB mới. **Phương án khác**: Dashboard tự đọc `WalletRepository.loadAll()` riêng — bỏ.
- **Quyết định**: Tách `TxnRowTile`/`MonthStatRow` dùng chung giữa màn Giao dịch và Dashboard. **Lý do**: đúng 1:1 thiết kế & hành vi, tránh chép ~150 dòng. **Phương án khác**: widget riêng cho Dashboard — bỏ.
- **Quyết định**: Danh sách gần đây = làm phẳng `groups` rồi lấy 5 dòng đầu, không nhóm ngày. **Lý do**: đúng thứ tự sẵn có, đúng thiết kế tham chiếu. **Phương án khác**: hàm tính riêng — bỏ.
- **Quyết định**: Làm mới khi quay lại tab Tổng quan qua `AppShell._onTabSelected` (`index == 0`) + tự load ở `initState` (vì là tab mặc định lúc boot). **Lý do**: bám đúng mẫu tab Giao dịch/Báo cáo đã có. **Phương án khác**: stream lắng nghe DB — bỏ (over-engineering).
- **Quyết định**: Không làm Privacy mode (icon con mắt) — đã chốt Ngoài phạm vi ở spec.md.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — chỉ thêm 1 trường `walletTotal: int` vào `TransactionView`, không có bảng/entity mới.
- **Hợp đồng giao diện**: không áp dụng — app hoàn toàn offline, không có API/CLI công khai (bỏ `contracts/`).
- **Kịch bản khởi động nhanh**: xem `quickstart.md`.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Không thêm dependency khi không cần | ✅ | 0 package mới |
| Không đổi schema khi không cần | ✅ | Giữ nguyên drift schema v10 |
| Tái sử dụng thay vì trùng lặp | ✅ | Dùng lại `TransactionController` + tách widget dùng chung thay vì viết lại |
| Đúng design system | ✅ | Header/card/row bám đúng `docs/design-system-app-thu-chi.md` + `docs/dashboard/man-hinh-tong-quan.svg` |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/lib/
├── core/
│   ├── transaction/
│   │   ├── transaction_list.dart        # SỬA: TransactionView + trường walletTotal
│   │   └── transaction_controller.dart  # SỬA: load() tính walletTotal = activeTotal(wallets)
│   └── widgets/
│       ├── txn_row_tile.dart            # MỚI: tách từ transaction_screen.dart (_TransactionRow/_RowBubble)
│       └── month_stat_row.dart          # MỚI: tách từ transaction_screen.dart (_MonthStatCard/_StatBlock)
├── screens/
│   ├── transaction_screen.dart          # SỬA: dùng TxnRowTile/MonthStatRow thay widget private cũ
│   └── dashboard_screen.dart            # SỬA: thêm số dư (ScreenHeader.bottom) + MonthStatRow +
│                                         #      khu "Giao dịch gần đây" (5 dòng qua TxnRowTile) + rỗng
└── core/app_shell.dart                  # SỬA: _onTabSelected thêm nhánh index == 0 → load lại

app/sora_thu_chi/test/
├── core/transaction/
│   └── transaction_list_test.dart       # SỬA: cập nhật constructor TransactionView (walletTotal)
├── screens/
│   └── dashboard_screen_test.dart       # MỚI: số dư/thẻ thu-chi/5 dòng gần đây/tap mở chi tiết/
│                                         #      tap Xem tất cả gọi onSelectTab(1)/trạng thái rỗng
└── core/widgets/
    └── txn_row_tile_test.dart           # MỚI (tuỳ chọn) — nếu transaction_screen_test.dart hiện có
                                          #      chưa phủ đủ hành vi widget sau khi tách
```

## Rủi ro & ngoại lệ có lý do

- **Rủi ro**: Thêm trường `walletTotal` vào `TransactionView` có thể phá test hiện có đang dựng `TransactionView(groups:, stat:)` không truyền trường mới. → Giảm rủi ro: đặt `walletTotal` có giá trị mặc định `0`, rà lại toàn bộ chỗ dựng `TransactionView` trong test khi thi công (task riêng).
- **Rủi ro**: Tách `TxnRowTile`/`MonthStatRow` khỏi `transaction_screen.dart` có thể lệch hành vi nếu sót tham số/callback (đặc biệt logic mở chi tiết theo `detailGroupId`/`detailTransactionId`). → Giảm rủi ro: chạy lại `transaction_screen_test.dart` hiện có sau khi tách, đảm bảo xanh trước khi thêm test Dashboard mới.
- Không có ngoại lệ vi phạm nguyên tắc dự án cần biện minh.
