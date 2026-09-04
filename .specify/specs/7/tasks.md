# Danh sách Task: Thêm/sửa ví (form dùng chung + hạ tầng lưu ví drift)

**Mã PBI**: 7
**Nguồn**: plan.md, spec.md, data-model.md, research.md, quickstart.md

## Pha 1: Setup

- [X] T001 Sửa `app/sora_thu_chi/pubspec.yaml`: thêm runtime deps `sqlite3_flutter_libs`, `path_provider`, `path` (drift `^2.34.4` đã khai báo — giữ) + dev deps `drift_dev` (cùng dòng 2.x) và `build_runner`; chạy `flutter pub get`; nếu xung đột version để `flutter pub` tự giải, chốt bản thực thi

## Pha 2: Foundational

*(Hạ tầng bắt buộc xong trước mọi user story: mở rộng model `Wallet`, hàm thuần rule mặc định, preset icon/màu, khung màn phụ đỡ nút chân, và lần đầu wire drift bảng `wallets` + repository seam + controller — theo plan.md "Cấu trúc dự án dự kiến".)*

- [X] T002 Sửa `app/sora_thu_chi/lib/core/wallet/wallet.dart`: thêm trường optional **có default để không phá constructor/hằng hiện có** — `initialBalance` (int, default `balance`), `currency` (String, `'VND'`), `color` (int? ARGB), `statementDate`/`dueDate`/`maturityDate` (DateTime?), `termMonths` (int?), `institutionName`/`lastDigits` (String?) + phương thức `copyWith` (Wallet bất biến); giữ nguyên field/getter hiện có (theo data-model.md §Thực thể)
- [X] T003 [P] Tạo `app/sora_thu_chi/lib/core/wallet/wallet_rules.dart`: hàm thuần thao tác `List<Wallet>` — `hasActiveDefault`, `resolveOnCreate` (list không có ví active → ví mới ép default — acceptance 3), `resolveOnUpdate` (bật mặc định cho B → dời cờ khỏi A; tắt cờ của ví default: còn active khác → chọn active đầu theo `walletsByDisplayOrder` làm thay thế, chỉ còn mình nó → chặn tắt giữ default) — logic bất biến FR-007/008/acceptance 4, không đụng repo
- [X] T004 [P] Tạo `app/sora_thu_chi/lib/core/wallet/wallet_presets.dart`: hằng danh sách emoji icon ví (`💵🏦💳📱🏷️…`) + `defaultIconFor(WalletType)`; màu ví = danh sách preset tham chiếu **token** `AppColors` (không hex cứng) + màu default hợp lý — spec §Giả định "biểu tượng & màu sắc" (research Q9)
- [X] T005 [P] Sửa `app/sora_thu_chi/lib/core/widgets/sub_page_scaffold.dart`: thêm tham số `Widget? bottomNavigationBar` forward vào `Scaffold.bottomNavigationBar` (giữ `title`/`child` cũ) — nền cho nút "Lưu ví" cố định chân màn (SC-007)
- [X] T006 [P] Tạo `app/sora_thu_chi/lib/data/db/app_database.dart`: drift `@DriftDatabase(tables: [Wallets])` schemaVersion 1 — bảng `wallets` đủ 18 cột data-model.md (id autoIncrement PK, name, wallet_type `textEnum<WalletType>`, icon, color int?, initial_balance, balance, currency default `'VND'`, is_default, is_hidden, sort_order, credit_limit?, credit_used?, statement_date?, due_date?, term_months?, maturity_date?, institution_name?, last_digits?) + lớp `AppDatabase` mở file `createInBackground` (path_provider `getApplicationDocumentsDirectory`) + `onCreate`: tạo bảng rồi **SEED 5 ví mẫu** khớp `WalletSource.all()` (kèm `initialBalance`/`currency`/`color` mở rộng — Vietcombank `initial_balance` 1.200.000, `balance` 14.800.000 theo plan §Số dư); chạy `dart run build_runner build --delete-conflicting-outputs` sinh `app_database.g.dart` (commit)
- [X] T007 Tạo `app/sora_thu_chi/lib/data/wallet_repository.dart`: `abstract class WalletRepository` seam test — `Future<List<Wallet>> loadAll()`, `Future<Wallet> insert(Wallet draft)`, `Future<Wallet> update(Wallet wallet)` (interface theo plan)
- [X] T008 [P] Tạo `app/sora_thu_chi/test/wallet_rules_test.dart`: unit test hàm thuần `wallet_rules` — list rỗng → tạo ví đầu tiên `isDefault=true` đúng 1 default (acceptance 3); bật default B → A hết cờ (acceptance 4); tắt cờ default khi còn active khác → chọn thay thế active đầu; chặn tắt khi default duy nhất active (FR-007/008, SC-005); bơm list tĩnh qua hàm thuần, không cần DB/controller
- [X] T009 Tạo `app/sora_thu_chi/lib/data/wallet_repository_drift.dart`: `DriftWalletRepository implements WalletRepository` — map dòng `wallets` ↔ `Wallet` (gồm trường optional đợt này), `loadAll` đọc có thứ tự, `insert`/`update` ghi DB (update giữ `is_hidden` FR-012; khi sửa ví chưa giao dịch đổi số dư → ghi **cả** `initial_balance` và `balance` theo data-model §Số dư)
- [X] T010 [P] Tạo `app/sora_thu_chi/test/wallets_dao_test.dart`: drift tích hợp `NativeDatabase.memory()` — migration schemaVersion 1 + seed đủ 5 ví (đúng `WalletSource`), CRUD loadAll/insert/update, map field optional đúng; skip-guard `markTestSkipped` nếu host Windows thiếu sqlite native (research Q12 — app thật dùng `sqlite3_flutter_libs`)
- [X] T011 Tạo `app/sora_thu_chi/lib/core/wallet/wallet_controller.dart`: `WalletController extends GetxController` giữ `RxList<Wallet>` — `init()` nạp repo + nếu không có active default → `ensureDefault`; `create({WalletType, name, initialBalance, color, …}, {bool wantDefault})`: tính `sortOrder` kế (max + 1), gọi `wallet_rules.resolveOnCreate`/bật cờ theo `wantDefault` → `repository.insert` → reload cache; `update(Wallet wallet, …, {bool? wantDefault})`: gọi `resolveOnUpdate` → `repository.update` → reload cache (FR-013)
- [X] T012 Tạo `app/sora_thu_chi/lib/data/wallet_deps.dart`: hàm `ensureWalletController()` — nếu `Get.isRegistered<WalletController>` trả về controller có sẵn; ngược lại `Get.put(WalletController(DriftWalletRepository(AppDatabase())))` + gọi `init()` load nền; không đụng luồng PIN (research Q13)
- [X] T013 [P] Tạo `app/sora_thu_chi/test/fakes/fake_wallet_repository.dart`: `FakeWalletRepository implements WalletRepository` map bộ nhớ seed `WalletSource.all()` — `loadAll`/`insert` (gán id tăng + sortOrder)/`update`; dùng cho mọi widget/controller test (không sqlite native)
- [X] T014 Tạo `app/sora_thu_chi/test/wallet_controller_test.dart`: `WalletController` + `FakeWalletRepository` — init nạp 5 ví + reactive cache; create ghi qua repo + đúng bất biến mặc định (ví đầu tiên ép default, bật cờ dời cờ cũ); update đổi tên/icon + ghi cả `initial_balance`/`balance` khi chưa giao dịch (acceptance 7); cache `RxList` phản ánh ngay (FR-013)

