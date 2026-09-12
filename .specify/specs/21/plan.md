# Kế hoạch triển khai: Chi tiết Ngân sách (tiến độ, tốc độ chi tiêu, so sánh nhiều kỳ)

**Mã PBI**: 21
**Liên kết spec**: [.specify/specs/21/spec.md](./spec.md)
**Ngày tạo**: 2026-09-12
**Ngữ cảnh kỹ thuật bổ sung từ người dùng**: "Hãy lên giải pháp thi công cho PBI 21"

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12 / Flutter (Android + iOS), app **offline hoàn toàn** |
| Framework / Thư viện chính | GetX `^4.7.3` (điều hướng + DI + i18n), Material; biểu đồ dùng **`fl_chart ^1.2.0`** — đã khai báo sẵn trong `pubspec.yaml` (PBI 20 chưa dùng) và đã resolve trong `.dart_tool/package_config.json` ⇒ **không sửa pubspec** |
| Lưu trữ dữ liệu | drift `^2.34.4` + sqlite local — **schema v6 → v7**: thêm **1 cột** `budgets.is_archived` (bool, default `false`), **không thêm bảng**, không seed; sinh lại `app_database.g.dart` bằng `build_runner` |
| Kiểm thử | `flutter_test` — 533 test hiện có; bổ sung **2 file test mới**, sửa **3 file test** + `FakeWalletRepository`; mục tiêu **không đỏ test cũ** |
| Nền tảng triển khai | Build local (`flutter build apk` / iOS build) — không server, không CI đặc thù |
| Ràng buộc hiệu năng | Màn Chi tiết quét `transactions` **một lần** khi nạp rồi tính mọi kỳ (kỳ đang xem + tối đa 3 kỳ so sánh) trên cùng danh sách trong RAM (DB local một thiết bị, vài nghìn dòng ⇒ tức thời). Không snapshot, không cache |
| Ràng buộc khác | Ngôn ngữ giao diện/tài liệu/commit: **tiếng Việt có dấu**; bám Design System (teal `#0F6E56` cho hành động chính, coral `#D85A30` **chỉ** cho chi tiêu/cảnh báo; cột "Dự kiến" màu trung tính); mọi màu đi qua token `AppColors`/`SoraColors` để chạy đúng dark mode (PBI 18); mọi nhãn tĩnh phải có bản dịch EN (PBI 19) |
| Nguồn chân lý nghiệp vụ | `docs/budget/nghiep-vu-ngan-sach.md` (§4.6 so sánh dự kiến–thực tế + tốc độ tiêu, §4.7 lưu trữ, §6 màu, §7 biên) + mockup `man-hinh-03-chi-tiet-ngan-sach.svg`; wiki `wiki-knowledge/entity/Ngân sách.md`; kế thừa `research.md` PBI 20 (R3 không snapshot, R5 mốc kỳ, R7 3 dải màu) |

*Không còn mục `NEEDS CLARIFICATION`: spec đã "Đã làm rõ" (0 điểm mở), các quyết định còn lại là chi tiết triển khai — xem `research.md`.*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

`.specify/memory/constitution.md` **không tồn tại** (repo chưa tạo hiến pháp) ⇒ đối chiếu theo `CLAUDE.md` của repo và các quyết định đã chốt trong `docs/`.

