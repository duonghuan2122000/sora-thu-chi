# Kế hoạch triển khai: Chuyển tiền giữa các ví

**Mã PBI**: 8
**Liên kết spec**: .specify/specs/8/spec.md
**Ngày tạo**: 2026-09-05

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12.x / Flutter stable (máy Windows — theo PBI 1–7) |
| Framework / Thư viện chính | Flutter Material; **GetX** state (`get ^4.7.3`, `WalletController` PBI 7); sub-page `SubPageScaffold`; token `AppColors`; `formatAmount`/`formatMoney` |
| Lưu trữ dữ liệu | **drift `^2.34.4` (đã wire PBI 7)**: thêm bảng `transactions` (schemaVersion 1 → 2). Cột subset theo research R3; seed 11 dòng giao dịch mẫu ở migration/onCreate (R2); Transfer = 2 dòng liên kết `transfer_group_id`, ghi atomic 4 bước trong 1 `db.transaction()` (R1/R4/R7) |
| Kiểm thử | `flutter analyze` sạch + `flutter test`: unit thuần (`transfer_rules`, `parseAmount`, format), controller/repository qua `FakeWalletRepository` (mở rộng — không sqlite native trên host), widget test transfer + detail, DAO drift `NativeDatabase.memory()` (migration v2 + seed + atomic transfer, skip-guard nếu host thiếu sqlite); QA emulator theo `quickstart.md` |
| Nền tảng triển khai | Android (kiểm chứng chính); iOS widget thuần + drift có `sqlite3_flutter_libs` — rủi ro thấp, verify khi có máy macOS |
| Ràng buộc hiệu năng | Không đặc thù; DB nhỏ, mỗi ví đọc 1 lần vào màn chi tiết, ghi 1 transaction ngắn → không cần cache phức tạp |
| Ràng buộc khác | App offline; màn chỉ sau mở khóa (PBI 3 — không làm thêm); sub-page không bottom nav; design system: app bar teal, **1 teal** hành động chính, **coral chỉ chi tiêu/cảnh báo**, transfer màu trung tính (`softCardBg`/`listLabel` — đã có), bo 10 / nút 44 bo 8, `đ` định dạng; không hex cứng; tài liệu & commit tiếng Việt có dấu |

