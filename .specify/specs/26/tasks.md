# Danh sách Task: So sánh kỳ (màn 03 Báo cáo)

**Mã PBI**: 26
**Nguồn**: spec.md, plan.md, data-model.md, research.md, quickstart.md
**Ghi chú phạm vi**: chỉ màn **03 (So sánh kỳ)** — **không** schema mới (giữ drift **v8**), không migration, không `build_runner`, **không** dependency mới (`LineChart` của `fl_chart ^1.2.0` đã có trong `pubspec.yaml`), không sửa `sora_colors.dart`/`app_colors.dart`, không sửa `pubspec.yaml`, không đụng `app_shell.dart`/`AppBottomNavBar`/`WalletRepository`.

## Định dạng task

`- [ ] [MãTask] [P?] [Story?] Mô tả kèm đường dẫn file`

- `[P]`: có thể chạy song song (khác file, không phụ thuộc task chưa xong)
- `[Story]`: bắt buộc ở pha User Story (VD `[US1]`), không dùng ở Setup/Foundational/Polish

---

## Pha 1: Setup

- [X] T001 Chạy `flutter pub get` + `flutter analyze` + `flutter test` tại `app/sora_thu_chi/` để chốt baseline (**835 pass + 1 test đỏ có sẵn** ở `test/transactions_dao_test.dart`) và xác nhận `fl_chart ^1.2.0` + `BarChart`/`PieChart` đã chạy thật ở PBI 21/22 — **không** sửa `app/sora_thu_chi/pubspec.yaml`, **không** chạy `build_runner`
- [X] T002 [P] Spike **lần đầu dùng `LineChart`**: dựng thử tối thiểu một `LineChart` 2 đường (một `LineChartBarData` nét liền + một `dashArray: [4, 3]`, `FlSpot`, `FlDotData` ẩn `show: false`, `FlTitlesData` chỉ bật trục hoành với `SideTitles` + hàm nhãn trả `SizedBox.shrink()` cho mốc không vẽ) trong scratch hoặc test tạm ở `app/sora_thu_chi/test/` → chạy `flutter analyze` + test để chốt **đúng API của `fl_chart 1.x`** (rủi ro 1 plan.md), ghi lại chữ ký tham số thật rồi **xoá** file spike trước T021

## Pha 2: Foundational

*(Bắt buộc xong trước mọi user story: 4 thực thể logic + 4 hàm thuần + 15 khóa dịch + 2 method controller. Không schema, không migration — data-model §5)*

