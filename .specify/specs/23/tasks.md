# Danh sách Task: Chi tiết theo danh mục (màn 02 Báo cáo)

**Mã PBI**: 23
**Nguồn**: spec.md, plan.md, data-model.md, research.md, quickstart.md
**Ghi chú phạm vi**: chỉ màn **02 (Chi tiết theo danh mục)** — không schema mới (giữ drift **v7**), không migration, không `build_runner`, không dependency mới (tái dùng `fl_chart` sẵn có), không sửa `app_shell.dart`, không sửa `sora_colors.dart`.

## Định dạng task

`- [ ] [MãTask] [P?] [Story?] Mô tả kèm đường dẫn file`

- `[P]`: có thể chạy song song (khác file, không phụ thuộc task chưa xong)
- `[Story]`: bắt buộc ở pha User Story (VD `[US1]`), không dùng ở Setup/Foundational/Polish

---

## Pha 1: Setup

- [X] T001 Chạy `flutter pub get` + `flutter analyze` + `flutter test` tại `app/sora_thu_chi/` để chốt baseline (**657 test**, ghi nhận test đỏ **có sẵn** ở `test/transactions_dao_test.dart` nếu còn) và xác nhận `fl_chart` + `PieChart` đã có sẵn từ PBI 22 — **không** sửa `app/sora_thu_chi/pubspec.yaml`, **không** chạy `build_runner`
- [X] T002 [P] Đọc lại cách dựng `PieChart`/`PieChartSectionData`/`PieTouchData` đang chạy ở `app/sora_thu_chi/lib/screens/report_screen.dart` (PBI 22) để chốt đúng tham số `centerSpaceRadius`/`radius`/`sectionsSpace`/`touchCallback` dùng ở T012 — nếu API khác dự kiến thì ghi nhận trước khi thi công

## Pha 2: Foundational

*(Bắt buộc xong trước mọi user story: 2 thực thể logic + 3 hàm thuần + khóa dịch + method controller)*

- [X] T003 Thêm `class ReportCategoryRow` (`int? categoryId`, `String name`, `int amount`, `int percent`, `int rank`; `-1` = "Khác") và `class ReportCategoryDetail` (`ReportPeriod period`, `DateRange range`, `int total`, `bool hasAnyTxn`, `List<ReportCategoryRow> rows`, getter `bool get isEmpty => total == 0`) vào `app/sora_thu_chi/lib/core/report/report_view.dart` — data-model §1.1/§1.2, FR-006/FR-013
- [X] T004 Thêm hàm thuần `ReportCategoryDetail reportCategoryDetail({required List<Transaction> transactions, required List<Category> categories, required ReportPeriod period, required DateTime now})` vào `app/sora_thu_chi/lib/core/report/report_view.dart`: **tái dùng** `_breakdown` cùng file nhưng **bỏ** `.take(5)`, thêm dòng **"Khác"** (`categoryId == null`) **xếp cuối** khi có tiền chi không gắn danh mục, chia `percent` bằng `percentSplit` trên **toàn bộ** dòng, `rank` = chỉ số sau sắp xếp ("Khác" = `-1`), cờ `hasAnyTxn` tính từ chính danh sách giao dịch + `range` — FR-006…FR-010, data-model luật 1–19, R2/R7
- [X] T005 Thêm `String reportPeriodChipLabel(ReportPeriod period, DateRange range)` (`Ngày 12/09/2026` · `Tuần 07/09–13/09/2026` — năm theo **ngày cuối kỳ** · `Tháng 9/2026` · `Năm 2026`) và `String reportExpenseCenterLabel(ReportPeriod period)` (`Tổng chi ngày/tuần/tháng/năm`) vào `app/sora_thu_chi/lib/core/report/report_view.dart`, ghép **danh từ kỳ đã có bản dịch** với chuỗi ngày không phụ thuộc ngôn ngữ — FR-003/FR-004, R3
- [X] T006 [P] Thêm **7 khóa dịch** EN vào `app/sora_thu_chi/lib/core/locale/sora_translations.dart`, mục "Báo cáo (PBI 23) — màn Chi tiết `02`": `'Chi tiêu theo danh mục'`, `'DANH MỤC (@n)'`, `'Tổng chi ngày'`, `'Tổng chi tuần'`, `'Tổng chi tháng'`, `'Tổng chi năm'`, `'Chạm vào một danh mục để xem các giao dịch'` — FR-018, R8 (dùng lại `'Xem tất cả'`, `'Khác'`, `'Tổng chi'`, 4 danh từ kỳ, 2 thông điệp rỗng — **không** thêm nữa)
- [X] T007 Thêm method `ReportCategoryDetail? categoryDetail()` vào `app/sora_thu_chi/lib/core/report/report_controller.dart`: trả `null` khi `!_loaded`, ngược lại gọi `reportCategoryDetail(transactions: _transactions, categories: _categories, period: period.value, now: _now)` — **không** thêm Rx state, **không** đọc DB, **không** đổi `load()`/`setPeriod()` — FR-015, R1
- [X] T008 Mở rộng `app/sora_thu_chi/test/report_view_test.dart`: `reportCategoryDetail` (**7 danh mục → đủ 7 dòng**, không cắt 5; `Σ amount == total`; `Σ percent == 100`; "Khác" **cuối** và **chỉ** khi có tiền chi không gắn danh mục; gộp con → cha; danh mục **ẩn** vẫn tính; con mồ côi nhóm theo chính nó; đồng hạng → tên tăng dần; `rank` = chỉ số và "Khác" = `-1`; 1 danh mục → 1 dòng 100%; kỳ chỉ Thu / chỉ transfer → `total == 0` + `hasAnyTxn` đúng; kỳ rỗng → `rows` rỗng), `reportPeriodChipLabel` (4 kỳ + tuần vắt qua tháng + tuần vắt qua năm) và `reportExpenseCenterLabel` (4 kỳ); số liệu tính theo `now` **bơm tham số** (`DateTime(2026, 3, 15)` như test PBI 22), dùng `FakeWalletRepository.withCategories(...)` — R9, data-model §2
- [X] T009 Cổng chốt Foundational: chạy `flutter test test/report_view_test.dart test/sora_translations_test.dart` tại `app/sora_thu_chi/` → toàn bộ **xanh** trước khi vào user story

