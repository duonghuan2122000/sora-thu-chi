# Danh sách Task: Chuyển tiền giữa các ví

**Mã PBI**: 8
**Nguồn**: plan.md, spec.md, data-model.md, research.md, quickstart.md

## Pha 1: Setup

*(Không có task — PBI 8 không thêm dependency/pubspec mới: drift `^2.34.4`, drift_dev & build_runner đã khai báo từ PBI 7; chỉ bump schemaVersion trong file có sẵn ở Foundational.)*

## Pha 2: Foundational

*(Hạ tầng bắt buộc xong trước user story: bảng `transactions` drift (schema 1→2) + seed 11 dòng mẫu; mở rộng seam `WalletRepository` (`transactionsOf`, `performTransfer`) + impl Drift/Fake; hàm thuần `transfer_rules`/`parseAmount`/`formatDateTimeLabel`; `WalletController.transfer` + reload — theo plan.md "Cấu trúc dự án dự kiến".)*

- [X] T001 Sửa `app/sora_thu_chi/lib/core/transaction/transaction_source.dart`: đổi vai trò thành **nguồn seed chuẩn 11 dòng mẫu** (migration v2 + Fake + DAO test cùng dùng), bỏ comment "chưa có luồng ghi"; **giữ nguyên API hiện có** `all()`/`forWallet()` để màn chi tiết & test cũ còn compile (thay nguồn màn chi tiết xử lý ở US1); bổ sung cách định nhóm 2 vế transfer để seed gắn `transfer_group_id` chung — cặp vế nguồn Vietcombank `-700.000` (id 8) ↔ vế đích Momo `+700.000` (id 11), cùng note `'Chuyển sang Momo'` (data-model §Migration, R2)
- [X] T002 [P] Sửa `app/sora_thu_chi/lib/core/money_format.dart`: thêm hàm thuần `int parseAmount(String input)` — lọc ký tự số (bỏ `.` phân tách), rỗng/không số → `0`, số âm → giá trị âm; đối nghịch đúng `formatAmount` (research R9, spec FR-005)
- [X] T003 [P] Sửa `app/sora_thu_chi/lib/core/date_label.dart`: thêm `String formatDateTimeLabel(DateTime)` → `'dd/MM/yyyy HH:mm'` (tái dùng `_two`), dùng cho dòng hiển thị ngày giờ chọn trên màn chuyển (plan "không viết lại date label cơ bản")
- [X] T004 [P] Tạo `app/sora_thu_chi/lib/core/wallet/transfer_rules.dart`: hàm thuần trên `List<Wallet>` — `List<Wallet> eligibleDestinations(wallets, sourceId)`: ví **hoạt động** (`!isHidden`), cùng `currency` ví nguồn, `type != credit`, `id != sourceId` (spec FR-003/011/018/019, research R8); `bool canTransferFromWallet(Wallet)` = `type != credit` (FR-018 — ví ẩn đang đứng ở chi tiết vẫn làm nguồn được); `bool hasEligibleDestination(...)` = list kết quả không rỗng — báo "chưa có ví đích" (FR-019); không đụng repo/UI
- [X] T005 [P] Sửa `app/sora_thu_chi/lib/data/wallet_repository.dart`: thêm vào `abstract class WalletRepository` — `Future<List<Transaction>> transactionsOf(int walletId)` (đọc giao dịch đúng ví, mới nhất trước) và `Future<void> performTransfer({required int fromWalletId, required int toWalletId, required int amount, required DateTime date, String note})` (ghi atomic 2 vế, `amount` dương; validation nghiệp vụ do `transfer_rules`/UI — repository không tự chặn) (plan §R6)
- [X] T006 Sửa `app/sora_thu_chi/lib/data/db/app_database.dart`: `schemaVersion` 1 → 2; thêm `@Table` (qua `@DataClassName('TransactionsRow')`) bảng `transactions` đủ 8 cột data-model.md §Giao dịch — `id` autoIncrement PK, `walletId` NOT NULL có index đơn, `type` `textEnum<TxnType>()` NOT NULL, `amount` int NOT NULL (signed), `category` text default `''`, `note` text default `''`, `transactionDate` dateTime NOT NULL, `transferGroupId` int nullable; đăng ký bảng vào `@DriftDatabase(tables: [Wallets, Transactions])`; `MigrationStrategy`: `onUpgrade(v1→v2)` tạo bảng `transactions` + **seed 11 dòng mẫu từ `TransactionSource`** (dòng tự sinh id 1..11 theo thứ tự, gán 2 vế transfer cùng `transfer_group_id` = id vế nguồn ghi trước — data-model §Migration R7), `onCreate` tạo 2 bảng + seed ví (giữ nguyên `_seedSampleWallets`) + seed giao dịch tương tự; chạy `dart run build_runner build --delete-conflicting-outputs` sinh mới `app_sora_thu_chi/lib/data/db/app_database.g.dart` (commit)
- [X] T007 [P] Tạo `app_sora_thu_chi/test/transfer_rules_test.dart`: unit hàm thuần `transfer_rules` — lọc đích đúng: loại credit, loại ví ẩn, ví khác `currency`, trùng `sourceId` (spec acceptance 2, FR-003); `canTransferFromWallet`: credit → false, cash/bank/ewallet/savings → true (acceptance 10, FR-018); ví ẩn làm nguồn (từ chi tiết) vẫn tính được `hasEligibleDestination` (edge, spec §Giả định); chỉ có 1 ví active / không còn đích hợp lệ → `hasEligibleDestination == false` (FR-019); bơm list tĩnh `Wallet`, không DB/controller
- [X] T008 [P] Sửa `app/sora_thu_chi/test/money_format_test.dart`: thêm case `parseAmount` — `'2.000.000'` → `2000000`, `''`/`'abc'` → `0`, `'−500.000'` → `-500000`, số rất lớn không tràn (spec FR-005, SC-002; research R9)
- [X] T009 [P] Sửa `app/sora_thu_chi/test/date_label_test.dart`: thêm case `formatDateTimeLabel` — hiển thị đúng `'dd/MM/yyyy HH:mm'`, bổ sung số 0 đứng trước ngày/tháng/giờ/phút (vd `'05/09/2026 09:05'`); deterministic bằng `DateTime` cụ thể
- [X] T010 Sửa `app/sora_thu_chi/test/fakes/fake_wallet_repository.dart`: implement `WalletRepository` mở rộng — giữ `_store` ví + thêm `List<Transaction> _transactions` trong bộ nhớ (seed mặc định từ `TransactionSource.all()`, dòng tự gán id tăng); `transactionsOf(walletId)` lọc + `sortNewestFirst`; `performTransfer` = đổi `balance` ví nguồn (`−amount`) & ví đích (`+amount`) trong `_store`, thêm 2 dòng `type=transfer` (`−amount` vế nguồn / `+amount` vế đích, cùng `date`/`note`, cùng `transferGroupId` = id vế ghi trước); cần khớp nguồn thật để test chi tiết (spec acceptance 7)
- [X] T011 Sửa `app/sora_thu_chi/lib/data/wallet_repository_drift.dart`: implement 2 method mới — `transactionsOf`: `select` bảng `transactions` lọc `walletId`, map `TransactionsRow` → `Transaction` domain (không đổi model, map 1-1 data-model §Giao dịch), sắp `sortNewestFirst`; `performTransfer`: chạy trong **một `_db.transaction()`** — (1) trừ `balance` ví nguồn, (2) cộng `balance` ví đích, (3) insert vế nguồn `type=transfer amount=−amount`, (4) insert vế đích `+amount` cùng `date`/`note` rồi update lại `transferGroupId` = id vế nguồn vừa ghi (FR-012/015, R1/R4/R7)
- [X] T012 Sửa `app/sora_thu_chi/lib/core/wallet/wallet_controller.dart`: thêm `Future<void> transfer({required int fromId, required int toId, required int amount, required DateTime date, String note = ''})` — gọi `_repository.performTransfer(...)` rồi `_reload()` cache ví (cả 2 ví số dư mới — FR-014); thêm `Future<List<Transaction>> transactionsOf(int walletId)` passthrough tới repository (màn chi tiết đọc giao dịch qua controller làm façade, không đụng repo trực tiếp)
- [X] T013 [P] Sửa `app/sora_thu_chi/test/wallets_dao_test.dart`: drift `NativeDatabase.memory()` — migration `schemaVersion` 1 → 2 không phá seed ví PBI 7 (5 ví còn nguyên, số dư đúng `WalletSource`), bảng `transactions` được tạo + seed đủ 11 dòng (2 vế transfer cùng `transfer_group_id`) trên DB cũ upgrade (data-model §Migration); skip-guard `markTestSkipped` nếu host Windows thiếu sqlite native (như PBI 7)
- [X] T014 [P] Sửa `app/sora_thu_chi/test/wallet_controller_test.dart`: nhóm transfer (bơm `FakeWalletRepository` + `TransactionSource` seed) — `controller.transfer` gọi repo, cache `RxList` reload đúng số dư 2 ví (nguồn −x, đích +x — acceptance 7, SC-002); `transactionsOf` trả đúng giao dịch của ví (spec FR-008)
- [X] T015 [P] Tạo `app/sora_thu_chi/test/transactions_dao_test.dart`: drift `NativeDatabase.memory()` — migration v2 + seed 11 dòng khớp `TransactionSource` (2 vế transfer chung `transfer_group_id`); `performTransfer` atomic: 2 dòng cùng group, `balance` nguồn trừ / đích cộng đúng; lỗi giữa chừng → rollback không để lệch một phía (FR-012/015, SC-006); DAO không giữ trạng thái sau rollback; skip-guard nếu host thiếu sqlite native