- [X] T003 Thêm `enum CompareMode { previous, lastYear }` (cạnh `enum ReportPeriod`), `class CompareSide` (`DateRange range`, `int income`, `int expense`, `List<int> dailyExpense`, getter `bool get hasAnyTxn => income > 0 || expense > 0`), `class CompareDelta` (`int? percent`, `int direction`, `bool? isGood`), `class ReportComparison` (`ReportPeriod period`, `CompareSide left`, `CompareSide right`, `CompareDelta incomeDelta`, `CompareDelta expenseDelta`, `String insight`, getter `bool get isEmpty`, `bool get hasExpense`, `int get dayCount`) vào `app/sora_thu_chi/lib/core/report/report_view.dart` — data-model §1.1–§1.4, FR-003/FR-005/FR-007/FR-008/FR-016
- [X] T004 Thêm hàm thuần `DateRange reportRefRange(ReportPeriod period, DateRange main, CompareMode mode)` vào `app/sora_thu_chi/lib/core/report/report_view.dart`: `previous` → `reportPeriodRange(period, _previousStart(period, main.start))`; `lastYear` → dời `main.start` lùi **1 năm** (**kẹp 29/02 → 28/02**) rồi `reportPeriodRange(period, shifted)` — **một** luật chạy cho cả 4 loại kỳ, Tuần tự bắt Thứ Hai, Tháng/Năm giải bằng số học ngày — FR-003/FR-005/FR-018, data-model luật 2–4, R4
- [X] T005 Thêm hàm thuần `List<int> reportDailyExpense(List<Transaction> transactions, DateRange range)` vào `app/sora_thu_chi/lib/core/report/report_view.dart`: trả mảng dài **đúng bằng số ngày** của `range` (index 0 = ngày đầu kỳ), chỉ cộng giao dịch **Chi** (lọc `type == TxnType.expense` như `reportTotals` ⇒ transfer/adjustment tự bị loại), **không** luỹ kế — FR-012/FR-015, data-model luật 10–12, R6
- [X] T006 Thêm hàm thuần `CompareDelta compareDelta({required int main, required int ref, required bool higherIsGood})` vào `app/sora_thu_chi/lib/core/report/report_view.dart`: `ref == 0` ⇒ `percent = null`, `isGood = null`, `direction = 0`; `percent == 0` ⇒ `direction = 0` + `isGood = null` (không mũi tên, không tô màu); còn lại `percent = ((main − ref) / ref * 100).round()`, `direction` theo dấu, `isGood = higherIsGood ? (main − ref) > 0 : (main − ref) < 0` — **màu theo ý nghĩa, không theo chiều** — FR-009/FR-010/FR-011, data-model luật 5–9, R5
- [X] T007 Thêm hàm thuần `ReportComparison reportComparison({required List<Transaction> transactions, required List<Category> categories, required ReportPeriod period, required DateTime leftAnchor, required DateTime rightAnchor})` + hàm private `String _insightSentence(...)` vào `app/sora_thu_chi/lib/core/report/report_view.dart`: hai vế dựng qua `reportPeriodRange` + `reportTotals` + `reportDailyExpense`; hai delta qua `compareDelta` (`higherIsGood: true` cho Thu, `false` cho Chi); câu Nhận xét ghép **mệnh đề chính + mệnh đề danh mục** theo thứ tự ưu tiên R9 (cả hai không có chi tiêu → kỳ **phải** không có chi tiêu → `0%` → tăng/giảm), chữ `@ref` **suy từ so sánh ngày** (`right.range.start < left.range.start` ⇒ "kỳ trước", ngược lại "kỳ sau" — **không** lấy từ `CompareMode`), danh mục tăng mạnh nhất lấy bằng cách gọi `_breakdown` cho **cả hai** kỳ rồi chọn **max dương** chênh lệch tuyệt đối (gộp cha, gồm danh mục **ẩn**) — FR-013/FR-014, data-model luật 15–20, R8/R9
- [X] T008 [P] Thêm **khóa dịch EN** vào nhánh `en` của `app/sora_thu_chi/lib/core/locale/sora_translations.dart`, mục "Báo cáo (PBI 26) — màn So sánh kỳ `03`": `'So sánh kỳ'`, `'So sánh'`, `'Xu hướng chi tiêu theo ngày'`, `'Nhận xét'`, `'Kỳ đối chiếu không có dữ liệu để so sánh'`, `'Chưa có giao dịch nào trong hai kỳ này'`, `'Chưa có dữ liệu để so sánh'`, `'Hai kỳ đều chưa có chi tiêu.'`, `'Kỳ này bạn chi @amount, kỳ đối chiếu chưa có chi tiêu để so sánh.'`, `'Bạn chi nhiều hơn @ref @percent%.'`, `'Bạn chi ít hơn @ref @percent%.'`, `'Bạn chi tiêu bằng @ref.'`, `' Chủ yếu do danh mục @category tăng mạnh.'`, `'kỳ trước'`, `'kỳ sau'` — **tái dùng** (không thêm) `'Thu nhập'`, `'Chi tiêu'`, `'Tháng'`/`'Tuần'`/`'Ngày'`/`'Năm'`, `'Khác'`, `'Thử lại'`, `'Chưa có giao dịch nào trong kỳ này'` — FR-021, R11 (khóa dịch = chính chuỗi tiếng Việt, mặc định VI không cần bản đồ)
- [X] T009 Thêm 2 method vào `app/sora_thu_chi/lib/core/report/report_controller.dart`: `ReportComparison? comparison({required DateTime leftAnchor, required DateTime rightAnchor})` (trả `null` khi `!_loaded`, ngược lại gọi `reportComparison(transactions: _transactions, categories: _categories, period: period.value, leftAnchor: leftAnchor, rightAnchor: rightAnchor)`) và `bool hasAnyTxnBefore(DateTime start)` (một vòng lặp trên `_transactions`: `type == income || type == expense`, `date` **trước** `start`, **transfer/adjustment không tính**) — **không** thêm Rx state, **không** đọc DB, **không** đổi `load()`/`setPeriod()`/`categoryDetail()` — FR-015/FR-017, R1/R3
- [X] T010 [P] Mở rộng `app/sora_thu_chi/test/report_view_test.dart`, nhóm test mới "So sánh kỳ (PBI 26)": `reportRefRange` (4 loại kỳ × 2 chế độ; Tuần lùi 7 ngày **vẫn Thứ Hai**; Tháng 2/2024 nhuận → tháng 1/2024; `lastYear` từ 29/02/2024 **kẹp** 28/02/2023), `reportDailyExpense` (độ dài = số ngày kỳ; **không** luỹ kế; chỉ Chi; transfer/adjustment không tính; kỳ rỗng → toàn 0), `compareDelta` (tăng/giảm/`0%`/`ref == 0`; màu theo ý nghĩa: Thu tăng & Chi giảm ⇒ `isGood == true`; Thu giảm & Chi tăng ⇒ `false`; `0%` và `ref == 0` ⇒ `null`), `reportComparison` (`isEmpty`, `hasExpense`, `dayCount` khi hai kỳ khác số ngày; **4 biến thể** câu Nhận xét + mệnh đề danh mục; danh mục con **gộp cha**; danh mục **ẩn** vẫn nêu tên; không danh mục nào tăng → không nêu tên; chữ **`@ref`** đổi đúng chiều khi hoán đổi hai mốc) — FR-003…FR-016, R9/R14
- [X] T011 [P] Mở rộng `app/sora_thu_chi/test/report_controller_test.dart`: `comparison(...)` trả `null` khi **chưa** `load()`; sau `load(now: DateTime(2026, 3, 15))` số liệu **khớp** kết quả gọi thẳng hàm thuần `reportComparison` cùng tham số; `hasAnyTxnBefore` — giao dịch transfer/adjustment **không** tính, giao dịch đúng mốc `date == start` **không** tính, giao dịch sau `start` không tính, có giao dịch thu/chi trước `start` ⇒ `true` — FR-017, R1/R3/R14
- [X] T012 Cổng chốt Foundational: chạy `flutter test test/report_view_test.dart test/report_controller_test.dart test/sora_translations_test.dart` tại `app/sora_thu_chi/` → toàn bộ **xanh** trước khi vào user story

