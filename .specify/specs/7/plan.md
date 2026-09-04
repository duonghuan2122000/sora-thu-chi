# Kế hoạch triển khai: Thêm/sửa ví (form dùng chung + hạ tầng lưu ví drift)

**Mã PBI**: 7
**Liên kết spec**: .specify/specs/7/spec.md
**Ngày tạo**: 2026-09-04

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12.x / Flutter stable (máy Windows — theo PBI 1–6) |
| Framework / Thư viện chính | Flutter Material; **GetX** state (`get ^4.7.3` đã có — app dùng `GetMaterialApp` + `PinController` ở PBI 3); UI form widget thuần + controller |
| Lưu trữ dữ liệu | **drift `^2.34.4` (đã khai báo) — PBI này wire lần đầu**: thêm runtime deps `sqlite3_flutter_libs`, `path_provider`, `path`; dev deps `drift_dev` (cùng dòng 2.x) + `build_runner`; codegen `.g.dart`. Bảng `wallets` (schemaVersion 1, seed 5 ví mẫu ở `onCreate`). Giao dịch vẫn mock (`TransactionSource`, PBI 6) |
| Kiểm thử | `flutter analyze` sạch + `flutter test`: unit `wallet_rules` (mặc định), controller test (qua `FakeWalletRepository` — **không** sqlite native trên host), widget test list/detail/form, tích hợp DAO drift (`NativeDatabase.memory()`, skip-guard nếu host thiếu sqlite); **cập nhật** test PBI 5 (list đọc controller) + PBI 6 (case "Sửa ví" giờ mở form); QA emulator theo `quickstart.md` |
| Nền tảng triển khai | Android (kiểm chứng chính); iOS code thuần widget + drift có `sqlite3_flutter_libs`, rủi ro thấp — verify khi có máy macOS |
| Ràng buộc hiệu năng | Không đặc thù; DB 5–vài chục dòng, đọc 1 lần lúc vào danh sách → không cần cache phức tạp |
| Ràng buộc khác | App offline; màn chỉ sau mở khóa (PBI 3 — không làm thêm); sub-page không bottom nav; design system (app bar teal, 1 teal hành động, coral chỉ chi tiêu; bo 10/nút 44; `đ` định dạng); style tập trung token; tài liệu & commit tiếng Việt có dấu |

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md`. Đối chiếu `CLAUDE.md` + design system + wiki [[Ví & Tài khoản]]/[[Nguyên tắc nghiệp vụ]]/[[Stack kỹ thuật]]:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không đăng nhập/server | ✅ | drift SQLite local file; không gọi mạng |
| Đúng stack đã chốt (drift + GetX) | ✅ | Đúng dịp: luồng ghi đầu tiên → wire drift; GetX controller như `PinController` |
| Số dư ví là đại lượng suy ra, không sửa tay | ✅ | Lưu `balance` cache + `initial_balance`; ví đã có giao dịch khóa số dư, chỉ sửa qua giao dịch điều chỉnh (ngoài phạm vi — form chỉ nhắc) |
| `initial_balance` bất biến sau khi có giao dịch | ✅ | FR-010 ma trận khóa (data-model §Ma trận) |
| "Ví mặc định chỉ 1" | ✅ | Bất biến tại `wallet_rules.dart` + unit test; tự chọn thay thế khi tắt |
| "Ẩn thay vì xóa khi có lịch sử" | ✅ | Ngoài phạm vi (ẩn/xóa PBI riêng); sửa giữ `is_hidden` (FR-012) |
| "Cấm số liệu minh họa giả" | ⚠️ | Seed ví mẫu vào DB thật (nối PBI 5/6) — spec/pha demo bắt buộc, xem Rủi ro & Quyết định mở #1 |
| Design system (teal sub-page, bo, `đ`; không hex cứng) | ✅ | Form sub-page `SubPageScaffold`; nút chính 44 bo 8; màu preset tách token; không hex trong widget |
| "Số liệu suy ra không sửa tay" & style tập trung | ✅ | Mở rộng `Wallet` optional + token màu tập trung `app_colors` |
| Tài liệu & commit tiếng Việt có dấu | ✅ | Toàn bộ file tiếng Việt |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Quyết định chính:

- **Wire drift ngay** bảng `wallets` (Q1 — user chọn): deps `sqlite3_flutter_libs`/`path_provider`/`path` + dev `drift_dev`/`build_runner`, migration schemaVersion 1, **seed 5 ví mẫu ở `onCreate`** (Q3) để giữ liên tục PBI 5/6; `WalletSource` thành hằng seed.
- **`WalletRepository` (interface) ← `DriftWalletRepository` + `FakeWalletRepository` (test)**, `WalletController extends GetxController` giữ `RxList<Wallet>` (Q2/Q13). Screen danh sách đọc controller reactive; screen chi tiết giữ nhận `Wallet` qua constructor, chỉ thành `StatefulWidget` cập nhật sau sửa (tránh đập lại test PBI 6).
- **Chỉ VND đợt này** (Q4 — user chọn): cột `currency='VND'` lưu sẵn; form hiển thị VND đọc-only. Lệch FR-006 có chủ đích.
- **`hasTransactions` truyền vào form từ người gọi** (Q5); **bất biến ví mặc định = hàm thuần** `wallet_rules.dart` unit test trực tiếp (Q6); **mở rộng `Wallet` bằng trường optional + `copyWith`** (Q7); trường riêng động theo loại + validate hạn mức thẻ >0 (Q8); **icon/ màu preset** `wallet_presets.dart` + token tint (Q9); **form một scroll + nút Lưu cố định chân** (mở rộng `SubPageScaffold` thêm `bottomNavigationBar`) (Q10); nối điểm vào list "+ Thêm ví mới" + detail "Sửa ví" (Q11); **test không lệ thuộc sqlite native** — widget/unit/controller dùng fake repo, DAO tích hợp dùng `NativeDatabase.memory()` skip-guard (Q12); khởi tạo controller qua `WalletDeps.ensure()` khi vào màn danh sách, không đụng luồng PIN (Q13); dashboard/report/giao dịch không đổi (Q14).

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — bảng drift `wallets` (18 cột, schemaVersion 1, seed ở `onCreate`), trường `Wallet` bổ sung, ma trận khóa trường thêm/sửa theo "đã có giao dịch", bất biến ví mặc định.
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app nội bộ offline, không API/CLI (research Q14).
- **Kịch bản khởi động nhanh**: xem `quickstart.md` — nhóm QA A–J đối chiếu SC/acceptance/FR, gồm kiểm bền qua restart (điểm mới của drift) + validation + bất biến mặc định + khóa trường khi đã có giao dịch.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Không phình layer nghiệp vụ | ✅ | Thêm đúng 1 bảng + 1 controller + repository seam + hàm thuần rule; không service/event bus dư |
| Đúng seam cho PBI Giao dịch sau | ✅ | `transactions` chưa vào DB; giao dịch mock giữ nguyên; repo chỉ `wallets` — PBI sau thêm bảng mới, không đập cấu trúc |
| Test không phụ thuộc thiết bị/sqlite native | ✅ | Fake repo cho mọi test màn/controller; DAO tích hợp skip-guard (Q12) |
| Shell, PIN, Cài đặt, list/detail cũ không vỡ | ⚠️ | Danh sách đổi sang đọc controller → **test PBI 5 phải cập nhật** (chuyển bơm `wallets` → bơm controller fake seed); detail case "Sửa ví no-op" → giờ mở form (PBI 6 test sửa). Đây là thay đổi có chủ đích theo spec, không phải hồi quy |
| Tái dùng hơn viết mới | ✅ | `SubPageScaffold`, `AppColors`, `formatMoney`/`formatAmount`, `walletsByDisplayOrder`/`activeTotal`, `WalletSource` (seed), `WalletType` enum + label có sẵn; không thêm lib icon/intl |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── pubspec.yaml                                   # [SỬA] + sqlite3_flutter_libs, path_provider, path;
│                                                  #        dev + drift_dev, build_runner
├── lib/
│   ├── data/
│   │   ├── db/
│   │   │   ├── app_database.dart                  # [TẠO] drift: @DriftDatabase(tables:[Wallets]);
│   │   │   │                                      #        AppDatabase + mở file (NativeDatabase
│   │   │   │                                      #        .createInBackground, path_provider);
│   │   │   │                                      #        onCreate: tạo bảng + SEED 5 ví mẫu
│   │   │   └── app_database.g.dart                # [GEN] build_runner (commit)
│   │   ├── wallet_repository.dart                 # [TẠO] abstract WalletRepository (loadAll/insert/
│   │   │                                          #        update) — seam test
│   │   └── wallet_repository_drift.dart           # [TẠO] DriftWalletRepository: map Wallet↔row, ghi DB
│   ├── core/
│   │   ├── wallet/
│   │   │   ├── wallet.dart                        # [SỬA] + trường optional (initialBalance, currency,
│   │   │   │                                      #        color ARGB?, statementDate/dueDate?,
│   │   │   │                                      #        termMonths?, maturityDate?, institutionName?,
│   │   │   │                                      #        lastDigits?) + copyWith — giữ const cũ
│   │   │   ├── wallet_source.dart                 # [SỬA] seed 5 ví mẫu kèm initialBalance (Vietcombank
│   │   │   │                                      #        initial 1.200.000 = balance), color mặc định…
│   │   │   ├── wallet_controller.dart             # [TẠO] WalletController(GetxController, RxList<Wallet>):
│   │   │   │                                      #        init() nạp repo + ensureDefault khi rỗng;
│   │   │   │                                      #        create(draft,{wantDefault})/update(id,draft,…):
│   │   │   │                                      #        gọi wallet_rules → repo ghi → reload cache
│   │   │   ├── wallet_rules.dart                  # [TẠO] hàm thuần: hasActiveDefault / resolveOnCreate /
│   │   │   │                                      #        resolveOnUpdate (dời/cho-tắt/chặn-tắt mặc định)
│   │   │   └── wallet_presets.dart                # [TẠO] icon emoji set + defaultIconFor(type) + tham
│   │   │                                          #        chiếu bảng màu tint (token app_colors)
│   │   └── widgets/sub_page_scaffold.dart         # [SỬA] + tham số bottomNavigationBar (forward Scaffold)
│   ├── data/wallet_deps.dart                      # [TẠO] ensureWalletController(): Get.isRegistered hoặc
│   │                                          #        put DriftWalletRepository+controller, load nền
│   └── screens/
│       ├── wallet_form_screen.dart                # [TẠO] WalletFormScreen({Wallet? wallet, bool hasTxns,
│       │                                          #        WalletController controller}): sub-page teal;
│       │                                          #        một scroll: Tên / Loại chip(5) / Số dư ban đầu
│       │                                          #        + Tiền tệ(VND read-only) / trường riêng động
│       │                                          #        theo loại / icon+màu / Switch mặc định (khóa khi
│       │                                          #        default duy nhất) / ghi chú khóa nếu hasTxns;
│       │                                          #        nút Lưu cố định chân (SC-007); validate lỗi đúng
│       │                                          #        trường; pop trả kết quả (FR-013/014)
│       ├── wallet_list_screen.dart                # [SỬA] đọc WalletController (Obx RxList) thay vì tham số
│       │                                          #        wallets; _AddWalletButton → push WalletFormScreen
│       │                                          #        (thêm) — list tự cập nhật tổng/hàng (FR-013);
│       │                                          #        hàng giữ push WalletDetailScreen(wallet)
│       └── wallet_detail_screen.dart              # [SỬA] StatelessWidget → StatefulWidget; hành động nhanh
│                                                  #        "Sửa ví": push WalletFormScreen(wallet,
│                                                  #        hasTransactions: transactions.isNotEmpty), nhận kết
│                                                  #        quả → setState wallet; 2 nút còn lại giữ no-op
└── test/
    ├── fakes/fake_wallet_repository.dart          # [TẠO] map bộ nhớ: loadAll/insert/update (seed WalletSource)
    ├── wallet_rules_test.dart                     # [TẠO] unit: ví đầu tiên mặc định / bật dời cờ / tắt chọn
    │                                              #        thay thế / chặn tắt khi default duy nhất (SC-005…)
    ├── wallet_controller_test.dart                # [TẠO] controller + fake repo: create/update ghi qua repo,
    │                                              #        cache reactive, đúng bất biến mặc định
    ├── wallet_form_screen_test.dart               # [TẠO] widget: render 2 chế độ, chip đổi trường riêng,
    │                                              #        validation lỗi đúng trường, khóa khi hasTxns,
    │                                              #        chặn tắt default duy nhất, cỡ chữ lớn/safe area,
    │                                              #        back giữ nguyên, lưu pop đúng kết quả
    ├── wallets_dao_test.dart                      # [TẠO] drift NativeDatabase.memory(): migration+seed
    │                                              #        (5 ví) + CRUD; skip-guard nếu host thiếu sqlite
    ├── wallet_list_screen_test.dart               # [SỬA] bơm WalletController(fake) thay tham số wallets;
    │                                              #        "+ Thêm ví mới" → mở WalletFormScreen
    └── wallet_detail_screen_test.dart             # [SỬA] case (h): chạm "Sửa ví" → mở form (không còn
                                                   #        no-op); các case còn lại giữ bơm Wallet/transactions
```

