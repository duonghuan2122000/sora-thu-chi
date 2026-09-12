# Kế hoạch triển khai: Chi tiết theo danh mục (màn 02 Báo cáo)

**Mã PBI**: 23
**Liên kết spec**: [.specify/specs/23/spec.md](./spec.md)
**Ngày tạo**: 2026-09-12

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12 / Flutter (Android + iOS), app **offline hoàn toàn** |
| Framework / Thư viện chính | GetX `^4.7.3` (điều hướng + DI + i18n), Material; vòng tròn dùng **`fl_chart ^1.2.0`** — `PieChart` đã chạy thật ở PBI 22 ⇒ **không sửa `pubspec.yaml`**, **không** thêm dependency |
| Lưu trữ dữ liệu | drift `^2.34.4` + sqlite local — **schema giữ nguyên v7** (PBI 21): **không** thêm bảng/cột, **không** migration, **không** chạy `build_runner`; màn 02 **không** đọc DB (R1) |
| Kiểm thử | `flutter_test` — 657 test hiện có; bổ sung **1 file test mới**, sửa **3 file test** (module thuần, màn 01, smoke tối); mục tiêu **không đỏ test cũ** |
| Nền tảng triển khai | Build local (`flutter build apk` / iOS build) — không server, không CI đặc thù |
| Ràng buộc hiệu năng | Màn 02 dựng số liệu từ **bản chụp RAM** của `ReportController` (đã nạp khi mở tab Báo cáo) ⇒ **không** phát sinh phép đọc DB nào; SC-008 (< 1 giây) không đổi so với PBI 22 |
| Ràng buộc khác | Ngôn ngữ giao diện/tài liệu/commit: **tiếng Việt có dấu**; bám Design System (teal `#0F6E56` = hành động/trạng thái chọn; coral `#D85A30` **chỉ** cho chi tiêu/cảnh báo ⇒ **không** dùng trong bảng màu định tính); mọi màu đi qua token `AppColors`/`SoraColors` để chạy đúng dark mode (PBI 18); mọi nhãn tĩnh phải có bản dịch EN (PBI 19) |
| Nguồn chân lý nghiệp vụ | `docs/report/bao-cao-thong-ke-giai-phap.md` (§3.5 "Xem tất cả" → màn Chi tiết liệt kê **đầy đủ**, §5 danh sách màn hình + bảng màu định tính, §3.2 drill-down) + mockup `docs/report/man-hinh-02-chi-tiet-danh-muc.svg`; kế thừa `research.md` PBI 22 (mốc kỳ, `_breakdown`, drill-down bằng `TxnSearchFilter`) và PBI 21 (màn con `popUntil` rồi đổi tab) |

*Không còn mục `NEEDS CLARIFICATION`: spec đã "Đã làm rõ" (2 quyết định chốt 2026-09-12); các quyết định còn lại là chi tiết triển khai — xem `research.md` (R1…R10).*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

`.specify/memory/constitution.md` **không tồn tại** (repo chưa tạo hiến pháp) ⇒ đối chiếu theo `CLAUDE.md` của repo và các quyết định đã chốt trong `docs/`.

