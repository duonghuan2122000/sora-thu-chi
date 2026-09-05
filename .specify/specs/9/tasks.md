# Danh sách Task: Màn hình danh sách giao dịch

**Mã PBI**: 9
**Nguồn**: plan.md, spec.md, data-model.md, research.md, quickstart.md

## Pha 1: Setup

*(Không có task — PBI 9 **không đổi schema** (giữ `schemaVersion` 2, bảng `transactions` 8 cột PBI 8) và không thêm dependency/pubspec mới: drift `^2.34.4` + GetX + flutter_lints đã khai báo từ PBI 7; `build_runner` **không cần chạy** vì không thêm bảng/cột drift. Toàn bộ là đọc & trình bày dữ liệu có sẵn, dựng trên seam `WalletRepository` + pattern controller/deps đã có.)*

## Pha 2: Foundational

*(Hạ tầng bắt buộc xong trước user story: domain `Transaction` mang `transferGroupId`; seam `WalletRepository.allTransactions()` + impl Drift/Fake; hàm thuần gộp/nhóm/thống kê/header ngày; `TransactionController` + deps singleton repository — theo plan.md "Cấu trúc dự án dự kiến" và R1–R8/R10.)*

- [X] T001 Sửa `app/sora_thu_chi/lib/core/transaction/transaction.dart`: thêm field **`transferGroupId` (int?, nullable)** vào `Transaction` (constructor mặc định `null`) — map 1-1 từ cột drift, phục vụ ghép cặp 2 vế transfer thành 1 dòng (spec FR-007, data-model §Thay đổi trên domain, R1); **additive** — không phá constructor/sort/`transactionsForWallet`/màn chi tiết ví đang dùng
- [X] T002 [P] Sửa `app/sora_thu_chi/lib/core/date_label.dart`: thêm hàm thuần `String formatDayGroupHeader(DateTime date, {DateTime? now})` — trả `'HÔM NAY - dd/MM/yyyy'` nếu cùng ngày `now`, `'HÔM QUA - dd/MM/yyyy'` nếu hôm trước, còn lại `'dd/MM/yyyy'` (tái dùng `_two`; spec FR-005)
- [X] T003 [P] Sửa `app/sora_thu_chi/lib/core/widgets/screen_header.dart`: thêm 2 tham số tùy chọn **giữ nguyên layout hiện tại** — `centerTitle` (bool, default false) và `trailing` (Widget?, default null); `centerTitle: true` → tiêu đề căn giữa, `trailing` đặt bên phải cùng hàng tiêu đề (research R9; màn Giao dịch dùng `trailing` = icon lọc, 3 màn main còn lại không truyền → không vỡ)
- [X] T004 Tạo `app/sora_thu_chi/lib/core/transaction/transaction_list.dart`: các hàm **thuần** inject `now` — (1) gộp cặp transfer: 2 dòng `type=transfer` chung `transferGroupId` → 1 item "Chuyển khoản", phụ đề `'ví nguồn → ví đích'` (nguồn = vế `amount<0`, đích = vế `amount>0`, tra tên ví từ `Map<int,String>` id→tên), số tiền `|amount|`; vế lẻ (group thiếu cặp) → dòng trung tính fallback, không crash; không transfer → giữ nguyên; (2) `List<DayGroup>` nhóm theo ngày lịch mới nhất trên, mỗi nhóm mang `day` + `header` (dùng `formatDayGroupHeader`) + rows xếp giảm dần, trùng ngày giờ ổn định theo `id` tăng; (3) `MonthStat monthlyIncomeExpense(all, now)` — `incomeTotal = Σ income.amount`, `expenseTotal = −Σ expense.amount` (dương), chỉ dòng `date ∈ [ngày 1 tháng dương lịch, now]`, **loại trừ** `transfer` + `adjustment` bằng `type` (FR-003/008, R3); (4) `categoryGlyph(String name)` — map ngắn vài danh mục mẫu quen thuộc (Ăn uống/Lương/Di chuyển…) + fallback chung, **tầng presentation tạm**, đánh dấu gỡ khi bảng `categories` đến (R5); spec edge "tương lai cùng tháng không tính", "ví ẩn vẫn tính", "mỗi giao dịch đúng 1 lần" (SC-004)
- [X] T005 [P] Sửa `app/sora_thu_chi/lib/data/wallet_repository.dart`: thêm vào `abstract class WalletRepository` — `Future<List<Transaction>> allTransactions()` trả **toàn bộ** dòng `transactions` (mọi ví kể cả ví ẩn), sắp `sortNewestFirst` (spec FR-004, R1); không lọc `wallet_id`
- [X] T006 [P] Sửa `app/sora_thu_chi/lib/data/wallet_deps.dart`: thêm `WalletRepository ensureWalletRepository()` (Get **singleton** — tạo `DriftWalletRepository(AppDatabase())` 1 lần, trả instance đã đăng ký nếu có); sửa `ensureWalletController()` dùng chung instance repository đó; giữ ưu tiên controller/repo fake do test `Get.put` trước (research R7 — tránh 2 connection drift trên 1 file)
- [X] T007 Sửa `app/sora_thu_chi/lib/data/wallet_repository_drift.dart`: thêm impl `allTransactions()` — `select` toàn bộ bảng `transactions`, map `TransactionsRow` → `Transaction`, sắp `sortNewestFirst`; sửa `_toTransaction` điền `transferGroupId: r.transferGroupId` (field drift đã có từ PBI 8; spec FR-004/007, R1)
- [X] T008 [P] Sửa `app/sora_thu_chi/test/fakes/fake_wallet_repository.dart`: thêm `allTransactions()` trả toàn bộ `_transactions` (sắp `sortNewestFirst`); **gán `transferGroupId`** cho 2 vế — khi seed từ `TransactionSource.all()` dùng map `TransactionSource.transferGroupLegs {8:11}` (group = id vế nguồn, khớp seed DB), và trong `performTransfer` gán cả 2 vế cùng group = id vế ghi trước; bỏ comment cũ "Domain không chứa group" (giờ domain đã mang group — spec FR-007, R10); khớp nguồn thật để test controller/màn
- [X] T009 Tạo `app/sora_thu_chi/lib/core/transaction/transaction_controller.dart`: `GetxController` nhận `WalletRepository` qua constructor (pattern PBI 7/8) — `Future<void> load()` đọc `repo.allTransactions()` + `repo.loadAll()` (tên ví kể cả ẩn), qua hàm thuần `transaction_list.dart` sinh `List<DayGroup>` + `MonthStat`; Rx state: `isLoading` lần đầu → nội dung | rỗng | lỗi đọc (`error` + nút `retry()` gọi lại `load`); expose dữ liệu bất biến cho màn (research R3/R4/R8)
- [X] T010 [P] Sửa `app/sora_thu_chi/test/date_label_test.dart`: thêm case `formatDayGroupHeader` — cùng ngày → `'HÔM NAY - dd/MM/yyyy'`, hôm trước → `'HÔM QUA - …'`, ngày khác → `'dd/MM/yyyy'`; inject `now` cố định deterministic (spec FR-005)
- [X] T011 [P] Tạo `app/sora_thu_chi/test/transaction_list_test.dart`: unit thuần bơm `Transaction`/tên ví tĩnh + `now` cố định — (a) ghép cặp transfer chung group → **1 dòng** "Chuyển khoản" phụ đề "nguồn → đích", `|x|` (acceptance 4, FR-007); vế lẻ fallback không crash; không group → giữ 2 dòng; (b) nhóm ngày mới nhất trên, header đúng, trùng ngày giờ ổn định theo `id` (edge SC-004); (c) `monthlyIncomeExpense`: đúng tổng thu/chi tháng, **bỏ** transfer & adjustment, **bỏ** thu/chi cùng tháng nhưng sau `now` (đặt lịch), ví ẩn **vẫn** tính (FR-003/008, edge); (d) `categoryGlyph` map + fallback (R5)
- [X] T012 [P] Tạo `app/sora_thu_chi/test/transaction_controller_test.dart`: bơm `FakeWalletRepository` (Get.put) — `load()` → `DayGroups` + `MonthStat` khớp seed 11 dòng (2 vế transfer gộp 1 dòng; Thu/Chi đúng tổng, transfer không tính); sau khi `fake.performTransfer` → gọi lại `load()` phản ánh dòng mới (acceptance 6, FR-011); repo ném lỗi → trạng thái lỗi, `retry()` thành công → nội dung (R8)
- [X] T013 [P] Sửa `app/sora_thu_chi/test/transactions_dao_test.dart`: drift `NativeDatabase.memory()` (giữ skip-guard nếu host thiếu sqlite, như PBI 7/8) — `allTransactions()` trả đủ 11 dòng seed, cặp transfer vế 8 & 11 **cùng `transferGroupId`** đã map lên domain (khớp `TransactionSource.transferGroupLegs`); không phá case migration/`performTransfer` PBI 8 (R1/R10)
- [X] T014 Tạo `app/sora_thu_chi/lib/data/transaction_deps.dart`: `TransactionController ensureTransactionController()` — `Get.put(TransactionController(ensureWalletRepository()))` nếu chưa đăng ký (dùng chung 1 repo/DB — R7), trả controller đã có nếu `Get.isRegistered`; không nạp DB ở đây (nạp do AppShell khi chọn tab — R6); pattern bám `wallet_deps.dart`

