# Danh sách Task: Báo cáo tổng quan (tab Báo cáo)

**Mã PBI**: 22
**Nguồn**: spec.md, plan.md, data-model.md, research.md, quickstart.md
**Ghi chú phạm vi**: chỉ màn **01 (Tổng quan)** — không schema mới (giữ drift **v7**), không migration, không dependency mới, không `build_runner`.

## Định dạng task

`- [ ] [MãTask] [P?] [Story?] Mô tả kèm đường dẫn file`

- `[P]`: có thể chạy song song (khác file, không phụ thuộc task chưa xong)
- `[Story]`: bắt buộc ở pha User Story (VD `[US1]`), không dùng ở Setup/Foundational/Polish

---

## Pha 1: Setup

- [X] T001 Chạy `flutter pub get` + `flutter analyze` + `flutter test` tại `app/sora_thu_chi/` để chốt baseline (597 test, ghi nhận các test đỏ **có sẵn**) và xác nhận `fl_chart ^1.2.0` đã có trong `app/sora_thu_chi/pubspec.yaml` (không sửa pubspec, không chạy `build_runner`)
- [X] T002 [P] Khảo sát API `PieChart`/`PieChartData`/`PieChartSectionData`/`PieTouchData`/`centerSpaceRadius` của `fl_chart ^1.2.0` trong package cache để chốt chữ ký tham số dùng ở T016 (Rủi ro 1 — API `PieChart` chưa dùng lần nào trong repo; nếu vỡ thì chuyển phương án lùi `CustomPaint` đã ghi ở plan.md)

## Pha 2: Foundational

*(Bắt buộc xong trước mọi user story: kiểu dùng chung, token màu, khóa dịch, và toàn bộ mô hình dữ liệu thuần)*