## Pha 3: User Story 1 — Mở màn Chi tiết và xem phân bổ đầy đủ (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: từ thẻ "Top danh mục chi tiêu" ở màn Tổng quan, chạm **"Xem tất cả"** (1 lần chạm) → màn **Chi tiêu theo danh mục** mở ra với app bar teal + back (không bottom nav), chip kỳ tĩnh kế thừa kỳ đang xem, vòng tròn phân bổ có **tổng chi ở giữa**, tiêu đề nhóm `DANH MỤC (n)` và **đầy đủ** mọi danh mục chi của kỳ (chấm màu theo thứ hạng, tên, số tiền, %, thanh tiến độ) + dòng gợi ý cuối màn.
**Tiêu chí kiểm thử độc lập**: mở tab Báo cáo ở kỳ Tháng có ≥ 7 danh mục chi → chạm "Xem tất cả" → đối chiếu mockup `docs/report/man-hinh-02-chi-tiet-danh-muc.svg` (trừ khác biệt cố ý: chip kỳ **không** mũi tên); đếm đủ số dòng, `n` khớp số dòng, cộng tay tiền/`%` khớp số giữa vòng tròn; chạm back → về màn Tổng quan **vẫn kỳ cũ**.

- [X] T010 [US1] Tạo khung màn `app/sora_thu_chi/lib/screens/report_category_detail_screen.dart`: `StatelessWidget { ValueChanged<int>? onSelectTab }`, đọc `ensureReportController()` + `categoryDetail()`, toàn thân bọc `Obx`, ngoài cùng `SubPageScaffold(title: 'Chi tiêu theo danh mục'.tr, child: ...)` (app bar teal + back sẵn có, **không** bottom nav, **không** FAB), thân `ListView` (`padding` đáy 24); `detail == null` ⇒ `SizedBox.shrink()` — FR-002/FR-015, plan.md §Kiến trúc 3
- [X] T011 [US1] Dựng **chip kỳ** trong `app/sora_thu_chi/lib/screens/report_category_detail_screen.dart`: `Container` bo `15px`, nền `softCardBg`, chữ `textPrimary` w600, nội dung `reportPeriodChipLabel(detail.period, detail.range)`, `ValueKey('report-detail-chip')` — **nhãn tĩnh**: **không** `InkWell`, **không** mũi tên, **không** menu chọn kỳ (khác mockup — quyết định đã chốt) — FR-003
- [X] T012 [US1] Dựng **vòng tròn phân bổ** trong `app/sora_thu_chi/lib/screens/report_category_detail_screen.dart`: ô `200×200` giữa màn, `PieChart` (`sectionsSpace: 2`, `centerSpaceRadius` ≈ 52, `radius` ≈ 30, `showTitle: false`, màu = `SoraColors.chartPalette[rank < 0 ? 5 : rank % 5]`, `PieTouchData.touchCallback` → drill-down như chạm dòng) + `Stack` nhãn giữa gồm `reportExpenseCenterLabel(detail.period)` (nhỏ, `textSecondary`) và `formatMoney(detail.total)` (`FittedBox(fit: scaleDown)`, `textPrimary` w700), `ValueKey('report-detail-donut')` — FR-004/FR-007, R4
- [X] T013 [US1] Dựng **tiêu đề nhóm + các dòng danh mục** trong `app/sora_thu_chi/lib/screens/report_category_detail_screen.dart`: tiêu đề `DANH MỤC (@n).trParams({'n': '${detail.rows.length}'})` (chữ hoa, `tabInactive`, có đường phân cách phía trên) rồi mỗi dòng `InkWell` (`ValueKey('report-detail-row-<id|other>')`) chứa `Row`: chấm tròn 10px màu `chartPalette[rank < 0 ? 5 : rank % 5]` + `Expanded(Column)` gồm hàng `[Expanded(Text(name, maxLines: 1, overflow: ellipsis)), Text(formatMoney(amount), w600)]`, dòng `'${percent}%'` (`textSecondary`, căn phải) và `ClipRRect(LinearProgressIndicator(value: percent / 100, minHeight: 4))` **cùng màu** với chấm (màu lấy từ đúng một biến `rank` ⇒ SC-007 tự đúng); phân cách bằng `Divider`/`Border` màu `listDivider` — FR-005/FR-006/FR-007/FR-020, data-model §4
- [X] T014 [US1] Dựng **dòng gợi ý cuối danh sách** trong `app/sora_thu_chi/lib/screens/report_category_detail_screen.dart`: `'Chạm vào một danh mục để xem các giao dịch'.tr` — chữ tĩnh, căn giữa, màu `tabInactive` (không phải nút) — FR-006, giả định spec
- [X] T015 [US1] Thêm điểm vào **"Xem tất cả"** trong `app/sora_thu_chi/lib/screens/report_screen.dart`: hàng tiêu đề `_TopCategoriesCard` thành `Row` gồm `Expanded(Text('Top danh mục chi tiêu'))` + khi `view.hasExpense` một `InkWell`/`TextButton` `ValueKey('report-see-all')` nội dung `'Xem tất cả'.tr` (màu `tealOnNeutral`, cỡ 12) → callback `onSeeAll` mới của thẻ → `Navigator.push(MaterialPageRoute(builder: (_) => ReportCategoryDetailScreen(onSelectTab: onSelectTab)))`; **không** đổi gì khác ở màn 01 (khu teal, 3 thẻ, drill-down cũ, `ValueKey` cũ) — FR-001, R6
- [X] T016 [P] [US1] Viết `app/sora_thu_chi/test/report_category_detail_screen_test.dart` (phần US1): vẽ màn → tiêu đề app bar, chip kỳ **đúng chuỗi**, nhãn giữa vòng tròn + số tiền, `DANH MỤC (n)` khớp số dòng, **đủ n** dòng, dòng gợi ý; **không** có bottom nav; ca English ⇒ **0** nhãn tiếng Việt còn sót (khôi phục `Get.locale` trong `addTearDown`, bài học PBI 19); dựng `TransactionController(fake)` qua `Get.put(...)` rồi `Get.reset()` trong `tearDown`; màn 02 là `home:` của `MaterialApp` trong test để `popUntil(isFirst)` không pop mất chính nó — R9
- [X] T017 [P] [US1] Mở rộng `app/sora_thu_chi/test/report_screen_test.dart`: thẻ Top có `'Xem tất cả'` khi kỳ có chi tiêu, **không** có khi thẻ rỗng; chạm → `find.byType(ReportCategoryDetailScreen)` xuất hiện — FR-001, R9