## Pha 3: User Story 1 - Màn hình danh sách giao dịch (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: Màn "Giao dịch" hiển thị đúng bố cục `docs/transaction/01-danh-sach-giao-dich.svg` (spec acceptance 1–8, FR-001…015) — app bar teal tiêu đề "Giao dịch" + icon lọc, card "Thu/Chi tháng này", danh sách giao dịch nhóm theo ngày (thu teal `+`, chi coral `−`, chuyển khoản 1 dòng trung tính không dấu), empty state khi chưa có giao dịch, tự cập nhật khi quay lại tab (FR-011); FAB / icon lọc / chạm dòng là điểm vào no-op không lỗi (FR-014 — màn đích PBI sau).
**Tiêu chí kiểm thử độc lập**: `flutter test test/transaction_screen_test.dart` pass — render đúng header/card/danh sách theo seed fake, màu+dấu từng loại dòng, transfer đúng 1 dòng trung tính, card số đúng, empty state `0 đ`, chạm FAB/filter/dòng không crash, ví ẩn vẫn hiện, cỡ chữ lớn + safe area cuộn không vỡ, số tiền rất lớn không tràn (không cần sqlite native).

- [X] T015 [US1] Viết lại `app/sora_thu_chi/lib/screens/transaction_screen.dart` (hiện là khung trống): GetX theo pattern PBI 7/8 — controller đăng ký trước khi build qua `ensureTransactionController()` (Get.put nhẹ, **không** nạp DB ở `initState` — R6); `Obx` theo trạng thái controller: (1) **header**: `ScreenHeader(title: 'Giao dịch', centerTitle: true, trailing: icon lọc no-op (InkWell, FR-014))`; (2) **card thống kê** đầu body nền trắng: `Row` 2 khối cạnh nhau nền `softCardBg` bo 10 gap 10 padding 20/16 — label "Thu tháng này" + mũi tên lên teal / "Chi tháng này" + mũi tên xuống coral, số `incomeTotal`/`expenseTotal` (Thu `textPrimary`, Chi `coral` — R9), `formatMoney` đuôi `đ`; (3) **danh sách**: nội dung → `ListView.builder` trên `List<DayGroup>` kèm `PageStorageKey`, mỗi nhóm 1 tiêu đề ngày (`DayGroup.header`), rows bên dưới, đệm đáy đủ chống FAB/bottom nav che hàng cuối; rỗng (chưa có giao dịch) → card vẫn hiện `0 đ`/`0 đ` + vùng giữa hiển thị hướng dẫn ghi giao dịch đầu tiên trỏ FAB, không báo lỗi (FR-010); lỗi đọc → thông báo + nút "Thử lại" gọi `retry()` (R8); (4) **dòng giao dịch**: icon bubble tròn — thu/chi nền `tealLightBg` + glyph teal theo `categoryGlyph`, transfer/adjustment nền `softCardBg` + glyph trung tính; tiêu đề = tên danh mục (rỗng → `typeLabel`), phụ đề = tên ví (tra từ map id→tên) kèm ` · ghi chú` nếu có ghi chú (không ghi chú → không dấu phân cách thừa — edge spec); số tiền căn phải: thu `formatSignedMoney` màu teal dấu `+`, chi màu coral dấu `−`, chuyển khoản `formatMoney(amount.abs())` màu trung tính **không** dấu, adjustment trung tính; số tiền đặt trong `Flexible` + scale-down nếu cần, **không** ellipsis cắt số (FR-009); (5) chạm một dòng no-op không crash (FR-014); FAB là của `AppShell` (PBI 2) — màn không dựng FAB riêng; dùng token `AppColors` (không hex cứng trong widget — CLAUDE.md)
- [X] T016 [P] [US1] Tạo `app/sora_thu_chi/test/transaction_screen_test.dart`: widget test bơm `FakeWalletRepository` (Get.put trước pump) — (a) render theo seed 11 dòng: header "Giao dịch" giữa + icon lọc phải, card 2 khối Thu `15.000.000 đ` / Chi `2.455.000 đ` (chạy `now` cố định trong tháng đủ 11 dòng), nhóm "HÔM NAY"/"HÔM QUA"/`dd/MM/yyyy` đúng (acceptance 1–3, SC-002); (b) dòng thu `+15.000.000 đ` teal, dòng chi `−85.000 đ` coral (FR-006, SC-003); (c) chuyển khoản xuất hiện **1 dòng** "Chuyển khoản", phụ đề "Vietcombank → Momo", `700.000 đ` trung tính không dấu (acceptance 4, FR-007); (d) chạm icon lọc / một dòng → không crash (FR-014); chạm FAB (shell) → mở màn tạm không lỗi; (e) fake không seed giao dịch → empty state hướng dẫn + card `0 đ`/`0 đ`, không lỗi (FR-010); (f) ví ẩn (fake `update` set `isHidden`) → giao dịch ví đó vẫn hiện, tên ví đủ (edge); (g) cỡ chữ lớn (`textScaleFactor` cao) + safe area inset → cuộn tới cuối không `RenderFlex overflow` (acceptance 8, FR-013); (h) số tiền rất lớn hiển thị đủ không tràn/cắt (FR-009)
- [X] T017 [US1] Sửa `app/sora_thu_chi/lib/core/app_shell.dart`: `_onTabSelected` — khi `index == 1` (tab "Giao dịch") gọi `ensureTransactionController().load()` fire-and-forget (không `await`/`setState` thêm; R6, acceptance 6, FR-011 — nạp lại mỗi lần quay lại tab, lần đầu cũng chính là lần nạp đầu); đảm bảo controller đã đăng ký trước khi `TransactionScreen` build lần đầu (IndexedStack build sẵn 4 màn từ boot — phối hợp T015/T014); không đổi tab/FAB khác