- [X] T003 Tách `DateRange` (khoảng **nửa mở** + `contains`) từ `app/sora_thu_chi/lib/core/budget/budget_view.dart` sang file mới `app/sora_thu_chi/lib/core/date_range.dart`; tại `budget_view.dart` xóa khai báo cũ và thêm `export '../date_range.dart' show DateRange;` (R3 — mọi import cũ không phải sửa)
- [X] T004 [P] Thêm token `final List<Color> chartPalette;` (6 phần tử: 5 hạng + "Khác") vào `app/sora_thu_chi/lib/theme/sora_colors.dart` — Light `[0xFF0F6E56, 0xFF3D8C77, 0xFFE3B341, 0xFF6B7FD7, 0xFFB4B2A9, 0xFF5F5E5A]`, Dark `[0xFF3FA98A, 0xFF4FB694, 0xFFE3B341, 0xFF8B9DEE, 0xFFA8A8A3, 0xFFC9C7BE]`; cập nhật `copyWith` + `lerp` (lerp từng phần tử theo chỉ số, cùng độ dài cố định) — R4/FR-011
- [X] T005 [P] Thêm các khóa dịch EN cho màn Báo cáo vào `app/sora_thu_chi/lib/core/locale/sora_translations.dart`, mục "Báo cáo (PBI 22)" theo plan.md §4 (`'Ngày'`, `'Tổng thu'`, `'Tổng chi'`, `'Dòng tiền 6 ngày/tuần/tháng/năm gần đây'`, `'Phân bổ chi tiêu theo danh mục'`, `'Top danh mục chi tiêu'`, `'Chưa có giao dịch nào trong kỳ này'`, `'Chưa có chi tiêu nào trong kỳ này'`, `'Không đọc được dữ liệu báo cáo.'`) — FR-018/SC-010
- [X] T006 Viết `app/sora_thu_chi/test/report_view_test.dart`: ca `reportPeriodRange` (Ngày/Tuần **bắt đầu Thứ Hai**, Chủ Nhật vẫn thuộc tuần đó/Tháng/Năm + biên nửa mở: mốc đúng `end` **không** thuộc kỳ), `reportPeriodSeries` (đủ **6**, kỳ đang chọn ở **cuối**, lùi đúng 1 đơn vị lịch qua mốc tháng/năm — VD 15/1 → T8…T1), `reportTotals` (cộng đúng thu/chi, **loại** `transfer` + `adjustment`, giao dịch ngày tương lai vẫn tính), `reportBarSeries` (kỳ rỗng → 2 cột 0 nhưng vẫn có nhãn), `percentSplit` (`[1,1,1]` → `[34,33,33]`, `[1,2]` → `[33,67]`, tổng = 100 với 5–6 phần tử), `reportBreakdown` (gộp **con → cha**, ≤5 danh mục ⇒ **không** "Khác", 6 danh mục ⇒ top 5 + "Khác" xếp cuối, tiền `categoryId == null` vào "Khác", danh mục **ẩn** vẫn tính, đồng hạng → tên tăng dần, `Σ tiền lát = expense`, `Σ % = 100`), `reportTopCategories` (≤5, giảm dần, **không** "Khác", `percent` = tỉ lệ trên tổng chi), `buildReportView` (cờ `hasAnyTxn`/`hasExpense` cho 4 ca: rỗng / chỉ Thu / chỉ Chi / chỉ transfer)
- [X] T007 Dựng phần kỳ trong `app/sora_thu_chi/lib/core/report/report_view.dart`: `enum ReportPeriod { day, week, month, year }` + nhãn hiển thị, `DateRange reportPeriodRange(ReportPeriod period, DateTime anchor)` (Ngày `[d, d+1)`, Tuần `[thứ Hai, +7 ngày)`, Tháng `[mùng 1, mùng 1 tháng sau)`, Năm `[1/1, 1/1 năm sau)` — dùng số học ngày, **không** cộng `Duration` cho tháng/năm), `List<DateRange> reportPeriodSeries(ReportPeriod period, DateTime anchor, {int count = 6})` (kỳ đang chọn ở **cuối**) — FR-006/FR-021, data-model luật 1–5
- [X] T008 Thêm vào `app/sora_thu_chi/lib/core/report/report_view.dart`: `class ReportBar` (`DateRange range`, `String label` theo `dd/MM` | `T@tháng` | `@năm`, `int income`, `int expense`, `bool isCurrent`), `({int income, int expense}) reportTotals(List<Transaction> txns, DateRange range)` — **phép lọc duy nhất** loại `TxnType.transfer` + `adjustment`, `income` cộng `+amount` / `expense` cộng `−amount`; `List<int> percentSplit(List<int> amounts, int total)` chia theo **phần dư lớn nhất**; `List<ReportBar> reportBarSeries({transactions, period, anchor, categories})` — FR-004/FR-005/FR-006, data-model luật 6–10, R5
- [X] T009 Thêm vào `app/sora_thu_chi/lib/core/report/report_view.dart`: `class ReportSlice` (`int? categoryId` — `null` = "Khác", `name`, `icon`, `color`, `int rank` — `0…4` hạng / `-1` cho "Khác", `int amount`, `int percent`) + `List<ReportSlice> reportBreakdown({transactions, categories, range})` — gom theo **danh mục cha** (`category.parentId ?? category.id`, tên/icon/màu lấy từ cha), top **5** + nhóm **"Khác"** (phần ngoài top 5 + tiền chi `categoryId == null`, chỉ hiện khi có phần dư, luôn xếp **cuối**), sắp **giảm dần** theo tiền — đồng hạng theo **tên tăng dần**, gán `percent` bằng `percentSplit`; con trỏ tới cha không còn tồn tại ⇒ nhóm theo chính nó — FR-008/FR-009/FR-010/FR-011, data-model luật 11–19, R6
- [X] T010 Thêm vào `app/sora_thu_chi/lib/core/report/report_view.dart`: `class ReportTopCategory` (`int categoryId`, `name`, `icon`, `color`, `int amount`, `double percent`) + `List<ReportTopCategory> reportTopCategories(...)` (**≤ 5**, giảm dần, **không** có dòng "Khác", cùng nguồn nhóm với `reportBreakdown` ⇒ số tiền khớp lát cắt) + `class ReportView` (`period`, `range`, `income`, `expense`, `List<ReportBar> bars`, `List<ReportSlice> slices`, `List<ReportTopCategory> top`, `bool get hasAnyTxn`, `bool get hasExpense`) + `ReportView buildReportView({transactions, categories, period, now})` — FR-013/FR-014/FR-015, data-model luật 20–25, R10
- [X] T011 Chạy `flutter test test/report_view_test.dart` tại `app/sora_thu_chi/` → **toàn bộ xanh** (chốt Foundational trước khi vào user story)