| Nguyên tắc (nguồn: CLAUDE.md + docs) | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline hoàn toàn, không server/không auth | ✅ | Chỉ thêm 1 cột sqlite local; biểu đồ vẽ từ dữ liệu trên máy |
| Ngôn ngữ giao diện/tài liệu/commit: tiếng Việt có dấu | ✅ | Mọi nhãn, tài liệu, comment, commit của PBI này bằng tiếng Việt |
| Stack đã chốt (drift + GetX + fl_chart) | ✅ | `fl_chart` là stack đã chốt trong `docs/tinh-nang…md §Stack` và **đã có trong pubspec** — PBI này là lần dùng đầu, không thêm dependency mới |
| Design system: 1 màu thương hiệu teal, coral chỉ cho chi/cảnh báo, không hex cứng trong widget | ✅ | 3 dải màu tiến độ + màu cột "Thực tế" tái dùng đúng quy tắc PBI 20 (teal / coral alpha 0.6 / coral); cột "Dự kiến" dùng màu trung tính của token; card bo `10px`, nút bo `8px` cao `44px` |
| Số dư ví là đại lượng suy ra, không sửa tay | ✅ | Không đụng `wallets`; ngân sách cũng là đại lượng **suy ra** từ giao dịch |
| Thu/chi/chuyển khoản: transfer không tính là thu/chi | ✅ | Mọi số liệu + danh sách chỉ lấy `type == expense`; thu & transfer bị loại (FR-011) |
| Màn con của shell: app bar thương hiệu + back, **không** bottom nav | ✅ | Màn Chi tiết dùng `SubPageScaffold` (thêm tham số `subtitle`) — đúng FR-001 |
| Bám mockup: phần chưa có hiệu lực thì hiển thị nhưng chưa kích hoạt | ✅ | Đợt này **không** thêm phần tử no-op nào; mọi thứ trên màn `03` đều có hiệu lực thật |
| Không sửa dữ liệu người dùng ngoài phạm vi | ✅ | Chỉ ghi `budgets` (1 cột mới); `transactions`/`categories`/`wallets` chỉ **đọc**; lưu trữ **không** xóa giao dịch (FR-017) |
| Quy trình PBI: spec → plan → task → implement | ✅ | Đang ở bước plan; `tasks.md` sinh ở bước sau |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại [research.md](./research.md). Tóm tắt các quyết định chính:

- **Điểm vào** — **Quyết định**: chạm dòng ở màn Tổng quan mở **màn Chi tiết** (không mở thẳng form như PBI 20); form `02` vào từ nút "Chỉnh sửa". **Lý do**: FR-001 chốt thay hành vi cũ. **Phương án khác**: giữ tap = mở form + thêm nút "Chi tiết" (trái mockup).
- **App bar 2 dòng** — **Quyết định**: thêm tham số tùy chọn `String? subtitle` cho `SubPageScaffold` (app bar `Column` 2 dòng, `toolbarHeight` 68). **Lý do**: mockup `03` vẽ 2 dòng; thay đổi **additive**, 8 màn đang dùng không đổi. **Phương án khác**: màn tự dựng `Scaffold`/`AppBar` (nhân bản cấu hình theme).
- **Lưu trữ ngân sách** — **Quyết định**: **schema v7**, thêm `budgets.is_archived` (bool default `false`); lưu trữ = `updateBudget(budget.copyWith(isArchived: true))`; `budgets()` **giữ nguyên** (trả cả đã lưu trữ), `buildBudgetOverview` bỏ qua dòng archived. **Lý do**: FR-016/FR-017 chỉ cần 1 bit + `addColumn` có default là migration an toàn nhất. **Phương án khác**: bảng `budget_archives` / `archived_at` / xóa cứng (doc §4.7 loại trừ).
- **Module thuần** — **Quyết định**: file mới `core/budget/budget_detail.dart` cho toàn bộ số liệu màn `03`. **Lý do**: `budget_view.dart` đã 236 dòng và chỉ phục vụ màn `01`; đây là màn khác với bộ hàm khác. **Phương án khác**: nhồi chung (file ~450 dòng trộn 2 màn).
- **Kỳ đang xem & danh sách kỳ** — **Quyết định**: mặc định kỳ chứa `now` (không lặp lại → kỳ chứa `startDate`); danh sách kỳ từ kỳ `startDate` tới kỳ hiện tại, **dừng ở kỳ `startDate`** nếu không lặp lại. **Lý do**: FR-020/FR-023 + kịch bản 3/17 cùng đúng. **Phương án khác**: luôn liệt kê tới kỳ hiện tại (ngân sách đã hết kỳ vẫn cho chọn kỳ vô hiệu lực).
- **Ngày còn lại / % ngày đã qua** — **Quyết định**: `elapsedDays = clamp(today − start + 1, 0, total)`, `daysLeft = total − elapsedDays` (sàn 0). **Lý do**: tự nhất quán, không âm, ngày cuối kỳ = 0, và **khớp mockup** ("18 ngày còn lại"). **Phương án khác**: `end − today` (ra 19) như màn `01` — không sửa màn `01` đợt này (xem Rủi ro 2).
- **Cảnh báo tốc độ** — **Quyết định**: `!ended && usedPercent > elapsedPercent`; chỉ **một** băng (chi nhanh hơn). **Lý do**: FR-007 + giả định spec. **Phương án khác**: dự báo số tiền tới hết kỳ (ngoài phạm vi).
- **Huy hiệu trạng thái** — **Quyết định**: `<80%` "Bình thường @p%" / `80–99%` "Sắp đạt @p%" / `≥100%` "Vượt @p%" — tái dùng `budgetProgressLevel` cho cả màu lẫn chữ. **Lý do**: FR-004/FR-005, một nguồn duy nhất. **Phương án khác**: nhãn riêng cho mốc đúng 100% (FR-005 nói "từ 100% trở lên" ⇒ giữ "Vượt").
- **Biểu đồ** — **Quyết định**: `fl_chart` `BarChart` (cột đôi + `ExtraLinesData` `dashArray` cho mốc giới hạn + `FlTitlesData` cho nhãn kỳ). **Lý do**: rung "dependency đã cài" — thư viện **đã nằm trong stack** và đã resolve; tự vẽ phải thêm `CustomPaint` + tự tính scale. **Phương án khác**: tự dựng `Container` tỉ lệ (giữ làm phương án lùi nếu API vỡ — Rủi ro 1).
- **"Xem tất cả"** — **Quyết định**: dựng `TxnSearchFilter` (Chi + khoảng kỳ đang xem + phạm vi danh mục + mới nhất trước) → `ensureTransactionController().setFilter(f)` → `popUntil(isFirst)` → `onSelectTab(1)`. **Lý do**: màn Giao dịch đã có sẵn hạ tầng lọc + gộp danh mục con (PBI 12) ⇒ SC-005 khớp số. **Phương án khác**: đẩy màn Giao dịch thứ hai (nhân bản controller).
- **Một phép lọc dùng chung** — **Quyết định**: thêm `budgetPeriodTransactions(...)` vào `budget_view.dart` và cho `budgetSpent` **fold** chính hàm đó; màn `03` hiển thị `take(5)`. **Lý do**: SC-005/FR-014 đòi tổng danh sách khớp 100% số đã dùng — một predicate thì không thể lệch. **Phương án khác**: hai bộ lọc song song (chính là chỗ dễ lệch số).
- **Dòng giao dịch** — **Quyết định**: tiêu đề = `note` (rỗng → tên danh mục), dòng phụ = `relativeDayLabel + HH:mm` (thêm `formatTimeLabel` vào `date_label.dart`), số tiền coral. **Lý do**: FR-012 đòi tên + thời gian, mockup vẽ tên người bán. **Phương án khác**: `buildDisplayRows` (không có thời gian ⇒ trượt FR-012).
- **Nút đổi kỳ** — **Quyết định**: `showModalBottomSheet` + danh sách kỳ giảm dần, kỳ đang xem đánh dấu. **Lý do**: pattern sẵn có của app, không thêm màn. **Phương án khác**: `PopupMenuButton` (chật khi ngân sách Tuần có hàng chục kỳ).
- **Không thêm dependency** — **Quyết định**: `pubspec.yaml` không đổi.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem [data-model.md](./data-model.md) — schema **v7** (thêm cột `is_archived`); 3 thực thể logic (`Budget` + `isArchived`, `BudgetPeriodSummary`, `BudgetDetail`) + 10 luật bất biến + bảng chuyển trạng thái (chỉ 1 chiều: đang theo dõi → đã lưu trữ).
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app thuần nội bộ, không API/CLI/endpoint lộ ra ngoài (đồng nhất PBI 19/20). Hợp đồng nội bộ duy nhất là `WalletRepository` — **không đổi chữ ký** (chỉ map thêm 1 cột).
- **Kịch bản khởi động nhanh**: xem [quickstart.md](./quickstart.md) — 14 nhóm kiểm thử tay A–N, phủ FR-001…FR-024 và SC-001…SC-012.

### Kiến trúc chi tiết

**1. Tầng nghiệp vụ thuần (`lib/core/budget/`)**

