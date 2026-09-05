# Kế hoạch triển khai: Màn hình chi tiết giao dịch

**Mã PBI**: 10
**Liên kết spec**: .specify/specs/10/spec.md
**Ngày tạo**: 2026-09-05

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12.x / Flutter stable (máy Windows — theo PBI 1–9) |
| Framework / Thư viện chính | Flutter Material; GetX state cho màn danh sách (giữ nguyên); màn detail **Stateful + seam** bám `WalletDetailScreen` (research R10); `SubPageScaffold` (mở rộng `actions`), token `AppColors`, `formatMoney/formatSignedMoney`, `categoryGlyph`, `TxnRow`/`DayGroup` |
| Lưu trữ dữ liệu | **drift `^2.34.4`, schema v2 → v3**: bảng `transactions` thêm cột `tags`/`receipt_image`/`location` (text, default `''`) + domain `Transaction` 3 field + `build_runner` tái sinh `.g.dart` (research R3) |
| Kiểm thử | `flutter analyze` sạch + `flutter test`: unit thuần (detail builder: transfer 2 ví/không dấu, adjustment trung tính, parseTags, ẩn hàng rỗng, cha·con bằng chuỗi ghép, format ngày giờ `·`), widget detail (seam bơm view: khối tóm tắt màu/dấu theo loại, hàng Ví/Ngày giờ/ghi chú/tag/ảnh/vị trí có-điều-kiện, cỡ chữ lớn + safe area), cập nhật widget danh sách (chạm dòng → mở detail), DAO drift memory (map cột mới, skip-guard) |
| Nền tảng triển khai | Android (kiểm chứng chính); iOS widget thuần — rủi ro thấp, verify khi có máy macOS |
| Ràng buộc hiệu năng | SC-001: mở chi tiết hiển thị đầy đủ ≤1s với 1.000 giao dịch → đọc `allTransactions` 1 lần local + build view trong bộ nhớ (R1/R9) |
| Ràng buộc khác | App offline; màn chỉ sau mở khóa (PBI 3 — không làm thêm). Design system: teal `#0F6E56` (thu/hành động chính), coral `#D85A30` (chỉ chi/cảnh báo), transfer/điều chỉnh **trung tính**; mockup `04-chi-tiet-giao-dich.svg`; sub-page có back không bottom nav; Sửa/Nhân bản/3 chấm là điểm vào no-op (màn đích PBI sau — FR-012); tài liệu & commit tiếng Việt có dấu |