---

## Pha 3: User Story 1 — Xem Tổng quan theo kỳ (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: chạm tab **Báo cáo** → màn Tổng quan mở ra với khu đầu màn teal (tiêu đề "Báo cáo" + segmented control 4 kỳ, mặc định **Tháng** + 2 số tổng thu/chi đã loại transfer), hàng điều hướng "Ngân sách" giữ nguyên, và đổi kỳ thì **toàn bộ** số liệu tính lại.
**Tiêu chí kiểm thử độc lập**: mở tab Báo cáo, đối chiếu khu đầu màn với mockup `01` (`docs/report/man-hinh-01-bao-cao-tong-quan.svg`); chạm lần lượt Ngày/Tuần/Tháng/Năm → 2 số tổng + nhãn kỳ đổi đúng, không có nút biểu tượng lịch; chạm hàng "Ngân sách" → màn Tổng quan Ngân sách mở ra và quay lại vẫn giữ kỳ đang chọn.

- [X] T012 [US1] Viết `app/sora_thu_chi/test/report_controller_test.dart`: `load()` → `data != null` + `period` mặc định `month`; `setPeriod(p)` → số liệu đổi **và** repository **không** bị gọi lại (đếm số lần gọi fake — SC-007); `load(now:)` đổi mốc ⇒ kỳ tính lại theo mốc mới; fake ném lỗi ⇒ `error` được set + `data` cũ **giữ nguyên** (dùng `FakeWalletRepository.withCategories(...)`, `Get.reset()` trong `addTearDown`)
- [X] T013 [P] [US1] Tạo `app/sora_thu_chi/lib/core/report/report_controller.dart`: `class ReportController extends GetxController` nhận `WalletRepository` — `Rx<ReportPeriod> period` (mặc định `month`), `Rxn<ReportView> data`, `RxBool isLoading` (khởi đầu `false` — màn build sẵn offstage trong `IndexedStack`, bám khuôn `TransactionController`), `RxnString error`, `DateTime get now`; `Future<void> load({DateTime? now})` đọc `allTransactions()` + `categoriesIncludingHidden(CategoryType.expense)` rồi dựng `data` bằng `buildReportView` (lỗi ⇒ `error = 'Không đọc được dữ liệu báo cáo.'`, **giữ** `data` cũ); `void setPeriod(ReportPeriod p)` đổi `period` rồi dựng lại `data` **từ dữ liệu đã nạp trong RAM, không đọc DB** (R1/FR-016/SC-007)
- [X] T014 [P] [US1] Tạo `app/sora_thu_chi/lib/data/report_deps.dart`: `ReportController ensureReportController()` — khuôn `ensureTransactionController()` trong `app/sora_thu_chi/lib/data/transaction_deps.dart`, dùng chung `ensureWalletRepository()` singleton (kèm chú thích: controller được khởi tạo ngay lúc boot vì màn build trong `IndexedStack` — Rủi ro 7)
- [X] T015 [US1] Viết lại `app/sora_thu_chi/lib/screens/report_screen.dart` phần khung: giữ nguyên chữ ký `StatelessWidget { ValueChanged<int>? onSelectTab }` (AppShell không phải sửa chỗ dựng màn), đọc `ensureReportController()`, toàn thân bọc `Obx`; `Column` gồm `ScreenHeader(title: 'Báo cáo', bottom: …)` — vùng teal chứa segmented control **4 lựa chọn** (mặc định **Tháng**, lựa chọn đang chọn = pill trắng + chữ teal; widget cục bộ ~15 dòng, R12) + hàng **2 số tổng** chữ trắng (mũi tên ↑ teal nhạt cho "Tổng thu", ↓ coral cho "Tổng chi"), số tiền bọc `FittedBox(fit: scaleDown)`, **không** truyền `trailing` (nút lịch để PBI sau — FR-002); `Expanded` → 3 nhánh: đang nạp lần đầu (spinner) / lỗi (`error` + nút "Thử lại" gọi `load()`) / nội dung (`ListView`, `padding` bottom 96); `ValueKey`: `report-period-day|week|month|year` — FR-001/FR-002/FR-004, SC-001/SC-002
- [X] T016 [US1] Giữ hàng điều hướng **"Ngân sách"** trong `app/sora_thu_chi/lib/screens/report_screen.dart` đúng như hiện tại: widget `_EntryRow` + `ValueKey('report-entry-budget')` + `_openBudget()`, đặt **ngay dưới khu đầu màn, trước thẻ biểu đồ** (FR-017/kịch bản 17); kỳ đang chọn sống trong controller singleton ⇒ rời sang Ngân sách rồi quay lại vẫn giữ kỳ
- [X] T017 [US1] Nối đổi kỳ trong `app/sora_thu_chi/lib/screens/report_screen.dart`: chạm một lựa chọn segmented → `controller.setPeriod(p)` (Obx tự vẽ lại — FR-003); thêm vào `app/sora_thu_chi/lib/core/app_shell.dart` hàm `_onTabSelected`: `if (index == 2) ensureReportController().load();` cạnh dòng `if (index == 1) ensureTransactionController().load();` (FR-016/kịch bản 12 — R1)
- [X] T018 [US1] Viết `app/sora_thu_chi/test/report_screen_test.dart` phần US1: render tiêu đề "Báo cáo", 4 lựa chọn kỳ + mặc định **Tháng**, "Tổng thu"/"Tổng chi" kèm số tiền, hàng "Ngân sách", **không** có icon lịch; đổi kỳ: chạm **Năm** → 2 số tổng tính theo năm; lỗi đọc → thông báo + nút "Thử lại" (test đụng `.tr` phải khôi phục `Get.locale` trong `addTearDown`, `Get.reset()` xóa cả `ReportController`)
- [X] T019 [US1] Chạy `flutter analyze` + `flutter test test/report_controller_test.dart test/report_screen_test.dart` tại `app/sora_thu_chi/` → xanh, không đỏ test cũ

