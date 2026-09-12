# Danh sách Task: Tổng quan Ngân sách (ngân sách theo danh mục)

**Mã PBI**: 20
**Nguồn**: plan.md, spec.md, data-model.md, research.md, quickstart.md
**Ngày tạo**: 2026-09-12

## Định dạng task

`- [ ] [MãTask] [P?] [Story?] Mô tả kèm đường dẫn file`

- `[P]`: có thể chạy song song (khác file, không phụ thuộc task chưa xong)
- `[Story]`: bắt buộc ở pha User Story (VD `[US1]`), không dùng ở Setup/Foundational/Polish
- Mọi đường dẫn tính từ `app/sora_thu_chi/`

## Pha 1: Setup

- [X] T001 [P] Lấy mốc xanh trước khi sửa: chạy `flutter pub get` rồi `flutter test` tại `app/sora_thu_chi/` (kỳ vọng 472 test xanh) và xác nhận `pubspec.yaml` **không đổi** (research R13 — không thêm package)

## Pha 2: Foundational

*(Bắt buộc xong trước khi làm bất kỳ user story nào)*

- [X] T002 Thêm bảng `Budgets` (6 cột: `id`, `category_id`, `amount`, `period`, `is_recurring` default `true`, `start_date`; `@DataClassName('BudgetsRow')`) + `schemaVersion => 6` + migration `if (from < 6) await m.createTable(budgets);` (**không seed**) tại `lib/data/db/app_database.dart`
- [X] T003 Sinh lại `lib/data/db/app_database.g.dart` bằng `dart run build_runner build --delete-conflicting-outputs` (không sửa tay; phụ thuộc T002)
- [X] T004 [P] Tạo `lib/core/budget/budget.dart`: `enum BudgetPeriod { weekly, monthly, yearly }` + extension `label` (`Tuần`/`Tháng`/`Năm`) + `class Budget { id, categoryId, amount, period, isRecurring, startDate }`
- [X] T005 [P] Tạo `lib/core/budget/budget_view.dart`: `DateRange` (`end` độc quyền) + `budgetPeriodRange(period, anchor)` (tháng/năm dương lịch, **tuần bắt đầu Thứ Hai**) + `budgetScopeCategoryIds(categoryId, categories)` (bản thân + con trực tiếp, không lấy cháu) + `budgetSpent` (chỉ `type == expense`, `categoryId ∈ scope`, `transactionDate ∈ [start, end)`, đã chi = `-tổng amount`) + `enum BudgetStatus {active, ended, invalid}` + `enum ProgressLevel {normal, near, over}` + `budgetProgressLevel(percent)` + `class BudgetRow` + `class BudgetOverview` + `buildBudgetOverview({budgets, transactions, categories, now, viewedMonth})` (tính dòng, thẻ tổng, `daysLeft`, sắp xếp theo data-model.md)
- [X] T006 [P] Tạo `lib/core/budget/budget_rules.dart`: `budgetEffectiveRange(budget)`, `budgetOverlaps(a, b)` (cùng `categoryId` + cùng `period` + khoảng hiệu lực giao nhau), `findOverlappingBudget({candidate, existing})` (bỏ qua chính nó theo `id`), `validateBudgetForm(...)` trả khóa thông báo lỗi ("Vui lòng chọn danh mục." / "Vui lòng nhập số tiền lớn hơn 0." / "Đã có ngân sách cho danh mục này trong kỳ. Hãy sửa ngân sách đang có.")
- [X] T007 Thêm 3 method `budgets()`, `insertBudget(Budget)` (bỏ qua id, DB sinh), `updateBudget(Budget)` (ghi theo id) vào interface `lib/data/wallet_repository.dart` kèm doc comment
- [X] T008 Impl 3 method tại `lib/data/wallet_repository_drift.dart` (map dòng `budgets` ↔ domain `Budget`, enum `period` ↔ text) — phụ thuộc T007
- [X] T009 [P] Impl 3 method trên map bộ nhớ + seed ngân sách tuỳ chọn qua constructor additive (test cũ không đổi hành vi) tại `test/fakes/fake_wallet_repository.dart` — phụ thuộc T007
- [X] T010 [P] Viết `test/budget_test.dart`: `BudgetPeriod.label`; `budgetPeriodRange` cho 3 chu kỳ (tuần bắt đầu Thứ Hai, ranh giới tháng/năm, `end` độc quyền)
- [X] T011 [P] Viết `test/budget_view_test.dart`: `budgetScopeCategoryIds` (bản thân + con, không lấy cháu); `budgetSpent` chỉ tính Chi, bỏ Thu/transfer, đúng khoảng ngày, tạo giữa kỳ ra số ≠ 0; `budgetProgressLevel` ở 4 mốc 45/84/96/107%; `buildBudgetOverview`: tổng chỉ gồm dòng `active`, sắp giảm dần %, `daysLeft`, dòng `ended` (không lặp lại + kỳ đã qua) và `invalid` (danh mục không tồn tại) bị loại khỏi tổng; chu kỳ Tuần giữ kỳ của `now` khi `viewedMonth` đổi
- [X] T012 [P] Viết `test/budget_rules_test.dart`: `budgetOverlaps` cùng danh mục + cùng chu kỳ chồng thời gian → chồng; khác chu kỳ → không; không lặp lại đã qua kỳ → không; sửa chính nó → không tự chặn; `validateBudgetForm` trả đúng khóa lỗi khi thiếu danh mục / tiền ≤ 0
- [X] T013 Viết `test/budgets_dao_test.dart`: drift insert → `budgets()` đọc lại đủ 6 trường; `updateBudget` đổi `amount`/`isRecurring`; migration DB v5 giả lập (bỏ bảng `budgets`, `user_version = 5`) → mở lại tạo bảng và dữ liệu cũ nguyên vẹn; bảng **rỗng** sau khi tạo mới (không seed) — bám khuôn `test/transactions_dao_test.dart`
- [X] T014 Tách khối FAB tròn 52px teal khỏi `lib/core/app_shell.dart` sang `lib/core/widgets/add_transaction_fab.dart` và cho `app_shell.dart` dùng lại widget chung (giữ nguyên hành vi; test cũ vẫn xanh)