## Pha 3: User Story 1 - Chuyển tiền giữa hai ví (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: Hoàn tất một lần chuyển tiền end-to-end (spec acceptance 1–11, FR-001…019) — từ màn chi tiết ví (PBI 6) chạm hành động nhanh "Chuyển tiền" → mở màn `wallet_transfer_screen` bám mockup `docs/wallet/wallet-transfer-screen.svg`, chọn ví đích (danh sách lọc theo quy tắc), nhập số tiền/ngày giờ/ghi chú, xem trước "Số dư sau chuyển" (cảnh báo mềm khi âm), xác nhận → controller ghi atomic 2 vế → quay về chi tiết ví với số dư + "GIAO DỊCH GẦN ĐÂY" đã cập nhật; thẻ tín dụng & trường hợp không có ví đích bị chặn rõ ràng.
**Tiêu chí kiểm thử độc lập**: `flutter test test/wallet_transfer_screen_test.dart test/wallet_detail_screen_test.dart` pass — màn chuyển render đúng bố cục, chọn/hoán đổi ví, preview số dư, lỗi đúng trường, double-tap 1 lần gọi, back không lưu (fake repo, không sqlite native); detail mở màn từ Vietcombank + cập nhật sau khi pop.

- [X] T016 [US1] Tạo `app/sora_thu_chi/lib/screens/wallet_transfer_screen.dart`: `StatefulWidget` nhận `Wallet sourceWallet` (ô "Từ ví" nạp sẵn — spec acceptance 1, FR-001) + `WalletController controller`; body một `ListView` cuộn được trên `SubPageScaffold(title: 'Chuyển tiền giữa ví')` (không bottom nav, nút back — FR-001, SC-007); các khối theo mockup: ô **Từ ví** (icon + tên + `formatMoney` số dư hiện tại, chỉ đọc) → nút **hoán đổi** giữa 2 ô (đổi chỗ nguồn/đích khi cả hai đã chọn, cập nhật số dư 2 ô — acceptance 3, FR-004) → ô **Đến ví** (trống hiển thị `'Chọn ví'`; chạm mở `showModalBottomSheet` liệt kê `transfer_rules.eligibleDestinations(controller.wallets, sourceId)` — mỗi dòng icon + tên + số dư, không chứa ví nguồn/thẻ tín dụng/ví ẩn — acceptance 2, FR-003/011/018); trường **Số tiền chuyển** bắt buộc > 0, chỉ chữ số, nhập sống phân tách nghìn bằng `parseAmount`/`formatAmount` hậu tố `đ`, giới hạn độ dài hợp lý chống tràn (acceptance 4, FR-005, SC-002/007); bộ **Ngày giờ** (default `DateTime.now()`, chạm mở `showDatePicker` + `showTimePicker`, hiển thị qua `formatDateTimeLabel` — FR-006); trường **Ghi chú** tùy chọn (FR-007); dòng **"Số dư sau chuyển"** live khi đủ nguồn+đích+tiền (`formatMoney(src.balance − amount)` / `formatMoney(dst.balance + amount)`), số dư nguồn sau chuyển âm → chữ coral + cảnh báo mềm `'Số dư sau chuyển sẽ âm'` nhưng **không chặn** (acceptance 6, FR-008/009); nút **"Xác nhận chuyển tiền"** 44 cao bo 8 teal — vô hiệu khi thiếu đích / tiền ≤ 0 / ngày giờ rỗng / đang lưu, lỗi báo đúng trường (acceptance 5/10-edge, FR-010); chạm → `controller.transfer(...)` với cờ `saving` chống double-tap (SC-006), thành công `Navigator.pop(true)`; lỗi lưu → báo + giữ dữ liệu đã nhập (FR-015)
- [X] T017 [P] [US1] Tạo `app/sora_thu_chi/test/wallet_transfer_screen_test.dart`: widget test bơm `WalletController` + `FakeWalletRepository` (Get.put trước pump) — (a) mở màn từ Vietcombank: title, ô "Từ ví" nạp sẵn VCB + số dư `14.800.000 đ`, ô "Đến ví" `'Chọn ví'`, đủ trường + dòng "Số dư sau chuyển" + nút Xác nhận, không bottom nav (acceptance 1); (b) chạm "Đến ví" → sheet liệt kê ví active cùng VND không chứa VCB / thẻ VIB / ví ẩn (acceptance 2); (c) chọn Momo → ô hiển thị + số dư `1.450.000 đ`; chạm hoán đổi → nguồn thành Momo / đích thành VCB, số dư đổi theo (acceptance 3); (d) nhập `2000000` → hiển thị `2.000.000 đ`; preview `12.800.000 đ / 3.450.000 đ` (acceptance 4, SC-002); (e) Xác nhận khi tiền trống/`0` → chặn + lỗi tại trường, không gọi transfer (acceptance 5); (f) nguồn `500.000 đ` chuyển `1.000.000` → preview `−500.000 đ` + cảnh báo mềm + nút vẫn bấm (acceptance 6); (g) chạm Xác nhận 2 lần nhanh → đúng 1 lần gọi `transfer` (SC-006); (h) back chưa xác nhận → pop không tạo gì (acceptance 9); (i) textScale 2.0 + safe inset → cuộn tới nút không `RenderFlex overflow` (acceptance 11, FR-016)
- [X] T018 [US1] Sửa `app/sora_thu_chi/lib/screens/wallet_detail_screen.dart`: đổi nguồn giao dịch sang đọc động + nối hành động "Chuyển tiền" (FR-001/014) — giữ constructor seam `List<Transaction>? transactions` (khác null → dùng thẳng cho test cũ); `transactions == null` → `initState` nạp qua `controller.transactionsOf(walletId)` (cần `ensureWalletController()`), trạng thái loading nhẹ, hiển thị nhóm "GIAO DỊCH GẦN ĐÂY" như cũ; `_QuickActions.onTransfer` mới: ví `credit` → `SnackBar` thông báo thẻ tín dụng chưa dùng để chuyển, **không** mở màn (acceptance 10, FR-018); không còn `hasEligibleDestination(controller.wallets, id)` → `SnackBar` "chưa có ví đích hợp lệ" (FR-019, edge 1-ví); ngược lại `Navigator.push(WalletTransferScreen(sourceWallet: _wallet, controller: controller))`, await kết quả `true` → `setState`: lấy lại `_wallet` theo id từ `controller.wallets` (số dư mới) + nạp lại danh sách giao dịch qua `controller.transactionsOf` (khoản chuyển xuất hiện 2 vế màu trung tính — FR-014, SC-002); bỏ import/default `TransactionSource`
- [X] T019 [US1] Sửa `app/sora_thu_chi/test/wallet_detail_screen_test.dart`: case "(h)" (Chuyển tiền trước no-op) đổi thành — thẻ VIB: chạm "Chuyển tiền" → SnackBar thông báo, không mở màn (acceptance 10); Vietcombank có ví đích hợp lệ (fake seed Momo) → chạm → mở `WalletTransferScreen` (FR-001); sau khi màn chuyển pop `true` → về detail số dư VCB `12.800.000 đ` + giao dịch đã reload (dòng transfer mới hiện trong nhóm — FR-014, SC-002); case bơm sẵn `transactions` giữ nguyên như cũ; cập nhật các test khác (vd `wallet_list_screen_test.dart`) nếu đổi hành vi default-load khi `transactions == null` — đảm bảo đăng ký `FakeWalletRepository` trước pump