*Không còn mục `NEEDS CLARIFICATION` — đã giải quyết toàn bộ ở research R1–R10.*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md`. Đối chiếu `CLAUDE.md` + design system + wiki [[Ví & Tài khoản]]/[[Giao dịch]]/[[Nguyên tắc nghiệp vụ]]/[[Stack kỹ thuật]]:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không đăng nhập/server | ✅ | drift SQLite local; không gọi mạng |
| Đúng stack đã chốt (drift + GetX) | ✅ | Bảng `transactions` drift (schema 2); orchestrate trong `WalletController`; không thêm dependency (ngày giờ = native picker, phân tách nghìn = hàm thuần) |
| Số dư ví là đại lượng suy ra, không sửa tay | ✅ | Không có luồng "sửa tay số dư"; khoản chuyển thay đổi số dư qua **một sự kiện được bút toán hóa** (2 vế ghi vào `transactions`), đúng rule docs §5. Vẫn giữ cột cache thay vì suy ra — lý do ở R4 + Rủi ro |
| Transfer không phải thu/chi, không vào báo cáo | ✅ | `type=transfer` tách biệt; không gắn danh mục; 2 vế `+x/−x` tự triệt tiêu trong mọi tổng |
| "2 bút toán liên kết đi cùng nhau" (FR-012/015) | ✅ | Một `db.transaction()`; `transfer_group_id` nối 2 vế cho sửa/xóa đồng bộ sau |
| Nguồn ≠ đích, cùng tiền tệ, loại thẻ tín dụng | ✅ | Hàm thuần `transfer_rules.dart` + UI chặn (FR-003/011/018/019) |
| "Ẩn thay vì xóa" & luật ẩn | ✅ | Ví ẩn không vào danh sách chọn đích; nguồn là ví đang xem (kể cả ẩn) vẫn chuyển được — bám spec §Giả định |
| Design system (teal/coral, transfer trung tính, `đ`, token, không hex cứng) | ✅ | Dòng "Số dư sau chuyển"/ô ví tái dùng `formatMoney`; cảnh báo âm dùng `coral` (ngữ cảnh cảnh báo hợp lệ); transfer dùng token trung tính có sẵn |
| "Cấm số liệu minh họa giả" | ⚠️ | Seed 11 dòng giao dịch mẫu vào DB thật (nối PBI 6 + giữ đối chiếu số dư cache) — xem Rủi ro, cùng Quyết định mở #1 như seed ví PBI 7 |
| Tái dùng hơn viết mới | ✅ | `SubPageScaffold`, `AppColors`, `formatAmount/SignedMoney`, `WalletController`, domain `Transaction` + `sortNewestFirst`, mẫu repo/fake PBI 7; không thêm lib |
| Test không phụ thuộc thiết bị/sqlite native | ✅ | Mọi test màn/controller dùng `FakeWalletRepository`; DAO tích hợp `NativeDatabase.memory()` skip-guard |
| Tài liệu & commit tiếng Việt có dấu | ✅ | Toàn bộ file tiếng Việt |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Quyết định chính:

- **Giới thiệu bảng `transactions` ngay (schema 1→2)**, Transfer = **2 dòng liên kết `transfer_group_id`** (vế nguồn `−x`, vế đích `+x`), đúng mô hình docs §4/§7 (R1). Ghi atomic trong 1 `db.transaction()` (R4: đồng thời trừ/cộng `balance` hai ví; R7: group = id vế ghi trước).
- **Seed 11 dòng giao dịch mẫu hiện tại** ở migration/onCreate — giữ liên tục demo PBI 6 và đối chiếu số dư; `TransactionSource` thành hằng seed như `WalletSource` PBI 7 (R2).
- **Bảng subset cột** đủ PBI 8 (`category` chữ tạm, chưa `category_id`/tag/ảnh/location/tỷ giá) — tránh mã chết, migration sang chuẩn khi module Giao dịch đến (R3).
- **Số dư giữ là cột cache**, chưa suy ra từ bảng giao dịch (bộ mẫu không nhất quán) (R4). **Vòng đọc danh sách ví chi tiết chuyển về DB** qua repository (R5).
- **Mở rộng seam `WalletRepository`** (`transactionsOf`, `performTransfer`) + `WalletController.transfer`; Drift & Fake cùng implement (R6).
- **UI**: màn `wallet_transfer_screen.dart` trên `SubPageScaffold` bám mockup `wallet-transfer-screen.svg`; phân tách nghìn sống bằng hàm thuần `parseAmount` + `formatAmount` (R9); nút vô hiệu khi thiếu dữ liệu/đang lưu chống double-tap (R10); chặn credit + báo "chưa có ví đích" theo `transfer_rules.dart` thuần (R8).

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — bảng `transactions` (schema 2, 8 cột), Transfer = 2 dòng + group, bất biến atomic, migration v2.
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app nội bộ offline, không API/CLI (bám PBI 7).
- **Kịch bản khởi động nhanh**: xem `quickstart.md` — nhóm QA A–F đối chiếu acceptance/SC/FR, gồm chống trùng, kiểm bền qua restart, cỡ chữ/safe area, không hồi quy khóa app.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Không phình layer nghiệp vụ | ✅ | Thêm đúng 1 bảng + 1 màn + vài hàm thuần + mở rộng 2 seam đã có; không service/event bus dư |
| Đúng seam cho PBI Giao dịch sau | ⚠️ | PBI 8 **đi trước một phần** module Giao dịch: tạo bảng `transactions` + vòng đọc gần đây của chi tiết ví. Giới hạn: bảng subset, transfer chỉ ghi (không sửa/xóa/undo/danh sách toàn app), 11 dòng mẫu vẫn còn. Cột `category` chữ + seed mẫu sẽ thay khi Giao dịch tới |
| Hai vế transfer đi cùng nhau, không lệch một phía | ✅ | `db.transaction()` (4 ghi) — rollback toàn bộ nếu lỗi; DAO test phủ |
| Không tạo khoản chuyển trùng khi chạm liên tiếp | ✅ | Nút vô hiệu + cờ saving trong lúc ghi |
| Transfer không chạm thu/chi/báo cáo/ngân sách | ✅ | `type=transfer`, báo cáo sau lọc theo type; không thay đổi gì ở các màn tổng hợp hiện tại |
| List/detail ví cũ không vỡ | ⚠️ | Màn chi tiết đổi vòng đọc sang repository → **test PBI 6 phải cập nhật** (default không còn `TransactionSource`; case "Chuyển tiền no-op" thành mở màn/chặn credit). Thay đổi có chủ đích theo spec — giữ bộ mẫu seed nên số liệu QA khớp |
| Reuse > viết mới | ✅ | Như cột "trước thiết kế": không thêm lib, không viết lại formatter/tiền tệ/date label cơ bản (chỉ bổ sung `parseAmount`, `formatDateTimeLabel`) |
| Fake repo luôn chạy mọi test màn/controller | ✅ | Mở rộng `FakeWalletRepository` + 2 method; không sqlite native trong widget/unit |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── data/
│   │   ├── db/
│   │   │   ├── app_database.dart                  # [SỬA] + @Table Transactions (8 cột, index wallet_id);
│   │   │   │                                      #        schemaVersion 2; onUpgrade v1→v2: tạo bảng +
│   │   │   │                                      #        seed 11 giao dịch mẫu (TransactionSource.all());
│   │   │   │                                      #        onCreate: tạo 2 bảng + seed ví + seed giao dịch
│   │   │   └── app_database.g.dart                # [GEN] build_runner (commit)
│   │   ├── wallet_repository.dart                 # [SỬA] interface + transactionsOf(walletId);
│   │   │                                          #        + performTransfer({fromWalletId,toWalletId,
│   │   │                                          #        amount,date,note})
│   │   └── wallet_repository_drift.dart           # [SỬA] Drift impl: transactionsOf (lọc wallet_id, map
│   │                                              #        row→Transaction, sortNewestFirst);
│   │                                              #        performTransfer = db.transaction: trừ balance
│   │                                              #        nguồn, cộng balance đích, insert 2 dòng
│   │                                              #        type=transfer (±amount, cùng date/note, group=
│   │                                              #        id vế trước rồi update lại) (R1/R4/R7)
│   ├── core/
│   │   ├── money_format.dart                      # [SỬA] + parseAmount(String): lọc ký tự số → int (R9)
│   │   ├── date_label.dart                        # [SỬA] + formatDateTimeLabel(DateTime): 'dd/MM/yyyy HH:mm'
│   │   ├── transaction/
│   │   │   ├── transaction.dart                   # giữ nguyên (domain đã đủ: signed amount, type, date)
│   │   │   └── transaction_source.dart            # [SỬA] role → hằng seed 11 dòng mẫu cho migration + fake
│   │   ├── wallet/
│   │   │   ├── transfer_rules.dart                # [TẠO] hàm thuần: eligibleDestinations(wallets, sourceId)
│   │   │   │                                      #        (active, cùng currency, !=credit, !=nguồn);
│   │   │   │                                      #        canTransferFromWallet(w) (chặn credit);
│   │   │   │                                      #        hasEligibleDestination(...) (FR-019)
│   │   │   └── wallet_controller.dart             # [SỬA] + transfer({from,to,amount,date,note}): gọi repo
│   │   │                                          #        .performTransfer rồi _reload() cache (cả 2 ví)
│   │   └── widgets/sub_page_scaffold.dart         # giữ nguyên (đã có bottomNavigationBar nếu cần)
│   └── screens/
│       ├── wallet_transfer_screen.dart            # [TẠO] StatefulWidget trên SubPageScaffold, title "Chuyển
│       │                                          #        tiền giữa ví": ô Từ ví (nạp sẵn, icon+tên+số dư),
│       │                                          #        ô Đến ví (trống "Chọn ví" → modal sheet danh sách
│       │                                          #        đích lọc transfer_rules), nút hoán đổi giữa 2 ô,
│       │                                          #        Số tiền chuyển (live '.', hậu tố 'đ'), Ngày giờ
│       │                                          #        (picker native, default now), Ghi chú (optional),
│       │                                          #        dòng "Số dư sau chuyển" (live, cảnh báo coral khi
│       │                                          #        âm), nút "Xác nhận chuyển tiền" (vô hiệu khi thiếu
│       │                                          #        đích/tiền≤0/đang lưu; lỗi báo đúng trường);
│       │                                          #        thành công → pop true (FR-001…019)
│       └── wallet_detail_screen.dart              # [SỬA] "Chuyển tiền": credit → thông báo không hỗ trợ;
│       │                                          #        không có ví đích hợp lệ → thông báo rõ; ngược lại
│       │                                          #        push WalletTransferScreen. Sau khi trở về (true):
│       │                                          #        wallet từ controller (số dư mới) + nạp lại danh
│       │                                          #        sách giao dịch qua repository (FR-014). Nhận tham số
│       │                                          #        transactions (seam) / WalletController (test)
│       └── wallet_list_screen.dart                # giữ nguyên (đọc WalletController reactive → tự cập nhật)
└── test/
    ├── fakes/fake_wallet_repository.dart          # [SỬA] + lưu list Transaction trong bộ nhớ; implement
    │                                              #        transactionsOf + performTransfer (đổi balance, thêm
    │                                              #        2 vế cùng group); seed 11 mẫu nếu cần khớp detail
    ├── transfer_rules_test.dart                   # [TẠO] unit thuần: filter đích (credit/ẩn/khác tiền tệ/
    │                                              #        trùng nguồn), chặn nguồn credit, chỉ 1 ví / không
    │                                              #        còn đích (acceptance 10, FR-018/019)
    ├── money_format_test.dart                     # [SỬA] + parseAmount (bỏ '.', rỗng→0, âm, rất lớn)
    ├── wallet_transfer_screen_test.dart           # [TẠO] widget: render đúng bố cục/nhãn, chọn đích, hoán
    │                                              #        đổi, preview "Số dư sau chuyển", cảnh báo âm, lỗi
    │                                              #        đúng trường (tiền/ngày), chạm đúp chỉ 1 lần gọi,
    │                                              #        cỡ chữ lớn cuộn được, back không lưu
    ├── wallet_detail_screen_test.dart             # [SỬA] case "Chuyển tiền": chặn credit / mở màn; cập nhật
    │                                              #        số dư & danh sách sau khi trở về; giữ case cũ bơm
    ├── wallet_controller_test.dart                # [SỬA] + group transfer: gọi repo.performTransfer → reload
    │                                              #        cache 2 ví đúng số dư
    ├── transactions_dao_test.dart                 # [TẠO] drift NativeDatabase.memory(): migration v2 + seed
    │                                              #        11 dòng; performTransfer atomic (2 dòng cùng group,
    │                                              #        balance trừ/cộng đúng); rollback khi lỗi giữa chừng;
    │                                              #        skip-guard nếu host thiếu sqlite
    └── wallets_dao_test.dart                      # [SỬA] migration v1→v2 không phá seed ví; số dòng tăng
```

