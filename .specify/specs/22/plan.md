# Kế hoạch triển khai: Báo cáo tổng quan (tab Báo cáo)

**Mã PBI**: 22
**Liên kết spec**: [.specify/specs/22/spec.md](./spec.md)
**Ngày tạo**: 2026-09-12

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12 / Flutter (Android + iOS), app **offline hoàn toàn** |
| Framework / Thư viện chính | GetX `^4.7.3` (điều hướng + DI + i18n), Material; biểu đồ dùng **`fl_chart ^1.2.0`** — **đã dùng thật ở PBI 21** (cột) và đã có trong `pubspec.yaml` ⇒ đợt này thêm `PieChart`, **không sửa pubspec** |
| Lưu trữ dữ liệu | drift `^2.34.4` + sqlite local — **schema giữ nguyên v7** (PBI 21): **không** thêm bảng/cột, **không** migration, **không** chạy `build_runner` |
| Kiểm thử | `flutter_test` — 597 test hiện có; bổ sung **3 file test mới**, sửa **2 file test** (widget shell + smoke tối); mục tiêu **không đỏ test cũ** |
| Nền tảng triển khai | Build local (`flutter build apk` / iOS build) — không server, không CI đặc thù |
| Ràng buộc hiệu năng | Nạp **một lần** khi mở tab (`allTransactions()` + `categoriesIncludingHidden(expense)`) rồi tính mọi kỳ trên cùng danh sách trong RAM; đổi kỳ **không** đọc DB (SC-007 < 1 giây). Không snapshot, không bảng tổng hợp |
| Ràng buộc khác | Ngôn ngữ giao diện/tài liệu/commit: **tiếng Việt có dấu**; bám Design System (teal `#0F6E56` = hành động/trạng thái chọn; coral `#D85A30` **chỉ** cho chi tiêu/cảnh báo — nhãn "Tổng chi" ở khu đầu màn là **nhãn**, không phải màu; vòng tròn dùng **bảng màu định tính riêng**, không coral); mọi màu đi qua token `AppColors`/`SoraColors` để chạy đúng dark mode (PBI 18); mọi nhãn tĩnh phải có bản dịch EN (PBI 19) |
| Nguồn chân lý nghiệp vụ | `docs/report/bao-cao-thong-ke-giai-phap.md` (§2.2 loại trừ transfer, §3.1 tổng quan, §3.2 phân bổ, §3.5 top danh mục, §5 bảng màu định tính, §8 biên) + mockup `docs/report/man-hinh-01-bao-cao-tong-quan.svg`; kế thừa `research.md` PBI 21 (mốc kỳ, mẹo `dateEnd` của bộ lọc) |

*Không còn mục `NEEDS CLARIFICATION`: spec đã "Đã làm rõ" (3 quyết định chốt 2026-09-12); các quyết định còn lại là chi tiết triển khai — xem `research.md` (R1…R12).*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

`.specify/memory/constitution.md` **không tồn tại** (repo chưa tạo hiến pháp) ⇒ đối chiếu theo `CLAUDE.md` của repo và các quyết định đã chốt trong `docs/`.