| Nguyên tắc (nguồn: CLAUDE.md + docs) | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline hoàn toàn, không server/không auth | ✅ | Không đọc mạng; số liệu lấy từ RAM đã nạp từ sqlite local (QA nhóm K) |
| Ngôn ngữ giao diện/tài liệu/commit: tiếng Việt có dấu | ✅ | Mọi nhãn, tài liệu, comment, commit của PBI này bằng tiếng Việt |
| Stack đã chốt (drift + GetX + fl_chart) | ✅ | Không thêm dependency, không sửa `pubspec.yaml`; vòng tròn tái dùng `PieChart` sẵn có |
| Design system: 1 màu thương hiệu teal, coral chỉ cho chi/cảnh báo, không hex cứng trong widget | ✅ | Bảng màu định tính **đã có token** `SoraColors.chartPalette` (PBI 22) — đợt này chỉ **đọc** token, không thêm hex vào widget, không sửa `sora_colors.dart` |
| Số dư ví là đại lượng suy ra, không sửa tay | ✅ | Màn chỉ đọc; không ghi bất kỳ bảng nào |
| Thu/chi/chuyển khoản: transfer không tính là thu/chi | ✅ | Dùng lại **đúng** hàm `_breakdown` của màn 01 (đã loại transfer/adjustment) ⇒ hai màn không thể lệch số |
| Màn cấp tab có bottom nav, **màn con không** | ✅ | Màn 02 là route đè shell qua `SubPageScaffold` (app bar teal + back, không bottom nav); **không** đụng `AppShell`/`AppBottomNavBar` |
| Không sửa dữ liệu người dùng ngoài phạm vi | ✅ | Chỉ **đọc** `transactions` + `categories`; không đụng `wallets`/`budgets` |
| Không phá vỡ hành vi PBI trước | ✅ | Màn 01 chỉ **thêm** liên kết "Xem tất cả"; `ReportView`/`reportBreakdown`/`reportTopCategories` giữ nguyên chữ ký; bộ lọc màn Giao dịch chỉ **đặt**, không đổi ngữ nghĩa (tái dùng hạ tầng PBI 12) |
| YAGNI / không abstraction sớm | ✅ | 1 hàm thuần + 1 method controller + 1 màn mới; không controller mới, không repository mới, không widget dùng chung mới, không cache/bảng tổng hợp |
| Quy trình PBI: spec → plan → task → implement | ✅ | Đang ở bước plan; `tasks.md` sinh ở bước sau |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại [research.md](./research.md). Tóm tắt các quyết định chính:

- **Nguồn dữ liệu (R1)** — **Quyết định**: màn 02 **không đọc DB**, dựng số liệu từ bản chụp RAM của `ReportController` qua method mới `categoryDetail()`. **Lý do**: màn chỉ mở được từ màn 01 đang có dữ liệu ⇒ không cần loading/error thứ hai, và hai màn **không thể lệch số**. **Phương án khác**: `StatefulWidget` đọc DB trong `initState` (khuôn PBI 21 — thêm ~40 dòng + dữ liệu đọc ở thời điểm khác ⇒ rủi ro lệch số).
- **Danh sách đầy đủ + màu lặp chu kỳ (R2)** — **Quyết định**: hàm thuần mới `reportCategoryDetail(...)` tái dùng `_breakdown` (cùng file), bỏ `.take(5)`, thêm "Khác" cuối, `percentSplit` toàn bộ dòng; màu = `chartPalette[rank % 5]` (5 màu định tính), "Khác" = `chartPalette[5]`. **Lý do**: doc §5 chốt 5 màu định tính + spec chốt lặp chu kỳ; một bảng màu duy nhất ⇒ không đụng token/test PBI 22. **Phương án khác**: màu hồng `#C97B84` của mockup 02 (lệch doc §5, lệch màn 01); bảng màu riêng cho màn 02.
- **Chip kỳ (R3)** — **Quyết định**: `reportPeriodChipLabel(period, range)`, ghép danh từ kỳ **đã có bản dịch** (`Ngày/Tuần/Tháng/Năm`) với chuỗi ngày không phụ thuộc ngôn ngữ → `Tháng 9/2026`, `Tuần 07/09–13/09/2026`. **Lý do**: FR-003 cần loại kỳ + mốc; không thêm khóa dịch nào. **Phương án khác**: dùng lại khóa PBI 20/21 (`'Tháng @tháng, @năm'`) — bản EN mất "loại kỳ".
- **Vòng tròn (R4)** — **Quyết định**: `PieChart` (`centerSpaceRadius` ≈ 52, `radius` ≈ 30, `sectionsSpace: 2`) + `Stack` nhãn giữa; dựng **cục bộ** trong màn 02. **Lý do**: kích thước/nhãn/ngữ nghĩa lát khác màn 01 ⇒ tách widget chung phải sửa màn 01 + test PBI 22 mà lợi ích ~0. **Phương án khác**: widget vòng tròn dùng chung.
- **Drill-down (R5)** — **Quyết định**: `TxnSearchFilter` (Chi + `dateStart`/`dateEnd` của kỳ + `categoryIds = {id cha}`) → `setFilter` → `popUntil(isFirst)` → `onSelectTab(1)`; dòng "Khác" **không** chạm được. **Lý do**: bộ lọc PBI 12 tự mở rộng cha → con ⇒ SC-006 khớp 0 đ; màn 02 là route đè shell nên phải `popUntil` trước khi đổi tab (khác màn 01). **Phương án khác**: tự đẩy màn Giao dịch thứ hai (chồng 2 màn con).
- **Điểm vào (R6)** — **Quyết định**: liên kết `Xem tất cả` (khóa dịch **đã có**) ở bên phải hàng tiêu đề thẻ Top, chỉ hiện khi thẻ có nội dung. **Lý do**: FR-001 + kế thừa nếp "màn con đẩy từ tab". **Phương án khác**: hiện cả khi thẻ rỗng (dẫn tới màn 02 rỗng vô nghĩa).
- **Trạng thái rỗng (R7)** — **Quyết định**: `ReportCategoryDetail` mang cờ `hasAnyTxn`; `total == 0` ⇒ rỗng toàn màn, 2 thông điệp (khóa **đã có**) cho "chỉ Thu" vs "không có gì/chỉ transfer". **Phương án khác**: đọc thêm `controller.data.value` cho cờ (hai nguồn cho một lần vẽ).
- **i18n (R8)** — **Quyết định**: **7 khóa mới** (tiêu đề, `DANH MỤC (@n)`, 4 nhãn giữa vòng, dòng gợi ý); dùng lại `'Xem tất cả'`, `'Khác'`, `'Tổng chi'`, 4 danh từ kỳ, 2 thông điệp rỗng.
- **Test (R9)** — **Quyết định**: 1 file test màn mới + mở rộng 3 file test sẵn có (bảng chi tiết ở mục "Test").
- **Ràng buộc kế thừa (R10)** — **Quyết định**: không schema, không migration, không dependency, không `WalletRepository` mới, không `contracts/`.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem [data-model.md](./data-model.md) — **không đổi schema**; 2 thực thể logic (`ReportCategoryRow`, `ReportCategoryDetail`) + 3 hàm thuần + **19 luật bất biến** (đủ mọi danh mục, lặp màu chu kỳ, "Khác" cuối & không chạm được, Σ% = 100, Σ tiền = tổng chi, gộp cha, cờ rỗng) + bảng vòng đời "khi nào số liệu đổi".
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app thuần nội bộ, không API/CLI/endpoint lộ ra ngoài (đồng nhất PBI 19/20/21/22). Hợp đồng nội bộ duy nhất là `WalletRepository` — **không đổi chữ ký**.
- **Kịch bản khởi động nhanh**: xem [quickstart.md](./quickstart.md) — **12 nhóm kiểm thử tay A–L**, phủ FR-001…FR-020 và SC-001…SC-014.