## Pha 3: User Story 1 — Mở màn So sánh kỳ và xem số liệu hai kỳ (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: từ màn Tổng quan Báo cáo, chạm **1 lần** vào biểu tượng so sánh trên vùng tiêu đề → màn **So sánh kỳ** mở ra (app bar teal + back + tiêu đề "So sánh kỳ", **không** bottom nav/FAB): cặp chip kỳ (trái = kỳ đang xem, tô teal/chữ trắng, nhãn tĩnh; giữa là **nút hoán đổi**; phải = kỳ liền trước, nền nhạt) + thẻ **Thu nhập** và **Chi tiêu** với **cặp cột tỉ lệ**, **hai dòng số tiền** và **badge %** tô màu theo ý nghĩa; hoán đổi đổi chỗ hai kỳ và mọi thành phần cập nhật theo; back về màn 01 giữ nguyên kỳ đang chọn.
**Tiêu chí kiểm thử độc lập**: ở kỳ Tháng có dữ liệu → chạm icon → màn 03 mở đúng mockup `docs/report/man-hinh-03-so-sanh-ky.svg` phần chip + 2 thẻ số liệu; cộng tay từ sổ giao dịch khớp **0 đ**; badge đúng chiều + đúng màu; hoán đổi 2 lần về đúng trạng thái ban đầu; back không đổi kỳ màn 01.