## Pha cuối: Polish & Cross-cutting

- [X] T018 Chạy `flutter analyze` (sạch 0 warning) + `flutter test` toàn bộ tại `app/sora_thu_chi/` (test PBI 2–8 chạy lại **xanh không hồi quy** — nhất là `wallet_controller_test`/`wallets_dao_test` do deps chuyển singleton repo R7, `transaction_test`/`wallet_detail_screen_test` do domain `Transaction` thêm field, `transactions_dao_test` mở rộng; DAO skip-guard); xác nhận `app_database.g.dart` **không** đổi (không chạy `build_runner`); đối chiếu danh sách "Không đổi" plan.md — `main.dart`, `app.dart`, `boot_gate.dart`, `pin_*`, `transaction_source.dart`, bảng drift/migration, `wallet_*` screens, dashboard/report/settings/add_transaction screens không thay đổi + ghi nhận seed 11 dòng / quyết định mở #1 (R5)
- [X] T019 Kiểm chứng thủ công emulator theo `.specify/specs/9/quickstart.md` nhóm A–G: tab Giao dịch đúng mockup + đối chiếu bảng 11 dòng (A), chuyển khoản 1 dòng trung tính (B), card tháng đúng tổng (C, chạy ngày ≥ 6 trong tháng), tự làm mới sau khi Chuyển tiền PBI 8 từ Cài đặt rồi quay lại tab (D), cuộn + cỡ chữ lớn + safe area không vỡ (E), edge: chưa có giao dịch `0 đ` + hướng dẫn, ví ẩn vẫn hiện, khóa app không lộ số tiền (F), không hồi quy các tab/FAB/ví/PIN + `flutter test` xanh (G); ghi kết quả vào trạng thái PBI