| File | Vai trò |
|---|---|
| `budget.dart` **(sửa)** | Thêm `final bool isArchived` (mặc định `false` — mọi chỗ khởi tạo cũ không đổi) + `Budget copyWith({int? categoryId, int? amount, BudgetPeriod? period, bool? isRecurring, DateTime? startDate, bool? isArchived})` |
| `budget_view.dart` **(sửa)** | Thêm `List<Transaction> budgetPeriodTransactions({categoryIds, transactions, range})` (Chi + phạm vi + khoảng ngày, **mới nhất trước**); `budgetSpent` **gọi lại** hàm này rồi cộng `-amount` (refactor thuần, không đổi hành vi); `buildBudgetOverview` **bỏ qua** dòng `budget.isArchived` |
| `budget_detail.dart` **(mới)** | Toàn bộ số liệu màn `03`, hàm thuần: `budgetPeriodOptions(budget, now)` → `List<DateRange>` (R5); `budgetDaysLeft(range, now)` / `budgetElapsedPercent(range, now)` (R6); `budgetPaceWarning({usedPercent, elapsedPercent, ended})` (R7); `budgetComparisonSeries({budget, transactions, categories, now, viewedRange, maxPeriods = 3})` → `List<BudgetPeriodSummary>` (lùi theo bước chu kỳ, dừng trước kỳ `startDate`); `class BudgetPeriodSummary {range, spent, limit, percent, level, ended}`; `class BudgetDetail {…}` + `buildBudgetDetail({budget, categories, transactions, now, viewedRange})` (gom tất cả + `periodOptions` + `transactions` đã lọc) |

**2. Tầng dữ liệu (sửa + sinh mã)**

| File | Thay đổi |
|---|---|
| `lib/data/db/app_database.dart` | `Budgets` thêm `BoolColumn isArchived` (default `false`); `schemaVersion => 7`; migration `if (from < 7) addColumn(budgets, budgets.isArchived)` |
| `lib/data/db/app_database.g.dart` | Sinh lại bằng `dart run build_runner build --delete-conflicting-outputs` (không sửa tay) |
| `lib/data/wallet_repository.dart` | **Không đổi chữ ký**; cập nhật doc comment của `budgets()` (trả **cả** ngân sách đã lưu trữ — view tự lọc) |
| `lib/data/wallet_repository_drift.dart` | Map thêm `isArchived` ↔ `is_archived` trong `budgets()` / `insertBudget` / `updateBudget` |
| `test/fakes/fake_wallet_repository.dart` | `insertBudget` giữ `isArchived`; seed ngân sách tuỳ chọn đã có sẵn từ PBI 20 (chỉ thêm trường) |

**3. Màn Chi tiết — `lib/screens/budget_detail_screen.dart` (mới, mockup `03`)**

- `StatefulWidget{ int budgetId; WalletRepository? repository; DateTime? now; ValueChanged<int>? onSelectTab; }` — nạp trong `initState`: `budgets()` (tìm theo `budgetId`) + `allTransactions()` + `categoriesIncludingHidden(expense)`; `_now` bơm được để test deterministic.
- `Scaffold` = `SubPageScaffold(title: tên danh mục, subtitle: 'Ngân sách @chu kỳ • @kỳ', actions: [nút đổi kỳ], child: ListView, bottomNavigationBar: SafeArea(Row 2 nút))` — **không** bottom nav.
- Thân màn 4 nhánh: **đang nạp** (spinner) → **lỗi** ("Không đọc được ngân sách." + Thử lại) → **không hợp lệ** (danh mục đã xóa: thông báo + nhắc gán lại, **ẩn** thẻ tiến độ/biểu đồ/danh sách; 2 nút vẫn hiện — FR-019) → **nội dung**.
- Nội dung theo thứ tự mockup:
  1. **Thẻ tiến độ** — nhãn "Đã dùng" + số tiền (màu theo 3 dải) + "trên {giới hạn} giới hạn"; phải: "Trạng thái" + huy hiệu (`_StatusBadge` — coral nhạt nền khi ≥ 80%); thanh tiến độ (dùng lại dải màu của màn `01`: teal / coral alpha 0.6 / coral); dòng cuối: trái "Vượt {số} đ" hoặc "Còn lại {số} đ", phải "@n ngày còn lại" hoặc **"Đã kết thúc"**.
  2. **Băng cảnh báo tốc độ** (chỉ khi `showPaceWarning`) — nền coral nhạt, icon `!` tròn coral, tiêu đề + "Đã dùng @p% ngày nhưng chi @q% ngân sách".
  3. **Khối SO SÁNH DỰ KIẾN • THỰC TẾ** — chú giải 2 ô màu, `BarChart` (cột đôi/kỳ, `maxY` = max(limit, max spent) × 1.15), `ExtraLinesData` nét đứt ở mức giới hạn kèm nhãn "Dự kiến {giới hạn}", nhãn kỳ dưới trục (kỳ đang xem đậm hơn).
  4. **GIAO DỊCH TRONG KỲ** + "Xem tất cả" — tối đa **5** dòng (`take(5)` của `detail.transactions`); mỗi dòng: bubble icon danh mục (màu danh mục, bám nếp `_BudgetRowTile`), tiêu đề (`note` → tên danh mục), dòng phụ `'Hôm nay, 12:30'`, số tiền coral; rỗng → trạng thái rỗng.
  5. **2 nút** ở `bottomNavigationBar`: **"Chỉnh sửa"** (viền, `OutlinedButton` cao 44px) và **"Lưu trữ ngân sách"** (`FilledButton` teal cao 44px) — hiển thị ở **mọi kỳ** (FR-024).