- [X] T013 [US1] Tạo khung màn `app/sora_thu_chi/lib/screens/report_comparison_screen.dart`: `StatefulWidget` giữ **3 field** `DateTime _left`, `DateTime _right`, `CompareMode _mode` (initState: `final c = ensureReportController();` `_left = c.now`; `_right = reportRefRange(c.period.value, reportPeriodRange(c.period.value, c.now), CompareMode.previous).start`; `_mode = CompareMode.previous`), thân bọc `Obx` gọi `c.comparison(leftAnchor: _left, rightAnchor: _right)`, ngoài cùng `SubPageScaffold(title: 'So sánh kỳ'.tr, child: ...)` (app bar teal + back sẵn có, **không** bottom nav, **không** FAB), `comparison == null` ⇒ `SizedBox.shrink()` (chỉ xảy ra ở test), `ValueKey('report-comparison-screen')` trên `ListView` (`padding` đáy 24) — FR-002/FR-015, R1/R2, plan.md §Kiến trúc 3
- [X] T014 [US1] Dựng **cặp chip kỳ + nút hoán đổi** trong `app/sora_thu_chi/lib/screens/report_comparison_screen.dart`: hàng `Row` — chip trái `Expanded` + `Container` bo `15px` nền `AppColors.teal`, chữ trắng w600, `ValueKey('report-compare-chip-left')`, **không** `InkWell` (nhãn tĩnh — FR-005); giữa là nút tròn 28 px icon `Icons.swap_horiz` `ValueKey('report-compare-swap')` → `setState` **đổi chỗ** `_left` ⇄ `_right` (**không** tính lại kỳ đối chiếu theo `_mode` — FR-006); chip phải `Expanded` `Container` bo `15px` nền `colors.softCardBg` chữ `colors.listLabel`, `ValueKey('report-compare-chip-right')`; cả hai chip dùng `FittedBox(fit: BoxFit.scaleDown)` + `Text(maxLines: 1)` với nhãn `reportPeriodChipLabel(period, reportPeriodRange(period, mốc))` — FR-003/FR-004/FR-006/FR-023, R4/R10
- [X] T015 [US1] Dựng widget `_CompareStatCard` trong `app/sora_thu_chi/lib/screens/report_comparison_screen.dart` (dùng cho cả hai thẻ): thẻ nền `colors.softCardBg` bo `10`; hàng tiêu đề `Text(title)` + badge `ValueKey('report-compare-badge-<income|expense>')` — `percent == null` ⇒ hiện ghi chú `'Kỳ đối chiếu không có dữ liệu để so sánh'.tr` thay badge, `percent == 0` ⇒ `'0%'` **không** mũi tên **không** tô màu, còn lại `'▲ @percent%'`/`'▼ @percent%'` màu `isGood == true ? colors.tealOnNeutral : colors.coralOnNeutral`; hàng dưới: **hai cột** `Container` cao `64 * value / max` (cột lớn hơn chiếm trọn 64; cả hai 0 ⇒ không vẽ cột) — cột **trái** tô màu loại giao dịch (`tealOnNeutral` cho Thu / `coralOnNeutral` cho Chi), cột **phải** `colors.dotEmpty` alpha `0.5` — kèm **hai dòng số** `formatMoney` (nhãn cột bằng `reportBarLabel(period, range.start)`, dòng kỳ **trái** đậm hơn) — FR-007/FR-008/FR-009/FR-010/FR-011, data-model luật 7–9/14, R5/R10/R13
- [X] T016 [US1] Thêm điểm vào trong `app/sora_thu_chi/lib/screens/report_screen.dart`: `ScreenHeader(title: 'Báo cáo'.tr, trailing: _CompareButton(...), bottom: ...)` — nút tròn 48 px icon `Icons.compare_arrows` `ValueKey('report-compare-entry')`, màu `AppColors.white` khi **bật**, `AppColors.tealLightText` khi **tắt** (theo `controller.hasAnyTxnBefore(view.range.start)`); chạm khi **tắt** → `SnackBar('Chưa có dữ liệu để so sánh'.tr)` **không** mở màn; chạm khi bật → `Navigator.push(MaterialPageRoute(builder: (_) => const ReportComparisonScreen()))` (**không** truyền `onSelectTab`) — FR-001/FR-017/FR-020, R3, plan.md §Kiến trúc 4
- [X] T017 [P] [US1] Viết `app/sora_thu_chi/test/report_comparison_screen_test.dart` (phần US1): pump màn 03 với `FakeWalletRepository.withCategories(...)` + `ReportController.load(now: DateTime(2026, 3, 15))` qua `ensureReportController()` (`Get.put` rồi `Get.reset()` trong `tearDown`) — app bar teal + tiêu đề "So sánh kỳ", **không** có bottom nav/FAB; nhãn hai chip đúng chuỗi `Tháng 3/2026` / `Tháng 2/2026`; chiều cao hai cột đúng tỉ lệ; hai dòng số `formatMoney` đúng; badge đúng chiều + đúng màu (dùng `tester.widget<Text>(...)`/`Container` lấy `color`); chạm `report-compare-swap` → chip **đổi chỗ** + mọi số liệu và màu badge cập nhật, chạm **lần hai** về **đúng** trạng thái ban đầu; ca English (`Get.updateLocale(Locale('en'))`, khôi phục `Get.locale` trong `addTearDown` — bài học PBI 19) ⇒ **0** nhãn tiếng Việt còn sót — FR-003/FR-006/FR-007/FR-010/FR-021, SC-001/SC-005/SC-007/SC-013, R14
- [X] T018 [P] [US1] Mở rộng `app/sora_thu_chi/test/report_screen_test.dart`: có `report-compare-entry` trên vùng tiêu đề; chạm → `find.byType(ReportComparisonScreen)` xuất hiện; ca **chưa từng** có thu/chi trước kỳ đang xem → icon ở trạng thái vô hiệu hoá, chạm → có `SnackBar` + **không** mở màn 03 — FR-001/FR-017, SC-002, R14

