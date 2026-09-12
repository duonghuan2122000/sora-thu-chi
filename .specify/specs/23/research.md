# Nghiên cứu kỹ thuật: Chi tiết theo danh mục (màn 02 Báo cáo)

**Mã PBI**: 23
**Liên kết spec**: [spec.md](./spec.md)
**Ngày tạo**: 2026-09-12
**Đầu vào bổ sung**: không có (spec đã "Đã làm rõ", 2 quyết định chốt 2026-09-12)

Không còn mục `NEEDS CLARIFICATION`. Các quyết định dưới đây là **chi tiết triển khai** trong khuôn khổ đã chốt ở spec (FR-001…FR-020) và các PBI trước (PBI 12 bộ lọc, PBI 18 theme, PBI 19 i18n, PBI 22 màn `01`).

---

## R1 — Nguồn dữ liệu của màn Chi tiết

- **Quyết định**: màn 02 **không đọc DB**. Nó dùng lại **bản chụp RAM** của `ReportController` (giao dịch + danh mục đã nạp khi mở tab Báo cáo) qua một method mới `ReportController.categoryDetail()` gọi trong `Obx` lúc build.
- **Lý do**:
  - Màn 02 **chỉ mở được** từ liên kết "Xem tất cả" trên màn `01`, mà màn `01` chỉ vẽ nội dung khi `data != null` ⇒ bản chụp RAM luôn sẵn có ⇒ **không** cần trạng thái `loading`/`error`/nút "Thử lại" thứ hai.
  - Số liệu màn 02 và màn 01 lấy từ **cùng một bản chụp** ⇒ không thể lệch nhau (điểm dễ sai nhất của PBI này là lệch số giữa hai màn).
  - FR-015/SC-009 vẫn đạt: bản chụp được `AppShell` làm mới **mỗi lần chọn tab Báo cáo** và **sau khi lưu giao dịch qua FAB** (R1/R11 của PBI 22); màn 02 dựng lại số liệu mỗi lần build ⇒ mở lại là thấy số mới.
- **Phương án khác đã xem xét**:
  - `StatefulWidget` đọc DB trong `initState` (khuôn màn Chi tiết Ngân sách — PBI 21): thêm ~40 dòng (loading, error, seam `WalletRepository?`), và dữ liệu đọc ở **thời điểm khác** với màn 01 ⇒ có thể lệch số giữa hai màn (đúng thứ spec cấm ở SC-006).
  - Truyền `List<Transaction>` + `List<Category>` xuống constructor màn 02: nạp sẵn nhưng bơm dữ liệu thô qua ranh giới màn, test phải tự dựng dữ liệu thay vì dùng controller như màn 01.

## R2 — Danh sách đầy đủ + bảng màu lặp theo chu kỳ

- **Quyết định**: thêm hàm thuần `reportCategoryDetail({transactions, categories, period, now})` vào `lib/core/report/report_view.dart`, **tái dùng** hàm `_breakdown` đang có (cùng file, đang là private):
  - Lấy **toàn bộ** nhóm danh mục cha (bỏ `.take(5)` của `reportBreakdown`), giữ nguyên thứ tự giảm dần + đồng hạng theo tên (`normalizeSearch`).
  - Thêm dòng **"Khác"** (`categoryId == null`) **xếp cuối** khi có tiền chi không gắn danh mục (FR-010).
  - Chia % bằng `percentSplit` (phần dư lớn nhất) trên **toàn bộ** dòng ⇒ tổng = 100 (FR-008).
  - Màu: hạng `i` → `SoraColors.chartPalette[i % 5]`; "Khác" → `chartPalette[5]`. Màn 02 chỉ trả **chỉ số màu**, widget ánh xạ sang token theo theme.
- **Lý do**:
  - Doc §5 chốt bộ màu định tính gồm **5 màu** (teal, teal đậm nhạt, hổ phách, xanh lam nhạt, xám) — hết 5 màu thì lặp chu kỳ là hệ quả đã chấp nhận ở spec (chốt 2026-09-12).
  - Dùng **một** bảng màu duy nhất ⇒ 5 hạng đầu của màn 02 trùng màu lát cắt màn 01 (SC-007), không phải sửa `SoraColors` ⇒ không đụng test PBI 22.
