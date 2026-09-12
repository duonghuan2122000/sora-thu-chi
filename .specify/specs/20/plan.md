# Kế hoạch triển khai: Tổng quan Ngân sách (ngân sách theo danh mục)

**Mã PBI**: 20
**Liên kết spec**: [.specify/specs/20/spec.md](./spec.md)
**Ngày tạo**: 2026-09-12
**Ngữ cảnh kỹ thuật bổ sung từ người dùng**: "Hãy lên giải pháp thi công cho PBI 20"

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12 / Flutter (Android + iOS), app **offline hoàn toàn** |
| Framework / Thư viện chính | GetX `^4.7.3` (điều hướng + DI + i18n), Material; **không thêm package nào** (research R13) |
| Lưu trữ dữ liệu | drift `^2.34.4` + sqlite local — **schema v5 → v6**, thêm bảng `budgets` (6 cột), không sửa bảng cũ, **không seed**; sinh lại `app_database.g.dart` bằng `build_runner` |
| Kiểm thử | `flutter_test` — 472 test hiện có; bổ sung 5 file test mới + sửa `FakeWalletRepository`; mục tiêu **không đỏ test cũ** |
| Nền tảng triển khai | Build local (`flutter build apk` / iOS build) — không server, không CI đặc thù |
| Ràng buộc hiệu năng | Màn Tổng quan tính lại "đã chi" bằng cách quét `transactions` **một lần** mỗi lần nạp (DB local một thiết bị, vài nghìn dòng ⇒ tức thời). Không snapshot, không cache (research R3) |
| Ràng buộc khác | Ngôn ngữ giao diện/tài liệu/commit: **tiếng Việt có dấu**; bám Design System (teal `#0F6E56` cho hành động chính, coral `#D85A30` **chỉ** cho chi tiêu/cảnh báo, thanh tiến độ = teal / coral nhạt / coral); mọi màu đi qua token `AppColors`/`SoraColors` để chạy đúng dark mode (PBI 18); mọi nhãn tĩnh phải có bản dịch EN (PBI 19) |
| Nguồn chân lý nghiệp vụ | `docs/budget/nghiep-vu-ngan-sach.md` (§3.1 mô hình, §4.1 khớp giao dịch, §4.2 chồng lấn, §4.3 vòng đời kỳ, §6 màu, §7 biên, §8 chia nhỏ **2a**) + mockup `man-hinh-01-tong-quan-ngan-sach.svg`, `man-hinh-02-them-ngan-sach.svg`; wiki `wiki-knowledge/entity/Ngân sách.md` |

*Không còn mục `NEEDS CLARIFICATION`: spec đã "Đã làm rõ" (0 điểm mở), các quyết định còn lại là chi tiết triển khai — xem `research.md`.*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

`.specify/memory/constitution.md` **không tồn tại** (repo chưa tạo hiến pháp) ⇒ đối chiếu theo `CLAUDE.md` của repo và các quyết định đã chốt trong `docs/`.

| Nguyên tắc (nguồn: CLAUDE.md + docs) | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline hoàn toàn, không server/không auth | ✅ | Chỉ thêm bảng sqlite local; không có API/đồng bộ |
| Ngôn ngữ giao diện/tài liệu/commit: tiếng Việt có dấu | ✅ | Mọi nhãn, tài liệu, comment, commit của PBI này bằng tiếng Việt |
| Stack đã chốt (drift + GetX) | ✅ | Dùng drift cho `budgets`; GetX chỉ cho `.tr`/điều hướng — **không** thêm `fl_chart` (biểu đồ thuộc PBI sau) |
| Design system: 1 màu thương hiệu teal, coral chỉ cho chi/cảnh báo, không hex cứng trong widget | ✅ | Thanh tiến độ 3 dải dùng `AppColors.teal` / `AppColors.coral` (+ alpha 0.6) / `SoraColors` token; card bo `10px`, nút chính bo `8px` cao `44px` |
| Số dư ví là đại lượng suy ra, không sửa tay | ✅ | Không đụng `wallets`; ngân sách cũng là đại lượng **suy ra** từ giao dịch (đúng tinh thần) |
| Thu/chi/chuyển khoản: transfer không tính là thu/chi | ✅ | "Đã chi" chỉ lấy `type == expense`; thu & transfer bị loại (FR-006) |
| Màn con của shell: app bar thương hiệu + back, **không** bottom nav | ✅ | Màn Thêm/Sửa ngân sách dùng `SubPageScaffold` (không bottom nav) — đúng FR-008. Màn Tổng quan **có** bottom nav theo đúng mockup `01` (ngoại lệ đã được spec chốt ở FR-001) |
| Bám mockup: phần chưa có hiệu lực thì hiển thị nhưng chưa kích hoạt | ✅ | "Tổng cộng", "Ví áp dụng", "Cộng dồn phần chưa dùng hết", "Ngưỡng cảnh báo", "Sao chép tháng trước" — hiện theo mockup, no-op (FR-009/014) |
| Không sửa dữ liệu người dùng ngoài phạm vi | ✅ | Chỉ ghi bảng `budgets` mới; không đụng `transactions`/`categories`/`wallets` |
| Quy trình PBI: spec → plan → task → implement | ✅ | Đang ở bước plan; `tasks.md` sinh ở bước sau |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại [research.md](./research.md). Tóm tắt các quyết định chính:

- **Điểm vào & bottom nav** — **Quyết định**: đẩy route `BudgetOverviewScreen` (không nút back), tự dựng `AppBottomNavBar(selectedIndex: 2)` + FAB, nhận callback `onSelectTab` từ `AppShell`; chạm tab khác = `pop()` rồi đổi tab. **Lý do**: mockup `01` là màn cấp tab nhưng có nút `+` riêng ⇒ không dùng được `SubPageScaffold`; callback là cách duy nhất để bottom nav ở màn đẩy chuyển tab thật. **Phương án khác**: nhúng thẳng vào tab Báo cáo (mất đường quay lại khung Báo cáo).
- **Schema v6, 6 cột** — **Quyết định**: `budgets(id, categoryId, amount, period, isRecurring, startDate)`, không seed. **Lý do**: 10 cột còn lại của doc §3.1 hoặc chưa có hiệu lực (2a), hoặc suy ra được (`status`). **Phương án khác**: dựng đủ 18 cột — thừa, và `status` lưu sẵn phải đồng bộ tay.
- **Không bảng snapshot** — **Quyết định**: tính lại "đã chi / % / còn lại / ngày còn lại" mỗi lần nạp màn. **Lý do**: doc §9 cho phép khi dữ liệu nhỏ; bỏ snapshot ⇒ SC-010 (không hồi tố kỳ trước) đúng hiển nhiên. **Phương án khác**: `budget_period_snapshots` + recompute — thêm bảng và thêm nguy cơ lệch dữ liệu.
- **Khớp giao dịch** — **Quyết định**: `type == expense` + `categoryId ∈ {danh mục} ∪ con` + `transaction_date ∈ [start, end)`; đã chi = `-tổng amount` (amount có dấu). **Lý do**: FR-006 + kịch bản 10/11. **Phương án khác**: khớp thêm theo text tên — dễ cộng nhầm.
- **Mốc kỳ** — **Quyết định**: tháng/năm dương lịch, tuần bắt đầu **Thứ Hai**. **Lý do**: đúng quy ước sẵn có (`resolveDatePreset`); spec giả định mốc mặc định. **Phương án khác**: `periodStartRule` — ngoài phạm vi.
- **Màu 80–99%** — **Quyết định**: `AppColors.coral.withValues(alpha: 0.6)` cho thanh, % vẫn coral đậm. **Lý do**: mockup `01` vẽ đúng vậy. **Phương án khác**: thêm token `coralLight` — cùng một màu, không nên thành token theme mới.
- **Thứ tự dòng** — **Quyết định**: active giảm dần theo %, dòng `ended`/`invalid` xuống cuối. **Lý do**: FR-022 + dòng không có % không thuộc thang đó.
- **Seam dữ liệu** — **Quyết định**: mở rộng `WalletRepository` (3 method), **không** thêm repository/controller; 2 màn là `StatefulWidget` + tham số `repository`. **Lý do**: seam này đã chứa `categories*`/`allTransactions`; bám nếp PBI 13–16. **Phương án khác**: `BudgetRepository` + `BudgetController` riêng (doc §9) — thêm file, không đổi hành vi.
- **Ô nhập tiền** — **Quyết định**: `digitsOnly` + formatter riêng tư định dạng `3.000.000` khi gõ, lưu bằng `parseAmount`. **Lý do**: FR-011 đòi phân tách nghìn; dùng lại `formatAmount`/`parseAmount`. **Phương án khác**: `AmountKeypad` — mockup vẽ bàn phím hệ thống, keypad đó không định dạng nghìn.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem [data-model.md](./data-model.md) — schema **v6**, bảng `budgets` 6 cột (không seed); 3 thực thể logic (Ngân sách, Kỳ ngân sách tính toán, Dòng hiển thị `BudgetRow`) + luật hợp lệ + chuyển trạng thái suy ra.
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app thuần nội bộ, không API/CLI/endpoint lộ ra ngoài (đồng nhất PBI 19). Hợp đồng nội bộ duy nhất là 3 method repository, mô tả trong `data-model.md`.
- **Kịch bản khởi động nhanh**: xem [quickstart.md](./quickstart.md) — 14 nhóm kiểm thử tay A–N, phủ FR-001…FR-024 và SC-001…SC-014.