## Pha 4: User Story 2 — Chip kỳ đối chiếu: cùng kỳ năm trước (Ưu tiên: P2)

**Mục tiêu**: chạm **chip kỳ đối chiếu** (chip phải) → kỳ đối chiếu luân chuyển giữa **kỳ liền trước** ⇄ **cùng kỳ năm trước**, mọi số liệu của màn (cặp cột, hai dòng số, badge %, biểu đồ, chú giải, câu Nhận xét) cập nhật theo cặp kỳ mới; chạm lần nữa quay về trạng thái ban đầu; kỳ chính và kỳ đang chọn của màn Tổng quan **không** đổi.
**Tiêu chí kiểm thử độc lập**: ở trạng thái mặc định (T3/2026 vs T2/2026) chạm chip phải → chip phải thành `Tháng 3/2025` và số liệu đổi theo; chạm lần nữa quay về `Tháng 2/2026` trùng khớp; lặp lại đúng với kỳ Ngày/Tuần/Năm.

- [X] T019 [US2] Thêm hành vi **chạm chip phải** trong `app/sora_thu_chi/lib/screens/report_comparison_screen.dart`: bọc chip phải trong `InkWell` (`onTap` → `setState`: `_mode = _mode == CompareMode.previous ? CompareMode.lastYear : CompareMode.previous;` rồi `_right = reportRefRange(period, reportPeriodRange(period, _left), _mode).start`) + **chỉ báo thị giác bấm được** (icon `Icons.swap_horiz`/`Icons.expand_more` nhỏ cạnh chữ, màu `colors.tabInactive`) — **khác biệt cố ý** so với mockup `03`; chip **trái** giữ nguyên nhãn tĩnh, **không** `InkWell` — FR-005/FR-020, SC-016, R4/R10
- [X] T020 [US2] Bổ sung vào `app/sora_thu_chi/test/report_comparison_screen_test.dart` (phần US2): chạm `report-compare-chip-right` → nhãn chip phải đúng `Tháng 3/2025` + số liệu/badge đổi theo cặp mới; chạm lần nữa → về `Tháng 2/2026` **trùng khớp** trạng thái ban đầu; chip **trái** đổi mode xong vẫn nguyên; ca kỳ **Ngày/Tuần/Năm** ra đúng mốc (hôm trước/năm trước; tuần trước vẫn bắt Thứ Hai) — FR-005, SC-016, R14

## Pha 5: User Story 3 — Biểu đồ xu hướng chi tiêu theo ngày (Ưu tiên: P2)

**Mục tiêu**: thẻ **"Xu hướng chi tiêu theo ngày"** vẽ **hai đường** — kỳ trái **nét liền teal**, kỳ phải **nét đứt xám** — kèm **chú giải** khớp nhãn hai chip; trục hoành đánh số **ngày trong kỳ** (`1 … dayCount`), mỗi điểm là **tổng chi của ngày đó** (không luỹ kế); kỳ ngắn hơn **dừng** ở ngày cuối kỳ đó.
**Tiêu chí kiểm thử độc lập**: so tháng 2/2026 (28 ngày) với tháng 1/2026 (31 ngày) → trục `1 … 31`, đường tháng 2 chỉ có 28 điểm; kiểm một ngày có nhiều giao dịch chi → điểm đúng bằng tổng chi **riêng ngày đó**; kỳ **Ngày** vẫn vẽ được (mỗi kỳ 1 điểm).

- [X] T021 [US3] Dựng widget `_TrendCard` trong `app/sora_thu_chi/lib/screens/report_comparison_screen.dart`: thẻ nền `colors.softCardBg` bo `10`, tiêu đề `'Xu hướng chi tiêu theo ngày'.tr` + **chú giải** `Wrap` nhãn 2 kỳ (`reportPeriodChipLabel` — khớp cặp chip, chấm màu tương ứng), thân `LineChart` (`LineChartData`) với **2** `LineChartBarData`: kỳ **trái** `colors.tealOnNeutral` nét **liền**, kỳ **phải** `colors.tabInactive` + `dashArray: [4, 3]` nét **đứt**; `FlDotData(show: false)`, không `isCurved`; `FlTitlesData` chỉ bật **trục hoành** (`interval: 1`, hàm nhãn chỉ vẽ ở mốc `1`, giữa, `dayCount`, các mốc khác trả `SizedBox.shrink()`), **không** trục tung/lưới; `borderData` đường đáy `colors.divider`; dữ liệu điểm dựng từ `dailyExpense` (kỳ ngắn hơn **tự dừng** vì hết điểm — không nội suy/đệm 0), `ValueKey('report-compare-trend')` — FR-012, data-model luật 12–13, R6/R7
- [X] T022 [US3] Bổ sung vào `app/sora_thu_chi/test/report_comparison_screen_test.dart` (phần US3): có `report-compare-trend` + `LineChart`; chú giải đủ 2 nhãn khớp cặp chip; dữ liệu 2 đường **khớp** `reportDailyExpense` của từng kỳ (số điểm mỗi đường = số ngày kỳ đó, **không** kéo dài); kỳ **Ngày** vẫn vẽ được — FR-012, SC-003/SC-009, R14