| Nguyên tắc (nguồn: CLAUDE.md + docs) | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline hoàn toàn, không server/không auth | ✅ | Chỉ **đọc** sqlite local; biểu đồ vẽ từ dữ liệu trên máy; tắt mạng vẫn đủ số liệu (QA nhóm K) |
| Ngôn ngữ giao diện/tài liệu/commit: tiếng Việt có dấu | ✅ | Mọi nhãn, tài liệu, comment, commit của PBI này bằng tiếng Việt |
| Stack đã chốt (drift + GetX + fl_chart) | ✅ | `fl_chart` (`BarChart` + `PieChart`) và GetX đều đã có; **không thêm dependency**, không sửa `pubspec.yaml` |
| Design system: 1 màu thương hiệu teal, coral chỉ cho chi/cảnh báo, không hex cứng trong widget | ⚠️ có lý do | Vòng tròn cần **bảng màu định tính riêng** (doc §5: teal, teal đậm nhạt, hổ phách, xanh lam nhạt, xám) — 5 mã màu **chưa có token** trong `AppColors`. **Xử lý**: khai báo thành **token theme** `SoraColors.chartPalette` (đúng tinh thần "màu đi qua token", chạy được dark mode), **không** rải hex trong widget. Cột biểu đồ + 2 số tổng vẫn dùng token teal/coral sẵn có |
| Số dư ví là đại lượng suy ra, không sửa tay | ✅ | Màn chỉ đọc; không ghi bất kỳ bảng nào |
| Thu/chi/chuyển khoản: transfer không tính là thu/chi | ✅ | **Một** phép lọc duy nhất (`reportTotals`) loại `transfer` + `adjustment`; dùng cho 2 số tổng, 6 cột, phân bổ, top (FR-004/SC-004) |
| Màn cấp tab: nằm trong app shell, **có** bottom nav | ✅ | Màn Tổng quan Báo cáo thay chỗ `ReportScreen` hiện tại trong `IndexedStack`; bottom nav do shell giữ (không tự dựng như màn Ngân sách) |
| Không sửa dữ liệu người dùng ngoài phạm vi | ✅ | Chỉ **đọc** `transactions` + `categories`; không đụng `wallets`/`budgets` |
| Không phá vỡ hành vi PBI trước | ✅ | Điểm vào "Ngân sách" giữ nguyên (FR-017); bộ lọc màn Giao dịch chỉ **đặt**, không đổi ngữ nghĩa (tái dùng hạ tầng PBI 12) |
| Quy trình PBI: spec → plan → task → implement | ✅ | Đang ở bước plan; `tasks.md` sinh ở bước sau |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại [research.md](./research.md). Tóm tắt các quyết định chính:

- **Cách nạp dữ liệu (R1)** — **Quyết định**: `ReportController` (GetX, khuôn `TransactionController`) + seam `report_deps.dart`; `AppShell` gọi `load()` khi chọn tab **Báo cáo**. **Lý do**: `ReportScreen` sống trong `IndexedStack` từ boot ⇒ `initState` **không** chạy lại khi đổi tab, mà FR-016/kịch bản 12 đòi tính lại lúc **mở màn**. **Phương án khác**: `StatefulWidget` + `GlobalKey` (ít dòng nhưng phá nếp đang có); nạp trong `initState` (trượt FR-016).
- **Mô hình kỳ (R2)** — **Quyết định**: module thuần `core/report/report_view.dart`; kỳ dương lịch nửa mở `[start, end)`; tuần bắt đầu **Thứ Hai**; biểu đồ = **6 đơn vị liên tiếp** kết thúc ở kỳ đang chọn. **Lý do**: FR-021/FR-006 + kế thừa quy ước `resolveDatePreset`/`budgetPeriodRange`. **Phương án khác**: tái dùng `DatePreset` (thiếu "Năm").
- **Chỗ ở `DateRange` (R3)** — **Quyết định**: tách sang `lib/core/date_range.dart`, `budget_view.dart` **re-export** (không file nào phải sửa). **Lý do**: kiểu dùng chung 2 module, tránh phụ thuộc sai hướng report→budget. **Phương án khác**: import `budget_view.dart show DateRange`; tự định nghĩa kiểu trùng.
- **Bảng màu vòng tròn (R4)** — **Quyết định**: `SoraColors.chartPalette` (6 màu, **đổi theo theme**): 4 mã mockup (teal `#0F6E56`, teal đậm nhạt `#3D8C77`, hổ phách `#E3B341`, xanh lam nhạt `#6B7FD7`) + xám `#B4B2A9` cho hạng 5 + **xám đậm riêng cho "Khác"**; gán **cố định theo thứ hạng**. **Lý do**: FR-011 + vòng tròn có thể tới 6 lát; **cấm coral**; token theme để đạt tương phản dark (SC-011). **Phương án khác**: dùng `category.color` (trái FR-011); để hex bất biến (trượt SC-011).
- **Tổng % = 100 (R5)** — **Quyết định**: chia % theo **phần dư lớn nhất** (largest remainder). **Lý do**: FR-009/SC-005 đòi tổng đúng 100 và từng dòng khớp tỉ lệ thật. **Phương án khác**: lát cuối/"Khác" hấp thụ phần dư (±3% vào một dòng).
- **Gộp danh mục con & "Khác" (R6)** — **Quyết định**: gom theo **danh mục cha**; **"Khác"** = ngoài top 5 + tiền chi **không gắn danh mục**, luôn xếp cuối, chỉ hiện khi có phần dư. **Lý do**: FR-009/FR-010 + biên spec. **Phương án khác**: tách theo danh mục con (ngoài phạm vi); bỏ giao dịch `categoryId == null` (làm tổng lát ≠ tổng chi).
- **Chạm danh mục → màn Giao dịch (R7)** — **Quyết định**: đặt `TxnSearchFilter` (Chi + khoảng kỳ + `categoryIds = {id cha}`) rồi `onSelectTab(1)`; **không** `popUntil` (màn Báo cáo *là* tab). **Lý do**: bộ lọc PBI 12 **tự mở rộng cha → con** ⇒ SC-006 khớp 100%. **Phương án khác**: tự đẩy màn Giao dịch thứ hai. **Nhóm "Khác"**: không có đích (không bộ lọc danh mục nào tái lập đúng nhóm gộp).
- **Biểu đồ (R8)** — **Quyết định**: `fl_chart` `BarChart` (**chạm cột → tooltip số tiền**, FR-007) + `PieChart` (`centerSpaceRadius` + `Stack` cho nhãn "Tổng chi" giữa vòng tròn). **Lý do**: dependency đã cài, PBI 21 đã dùng thành công. **Phương án khác**: tự vẽ `CustomPaint` (chỉ dùng nếu API vỡ — Rủi ro 1).
- **Tầng dữ liệu (R9)** — **Quyết định**: **không** đổi schema (giữ **v7**), **không** thêm method `WalletRepository`, **không** bảng tổng hợp/cache. **Lý do**: mọi số liệu là đại lượng **tính toán**; SC-007 đặt ngưỡng < 1 giây trên dữ liệu vài nghìn dòng. **Phương án khác**: `report_monthly_summary` + upsert (doc §2.2 — tối ưu sớm, đụng mọi đường ghi giao dịch).
- **Trạng thái rỗng (R10)** — **Quyết định**: xét theo **kỳ đang chọn** (không theo cửa sổ 6 đơn vị); 2 thông điệp: "không có giao dịch" (cả 3 thẻ) vs "không có chi tiêu" (thẻ phân bổ + top). **Lý do**: FR-014 nói "kỳ đang chọn"; FR-006 vẫn đòi đủ 6 cột. **Phương án khác**: xét rỗng theo cả cửa sổ (che mất biểu đồ thật).
- **Làm mới sau FAB (R11)** — **Quyết định**: `AppShell._openAddTransaction` nạp lại controller báo cáo **khi tab đang chọn là Báo cáo**. **Lý do**: FAB hiện trên mọi tab; không nạp lại thì số liệu cũ ngay trước mắt. **Phương án khác**: chỉ dựa vào nạp-khi-chọn-tab (hở đúng đường này).
- **Widget dùng chung (R12)** — **Quyết định**: tái dùng `ScreenHeader` (tham số `bottom` **đã có**), `categoryIcon`, `formatMoney`; dựng **cục bộ** segmented control + thanh tiến độ thẻ top (~15 dòng mỗi cái). **Lý do**: repo chưa có 2 widget này dùng chung; tách thanh tiến độ của ngân sách ra sẽ chạm 2 màn + 2 bộ test cho 12 dòng.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem [data-model.md](./data-model.md) — **không đổi schema**; 5 thực thể logic (`ReportPeriod`+`DateRange`, `ReportBar`, `ReportSlice`, `ReportTopCategory`, `ReportView`) + **25 luật bất biến** (loại transfer, nửa mở, gộp cha, top 5 + "Khác", % = 100, cờ rỗng theo kỳ đang chọn) + bảng vòng đời "khi nào tính lại".
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app thuần nội bộ, không API/CLI/endpoint lộ ra ngoài (đồng nhất PBI 19/20/21). Hợp đồng nội bộ duy nhất là `WalletRepository` — **không đổi chữ ký**.
- **Kịch bản khởi động nhanh**: xem [quickstart.md](./quickstart.md) — **12 nhóm kiểm thử tay A–L**, phủ FR-001…FR-022 và SC-001…SC-013.

### Kiến trúc chi tiết

**1. Tầng nghiệp vụ thuần**

