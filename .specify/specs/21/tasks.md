# Danh sách Task: Chi tiết Ngân sách (tiến độ, tốc độ chi tiêu, so sánh nhiều kỳ)

**Mã PBI**: 21
**Nguồn**: plan.md, spec.md, data-model.md, research.md, quickstart.md
**Ngày tạo**: 2026-09-12

## Định dạng task

`- [ ] [MãTask] [P?] [Story?] Mô tả kèm đường dẫn file`

- `[P]`: có thể chạy song song (khác file, không phụ thuộc task chưa xong)
- `[Story]`: bắt buộc ở pha User Story (VD `[US1]`), không dùng ở Setup/Foundational/Polish
- Mọi đường dẫn tính từ `app/sora_thu_chi/`

## Pha 1: Setup

- [X] T001 [P] Lấy mốc xanh trước khi sửa: chạy `flutter pub get` rồi `flutter test` tại `app/sora_thu_chi/` (kỳ vọng 533 test xanh, ghi nhận số test đỏ có sẵn nếu có); xác nhận `pubspec.yaml` **không đổi** và `fl_chart ^1.2.0` đã có sẵn (research R9, R13)

## Pha 2: Foundational

*(Bắt buộc xong trước khi làm bất kỳ user story nào)*

- [X] T002 [P] Sửa `lib/core/budget/budget_view.dart`: thêm `List<Transaction> budgetPeriodTransactions({required Set<int> categoryIds, required List<Transaction> transactions, required DateRange range})` (chỉ `type == expense`, `categoryId ∈ categoryIds`, `date ∈ [start, end)`, sắp **mới nhất trước**) và cho `budgetSpent` **gọi lại** hàm này rồi cộng `-amount` (refactor thuần, không đổi hành vi) — research R11, FR-011, SC-005
- [X] T003 [P] Tạo `lib/core/budget/budget_detail.dart` (phần nền): `budgetDaysLeft(DateRange, DateTime now)` + `budgetElapsedPercent(DateRange, DateTime now)` (`totalDays = end − start`; `elapsedDays = clamp(today − start + 1, 0, totalDays)`; `daysLeft = totalDays − elapsedDays`, sàn 0) + `budgetPaceWarning({usedPercent, elapsedPercent, ended})` → `!ended && usedPercent > elapsedPercent` + `class BudgetDetail { budget, category, range, spent, percent, level, overAmount, remainingAmount, ended, daysLeft, elapsedPercent, showPaceWarning, transactions }` + `buildBudgetDetail({budget, categories, transactions, now, viewedRange})` — research R6, R7, FR-003…FR-006
- [X] T004 [P] Thêm `String formatTimeLabel(DateTime)` → `'HH:mm'` vào `lib/core/date_label.dart` (dùng lại hàm `_two` đang private) — research R12, FR-012
- [X] T005 [P] Thêm tham số tuỳ chọn `String? subtitle` vào `lib/core/widgets/sub_page_scaffold.dart`: khi có thì app bar dựng `Column` (tiêu đề + dòng phụ 11px trắng 80%) và `toolbarHeight` = 68; khi `null` giữ nguyên hành vi 8 màn đang dùng — research R2, FR-002
- [X] T006 [P] Bổ sung `test/budget_view_test.dart`: `budgetPeriodTransactions` chỉ lấy Chi, gồm danh mục con, đúng khoảng `[start, end)`, sắp mới nhất trước; `budgetSpent` khớp **tổng** danh sách đó; Thu và transfer không lọt vào (phụ thuộc T002)
- [X] T007 [P] Tạo `test/budget_detail_test.dart`: `budgetDaysLeft`/`budgetElapsedPercent` mốc 12/09 trong tháng 9 → **18 ngày còn lại / 40%**; ngày cuối kỳ → `0` (không âm); kỳ đã qua → `0`; `budgetPaceWarning` 107% vs 40% → `true`, 40% vs 90% → `false`, `ended` → `false` (phụ thuộc T003)