- **Phương án khác đã xem xét**:
  - Lấy màu hồng `#C97B84` của mockup 02 cho hạng 5: mockup lệch doc §5 (doc ghi màu thứ 5 là **xám**) và lệch bảng màu đang chạy ở màn 01 ⇒ hai màn cùng danh mục sẽ khác màu. Bỏ qua, ghi nhận là khác biệt cố ý so với mockup (cùng loại với khác biệt chip kỳ đã chốt).
  - Khai báo bảng màu riêng cho màn 02: hai bảng màu song song, sửa một bên dễ quên bên kia.
  - Thêm màu hồng vào `chartPalette` dùng chung: đổi màu hạng 5 của màn 01 ⇒ vỡ test PBI 22, ngoài phạm vi PBI này.

## R3 — Nhãn chip kỳ (nhãn tĩnh)

- **Quyết định**: hàm thuần `reportPeriodChipLabel(period, range)` trong `report_view.dart`, ghép **danh từ kỳ đã có bản dịch** với chuỗi ngày **không phụ thuộc ngôn ngữ**:
  - Ngày → `Ngày 12/09/2026` (EN: `Day 12/09/2026`)
  - Tuần → `Tuần 07/09–13/09/2026` (bắt đầu Thứ Hai; năm lấy theo ngày cuối kỳ)
  - Tháng → `Tháng 9/2026`
  - Năm → `Năm 2026`
  Dùng lại các khóa đã có `'Ngày' / 'Tuần' / 'Tháng' / 'Năm'` (EN: `Day/Week/Month/Year`) ⇒ **không thêm khóa** cho chip. Chip là `Container` tĩnh, **không** `InkWell`, **không** mũi tên (FR-003, khác mockup 02).
- **Lý do**: FR-003 cần "loại kỳ + mốc kỳ"; ghép danh từ + số là cách ngắn nhất mà bản EN vẫn đủ nghĩa ("Week 07/09–13/09/2026"), và không sinh thêm khóa dịch nào phải bảo trì.
- **Phương án khác đã xem xét**:
  - 4 khóa mới dạng `'Ngày @ngày/@tháng/@năm'`: EN vẫn phải là `Day 12/09/2026` ⇒ kết quả y hệt, thêm 4 khóa.
  - Dùng lại `'Tháng @tháng, @năm'` / `'Tuần @từ – @đến'` / `'Năm @năm'` của PBI 20/21: bản EN của chúng chỉ còn số (`9/2026`, `07/09 – 13/09`) ⇒ mất "loại kỳ", trượt FR-003 khi ở English.

## R4 — Vòng tròn phân bổ

- **Quyết định**: dùng `fl_chart` `PieChart` (đã dùng thật ở màn 01 — PBI 22) với `centerSpaceRadius` ≈ 52, `radius` ≈ 30, `sectionsSpace: 2`, **không** nhãn trên lát; nhãn giữa vòng phủ bằng `Stack` gồm `'Tổng chi @đơn vị'` + `formatMoney(total)` (bọc `FittedBox(fit: scaleDown)`). Chạm một lát → cùng đường drill-down với chạm dòng (R5).
- **Lý do**: dependency đã cài; mockup 02 vẽ vòng tròn lớn ở giữa màn (bán kính ngoài ~83/360 đơn vị) nên kích thước khác màn 01.
- **Phương án khác đã xem xét**: tách vòng tròn thành widget dùng chung cho màn 01 + màn 02 — hai nơi khác nhau cả kích thước, nhãn giữa và ngữ nghĩa lát (top 5 + "Khác" vs đầy đủ + lặp màu) ⇒ abstraction đổi lấy ~30 dòng tiết kiệm nhưng phải sửa `report_screen.dart` + test PBI 22. Dựng cục bộ trong màn 02.

## R5 — Drill-down sang màn Giao dịch

- **Quyết định**: chạm một dòng/lát danh mục (`categoryId != null`):
  `TxnSearchFilter(now: controller.now, type: expense, datePreset: custom, dateStart: range.start, dateEnd: range.end − 1 ngày, categoryIds: {categoryId}, sort: dateNewest)` → `ensureTransactionController().setFilter(...)` → `Navigator.popUntil((r) => r.isFirst)` → `onSelectTab?.call(1)`.