*Không còn mục `NEEDS CLARIFICATION` — giải quyết toàn bộ ở research R1–R10.*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md`. Đối chiếu `CLAUDE.md` + design system + wiki [[Giao dịch]]/[[Nguyên tắc nghiệp vụ]]/[[Stack kỹ thuật]]:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không đăng nhập/server | ✅ | Đọc drift SQLite local; không gọi mạng |
| Đúng stack đã chốt (drift + GetX) | ✅ | Không thêm dependency; màn detail tái dùng pattern Stateful+seam có sẵn (không phình thêm controller GetX cho 1 lần đọc — R10) |
| Số dư ví là đại lượng suy ra | ✅ | Thuần đọc giao dịch; không chạm `balance` |
| Transfer không phải thu/chi, không vào báo cáo | ✅ | Trình bày 1 màn trung tính, 2 hàng ví nguồn/đích; không màu thu/chi (FR-004/006) |
| "Ẩn giữ lịch sử & báo cáo" (danh mục/ví ẩn) | ✅ | Hiển thị chuỗi `category` + tên ví đã lưu kể cả khi ẩn (FR-011, edge) |
| Mỗi PBI = một màn; điểm vào chưa kích hoạt luồng sâu | ✅ | Sửa/Nhân bản/3 chấm hiển thị đúng mockup, chạm no-op không lỗi/treo (FR-012) — màn đích (thêm/sửa giao dịch) là PBI sau |
| Design system (teal/coral/trung tính, bo 8/10, `đ`, token, không hex cứng) | ✅ | Tái dùng `AppColors`; thu teal `+`, chi coral `−`, transfer/điều chỉnh trung tính không dấu; thumbnail bo 8; nút chính bo 8 cao 44 |
| "Cấm số liệu minh họa giả" | ⚠️ | Dữ liệu = bộ seed đã có (11 dòng PBI 6/8) + **làm giàu trường tùy chọn (tags/location)** cho 1 dòng mẫu khớp mockup để QA (R3); seed demo vẫn còn tới khi module Giao dịch có luồng xóa + dữ liệu thật (quyết định mở #1) |
| Tái dùng hơn viết mới | ✅ | `WalletRepository.allTransactions/loadAll`, `Transaction`, `categoryGlyph`, `formatSignedMoney`, `SubPageScaffold`, `AppColors`, pattern seam test |
| Test không phụ thuộc sqlite native | ✅ | Unit/widget chạy fake/seam; DAO tích hợp skip-guard |
| Tài liệu & commit tiếng Việt có dấu | ✅ | Toàn bộ file tiếng Việt |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Quyết định chính:

- **Nguồn dữ liệu detail: nạp lại mỗi lần mở** qua `allTransactions()` + `loadAll()` rồi hàm thuần chọn theo ref — đáp ứng FR-010 (R1).
- **Ref mở màn từ danh sách**: mở rộng `TxnRow` bằng `detailTransactionId`/`detailGroupId` (đúng 1 cái khác null); dòng chạm → push `TransactionDetailScreen`; quay lại giữ nguyên vị trí cuộn (R2).
- **Bump schema drift v3** — thêm cột `tags`/`receipt_image`/`location` + domain + migration + seed làm giàu row 1 (tags/location text); `receipt_image` để trống, verify bằng widget test (R3 — do người dùng chốt).
- **`tags` lưu chuỗi phân tách phẩy không `#`**, hiển thị chip `#tag` qua `parseTags` (R4).
- **Màu/dấu/khối tóm tắt bám PBI 9 + mockup**: thu teal `+`, chi coral `−`, transfer/adjustment trung tính không dấu; nhãn danh mục hiển thị đúng chuỗi `category` lưu — cha·con hiện khi dữ liệu mang chuỗi ` · ` (R5).
- **Khung màn**: `SubPageScaffold` mở rộng `actions` (icon 3 chấm) + `bottomNavigationBar` (2 nút Nhân bản phụ/Sửa chính, no-op) (R6).
- **Vùng chi tiết hàng có điều kiện** (Ví hoặc Ví nguồn/đích, Ngày giờ, Ghi chú, Tag, Ảnh hóa đơn, Vị trí), ngăn kẻ mảnh (R7); định dạng ngày giờ `'dd/MM/yyyy · HH:mm'` hàm mới (R8).
- **Không thêm method repository** — tận dụng `allTransactions`/`loadAll` (R9); màn detail Stateful + seam, không phình GetX (R10).

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — schema v3 thêm 3 cột tùy chọn + domain 3 field; view hiển thị dựng bởi `transaction_detail.dart`.
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app nội bộ offline, không API/CLI (bám PBI 7/8/9).
- **Kịch bản khởi động nhanh**: xem `quickstart.md` — nhóm QA A–H đối chiếu acceptance/FR/SC; QA tay emulator (cần `flutter pub run build_runner` để regen `.g.dart` trước).

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Không phình layer nghiệp vụ | ✅ | Thêm đúng file view-model thuần `transaction_detail.dart` + 1 màn + vài hàm nhỏ; không service/event bus dư |
| Đúng seam cho module Giao dịch sau | ✅ | Chỉ đọc + trình bày; **chưa** sửa/xóa/nhân bản; 3 điểm vào no-op. Schema v3 bổ sung cột đúng mô hình chuẩn docs — sẵn sàng cho màn thêm/sửa (PBI sau) ghi |
| Transfer không lệch 2 vế | ✅ | Màn chi tiết tìm đủ 2 vế theo `transfer_group_id`; nhóm thiếu vế → fallback đơn, không crash |
| Không hồi quy PBI 6/8/9 | ⚠️ | Thay đổi **có chủ đích**: (1) domain `Transaction` + 3 field default `''` (additive); (2) `TxnRow` + 2 field ref; (3) dòng danh sách từ no-op → **mở màn detail** (điểm vào PBI 9 thành chủ động — phải cập nhật kỳ vọng widget test PBI 9); (4) seed row 1 thêm tags/location (không đổi category/note/giá trị — test số lượng/tổng giữ nguyên). Chạy lại toàn bộ test cũ xác minh |
| Reuse > viết mới | ✅ | Không thêm lib; tái dùng formatter/`_toTransaction`/`SubPageScaffold`/pattern fake + seam; chỉ thêm `parseTags`/`formatDateTimeDetailLabel`/`buildTransactionDetail` |
| Fake repo luôn chạy mọi test màn/controller | ✅ | Field mới default `''`; fake seed từ `TransactionSource.all()` tự mang tags/location row 1 |
| Không đổi hành vi `performTransfer` | ✅ | 3 cột mới default `''` — `TransactionsCompanion.insert` hiện có không cần sửa |
| Khóa app không lộ số tiền | ✅ | Detail là route trong app sau boot-gate (PBI 3) — không làm thêm |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── core/
│   │   ├── transaction/
│   │   │   ├── transaction.dart                  # [SỬA] + tags/receiptImage/location (String, default '')
│   │   │   ├── transaction_list.dart             # [SỬA] TxnRow + detailTransactionId / detailGroupId
│   │   │   │                                     #        (đúng 1 khác null — ref mở màn detail, R2)
│   │   │   ├── transaction_detail.dart           # [TẠO] pure: buildTransactionDetail(all, walletName, ref)
│   │   │   │                                     #        → TransactionDetailView (type/summary/amount/hàng
│   │   │   │                                     #        có điều kiện) + parseTags(tags) (R1/R4/R5/R7)
│   │   │   └── transaction_source.dart           # [SỬA] row 1: tags 'côngty', location '123 Láng Hạ…';
│   │   │                                         #        receiptImage '' (giữ category/note/amount — R3)
│   │   ├── date_label.dart                       # [SỬA] + formatDateTimeDetailLabel → 'dd/MM/yyyy · HH:mm'
│   │   └── widgets/sub_page_scaffold.dart        # [SỬA] + actions (List<Widget>?, default null) — icon 3 chấm
│   ├── data/
│   │   ├── db/app_database.dart                  # [SỬA] + 3 cột Transactions (tags/receipt_image/location,
│   │   │                                         #        default ''), schemaVersion 3, onUpgrade addColumn
│   │   ├── db/app_database.g.dart                # [TÁI SINH] build_runner
│   │   └── wallet_repository_drift.dart          # [SỬA] _toTransaction map 3 field mới
│   ├── screens/
│   │   ├── transaction_detail_screen.dart        # [TẠO] Stateful + seam loader (R10): SubPageScaffold title
│   │   │                                         #        'Chi tiết giao dịch' + actions 3 chấm no-op; body:
│   │   │                                         #        khối tóm tắt + ListView hàng chi tiết có điều kiện
│   │   │                                         #        (Ví/Ví nguồn-đích, Ngày giờ, Ghi chú, Tag chip,
│   │   │                                         #        Ảnh thumbnail, Vị trí); bottom 2 nút Nhân bản/Sửa
│   │   │                                         #        no-op (FR-012); loading/lỗi+Thử lại
│   │   └── transaction_screen.dart               # [SỬA] _TransactionRow.onTap → push TransactionDetailScreen
│   │                                             #        (bỏ no-op cũ); truyền ref từ TxnRow (R2)
│   └── (khác giữ nguyên)
└── test/
    ├── fakes/fake_wallet_repository.dart         # [SỬA] không bắt buộc (field default); giữ khớp seed
    ├── transaction_detail_test.dart              # [TẠO] unit pure: build theo ref (id / group), transfer
    │                                              #        2 ví + không dấu, adjustment trung tính, cha·con
    │                                              #        từ chuỗi ' · ', ẩn hàng rỗng (note/tag/ảnh/vị trí),
    │                                              #        parseTags, không tìm thấy → null
    ├── transaction_screen_test.dart              # [SỬA] dòng chạm → mở màn detail (thay no-op); giữ case khác
    ├── transaction_detail_screen_test.dart        # [TẠO] widget seam: summary màu/dấu theo loại (thu teal +,
    │                                              #        chi coral −, transfer/adjust trung tính không dấu),
    │                                              #        hàng Ví/Ngày giờ 'dd/MM/yyyy · HH:mm', ghi chú gói
    │                                              #        dòng, tag chip #, ảnh thumbnail (path giả), vị trí,
    │                                              #        không-dữ-liệu → ẩn hàng không dòng trống, 3 chấm +
    │                                              #        2 nút chạm không crash, back về danh sách, cỡ chữ
    │                                              #        lớn + safe area cuộn không vỡ, số tiền lớn không tràn
    ├── date_label_test.dart                      # [SỬA] + formatDateTimeDetailLabel
    ├── transactions_dao_test.dart                # [SỬA] + map 3 cột mới (row 1 tags/location); schema v3
    └── widget_test.dart / wallet_*_test / PBI9    # chạy lại — không hồi quy (domain/seed additive)