## Pha 3: User Story 1 - Màn Chi tiết Ngân sách ở kỳ hiện tại (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: Từ màn Tổng quan Ngân sách, chạm một dòng ngân sách mở màn Chi tiết đúng mockup `03` — app bar 2 dòng, thẻ tiến độ (đã dùng / vượt–còn lại / ngày còn lại / huy hiệu trạng thái theo 3 dải màu), băng cảnh báo tốc độ chi tiêu, danh sách giao dịch Chi trong kỳ rút gọn 5 dòng kèm "Xem tất cả" mở màn Giao dịch đã lọc sẵn.
**Tiêu chí kiểm thử độc lập**: Seed `FakeWalletRepository` sẵn 1 ngân sách (giới hạn nhỏ hơn tổng Chi trong kỳ) + giao dịch Chi/Thu/transfer (có cả giao dịch ở danh mục con) → mở màn bằng 1 lần chạm → "đã dùng" và "vượt" khớp tổng Chi (Thu/transfer không ảnh hưởng), huy hiệu "Vượt …%" + băng cảnh báo hiện, danh sách đúng 5 dòng mới nhất và tổng khớp thẻ tiến độ; chạm "Xem tất cả" → `TransactionController.activeFilter` đúng Chi + khoảng kỳ + phạm vi danh mục.