- **Lý do**:
  - Bộ lọc PBI 12 (`_effectiveCategoryIds`) **tự mở rộng cha → con** ⇒ chọn 1 id cha là ra đúng tập giao dịch tạo nên số tiền của dòng (FR-011/SC-006), không cần tự tính tập id như `budgetScopeCategoryIds`.
  - Màn 02 là **route đè shell** (màn con có app bar + back, không bottom nav) ⇒ phải `popUntil` về shell rồi mới đổi tab, đúng nếp màn Chi tiết Ngân sách (PBI 21); khác màn 01 — màn 01 *là* tab nên chỉ cần `onSelectTab` (R7 PBI 22).
- **Phương án khác đã xem xét**: tự đẩy màn Giao dịch thứ hai lên trên màn 02 — chồng 2 màn con, nút back rối. Dòng **"Khác"**: không có đích (không danh mục nào tái lập đúng nhóm gộp) ⇒ không phản hồi khi chạm (FR-012), giống màn 01.

## R6 — Điểm vào "Xem tất cả" trên màn 01

- **Quyết định**: thêm liên kết `Xem tất cả` (khóa dịch **đã có**, PBI 21) ở **bên phải hàng tiêu đề** thẻ "Top danh mục chi tiêu", `ValueKey('report-see-all')`; **chỉ hiện khi thẻ có nội dung** (`view.hasExpense`). Chạm → `Navigator.push(MaterialPageRoute(builder: (_) => ReportCategoryDetailScreen(onSelectTab: onSelectTab)))`.
- **Lý do**: FR-001 + mockup 01 không vẽ liên kết nên PBI 22 để trống chỗ này (đã ghi trong spec màn 23). Không truyền dữ liệu kỳ xuống màn 02 vì màn 02 đọc `ReportController` (R1) — kỳ nằm ở controller singleton nên tự đúng.
- **Phương án khác đã xem xét**: truyền `period`/`now`/`range` xuống constructor màn 02 — hai nguồn sự thật cho cùng một kỳ, dễ lệch; đặt liên kết cả khi thẻ rỗng — dẫn tới màn 02 rỗng vô nghĩa.

## R7 — Trạng thái rỗng

- **Quyết định**: `ReportCategoryDetail` mang cờ `hasAnyTxn` (kỳ có ít nhất 1 giao dịch Thu/Chi — transfer không tính). `total <= 0` ⇒ màn hiện **trạng thái rỗng toàn màn** (không vẽ vòng tròn, không hiện tiêu đề nhóm):
  - `hasAnyTxn == true` (chỉ có Thu) → `Chưa có chi tiêu nào trong kỳ này` (khóa **đã có**).
  - `hasAnyTxn == false` (kỳ rỗng hoặc chỉ chuyển khoản) → `Chưa có giao dịch nào trong kỳ này` (khóa **đã có**).
- **Lý do**: FR-013/FR-014 tách đúng 2 thông điệp này; cờ tính từ **cùng** bản chụp dữ liệu ⇒ không thể hiện vòng tròn rỗng.
- **Phương án khác đã xem xét**: đọc `controller.data.value!.hasAnyTxn` (cờ có sẵn của `ReportView`) — màn 02 phải phụ thuộc **hai** nguồn (`data` + `categoryDetail`) cho một lần vẽ; gộp vào `ReportCategoryDetail` thì màn 02 chỉ có một.

## R8 — Nhãn cần dịch (FR-018)

- **Quyết định**: thêm vào `lib/core/locale/sora_translations.dart`, mục "Báo cáo (PBI 23)":
  - `'Chi tiêu theo danh mục'` → `Spending by category` (tiêu đề app bar; trùng bản EN của khóa PBI 22 nhưng khác chuỗi VI ⇒ khóa riêng)
  - `'DANH MỤC (@n)'` → `CATEGORIES (@n)` (tiêu đề nhóm, theo nếp `'DANH MỤC CON: @tên'` đã có)
  - `'Tổng chi ngày'` → `Day total`, `'Tổng chi tuần'` → `Week total`, `'Tổng chi tháng'` → `Month total`, `'Tổng chi năm'` → `Year total` (nhãn giữa vòng tròn)
  - `'Chạm vào một danh mục để xem các giao dịch'` → `Tap a category to see its transactions`
  - Tổng **7 khóa mới**.