## Sơ đồ phụ thuộc

```text
Foundational:
  T001 transaction.dart (+transferGroupId) ──▶ T004 transaction_list (gộp/nhóm/thống kê/glyph) ──▶ T011 transaction_list_test
                                        └──▶ T005 [P] WalletRepository.allTransactions ──▶ T007 DriftWalletRepository ──▶ T013 transactions_dao_test
                                                                            └────────────▶ T008 [P] Fake ──▶ T012 controller_test
  T001 ──▶ T009 TransactionController (T004 pure + T005 seam) ──▶ T012 controller_test ──▶ T014 transaction_deps
  T002 [P] date_label ──▶ T010 date_label_test ;   T002 ──▶ T004 (DayGroup.header)
  T003 [P] screen_header (centerTitle/trailing)                    └────────────────────▶ T015 screen (US1)
  T006 [P] wallet_deps (ensureWalletRepository singleton, R7) ──▶ T014 transaction_deps
US1:
  T015 transaction_screen (T009 controller + T003 header + T014 deps) ──▶ T016 [P] screen_test
  T014 ──▶ T017 app_shell onTabSelected load (R6/FR-011)
Polish:
  T018 analyze + full test (không hồi quy PBI 2–8, deps singleton) ──▶ T019 QA emulator (quickstart A–G)
```