- Hành vi:
  - **Đổi kỳ**: nút lịch → `showModalBottomSheet` liệt kê `periodOptions` (giảm dần) → chọn → `setState(_viewedRange = …)`.
  - **Chỉnh sửa**: `push(BudgetFormScreen(budget: current, repository: _repository, now: _now))`; `true` → nạp lại **giữ kỳ đang xem** (khớp `range.start` trong `periodOptions` mới; không khớp → về kỳ mặc định — Rủi ro 4).
  - **Lưu trữ**: `showDialog` xác nhận → `updateBudget(copyWith(isArchived: true))` → `pop(true)` về màn Tổng quan (màn Tổng quan nạp lại ⇒ dòng biến mất).
  - **Xem tất cả**: dựng `TxnSearchFilter` (R10) → `ensureTransactionController().setFilter(f)` → `popUntil(isFirst)` → `onSelectTab?.call(1)`.
- `ValueKey`: `budget-detail-period-picker`, `budget-detail-period-<startISO>`, `budget-detail-edit`, `budget-detail-archive`, `budget-detail-see-all`, `budget-detail-confirm-archive`, `budget-detail-cancel-archive`.

**4. Sửa màn Tổng quan & khung dùng chung**

| File | Thay đổi |
|---|---|
| `lib/screens/budget_overview_screen.dart` | Chạm dòng → `_openDetail(budgetId)` (push `BudgetDetailScreen(onSelectTab: widget.onSelectTab, …)`); sau khi quay về → `_reloadSilent()` (sửa hoặc lưu trữ đều có thể đã đổi dữ liệu) |
| `lib/core/widgets/sub_page_scaffold.dart` | Thêm `String? subtitle` (app bar 2 dòng + `toolbarHeight` 68 khi có) |
| `lib/core/date_label.dart` | Thêm `String formatTimeLabel(DateTime)` → `'HH:mm'` |

**5. Dịch nhãn (FR-021)** — thêm ~25 khóa EN vào `lib/core/locale/sora_translations.dart` dưới mục "Ngân sách (PBI 21)": nhóm màn `03` (app bar phụ `'Ngân sách @chu kỳ • @kỳ'`, `'Đã dùng'`, `'Trạng thái'`, `'trên @số đ giới hạn'`, 3 dạng huy hiệu `'Bình thường/Sắp đạt/Vượt @p%'`, `'Vượt @số đ'`, `'Tốc độ chi tiêu nhanh hơn dự kiến'`, `'Đã dùng @p% ngày nhưng chi @q% ngân sách'`, `'SO SÁNH DỰ KIẾN • THỰC TẾ'`, `'Dự kiến'`/`'Thực tế'`, `'Dự kiến @số đ'`, `'GIAO DỊCH TRONG KỲ'`, `'Xem tất cả'`, trạng thái rỗng + dòng phụ, `'Chỉnh sửa'`, `'Lưu trữ ngân sách'`, `'Lưu trữ'`, hộp thoại xác nhận (tiêu đề + thân), `'Chọn kỳ'`, nhãn kỳ `'Tuần @từ – @đến'` / `'Năm @năm'`, nhãn trục `'T@tháng'` / `'@ngày/@tháng'`) + trạng thái không hợp lệ. Chuỗi động dùng `trParams`, không nối chuỗi tay. `sora_translations_test` tự quét literal `.tr` ⇒ thiếu khóa là đỏ.

**6. Test**