## Pha 3: User Story 1 - Màn Tổng quan Ngân sách (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: Từ tab Báo cáo, người dùng mở màn Tổng quan Ngân sách đúng mockup `01` — bộ chọn kỳ, thẻ tổng, danh sách từng danh mục với "đã chi / giới hạn", % và màu thanh tiến độ theo 3 dải ngưỡng.
**Tiêu chí kiểm thử độc lập**: Seed `FakeWalletRepository` sẵn vài ngân sách + giao dịch Chi/Thu/transfer → mở màn bằng 1 lần chạm từ tab Báo cáo → thấy đúng số đã chi (Thu và transfer không ảnh hưởng), đúng màu teal/coral nhạt/coral ở 45/84/96/107%, đổi kỳ tháng thì số liệu tính lại, chạm tab khác ở bottom nav thì gọi `onSelectTab`.

- [X] T015 [US1] Tạo `lib/screens/budget_overview_screen.dart` — khung `Scaffold`: `StatefulWidget{ WalletRepository? repository; ValueChanged<int>? onSelectTab; }`, nạp trong `initState` (`budgets()` + `allTransactions()` + `categoriesIncludingHidden(expense)`), `_now` bơm được để test; thân dùng `ScreenHeader(title: 'Ngân sách'.tr, trailing: nút '+' tròn)` + bộ chọn kỳ (mũi tên trước/sau, nhãn `'Tháng @tháng, @năm'`, `ValueKey('budget-month-prev'/'budget-month-next')`); `bottomNavigationBar: AppBottomNavBar(selectedIndex: 2, onTabSelected: …)` — chạm tab khác thì `pop()` rồi gọi `onSelectTab` (FR-001, FR-002, research R1)
- [X] T016 [US1] Dựng 4 nhánh thân màn trong `lib/screens/budget_overview_screen.dart`: **đang nạp** (spinner) → **lỗi** ("Không đọc được ngân sách." + nút "Thử lại") → **rỗng** khi không có dòng nào (lời nhắc + nút "Thêm ngân sách", không hiện thẻ tổng/danh sách trơ — FR-019, research R9) → **nội dung** (FR-024: cuộn tới được phần tử cuối)
- [X] T017 [US1] Dựng thẻ tổng trong `lib/screens/budget_overview_screen.dart`: nhãn "Tổng ngân sách tháng này", cặp số `tổng đã chi / tổng giới hạn`, thanh tiến độ tổng, dòng "Còn lại … đ", dòng "… ngày còn lại" (FR-003, định dạng tiền qua `formatAmount`)
- [X] T018 [US1] Dựng widget dòng `_BudgetRowTile` trong `lib/screens/budget_overview_screen.dart`: vòng icon danh mục (token `SoraColors`) → tên + "đã chi / giới hạn" → nhãn chu kỳ cho dòng Tuần/Năm → **%** ở cuối dòng → thanh tiến độ bo `3px` bên dưới → `Divider`; màu 3 dải `<80%` teal, `80–99%` thanh `AppColors.coral.withValues(alpha: 0.6)` + % coral, `≥100%` thanh coral đậm + % coral, **không** hiện số tiền vượt; dòng `ended` hiện "Đã kết thúc", dòng `invalid` hiện "Danh mục đã bị xóa" (FR-004, FR-005, FR-020, FR-021, research R7)
- [X] T019 [US1] Gắn FAB dùng chung `AddTransactionFab` vào `lib/screens/budget_overview_screen.dart` (mở `AddTransactionScreen`) và **nạp lại** màn khi `push` trả `true` (SC-009)
- [X] T020 [US1] Sửa `lib/screens/report_screen.dart` (thêm tham số `onSelectTab`, thân tab = hàng điểm vào "Ngân sách" có icon + tên + mũi tên → `Navigator.push(BudgetOverviewScreen(onSelectTab: …))`) và `lib/core/app_shell.dart` (`_screens` từ `static const` → `late final`, bơm `onSelectTab: _onTabSelected`) — FR-001, SC-001
- [X] T021 [US1] Thêm khóa dịch EN cho màn `01` + hàng điểm vào tab Báo cáo vào `lib/core/locale/sora_translations.dart` (tiêu đề, thẻ tổng, "Còn lại @số đ", "@n ngày còn lại", `DANH MỤC`, "Sao chép tháng trước", "Tháng @tháng, @năm" → bản EN `@tháng/@năm`, "Đã kết thúc", "Danh mục đã bị xóa", chuỗi trạng thái rỗng + nút, "Không đọc được ngân sách.", "Thử lại"; chuỗi động dùng `trParams`) — FR-023, research R6
- [X] T022 [US1] Viết `test/budget_overview_screen_test.dart`: rỗng → lời nhắc + nút; có dữ liệu → tiêu đề + nút `+` + nhãn tháng + thẻ tổng + `DANH MỤC` + "Sao chép tháng trước" + dòng đúng "đã chi / giới hạn" và %; mũi tên đổi tháng → số liệu tính lại; dòng Tuần không đổi khi đổi kỳ tháng; dòng `ended` hiện "Đã kết thúc"; chạm tab khác ở bottom nav → gọi `onSelectTab`; test khôi phục `Get.locale` trong `addTearDown`