| File | Vai trò |
|---|---|
| `lib/core/date_range.dart` **(mới)** | Chuyển `DateRange` (khoảng **nửa mở** + `contains`) từ `budget_view.dart` sang — kiểu dùng chung 2 module (R3) |
| `lib/core/budget/budget_view.dart` **(sửa)** | Bỏ khai báo `DateRange`, thêm `export '../date_range.dart' show DateRange;` ⇒ mọi import cũ không đổi |
| `lib/core/report/report_view.dart` **(mới)** | Toàn bộ số liệu màn Tổng quan, **hàm thuần**: `enum ReportPeriod {day, week, month, year}` + `label`; `reportPeriodRange(period, anchor)`; `reportPeriodSeries(period, anchor, {count = 6})` → `List<DateRange>` (kỳ đang chọn ở **cuối**); `reportTotals(transactions, range)` → `({int income, int expense})` — **phép lọc duy nhất** loại transfer/adjustment; `List<int> percentSplit(List<int> amounts, int total)` (phần dư lớn nhất); `reportBarSeries({transactions, period, anchor, categories?})` → `List<ReportBar>`; `reportBreakdown({transactions, categories, range})` → `List<ReportSlice>` (gộp cha, top 5 + "Khác", sắp giảm dần ‑ đồng hạng theo tên); `reportTopCategories(...)` → `List<ReportTopCategory>` (≤ 5, **không** "Khác"); `class ReportBar/ReportSlice/ReportTopCategory`; `buildReportView({transactions, categories, period, now})` → `ReportView` (gom tất cả + cờ `hasAnyTxn`/`hasExpense`) |
| `lib/core/locale/sora_translations.dart` **(sửa)** | Thêm ~14 khóa EN dưới mục "Báo cáo (PBI 22)" (danh sách ở mục 4) |

**2. Trạng thái màn — `lib/core/report/report_controller.dart` (mới)**

- `ReportController(WalletRepository)` — `Rx<ReportPeriod> period` (mặc định `month`), `Rxn<ReportView> data`, `RxBool isLoading` (khởi đầu `false` — màn build sẵn offstage, bám `TransactionController`), `RxnString error`, `DateTime get now`.
- `Future<void> load({DateTime? now})`: đọc `allTransactions()` + `categoriesIncludingHidden(CategoryType.expense)` → dựng `data` bằng `buildReportView`. Lỗi ⇒ `error = 'Không đọc được dữ liệu báo cáo.'`, **giữ** `data` cũ (nếu có).
- `void setPeriod(ReportPeriod p)`: đổi `period` rồi **dựng lại `data` từ dữ liệu đã nạp trong RAM** — không đọc DB (SC-007).
- `lib/data/report_deps.dart` **(mới)**: `ensureReportController()` — khuôn `ensureTransactionController()` (dùng chung `ensureWalletRepository()` singleton).

**3. Màn `lib/screens/report_screen.dart` (viết lại — mockup `01`)**

- `StatelessWidget { ValueChanged<int>? onSelectTab }` (giữ nguyên chữ ký hiện có — `AppShell` không phải sửa chỗ dựng màn) — đọc `ensureReportController()`, toàn thân bọc `Obx`.
- `Column`: `ScreenHeader(title: 'Báo cáo', bottom: …)` — **vùng teal** chứa: segmented control 4 lựa chọn (mặc định **Tháng**, lựa chọn đang chọn = pill trắng + chữ teal) + hàng **2 số tổng** chữ trắng (mũi tên ↑ teal nhạt cho Thu, ↓ cho Chi). **Không** có `trailing` (nút lịch để PBI sau — FR-002).
- `Expanded` → 4 nhánh: **đang nạp lần đầu** (spinner) → **lỗi** (`error` + nút "Thử lại" gọi `load()`) → **nội dung** (`ListView`, `padding bottom 96`).
- Nội dung theo đúng thứ tự mockup:
  1. **Hàng điều hướng "Ngân sách"** — giữ nguyên widget `_EntryRow` + `ValueKey('report-entry-budget')` + `_openBudget()` như hiện tại (FR-017).
  2. **Thẻ "Dòng tiền 6 <đơn vị> gần đây"** — tiêu đề theo kỳ; chú giải **Thu** (chấm teal) / **Chi** (chấm coral); `BarChart` (`aspectRatio` ~1.6, `maxY` = max × 1.15), nhãn trục bằng `FlTitlesData`/`SideTitles`, cột teal = thu / coral = chi, `barTouchData` bật tooltip (`formatMoney`) — FR-007. Kỳ rỗng ⇒ `_EmptyCard('Chưa có giao dịch nào trong kỳ này')`.
  3. **Thẻ "Phân bổ chi tiêu theo danh mục"** — `Row`: `PieChart` (`centerSpaceRadius` ≈ 34, `sectionsSpace: 2`, không nhãn trên lát) + **`Stack`** phủ giữa vòng tròn nhãn **"Tổng chi"** + số tiền; bên phải `Expanded` danh sách chú giải (chấm màu `chartPalette`, tên, `@p%`). Chạm lát/dòng → `_openCategory(slice)`. Kỳ không có Chi ⇒ `_EmptyCard('Chưa có chi tiêu nào trong kỳ này')`.
  4. **Thẻ "Top danh mục chi tiêu"** — tối đa 5 dòng: bubble icon danh mục (màu danh mục) + tên + số tiền + **thanh tiến độ** cục bộ (một màu teal, `percent/100`). Rỗng ⇒ `_EmptyCard('Chưa có chi tiêu nào trong kỳ này')`.