## Pha 4: User Story 2 — Chạm danh mục để xem các giao dịch tạo nên số tiền (Ưu tiên: P2)

**Mục tiêu**: chạm một dòng danh mục (hoặc lát cắt trên vòng tròn) → sang màn **Giao dịch** đã lọc sẵn theo **danh mục đó (gồm danh mục con)** trong **đúng khoảng thời gian của kỳ đang xem**, khớp **0 sai lệch** về số lượng và tổng tiền; dòng "Khác" **không** phản hồi khi chạm.
**Tiêu chí kiểm thử độc lập**: chạm "Ăn uống" → màn Giao dịch mở đúng tab, chip lọc Chi + khoảng ngày của kỳ + danh mục cha, tổng tiền khớp số của dòng vừa chạm; chạm "Khác" → không có gì xảy ra.

- [X] T018 [US2] Thêm hành vi **drill-down** trong `app/sora_thu_chi/lib/screens/report_category_detail_screen.dart` cho dòng danh mục **và** lát cắt (`categoryId != null`): dựng `TxnSearchFilter(now: controller.now, type: TxnTypeFilter.expense, datePreset: DatePreset.custom, dateStart: detail.range.start, dateEnd: detail.range.end.subtract(const Duration(days: 1)), categoryIds: {categoryId}, sort: SortOption.dateNewest)` → `ensureTransactionController().setFilter(filter)` → `Navigator.of(context).popUntil((r) => r.isFirst)` → `widget.onSelectTab?.call(1)` (bộ lọc PBI 12 tự mở rộng cha → con ⇒ SC-006 khớp 0 đ) — FR-011, R5
- [X] T019 [US2] Chốt **dòng "Khác" không chạm được** trong `app/sora_thu_chi/lib/screens/report_category_detail_screen.dart`: `onTap: null` khi `categoryId == null` (`ValueKey('report-detail-row-other')`) — **không** đổi bộ lọc, **không** đổi tab — FR-012, R5
- [X] T020 [US2] Bổ sung vào `app/sora_thu_chi/test/report_category_detail_screen_test.dart` (phần US2): chạm dòng danh mục → `TransactionController.activeFilter` đúng (Chi + `dateStart`/`dateEnd` của kỳ + `categoryIds = {cha}`) **và** `onSelectTab(1)` được gọi; chạm dòng **"Khác"** → **không** đổi bộ lọc, **không** gọi `onSelectTab` — R9, FR-011/FR-012