## Pha 4: User Story 2 - Màn Thêm/Sửa ngân sách (Ưu tiên: P2)

**Mục tiêu**: Người dùng đặt giới hạn chi tiêu cho một danh mục theo chu kỳ Tuần/Tháng/Năm, sửa lại được, và hệ thống chặn ngân sách chồng lấn.
**Tiêu chí kiểm thử độc lập**: Mở màn Thêm ngân sách từ nút `+` → đúng bố cục và mặc định mockup `02`; lưu thiếu danh mục / tiền 0 bị chặn kèm thông báo; lưu hợp lệ ghi vào repository và `pop(true)`; chạm một dòng ngân sách → mở chế độ sửa điền sẵn; tạo trùng danh mục + chu kỳ chồng thời gian bị chặn.

- [X] T023 [US2] Tạo `lib/screens/budget_form_screen.dart` với `SubPageScaffold(title: …, bottomNavigationBar: nút "Lưu ngân sách" cao 44px teal)` — **không** bottom nav; `StatefulWidget{ WalletRepository? repository; Budget? budget; }`; thứ tự khối đúng mockup `02`: **PHẠM VI NGÂN SÁCH** (2 lựa chọn, "Theo danh mục" chọn sẵn, "Tổng cộng" `onTap: () {}` no-op) → **DANH MỤC** (hàng `ValueKey('budget-category-row')` mở `CategoryPickerScreen(type: expense)` tái dùng nguyên vẹn, hiện icon + tên) → ô **SỐ TIỀN GIỚI HẠN** → **CHU KỲ** (3 chip `ValueKey('budget-period-weekly'/'budget-period-monthly'/'budget-period-yearly')`, mặc định Tháng) → hàng **"Ví áp dụng" = "Tất cả ví"** (no-op) → công tắc **"Lặp lại tự động mỗi kỳ"** (`ValueKey('budget-recurring-switch')`, **thật**, mặc định bật) → công tắc **"Cộng dồn phần chưa dùng hết"** (`onChanged: null`) → hàng **"Ngưỡng cảnh báo" = "80% và 100%"** (no-op) (FR-008, FR-009, FR-010, FR-012, FR-013, FR-014)
- [X] T024 [US2] Ô nhập số tiền trong `lib/screens/budget_form_screen.dart`: `ValueKey('budget-amount')` + `FilteringTextInputFormatter.digitsOnly` + `TextInputFormatter` riêng tư định dạng `3.000.000` ngay khi gõ (con trỏ về cuối), hậu tố `đ`, lưu bằng `parseAmount` (FR-011, research R12)
- [X] T025 [US2] Luồng lưu trong `lib/screens/budget_form_screen.dart` (`ValueKey('budget-save')`): `validateBudgetForm` → `findOverlappingBudget` (bỏ qua chính nó khi sửa) → `insertBudget`/`updateBudget` → `Navigator.pop(true)`; khi lỗi → **không lưu**, hiện `SnackBar` nền `AppColors.coral` với thông báo tương ứng (FR-015, FR-016, bám nếp `add_transaction_screen`)
- [X] T026 [US2] Thêm chế độ sửa vào `lib/screens/budget_form_screen.dart` (`budget != null` → tiêu đề "Sửa ngân sách", `startDate` giữ nguyên, điền sẵn danh mục/số tiền/chu kỳ/lặp lại) và nối chạm dòng ở `lib/screens/budget_overview_screen.dart` → mở `BudgetFormScreen(budget: …)`, nạp lại khi pop `true` (FR-017, FR-018)
- [X] T027 [US2] Thêm khóa dịch EN cho màn `02` vào `lib/core/locale/sora_translations.dart` (2 tiêu đề, "PHẠM VI NGÂN SÁCH", "Theo danh mục", "Tổng cộng", "DANH MỤC", "Chọn danh mục", "SỐ TIỀN GIỚI HẠN", "CHU KỲ", "Tuần"/"Tháng"/"Năm", "Ví áp dụng", "Tất cả ví", 2 nhãn công tắc, "Ngưỡng cảnh báo", "80% và 100%", "Lưu ngân sách", 3 thông báo lỗi validate) — FR-023
- [X] T028 [US2] Viết `test/budget_form_screen_test.dart`: mặc định đúng mockup (Theo danh mục / Tháng / Lặp lại bật / Cộng dồn tắt / Tất cả ví / 80% và 100%); gõ `3000000` → ô hiện `3.000.000`; Lưu thiếu danh mục → SnackBar + không ghi repo; Lưu tiền 0 → SnackBar; Lưu hợp lệ → ghi repo + `pop(true)`; chế độ sửa → tiêu đề "Sửa ngân sách" + điền sẵn; trùng danh mục + chu kỳ → SnackBar "Đã có ngân sách…" + không ghi; khôi phục `Get.locale` trong `addTearDown`