## Pha 3: User Story 1 - Thêm ví mới (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: Tạo được ví mới từ màn danh sách (FR-001..008, acceptance 1/2/3/4/8) — form dùng chung chế độ "Thêm ví mới" (sub-page teal, nút back, không bottom nav), đủ khối tên/loại chip/trường riêng theo loại/số dư ban đầu + tiền tệ (VND)/icon & màu/cờ mặc định; validate lỗi đúng trường; lưu → controller.create → quay danh sách, tổng & hàng mới phản ánh ngay; back chưa lưu không tạo gì.
**Tiêu chí kiểm thử độc lập**: `flutter test test/wallet_form_screen_test.dart` + `test/wallet_list_screen_test.dart` pass — mở form từ list, tạo ví (fake repo) → về list thấy ví mới + tổng đúng, 5 loại ví hiện trường riêng đúng, validation chặn tên trống/hạn mức thẻ ≤ 0, back giữ nguyên.

- [X] T015 [US1] Tạo `app/sora_thu_chi/lib/screens/wallet_form_screen.dart` — chế độ **thêm** (`WalletFormScreen({Wallet? wallet, bool hasTransactions, WalletController controller})`, `wallet == null`): `SubPageScaffold(title: 'Thêm ví mới', bottomNavigationBar: SafeArea(nút "Lưu ví" 44 bo 8 teal))`; body **một scroll** chứa — `TextFormField` **Tên ví** (bắt buộc, trim rỗng → lỗi tại trường); khối **Loại ví** 5 chip `WalletType` (label tiếng Việt, chip chọn teal); **Số dư ban đầu** ô nhập số chỉ chữ số (bắt buộc khi tạo, `0` hợp lệ, suffix `đ`) + **Tiền tệ** hiển thị `VND` đọc-only (FR-006, research Q4); khối **trường riêng theo loại động**: credit → hạn mức tín dụng (bắt buộc > 0 — chặn lưu + lỗi tại trường, acceptance 8), ngày sao kê/đến hạn (tùy chọn, `showDatePicker` mặc định); savings → kỳ hạn tháng + ngày đáo hạn; bank/ewallet → tên ngân hàng/tổ chức + số cuối (chỉ hiển thị); cash → không trường; đổi chip giữa lúc nhập → bỏ giá trị loại cũ (edge); **Icon & màu** từ `wallet_presets` (chọn phản hồi, default theo loại); **Switch "Đặt làm ví mặc định"** → Save truyền `wantDefault` (controller/rules lo việc ép/dời cờ — acceptance 3/4); khi save: validate → `controller.create` → `Navigator.pop(updated)`; save lỗi → báo + **giữ dữ liệu đã nhập** (FR-014); back chưa lưu → pop không tạo gì (acceptance 9)
- [X] T016 [P] [US1] Tạo `app/sora_thu_chi/test/wallet_form_screen_test.dart` — widget test chế độ thêm (bơm `WalletController` + `FakeWalletRepository`, `Get.put` trước pump): (a) title "Thêm ví mới", đủ các khối + nút "Lưu ví", không bottom nav; (b) 5 chip loại → cash không trường riêng, credit hiện hạn mức, savings kỳ hạn/đáo hạn, bank tên+số cuối, ewallet tổ chức+số cuối (FR-003); (c) đổi chip sau khi nhập → trường loại cũ mất (edge); (d) lưu thiếu tên / tên chỉ khoảng trắng / thiếu số dư → chặn, lỗi đúng trường (FR-005); (e) số dư `0` → hợp lệ; (f) credit hạn mức trống hoặc `0` → chặn tại trường hạn mức, nhập `20.000.000` → lưu được (acceptance 8); (g) nhập đủ + Lưu → `controller.create` gọi (fake chứa ví mới) + pop (acceptance 2); (h) back chưa lưu → pop, không tạo (acceptance 9); (i) textScale 2.0 + safe inset → cuộn hết không `RenderFlex overflow`, nút Lưu với tới (SC-007)
- [X] T017 [US1] Sửa `app/sora_thu_chi/lib/screens/wallet_list_screen.dart`: đổi nguồn sự thật từ tham số `wallets` → đọc `WalletController` reactive (`Obx` trên `RxList` — plan Q2/Q13): stateful, `initState` gọi `WalletDeps.ensureWalletController()`, hiển thị spinner khi đang nạp (tránh nháy empty state); `_TotalCard`/hàng ví tính từ controller cache (`walletsByDisplayOrder`/`activeTotal`/`activeCount` giữ nguyên hàm thuần); nút `_AddWalletButton` → `Navigator.push(WalletFormScreen(controller: controller))` chế độ thêm, sau khi pop danh sách tự cập nhật tổng/hàng (FR-013); bỏ constructor `wallets` (settings `WalletListScreen()` không đổi — tự ensure)
- [X] T018 [US1] Sửa `app/sora_thu_chi/test/wallet_list_screen_test.dart` **và** `test/settings_screen_test.dart`: thay bơm `wallets:`/`WalletSource` bằng đăng ký `Get.put(WalletController(FakeWalletRepository()))` (+ `init`) trước pump, `tearDown` reset — giữ nguyên mọi khẳng định hiển thị cũ (tổng `19.450.000 đ`, 4 active, thẻ VIB, ví ẩn cuối, 1 nhãn Mặc định…); sửa case "(h)": tap hàng → mở detail như cũ, tap `+ Thêm ví mới` → **mở `WalletFormScreen`** (không còn no-op); thêm case: chạy luồng thêm trên fake (nhập tên/số dư → Lưu) → về list thấy ví mới + tổng tăng; settings test (PBI 4) thêm đăng ký fake controller trước khi tap "Quản lý ví" để list không khởi tạo drift trong widget test