| File | Nội dung |
|---|---|
| `test/budget_detail_test.dart` **(mới)** | `budgetPeriodOptions`: Tháng 3 kỳ liên tiếp, Tuần (bắt đầu Thứ Hai), Năm; ngân sách không lặp lại → **1** lựa chọn; không có kỳ trước `startDate`. `budgetDaysLeft`/`budgetElapsedPercent`: mốc 12/09 trong tháng 9 → **18 ngày còn lại / 40%**; ngày cuối kỳ → 0, không âm; kỳ đã qua → 0. `budgetPaceWarning`: 107% vs 40% → true; 40% vs 90% → false; `ended` → false. `budgetComparisonSeries`: 3 kỳ đúng thứ tự (kỳ đang xem cuối), dừng trước kỳ `startDate`, kỳ đang xem ở quá khứ → 3 kỳ tính đến nó, mới có 1–2 kỳ → 1–2 phần tử. `buildBudgetDetail`: `spent` = tổng Chi gồm **danh mục con**, bỏ Thu/transfer; `overAmount`/`remainingAmount` đúng ở mốc 100%; `transactions` **mới nhất trước** và tổng khớp `spent` (SC-005); `category == null` → không hợp lệ |
| `test/budget_detail_screen_test.dart` **(mới)** | Render đủ thành phần mockup (app bar 2 dòng, "Đã dùng", "trên … giới hạn", "Trạng thái", huy hiệu, "Vượt … đ", "… ngày còn lại", "SO SÁNH…", "GIAO DỊCH TRONG KỲ", "Xem tất cả", 2 nút); chưa vượt → huy hiệu **không** có chữ "Vượt" + hiện "Còn lại …"; vượt → huy hiệu "Vượt 107%" + "Vượt … đ"; băng cảnh báo **hiện/ẩn** theo `% đã dùng > % ngày`; **đổi kỳ** → số liệu + "Đã kết thúc" + băng ẩn; danh sách chỉ **5** dòng + tổng vẫn khớp; rỗng → trạng thái rỗng; **"Xem tất cả"** → `TransactionController.activeFilter` đúng (Chi + khoảng kỳ + phạm vi danh mục) + `onSelectTab(1)` được gọi + đã `pop`; **Chỉnh sửa** → mở `BudgetFormScreen` điền sẵn, lưu xong → số liệu theo giới hạn mới, **giữ kỳ đang xem**; **Lưu trữ** → hủy không ghi, xác nhận → `updateBudget` có `isArchived = true` + `pop(true)`; danh mục đã xóa → trạng thái không hợp lệ + 2 nút vẫn hiện; English → không còn nhãn tiếng Việt |
| `test/budget_view_test.dart` **(sửa)** | Thêm: `budgetPeriodTransactions` (chỉ Chi, gồm con, đúng khoảng, mới nhất trước) và `budgetSpent` khớp tổng danh sách; `buildBudgetOverview` **loại** dòng `isArchived` khỏi danh sách **và** khỏi thẻ tổng |
| `test/budget_overview_screen_test.dart` **(sửa)** | Đổi khẳng định "chạm dòng → Sửa ngân sách" thành "chạm dòng → mở **Chi tiết Ngân sách**"; giữ nguyên các test khác |
| `test/budgets_dao_test.dart` **(sửa)** | `isArchived` mặc định `false` khi insert; `updateBudget` ghi được `isArchived = true` rồi đọc lại; migration: DB v6 giả lập (`user_version = 6`, không có cột) → mở lại có cột, **dữ liệu ngân sách cũ nguyên vẹn** (bám khuôn `transactions_dao_test`) |
| `test/fakes/fake_wallet_repository.dart` **(sửa)** | `insertBudget` giữ `isArchived` |