## Pha cuối: Polish & Cross-cutting

- [X] T029 Chạy `flutter analyze` (kỳ vọng sạch, không warning mới) và `flutter test` toàn bộ tại `app/sora_thu_chi/` — xác nhận 0 test đỏ, gồm `sora_translations_test` (thiếu khóa dịch là đỏ) và toàn bộ test cũ trong `test/`
- [X] T030 Chạy QA tay trên emulator Android theo `.specify/specs/20/quickstart.md` nhóm **A–N**, đối chiếu mockup `docs/budget/man-hinh-01-tong-quan-ngan-sach.svg` + `man-hinh-02-them-ngan-sach.svg`, rồi điền bảng "Ghi nhận kết quả" ở cuối `quickstart.md`
- [X] T031 Tick `.specify/specs/20/checklists/requirements.md` sau khi thi công xong (giữ nguyên nội dung đã duyệt)
- [X] T032 Đồng bộ wiki theo skill `sora-wiki`: page `wiki-knowledge/entity/Ngân sách.md` (schema v6, tính lại thay vì snapshot, mốc tuần Thứ Hai, khớp `category_id` + con, đóng ⚠ màu 80–99%, phạm vi 2a đã dựng màn `01`+`02`), page Lộ trình phát triển (ghi PBI 20 xong, còn lại 2b/2c + màn `03`), page Design system (dải coral nhạt) + append `wiki-knowledge/log.md`