---

## Pha 4: User Story 2 — Biểu đồ dòng tiền 6 đơn vị (Ưu tiên: P2)

**Mục tiêu**: thẻ **"Dòng tiền 6 \<đơn vị\> gần đây"** với chú giải Thu (teal) / Chi (coral) và **biểu đồ cột ghép đôi** 6 đơn vị liên tiếp kết thúc ở kỳ đang chọn; chạm một cột hiện **số tiền chính xác**.
**Tiêu chí kiểm thử độc lập**: ở kỳ Tháng thấy 6 nhóm cột có nhãn `T4…T9` (tháng hiện tại là nhãn cuối, đậm hơn); đổi sang Tuần/Ngày/Năm → tiêu đề thẻ đổi theo và nhãn trục đổi đơn vị; chạm một cột → hiện số tiền, chạm ra ngoài → ẩn, không điều hướng.

- [X] T020 [US2] Dựng thẻ biểu đồ trong `app/sora_thu_chi/lib/screens/report_screen.dart` (widget riêng tư cục bộ): tiêu đề theo kỳ đang chọn (4 khóa dịch `'Dòng tiền 6 …gần đây'`), chú giải **Thu** (chấm teal) / **Chi** (chấm coral), `BarChart` của `fl_chart` — `BarChartGroupData` 2 `BarChartRodData` (thu = token teal, chi = token coral; **không** hex cứng), `FlTitlesData`/`SideTitles` cho nhãn đơn vị dưới trục + nhãn trục tung, `aspectRatio` ~1.6, `maxY` = max × 1.15, `ValueKey('report-flow-chart')` — FR-005/FR-006
- [X] T021 [US2] Bật `barTouchData: BarTouchData(enabled: true, touchTooltipData: …)` trong thẻ biểu đồ ở `app/sora_thu_chi/lib/screens/report_screen.dart` — `getTooltipItem` trả `formatMoney(...)` để chạm một cột hiện **số tiền chính xác** và **không** điều hướng sang màn khác (FR-007; nếu tooltip mặc định không hiện số đã định dạng thì tự dựng `BarTouchTooltipData`) — Rủi ro 5
- [X] T022 [US2] Bổ sung vào `app/sora_thu_chi/test/report_screen_test.dart` phần US2: thẻ biểu đồ hiện đúng tiêu đề ở kỳ **Tháng** và đổi thành "Dòng tiền 6 năm gần đây" khi chạm **Năm**; kỳ rỗng (chỉ transfer) → biểu đồ vẫn dựng đủ **6** nhóm cột với giá trị 0 (FR-006)
- [X] T023 [US2] Chạy `flutter analyze` + `flutter test test/report_screen_test.dart` tại `app/sora_thu_chi/` → xanh