Ghi chú test: test đụng `.tr` phải khôi phục `Get.locale` trong `addTearDown` (bài học PBI 19); test màn dùng `FakeWalletRepository` ⇒ không cần sqlite native; mọi số liệu tính theo `now` **bơm tham số**, không dùng giờ thật; test "Xem tất cả" cần `Get.put(TransactionController(fake))` (hoặc `Get.testMode`) rồi dọn `Get.reset()`.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline, không server | ✅ | Chỉ thêm 1 cột sqlite; biểu đồ vẽ cục bộ |
| Không sửa dữ liệu người dùng ngoài phạm vi | ✅ | Chỉ ghi `budgets.is_archived`; giao dịch/danh mục/ví chỉ **đọc**; lưu trữ không xoá giao dịch (FR-017, test phủ) |
| Transfer & Thu không tính vào chi | ✅ | Một predicate duy nhất trong `budgetPeriodTransactions`; dùng cho cả số đã dùng lẫn danh sách lẫn bộ lọc "Xem tất cả" |
| Design system + dark mode | ✅ | Không hex cứng mới: teal/coral/trung tính đều qua `AppColors`/`SoraColors`; chart nhận màu qua tham số |
| Màn con không bottom nav | ✅ | `SubPageScaffold` (không bottom nav); chỉ **đổi** cấu hình app bar, không đổi hành vi màn khác |
| i18n đầy đủ (PBI 19) | ✅ | ~25 khóa mới; `sora_translations_test` quét tự động ⇒ thiếu khóa là đỏ; QA nhóm M gạch đầu dòng từng nhãn |
| YAGNI / không abstraction sớm | ✅ | Không `BudgetController`, không repository mới, không bảng snapshot, không bảng archive riêng, không cột `archived_at` chưa dùng, không thêm dependency; **một** file module thuần mới là chỗ chứa đúng trách nhiệm |
| Không phá vỡ test hiện có | ✅ (cần kiểm chứng khi thi công) | `Budget.isArchived` có default; `WalletRepository` không đổi chữ ký; chỉ 1 khẳng định trong `budget_overview_screen_test` phải cập nhật theo FR-001 |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── core/
│   │   ├── budget/
│   │   │   ├── budget.dart                        # SỬA: +isArchived, +copyWith
│   │   │   ├── budget_view.dart                   # SỬA: +budgetPeriodTransactions, budgetSpent fold, loại archived
│   │   │   ├── budget_detail.dart                 # MỚI — số liệu màn 03 (thuần)
│   │   │   └── budget_rules.dart                  # giữ nguyên
│   │   ├── date_label.dart                        # SỬA: +formatTimeLabel
│   │   ├── locale/sora_translations.dart          # SỬA: +~25 khóa EN
│   │   └── widgets/sub_page_scaffold.dart         # SỬA: +subtitle
│   ├── data/
│   │   ├── db/app_database.dart                   # SỬA: cột is_archived, schemaVersion 7, migration
│   │   ├── db/app_database.g.dart                 # SINH LẠI (build_runner)
│   │   ├── wallet_repository.dart                 # SỬA: doc comment (không đổi chữ ký)
│   │   └── wallet_repository_drift.dart           # SỬA: map isArchived
│   └── screens/
│       ├── budget_detail_screen.dart              # MỚI — màn 03
│       └── budget_overview_screen.dart            # SỬA: chạm dòng → màn Chi tiết
└── test/
    ├── budget_detail_test.dart                    # MỚI
    ├── budget_detail_screen_test.dart             # MỚI
    ├── budget_view_test.dart                      # SỬA
    ├── budget_overview_screen_test.dart           # SỬA (1 khẳng định)
    ├── budgets_dao_test.dart                      # SỬA
    └── fakes/fake_wallet_repository.dart          # SỬA