### Kiến trúc chi tiết

**1. Tầng nghiệp vụ thuần — `lib/core/report/report_view.dart` (sửa, thêm ~90 dòng)**

| Thành phần | Vai trò |
|---|---|
| `class ReportCategoryRow` | Một dòng danh mục: `categoryId?`, `name`, `amount`, `percent`, `rank` (`-1` = "Khác") |
| `class ReportCategoryDetail` | `period`, `range`, `total`, `hasAnyTxn`, `rows`; getter `isEmpty => total == 0` |
| `ReportCategoryDetail reportCategoryDetail({transactions, categories, period, now})` | Dựng số liệu màn 02: gọi `_breakdown` (tái dùng, **không** `.take(5)`), thêm "Khác" cuối khi `other > 0`, `percentSplit` trên toàn bộ dòng; `hasAnyTxn` tính từ chính danh sách giao dịch + `range` |
| `String reportPeriodChipLabel(ReportPeriod period, DateRange range)` | Nhãn chip: `Ngày 12/09/2026` · `Tuần 07/09–13/09/2026` (năm theo ngày cuối kỳ) · `Tháng 9/2026` · `Năm 2026` |
| `String reportExpenseCenterLabel(ReportPeriod period)` | `Tổng chi ngày/tuần/tháng/năm` (nhãn giữa vòng tròn) |

Không sửa `reportBreakdown` / `reportTopCategories` / `buildReportView` / `ReportView` ⇒ màn 01 và test PBI 22 không đổi.

**2. Trạng thái màn — `lib/core/report/report_controller.dart` (sửa, +1 method)**