## Pha 4: User Story 2 - Sửa ví (Ưu tiên: P1)

**Mục tiêu**: Sửa ví từ màn chi tiết (FR-009..014, acceptance 5/6/7) — mở form "Sửa ví" với toàn bộ trường nạp sẵn; **khóa ma trận khi ví đã có giao dịch** (số dư ban đầu/tiền tệ/loại không chỉnh + ghi chú "Điều chỉnh số dư", FR-010); ví chưa giao dịch đổi được số dư ban đầu (ghi cả `initial_balance`+`balance`, FR-011/acceptance 7); lưu → controller.update → quay chi tiết cập nhật, số dư & lịch sử không đổi (SC-004).
**Tiêu chí kiểm thử độc lập**: widget test form chế độ sửa (prefill, lock hasTxns, đổi số dư khi chưa giao dịch) + test detail case "Sửa ví" mở form và quay về cập nhật — `flutter test test/wallet_form_screen_test.dart test/wallet_detail_screen_test.dart`.

- [X] T019 [US2] Sửa `app/sora_thu_chi/lib/screens/wallet_form_screen.dart` — chế độ **sửa** (`wallet != null`): title "Sửa ví", `initState` nạp toàn bộ trường giá trị hiện tại của ví (FR-009); khi `hasTransactions == true` → **khóa** ô Số dư ban đầu + Tiền tệ + chip Loại ví (hiển thị disabled, kèm ghi chú "Muốn đổi số dư → tạo giao dịch Điều chỉnh số dư", không có ô nhập số dư hiện tại — FR-010/acceptance 6); khi chưa giao dịch → mọi trường sửa được, đổi số dư ban đầu gọi update ghi cả `initial_balance`+`balance` (FR-011/acceptance 7); cờ mặc định: Switch thể hiện `wallet.isDefault`, **disable/chặn tắt khi default duy nhất active** (gọi `wallet_rules.hasActiveDefault` trên list controller — FR-008/edge); Save → `controller.update` → `Navigator.pop(Wallet mới)`, giữ nguyên `is_hidden` (FR-012)
- [X] T020 [P] [US2] Mở rộng `app/sora_thu_chi/test/wallet_form_screen_test.dart` — case chế độ sửa: (a) title "Sửa ví" + mọi trường nạp đúng giá trị ví (acceptance 5); (b) `hasTransactions: true` → Số dư/Tiền tệ/Loại ví không chỉnh được + có ghi chú điều chỉnh, sửa tên/icon/hạn mức OK (FR-010, SC-004); (c) `hasTransactions: false` → đổi số dư ban đầu `1.000.000 → 2.000.000` → controller.update ghi `initial_balance`=balance=`2.000.000` (acceptance 7); (d) đổi loại khi chưa giao dịch → trường riêng loại mới hiện; (e) ví đang default duy nhất → không tắt được cờ (edge); (f) lưu → pop Wallet cập nhật; lưu lỗi → giữ dữ liệu (FR-014)
- [X] T021 [US2] Sửa `app/sora_thu_chi/lib/screens/wallet_detail_screen.dart`: `StatelessWidget` → `StatefulWidget` giữ `Wallet` trong state; hành động nhanh **"Sửa ví"** (bỏ no-op) → lấy controller (`WalletDeps.ensureWalletController()`) + `Navigator.push(WalletFormScreen(wallet: wallet, hasTransactions: transactions.isNotEmpty, controller: controller))`, `await` kết quả → có `Wallet` mới thì `setState` cập nhật (tên mới hiện ngay — FR-013); **2 nút còn lại** (Chuyển tiền/Ẩn ví) giữ no-op (PBI sau); số dư & nhóm giao dịch hiển thị không đổi khi chỉ sửa tên/icon/màu/hạn mức (SC-004)
- [X] T022 [US2] Sửa `app/sora_thu_chi/test/wallet_detail_screen_test.dart`: case "(h)" đổi — chạm **"Sửa ví"** (sau khi `Get.put` controller fake) → mở `WalletFormScreen`; thêm case: trong form sửa đổi tên Vietcombank → Lưu → pop về detail hiện tên mới, số dư `14.800.000 đ` + danh sách giao dịch **không đổi** (SC-004); các case còn lại (a–g, i, j) giữ nguyên bơm `wallet`/`transactions` qua constructor, riêng case "(h)" cũ tap Chuyển tiền/Ẩn ví giữ không mở màn