---

## Pha 5: User Story 3 — Phân bổ chi tiêu theo danh mục + drill-down (Ưu tiên: P3)

**Mục tiêu**: thẻ **"Phân bổ chi tiêu theo danh mục"** — vòng tròn (donut) chia theo top 5 danh mục cha + nhóm "Khác", nhãn **"Tổng chi"** kèm số tiền ở giữa vòng tròn, danh sách chú giải (chấm màu, tên, **%**) sắp giảm dần; chạm một lát cắt hoặc dòng chú giải → mở màn **Giao dịch** đã lọc sẵn theo danh mục đó (gồm danh mục con) + khoảng thời gian của kỳ.
**Tiêu chí kiểm thử độc lập**: cộng các **%** trên chú giải = **100%**; tiền các lát = đúng tổng chi của kỳ; giao dịch ở danh mục con gộp vào **một** dòng mang tên cha; chạm một danh mục → màn Giao dịch có chip **Chi** + khoảng ngày của kỳ + danh mục đó, tổng tiền khớp **100%**; chạm nhóm **"Khác"** → không điều hướng.

- [X] T024 [US3] Dựng thẻ phân bổ trong `app/sora_thu_chi/lib/screens/report_screen.dart` (widget riêng tư cục bộ — Rủi ro 1 giảm nhẹ: đổi cách vẽ chỉ chạm 1 chỗ): `Row` gồm `PieChart` (`PieChartData` + `PieChartSectionData` màu lấy từ `SoraColors.chartPalette[rank]` / chỉ số **5** cho "Khác", **không** nhãn trên lát, `centerSpaceRadius` ≈ 34, `sectionsSpace: 2`, `ValueKey('report-donut')`) và **`Stack`** phủ giữa vòng tròn nhãn **"Tổng chi"** + `formatMoney(view.expense)` (fl_chart không tự vẽ chữ ở tâm — Rủi ro 2); bên phải `Expanded` **danh sách chú giải** (chấm màu `chartPalette`, tên danh mục, `@p%`) — FR-008/FR-009/FR-011, `ValueKey('report-slice-<id|other>')` + `ValueKey('report-legend-<id|other>')`
- [X] T025 [US3] Nối drill-down trong `app/sora_thu_chi/lib/screens/report_screen.dart`: chạm lát cắt/dòng chú giải có `categoryId != null` → dựng `TxnSearchFilter(now: controller.now, type: expense, datePreset: custom, dateStart: view.range.start, dateEnd: view.range.end − 1 ngày, categoryIds: {categoryId}, sort: dateNewest)` → `ensureTransactionController().setFilter(f)` → `onSelectTab?.call(1)` (**không** `popUntil` — màn Báo cáo *là* tab); chạm nhóm **"Khác"** (`categoryId == null`) → **không** làm gì — FR-012, R7 (bộ lọc PBI 12 tự mở rộng cha → con ⇒ SC-006)
- [X] T026 [US3] Bổ sung vào `app/sora_thu_chi/test/report_screen_test.dart` phần US3: nhãn "Tổng chi" + số tiền giữa vòng tròn khớp tổng chi kỳ; chú giải sắp giảm dần kèm %; chạm **dòng chú giải** danh mục → `TransactionController.activeFilter` đúng (Chi + `dateStart`/`dateEnd` của kỳ + `categoryIds` = {cha}) **và** `onSelectTab(1)` được gọi; chạm nhóm **"Khác"** → bộ lọc **không** đổi, `onSelectTab` **không** gọi (cần `Get.put(TransactionController(fake))` với repo fake đã đăng ký)
- [X] T027 [US3] Chạy `flutter analyze` + `flutter test test/report_screen_test.dart` tại `app/sora_thu_chi/` → xanh