```dart
/// Số liệu màn Chi tiết theo danh mục (PBI 23) — dựng lại từ bản chụp RAM mỗi
/// lần gọi; màn 02 chỉ mở được từ màn Tổng quan đã có dữ liệu (research R1).
ReportCategoryDetail? categoryDetail() {
  if (!_loaded) return null;
  return reportCategoryDetail(
    transactions: _transactions,
    categories: _categories,
    period: period.value,
    now: _now,
  );
}
```

Không thêm Rx state, không đọc DB, không đổi `load()`/`setPeriod()`.

**3. Màn mới — `lib/screens/report_category_detail_screen.dart` (mới, mockup `02`)**

- `StatelessWidget { ValueChanged<int>? onSelectTab }`; đọc `ensureReportController()` và `categoryDetail()`, toàn thân bọc `Obx` (kỳ/dữ liệu đổi ở nơi khác → vẽ lại theo bản chụp mới nhất).
- Khung: `SubPageScaffold(title: 'Chi tiêu theo danh mục'.tr, child: …)` — app bar teal + nút back sẵn có, **không** bottom nav, **không** FAB.
- Thân (`ListView`, `padding bottom 24`) theo đúng thứ tự mockup:
  1. **Chip kỳ** — `Container` bo `15px`, nền `softCardBg`, chữ `textPrimary` w600, nội dung `reportPeriodChipLabel(...)`; **nhãn tĩnh**, không `InkWell`, không mũi tên (FR-003). `ValueKey('report-detail-chip')`.
  2. **Vòng tròn** — ô `200×200` giữa màn: `PieChart` (`sectionsSpace: 2`, `centerSpaceRadius` ≈ 52, `radius` ≈ 30, `showTitle: false`, màu = `palette[rank < 0 ? 5 : rank % 5]`, `PieTouchData.touchCallback` → chạm lát = drill-down như chạm dòng) + `Stack` nhãn giữa gồm `reportExpenseCenterLabel(period)` (nhỏ, `textSecondary`) và `formatMoney(total)` (`FittedBox(scaleDown)`, `textPrimary` w700). `ValueKey('report-detail-donut')`.
  3. **Tiêu đề nhóm** `DANH MỤC (@n).trParams({'n': '${rows.length}'})` — chữ hoa, `tabInactive` (bám mockup) — có đường phân cách phía trên (FR-005).
  4. **Các dòng danh mục** (FR-006): mỗi dòng `InkWell` (`ValueKey('report-detail-row-<id|other>')`, `onTap: null` khi `categoryId == null` — FR-012), bên trong `Row`:
     - chấm tròn 10px màu `palette[rank < 0 ? 5 : rank % 5]`;
     - `Expanded(Column)`: hàng `[Expanded(Text(name, maxLines: 1, ellipsis)), Text(formatMoney(amount), w600)]` → `Text('${percent}%', textSecondary, căn phải)` → `ClipRRect(LinearProgressIndicator(value: percent / 100, minHeight: 4, color = màu dòng, background = colors.divider))`;
     - màu chấm **và** thanh tiến độ **cùng một giá trị** lấy từ `rank` ⇒ SC-007 tự đúng;
     - phân cách giữa các dòng bằng `Divider`/`Border` màu `listDivider`.
  5. **Dòng gợi ý** `'Chạm vào một danh mục để xem các giao dịch'.tr` — chữ tĩnh, căn giữa, `tabInactive`.
- **Trạng thái rỗng** (FR-013/FR-014): `detail.total == 0` ⇒ `Center` thông điệp `hasAnyTxn ? 'Chưa có chi tiêu nào trong kỳ này'.tr : 'Chưa có giao dịch nào trong kỳ này'.tr`, **không** vẽ vòng tròn/tiêu đề nhóm. `ValueKey('report-detail-empty')`.
- `detail == null` (chưa nạp — chỉ xảy ra ở test) ⇒ `SizedBox.shrink()` (màn chỉ mở được qua đường đã có dữ liệu).
- **Hành vi drill-down** (R5): dựng `TxnSearchFilter(now: controller.now, type: TxnTypeFilter.expense, datePreset: DatePreset.custom, dateStart: detail.range.start, dateEnd: detail.range.end.subtract(1 ngày), categoryIds: {categoryId}, sort: SortOption.dateNewest)` → `ensureTransactionController().setFilter(filter)` → `Navigator.of(context).popUntil((r) => r.isFirst)` → `widget.onSelectTab?.call(1)`.