## Pha 5: User Story 3 — Kỳ không có chi tiêu (Ưu tiên: P3)

**Mục tiêu**: kỳ rỗng (hoặc chỉ chuyển khoản nội bộ) và kỳ chỉ có Thu đều hiện **trạng thái rỗng toàn màn** với thông điệp phân biệt — **không** vẽ vòng tròn rỗng, **không** hiện tiêu đề nhóm rỗng.
**Tiêu chí kiểm thử độc lập**: mở màn 02 ở một tháng trống / tháng chỉ có Thu / tháng chỉ có chuyển khoản → thấy đúng thông điệp tương ứng, không có `PieChart`.

- [X] T021 [US3] Thêm **trạng thái rỗng** trong `app/sora_thu_chi/lib/screens/report_category_detail_screen.dart`: `detail.total == 0` ⇒ `Center` thông điệp `detail.hasAnyTxn ? 'Chưa có chi tiêu nào trong kỳ này'.tr : 'Chưa có giao dịch nào trong kỳ này'.tr` (khóa **đã có**), `ValueKey('report-detail-empty')` — **không** dựng chip/vòng tròn/tiêu đề nhóm/danh sách — FR-013/FR-014, R7
- [X] T022 [US3] Bổ sung vào `app/sora_thu_chi/test/report_category_detail_screen_test.dart` (phần US3): 3 ca — kỳ rỗng, kỳ chỉ Thu, kỳ chỉ transfer → thấy `report-detail-empty` + đúng thông điệp, **không** có `PieChart` — R9, SC-010

## Pha cuối: Polish & Cross-cutting

- [X] T023 [P] Thêm ca smoke **theme tối** cho màn 02 vào `app/sora_thu_chi/test/dark_theme_smoke_test.dart`: pump màn 02 (có dữ liệu) ở chế độ Tối → không overflow, token tối thật sự áp — FR-019, SC-012
- [X] T024 Chạy `flutter analyze` + `flutter test` toàn bộ tại `app/sora_thu_chi/` → **0 lỗi analyze**, **không đỏ test cũ** (chỉ còn test đỏ **có sẵn** đã ghi ở T001, nếu có)
- [X] T025 QA tay trên emulator theo `quickstart.md` nhóm **A–L** (điểm vào/bố cục/quay về, chip kỳ + nhãn giữa, danh sách đầy đủ + màu thặng dư chu kỳ, số khớp, gộp con + "Khác", drill-down, trạng thái rỗng, làm mới số liệu, Tối + English, màn hình nhỏ + cỡ chữ lớn + số hàng tỉ, offline/hiệu năng, biên kỳ & ngày) — ghi lại kết quả từng nhóm
- [X] T026 Tick checklist `.specify/specs/23/checklists/requirements.md` sau khi thi công xong (**giữ nguyên nội dung** đã duyệt)
- [X] T027 Đồng bộ wiki theo skill `sora-wiki`: cập nhật `wiki-knowledge/entity/` **Báo cáo** (màn `02`: chip kỳ nhãn tĩnh, vòng tròn + danh sách **đầy đủ** mọi danh mục, màu định tính **lặp chu kỳ** 5 màu + xám cho "Khác", drill-down `popUntil` + đổi tab, 2 trạng thái rỗng, số liệu dựng từ bản chụp RAM), `wiki-knowledge/concept/` **Lộ trình phát triển** (màn `02` xong; còn `03` So sánh kỳ / `04` Xuất báo cáo + bộ lọc nâng cao) và **Design system** (bảng màu định tính dùng theo **thứ hạng, lặp chu kỳ**; khác biệt cố ý với mockup `02`) + append `wiki-knowledge/log.md` + cập nhật `wiki-knowledge/index.md`
- [X] T028 Commit PBI 23 theo skill `git-commit` (Conventional Commits, message tiếng Việt có dấu, **không** trailer `Co-Authored-By`)