- [X] T008 [US1] Tạo `lib/screens/budget_detail_screen.dart` — khung màn: `StatefulWidget{ required int budgetId; WalletRepository? repository; DateTime? now; ValueChanged<int>? onSelectTab; }`, nạp trong `initState` (`budgets()` → tìm theo `budgetId`; `allTransactions()`; `categoriesIncludingHidden(expense)`), `_now` bơm được để test deterministic; thân `SubPageScaffold(title: tên danh mục, subtitle: 'Ngân sách @chu kỳ • @kỳ', child: ListView)` — **không** bottom nav, **chưa** có nút góc phải và 2 nút cuối (FR-001, FR-002)
- [X] T009 [US1] Dựng 4 nhánh thân màn trong `lib/screens/budget_detail_screen.dart`: **đang nạp** (spinner) → **lỗi** ("Không đọc được ngân sách." + nút "Thử lại") → **không hợp lệ** khi `detail.category == null` (thông báo + nhắc gán lại danh mục, **ẩn** thẻ tiến độ/biểu đồ/danh sách) → **nội dung** (FR-019, FR-022: cuộn tới được phần tử cuối)
- [X] T010 [US1] Dựng thẻ tiến độ trong `lib/screens/budget_detail_screen.dart`: nhãn "Đã dùng" + số tiền cỡ lớn màu theo **3 dải** (`<80%` teal, `80–99%` coral, `≥100%` coral) + dòng phụ "trên {giới hạn} giới hạn"; bên phải nhãn "Trạng thái" + widget riêng tư `_StatusBadge` (nền coral nhạt từ 80% trở lên; chữ "Bình thường @p%" / "Sắp đạt @p%" / "Vượt @p%"); thanh tiến độ bo `3px` tái dùng đúng dải màu của màn `01`; dòng cuối: trái "Vượt {số} đ" (khi ≥ 100%) hoặc "Còn lại {số} đ", phải "@n ngày còn lại" hoặc **"Đã kết thúc"** khi `ended` (FR-003, FR-004, FR-005, FR-006, research R8)
- [X] T011 [US1] Dựng băng cảnh báo tốc độ trong `lib/screens/budget_detail_screen.dart`: chỉ hiện khi `detail.showPaceWarning` — nền coral nhạt, biểu tượng cảnh báo tròn coral, tiêu đề "Tốc độ chi tiêu nhanh hơn dự kiến" + dòng phụ "Đã dùng @p% ngày nhưng chi @q% ngân sách" (FR-007, SC-004)
- [X] T012 [US1] Dựng nhóm "GIAO DỊCH TRONG KỲ" trong `lib/screens/budget_detail_screen.dart`: tiêu đề nhóm + liên kết "Xem tất cả" bên phải (`ValueKey('budget-detail-see-all')`), danh sách tối đa **5** dòng đầu của `detail.transactions` — mỗi dòng: bubble icon danh mục (màu danh mục, bám nếp `_BudgetRowTile`), tiêu đề `note` (rỗng → tên danh mục), dòng phụ `'${relativeDayLabel(date, now: _now)}, ${formatTimeLabel(date)}'`, số tiền Chi màu coral; kỳ không có giao dịch → **trạng thái rỗng** dễ hiểu (FR-011, FR-012, FR-013, research R12)
- [X] T013 [US1] Nối "Xem tất cả" trong `lib/screens/budget_detail_screen.dart`: dựng `TxnSearchFilter(now: _now, type: TxnTypeFilter.expense, datePreset: DatePreset.custom, dateStart: range.start, dateEnd: ngày cuối kỳ (= cuối `range.end` nửa mở), categoryIds: phạm vi danh mục ngân sách, sort: SortOption.dateNewest)` → `ensureTransactionController().setFilter(f)` → `Navigator.popUntil(isFirst)` → `onSelectTab?.call(1)`; test phủ cả nhánh `onSelectTab == null` (FR-014, SC-005, research R10, Rủi ro 8)
- [X] T014 [US1] Nối điểm vào: sửa `lib/screens/budget_overview_screen.dart` — chạm dòng ngân sách → `Navigator.push(BudgetDetailScreen(budgetId: …, repository: …, now: …, onSelectTab: widget.onSelectTab))`, quay về thì `_reloadSilent()` (sửa hoặc lưu trữ đều có thể đã đổi dữ liệu); đồng thời sửa **đúng 1 khẳng định** trong `test/budget_overview_screen_test.dart` từ "chạm dòng → Sửa ngân sách" thành "chạm dòng → mở Chi tiết Ngân sách" (FR-001, SC-001, research R1, Rủi ro 5)
- [X] T015 [P] [US1] Thêm khóa dịch EN cho phần đã dựng vào `lib/core/locale/sora_translations.dart` dưới mục "Ngân sách (PBI 21)": dòng phụ app bar `'Ngân sách @chu kỳ • @kỳ'`, `'Đã dùng'`, `'Trạng thái'`, `'trên @số đ giới hạn'`, 3 dạng huy hiệu, `'Vượt @số đ'`/`'Còn lại @số đ'`, `'@n ngày còn lại'`, `'Đã kết thúc'`, nội dung băng cảnh báo (tiêu đề + dòng phụ), `'GIAO DỊCH TRONG KỲ'`, `'Xem tất cả'`, trạng thái rỗng + dòng phụ, `'Không đọc được ngân sách.'`/`'Thử lại'`, trạng thái không hợp lệ; chuỗi động dùng `trParams`, **không** nối chuỗi tay (FR-021)
- [X] T016 [US1] Viết `test/budget_detail_screen_test.dart` (phần US1): render đủ thành phần mockup (app bar 2 dòng, "Đã dùng", "trên … giới hạn", "Trạng thái", huy hiệu, "Vượt … đ", "… ngày còn lại", "GIAO DỊCH TRONG KỲ", "Xem tất cả"); chưa vượt → huy hiệu **không** chứa chữ "Vượt" + hiện "Còn lại …"; vượt → "Vượt 107%" + "Vượt … đ"; băng cảnh báo **hiện/ẩn** theo `% đã dùng > % ngày`; danh sách chỉ **5** dòng nhưng tổng `detail.transactions` vẫn khớp `spent`; kỳ rỗng → trạng thái rỗng; "Xem tất cả" → `TransactionController.activeFilter` đúng (Chi + khoảng kỳ + phạm vi danh mục gồm con) + `onSelectTab(1)` được gọi + đã `pop`; danh mục đã xóa → trạng thái không hợp lệ; khôi phục `Get.locale` trong `addTearDown`, dọn `Get.reset()` sau test controller

## Pha 4: User Story 2 - Khối so sánh Dự kiến • Thực tế 3 kỳ (Ưu tiên: P2)

**Mục tiêu**: Màn Chi tiết có khối "SO SÁNH DỰ KIẾN • THỰC TẾ" — chú giải, đường mốc giới hạn nét đứt, biểu đồ cột đôi cho 3 kỳ gần nhất tính đến kỳ đang xem (kỳ đang xem là cột cuối), cột Thực tế teal/coral theo kết quả từng kỳ.
**Tiêu chí kiểm thử độc lập**: Seed ngân sách Tháng có dữ liệu 3 tháng → thấy 3 cặp cột đúng thứ tự với nhãn kỳ, kỳ đang xem đậm hơn; ngân sách mới có 1 kỳ → 1 cặp cột, không lỗi; cột Thực tế của kỳ vượt = coral, kỳ chưa vượt = teal, cột Dự kiến cùng màu trung tính; sửa giới hạn → mốc + cột Dự kiến đổi, cột Thực tế các kỳ trước không đổi.

