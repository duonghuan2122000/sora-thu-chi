# Kế hoạch triển khai: Màn hình danh sách giao dịch

**Mã PBI**: 9
**Liên kết spec**: .specify/specs/9/spec.md
**Ngày tạo**: 2026-09-05

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12.x / Flutter stable (máy Windows — theo PBI 1–8) |
| Framework / Thư viện chính | Flutter Material; **GetX** state (GetView/Obx, pattern PBI 7); `ScreenHeader` (màn main) + token `AppColors`; `formatAmount/formatSignedMoney`; shell bottom nav + FAB (PBI 2) |
| Lưu trữ dữ liệu | **drift `^2.34.4` (schema v2, bảng `transactions` 8 cột PBI 8)**: PBI 9 **không đổi schema** — chỉ thêm đọc `allTransactions()` + map `transfer_group_id` lên domain. Card tháng/nhóm ngày tính trong bộ nhớ từ cùng bộ dữ liệu |
| Kiểm thử | `flutter analyze` sạch + `flutter test`: unit thuần (group/ghép transfer/thống kê/label — inject `now`), controller & widget qua `FakeWalletRepository` (mở rộng: `allTransactions` + tự gán `transferGroupId`), DAO drift `NativeDatabase.memory()` (map group, skip-guard); QA emulator theo `quickstart.md` |
| Nền tảng triển khai | Android (kiểm chứng chính); iOS widget thuần — rủi ro thấp, verify khi có máy macOS |
| Ràng buộc hiệu năng | SC-001: tab hiển thị đầy đủ ≤1s với 1.000 giao dịch; SC-007 cuộn mượt nhiều nghìn dòng → đọc 1 lần local + build lười (R4) |
| Ràng buộc khác | App offline; màn chỉ sau mở khóa (PBI 3 — không làm thêm); main tab (có bottom nav/FAB). Design system: teal `#0F6E56` (thu/hành động chính), coral `#D85A30` (chỉ chi/cảnh báo), chuyển khoản/điều chỉnh **trung tính**; card bo 10; `đ` định dạng; không hex cứng trong widget; tài liệu & commit tiếng Việt có dấu |