Không đổi: `main.dart`, `app.dart`, `boot_gate.dart`, `pin_*`, shell, `settings_screen.dart`, dashboard/report/transaction screens, `wallet.dart`/`wallet_rules.dart`, `add_transaction_screen.dart`, `device_profile.dart`.

## Rủi ro & ngoại lệ có lý do

- **Seed 11 dòng giao dịch mẫu vào DB thật (R2)** — nguyên tắc "cấm số liệu minh họa" bị gỡ có chủ đích, cùng lý do với seed ví PBI 7: pha hiện tại mọi màn demo, số dư cache khớp Σ mẫu, bỏ seed → "GIAO DỊCH GẦN ĐÂY" rỗng đứng sau số dư 14.800.000 đ, đứt QA. Seed chạy một lần ở migration/onCreate, `category` chữ là tạm. **Gỡ khi PBI Giao dịch có luồng xóa + dữ liệu thật** (Quyết định mở #1).
- **Số dư cột cache thay vì suy ra từ bảng giao dịch (R4)** — lệch "balance = tính toán" một phần: bộ mẫu không nhất quán (Tiền mặt seed balance ≠ Σ mẫu), suy ra sẽ phá số liệu. Đợt này mỗi transfer ghi 2 bút toán nên **có đủ dấu vết**; PBI Giao dịch bật suy ra khi ghi đủ mọi loại. Đánh dấu trong code để không quên.
- **Đi trước một phần module Giao dịch** — PBI 8 tạo bảng `transactions` + đổi vòng đọc chi tiết ví sang DB. Bám schema docs để không đập lại; giới hạn rõ (subset cột, không sửa/xóa/undo/list toàn app) để Giao dịch PBI vẫn là module lớn riêng.
- **Test PBI 6 & fake repo phải cập nhật** — `FakeWalletRepository` thêm 2 method (nếu không test cũ không compile); detail case "Chuyển tiền no-op" → chặn credit/mở màn; default transactions không còn `TransactionSource`. Có chủ đích theo spec; giữ bộ mẫu seed nên số liệu QA khớp.
- **`transfer_group_id` sinh bằng id vế ghi trước (R7)** — 2 insert + 1 update trong cùng transaction; an toàn offline một người dùng. Nếu sau này cần nhóm chuyển rời rạc hơn (đồng bộ nhiều vế) → chuyển sang cột group riêng.
- **Gõ số rất lớn / vượt xa số dư** — phân tách nghìn đọc-xuôi-ngược phải ổn định với `int`; cần giới hạn độ dài hợp lý ở màn để tránh tràn màn hình (SC-002/007), phủ bằng widget test.
- **iOS chưa verify** (máy Windows): widget thuần + drift có plugin native — rủi ro thấp nhưng cần chạy thật trên macOS khi có; giữ trạng thái.
- **`sqlite3.dll` trên host Windows** — mọi test màn/controller chạy fake nên không cần; DAO tích hợp `NativeDatabase.memory()` cần sqlite native → skip-guard + QA emulator (như PBI 7).

## File đã tạo

- `.specify/specs/8/research.md`
- `.specify/specs/8/data-model.md`
- `.specify/specs/8/quickstart.md`
- `.specify/specs/8/plan.md`

Bước tiếp theo: chạy `/sora-task 8` để phân rã thành tasks.md.