### Kiến trúc chi tiết

**1. Tầng nghiệp vụ thuần (mới — bám khuôn `core/transaction/` + `core/wallet/wallet_rules.dart`)**

| File mới | Vai trò |
|---|---|
| `lib/core/budget/budget.dart` | `enum BudgetPeriod { weekly, monthly, yearly }` + extension `label` (`Tuần`/`Tháng`/`Năm`); `class Budget { id, categoryId, amount, period, isRecurring, startDate }` |
| `lib/core/budget/budget_view.dart` | Hàm thuần: `DateRange` + `budgetPeriodRange(period, anchor)`; `budgetScopeCategoryIds(categoryId, categories)` (bản thân + con); `budgetSpent(...)`; `enum BudgetStatus {active, ended, invalid}`, `enum ProgressLevel {normal, near, over}` + `budgetProgressLevel(percent)`; `class BudgetRow`; `class BudgetOverview` + `buildBudgetOverview({budgets, transactions, categories, now, viewedMonth})` (tính dòng, thẻ tổng, `daysLeft`, sắp xếp) |
| `lib/core/budget/budget_rules.dart` | `validateBudgetForm(...)` → khóa thông báo lỗi; `budgetEffectiveRange(budget)`; `budgetOverlaps(a, b)`; `findOverlappingBudget({candidate, existing})` |

**2. Tầng dữ liệu (sửa + sinh mã)**

| File | Thay đổi |
|---|---|
| `lib/data/db/app_database.dart` | Bảng `Budgets` (`@DataClassName('BudgetsRow')`), `schemaVersion => 6`, migration `if (from < 6) createTable(budgets)` — **không seed** |
| `lib/data/db/app_database.g.dart` | Sinh lại bằng `dart run build_runner build --delete-conflicting-outputs` (không sửa tay) |
| `lib/data/wallet_repository.dart` | Thêm `budgets()`, `insertBudget(Budget)`, `updateBudget(Budget)` + doc comment |
| `lib/data/wallet_repository_drift.dart` | Impl 3 method (map dòng ↔ domain, `insert` bỏ qua id, `update` ghi theo id) |
| `test/fakes/fake_wallet_repository.dart` | Impl 3 method trên map bộ nhớ; seed ngân sách tuỳ chọn qua constructor additive (test cũ không đổi) |

**3. Màn Tổng quan — `lib/screens/budget_overview_screen.dart` (mới, mockup `01`)**