```

Không tạo `contracts/`: dự án thuần nội bộ, không có giao diện lộ ra ngoài.

## Rủi ro & ngoại lệ có lý do

1. **`fl_chart` lần đầu dùng trong repo** (khai báo từ trước nhưng chưa có chỗ nào import). API 1.2.0 có thể khác ví dụ cũ (`BarChartData`/`BarChartRodData`/`ExtraLinesData`/`FlTitlesData`). **Giảm nhẹ**: dựng chart trong **một** widget riêng tư của `budget_detail_screen.dart` để đổi cách vẽ chỉ chạm 1 chỗ; `flutter analyze` bắt lỗi API ngay. **Phương án lùi đã cân nhắc**: tự vẽ cột bằng `Container` theo tỉ lệ + `CustomPaint` cho nét đứt (~60 dòng, không nhãn trục) — chỉ dùng nếu API vỡ không đáng sửa.
2. **"Ngày còn lại" lệch 1 ngày giữa màn `01` (PBI 20, không tính hôm nay) và màn `03` (tính hôm nay).** Công thức màn `03` khớp mockup ("18 ngày còn lại"). **Quyết định**: **không** sửa màn `01` trong PBI này (ngoài phạm vi, có test riêng đang khẳng định số cũ). **Nếu** người dùng muốn đồng bộ: đổi màn `01` sang gọi `budgetDaysLeft` — một dòng trong `buildBudgetOverview` + cập nhật 1 khẳng định test.
3. **Huy hiệu đúng 100% hiển thị "Vượt 100%"** (số tiền vượt = 0). FR-005 nói "từ 100% trở lên" dùng "Vượt"; biên spec chỉ đòi "thể hiện đã đạt giới hạn". **Giảm nhẹ**: ghi nhận; nếu thấy khó đọc, thêm **một** nhánh `percent == 100 → 'Đạt 100%'` ở `_StatusBadge`.
4. **Đổi chu kỳ ngân sách ở màn Sửa ⇒ kỳ đang xem có thể không còn tồn tại** (VD Tháng → Tuần). **Giảm nhẹ**: sau khi nạp lại, khớp kỳ đang xem theo `range.start` trong danh sách mới; không khớp → về kỳ mặc định của chu kỳ mới (không lỗi, không màn trắng); test phủ nhánh này (nhóm H mục 4).
5. **Test cũ khẳng định "chạm dòng → Sửa ngân sách"** sẽ đỏ vì FR-001 đổi hành vi. **Giảm nhẹ**: đã liệt kê trong cấu trúc dự kiến; sửa **đúng 1 khẳng định** (không nới lỏng test).
6. **Sinh mã drift v7 bắt buộc.** Quên chạy `build_runner` ⇒ `app_database.g.dart` thiếu getter `isArchived` ⇒ analyze/test đỏ ngay. **Giảm nhẹ**: ghi bước 0 trong `quickstart.md` và trong `tasks.md`.
7. **`budgets()` trả cả ngân sách đã lưu trữ** ⇒ mọi nơi đọc phải tự lọc (hiện chỉ `buildBudgetOverview`). **Giảm nhẹ**: lọc tập trung ở **một** chỗ (view thuần) + test khẳng định; khi PBI sau cần màn "Đã lưu trữ" thì lọc theo cờ, hoặc thêm method riêng — lúc đó mới đổi.
8. **`onSelectTab` truyền 2 tầng** (shell → màn Tổng quan → màn Chi tiết). Nếu null (ví dụ màn Chi tiết mở từ chỗ khác sau này), "Xem tất cả" vẫn đặt được bộ lọc và `popUntil` về shell nhưng **không** đổi tab. **Giảm nhẹ**: test khẳng định cả hai nhánh (có/không callback); điểm vào duy nhất hiện tại luôn truyền callback.
9. **"Xem tất cả" phụ thuộc `TransactionController` singleton.** Nếu controller chưa từng `load()`/chưa có `data`, `setFilter` vẫn đúng nhưng view lọc chỉ dựng sau `load()` kế tiếp (AppShell gọi khi đổi tab) — đúng luồng thực tế. **Giảm nhẹ**: test bơm fake repository + gọi `load(now:)` trước khi kiểm tập lọc (SC-005).
10. **Danh sách giao dịch chỉ hiển thị 5 dòng** ⇒ SC-005 (tổng khớp) chỉ kiểm chứng được đầy đủ qua "Xem tất cả" + test tự động. **Giảm nhẹ**: QA nhóm G đối chiếu tổng ở màn Giao dịch; test khẳng định tổng `detail.transactions` khớp `spent`.

## Việc bàn giao kèm (ngoài code)

- Tick `checklists/requirements.md` sau khi thi công xong (giữ nguyên nội dung đã duyệt).
- Đồng bộ wiki (`wiki-knowledge/`) theo skill `sora-wiki`: page **Ngân sách** (schema **v7** với `is_archived`, màn `03` đã dựng, công thức ngày còn lại gồm hôm nay, ngưỡng cảnh báo nhịp `% dùng > % ngày`, so sánh 3 kỳ dự kiến–thực tế tính từ dữ liệu, `fl_chart` đã dùng, lưu trữ một chiều **chưa có nơi xem lại**), page **Lộ trình phát triển** (đóng phần 2c ở mức tối thiểu đã dựng, ghi PBI 21 xong, còn lại 2b + phần còn lại của 2c), page **Design system** (cột "Dự kiến" màu trung tính, đường mốc nét đứt) + append `wiki-knowledge/log.md`.