Không đổi: `main.dart`, `app.dart`, `boot_gate.dart`, `pin_*`, shell, `settings_screen.dart`, dashboard/report/transaction screens, `transaction.dart`/`transaction_source.dart`, `device_profile.dart`.

## Rủi ro & ngoại lệ có lý do

- **Seed ví mẫu vào DB thật (kế thừa pha demo PBI 5/6)** — nguyên tắc "cấm số liệu minh họa" được gỡ vì pha hiện tại mọi màn đang demo và giao dịch mock tham chiếu `walletId` 1..5; bỏ seed → app mở ra danh sách rỗng, đứt QA cũ. Seed chỉ chạy `onCreate`. **Gỡ khi PBI Giao dịch tới** (có luồng xóa + dữ liệu thật) — Quyết định mở #1. Acceptance 3 (ví đầu tiên) không QA tay được (DB luôn seed) → phủ bằng unit test `wallet_rules`.
- **Chỉ VND, lệch FR-006** — user chốt. Form hiển thị VND đọc-only; đa tiền tệ + render đơn vị theo ví để PBI module tiền tệ. Cột `currency` lưu sẵn `'VND'` tránh migration sau.
- **Test PBI 5 & 6 phải cập nhật** — danh sách chuyển nguồn sự thật sang `WalletController` (fake repo), detail case "Sửa ví no-op" thành "mở form". Thay đổi có chủ đích theo spec, không phải hồi quy; giữ bộ mẫu như cũ nên số liệu QA khớp.
- **Drift = hạ tầng mới toàn project** — lần đầu wire: deps + build_runner codegen + migration + mở file. Giữ phạm vi đúng 1 bảng `wallets`, không tạo schema giao dịch (PBI sau). Nếu `drift_dev`/`build_runner` có xung đột version → để `flutter pub` tự giải, chốt bản trong lúc thi công.
- **`sqlite3.dll` trên host Windows** — `flutter test` màn/controller chạy fake repo nên không cần; riêng DAO tích hợp `NativeDatabase.memory()` cần sqlite native → nếu host chưa có, test `markTestSkipped` + phủ bằng QA emulator (app thật dùng `sqlite3_flutter_libs`). Cân nhắc cài sqlite cho host để đóng test DAO.
- **"Tự chọn ví mặc định thay thế" xấp xỉ theo thứ tự hiển thị** — spec §Giả định ưu tiên "số dư dương + dùng gần nhất"; chưa có trường `last_used_at` → chọn ví active đầu (`sortOrder`). Bổ sung khi có khái niệm "dùng gần nhất" (Quyết định mở #2).
- **Màu ví / bảng palette chưa có mockup chi tiết** — spec giao cho triển khai; dùng tint sáng tập trung token, đối chiếu mắt emulator; lệch nhỏ chỉnh được.
- **iOS chưa verify** (máy Windows): widget/material thuần + drift có plugin native — rủi ro thấp nhưng cần chạy thật trên macOS khi có; giữ trạng thái.

## File đã tạo

- `.specify/specs/7/research.md`
- `.specify/specs/7/data-model.md`
- `.specify/specs/7/quickstart.md`
- `.specify/specs/7/plan.md`

Bước tiếp theo: chạy `/sora-task 7` để phân rã thành tasks.md.