---

## Pha 6: User Story 4 — Top danh mục chi tiêu (Ưu tiên: P4)

**Mục tiêu**: thẻ **"Top danh mục chi tiêu"** liệt kê tối đa **5** danh mục chi nhiều nhất trong kỳ — mỗi dòng có biểu tượng danh mục, tên, số tiền và **thanh tiến độ** thể hiện tỉ lệ trên tổng chi.
**Tiêu chí kiểm thử độc lập**: kỳ có ≤ 5 danh mục chi → số dòng = số danh mục; kỳ nhiều hơn → đúng 5 dòng, **không** có dòng "Khác"; số tiền mỗi dòng khớp lát cắt cùng danh mục ở thẻ phân bổ; thứ tự giảm dần.

- [X] T028 [US4] Dựng thẻ top trong `app/sora_thu_chi/lib/screens/report_screen.dart` (widget riêng tư cục bộ): tối đa 5 dòng — bubble `categoryIcon` (màu danh mục) + tên + `formatMoney(amount)` + **thanh tiến độ** cục bộ ~15 dòng (**một** màu teal, bề rộng `percent / 100`), `ValueKey('report-top-<id>')`; R12: **không** tách widget dùng chung với thanh tiến độ 3 dải ngưỡng của màn ngân sách — FR-013
- [X] T029 [US4] Bổ sung vào `app/sora_thu_chi/test/report_screen_test.dart` phần US4: kỳ có 3 danh mục chi → 3 dòng, có thanh tiến độ; kỳ có > 5 danh mục → đúng 5 dòng và **không** có dòng "Khác"; số tiền dòng top khớp số tiền lát cắt cùng danh mục (FR-013)
- [X] T030 [US4] Chạy `flutter analyze` + `flutter test test/report_screen_test.dart` tại `app/sora_thu_chi/` → xanh

---

## Pha 7: User Story 5 — Trạng thái rỗng & số liệu luôn mới (Ưu tiên: P5)

**Mục tiêu**: mỗi thẻ có **trạng thái rỗng dễ hiểu** thay vì biểu đồ trống gây hiểu lầm là lỗi; và số liệu luôn phản ánh dữ liệu mới sau khi thêm/sửa/xóa giao dịch.
**Tiêu chí kiểm thử độc lập**: kỳ không có Thu/Chi → 2 số tổng `0 đ` + **cả 3 thẻ** hiện "Chưa có giao dịch nào trong kỳ này"; kỳ chỉ có Thu → biểu đồ vẫn vẽ đủ 6 đơn vị, **riêng** thẻ phân bổ + thẻ top hiện "Chưa có chi tiêu nào trong kỳ này"; kỳ chỉ có chuyển khoản nội bộ → như kỳ rỗng; thêm một giao dịch Chi ở màn Giao dịch rồi chạm tab Báo cáo → số liệu mới ngay lần mở đó; đứng ở tab Báo cáo bấm FAB ghi giao dịch → quay lại đã thấy số mới.