*Không còn mục `NEEDS CLARIFICATION` — giải quyết toàn bộ ở research R1–R10.*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md`. Đối chiếu `CLAUDE.md` + design system + wiki [[Giao dịch]]/[[Nguyên tắc nghiệp vụ]]/[[Stack kỹ thuật]]:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không đăng nhập/server | ✅ | Đọc drift SQLite local; không gọi mạng |
| Đúng stack đã chốt (drift + GetX) | ✅ | Không thêm dependency; đọc qua seam `WalletRepository` đã có |
| Số dư ví là đại lượng suy ra | ✅ | Không chạm `balance`/ghi ví; màn này thuần đọc giao dịch |
| Transfer không phải thu/chi, không vào báo cáo | ✅ | Hiển thị 1 dòng trung tính; loại khỏi card tháng bằng `type` (FR-003/007/008) |
| "Ẩn giữ lịch sử & báo cáo" (gồm ví ẩn) | ✅ | Đọc mọi ví kể cả ẩn; tên ví/danh mục hiển thị đủ (edge spec) |
| Mỗi PBI = một màn; điểm vào chưa kích hoạt luồng sâu | ✅ | FAB/icon lọc/chạm dòng no-op không lỗi (FR-014) — màn đích là PBI riêng |
| Design system (teal/coral/trung tính, bo 10, `đ`, token, không hex cứng) | ✅ | Tái dùng `AppColors`; thu teal `+`, chi coral `−`, transfer/điều chỉnh trung tính không dấu |
| "Cấm số liệu minh họa giả" | ⚠️ | Dữ liệu là **bộ mẫu seed đã có sẵn từ PBI 6/8** (11 dòng), không thêm seed mới; vẫn còn tới khi PBI Giao dịch có luồng xóa + dữ liệu thật (quyết định mở #1) |
| Tái dùng hơn viết mới | ✅ | `WalletRepository`, `Transaction`, `sortNewestFirst`, `formatSignedMoney`, `ScreenHeader`, `AppColors`, pattern controller/deps/fake PBI 7/8 |
| Test không phụ thuộc sqlite native | ✅ | Màn/controller chạy fake; DAO tích hợp skip-guard |
| Tài liệu & commit tiếng Việt có dấu | ✅ | Toàn bộ file tiếng Việt |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Quyết định chính:

- **Đọc `allTransactions()` mọi ví kể cả ẩn**, domain `Transaction` thêm `transferGroupId` nullable để ghép cặp transfer (R1).
- **Gộp 2 bút toán transfer → 1 dòng** bằng hàm thuần: nguồn = vế âm, đích = vế dương, hiển thị `|x|` trung tính không dấu (R2); card tháng & nhóm ngày là hàm thuần trên cùng bộ dữ liệu, inject `now` (R3).
- **Không fetch phân trang SQL**: đọc 1 lần local + `ListView.builder` build lười + `PageStorageKey` — thoả SC-001/007 và *đảm bảo* "không trùng/bỏ sót" FR-012 (R4, có `ponytail:` ceiling).
- **Icon bubble dùng glyph mặc định tạm** (danh mục chỉ là chữ, chưa có icon/màu): thu/chi nền `tealLightBg` teal, transfer/điều chỉnh `softCardBg` trung tính — bám mockup SVG; gỡ khi bảng `categories` đến (R5).
- **Làm mới FR-011 bằng nạp lại khi chọn tab** trong `AppShell`; không nạp trong `initState` (IndexedStack build sẵn 4 màn từ boot) (R6).
- **Dùng chung 1 drift DB/repository** giữa `WalletController` và `TransactionController` qua `ensureWalletRepository()` singleton (R7).

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — **không đổi schema**; domain `Transaction` + `transferGroupId`; view hiển thị (card tháng + nhóm ngày + bất biến 1-dòng-transfer).
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app nội bộ offline, không API/CLI (bám PBI 7/8).
- **Kịch bản khởi động nhanh**: xem `quickstart.md` — nhóm QA A–G đối chiếu acceptance/FR/SC kèm bảng đối chiếu 11 dòng seed; QA tay emulator.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Không phình layer nghiệp vụ | ✅ | Thêm đúng 1 view-model thuần + 1 controller + vài hàm nhỏ; không service/event bus dư |
| Đúng seam cho module Giao dịch sau | ⚠️ | PBI 9 **chạm một phần** module Giao dịch: đọc toàn bộ giao dịch + gộp cặp transfer. Giới hạn rõ: không sửa/xóa/thêm giao dịch, không chạm bảng; icon danh mục là glyph tạm chờ bảng `categories` |
| Transfer không lệch 2 vế / không thành 2 dòng | ✅ | Ghép bằng `transferGroupId` + bất biến "âm = nguồn" của PBI 8; test phủ (kể cả vế lẻ fallback) |
| Không hồi quy màn ví / detail / transfer | ✅ | Chỉ thêm field domain (default null); detail giữ 2 dòng transfer đúng ngữ cảnh ví; deps chuyển sang repo singleton — test PBI 6/7/8 chạy lại xanh |
| Reuse > viết mới | ✅ | Không thêm lib; tái dùng formatter/`sortNewestFirst`/`ScreenHeader`/pattern fake; chỉ thêm `formatDayGroupHeader` |
| Fake repo luôn chạy mọi test màn/controller | ✅ | Mở rộng fake (`allTransactions` + gán group khi seed/transfer); drift DAO test skip-guard |
| Màn chính build sẵn (IndexedStack) không phình boot | ✅ | Không nạp DB ở `initState`; nạp khi chọn tab Giao dịch (R6) |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── core/
│   │   ├── transaction/
│   │   │   ├── transaction.dart                  # [SỬA] + transferGroupId (int?) — additive, map từ drift
│   │   │   ├── transaction_list.dart             # [TẠO] hàm thuần: ghép cặp transfer → dòng hiển thị,
│   │   │   │                                     #        build DayGroup (nhóm ngày + header), MonthStat;
│   │   │   │                                     #        categoryGlyph(name) tạm (R5)
│   │   │   ├── transaction_controller.dart       # [TẠO] GetX: load() đọc repo.allTransactions + wallets
│   │   │   │                                     #        (qua WalletController/loadAll), sinh DayGroups +
│   │   │   │                                     #        MonthStat; RxList/Rx state; error + retry (R8)
│   │   │   └── transaction_source.dart           # giữ nguyên (group do seed DB/fake tự gán)
│   │   ├── date_label.dart                       # [SỬA] + formatDayGroupHeader(date, {now}) → 'HÔM NAY - dd/MM/yyyy'
│   │   │                                         #        | 'HÔM QUA - …' | 'dd/MM/yyyy' (FR-005)
│   │   └── widgets/screen_header.dart            # [SỬA] + param tuỳ chọn centerTitle (mặc định false),
│   │                                             #        trailing (Widget? null) — giữ layout 4 màn cũ (R9)
│   ├── data/
│   │   ├── wallet_repository.dart                # [SỬA] interface + allTransactions()
│   │   ├── wallet_repository_drift.dart          # [SỬA] impl: select toàn bộ rows (mọi ví), map
│   │   │                                         #        transfer_group_id vào Transaction
│   │   ├── wallet_deps.dart                      # [SỬA] + ensureWalletRepository() (singleton drift);
│   │   │                                         #        ensureWalletController dùng chung repo (R7)
│   │   └── transaction_deps.dart                 # [TẠO] ensureTransactionController(): Get.put(
│   │                                             #        TransactionController(ensureWalletRepository()));
│   │                                             #        init nếu chưa nạp (dùng chung 1 DB — R7)
│   ├── core/wallet/wallet_controller.dart        # giữ nguyên (transfer đã reload cache ví)
│   ├── screens/
│   │   ├── transaction_screen.dart               # [VIẾT LẠI] màn Giao dịch thật: Obx theo controller;
│   │   │                                         #        ScreenHeader 'Giao dịch' centerTitle + trailing icon
│   │   │                                         #        lọc (no-op FR-014); card thống kê 2 khối; danh sách
│   │   │                                         #        nhóm ngày (ListView.builder + PageStorageKey, đệm đáy
│   │   │                                         #        chống FAB/nav); empty state hướng dẫn FAB (FR-010);
│   │   │                                         #        lỗi → thông báo + thử lại (R8); dòng chạm no-op;
│   │   │                                         #        số tiền Flexible + scale-down, không ellipsis cắt số (FR-009)
│   │   └── ... (màn khác giữ nguyên)
│   └── core/app_shell.dart                       # [SỬA] onTabSelected: index==1 → ensureTransactionController()
│                                                 #        .load() (fire-and-forget — R6/FR-011)
└── test/
    ├── fakes/fake_wallet_repository.dart         # [SỬA] + allTransactions(); seed & performTransfer gán
    │                                              #        transferGroupId 2 vế (giống DB seed)
    ├── transaction_list_test.dart                 # [TẠO] unit thuần: ghép transfer (1 dòng/nguồn-đích/không
    │                                              #        dấu/vế lẻ), nhóm ngày + header, MonthStat (bỏ
    │                                              #        transfer/adjustment; tương lai cùng tháng không tính;
    │                                              #        ví ẩn vẫn tính), thứ tự ổn định trùng giờ
    ├── date_label_test.dart                       # [SỬA] + formatDayGroupHeader (HÔM NAY/HÔM QUA/dd/MM/yyyy)
    ├── transaction_controller_test.dart           # [TẠO] controller fake: load → DayGroups+MonthStat đúng;
    │                                              #        reload sau khi fake.performTransfer phản ánh (FR-011);
    │                                              #        lỗi repo → trạng thái lỗi + retry
    ├── transaction_screen_test.dart               # [TẠO] widget: render header/card/danh sách theo seed;
    │                                              #        màu+dấu thu/chi, transfer 1 dòng trung tính; card số
    │                                              #        đúng; empty state '0 đ'; chạm FAB/filter/dòng không
    │                                              #        crash; ví ẩn vẫn hiện; cỡ chữ lớn + safe area cuộn
    │                                              #        không vỡ; số tiền rất lớn hiển thị đủ không tràn
    ├── transactions_dao_test.dart                 # [SỬA] + drift NativeDatabase.memory(): allTransactions trả
    │                                              #        11 dòng, cặp transfer cùng transferGroupId
    ├── widget_test.dart / wallet_*_test           # giữ nguyên — chạy lại xác minh không hồi quy (deps singleton)
```

