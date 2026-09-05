# Kế hoạch triển khai: Tìm kiếm & lọc giao dịch

**Mã PBI**: 12
**Liên kết spec**: .specify/specs/12/spec.md
**Ngày tạo**: 2026-09-05

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12.x / Flutter stable (máy Windows — theo PBI 1–11) |
| Framework / Thư viện chính | Flutter Material; `TransactionController` GetX singleton (giữ); màn lọc `05` **Stateful + repository inject** (seam PBI 11); tái dùng `SubPageScaffold` pattern (bottom bar), `AppColors`, `formatMoney/formatAmount`, `AmountKeypad`, `categoryIcon`, `walletsByDisplayOrder`, `buildDisplayRows/groupDisplayRows` |
| Lưu trữ dữ liệu | **Không đổi schema** (drift schema v4 giữ nguyên, không chạy `build_runner`); tính năng **chỉ đọc**: `allTransactions/loadAll/categories({type})` hiện có |
| Kiểm thử | `flutter analyze` sạch + `flutter test`: unit thuần (`transaction_filter`: normalize bỏ dấu, khớp AND từng tiêu chí, parent gộp con + fallback tên, group-keep transfer, sort ngày/tiền, summary count/total loại transfer/adjustment, min>max, preset date), widget (fake repo: màn lọc bố cục mockup `05` + chip loại + live summary khi gõ/chip + picker danh mục theo loại + ví + tiền sheet + date preset + Đặt lại/Áp dụng/back giữ tập cũ + cỡ chữ lớn & safe area; màn Giao dịch: icon lọc mở màn, áp dụng → thanh chỉ báo + tập lọc, sort tiền **phẳng**, Bỏ lọc về toàn bộ), controller (setFilter/clearFilter persist qua load, không hồi quy) |
| Nền tảng triển khai | Android (kiểm chứng chính); iOS widget thuần — rủi ro thấp, verify khi có máy macOS |
| Ràng buộc hiệu năng | SC-003: gõ tìm không treo/giật trên tới vài nghìn giao dịch → lọc thuần trên tập cache + summary **debounce ~250ms** (R9); một lần nạp mỗi `load()` (không đọc DB lại từng thao tác — R1) |
| Ràng buộc khác | App offline; chỉ sau mở khóa (PBI 3 — không làm thêm). Design system: teal `#0F6E56` hành động chính/chip chọn, coral `#D85A30` chỉ chi; thu dương/chi âm; tiền `42.500.000 đ`; card bo `10px`, nút bo `8px` cao `44px`. Chỉ đọc giao dịch; "ẩn giữ lịch sử"; transfer gộp 1 dòng (PBI 9). Mockup `05`. Tài liệu & commit tiếng Việt có dấu |