- [X] T031 [US5] Thêm trạng thái rỗng vào `app/sora_thu_chi/lib/screens/report_screen.dart`: widget cục bộ `_EmptyCard` dùng 2 thông điệp phân biệt theo cờ `hasAnyTxn`/`hasExpense` của `ReportView` — `!hasAnyTxn` ⇒ **cả 3** thẻ "Chưa có giao dịch nào trong kỳ này" (2 số tổng hiện `0 đ`); `hasAnyTxn && !hasExpense` ⇒ biểu đồ vẫn vẽ đủ 6 nhóm cột, **chỉ** thẻ phân bổ + thẻ top "Chưa có chi tiêu nào trong kỳ này" — FR-014/FR-015, R10/SC-009
- [X] T032 [US5] Thêm vào `app/sora_thu_chi/lib/core/app_shell.dart` hàm `_openAddTransaction`: sau khi lưu thành công (`saved == true`), giữ `ensureTransactionController().load()` và **thêm** nạp lại controller báo cáo **khi** `_selectedIndex == 2` (R11 — FAB hiện trên mọi tab, không nạp lại thì số liệu cũ ngay trước mắt; FR-016/SC-008)
- [X] T033 [US5] Bổ sung vào `app/sora_thu_chi/test/report_screen_test.dart` phần US5: kỳ rỗng → 3 thẻ rỗng + "Tổng thu"/"Tổng chi" = 0; kỳ chỉ Thu → biểu đồ vẫn dựng, 2 thẻ kia rỗng; kỳ chỉ transfer → như kỳ rỗng (FR-014/FR-015)
- [X] T034 [US5] Bổ sung vào `app/sora_thu_chi/test/report_controller_test.dart` phần US5: gọi `load()` hai lần liên tiếp với dữ liệu fake đổi giữa hai lần ⇒ `data` phản ánh số mới (đường nạp lại khi chọn tab + sau FAB — FR-016/SC-008)
- [X] T035 [US5] Chạy `flutter analyze` + `flutter test test/report_controller_test.dart test/report_screen_test.dart` tại `app/sora_thu_chi/` → xanh

---

## Pha 8: Polish & Cross-cutting

- [X] T036 Kiểm tra & sửa `app/sora_thu_chi/test/widget_test.dart`: nhóm shell — xác nhận các khẳng định đang có vẫn đúng sau khi `ReportScreen` được viết lại (đếm chữ "Báo cáo" = 2: header + tab) và `pumpShell` vẫn chạy với `FakeWalletRepository` (controller báo cáo khởi tạo lúc boot, nạp khi chọn tab 2) — chỉ sửa **nếu** khẳng định cũ vỡ
- [X] T037 Thêm ca smoke vào `app/sora_thu_chi/test/dark_theme_smoke_test.dart`: pump màn Tổng quan Báo cáo ở **theme tối** (có dữ liệu) → không overflow, token tối thật sự áp (FR-019/SC-011)
- [X] T038 Chạy `flutter analyze` + `flutter test` (toàn bộ) tại `app/sora_thu_chi/` → analyze sạch, **không đỏ test cũ** (ghi nhận các test đỏ **có sẵn** đã thấy ở T001)
- [X] T039 QA tay theo `quickstart.md` nhóm **A–I** trên emulator Android (bố cục/2 số tổng/chuyển khoản/biểu đồ/vòng tròn/drill-down/top/đổi kỳ/trạng thái rỗng/dữ liệu đổi) — đối chiếu mockup `docs/report/man-hinh-01-bao-cao-tong-quan.svg`; sửa lệch phát hiện được
- [X] T040 QA tay nhóm **J–K** (English không sót nhãn tiếng Việt, chế độ Tối, cỡ chữ lớn nhất + màn hình nhỏ, số tiền hàng tỉ, tắt mạng) — SC-010/SC-011/SC-012; lệch màu dark chỉ chỉnh **một chỗ** trong `SoraColors.chartPalette` tại `app/sora_thu_chi/lib/theme/sora_colors.dart`
- [X] T041 Tick `checklists/requirements.md` của PBI 22 (giữ nguyên nội dung đã duyệt, không sửa câu chữ)
- [X] T042 Đồng bộ wiki theo skill `sora-wiki`: tạo page `wiki-knowledge/entity/Bao-cao.md` (kỳ Ngày/Tuần/Tháng/Năm + tuần bắt đầu Thứ Hai, biểu đồ 6 đơn vị, gộp danh mục cha + nhóm "Khác", top 5, drill-down sang màn Giao dịch đã lọc, bảng màu định tính **không coral**, không bảng tổng hợp/cache); cập nhật `wiki-knowledge/concept/` (Design system: token `chartPalette` light/dark; Lộ trình phát triển: màn `01` xong, còn `02`/`03`/`04` + bộ lọc nâng cao; Stack kỹ thuật: `fl_chart` đã dùng cả `BarChart` lẫn `PieChart`) + append `wiki-knowledge/log.md` + cập nhật `wiki-knowledge/index.md`