## Pha cuối: Polish & Cross-cutting

- [X] T020 Chạy `flutter analyze` (sạch 0 warning) + `flutter test` toàn bộ tại `app/sora_thu_chi/` (test PBI 2–7 + PBI 8 mới pass, kể cả DAO có skip-guard); xác nhận `app_database.g.dart` mới đã sinh & sẽ commit; đối chiếu danh sách "Không đổi" plan.md — `main.dart`, `app.dart`, `boot_gate.dart`, `pin_*`, shell, `settings_screen.dart`, dashboard/report/transaction screens, `wallet.dart`/`wallet_rules.dart`/`wallet_source.dart`, `add_transaction_screen.dart`, `device_profile.dart`, `wallet_list_screen.dart` không thay đổi (trừ các file trong tasks trên) + ghi nhận seed 11 dòng mẫu / quyết định mở #1 (R2/R4)
- [X] T021 Kiểm chứng thủ công emulator theo `.specify/specs/8/quickstart.md` nhóm A–F: mở màn chuyển từ chi tiết Vietcombank đúng mockup (A), chọn đích / hoán đổi / preview "Số dư sau chuyển" `12.800.000 / 3.450.000` (B), lỗi đúng trường + chống double-tap + back không lưu (C), chuyển vượt số dư cảnh báo mềm (D), sau chuyển về chi tiết 2 ví số dư + giao dịch gần đây đúng + **bền qua restart** (E, drift mới), chặn thẻ tín dụng / chỉ 1 ví / cỡ chữ lớn + safe area + không hồi quy khóa app (F); ghi kết quả vào trạng thái PBI