*Không còn `NEEDS CLARIFICATION` — user đã chốt 2 lựa chọn hiển thị (R4 sắp tiền phẳng; R5 thay card bằng thanh lọc).*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md`. Đối chiếu `CLAUDE.md` + design system + wiki [[Giao dịch]]/[[Danh mục]]/[[Nguyên tắc nghiệp vụ]]/[[Stack kỹ thuật]]:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không đăng nhập/server | ✅ | drift SQLite local; không gọi mạng; không thêm dependency |
| Đúng stack đã chốt (drift + GetX), không thêm thư viện | ✅ | Lọc là hàm thuần Dart + widget; không package mới (bỏ dấu tự viết — R9) |
| Số dư ví là đại lượng suy ra | ✅ | Tính năng **chỉ đọc** — không đụng `wallets.balance`, không ghi DB |
| Transfer không phải thu/chi | ✅ | `TxnType.transfer`/`adjustment` có trong N kết quả nhưng **không** vào Tổng (FR-011); chip không có "Điều chỉnh" (R12) |
| "Ẩn giữ lịch sử & báo cáo" | ✅ | Ví/danh mục ẩn: giao dịch vẫn trong tập lọc "Tất cả"; chọn ví ẩn được (xem lịch sử); chỉ không chọn danh mục ẩn trong picker (R7/R8) |
| Mỗi PBI một màn; điểm vào no-op kích hoạt khi tới PBI | ✅ | Icon lọc no-op (PBI 9) → mở màn `05` thật; cập nhật kỳ vọng test (d) |
| Design system (teal/coral, bo, `đ`, token, không hex cứng) | ✅ | Chip chọn teal / trắng viền; nút bo 8 cao 44; `formatMoney`; màu danh mục là dữ liệu `category.color` |
| Không số liệu minh họa giả | ✅ | Không thêm seed; số trên summary lấy trực tiếp từ dữ liệu thiết bị (mockup chỉ minh họa) |
| Tái dùng hơn viết mới | ✅ | Tái dùng display pipeline PBI 9, keypad/color/icon PBI 11, sheet/picker pattern PBI 8; chỉ thêm module filter thuần + 1 màn form + nối hiển thị |
| Test không phụ thuộc sqlite native | ✅ | Unit/widget chạy fake/seam; không đổi DAO (không schema) |
| Tài liệu & commit tiếng Việt có dấu | ✅ | Toàn bộ file tiếng Việt |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Quyết định chính:

- **Lọc trong bộ nhớ, không SQL pushdown** — giữ nguyên repository; filter là hàm thuần trên cache `allTransactions` (giữ bất biến gộp transfer + summary nhanh) (R1).
- **Group-keep transfer** — tiêu chí khớp một vế thì giữ cả 2 vế cùng `transferGroupId` để `buildDisplayRows` gộp 1 dòng (lọc Ví không tách cặp) (R2).
- **Ngữ nghĩa summary** — `N` = dòng hiển thị sau gộp; `Tổng` = thu − chi (transfer/adjustment trong N, ngoài tổng) (R3).
- **Sắp xếp (user chốt)** — sort ngày giữ nhóm header; sort tiền **phẳng** toàn cục theo `abs(amount)` (R4).
- **Chỉ báo lọc (user chốt)** — khi đang lọc, card "Thu/Chi tháng này" ẩn, thay bằng thanh `N kết quả · Tổng: X đ` + "Bỏ lọc" (R5).
- **Filter state trong `TransactionController`** (bền qua tab), màn lọc là form trên **bản nháp**; Áp dụng → `pop(filter)`, back → `pop(null)` giữ tập cũ (R6/FR-015).
- **Danh mục** — chọn cha tự gộp con; khớp `category_id` + fallback tên (dòng lịch sử null id); nguồn chọn theo loại chip; chip Chuyển khoản vô hiệu dòng Danh mục (R7).
- **Ví** — một ví hoặc "Tất cả"; sheet có ví ẩn (xem lịch sử), `walletsByDisplayOrder` (R8).
- **Từ khóa** — normalize bỏ dấu tiếng Việt (tự viết bảng, không thêm package); substring trên note/category/tags; debounce ~250ms (R9).
- **Khoảng tiền** — ô Từ/Đến mở sheet dùng lại `AmountKeypad`; abs bao biên; min>max chặn Áp dụng (R10).
- **Khoảng thời gian** — preset Hôm nay/Tuần này/Tháng này/Toàn bộ + Tùy chọn (2 date picker chặn start>end); mặc định Tháng này; lưu preset + cặp ngày đã giải (R11).

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — **không đổi schema**; domain mới `TxnSearchFilter`/`SortOption`/`DatePreset`/`TxnTypeFilter`/`FilteredTxSummary` + luật khớp AND, group-keep, sort ngày vs tiền, bất biến hiển thị.
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app nội bộ offline, không API/CLI (bám PBI 7–11).
- **Kịch bản khởi động nhanh**: xem `quickstart.md` — nhóm QA A–I đối chiếu acceptance/FR/SC; QA tay emulator.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Không phình layer nghiệp vụ | ✅ | Thêm đúng 1 module thuần (`transaction_filter.dart`) + 1 màn form (`search_filter_screen.dart`) + nối controller/màn danh sách; không service/event bus; **không đổi schema/repository/fake** |
| Đúng seam cho test | ✅ | `SearchFilterScreen` nhận `repository` (mặc định `ensureWalletRepository`) + `initial` filter + `now`; controller giữ seam cũ — mọi test bơm `FakeWalletRepository` |
| Không hồi quy PBI 6/8/9/10/11 | ✅ | Đường dữ liệu `data` (không lọc) giữ nguyên — test cũ xanh; chỉ đổi **có chủ đích**: (1) icon lọc no-op → mở màn lọc (cập nhật test (d)); (2) màn danh sách khi đang lọc ẩn card tháng + thêm thanh chỉ báo (nhánh filter riêng, không đụng nhánh không-lọc). Chạy lại toàn bộ test xác minh |
| Tái dùng > viết mới | ✅ | `buildDisplayRows`/`groupDisplayRows`, `AmountKeypad`, `categoryIcon`/`category.color`, `walletsByDisplayOrder`, `SubPageScaffold.bottomNavigationBar` (nút chân), pattern sheet/dialog PBI 8/11 |
| "Ẩn giữ lịch sử" | ✅ | Tập lọc "Tất cả" luôn gồm giao dịch ví/danh mục ẩn; không bỏ lọt dòng null `category_id` (fallback tên — R7) |
| Chỉ đọc — không làm hỏng dữ liệu | ✅ | Không method ghi, không đổi bất kỳ `Transaction`; mọi tổ hợp không tạo/mất/sửa giao dịch (SC-010) |
| Khóa app không lộ số tiền | ✅ | Màn lọc là route trong shell sau boot-gate (PBI 3) — không làm thêm |
| Cập nhật wiki | ⚠️ | PBI 12 chạm nghiệp vụ đọc-lọc giao dịch — sau khi implement xong sync wiki (entity/concept) qua skill `sora-wiki` + `log.md` |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── core/
│   │   ├── transaction/
│   │   │   ├── transaction_filter.dart          # [TẠO] thuần: enum TxnTypeFilter/SortOption/DatePreset,
│   │   │   │                                     #        class TxnSearchFilter (defaults/reset/preset→khoảng),
│   │   │   │                                     #        normalizeSearch (bỏ dấu tiếng Việt),
│   │   │   │                                     #        filterTransactions (AND + parent gộp con + fallback
│   │   │   │                                     #        tên + group-keep transfer), FilteredTxSummary,
│   │   │   │                                     #        sort date-newest/oldest (group) vs amount (flat)
│   │   │   └── transaction_controller.dart      # [SỬA] + activeFilter Rxn<TxnSearchFilter?>, filtered
│   │   │                                         #        Rxn<FilteredTxView?>, cache _all/_names/now,
│   │   │                                         #        setFilter/clearFilter; load() dựng thêm view lọc
│   │   └── ... (money_format/date_label/widgets giữ nguyên)
│   ├── screens/
│   │   ├── search_filter_screen.dart            # [TẠO] Stateful (R6/R10/R11): màn con `05` toàn màn hình —
│   │   │                                         #        Scaffold riêng app bar teal: back + ô tìm pill (controller
│   │   │                                         #        text, debounce 250ms); chip loại cuộn ngang 4 nút; nhãn
│   │   │                                         #        "BỘ LỌC NÂNG CAO"; 5 dòng nâng cao (Khoảng thời gian /
│   │   │                                         #        Danh mục multi-chip + "+ Thêm" / Ví / Khoảng số tiền Từ–Đến /
│   │   │                                         #        Sắp xếp theo) — mỗi dòng icon + nhãn + value + chevron,
│   │   │                                         #        chạm mở bottom sheet (pattern PBI 8); dòng tóm tắt
│   │   │                                         #        "N kết quả · Tổng: X đ" live; bottom bar Đặt lại/Áp dụng
│   │   │                                         #        (SubPageScaffold.bottomNavigationBar, không cắt SC-011);
│   │   │                                         #        repository inject + now; sheet con: date preset,
│   │   │                                         #        category multi-select theo loại chip, wallet đơn,
│   │   │                                         #        amount nhập dùng AmountKeypad, sort single; validation
│   │   │                                         #        min>max chặn Áp dụng; Áp dụng pop(filter), back pop(null)
│   │   └── transaction_screen.dart               # [SỬA] Stateless giữ: icon lọc await push SearchFilterScreen →
│   │                                              #        setFilter(f); Obx nhánh: activeFilter!=null → thanh chỉ báo
│   │                                              #        (ẩn card tháng) + grouped (date sort) hoặc flat (amount sort)
│   │                                              #        + empty-khớp; null → nhánh cũ; Bỏ lọc → clearFilter
│   └── data/wallet_repository* / db/app_database # KHÔNG ĐỔI (chỉ đọc, schema v4)
└── test/
    ├── fakes/fake_wallet_repository.dart         # KHÔNG ĐỔI (đủ methods; chỉ thêm seed dữ liệu theo từng case)
    ├── transaction_filter_test.dart               # [TẠO] unit thuần: normalize bỏ dấu (an uong↔Ăn uống), khớp
    │                                                #        note/category/tags, chip loại, AND nhiều tiêu chí,
    │                                                #        parent gộp con + fallback tên (null category_id), group-keep
    │                                                #        transfer khi lọc ví, preset date (today/week/month/all,
    │                                                #        chặn custom), abs bao biên & trống một đầu & min>max vô
    │                                                #        hiệu, sort date-newest/oldest (nhóm) & amount (phẳng, tie),
    │                                                #        summary count/total (transfer/adjust trong N ngoài Tổng)
    ├── search_filter_screen_test.dart             # [TẠO] widget fake repo: bố cục mockup `05` (app bar + ô tìm pill +
    │                                                #        back, 4 chip Tất cả chọn, nhãn BỘ LỌC NÂNG CAO, 5 dòng,
    │                                                #        tóm tắt, Đặt lại/Áp dụng); gõ từ khóa → summary live (pump
    │                                                #        debounce); chip Chi/Thu/Chuyển khoản → summary + danh mục
    │                                                #        nguồn đổi; picker danh mục multi + parent; sheet ví; amount
    │                                                #        sheet (trống đầu / min>max chặn Áp dụng); date preset; Đặt
    │                                                #        lại về mặc định; Áp dụng pop(filter) / back pop(null); cỡ
    │                                                #        chữ lớn + safe area cuộn hết không overflow
    ├── transaction_controller_filter_test.dart    # [TẠO] setFilter/clearFilter trên cache; persist qua load() lặp;
    │                                                #        filter giữ nguyên qua setFilter rồi add giao dịch mới
    ├── transaction_screen_test.dart               # [SỬA] (d): icon lọc mở màn lọc thay vì no-op; + nhóm mới: áp dụng
    │                                                #        filter → thanh chỉ báo thay card tháng, list tập khớp; sort
    │                                                #        tiền → phẳng; Bỏ lọc → về toàn bộ; 0 kết quả → empty khớp
    ├── transaction_controller_test / transaction_* # chạy lại — không hồi quy (đường dữ liệu data giữ nguyên)
    ├── widget_test.dart                            # chạy lại — không hồi quy (nếu kỳ vọng no-op icon thì sửa)
    └── (không đổi) money_format / date_label / add_form / category_* / dao
```