- [X] T017 [P] [US2] Bổ sung `lib/core/budget/budget_detail.dart`: `class BudgetPeriodSummary { range, spent, limit, percent, level, ended }` + `budgetComparisonSeries({budget, transactions, categories, now, viewedRange, maxPeriods = 3})` (đi lùi từ kỳ đang xem theo đúng bước chu kỳ, **dừng trước** kỳ chứa `startDate`, trả về theo thứ tự tăng dần để kỳ đang xem là **phần tử cuối**; `limit` = `budget.amount` hiện tại cho mọi kỳ) + thêm field `comparison` vào `class BudgetDetail` và `buildBudgetDetail` (FR-008, FR-010, data-model luật 6–7)
- [X] T018 [US2] Dựng widget riêng tư `_ComparisonChart` trong `lib/screens/budget_detail_screen.dart` dùng `fl_chart` `BarChart`: `BarChartGroupData` 2 `BarChartRodData` mỗi kỳ (Dự kiến = màu trung tính lấy từ token `SoraColors`/`AppColors`, Thực tế = teal khi `level != over`, coral khi `over`), `maxY = max(limit, max spent) × 1.15`, `ExtraLinesData.horizontalLines` + `dashArray` cho **đường mốc giới hạn** kèm nhãn "Dự kiến {giới hạn}", `FlTitlesData` nhãn kỳ dưới trục (kỳ đang xem đậm hơn), `FlGridData(show: false)`/`FlBorderData(show: false)`; **không** hex cứng ngoài token; nếu API 1.2.0 vỡ không đáng sửa → phương án lùi: cột `Container` theo tỉ lệ + `CustomPaint` cho nét đứt (FR-009, research R9, Rủi ro 1)
- [X] T019 [US2] Chèn khối "SO SÁNH DỰ KIẾN • THỰC TẾ" vào thân `lib/screens/budget_detail_screen.dart` (giữa băng cảnh báo và nhóm giao dịch): tiêu đề khối, chú giải 2 ô màu (Dự kiến / Thực tế), `_ComparisonChart`; đồng thời thêm khóa dịch EN cho khối này vào `lib/core/locale/sora_translations.dart` (tiêu đề khối, `'Dự kiến'`/`'Thực tế'`, `'Dự kiến @số đ'`, nhãn trục `'T@tháng'` / `'@ngày/@tháng'` cho chu kỳ Tuần, `'@năm'` cho chu kỳ Năm) (FR-008, FR-021)
- [X] T020 [US2] Bổ sung test: `test/budget_detail_test.dart` — `budgetComparisonSeries` 3 kỳ đúng thứ tự (kỳ đang xem cuối), dừng trước kỳ `startDate`, kỳ đang xem ở quá khứ → 3 kỳ tính đến nó, ngân sách mới có 1–2 kỳ → 1–2 phần tử; `test/budget_detail_screen_test.dart` — thấy chú giải, đường mốc, 3 cặp cột + nhãn kỳ, nhãn kỳ đang xem đậm hơn, ngân sách kỳ đầu tiên → 1 cặp cột không lỗi (FR-009, FR-010, SC-006)

## Pha 5: User Story 3 - Đổi kỳ đang xem, xem lại các kỳ đã qua (Ưu tiên: P3)

**Mục tiêu**: Nút ở góc phải app bar mở bộ chọn kỳ của chính ngân sách đó (từ kỳ bắt đầu áp dụng đến kỳ hiện tại, đúng chu kỳ); chọn một kỳ → toàn bộ màn tính lại theo kỳ đó, kỳ đã kết thúc hiển thị "Đã kết thúc" và không có băng cảnh báo tốc độ.
**Tiêu chí kiểm thử độc lập**: Mở bộ chọn kỳ → danh sách đúng chu kỳ, không có kỳ nào trước `startDate`, ngân sách không lặp lại chỉ có 1 lựa chọn; chọn kỳ đã qua → số liệu/ngày còn lại/huy hiệu/danh sách/biểu đồ tính lại theo kỳ đó, hiện "Đã kết thúc", băng cảnh báo ẩn; ngân sách không lặp lại đã hết kỳ → mặc định mở đúng kỳ đã kết thúc.