- **Dùng lại**: `'Xem tất cả'`, `'Khác'`, `'Tổng chi'`, `'Ngày' / 'Tuần' / 'Tháng' / 'Năm'`, `'Chưa có giao dịch nào trong kỳ này'`, `'Chưa có chi tiêu nào trong kỳ này'`.
- **Lý do**: `test/sora_translations_test.dart` **tự quét** mọi literal `.tr` trong `lib/` ⇒ thiếu khóa là đỏ; dùng lại khóa cũ giữ số khóa mới ở mức nhỏ nhất.
- **Phương án khác đã xem xét**: dùng `'Tổng chi'` + tên đơn vị ở dạng chữ thường (`'tháng'`) — EN ra "Total expense month", sai trật tự từ.

## R9 — Test

- **Quyết định**:
  | File | Việc |
  |---|---|
  | `test/report_view_test.dart` (sửa) | `reportCategoryDetail`: đủ **mọi** danh mục (7 danh mục → 7 dòng, **không** cắt 5); `Σ tiền = total`, `Σ % = 100`; "Khác" **cuối danh sách** và **chỉ** khi có tiền chi không gắn danh mục; gộp con → cha; danh mục ẩn vẫn tính; danh mục con mồ côi nhóm theo chính nó; đồng hạng xếp theo tên; chỉ Thu / chỉ transfer → `total == 0` + `hasAnyTxn` đúng; 1 danh mục → 1 dòng 100%. Thêm `reportPeriodChipLabel` (4 kỳ + tuần vắt qua tháng/năm) và `reportExpenseCenterLabel` |
  | `test/report_category_detail_screen_test.dart` (mới) | Vẽ: tiêu đề, chip kỳ đúng chuỗi, `DANH MỤC (n)`, đủ n dòng, dòng gợi ý, nhãn giữa vòng tròn; chạm dòng → `TransactionController.activeFilter` đúng (Chi + `dateStart`/`dateEnd` kỳ + `categoryIds = {cha}`) **và** `onSelectTab(1)` được gọi; chạm **"Khác"** → không đổi bộ lọc, không gọi `onSelectTab`; 2 trạng thái rỗng; English → không còn nhãn tiếng Việt |
  | `test/report_screen_test.dart` (sửa) | "Xem tất cả" có mặt trên thẻ Top khi có chi tiêu, **không** có khi thẻ rỗng; chạm → `find.byType(ReportCategoryDetailScreen)` |
  | `test/dark_theme_smoke_test.dart` (sửa) | Thêm ca smoke màn 02 ở theme tối (có dữ liệu) → không overflow (FR-019) |
- **Lý do**: module thuần + widget test là hai tầng test đang có của repo; màu/tương phản là kiểm bằng mắt (quickstart nhóm I) nên không đưa vào test tự động.
- **Phương án khác đã xem xét**: test màu tự động bằng cách đọc `LinearProgressIndicator.valueColor` — khả thi nhưng chỉ khẳng định lại hằng số token; QC bằng mắt ở 2 theme vẫn cần.

## R10 — Ràng buộc kỹ thuật kế thừa (không đổi gì)

- **Quyết định**: **không** đổi schema drift (giữ **v7**), **không** migration, **không** `build_runner`, **không** thêm dependency, **không** thêm method `WalletRepository`, **không** tạo `contracts/`.
- **Lý do**: mọi số liệu là **đại lượng tính toán** từ dữ liệu đã có; màn 02 chỉ đọc bản chụp RAM (R1). SC-008 (< 1 giây) không đổi so với PBI 22 vì không thêm phép đọc DB nào.
- **Phương án khác đã xem xét**: thêm index/bảng tổng hợp theo danh mục — tối ưu sớm, đụng mọi đường ghi giao dịch (đã bác ở PBI 22, giữ nguyên).