```

Không đổi: `wallet_*` screens, màn main, PIN/boot, `AppShell` (trừ list PBI 9 đã có), `transaction_controller.dart`, `wallet_repository.dart` (interface), `wallet_deps.dart` (đã có `ensureWalletRepository`).

## Rủi ro & ngoại lệ có lý do

- **"Cha · con" chưa verify bằng data thật (acceptance 5)** — chưa có bảng `categories`/producer (quyết định mở #1): summary hiển thị **đúng chuỗi `category` lưu**; seed hiện chỉ tên cha (`'Ăn uống'`). Acceptance-5 được phủ bằng **unit/widget test với `Transaction` ghép chuỗi `'Ăn uống · Ăn ngoài'`**; khi module Danh mục lưu/join đường dẫn thì màn tự đúng, không đổi logic (R5). Nêu rõ trong quickstart để QA biết hàng tên danh mục trên emulator là `'Ăn uống'`.
- **Schema v3 + migration** — cần chạy `build_runner` tái sinh `.g.dart`; onUpgrade phải `addColumn` có default để không mất dữ liệu. QA trước khi chạy build phải regen; test DAO skip-guard khi host thiếu sqlite.
- **`receipt_image` trống mọi dòng seed (R3)** — chưa có producer/ảnh thật: hàng "Ảnh hóa đơn" không xuất hiện trên emulator (đúng rule ẩn-hàng-khi-rỗng); logic hiển thị ảnh được verify bằng widget test bơm `Transaction` có `receiptImage` path giả (`Image.file` + `errorBuilder` placeholder, không crash). Khi PBI thêm/sửa giao dịch cấp đường dẫn ảnh thật, hàng tự hiển thị.
- **Dữ liệu demo seed vẫn còn (quyết định mở #1)** — PBI 10 không thêm dòng mới, chỉ làm giàu trường tùy chọn 1 dòng để QA mockup; gỡ cùng luồng xóa + dữ liệu thật của module Giao dịch. QA phụ thuộc ngày chạy (ngày tương đối) — nêu rõ quickstart.
- **Hồi quy có chủ đích ở PBI 9** — dòng danh sách đổi từ no-op → mở màn detail; widget test PBI 9 phải cập nhật kỳ vọng case chạm dòng (không phải bug). Test số lượng/tổng giữ nguyên vì không đổi category/note/giá trị seed.
- **iOS chưa verify** (máy Windows): widget thuần + drift có plugin native — rủi ro thấp, giữ trạng thái.
- **`sqlite3.dll` host Windows** — unit/widget chạy fake/seam; DAO `NativeDatabase.memory()` skip-guard + QA emulator (như PBI 7/8/9).

## File đã tạo

- `.specify/specs/10/research.md`
- `.specify/specs/10/data-model.md`
- `.specify/specs/10/plan.md`
- `.specify/specs/10/quickstart.md`

Bước tiếp theo: chạy `/sora-task 10` để phân rã thành tasks.md.