- Hành vi:
  - **Đổi kỳ**: chạm lựa chọn → `controller.setPeriod(p)` (obx tự vẽ lại — FR-003).
  - **Chạm danh mục** (lát cắt hoặc dòng chú giải, `categoryId != null`): dựng `TxnSearchFilter(now: controller.now, type: expense, datePreset: custom, dateStart: view.range.start, dateEnd: view.range.end − 1 ngày, categoryIds: {categoryId}, sort: dateNewest)` → `ensureTransactionController().setFilter(f)` → `onSelectTab?.call(1)` (R7). Bấm nhóm **"Khác"** (`categoryId == null`): **không** làm gì.
  - **Giữ kỳ đang chọn** khi rời màn sang Ngân sách rồi quay lại: kỳ nằm trong controller singleton (kịch bản 17).
- `ValueKey`: `report-period-day|week|month|year`, `report-entry-budget` (giữ), `report-flow-chart`, `report-donut`, `report-slice-<id|other>`, `report-legend-<id|other>`, `report-top-<id>`.

**4. Dịch nhãn (FR-018)** — thêm vào `sora_translations.dart`, mục "Báo cáo (PBI 22)":

`'Ngày'` → Day · `'Tổng thu'` → Total income · `'Tổng chi'` → Total expense (`'Tổng chi'` dùng **cả** ở khu đầu màn **và** giữa vòng tròn) · `'Dòng tiền 6 ngày gần đây'` · `'… 6 tuần …'` · `'… 6 tháng …'` · `'… 6 năm …'` · `'Phân bổ chi tiêu theo danh mục'` · `'Top danh mục chi tiêu'` · `'Chưa có giao dịch nào trong kỳ này'` · `'Chưa có chi tiêu nào trong kỳ này'` · `'Không đọc được dữ liệu báo cáo.'` (11 khóa mới + các khóa **đã có** dùng lại: `'Tuần'/'Tháng'/'Năm'/'Thu'/'Chi'/'Khác'/'Ngân sách'/'Giới hạn chi tiêu theo danh mục'/'Thử lại'/'T@tháng'/'@năm'/'@ngày/@tháng'`). `sora_translations_test` tự quét literal `.tr` ⇒ thiếu khóa là đỏ.

**5. Khung app — `lib/core/app_shell.dart` (sửa 2 chỗ)**

| Chỗ | Thay đổi |
|---|---|
| `_onTabSelected` | `if (index == 1) ensureTransactionController().load();` **thêm** `if (index == 2) ensureReportController().load();` (FR-016/kịch bản 12 — R1) |
| `_openAddTransaction` | Sau khi lưu (`saved == true`): giữ `ensureTransactionController().load()`, **thêm** nạp lại controller báo cáo **khi** `_selectedIndex == 2` (R11) |

**6. Token màu — `lib/theme/sora_colors.dart` (sửa)**

- Thêm `final List<Color> chartPalette;` (6 phần tử: 5 hạng + "Khác").
- Light: `[0xFF0F6E56, 0xFF3D8C77, 0xFFE3B341, 0xFF6B7FD7, 0xFFB4B2A9, 0xFF5F5E5A]`
  Dark: `[0xFF3FA98A, 0xFF4FB694, 0xFFE3B341, 0xFF8B9DEE, 0xFFA8A8A3, 0xFFC9C7BE]`
- Cập nhật `copyWith` + `lerp` (lerp từng phần tử theo chỉ số — cùng độ dài cố định).
- QA nhóm J kiểm tương phản trên ảnh chụp (SC-011); lệch nhẹ ở dark thì chỉnh **một chỗ** trong bảng này.

**7. Test**