---

## Sơ đồ phụ thuộc

```text
Setup (T001–T002)
   ↓
Foundational (T003–T009)  ← chặn MỌI user story: 2 thực thể + 3 hàm thuần + 7 khóa dịch + categoryDetail()
   ↓
US1 P1 (T010–T017)  ← MVP: khung màn 02 + chip kỳ + vòng tròn + danh sách đầy đủ + dòng gợi ý + điểm vào "Xem tất cả"
   ├──→ US2 P2 (T018–T020)  drill-down sang màn Giao dịch (cần màn 02 đã vẽ dòng để chạm)
   └──→ US3 P3 (T021–T022)  trạng thái rỗng (cần khung màn 02 của US1; độc lập với US2)
   ↓
Polish (T023–T028)  ← T023 độc lập; T024 chốt sau khi US1–US3 xong; T025 QA tay; T026–T028 bàn giao
```

- **US2 và US3 độc lập nhau** về logic nhưng **cùng sửa** `lib/screens/report_category_detail_screen.dart` và `test/report_category_detail_screen_test.dart` ⇒ thi công **tuần tự**, không chạy song song.
- **US1 là cổng**: US2/US3 đều cần khung màn 02 + danh sách dòng đã dựng.
- Trong Foundational: T003 → T004 → T005 **tuần tự** (cùng `report_view.dart`); T006 [P] (file dịch) chạy song song được với T003–T005; T007 phụ thuộc T004; T008 phụ thuộc T003–T005; T009 là cổng chốt.
- Trong Polish: T023 [P] chạy cùng lúc với T024–T025 được (khác file).

## Ví dụ chạy song song

```text
# Pha 1 — Setup:
T002 [P] đọc cách dựng PieChart ở report_screen.dart — chạy cùng T001 nếu không chờ kết quả test

# Pha 2 — Foundational (khác file):
T003 → T004 → T005  report_view.dart (tuần tự)
T006 [P]            lib/core/locale/sora_translations.dart

# Pha 3 — US1 (2 file test khác nhau):
T016 [P] [US1] test/report_category_detail_screen_test.dart
T017 [P] [US1] test/report_screen_test.dart

# Pha cuối:
T023 [P] test/dark_theme_smoke_test.dart
```

## Chiến lược triển khai

- **MVP đề xuất: chỉ User Story 1** (T001–T017) — sau pha này màn 02 đã *dùng được*: mở từ "Xem tất cả", chip kỳ tĩnh, vòng tròn có tổng chi ở giữa, danh sách **đầy đủ** mọi danh mục với chấm màu theo thứ hạng + % + thanh tiến độ (SC-001…SC-004, SC-007 phần lớn đạt).
- **Giao hàng tăng dần**: US1 → US2 (drill-down, chốt SC-006) → US3 (trạng thái rỗng, chốt SC-010) → Polish (theme tối/English đã có test ở US1, QA tay A–L, wiki, commit). Mỗi pha kết thúc bằng `flutter analyze` + test xanh ⇒ là một bản release được.
- **Thứ tự bắt buộc**: Foundational phải xong trước US1 (T009 là cổng chốt); US2/US3 sau US1 và **tuần tự** với nhau (cùng file); Polish sau khi cả 3 story xong.
- **Rủi ro cần để mắt khi thi công**: lệch số giữa dòng và màn Giao dịch với dữ liệu cũ `categoryId == null` (Rủi ro 1 plan.md — ghi nhận, **không** sửa bộ lọc PBI 12 trong PBI này); màu trùng giữa hai hạng khi > 5 danh mục (đã chốt, phân biệt bằng tên + thứ tự); nhãn giữa vòng tròn với số hàng tỉ (giảm `centerSpaceRadius`/cỡ chữ — **một chỗ** trong màn 02).