**4. Điểm vào — `lib/screens/report_screen.dart` (sửa, ~15 dòng)**

- Trong `_TopCategoriesCard`, hàng tiêu đề thẻ chuyển thành `Row`: `Expanded(Text('Top danh mục chi tiêu'))` + khi `view.hasExpense` một `InkWell`/`TextButton` `ValueKey('report-see-all')` nội dung `'Xem tất cả'.tr` (màu `tealOnNeutral`, cỡ 12) → `onSeeAll` (callback mới của thẻ, do `ReportScreen` truyền) → `Navigator.push(MaterialPageRoute(builder: (_) => ReportCategoryDetailScreen(onSelectTab: onSelectTab)))` (R6).
- Không đổi gì khác ở màn 01 (khu teal, 3 thẻ, drill-down cũ, `ValueKey` cũ giữ nguyên).

**5. Khung app — `lib/core/app_shell.dart`: KHÔNG sửa**

Màn 02 là route đè shell (điều hướng bằng `Navigator.push`), không nằm trong `IndexedStack` ⇒ không cần nhánh nạp nào mới; việc làm mới số liệu đã có sẵn ở `_onTabSelected` (tab Báo cáo) và `_openAddTransaction` (PBI 22 R1/R11).

**6. Dịch nhãn (FR-018) — `lib/core/locale/sora_translations.dart` (sửa, +7 khóa)**

Mục mới "Báo cáo (PBI 23) — màn Chi tiết `02`":

`'Chi tiêu theo danh mục'` → *Spending by category* · `'DANH MỤC (@n)'` → *CATEGORIES (@n)* · `'Tổng chi ngày'` → *Day total* · `'Tổng chi tuần'` → *Week total* · `'Tổng chi tháng'` → *Month total* · `'Tổng chi năm'` → *Year total* · `'Chạm vào một danh mục để xem các giao dịch'` → *Tap a category to see its transactions*.

Dùng lại (không thêm): `'Xem tất cả'`, `'Khác'`, `'Tổng chi'`, `'Ngày'/'Tuần'/'Tháng'/'Năm'`, `'Chưa có giao dịch nào trong kỳ này'`, `'Chưa có chi tiêu nào trong kỳ này'`. `sora_translations_test` tự quét literal `.tr` ⇒ thiếu khóa là đỏ.

**7. Test**

| File | Nội dung |
|---|---|
| `test/report_view_test.dart` **(sửa)** | `reportCategoryDetail`: 7 danh mục → **7 dòng** (không cắt 5) + "Khác" cuối khi có tiền chi không gắn danh mục; `Σ amount == total`, `Σ percent == 100`; gộp con → cha; danh mục **ẩn** vẫn tính; con mồ côi nhóm theo chính nó; đồng hạng → tên tăng dần; `rank` = chỉ số (0…n-1) và "Khác" = `-1`; kỳ chỉ Thu / chỉ transfer → `total == 0` + `hasAnyTxn` đúng; kỳ rỗng → `rows` rỗng; 1 danh mục → 1 dòng 100%. Thêm `reportPeriodChipLabel` (4 kỳ; tuần vắt qua tháng; tuần vắt qua năm) và `reportExpenseCenterLabel` (4 kỳ) |
| `test/report_category_detail_screen_test.dart` **(mới)** | Vẽ: tiêu đề, chip đúng chuỗi, `DANH MỤC (n)` khớp số dòng, đủ n dòng, dòng gợi ý, nhãn giữa vòng tròn + số tiền; **không** có bottom nav. Chạm dòng danh mục → `TransactionController.activeFilter` đúng (Chi + `dateStart`/`dateEnd` của kỳ + `categoryIds = {cha}`) **và** `onSelectTab(1)` được gọi; chạm dòng **"Khác"** → **không** đổi bộ lọc, **không** gọi `onSelectTab`. Trạng thái rỗng: kỳ rỗng / chỉ Thu / chỉ transfer. English → không còn nhãn tiếng Việt |
| `test/report_screen_test.dart` **(sửa)** | Thẻ Top có `'Xem tất cả'` khi kỳ có chi tiêu; **không** có khi thẻ rỗng; chạm → `find.byType(ReportCategoryDetailScreen)` xuất hiện |
| `test/dark_theme_smoke_test.dart` **(sửa)** | Thêm ca smoke: pump màn 02 ở **theme tối** (có dữ liệu) → không overflow, token tối thật sự áp (FR-019) |