Không đổi: `wallet_*` screens/controller, màn PIN/boot, `transaction_list.dart`/`transaction_detail.dart`/`transaction_detail_screen.dart`, `add_transaction_screen.dart`, `category_picker_screen.dart`, `app_shell.dart`, `app_database.dart` (+`.g.dart`), `wallet_repository*`, `fake_wallet_repository.dart`.

## Rủi ro & ngoại lệ có lý do

- **Lọc trên toàn bộ tập (không phân trang SQL)** — cố ý: giữ bất biến gộp transfer & summary AND dễ đúng; DB local một người dùng, vài nghìn dòng đọc nhanh. Ceiling đã có sẵn (`ponytail:` `transaction_list.dart`): nếu vượt ~vài chục nghìn gây giật → chuyển fetch theo nhóm/điều kiện (R1).
- **Sắp tiền phẳng ≠ nhóm ngày mặc định** — user chốt (R4). Đây là nhánh hiển thị riêng trong màn Giao dịch; nhánh không-lọc & sort-ngày giữ nguyên mockup 01 (không hồi quy).
- **Hai nguồn khớp danh mục (`category_id` + fallback text tên)** — cố ý (R7): dòng lịch sử null id vẫn lọc được theo tên. Nguy cơ lệch khi module Danh mục đổi tên sau → fallback chỉ để giữ lịch sử, màn đọc tương lai đổi join. Không phải rào cản PBI 12.
- **Transfer gộp 1 dòng khi lọc Ví** — xử lý bằng group-keep (R2); cần test kỹ trường hợp chọn ví nguồn/đích để không ra 2 dòng hay vế lẻ.
- **`adjustment` không có chip riêng** (chỉ trong "Tất cả") — bám mockup 4 chip; FR/adjustment niche. Ghi rõ trong data-model để QA không ngạc nhiên.
- **Hồi quy có chủ đích icon lọc (PBI 9)** — no-op → mở màn lọc thật; cập nhật kỳ vọng test (d) & widget_test (nếu có). Các nhánh hiển thị không-lọc giữ nguyên để test cũ không đổi.
- **Màn danh sách khi đang lọc ẩn card "Thu/Chi tháng này"** — user chốt (R5); trạng thái không-lọc vẫn hiện card → không phá SC/card cũ.
- **iOS chưa verify** (máy Windows): widget thuần + không đổi plugin/native — rủi ro thấp, giữ trạng thái.
- **Debounce + Timer trong test widget** — phải `pump(Duration)` đủ 250ms và hủy Timer khi dispose để test không treo; đã tính trong thiết kế (R9).

## File đã tạo

- `.specify/specs/12/research.md`
- `.specify/specs/12/data-model.md`
- `.specify/specs/12/plan.md`
- `.specify/specs/12/quickstart.md`

Bước tiếp theo: chạy `/sora-task 12` để phân rã thành tasks.md.