- `StatefulWidget{ WalletRepository? repository; ValueChanged<int>? onSelectTab; }` — nạp trong `initState` (`budgets()` + `allTransactions()` + `categoriesIncludingHidden(expense)`), `_now` bơm được để test deterministic.
- `Scaffold`: thân = `ScreenHeader(title: 'Ngân sách'.tr, trailing: nút '+' tròn, bottom: bộ chọn kỳ)`; `bottomNavigationBar: AppBottomNavBar(selectedIndex: 2, onTabSelected: _onTabSelected)`; `floatingActionButton` = FAB dùng chung.
- Bộ chọn kỳ: chỉ đổi **tháng** đang xem (`Rx`/`setState`), mũi tên trái/phải; nhãn `'Tháng @tháng, @năm'`; `ValueKey('budget-month-prev'/'budget-month-next')`.
- Thân màn 4 nhánh: **đang nạp** (spinner) → **lỗi** ("Không đọc được ngân sách." + Thử lại) → **rỗng** (lời nhắc + nút "Thêm ngân sách", FR-019) → **nội dung**: thẻ tổng (nhãn "Tổng ngân sách tháng này", `đã chi / giới hạn`, thanh tiến độ tổng, "Còn lại … đ", "… ngày còn lại") + tiêu đề nhóm `DANH MỤC` + liên kết "Sao chép tháng trước" (no-op) + danh sách `_BudgetRowTile`.
- `_BudgetRowTile`: vòng icon danh mục (nền `coralLightBg`/`tealLightBg` theo token, icon qua `categoryIcon`) → tên + "đã chi / giới hạn" → **%** cuối dòng (teal hoặc coral) → thanh tiến độ bo `3px` bên dưới → `Divider`. Dòng `ended` hiện nhãn **"Đã kết thúc"**, dòng `invalid` hiện **"Danh mục đã bị xóa"** thay cho %.
- Chạm dòng → mở màn Sửa (`BudgetFormScreen(budget: …)`); lưu xong (pop `true`) → nạp lại. Nút `+`/nút rỗng → màn Thêm; FAB → `AddTransactionScreen` (lưu xong → nạp lại).

**4. Màn Thêm/Sửa — `lib/screens/budget_form_screen.dart` (mới, mockup `02`)**

- `StatefulWidget{ WalletRepository? repository; Budget? budget; }` — `budget == null` = thêm (tiêu đề "Thêm ngân sách", `startDate = hôm nay`), khác null = sửa (tiêu đề "Sửa ngân sách", điền sẵn giá trị).
- Dùng `SubPageScaffold(title: …, bottomNavigationBar: nút "Lưu ngân sách" cao 44px teal)` — **không** bottom nav (FR-008).
- Thứ tự khối đúng mockup: **PHẠM VI NGÂN SÁCH** (segmented 2 lựa chọn; "Tổng cộng" `onTap: () {}` — no-op) → **DANH MỤC** (hàng mở `CategoryPickerScreen(type: expense)` tái dùng nguyên vẹn, hiện icon + tên) → **SỐ TIỀN GIỚI HẠN** (ô nhập `digitsOnly` + formatter phân tách nghìn, hậu tố `đ`) → **CHU KỲ** (3 chip Tuần/Tháng/Năm, mặc định Tháng) → hàng **"Ví áp dụng" = "Tất cả ví"** (no-op) → công tắc **"Lặp lại tự động mỗi kỳ"** (**thật**, mặc định bật, FR-013) → công tắc **"Cộng dồn phần chưa dùng hết"** (`onChanged: null` — vô hiệu, khớp trạng thái tắt của mockup) → hàng **"Ngưỡng cảnh báo" = "80% và 100%"** (no-op).
- Lưu: `validateBudgetForm` → `findOverlappingBudget` (bỏ qua chính nó khi sửa) → `insertBudget`/`updateBudget` → `Navigator.pop(true)`. Lỗi → `SnackBar` nền `AppColors.coral` (bám nếp màn Thêm giao dịch), không lưu.
- `ValueKey`: `budget-category-row`, `budget-amount`, `budget-period-weekly|monthly|yearly`, `budget-recurring-switch`, `budget-save`.

**5. Nối vào shell (sửa 3 file)**

| File | Thay đổi |
|---|---|
| `lib/screens/report_screen.dart` | Thêm tham số `ValueChanged<int>? onSelectTab`; thân tab = danh sách có hàng **"Ngân sách"** (icon + tên + dòng phụ + mũi tên) → `Navigator.push(BudgetOverviewScreen(onSelectTab: …))` |
| `lib/core/app_shell.dart` | `_screens` từ `static const` → `late final` (bơm `onSelectTab: _onTabSelected`); thay FAB inline bằng widget dùng chung |
| `lib/core/widgets/add_transaction_fab.dart` (**mới**) | Tách nguyên khối FAB tròn 52px teal khỏi `app_shell.dart` để màn Tổng quan dùng lại (2 nơi dùng ⇒ đáng tách) |