Ghi chú test: test đụng `.tr` phải khôi phục `Get.locale` trong `addTearDown` (bài học PBI 19); dùng `FakeWalletRepository.withCategories(...)` ⇒ **không** cần sqlite native; mọi số liệu tính theo `now` **bơm tham số** (`_now = DateTime(2026, 3, 15)` như test PBI 22), không dùng giờ thật; test màn 02 cần `Get.put(TransactionController(fake))` (hoặc `ensureTransactionController()`) rồi `Get.reset()` trong `tearDown`; màn 02 là `home:` của `MaterialApp` trong test ⇒ `popUntil(isFirst)` không pop mất chính nó.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline, không server | ✅ | Không đọc DB, không mạng; vẽ từ bản chụp RAM |
| Không sửa dữ liệu người dùng ngoài phạm vi | ✅ | Không ghi bảng nào; `transactions`/`categories` chỉ đọc |
| Transfer & điều chỉnh không tính là thu/chi | ✅ | Dùng lại **đúng** `_breakdown` của màn 01 ⇒ cùng nguồn số, test có ca transfer-only |
| Design system + dark mode | ✅ | Không thêm hex nào; màu lấy từ `SoraColors.chartPalette` + token nền/chữ ⇒ dark mode tự đúng; **không** coral |
| Màn cấp tab có bottom nav, màn con không | ✅ | Màn 02 qua `SubPageScaffold`; không đụng `AppShell` |
| i18n đầy đủ (PBI 19) | ✅ | 7 khóa mới; `sora_translations_test` quét tự động ⇒ thiếu là đỏ; QA nhóm I gạch từng nhãn ở cả 4 kỳ |
| YAGNI / không abstraction sớm | ✅ | 1 hàm thuần + 1 method + 1 màn; không widget dùng chung mới, không controller mới, không cache |
| Không phá vỡ test/hành vi cũ | ✅ (kiểm chứng khi thi công) | Màn 01 chỉ **thêm** liên kết; `reportBreakdown`/`ReportView`/`chartPalette` không đổi; chỉ 3 file test sẵn có được chạm **nếu** khẳng định cũ vỡ |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── core/
│   │   ├── locale/sora_translations.dart        # SỬA: +7 khóa EN (Báo cáo PBI 23)
│   │   └── report/
│   │       ├── report_view.dart                 # SỬA: +ReportCategoryRow/Detail, reportCategoryDetail,
│   │       │                                    #       reportPeriodChipLabel, reportExpenseCenterLabel
│   │       └── report_controller.dart           # SỬA: +categoryDetail() (dựng từ bản chụp RAM)
│   └── screens/
│       ├── report_category_detail_screen.dart   # MỚI — màn 02 (chip kỳ + vòng tròn + danh sách đầy đủ)
│       └── report_screen.dart                   # SỬA: +"Xem tất cả" trên thẻ Top → đẩy màn 02
└── test/
    ├── report_view_test.dart                    # SỬA: +test hàm thuần mới
    ├── report_category_detail_screen_test.dart  # MỚI
    ├── report_screen_test.dart                  # SỬA: +"Xem tất cả"
    └── dark_theme_smoke_test.dart               # SỬA: +smoke màn 02 ở theme tối