Thứ tự thực thi chính: `T001 → T004 → T009 → T012 → T014 → T015 → T016 → T017 → T018 → T019` (T002/T003/T005/T006 chạy xen kẽ ngay; các test `[P]` T010/T011/T012/T013 chạy khi file nền tương ứng xong).

## Ví dụ chạy song song

```text
# Foundational — khởi động đồng thời từ đầu (khác file, độc lập với T001):
T002 [P] date_label.dart      T003 [P] screen_header.dart      T005 [P] wallet_repository.dart
T006 [P] wallet_deps.dart (singleton, R7)

# Foundational — sau khi file nền tương ứng xong:
T010 [P] date_label_test (sau T002)   T011 [P] transaction_list_test (sau T004)
T013 [P] transactions_dao_test (sau T007)   T008 [P] fake (sau T005) ──▶ T012 [P] controller_test (sau T009)

# US1 — test màn chạy song song việc nối AppShell (sau T015):
T016 [P] [US1] transaction_screen_test.dart
T017     [US1] app_shell.dart wiring
```

## Chiến lược triển khai

- **MVP đề xuất**: User Story 1 (toàn bộ PBI 9 — đặc tả là một lát cắt "hiển thị màn danh sách giao dịch + dựng điểm vào" duy nhất, không chia P1/P2/P3). Foundational dựng phần đọc/trình bày (domain + `allTransactions` + hàm thuần gộp/nhóm/thống kê + controller + deps singleton) làm tiền đề bắt buộc; US1 ghép `transaction_screen` + nối `AppShell` reload lên để ra giá trị end-to-end.
- **Thứ tự giao hàng tăng dần**: Foundational (domain + seam đọc + pure functions + controller + fake — mọi logic test được trên `FakeWalletRepository`, không cần sqlite native) → US1 màn danh sách (screen + wiring `AppShell` + widget test) → Polish (analyze/test toàn cục không hồi quy + QA emulator quickstart A–G). Không đổi schema drift — không cần `build_runner`.