| File | Nội dung |
|---|---|
| `test/report_view_test.dart` **(mới)** | `reportPeriodRange`: Ngày/Tuần (**bắt đầu Thứ Hai**, Chủ Nhật vẫn thuộc tuần đó)/Tháng/Năm + biên nửa mở (đúng ngày `end` **không** thuộc kỳ). `reportPeriodSeries`: đủ **6**, kỳ đang chọn ở cuối, lùi đúng 1 đơn vị lịch qua mốc tháng/năm (VD 15/1 → 6 tháng = T8…T1), không lệch khi tháng 30/31 ngày. `reportTotals`: cộng đúng thu/chi, **loại** transfer + adjustment, giao dịch ngày tương lai vẫn tính. `reportBarSeries`: kỳ không có giao dịch → 2 cột 0 + vẫn có nhãn. `percentSplit`: `[1,1,1]` → `[34,33,33]` (tổng 100), `[1,2]` → `[33,67]`, tổng luôn 100 với 5–6 phần tử. `reportBreakdown`: gộp **con → cha**; ≤ 5 danh mục ⇒ **không** "Khác"; 6 danh mục ⇒ top 5 + "Khác" (cuối); tiền chi `categoryId == null` ⇒ vào "Khác"; danh mục **ẩn** vẫn tính; đồng hạng → tên tăng dần; `Σ tiền lát = reportTotals.expense`; `Σ % = 100`. `reportTopCategories`: ≤ 5, giảm dần, **không** có "Khác", `percent` = tỉ lệ trên tổng chi. `buildReportView`: cờ `hasAnyTxn`/`hasExpense` đúng cho 4 ca (rỗng / chỉ Thu / chỉ Chi / có transfer-only ⇒ rỗng) |
| `test/report_controller_test.dart` **(mới)** | `load` → `data != null` + `period` mặc định `month`; `setPeriod` → số liệu đổi **và** repository **không** bị gọi lại (đếm số lần gọi fake — SC-007); lỗi đọc (fake ném) → `error` + `data` giữ nguyên; `load(now:)` đổi mốc ⇒ kỳ tính lại theo mốc mới |
| `test/report_screen_test.dart` **(mới)** | Render: tiêu đề "Báo cáo", 4 lựa chọn kỳ + mặc định **Tháng**, "Tổng thu"/"Tổng chi" + số tiền, hàng "Ngân sách", 3 tiêu đề thẻ, chú giải Thu/Chi, nhãn "Tổng chi" giữa vòng tròn, dòng top có thanh tiến độ; **không** có icon lịch. Đổi kỳ: chạm **Năm** → tiêu đề "Dòng tiền 6 năm gần đây" + 2 số tổng theo năm. Chạm **dòng chú giải** danh mục → `TransactionController.activeFilter` đúng (Chi + `dateStart`/`dateEnd` của kỳ + `categoryIds` = {cha}) **và** `onSelectTab(1)` được gọi; chạm nhóm **"Khác"** → **không** đổi bộ lọc, **không** gọi `onSelectTab`. Trạng thái rỗng: kỳ rỗng → 3 thẻ rỗng; kỳ chỉ Thu → biểu đồ vẫn vẽ, 2 thẻ kia rỗng. English → không còn nhãn tiếng Việt. Lỗi đọc → thông báo + "Thử lại" |
| `test/widget_test.dart` **(sửa — nếu cần)** | Nhóm shell: xác nhận các khẳng định đang có vẫn đúng sau khi `ReportScreen` được viết lại (đếm chữ "Báo cáo" = 2: header + tab) và `pumpShell` vẫn chạy với `FakeWalletRepository` (controller báo cáo khởi tạo lúc boot, nạp khi chọn tab) |
| `test/dark_theme_smoke_test.dart` **(sửa)** | Thêm ca smoke: pump màn Tổng quan Báo cáo ở **theme tối** (có dữ liệu) → không overflow, token tối thật sự áp (SC-011/FR-019) |