## Pha cuối: Polish & Cross-cutting

- [X] T023 Chạy `flutter analyze` (sạch 0 warning) + `flutter test` toàn bộ (test PBI 2/3/4/5/6 + 7 pass) tại `app/sora_thu_chi/`; xác nhận `app_database.g.dart` đã sinh & sẽ commit, không file/dependency dư; đối chiếu mục "Không đổi" plan.md (main.dart, app.dart, boot_gate.dart, pin_*, shell, settings_screen.dart, dashboard/report/transaction screens, `transaction.dart`/`transaction_source.dart`, `device_profile.dart` không thay đổi) + loại trừ seed ví mẫu/quyết định mở #1/#2
- [ ] T024 Kiểm chứng thủ công emulator theo `.specify/specs/7/quickstart.md` nhóm A–J: tạo ví tiền mặt từ list (A), **bền qua restart** — ví mới còn + tổng đúng (B, điểm mới drift), 5 loại ví + trường riêng + hạn mức thẻ chặn (C), validation lỗi đúng trường + back giữ nguyên (D), bất biến mặc định dời/tự chọn thay thế (E, phủ unit F), sửa Vietcombank đã có giao dịch khóa trường + số dư/lịch sử không đổi (G), sửa ví chưa giao dịch đổi số dư (H), cỡ chữ lớn + vùng an toàn (I), PIN che form khi xuống nền (J regression PBI 3); ghi kết quả vào trạng thái PBI

