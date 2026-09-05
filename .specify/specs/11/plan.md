# Kế hoạch triển khai: Màn hình thêm giao dịch & chọn danh mục

**Mã PBI**: 11
**Liên kết spec**: .specify/specs/11/spec.md
**Ngày tạo**: 2026-09-05

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12.x / Flutter stable (máy Windows — theo PBI 1–10) |
| Framework / Thư viện chính | Flutter Material; GetX ở màn chính (giữ nguyên); màn thêm + chọn danh mục **Stateful + repository inject** (bám `WalletTransferScreen`/detail, R11); `SubPageScaffold`/`Scaffold`, token `AppColors`, `formatMoney`, `categoryGlyph`, pattern fake test |
| Lưu trữ dữ liệu | **drift `^2.34.4`, schema v3 → v4**: tạo bảng `Categories` + thêm cột `transactions.category_id` (nullable) + seed danh mục mặc định (R1/R2/R4); domain `Category`/`CategoryType`; `build_runner` tái sinh `.g.dart` |
| Kiểm thử | `flutter analyze` sạch + `flutter test`: unit thuần (numpad digit/backspace, `missingRequiredFields`, dirty, ghi-đúng-dấu/bù-balance của `addTransaction`, chọn con/cha, đọc categories lọc type/ẩn), widget (seam/fake repo: màn thêm bố cục + numpad + validation + lưu pop true, màn chọn danh mục lưới/drill/Thêm mới no-op, cỡ chữ lớn + safe area), DAO drift memory (schema v4: categories seed + `category_id` map, skip-guard) |
| Nền tảng triển khai | Android (kiểm chứng chính); iOS widget thuần — rủi ro thấp, verify khi có máy macOS |
| Ràng buộc hiệu năng | SC-001: mở màn + ghi xong trong 30s thao tác; nạp ví/danh mục local nhỏ; chống bấm lưu 2 lần tạo trùng (FR-012) |
| Ràng buộc khác | App offline; màn chỉ sau mở khóa (PBI 3 — không làm thêm). Design system: teal `#0F6E56` (hành động chính/thu), coral `#D85A30` (chỉ chi/cảnh báo); mockup `02`/`03`; màn tác vụ đơn không bottom nav; tiền VND số nguyên, `,` no-op; danh mục mặc định + picker (cha-con 2 cấp) nguồn từ bảng `categories`; tài liệu & commit tiếng Việt có dấu |