Ghi chú test: test đụng `.tr` phải khôi phục `Get.locale` trong `addTearDown` (bài học PBI 19); test màn/controller dùng `FakeWalletRepository.withCategories(...)` ⇒ **không** cần sqlite native; mọi số liệu tính theo `now` **bơm tham số**, không dùng giờ thật; test chạm danh mục cần `Get.put(TransactionController(fake))` (hoặc `ensureTransactionController()` với repo fake đã đăng ký) rồi dọn `Get.reset()`; `Get.reset()` trong `addTearDown` cũng phải xoá `ReportController` (controller là singleton).

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline, không server | ✅ | Chỉ đọc sqlite local; cả 2 biểu đồ vẽ cục bộ |
| Không sửa dữ liệu người dùng ngoài phạm vi | ✅ | Không ghi bảng nào; `transactions`/`categories` chỉ đọc |
| Transfer & điều chỉnh không tính là thu/chi | ✅ | **Một** hàm `reportTotals` là nguồn duy nhất cho 2 số tổng, 6 cột, phân bổ và top; test khẳng định có ca transfer |
| Design system + dark mode | ⚠️ có lý do ⇒ ✅ | Bảng màu định tính **bắt buộc** bởi doc §5 (đã ghi ở mục "trước thiết kế"); triển khai thành token `SoraColors.chartPalette` (**theme-aware**), widget không hex cứng; teal/coral vẫn qua token |
| Màn cấp tab có bottom nav, màn con không | ✅ | Không đổi `AppShell`/`AppBottomNavBar`; màn Báo cáo vẫn là 1 trong 4 màn `IndexedStack` |
| i18n đầy đủ (PBI 19) | ✅ | 11 khóa mới; `sora_translations_test` quét tự động ⇒ thiếu khóa là đỏ; QA nhóm J gạch đầu dòng từng nhãn |
| YAGNI / không abstraction sớm | ✅ | Không bảng tổng hợp/cache, không migration, không dependency mới, không `Repository` mới, không widget dùng chung mới; **một** file module thuần + **một** controller (đúng chỗ, đúng khuôn có sẵn) |
| Không phá vỡ test/hành vi cũ | ✅ (cần kiểm chứng khi thi công) | `DateRange` re-export ⇒ 0 import phải sửa; `ReportScreen` giữ chữ ký + `ValueKey('report-entry-budget')`; `WalletRepository` không đổi; chỉ `widget_test`/`dark_theme_smoke_test` được chạm **nếu** khẳng định cũ vỡ |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── core/
│   │   ├── date_range.dart                        # MỚI — DateRange (khoảng nửa mở) dùng chung
│   │   ├── app_shell.dart                         # SỬA: nạp báo cáo khi chọn tab 2 + sau FAB
│   │   ├── budget/budget_view.dart                # SỬA: bỏ DateRange, re-export từ date_range.dart
│   │   ├── locale/sora_translations.dart          # SỬA: +11 khóa EN (Báo cáo PBI 22)
│   │   ├── report/report_view.dart                # MỚI — toàn bộ số liệu màn Tổng quan (thuần)
│   │   └── report/report_controller.dart          # MỚI — nạp + kỳ đang chọn (khuôn TransactionController)
│   ├── data/report_deps.dart                      # MỚI — ensureReportController()
│   ├── screens/report_screen.dart                 # VIẾT LẠI — màn 01 (header teal + 3 thẻ)
│   └── theme/sora_colors.dart                     # SỬA: +chartPalette (6 màu, light/dark)
└── test/
    ├── report_view_test.dart                      # MỚI
    ├── report_controller_test.dart                # MỚI
    ├── report_screen_test.dart                    # MỚI
    ├── widget_test.dart                           # SỬA (nếu khẳng định shell vỡ)
    └── dark_theme_smoke_test.dart                 # SỬA: +smoke màn Báo cáo ở theme tối