---

## Sơ đồ phụ thuộc

```text
Setup (T001–T002)
   ↓
Foundational (T003–T011)  ← chặn MỌI user story: DateRange, chartPalette, khóa dịch, report_view.dart
   ↓
US1 P1 (T012–T019)  ← MVP: controller + deps + khung màn + segmented + 2 số tổng + hàng Ngân sách
   ├──→ US2 P2 (T020–T023)  biểu đồ cột (cần thẻ + `view.bars` của US1)
   ├──→ US3 P3 (T024–T027)  vòng tròn phân bổ + drill-down (cần US1)
   ├──→ US4 P4 (T028–T030)  top danh mục (cần US1)
   └──→ US5 P5 (T031–T035)  trạng thái rỗng + nạp lại sau FAB (cần US1, và cần 3 thẻ của US2/US3/US4 để "rỗng" có nghĩa)
   ↓
Polish (T036–T042)
```

- **US2, US3, US4 độc lập nhau** về logic thuần (đã xong ở Foundational) nhưng **cùng sửa** `lib/screens/report_screen.dart` và `test/report_screen_test.dart` ⇒ thi công **tuần tự**, không chạy song song (T020/T024/T028 ghi vào cùng file).
- **US5 phụ thuộc US2+US3+US4** vì trạng thái rỗng là hành vi *của* 3 thẻ đó.
- Trong Foundational: T004/T005 chạy song song được với nhau và với T003 (khác file); T006–T010 **tuần tự** (cùng `report_view.dart`, T006 viết test trước).

## Ví dụ chạy song song

```text
# Pha 1 — Setup:
T002 [P] khảo sát API PieChart (chỉ đọc package cache) — chạy cùng lúc T001 được nếu không chờ kết quả analyze

# Pha 2 — Foundational (3 file khác nhau):
T003 tách DateRange → lib/core/date_range.dart + budget_view.dart
T004 [P] chartPalette → lib/theme/sora_colors.dart
T005 [P] khóa dịch EN → lib/core/locale/sora_translations.dart

# Pha 3 — US1 (2 file mới khác nhau):
T013 [P] [US1] report_controller.dart
T014 [P] [US1] report_deps.dart
```

## Chiến lược triển khai

- **MVP đề xuất: chỉ User Story 1** (T001–T019) — sau pha này màn Tổng quan đã *dùng được*: mở tab Báo cáo thấy đúng khu đầu màn, 4 kỳ, 2 số tổng đã loại transfer, giữ lối vào Ngân sách (SC-001/SC-002 một phần, SC-003/SC-004 đầy đủ).
- **Giao hàng tăng dần**: US1 → US2 (biểu đồ) → US3 (phân bổ + drill-down, đây là story nặng thứ hai sau US1) → US4 (top) → US5 (trạng thái rỗng + làm mới) → Polish (QA tay A–L + wiki). Mỗi pha kết thúc bằng `flutter analyze` + test xanh ⇒ là một bản release được.
- **Thứ tự bắt buộc**: Foundational **phải** xong trước US1 (T011 là cổng chốt); US2/US3/US4 sau US1; US5 sau cả 3 thẻ.