- [X] T021 [P] [US3] Bổ sung `lib/core/budget/budget_detail.dart`: `budgetPeriodOptions(Budget, DateTime now)` → `List<DateRange>` (sinh theo bước chu kỳ từ kỳ chứa `startDate` đến kỳ chứa `now`; nếu `!isRecurring` thì cận trên = kỳ chứa `startDate` ⇒ đúng 1 lựa chọn) + field `periodOptions` trong `BudgetDetail`/`buildBudgetDetail` + hàm xác định **kỳ mặc định** (kỳ chứa `now`; `!isRecurring` → kỳ chứa `startDate`) (FR-020, FR-023, kịch bản 3 & 17, research R5)
- [X] T022 [US3] Thêm nút đổi kỳ vào `lib/screens/budget_detail_screen.dart`: `SubPageScaffold(actions: [IconButton(icon lịch, ValueKey('budget-detail-period-picker'))])` → `showModalBottomSheet` liệt kê `detail.periodOptions` **giảm dần** (`ValueKey('budget-detail-period-<startISO>')`, kỳ đang xem đánh dấu teal) → chọn → `setState(_viewedRange = …)` để tính lại **toàn bộ** nội dung màn (dòng phụ app bar, thẻ tiến độ, số vượt/còn lại, huy hiệu, biểu đồ, danh sách, phạm vi lọc của "Xem tất cả") (FR-023, research R14)
- [X] T023 [P] [US3] Thêm khóa dịch EN cho bộ chọn kỳ vào `lib/core/locale/sora_translations.dart`: tiêu đề bộ chọn (`'Chọn kỳ'`), nhãn kỳ `'Tuần @từ – @đến'` / `'@tháng, @năm'` / `'Năm @năm'`, dòng phụ app bar cho chu kỳ Tuần/Năm (FR-002, FR-021, kịch bản 18)
- [X] T024 [US3] Bổ sung test: `test/budget_detail_test.dart` — `budgetPeriodOptions` cho Tháng (3 kỳ liên tiếp), Tuần (bắt đầu Thứ Hai), Năm; `!isRecurring` → **1** lựa chọn; không có kỳ nào trước `startDate`; `test/budget_detail_screen_test.dart` — mở bộ chọn thấy đúng các kỳ + kỳ đang xem được đánh dấu; chọn **kỳ đã qua** → số liệu + "Đã kết thúc" + băng cảnh báo ẩn + "Xem tất cả" lọc theo **khoảng của kỳ cũ**; ngân sách không lặp lại đã hết kỳ → mở đúng kỳ đã kết thúc (FR-020, FR-023, SC-012)

## Pha 6: User Story 4 - Chỉnh sửa & Lưu trữ ngân sách từ màn Chi tiết (Ưu tiên: P4)

**Mục tiêu**: Hai nút cuối màn hoạt động ở **mọi kỳ** đang xem — "Chỉnh sửa" mở màn Sửa ngân sách (PBI 20) điền sẵn rồi tính lại số liệu theo giới hạn mới, "Lưu trữ ngân sách" hỏi xác nhận rồi ngừng theo dõi mà **không** đụng tới giao dịch.
**Tiêu chí kiểm thử độc lập**: Sửa giới hạn → quay lại màn Chi tiết thấy số liệu mới, vẫn ở kỳ đang xem; Lưu trữ → hủy thì không ghi gì, xác nhận thì `updateBudget` có `isArchived = true` + màn đóng; sau khi lưu trữ, dòng biến mất khỏi màn Tổng quan và mọi giao dịch Chi của kỳ vẫn còn nguyên.