**6. Dịch nhãn (FR-023)** — thêm khóa EN vào `lib/core/locale/sora_translations.dart`, ~45 khóa theo 3 nhóm: màn `01` (tiêu đề, thẻ tổng, "Còn lại @số đ", "@n ngày còn lại", `DANH MỤC`, "Sao chép tháng trước", "Tháng @tháng, @năm", "Đã kết thúc", "Danh mục đã bị xóa", chuỗi trạng thái rỗng + nút, "Không đọc được ngân sách.", "Thử lại"); màn `02` (2 tiêu đề, "PHẠM VI NGÂN SÁCH", "Theo danh mục", "Tổng cộng", "DANH MỤC", "Chọn danh mục", "SỐ TIỀN GIỚI HẠN", "CHU KỲ", "Tuần"/"Tháng"/"Năm", "Ví áp dụng", "Tất cả ví", 2 nhãn công tắc, "Ngưỡng cảnh báo", "80% và 100%", "Lưu ngân sách", 3 thông báo lỗi); tab Báo cáo (hàng điểm vào + dòng phụ). Chuỗi động dùng `trParams`, không nối chuỗi tay. Test `sora_translations_test` tự quét literal `.tr` ⇒ thiếu khóa là đỏ.

**7. Test (mới 5 file + sửa 1 file fake)**

| File | Nội dung |
|---|---|
| `test/budget_test.dart` | `BudgetPeriod.label`; `budgetPeriodRange` cho 3 chu kỳ (tuần bắt đầu Thứ Hai, tháng/năm dương lịch, `end` độc quyền) |
| `test/budget_view_test.dart` | `budgetScopeCategoryIds` (bản thân + con, không lấy cháu); `budgetSpent` chỉ tính Chi, bỏ Thu/transfer, đúng khoảng ngày, tạo giữa kỳ ra số ≠ 0; `budgetProgressLevel` ở 4 mốc 45/84/96/107; dựng `BudgetOverview`: tổng chỉ gồm dòng active, sắp giảm dần %, `daysLeft`, dòng `ended` (không lặp lại + kỳ đã qua) và `invalid` (danh mục không tồn tại) bị loại khỏi tổng; chu kỳ Tuần giữ kỳ của `now` khi `viewedMonth` đổi |
| `test/budget_rules_test.dart` | `budgetOverlaps`: cùng danh mục + cùng chu kỳ chồng thời gian → chồng; khác chu kỳ → không; không lặp lại đã qua kỳ → không; sửa chính nó → không tự chặn; `validateBudgetForm` trả đúng khóa lỗi khi thiếu danh mục / tiền ≤ 0 |
| `test/budget_overview_screen_test.dart` | Rỗng → lời nhắc + nút; có dữ liệu → tiêu đề + `+` + nhãn tháng + thẻ tổng + `DANH MỤC` + "Sao chép tháng trước" + dòng đúng "đã chi / giới hạn" và %; mũi tên đổi tháng → số liệu tính lại; dòng Tuần không đổi; dòng ended hiện "Đã kết thúc"; chạm dòng → mở màn Sửa; bottom nav chạm tab khác → gọi `onSelectTab` |
| `test/budget_form_screen_test.dart` | Mặc định đúng mockup (Theo danh mục / Tháng / Lặp lại bật / Cộng dồn tắt / Tất cả ví / 80% và 100%); gõ `3000000` → ô hiện `3.000.000`; Lưu thiếu danh mục → SnackBar + không ghi repo; Lưu tiền 0 → SnackBar; Lưu hợp lệ → ghi repo + pop `true`; chế độ sửa → tiêu đề "Sửa ngân sách" + điền sẵn; trùng danh mục + chu kỳ → SnackBar "Đã có ngân sách…" + không ghi |
| `test/budgets_dao_test.dart` | Drift: insert → `budgets()` đọc lại đủ 6 trường; `updateBudget` đổi `amount`/`isRecurring`; migration: DB v5 giả lập (bỏ bảng `budgets`, `user_version = 5`) → mở lại tạo bảng, dữ liệu cũ nguyên vẹn (bám khuôn `transactions_dao_test`); bảng **rỗng** sau khi tạo mới (không seed) |
| `test/fakes/fake_wallet_repository.dart` (sửa) | Thêm map ngân sách + 3 method; seed tuỳ chọn qua constructor additive ⇒ test cũ không đổi hành vi |