## Sơ đồ phụ thuộc

```text
Setup (T001)
  └─ Foundational (T002 → T003; T004/T005/T006; T007 → T008/T009; T010–T013; T014)
       ├─ US1 (T015 → T016 → T017 → T018 → T019 → T020 → T021 → T022)
       └─ US2 (T023 → T024 → T025 → T026 → T027 → T028)

US1 và US2 chỉ gặp nhau ở T026 (chạm dòng ở màn Tổng quan mở màn Sửa).
T019 và T026 cùng sửa `budget_overview_screen.dart` ⇒ T026 phải chạy SAU T019.
Polish (T029 → T030 → T031 → T032) chạy sau khi cả 2 story xong.
```

## Ví dụ chạy song song

```text
# Foundational — nhóm logic thuần (khác file):
T004 [P] lib/core/budget/budget.dart
T005 [P] lib/core/budget/budget_view.dart
T006 [P] lib/core/budget/budget_rules.dart
T008 [P] lib/data/wallet_repository_drift.dart   (T007 xong trước)
T009 [P] test/fakes/fake_wallet_repository.dart  (T007 xong trước)

# Foundational — nhóm test logic thuần (khác file):
T010 [P] test/budget_test.dart
T011 [P] test/budget_view_test.dart
T012 [P] test/budget_rules_test.dart
```

## Chiến lược triển khai

- **MVP đề xuất**: User Story 1 (màn Tổng quan) — kiểm chứng được toàn bộ luật tính "đã chi / % / màu ngưỡng / đổi kỳ" bằng dữ liệu seed trong `FakeWalletRepository`, chưa cần màn nhập liệu.
- **Giao hàng tăng dần**: Foundational → US1 (đọc tiến độ) → US2 (tạo/sửa ngân sách) → Polish. Sau US2 mới có vòng dùng được trọn vẹn (tạo → thấy tiến độ); sau US1 chỉ là màn đọc với dữ liệu sẵn có.
- **Chốt chặn kỹ thuật**: T003 (`build_runner`) phải xong trước T008/T013, nếu không `app_database.g.dart` thiếu bảng `budgets` ⇒ analyze/test đỏ ngay (rủi ro 2 trong plan.md).