## Pha 6: User Story 4 — Thẻ Nhận xét tự động (Ưu tiên: P2)

**Mục tiêu**: thẻ **"Nhận xét"** (nền `colors.coralLightBg` + icon `Icons.error_outline` coral) hiển thị **một câu** nêu chiều + mức chênh lệch chi bằng chữ, kèm **tên danh mục cha tăng mạnh nhất** khi có danh mục tăng; chi **giảm** ⇒ câu nêu chiều "chi ít hơn"; kỳ đối chiếu **chưa có chi tiêu** ⇒ câu nêu **số tiền chi của kỳ chính** thay vì %.
**Tiêu chí kiểm thử độc lập**: chi T3 > T2 và "Ăn uống" tăng mạnh nhất → câu đúng như mockup `03`; làm chi T3 < T2 → câu đổi chiều; danh mục tăng là **danh mục con** → câu nêu tên **cha**; không danh mục nào tăng → câu **không** nêu tên.

- [X] T023 [US4] Dựng widget `_InsightCard` trong `app/sora_thu_chi/lib/screens/report_comparison_screen.dart`: thẻ nền `colors.coralLightBg` bo `10`, hàng tiêu đề `Icons.error_outline` màu `colors.coralOnNeutral` + `Text('Nhận xét'.tr)` đậm, dưới là `Text(comparison.insight)` (`textPrimary`, xuống dòng gọn — không `maxLines` cắt), `ValueKey('report-compare-insight')` — nội dung câu **đã dựng sẵn** ở tầng thuần (`ReportComparison.insight`, T007) ⇒ widget **không** tính lại gì — FR-013/FR-014/FR-023, R9
- [X] T024 [US4] Bổ sung vào `app/sora_thu_chi/test/report_comparison_screen_test.dart` (phần US4): có `report-compare-insight`; câu hiển thị **khớp** `comparison.insight`; ca chi **tăng** có danh mục tăng ⇒ câu nêu % + tên danh mục **cha**; ca chi **giảm** ⇒ câu "chi ít hơn"; ca kỳ đối chiếu **không có chi tiêu** ⇒ câu nêu **số tiền** (không có `%`); ca English ⇒ câu **dịch được** (`@ref`/`@percent`/`@amount`/`@category` là tham số có tên) — FR-013/FR-021, SC-008/SC-013, R9/R14

## Pha 7: User Story 5 — Trạng thái rỗng & kỳ đối chiếu không có dữ liệu (Ưu tiên: P3)

**Mục tiêu**: **cả hai kỳ** rỗng (hoặc chỉ có chuyển khoản nội bộ) ⇒ màn hiện **trạng thái rỗng** "Chưa có giao dịch nào trong hai kỳ này" — **không** vẽ cột 0, biểu đồ rỗng hay thẻ Nhận xét rỗng, nhưng **vẫn** hiện cặp chip + nút hoán đổi (để còn đường đổi chế độ); kỳ đối chiếu rỗng riêng lẻ ⇒ thẻ số liệu hiện **ghi chú** thay badge, thẻ xu hướng hiện ghi chú thay hai đường phẳng 0.
**Tiêu chí kiểm thử độc lập**: xoá hết thu/chi của cả hai kỳ (chỉ còn transfer) → thấy thông điệp rỗng + **vẫn** có cặp chip; xoá chi tiêu của riêng một kỳ → thẻ số liệu tương ứng ghi chú, **không** có `NaN`/`∞`/`▲ 0%`; kỳ chỉ có Thu ⇒ thẻ Chi tiêu ghi chú, thẻ xu hướng ghi chú.