```

Không tạo `contracts/`: dự án thuần nội bộ, không có giao diện lộ ra ngoài.
Không đụng `lib/data/db/*` (schema giữ **v7**) và không chạy `build_runner`.

## Rủi ro & ngoại lệ có lý do

1. **`PieChart` lần đầu dùng trong repo** (`BarChart` đã dùng ở PBI 21 nhưng `PieChart`/`PieTouchData` chưa). API `fl_chart ^1.2.0` có thể khác ví dụ cũ (`PieChartData`/`PieChartSectionData`/`centerSpaceRadius`/`touchCallback`). **Giảm nhẹ**: dựng vòng tròn trong **một** widget riêng tư của `report_screen.dart` để đổi cách vẽ chỉ chạm 1 chỗ; `flutter analyze` bắt lỗi API ngay. **Phương án lùi đã cân nhắc**: tự vẽ vòng bằng `CustomPaint` + `Path`/`arcTo` (~40 dòng, không hiệu ứng chạm) — chỉ dùng nếu API vỡ không đáng sửa.
2. **Nhãn "Tổng chi" giữa vòng tròn**: `fl_chart` không có API vẽ chữ ở tâm ⇒ phải phủ `Stack`. Nếu bố cục lệch ở màn hình nhỏ, giảm `centerSpaceRadius`/cỡ chữ và **kiểm bằng QA nhóm J** (cỡ chữ lớn nhất).
3. **Tương phản bảng màu ở dark mode (SC-011)** là con số **đo bằng mắt/công cụ trên ảnh chụp**, không phải test tự động. **Giảm nhẹ**: bảng màu tập trung **một chỗ** (`SoraColors.dark.chartPalette`) ⇒ chỉnh 1 dòng nếu lệch; QA nhóm J kiểm.
4. **Giao dịch cũ `categoryId == null` nhưng tên danh mục khớp cha**: thẻ phân bổ xếp tiền đó vào **"Khác"** (đúng biên spec), còn màn Giao dịch khi lọc theo danh mục cha vẫn khớp theo **tên** (`_normalizedNames`, PBI 12) ⇒ tổng danh sách có thể **lớn hơn** số trên lát cắt (SC-006 lệch). **Giảm nhẹ**: chỉ xảy ra với dữ liệu nâng cấp từ **trước schema v4**; QA nhóm E dùng dữ liệu thật (luôn có `category_id`). Nếu gặp: chấp nhận là hành vi sẵn có của bộ lọc, ghi nhận chứ **không** sửa bộ lọc trong PBI này (sửa sẽ đổi hành vi màn Giao dịch/PBI 12).
5. **Chạm một cột hiện số tiền** phụ thuộc tooltip dựng sẵn của `fl_chart` (mặc định hiện giá trị; cần cấu hình để hiện **tiền đã định dạng**). **Giảm nhẹ**: `getTooltipItem` trả `formatMoney(...)`; test QA nhóm C mục 4 là điểm chốt FR-007.
6. **Chọn kỳ nằm trong controller dùng chung** ⇒ nếu tương lai có màn thứ hai đọc `ReportController`, kỳ sẽ dùng chung. **Giảm nhẹ**: hiện chỉ **một** màn dùng; ghi nhận, khi cần màn thứ hai thì tách kỳ ra tham số màn.
7. **`ReportController` khởi tạo ngay lúc boot** (vì `ReportScreen` build trong `IndexedStack`) ⇒ `pumpShell` trong test phải có `WalletRepository` đã đăng ký trước (đã đúng: `widget_test.pumpShell` `Get.put(FakeWalletRepository())`). **Giảm nhẹ**: dòng chú thích trong `report_deps.dart` + giữ nguyên `pumpShell`.
8. **`DateRange` chuyển file** có thể làm lộ import thiếu ở file chưa quét. **Giảm nhẹ**: `budget_view.dart` **re-export** ⇒ mọi import cũ hợp lệ; `flutter analyze` xác nhận trong bước đầu thi công.
9. **Số tiền hàng tỉ** trên khu đầu màn teal + nhãn trục biểu đồ dễ tràn. **Giảm nhẹ**: bọc `FittedBox(fit: scaleDown)` cho 2 số tổng (bám nếp `_StatBlock` màn Giao dịch); QA nhóm K mục 1.
10. **Kịch bản 12 (dữ liệu đổi → số liệu đổi)** phụ thuộc `AppShell` gọi `load()` đúng lúc. **Giảm nhẹ**: `report_controller_test` khẳng định `load()` đọc lại DB còn `setPeriod` thì **không**; `widget_test` phủ đường chọn tab.

## Việc bàn giao kèm (ngoài code)

- Tick `checklists/requirements.md` sau khi thi công xong (giữ nguyên nội dung đã duyệt).
- Đồng bộ wiki (`wiki-knowledge/`) theo skill `sora-wiki`: tạo page **entity/Báo cáo** (kỳ Ngày/Tuần/Tháng/Năm + tuần bắt đầu Thứ Hai, biểu đồ 6 đơn vị, gộp danh mục cha + nhóm "Khác", top 5, drill-down sang màn Giao dịch đã lọc, bảng màu định tính **không coral**, không bảng tổng hợp/cache), cập nhật **concept/Design system** (token `chartPalette` light/dark), **concept/Lộ trình phát triển** (màn `01` Báo cáo xong; còn `02`/`03`/`04` + bộ lọc nâng cao), **concept/Stack kỹ thuật** (`fl_chart` đã dùng cả `BarChart` lẫn `PieChart`) + append `wiki-knowledge/log.md` và cập nhật `index.md`.