## Sơ đồ phụ thuộc

```text
Setup: T001 pubspec + pub get
  ↓
Foundational:  T002 wallet.dart ──────────────▶ (đa số task sau)
               T003 [P] wallet_rules.dart ──▶ T008 rules_test
               T004 [P] wallet_presets.dart ───────▶ T015 (form)
               T005 [P] sub_page_scaffold.dart ─────▶ T015 (form)
               T006 [P] app_database + codegen ──▶ T009 DriftWalletRepository ──▶ T010 dao_test
               T007 WalletRepository abstract ──▶ T009 / T013 fake ──▶ T014 controller_test
               T011 WalletController (sau T007+T003) ──▶ T012 wallet_deps / T014
  ↓
US1 (Thêm ví): T015 form thêm ──▶ T016 form_test (P) / T017 list wiring ──▶ T018 list_test
  ↓
US2 (Sửa ví):  T019 form sửa ──▶ T020 form_test (P) / T021 detail wiring ──▶ T022 detail_test
  ↓
Polish: T023 analyze + full test ──▶ T024 QA emulator
```

Thứ tự thực thi chính: `T001 → T002 → T007 → T009 → T011 → T012 → T015 → T017 → T018 → T019 → T021 → T022 → T023 → T024` (các task `[P]` chạy xen kẽ ngay khi file nền tương ứng xong).

## Ví dụ chạy song song

```text
# Foundational (khác file, không phụ thuộc nhau — sau T002/T007 đã xong):
T003 [P] wallet_rules.dart          T004 [P] wallet_presets.dart
T005 [P] sub_page_scaffold.dart     T006 [P] app_database.dart
T008 [P] wallet_rules_test          T013 [P] fake_wallet_repository.dart

# US1 — test form chạy song song việc nối list (cùng dựa T015 đã xong):
T016 [P] [US1] wallet_form_screen_test.dart
T017 [US1]     wallet_list_screen wiring

# US2 — test form sửa song song việc nối detail (sau T019):
T020 [P] [US2] mở rộng wallet_form_screen_test.dart
T021 [US2]     wallet_detail_screen wiring
```

## Chiến lược triển khai

- **MVP đề xuất**: User Story 1 — "Thêm ví mới". Hạ tầng drift/repository/controller/rules ở Foundational là tiền đề chung cho cả hai luồng; hoàn tất US1 cho phép tạo ví end-to-end (giá trị dùng độc lập), US2 "Sửa ví" ghép lên cùng một form.
- **Thứ tự giao hàng tăng dần**: Foundational (hạ tầng lưu ví drift + seam test) → US1 Thêm ví (form + nối list + tạo qua controller) → US2 Sửa ví (form nạp sẵn + khóa theo giao dịch + nối detail) → Polish (analyze/test toàn cục + QA emulator). Mỗi user story là một lát cắt kiểm thử độc lập (widget test với fake repository — không sqlite native), hai story dùng chung một file `WalletFormScreen` nên thi công tuần tự US1 → US2 trên cùng file, không nhân bản.