*Không còn mục `NEEDS CLARIFICATION` — giải quyết toàn bộ ở research R1–R12 (schema v4 do người dùng chốt, R1).*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md`. Đối chiếu `CLAUDE.md` + design system + wiki [[Giao dịch]]/[[Danh mục]]/[[Nguyên tắc nghiệp vụ]]/[[Stack kỹ thuật]]:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không đăng nhập/server | ✅ | drift SQLite local; không gọi mạng |
| Đúng stack đã chốt (drift + GetX, không thêm dependency) | ✅ | Không thêm lib; màn thêm/chọn Stateful + repository (không phình GetX cho màn tác vụ — R11) |
| Số dư ví là đại lượng suy ra, không sửa tay | ⚠️ | Bảng `wallets.balance` đang được duy trì eager khi ghi (PBI 8 transfer); PBI 11 bù balance cùng insert thu/chi trong 1 `db.transaction()` — nhất quán cơ chế hiện có; đánh dấu ceiling "suy ra theo ngày" (data-model §bất biến 7) |
| Transfer không phải thu/chi, không vào báo cáo | ✅ | Tab "Chuyển khoản" mở luồng PBI 8; màn này chỉ ghi thu/chi, không gắn danh mục cho transfer (FR-003) |
| Đúng 1 ví mặc định; ví ẩn không dùng ghi giao dịch mới | ✅ | Trường Ví pre-select ví mặc định, danh sách chọn = ví hoạt động (không ẩn), gồm thẻ tín dụng (R8) |
| Mỗi PBI = một màn; điểm vào chưa kích hoạt luồng sâu | ✅ | Ô "Thêm mới" lưới danh mục no-op không lỗi/treo (module Danh mục sau — FR ngoài phạm vi); sửa/xóa/nhân bản chưa kích hoạt |
| Design system (teal/coral, bo 8/10/44px, `đ`, token, không hex cứng widget) | ✅ | Tái dùng `AppColors`; accent số tiền theo loại (chi coral / thu teal); nút bo 8 cao 44; màu danh mục là **dữ liệu** trong `Categories` (không phải styling cứng) |
| "Ẩn giữ lịch sử & báo cáo" | ✅ | Giao dịch cũ/không khớp danh mục vẫn hiển thị qua `category` text; `category_id` null không phá màn đọc PBI 9/10 (R2) |
| "Cấm số liệu minh họa giả" | ⚠️ | Seed demo 11 dòng giữ nguyên; **thêm** seed danh mục mặc định (bảng mới, không phải dữ liệu giả hiển thị); vẫn gỡ cùng quyết định mở #1 khi module Giao dịch có dữ liệu thật |
| Tái dùng hơn viết mới | ✅ | Repository/domain/categoryGlyph/pattern bottom-sheet + dialog + fake; chỉ thêm bảng + method + 2 màn + widget numpad |
| Test không phụ thuộc sqlite native | ✅ | Unit/widget chạy fake/seam; DAO tích hợp skip-guard (như PBI 7–10) |
| Tài liệu & commit tiếng Việt có dấu | ✅ | Toàn bộ file tiếng Việt |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Quyết định chính:

- **Schema v4**: bảng `Categories` (id/name/type/icon/color/parent_id/sort_order/is_system/is_hidden) + cột `transactions.category_id`; **giữ** `category` text = snapshot hiển thị (không hồi quy PBI 9/10) — **user chốt** (R1/R2).
- **Repository thêm**: `categories({type})` (hoạt động, đúng type) + `addTransaction(...)` (1 `db.transaction()`: bù `wallets.balance` ± + insert dòng có dấu theo loại, `category_id` + `category.name`) (R3).
- **Seed danh mục mặc định**: 8 chi + 4 thu (gồm Khác) + con Ăn uống (Cà phê/Ăn ngoài/Đi chợ), màu/icon bám mockup; seed trong drift trước seed giao dịch; dòng cũ khớp tên → gán id, không khớp → null (R4).
- **Màn chọn danh mục**: 1 route, lưới cha 4 cột + khoan xuống con ngay trong màn ("DANH MỤC CON"), ô "Thêm mới" no-op, trả `Category` đã chọn (R5).
- **Nhập số tiền bằng numpad tùy chỉnh** (phím `,` no-op), số nguyên VND, accent chi coral/thu teal, hàm thuần digit/backspace/giới hạn 12 số (R6).
- **Màn thêm**: Scaffold riêng (app bar teal, leading X/actions check), segmented Chi|Thu|Chuyển khoản (default Chi), vùng số tiền + 4 trường + numpad + nút "Lưu giao dịch"; cờ `_saving` chống trùng; `_missing` báo lỗi tại trường; dialog xác nhận khi rời dirty (R7/R9).
- **Ví**: pre-select ví mặc định, chọn từ ví hoạt động (gồm thẻ), xử lý rỗng/1 ví (R8).
- **Tab "Chuyển khoản"** → push luồng PBI 8; **làm mới** gom ở `AppShell` sau `pop(true)` gọi `ensureTransactionController().load()` (R10).
- **Test seam**: `WalletRepository?` inject vào 2 màn; fake mở rộng (`categories`/`addTransaction`); hàm thuần để unit test (R11).

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — schema v4 (bảng `Categories` + `transactions.category_id`), domain `Category`/`CategoryType`, seed mặc định, repository method mới, migration & bất biến hiển thị.
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app nội bộ offline, không API/CLI (bám PBI 7–10).
- **Kịch bản khởi động nhanh**: xem `quickstart.md` — nhóm QA A–H đối chiếu acceptance/FR/SC kèm bảng seed danh mục; QA tay emulator.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Không phình layer nghiệp vụ | ✅ | Thêm đúng 1 bảng + 2 method repository + 2 domain file + 2 màn + 1 widget numpad + hàm thuần nhỏ; không service/event bus dư |
| Đúng seam cho module Giao dịch/Danh mục sau | ✅ | Màn thêm chỉ **tạo mới** (sửa/xóa/nhân bản chưa kích hoạt); bảng `categories` có sẵn cho module Danh mục CRUD; ô "Thêm mới" no-op; display giữ text snapshot nên đổi sang join sau không vỡ màn cũ |
| Không lệch 2 phía balance–giao dịch | ✅ | `addTransaction` ghi trong 1 `db.transaction()` (bù balance + insert), không có trạng thái lưu nửa chừng (FR-012 edge) |
| Chống giao dịch trùng | ✅ | Cờ `_saving` vô hiệu 2 điểm lưu (nút + check) khi đang lưu; lỗi hệ thống → snackbar giữ form |
| Chọn danh mục đúng loại | ✅ | Picker lọc `categories(type)` theo loại đang ghi; không chọn chéo thu/chi (FR-006/SC-004) |
| Không hồi quy PBI 6/8/9/10 | ⚠️ | Thay đổi có chủ đích: (1) schema v4 additive (`category_id` nullable, bảng mới); (2) seed `categories` + gán id cho dòng khớp tên; (3) FAB no-op → mở màn thêm thật (phải cập nhật kỳ vọng test PBI 2/9). Chạy lại toàn bộ test cũ xác minh |
| Reuse > viết mới | ✅ | Tái dùng `formatMoney`/`categoryGlyph`/`WalletController` (chuyển khoản)/pattern dialog + bottom-sheet + fake; chỉ thêm phần PBI 11 thiếu |
| Fake repo luôn chạy mọi test màn/controller | ✅ | Mở rộng fake: `categories` (seed) + `addTransaction` (ghi list + bù balance); field mới domain `categoryId` default null |
| Khóa app không lộ số tiền | ✅ | Màn thêm/chọn là route trong shell sau boot-gate (PBI 3) — không làm thêm |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── core/
│   │   ├── category/
│   │   │   ├── category.dart                    # [TẠO] enum CategoryType{income,expense} + domain Category
│   │   │   │                                    #        (id/name/type/icon/color/parentId/sortOrder/
│   │   │   │                                    #        isHidden/isSystem, isParent)
│   │   │   └── category_source.dart             # [TẠO] hằng seed bảng danh mục mặc định (cha + con) —
│   │   │                                        #        pattern WalletSource (R4)
│   │   ├── transaction/
│   │   │   ├── transaction.dart                 # [SỬA] + categoryId (int?) — additive, map từ drift
│   │   │   ├── transaction_source.dart          # [SỬA] (không đổi dòng/giá trị — hồi quy); drift seed gán
│   │   │   │                                    #        category_id khi tên khớp (xem app_database)
│   │   │   └── add_form.dart                    # [TẠO] thuần: appendAmountDigit/backspaceAmount(maxDigits 12),
│   │   │                                        #        missingRequiredFields, isDirty (R6/R9 — unit test)
│   │   ├── widgets/
│   │   │   ├── amount_keypad.dart               # [TẠO] numpad số tiền (mockup 02): 3×4 phím tròn viền,
│   │   │   │                                    #        ',' no-op + 0 + backspace (R6)
│   │   │   └── category_icon.dart               # [TẠO] categoryIcon(String key) → IconData (map khóa,
│   │   │                                        #        fallback category); dùng picker grid
│   │   └── ... (date_label/money_format giữ nguyên — có sẵn format cần dùng)
│   ├── data/
│   │   ├── db/app_database.dart                 # [SỬA] + bảng Categories + transactions.categoryId,
│   │   │                                        #        schemaVersion 4, migration onCreate/onUpgrade,
│   │   │                                        #        _seedCategories() trước _seedSampleTransactions();
│   │   │                                        #        _seedSampleTransactions gán category_id khớp tên
│   │   ├── db/app_database.g.dart               # [TÁI SINH] build_runner
│   │   ├── wallet_repository.dart               # [SỬA] interface + categories({type}) + addTransaction(...)
│   │   ├── wallet_repository_drift.dart         # [SỬA] impl 2 method (1 db.transaction: bù balance + insert);
│   │   │                                        #        _toTransaction map categoryId; _toCategory
│   │   └── wallet_deps.dart                     # [SỬA] không bắt buộc (đã ensure repo singleton)
│   ├── screens/
│   │   ├── add_transaction_screen.dart          # [VIẾT LẠI] Stateful (R7): Scaffold riêng AppBar teal
│   │   │                                        #        leading X / actions check; segmented Chi|Thu|Chuyển
│   │   │                                        #        khoản (default Chi); vùng số tiền + accent loại;
│   │   │                                        #        4 dòng trường (Danh mục/Ví/Ngày giờ/Ghi chú) —
│   │   │                                        #        Danh mục/Ví/Ngày giờ chạm mở picker/sheet/picker
│   │   │                                        #        (pattern PBI 8); amount_keypad; nút "Lưu giao dịch";
│   │   │                                        #        repository inject (R11); _saving/_missing/isDirty
│   │   │                                        #        dialog xác nhận rời; empty ví → thông báo
│   │   ├── category_picker_screen.dart          # [TẠO] Stateful (R5): lưới cha 4 cột + vùng "DANH MỤC CON"
│   │   │                                        #        khi chọn cha có con; cha không con → chọn; ô
│   │   │                                        #        "Thêm mới" no-op; pop(Category); empty state
│   │   └── transaction_screen.dart              # [SỬA] không bắt buộc (nếu categoryGlyph giữ) — giữ nguyên
│   └── core/app_shell.dart                      # [SỬA] _openAddTransaction await push<bool> → true thì
│                                                 #        ensureTransactionController().load() (R10/FR-013)
└── test/
    ├── fakes/fake_wallet_repository.dart        # [SỬA] + categories (seed CategorySource) + addTransaction
    │                                              #        (ghi list + bù balance); _toTransaction map categoryId
    ├── add_form_test.dart                        # [TẠO] unit thuần: appendAmountDigit (0 đầu, 12 số, chặn
    │                                              #        tràn), backspace, missingRequiredFields, isDirty
    ├── category_source_test.dart                 # [TẠO] seed hợp lệ: tên duy nhất trong cha+type, ≤2 cấp,
    │                                              #        màu/icon đủ, con thuộc cha
    ├── add_transaction_screen_test.dart          # [TẠO] widget fake repo: bố cục mockup (app bar X/check,
    │                                              #        segmented Chi mặc định, số 0 đ, 4 trường + Lưu);
    │                                              #        gõ numpad 1250 → 1.250.000 đ (chi coral/thu teal);
    │                                              #        chọn danh mục/ví/ngày; lưu pop(true) + ghi đúng loại/
    │                                              #        số/ví/ngày; thiếu trường → báo tại trường, không lưu;
    │                                              #        dirty + X → dialog xác nhận; 2 lần Lưu → 1 dòng;
    │                                              #        empty ví → chặn; cỡ chữ lớn + safe area không vỡ
    ├── category_picker_screen_test.dart          # [TẠO] widget fake: lưới đúng loại (thu/chi tách), cha có con
    │                                              #        → vùng con, chọn con → pop(Category), cha không con →
    │                                              #        chọn, "Thêm mới" no-op, empty state
    ├── transaction_test.dart / dao               # [SỬA] domain categoryId default null; test cũ chạy lại
    ├── transactions_dao_test.dart                # [SỬA] schema v4: seed categories (bảng rỗng → 12 cha/3 con?),
    │                                              #        allTransactions trả category_id khớp tên (row 1 Ăn uống),
    │                                              #        addTransaction drift (bù balance + dòng đúng dấu/id)
    ├── wallet_repository_test / wallet_*         # chạy lại — không hồi quy (domain/seed additive)
    ├── transaction_* / transaction_detail_*      # chạy lại — không hồi quy (text snapshot giữ nguyên)
    └── widget_test.dart                          # [SỬA] FAB mở màn thêm (thay kỳ vọng no-op) + shell refresh
```