- [X] T025 [US5] Thêm **trạng thái rỗng hai mức** trong `app/sora_thu_chi/lib/screens/report_comparison_screen.dart`: `comparison.isEmpty` ⇒ `ListView` chỉ gồm `_PeriodChips` + `Center` thông điệp `'Chưa có giao dịch nào trong hai kỳ này'.tr` (`ValueKey('report-compare-empty')`) — **không** dựng 3 thẻ; thẻ **xu hướng**: `!comparison.hasExpense` ⇒ ghi chú thay `LineChart`; ghi chú thẻ số liệu (`percent == null`) đã có ở T015 — **không** đổi thêm — FR-011/FR-016/FR-017, data-model luật 21–22, R12
- [X] T026 [US5] Bổ sung vào `app/sora_thu_chi/test/report_comparison_screen_test.dart` (phần US5): ca cả hai kỳ rỗng ⇒ có `report-compare-empty` + **không** có `LineChart`/`report-compare-insight` + **vẫn** có cặp chip + nút hoán đổi; ca kỳ chỉ có transfer ⇒ coi như rỗng; ca kỳ đối chiếu rỗng riêng ⇒ thẻ số liệu hiện ghi chú (`'Kỳ đối chiếu không có dữ liệu để so sánh'`), **không** có `NaN`/`∞`/`▲ 0%`; ca cả hai vế không có **chi tiêu** nhưng có Thu ⇒ thẻ xu hướng ghi chú, **không** có hai đường phẳng 0 — FR-011/FR-015/FR-016, SC-006/SC-012, R12/R14

## Pha cuối: Polish & Cross-cutting

- [X] T027 [P] Thêm ca smoke **theme tối** cho màn 03 vào `app/sora_thu_chi/test/dark_theme_smoke_test.dart`: pump màn So sánh kỳ (có dữ liệu) ở chế độ Tối → không overflow, token tối thật sự áp (kể cả nét đứt `tabInactive` trên nền tối) — FR-022, SC-014
- [X] T028 Chạy `flutter analyze` + `flutter test` toàn bộ tại `app/sora_thu_chi/` → **0 lỗi analyze**, **không đỏ test cũ** (chỉ còn test đỏ **có sẵn** đã ghi ở T001)
- [X] T029 QA tay trên emulator theo `quickstart.md` nhóm **A–O** (điểm vào & vô hiệu hoá, bố cục theo mockup `03`, số liệu & màu badge, kỳ đối chiếu rỗng/cả hai rỗng, nút hoán đổi, chip cùng kỳ năm trước, biểu đồ theo ngày, câu Nhận xét, làm mới số liệu, Tối + English, màn hình nhỏ + cỡ chữ lớn + số hàng tỉ, offline/hiệu năng) — ghi lại kết quả từng nhóm. **Ghi rõ trong bàn giao**: QA **Android** là đủ (PBI không đụng native/config) — **iOS chưa QA** (rủi ro 8 plan.md)
- [X] T030 Tick checklist `.specify/specs/26/checklists/requirements.md` sau khi thi công xong (**giữ nguyên nội dung** đã duyệt)
- [X] T031 Đồng bộ wiki theo skill `sora-wiki`: cập nhật `wiki-knowledge/entity/` **Báo cáo** (màn `03`: điểm vào icon vùng tiêu đề + vô hiệu hoá theo FR-017, chip kỳ chính **nhãn tĩnh** vs chip đối chiếu **bấm được** ⇄ cùng kỳ năm trước, nút hoán đổi **chỉ đổi chỗ**, `LineChart` 2 đường liền/đứt, câu Nhận xét ghép 2 mệnh đề + `@ref` suy từ ngày, 2 mức trạng thái rỗng, số liệu dựng từ bản chụp RAM), `wiki-knowledge/concept/` **Lộ trình phát triển** (màn `03` xong; còn `04` Xuất báo cáo + bộ lọc nâng cao) và **Design system** (cặp cột tỉ lệ 64 px, token thay cặp trắng-viền `#EFEFEF` của mockup — khác biệt cố ý) + append `wiki-knowledge/log.md` + cập nhật `wiki-knowledge/index.md`
- [ ] T032 Commit PBI 26 theo skill `git-commit` (Conventional Commits, message tiếng Việt có dấu, **không** trailer `Co-Authored-By`)

---

## Sơ đồ phụ thuộc