## Sơ đồ phụ thuộc

```text
Foundational:
  T001 transaction_source (seed 11 + nhóm 2 vế transfer) ──▶ T006 app_database schema v2 + seed ──▶ T011 DriftWalletRepository
  T002 [P] money_format.parseAmount ───▶ T008 money_format_test
  T003 [P] date_label.formatDateTimeLabel ─▶ T009 date_label_test
  T004 [P] transfer_rules.dart ────────▶ T007 transfer_rules_test
  T005 [P] WalletRepository abstract ──▶ T010 Fake ──▶ T012 WalletController ──▶ T014 controller_test
                                       └─▶ T011 (drift) ──▶ T015 transactions_dao_test
  T006 ──▶ T013 wallets_dao_test (migration v1→v2)
US1:
  T016 wallet_transfer_screen ──▶ T017 transfer_screen_test [P]
  T016 ──▶ T018 wallet_detail_screen wiring ──▶ T019 detail_test
Polish:
  T020 analyze + full test ──▶ T021 QA emulator
```

Thứ tự thực thi chính: `T001 → T006 → T011 → T015 → T005 → T010 → T012 → T014 → T016 → T018 → T019 → T020 → T021` (các task `[P]` chạy xen kẽ ngay khi file nền tương ứng xong; T002–T005 & T007–T009 có thể khởi động song song từ đầu với T001).