Không đổi: `wallet_*` screens/controller, màn main, PIN/boot, `transaction_list.dart`/`transaction_detail.dart` (đọc text), `transaction_controller.dart`, `sub_page_scaffold.dart`, `date_label.dart`, `money_format.dart`.

## Rủi ro & ngoại lệ có lý do

- **Schema v4 + migration chạm seed giao dịch cũ** — phải chạy `build_runner` tái sinh `.g.dart`; `createTable(categories)` + `addColumn(category_id)` trong nhánh `from < 4` (DB cũ chưa có bảng), seed categories chèn **1 lần** (kiểm bảng rỗng) để không duplicate khi upgrade nhiều bước; giao dịch cũ không khớp tên danh mục mặc định giữ `category_id` null — hiển thị text không đổi (R2). Test DAO skip-guard host thiếu sqlite.
- **`balance` eager vs ngày tương lai** — ghi giao dịch tương lai vẫn bù balance ngay (khớp `performTransfer` hiện có). "Số dư suy ra theo ngày giao dịch" là lý tưởng docs nhưng cơ chế đang duy trì cột eager; đánh `ponytail:` ceiling — chỉnh khi module ví/bao nhiêu PBI cần (data-model §bất biến 7).
- **Hai nguồn hiển thị danh mục (text snapshot + bảng)** — cố ý: `category` text giữ màn PBI 9/10 không hồi quy; `category_id` là tham chiếu mới. Nguy cơ lệch text/id khi module Danh mục đổi tên sau — đã ghi là snapshot, màn đọc đổi join khi đó. Không phải rào cản PBI 11.
- **Màu/icon danh mục mặc định tự chọn từ mockup** (docs không quy định) — lựa chọn tối thiểu, module Danh mục sau cho phép CRUD. QA đối chiếu mockup dùng bảng seed trong `data-model.md`.
- **Hồi quy có chủ đích FAB (PBI 2/9)** — stub no-op chuyển thành màn thêm thật; test AppShell phải cập nhật kỳ vọng. Seed giao dịch/giá trị giữ nguyên — test số lượng/tổng PBI 9/10 không đổi.
- **iOS chưa verify** (máy Windows): widget thuần + drift plugin native — rủi ro thấp, giữ trạng thái.
- **`sqlite3.dll` host Windows** — unit/widget chạy fake/inject; DAO `NativeDatabase.memory()` skip-guard + QA emulator (như PBI 7–10).
- **Danh mục seed có thể thay đổi sau này** — người dùng tự tạo/quản lý danh mục là module Danh mục riêng (ngoài đợt); màn này dùng bảng mặc định seed sẵn.

## File đã tạo

- `.specify/specs/11/research.md`
- `.specify/specs/11/data-model.md`
- `.specify/specs/11/plan.md`
- `.specify/specs/11/quickstart.md`

Bước tiếp theo: chạy `/sora-task 11` để phân rã thành tasks.md.