```text
Setup (T001–T002)
   ↓
Foundational (T003–T012)  ← chặn MỌI user story: 4 thực thể + 4 hàm thuần + 15 khóa dịch + comparison()/hasAnyTxnBefore()
   ↓
US1 P1 (T013–T018)  ← MVP: khung màn 03 + cặp chip + nút hoán đổi + 2 thẻ số liệu + điểm vào màn 01
   ├──→ US2 P2 (T019–T020)  chip kỳ đối chiếu ⇄ cùng kỳ năm trước (cần khung màn + chip của US1)
   ├──→ US3 P2 (T021–T022)  thẻ biểu đồ xu hướng (cần khung màn + dữ liệu dailyExpense của US1)
   ├──→ US4 P2 (T023–T024)  thẻ Nhận xét (cần khung màn; câu dựng sẵn ở Foundational)
   └──→ US5 P3 (T025–T026)  trạng thái rỗng 2 mức (cần khung màn + nhánh ghi chú thẻ của US1)
   ↓
Polish (T027–T032)  ← T027 độc lập; T028–T031 sau khi US1–US5 xong; T032 cuối cùng
```

- **US1 là cổng**: US2–US5 đều cần khung màn 03 đã dựng; **cả 5 story cùng sửa** `lib/screens/report_comparison_screen.dart` và `test/report_comparison_screen_test.dart` ⇒ thi công **tuần tự**, **không** chạy song song.
- **US2–US5 độc lập nhau** về logic (khác widget/thẻ) nhưng cùng file ⇒ thứ tự US2 → US3 → US4 → US5 (không bắt buộc, miễn tuần tự).
- Trong Foundational: T003 → T004 → T005 → T006 → T007 **tuần tự** (cùng `report_view.dart`); T008 [P] (file dịch) và T010 [P] (file test thuần) chạy song song được với T003–T007 khi phần chúng cần đã xong; T009 phụ thuộc T007; T011 phụ thuộc T009; T012 là cổng chốt.
- Trong Polish: T027 [P] (file test theme) chạy cùng lúc với T028–T031 được.

## Ví dụ chạy song song

```text
# Pha 1 — Setup:
T002 [P] spike LineChart — chạy cùng T001 nếu không chờ kết quả test baseline

# Pha 2 — Foundational (khác file):
T003 → T004 → T005 → T006 → T007   lib/core/report/report_view.dart (tuần tự)
T008 [P]                           lib/core/locale/sora_translations.dart
T010 [P]                           test/report_view_test.dart
T011 [P]                           test/report_controller_test.dart

# Pha 3 — US1 (2 file test khác nhau):
T017 [P] [US1] test/report_comparison_screen_test.dart
T018 [P] [US1] test/report_screen_test.dart

# Pha cuối:
T027 [P] test/dark_theme_smoke_test.dart
```

## Chiến lược triển khai

- **MVP đề xuất: chỉ User Story 1** (T001–T018) — sau pha này màn 03 đã *dùng được*: mở từ icon vùng tiêu đề (kèm trạng thái vô hiệu hoá), cặp chip + nút hoán đổi, hai thẻ số liệu với cặp cột tỉ lệ + hai dòng số + badge % đúng màu ngữ nghĩa (SC-001 phần chip/2 thẻ, SC-002/SC-003/SC-005/SC-007).
- **Giao hàng tăng dần**: US1 → US2 (chốt SC-016) → US3 (chốt SC-009) → US4 (chốt SC-008) → US5 (chốt SC-006/SC-012) → Polish (theme tối, QA tay A–O, wiki, commit). Mỗi pha kết thúc bằng `flutter analyze` + test xanh ⇒ là một bản release được.
- **Thứ tự bắt buộc**: Foundational xong trước US1 (T012 là cổng chốt); US2–US5 **tuần tự** sau US1 (cùng file); Polish sau khi cả 5 story xong.
- **Rủi ro cần để mắt khi thi công**: (1) **lần đầu dùng `LineChart`** — chốt API ở T002 trước khi dựng T021; (2) kỳ **Năm** ⇒ 365 điểm × 2 đường — đo ở nhóm O của quickstart; (3) **hoán đổi** làm câu Nhận xét sai chiều nếu lấy `@ref` theo `mode` — đã chốt R9, có test ở T010/T020; (4) hiểu FR-011 **theo từng chỉ số** (đọc ngược ⇒ chia 0 ở thẻ Chi) — test ở T010/T026; (5) **chip dài bị cắt** ở cỡ chữ lớn — `Expanded` + `FittedBox` ở T014, QA nhóm N; (6) test đỏ **có sẵn** `transactions_dao_test` dễ bị nhầm là lỗi mới — mốc baseline ghi ở T001.