```

Không tạo `contracts/`: dự án thuần nội bộ, không có giao diện lộ ra ngoài.
Không đụng `lib/data/db/*` (schema giữ **v7**), không chạy `build_runner`, không sửa `pubspec.yaml`, không sửa `lib/core/app_shell.dart`, không sửa `lib/theme/sora_colors.dart`.

## Rủi ro & ngoại lệ có lý do

1. **Lệch số giữa dòng và màn Giao dịch** với giao dịch cũ `categoryId == null` nhưng tên khớp danh mục, hoặc giao dịch của **danh mục ẩn**: màn 02 gộp tiền không gắn danh mục vào "Khác" và tính cả danh mục ẩn, còn bộ lọc màn Giao dịch mở rộng cha → con trên **danh mục đang hoạt động** (PBI 12). **Giảm nhẹ**: kế thừa nguyên rủi ro 4 của PBI 22 (dữ liệu tạo từ schema v4 luôn có `category_id`); QA nhóm F dùng dữ liệu thật. Nếu gặp: ghi nhận, **không** sửa bộ lọc trong PBI này (sửa sẽ đổi hành vi màn Giao dịch/PBI 12).
2. **Màu lặp chu kỳ gây trùng màu giữa hai hạng** (SC-014): hệ quả **đã chấp nhận** ở spec (chốt 2026-09-12) — phân biệt bằng tên + thứ tự. QA nhóm C mục 5 kiểm bằng mắt với 7 danh mục.
3. **Nhãn giữa vòng tròn trên màn hình nhỏ / số tiền hàng tỉ**: `fl_chart` không vẽ chữ ở tâm ⇒ `Stack` + `FittedBox(scaleDown)`; lệch bố cục thì giảm `centerSpaceRadius`/cỡ chữ — **một chỗ** trong màn 02. QA nhóm J.
4. **Chip kỳ khác mockup `02`** (không mũi tên, không bấm được): khác biệt **đã chốt** ở spec (2A) và ghi ở SC-001 ⇒ không phải lỗi khi đối chiếu mockup.
5. **Màu hạng 5 của mockup 02 là hồng `#C97B84`**, repo chạy màu xám theo doc §5: khác biệt **cố ý** (R2), ghi nhận trong `research.md` để lần sau không "sửa lại cho giống mockup" rồi làm lệch màn 01.
6. **Số liệu tính lại theo bản chụp RAM**: nếu tương lai có đường mở màn 02 mà **không** đi qua màn 01 (VD thông báo đẩy), bản chụp có thể chưa nạp ⇒ màn trống. **Giảm nhẹ**: `categoryDetail()` trả `null` và màn 02 chịu được (không crash); hiện chỉ có **một** điểm vào (FR-001) nên không xảy ra.
7. **`Get.reset()` trong test** phải xoá cả `ReportController` (singleton) và `TransactionController`; quên ⇒ test sau dùng nhầm bản chụp cũ (bài học PBI 22).
8. **Tên danh mục dài + số tiền lớn trên cùng một hàng** dễ đẩy số tiền ra ngoài. **Giảm nhẹ**: `Expanded(Text(ellipsis))` cho tên + `FittedBox`/cột phải cố định cho số tiền (FR-020); QA nhóm J.
9. **`percentSplit` với danh sách dài** (nhiều danh mục): thuật toán phần dư lớn nhất vẫn tổng = 100 (đã test ở PBI 22 với 5–6 phần tử) — thêm ca 7–8 phần tử vào test để chốt.
10. **Nút "Xem tất cả" chỉ hiện khi thẻ có nội dung**: nếu kỳ có chi tiêu nhưng người dùng muốn mở màn 02 từ thẻ rỗng (để thấy thông điệp rỗng), không có đường vào — chấp nhận: màn 02 rỗng không mang thông tin mới so với thẻ rỗng (SC-010 vẫn kiểm được bằng cách mở màn 02 ở kỳ có chi tiêu rồi đổi kỳ ở màn 01).

## Việc bàn giao kèm (ngoài code)

- Tick `checklists/requirements.md` sau khi thi công xong (giữ nguyên nội dung đã duyệt).
- Đồng bộ wiki (`wiki-knowledge/`) theo skill `sora-wiki`: cập nhật page **entity/Báo cáo** (màn `02` Chi tiết theo danh mục: chip kỳ nhãn tĩnh, vòng tròn + danh sách **đầy đủ** mọi danh mục, màu định tính **lặp chu kỳ** 5 màu + xám cho "Khác", drill-down `popUntil` + đổi tab, 2 trạng thái rỗng, số liệu dựng từ bản chụp RAM), **concept/Lộ trình phát triển** (màn `02` xong; còn `03` So sánh kỳ / `04` Xuất báo cáo + bộ lọc nâng cao), **concept/Design system** (bảng màu định tính dùng theo **thứ hạng, lặp chu kỳ**; khác biệt cố ý với mockup `02`) + append `wiki-knowledge/log.md` và cập nhật `index.md`.