Ghi chú test: các test đụng `.tr` phải khôi phục `Get.locale` trong `addTearDown` (bài học PBI 19); test màn dùng `FakeWalletRepository` ⇒ không cần sqlite native; mọi test tính theo `now` **bơm tham số**, không dùng giờ thật.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline, không server | ✅ | Chỉ thêm 1 bảng sqlite local |
| Không sửa dữ liệu người dùng ngoài phạm vi | ✅ | Chỉ ghi `budgets`; giao dịch/danh mục/ví chỉ **đọc** |
| Transfer & Thu không tính vào chi | ✅ | `budgetSpent` lọc `type == expense`; test phủ |
| Design system + dark mode | ✅ | 3 dải màu qua `AppColors` + token `SoraColors`; không hex cứng mới |
| Màn con không bottom nav | ✅ | Màn `02` dùng `SubPageScaffold`; màn `01` có bottom nav **theo đúng FR-001/mockup** (ngoại lệ spec đã chốt) |
| i18n đầy đủ (PBI 19) | ✅ | ~45 khóa mới; `sora_translations_test` quét tự động ⇒ thiếu khóa là đỏ; QA nhóm M |
| YAGNI / không abstraction sớm | ✅ | Không `BudgetController`, không `BudgetRepository`, không bảng snapshot, không 10 cột chưa dùng, không token màu mới, không `fl_chart`; chỉ tách FAB vì có **2 nơi** dùng thật |
| Không thêm dependency | ✅ | pubspec không đổi |
| Không phá vỡ test hiện có | ✅ (cần kiểm chứng khi thi công) | `WalletRepository` thêm method ⇒ `FakeWalletRepository` phải impl; các màn/test cũ không đổi hành vi |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── core/
│   │   ├── budget/                                   # MỚI (3 file — module thuần)
│   │   │   ├── budget.dart                           # BudgetPeriod, Budget
│   │   │   ├── budget_view.dart                       # kỳ, khớp danh mục, đã chi, %, BudgetRow/Overview
│   │   │   └── budget_rules.dart                      # validate + chồng lấn
│   │   ├── locale/sora_translations.dart              # SỬA: +~45 khóa EN
│   │   ├── widgets/add_transaction_fab.dart           # MỚI (tách từ app_shell)
│   │   └── app_shell.dart                             # SỬA: _screens non-const + onSelectTab + FAB chung
│   ├── data/
│   │   ├── db/app_database.dart                       # SỬA: bảng budgets, schemaVersion 6, migration
│   │   ├── db/app_database.g.dart                     # SINH LẠI (build_runner)
│   │   ├── wallet_repository.dart                     # SỬA: +3 method
│   │   └── wallet_repository_drift.dart               # SỬA: impl 3 method
│   └── screens/
│       ├── budget_overview_screen.dart                # MỚI — màn 01
│       ├── budget_form_screen.dart                    # MỚI — màn 02 (thêm/sửa)
│       └── report_screen.dart                         # SỬA: hàng điểm vào "Ngân sách"
└── test/
    ├── budget_test.dart · budget_view_test.dart · budget_rules_test.dart        # MỚI
    ├── budget_overview_screen_test.dart · budget_form_screen_test.dart · budgets_dao_test.dart  # MỚI
    └── fakes/fake_wallet_repository.dart              # SỬA: +map ngân sách & 3 method