- [X] T025 [P] [US4] Sửa `lib/core/budget/budget.dart`: thêm `final bool isArchived` (**mặc định `false`** ⇒ mọi chỗ khởi tạo cũ biên dịch nguyên) + `Budget copyWith({int? categoryId, int? amount, BudgetPeriod? period, bool? isRecurring, DateTime? startDate, bool? isArchived})`; sửa `lib/core/budget/budget_view.dart`: `buildBudgetOverview` **bỏ qua** dòng `budget.isArchived` (cả danh sách lẫn thẻ tổng) (FR-016, data-model luật 9)
- [X] T026 [P] [US4] Sửa `lib/data/db/app_database.dart`: `Budgets` thêm `BoolColumn isArchived` (default `false`), `schemaVersion => 7`, migration `if (from < 7) await m.addColumn(budgets, budgets.isArchived);` (**không** seed, không thêm bảng) (FR-016, data-model §Bảng drift)
- [X] T027 [US4] Sinh lại `lib/data/db/app_database.g.dart` bằng `dart run build_runner build --delete-conflicting-outputs` (không sửa tay; phụ thuộc T026 — quên bước này thì analyze/test đỏ ngay) (Rủi ro 6)
- [X] T028 [US4] Map thêm trường: `lib/data/wallet_repository_drift.dart` (`budgets()` / `insertBudget` / `updateBudget` ↔ cột `is_archived`), cập nhật doc comment `budgets()` trong `lib/data/wallet_repository.dart` (trả **cả** ngân sách đã lưu trữ — tầng view tự lọc, **không** đổi chữ ký), và giữ `isArchived` trong `insertBudget` của `test/fakes/fake_wallet_repository.dart` (phụ thuộc T025, T027)
- [X] T029 [US4] Thêm 2 nút cuối màn vào `lib/screens/budget_detail_screen.dart` (`bottomNavigationBar: SafeArea(Row 2 nút cao 44px)`, **hiện ở mọi kỳ** — FR-024): **"Chỉnh sửa"** (`ValueKey('budget-detail-edit')`, `OutlinedButton` viền) → `push(BudgetFormScreen(budget: detail.budget, repository: _repository, now: _now))`; trả `true` → nạp lại và **giữ kỳ đang xem** bằng cách khớp `range.start` trong `periodOptions` mới, không khớp → về kỳ mặc định (Rủi ro 4); **"Lưu trữ ngân sách"** (`ValueKey('budget-detail-archive')`, `FilledButton` teal) → `showDialog` xác nhận (`ValueKey('budget-detail-confirm-archive')` / `'budget-detail-cancel-archive'`) → `updateBudget(detail.budget.copyWith(isArchived: true))` → `Navigator.pop(true)` về màn Tổng quan (FR-015, FR-016, FR-017, FR-024)
- [X] T030 [P] [US4] Thêm khóa dịch EN cho 2 nút + hộp thoại xác nhận lưu trữ (tiêu đề + thân + nhãn nút xác nhận/hủy) vào `lib/core/locale/sora_translations.dart` (FR-021)
- [X] T031 [US4] Bổ sung test: `test/budgets_dao_test.dart` — `isArchived` mặc định `false` khi insert; `updateBudget` ghi `isArchived = true` rồi đọc lại; migration DB v6 giả lập (`user_version = 6`, bảng `budgets` không có cột `is_archived`) → mở lại có cột và **dữ liệu ngân sách cũ nguyên vẹn** (bám khuôn `test/transactions_dao_test.dart`); `test/budget_view_test.dart` — `buildBudgetOverview` loại dòng archived khỏi danh sách **và** khỏi thẻ tổng; `test/budget_detail_screen_test.dart` — "Chỉnh sửa" mở `BudgetFormScreen` điền sẵn, lưu xong → số liệu theo giới hạn mới + **giữ kỳ đang xem**, đổi chu kỳ → không lỗi và về kỳ mặc định mới; "Lưu trữ" → hủy **không** ghi gì, xác nhận → `updateBudget` có `isArchived = true` + `pop(true)`

## Pha cuối: Polish & Cross-cutting