## Ví dụ chạy song song

```text
# Foundational — khởi động đồng thời từ đầu (khác file, độc lập):
T001 transaction_source.dart      T002 [P] money_format.dart      T003 [P] date_label.dart
T004 [P] transfer_rules.dart      T005 [P] wallet_repository.dart

# Foundational — tầng test sau khi file tương ứng xong:
T007 [P] transfer_rules_test      T008 [P] money_format_test      T009 [P] date_label_test
T013 [P] wallets_dao_test (sau T006)   T014 [P] wallet_controller_test (sau T010/T012)
T015 [P] transactions_dao_test (sau T011)

# US1 — test màn chuyển chạy song song việc nối màn chi tiết (sau T016):
T017 [P] [US1] wallet_transfer_screen_test.dart
T018     [US1] wallet_detail_screen wiring
```

## Chiến lược triển khai

- **MVP đề xuất**: User Story 1 (toàn bộ PBI 8 — đặc tả là một lát cắt chuyển tiền duy nhất, không chia user story P1/P2). Foundational dựng phần dữ liệu (schema `transactions` v2 + seed + seam repository/controller + hàm thuần) làm tiền đề bắt buộc; US1 ghép màn chuyển + nối màn chi tiết ví lên để ra giá trị end-to-end.
- **Thứ tự giao hàng tăng dần**: Foundational (hạ tầng ghi transfer atomic + quy tắc chuyển + bộ test data) → US1 Chuyển tiền (màn `wallet_transfer_screen` + wiring màn chi tiết + widget test) → Polish (analyze/test toàn cục + QA emulator theo quickstart nhóm A–F). Mỗi lát cắt dùng `FakeWalletRepository` bơm qua seam — không cần sqlite native trên host; màn chi tiết và màn chuyển dùng chung `WalletController` nên thi công tuần tự T016 → T018 trên đúng seam đã mở rộng ở Foundational.