```

Không tạo `contracts/`: dự án thuần nội bộ, không có giao diện lộ ra ngoài.

## Rủi ro & ngoại lệ có lý do

1. **Ngoại lệ có lý do — màn Tổng quan có thanh điều hướng đáy dù là màn đẩy.** Nguyên tắc chung của app là "màn con đè shell thì không bottom nav"; FR-001 + mockup `01` chốt ngược lại cho màn này (nó là **màn cấp tab**, tab Báo cáo đang chọn). **Giảm nhẹ**: bottom nav ở màn này là **widget thật dùng lại** (`AppBottomNavBar`), tab sáng đúng, chạm tab khác thì `pop()` + đổi tab qua callback — không nhân bản state của shell, không có nav giả.
2. **Sinh mã drift bắt buộc.** Quên chạy `build_runner` ⇒ `app_database.g.dart` thiếu bảng ⇒ analyze/test đỏ ngay. **Giảm nhẹ**: ghi rõ trong `quickstart.md` bước 0 và trong `tasks.md`; `flutter analyze` sẽ bắt lỗi thiếu getter.
3. **`WalletRepository` thêm method ⇒ mọi impl phải cập nhật.** Interface này được `FakeWalletRepository` (test) impl; thiếu impl ⇒ toàn bộ test màn cũ không biên dịch. **Giảm nhẹ**: cập nhật fake **cùng bước** với interface; đã liệt kê trong cấu trúc dự kiến.
4. **Sót nhãn tĩnh tiếng Việt (SC-011 đòi 0).** Test `sora_translations_test` chỉ bắt lỗi "gắn `.tr` mà thiếu khóa", **không** bắt lỗi "quên gắn `.tr`". **Giảm nhẹ**: QA tay **nhóm M** ở chế độ English, gạch đầu dòng từng nhãn của cả 2 màn.
5. **Nhãn tiếng Anh dài hơn tiếng Việt** ("Cộng dồn phần chưa dùng hết" / "Auto-repeat every period") ở cỡ chữ lớn → tràn/cắt. **Giảm nhẹ**: dùng `Expanded` + `maxLines`/`ellipsis` như các màn PBI 17/19; QA nhóm M mục 3.
6. **Thứ tự dòng và trạng thái rỗng chỉ là suy luận từ mockup** (mockup không thể hiện thứ tự; spec ghi rõ cần chốt lại nếu muốn giữ thứ tự tạo). Đã chốt **giảm dần theo %** (FR-022). **Hệ quả đã biết**: ngân sách chu kỳ Tháng tạo ở tháng 9 vẫn hiện ở tháng 6 với 0% (spec không kiểm thử); nếu người dùng thấy vô lý thì đổi sang "ẩn ngân sách tạo sau kỳ đang xem" — một điều kiện trong `buildBudgetOverview`.
7. **Cột `ended`/`invalid` không có %** ⇒ không nằm trong thang sắp xếp của FR-022; đã chốt đẩy xuống cuối danh sách. Nếu spec sau muốn "đã kết thúc" biến mất khỏi danh sách thì sửa ở một chỗ (`buildBudgetOverview`).
8. **Không có FAB mới nhưng có FAB của shell trên màn Tổng quan**: chạm FAB mở màn Thêm giao dịch (PBI 11) rồi quay lại — màn Tổng quan phải **nạp lại** để số đã chi khớp (SC-009). **Giảm nhẹ**: nạp lại khi `push` trả `true`; test `budget_overview_screen_test` phủ nhánh này.
9. **`categoriesIncludingHidden` cho danh mục ngân sách**: ngân sách gắn danh mục **đang ẩn** vẫn hợp lệ (ẩn ≠ xoá) — chọn có ý thức để FR-021 chỉ kích hoạt khi danh mục **không còn** trong bảng. Test phủ cả 2 nhánh.

## Việc bàn giao kèm (ngoài code)

- Tick `checklists/requirements.md` sau khi thi công xong (giữ nguyên nội dung đã duyệt).
- Đồng bộ wiki (`wiki-knowledge/`) theo skill `sora-wiki`: page **Ngân sách** (schema v6 6 cột, bỏ snapshot table ⇒ tính lazy, mốc tuần Thứ Hai, khớp theo `category_id` + con, đóng ⚠ "màu 80–99%" bằng coral alpha 0.6, phạm vi 2a đã dựng màn `01`+`02`), page **Lộ trình phát triển** (đóng điểm mở tương ứng, ghi PBI 20 đã xong, còn lại 2b/2c + màn `03`), page **Design system** (dải coral nhạt) + append `wiki-knowledge/log.md`.