- [X] T032 Chạy `flutter analyze` (kỳ vọng sạch, không warning mới) và `flutter test` toàn bộ tại `app/sora_thu_chi/` — xác nhận không phát sinh test đỏ mới, gồm `sora_translations_test` (thiếu khóa EN là đỏ) và toàn bộ test cũ
- [X] T033 Chạy QA tay trên emulator Android theo `.specify/specs/21/quickstart.md` nhóm **A–N**, đối chiếu mockup `docs/budget/man-hinh-03-chi-tiet-ngan-sach.svg`, rồi điền bảng "Ghi nhận kết quả" ở cuối `quickstart.md`
- [X] T034 [P] Tick `.specify/specs/21/checklists/requirements.md` sau khi thi công xong (giữ nguyên nội dung đã duyệt)
- [X] T035 [P] Đồng bộ wiki theo skill `sora-wiki`: page `wiki-knowledge/entity/Ngân sách.md` (schema **v7** với `is_archived`, màn `03` đã dựng, công thức ngày còn lại **gồm hôm nay**, ngưỡng cảnh báo nhịp `% dùng > % ngày`, so sánh 3 kỳ dự kiến–thực tế tính lại từ dữ liệu, `fl_chart` đã dùng, lưu trữ một chiều **chưa có nơi xem lại**), page Lộ trình phát triển (PBI 21 xong, phần 2c đóng ở mức tối thiểu, còn lại 2b + phần còn lại của 2c), page Design system (cột "Dự kiến" màu trung tính, đường mốc nét đứt) + append `wiki-knowledge/log.md`

## Sơ đồ phụ thuộc

```text
Setup (T001)
  └─ Foundational (T002, T003, T004, T005 → T006 [cần T002], T007 [cần T003])
       ├─ US1 (T008 → T009 → T010 → T011 → T012 → T013 → T014; T015 [P]; T016)
       │     T014 sửa `budget_overview_screen.dart` (điểm vào) — phụ thuộc T008
       ├─ US2 (T017 → T018 → T019 → T020)      — phụ thuộc T008/T012 (chèn khối vào thân màn)
       ├─ US3 (T021 → T022 → T023 [P] → T024)  — phụ thuộc T008/T021
       └─ US4 (T025 [P] ∥ T026 → T027 → T028 → T029 → T030 [P] → T031)

US2, US3, US4 đều sửa `budget_detail_screen.dart` (T018/T019, T022, T029) ⇒ phải chạy TUẦN TỰ sau US1, không song song với nhau.
US2 và US3 cùng sửa `budget_detail.dart` (T017, T021) ⇒ T021 phải chạy sau T017 (hoặc ngược lại, không đồng thời).
US4 chạm schema ⇒ T027 (build_runner) bắt buộc xong trước mọi test đụng drift.
Polish (T032 → T033 → T034/T035) chạy sau khi cả 4 story xong.
```

## Ví dụ chạy song song

```text
# Foundational — 4 file khác nhau, chạy cùng lúc:
T002 [P] budget_view.dart          T003 [P] budget_detail.dart
T004 [P] date_label.dart           T005 [P] sub_page_scaffold.dart
# rồi T006 [P] và T007 [P] (2 file test khác nhau) sau khi T002/T003 xong

# US1 — 2 file khác nhau, chạy cùng lúc sau khi T008…T013 xong:
T015 [P] [US1] sora_translations.dart
T016 [US1] budget_detail_screen_test.dart

# US4 — 2 file khác nhau, chạy cùng lúc:
T025 [P] [US4] budget.dart + budget_view.dart
T026 [P] [US4] app_database.dart

# Polish — chạy cùng lúc sau khi hết test:
T034 [P] checklists/requirements.md
T035 [P] wiki-knowledge/
```

## Chiến lược triển khai

- **MVP đề xuất**: Pha 1 + Pha 2 + **User Story 1** — đã là một màn Chi tiết dùng được đầy đủ (tiến độ, cảnh báo nhịp, danh sách giao dịch, "Xem tất cả"), đúng SC-001…SC-005, SC-008, SC-011.
- **Giao hàng tăng dần**: US1 (MVP) → US2 (biểu đồ so sánh) → US3 (đổi kỳ, xem kỳ đã qua) → US4 (chỉnh sửa & lưu trữ + schema v7). Mỗi story là một bản release độc lập chạy được; US2/US3/US4 đều là phần bổ sung vào cùng một màn nên chỉ cần chạy test của story trước khi sang story sau.
- **Rủi ro cần theo dõi khi thi công**: API `fl_chart 1.2.0` (T018 — Rủi ro 1), quên `build_runner` sau T026 (Rủi ro 6), và 1 khẳng định test cũ ở `budget_overview_screen_test.dart` phải sửa theo FR-001 (T014 — Rủi ro 5).