Không đổi: `main.dart`, `app.dart`, `boot_gate.dart`, `pin_*`, bottom nav, `wallet_*` screens (trừ test do deps singleton), `settings_screen.dart`, `dashboard_screen.dart`, `report_screen.dart`, `add_transaction_screen.dart`, bảng drift/migration.

## Rủi ro & ngoại lệ có lý do

- **Danh mục chưa có icon/màu (R5)** — `transactions.category` là chữ tạm (schema v2, PBI 8), chưa có bảng `categories`. Bubble thu/chi dùng `tealLightBg`/teal + glyph mặc định tạm (một map pure nhỏ, tầng màn, không phải dữ liệu/DB) để QA đối chiếu mockup (SC-006); màu/icon riêng mỗi danh mục (FR-006) được phục vụ đúng khi module Danh mục cấp dữ liệu — **gỡ map tạm lúc đó** (quyết định mở #1).
- **FR-012 hiểu ở tầng render lười, không fetch phân trang SQL (R4)** — DB local sqlite một người dùng, quy mô thực nghìn dòng: đọc 1 lần nhanh + build lười thoả SC-001/007 và bảo đảm tuyệt đối "không trùng/bỏ sót" (chính là điều FR-012 cấm). Đánh dấu `ponytail:` ceiling — đổi sang fetch theo nhóm ngày khi dữ liệu vượt ~chục nghìn gây giật.
- **Bộ dữ liệu demo seed vẫn còn** — PBI 9 không thêm seed, chỉ đọc 11 dòng mẫu PBI 6/8 đã có; gỡ cùng quyết định mở #1 khi PBI Giao dịch có luồng xóa + dữ liệu thật. QA phụ thuộc ngày chạy (seed dùng ngày tương đối) — nêu rõ trong quickstart.
- **Deps chuyển sang dùng chung 1 repo drift (R7)** — tránh 2 connection drift trên 1 file; đụng `wallet_deps` → chạy lại toàn bộ test ví/controller đảm bảo không hồi quy (fake repo đăng ký trước vẫn ưu tiên).
- **Làm mới gắn với "quay lại tab" (R6)** — thoả FR-011 với luồng ghi hiện có (chuyển tiền PBI 8, qua Cài đặt). Khi PBI thêm/sửa giao dịch đến, luồng mới tự gọi `TransactionController.load()` sau lưu; không cần cơ chế khác.
- **iOS chưa verify** (máy Windows): widget thuần + drift có plugin native — rủi ro thấp, giữ trạng thái.
- **`sqlite3.dll` host Windows** — test màn/controller chạy fake; DAO `NativeDatabase.memory()` skip-guard + QA emulator (như PBI 7/8).

## File đã tạo

- `.specify/specs/9/research.md`
- `.specify/specs/9/data-model.md`
- `.specify/specs/9/quickstart.md`
- `.specify/specs/9/plan.md`

Bước tiếp theo: chạy `/sora-task 9` để phân rã thành tasks.md.
