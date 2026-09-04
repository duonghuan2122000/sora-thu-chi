# Kế hoạch triển khai: Màn hình chi tiết ví

**Mã PBI**: 6
**Liên kết spec**: .specify/specs/6/spec.md
**Ngày tạo**: 2026-09-04

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12.x (Flutter stable — máy Windows, theo PBI 1–5) |
| Framework / Thư viện chính | Flutter Material; UI thuần widget + model thuần Dart; **không** controller GetX mới (màn đọc tĩnh); drift đã khai báo nhưng chưa dùng (đợt này không wire — xem `research.md` Q11) |
| Lưu trữ dữ liệu | **Không thêm** — ví từ `WalletSource` (PBI 5, giữ nguyên); giao dịch từ bộ mẫu hằng `TransactionSource.all()/forWallet()` (đúng kiểu PBI 5); không đọc/ghi storage (xem `research.md` Q1/Q2) |
| Kiểm thử | `flutter analyze` sạch + `flutter test` (unit `formatSignedMoney`/`relativeDayLabel`/`transactionsForWallet`/sort; widget test màn chi tiết: hero ví thường / thẻ tín dụng / dòng thu-chi-transfer màu+dấu / ngày thân thiện / empty / ví ẩn mở / cỡ chữ lớn & vùng an toàn / back; **sửa** `wallet_list_screen_test` case "tap hàng không mở" → khẳng định điều hướng sang detail) + QA thủ công emulator theo `quickstart.md` |
| Nền tảng triển khai | Android (kiểm chứng chính); iOS (code thuần widget, rủi ro thấp — verify khi có máy macOS) |
| Ràng buộc hiệu năng | Không đặc thù; danh sách ngắn build tĩnh mỗi lần mở, không cần cache/reactive |
| Ràng buộc khác | App offline; màn chỉ hiển thị sau mở khóa (FR-016 — PBI 3 đã đảm bảo, không làm thêm); sub-page không bottom nav; design system: nền teal luôn chữ trắng, 1 teal hành động, coral **chỉ** chi tiêu/cảnh báo (thu=teal, chi=coral, transfer trung tính — wiki Giao dịch); số tiền căn phải `.` nghìn + `đ`; card bo 10 / nút chính bo 8 cao 44 / nút tròn 48; style tập trung token (widget không hex cứng); tài liệu & commit tiếng Việt có dấu |

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md`. Đối chiếu `CLAUDE.md` + design system + wiki [[Ví & Tài khoản]] / [[Giao dịch]]:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không đăng nhập/server | ✅ | Nguồn ví + giao dịch local (bộ mẫu hằng); không gọi mạng |
| Đúng stack đã chốt | ✅ | Không thêm dependency, không wire drift/GetX mới (research Q11) |
| Design system (nền teal chữ trắng; teal thu / coral chi / transfer trung tính; sub-page teal + back; bo 10; định dạng `đ`) | ✅ | Đối chiếu mockup `wallet-detail-screen.svg`; hero teal → chữ trắng; coral đúng chỗ dòng chi; lệch nhỏ hero thẻ tín dụng chữ trắng (xem Rủi ro) |
| Style tập trung 1 nơi | ✅ | Thêm 1 token `coralLightBg #FAECE7` vào `app_colors.dart`; formatter tiền/ngày thuần tập trung; widget không hex cứng |
| "Cấm số liệu minh họa giả" | ⚠️ | **Ngoại lệ có chủ đích** (nối PBI 5): spec §Thực thể chính/§Giả định/SC-003 **bắt buộc** bộ giao dịch mẫu để kiểm chứng hiển thị (SC-003/004) vì chưa có luồng tạo giao dịch & chưa có DB. Không persona/tên người thật; số liệu rõ là demo |
| Màn ví là sub-page, sau mở khóa | ✅ | Sub-page dùng `SubPageScaffold`; route chi tiết luôn nằm sau PinGate (PBI 3) — FR-016 thỏa sẵn |
| Điểm vào chưa có chức năng = treo, không lỗi | ✅ | 3 hành động nhanh + dòng giao dịch `onPressed/onTap` no-op, không mở màn (FR-007/011) |
| Số dư ví là đại lượng suy ra, không sửa tay | ✅ | Hero đọc `wallet.balance` (nguồn PBI 5); màn chỉ xem, không có nút sửa số dư (FR-004) |
| Tài liệu & commit tiếng Việt có dấu | ✅ | Toàn bộ file tiếng Việt |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Quyết định chính:

- **Nguồn giao dịch = model hằng + `TransactionSource.all()/forWallet()`**, đúng pattern PBI 5; screen nhận `List<Transaction>` qua constructor (Q1).
- **`Transaction` signed `amount`** (tác động ròng lên ví chứa dòng) + `TxnType income/expense/transfer/adjustment`; transfer = 2 dòng thuộc 2 ví (Q2).
- **`formatSignedMoney`** (`+`/`-` + `.` nghìn + `đ`, `core/money_format.dart`) và **`relativeDayLabel`** (`'Hôm nay'/'Hôm qua'/'dd/MM'`, `core/date_label.dart`) — 2 hàm thuần, không thêm `intl` (Q3/Q4).
- **Bố cục**: tái dùng `SubPageScaffold(title: wallet.name)`; body = một scroll duy nhất (hero teal nối app bar + 3 nút hành động + tiêu đề nhóm + danh sách/empty) — an toàn cỡ chữ/vùng an toàn (Q5).
- **Hành động nhanh** = 3 cột tròn teal nhạt, Material icon line, `onPressed {}` (Q6); **hero** = icon + `formatMoney(balance)` trắng lớn + `typeLabel`; thẻ tín dụng → `creditUsageLabel` + phần trăm (Q7); **empty** khi ví chưa có giao dịch (Q8).
- **Nối điều hướng** list → detail qua `InkWell` push `WalletDetailScreen(wallet)`; ví ẩn mở bình thường (Q9); **1 token mới** `coralLightBg #FAECE7` (Q10); **không dependency/controller/drift/contracts** (Q11).

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — `Transaction` (id, walletId, type, category, note, amount **signed**, date) + hàm thuần (lọc theo ví, sắp mới nhất, nhãn ngày, chuỗi `formatSignedMoney`, màu/icon theo type). `Wallet` giữ nguyên từ PBI 5 (hero đọc `balance`, thẻ đọc `creditUsageLabel`/`creditUsedPercent`).
- **Hợp đồng giao diện**: **không tạo** — app nội bộ, offline, không API/CLI công khai (Q11).
- **Kịch bản khởi động nhanh**: xem `quickstart.md` — nhóm QA A–H đối chiếu SC-001..008 & FR; empty/âm/giao dịch nhiều phủ bằng widget test.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Không phình layer nghiệp vụ | ✅ | Chỉ thêm 1 model + 1 hằng source + 2 hàm thuần + màn hình + 1 token; không store/controller/service |
| Không vi phạm mới phát sinh | ✅ | Ngoại lệ duy nhất = bộ giao dịch mẫu (spec bắt buộc, kế thừa quyết định mở PBI 5); lệch mockup/FR hero thẻ (chữ trắng) — ghi Rủi ro |
| Test không phụ thuộc thiết bị/lưu trữ | ✅ | UI pure widget, bơm `wallet` + `transactions` qua constructor; unit hàm thuần; `relativeDayLabel` bơm `now` |
| Shell, PIN, danh sách ví, Cài đặt cũ không vỡ | ✅ | Không sửa `WalletSource`/ví mẫu; `WalletListScreen` chỉ thêm `InkWell` tap hàng (đổi đúng hành vi FR-001); test PBI 5 case "tap hàng không mở" được **cập nhật** (FR-001 PBI 6) |
| Tái dùng hơn viết mới | ✅ | `SubPageScaffold`, `AppColors`, token có sẵn, `creditUsageLabel`/`creditUsedPercent` (PBI 5); không thêm `intl`/icon lib; Material icon line theo DS |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── theme/app_colors.dart                        # [SỬA] thêm coralLightBg #FAECE7 (tròn icon dòng chi)
│   ├── core/
│   │   ├── money_format.dart                        # [SỬA] thêm formatSignedMoney(int): '+X đ'/'-X đ'/'0 đ'
│   │   ├── date_label.dart                          # [TẠO] relativeDayLabel(DateTime, {now}): Hôm nay / Hôm qua / dd/MM
│   │   └── transaction/
│   │       ├── transaction.dart                     # [TẠO] TxnType + label; Transaction(id, walletId, type,
│   │       │                                        #        category, note, amount signed, date) + typeLabel;
│   │       │                                        #        transactionsForWallet / sortNewestFirst (hàm thuần)
│   │       └── transaction_source.dart              # [TẠO] TransactionSource.all() — bộ mẫu theo quickstart;
│   │                                                #        forWallet(walletId) lọc + sắp mới nhất; ngày tương đối now
│   └── screens/
│       ├── wallet_detail_screen.dart                # [TẠO] WalletDetailScreen({wallet, List<Transaction>? transactions})
│       │                                            #        — SubPageScaffold(title: wallet.name) + scroll:
│       │                                            #        _Hero (teal: icon + số dư/credit + typeLabel),
│       │                                            #        _QuickActions (Chuyển tiền/Sửa ví/Ẩn ví, no-op),
│       │                                            #        SectionHeader('GIAO DỊCH GẦN ĐÂY'),
│       │                                            #        danh sách _TxnRow (màu/icon theo type) / _EmptyTransactions
│       └── wallet_list_screen.dart                  # [SỬA] hàng ví bọc InkWell → push WalletDetailScreen(wallet)
│                                                    #        (FR-001, kể cả ví ẩn); giữ nguyên phần còn lại
└── test/
    ├── money_format_test.dart                       # [SỬA] thêm case formatSignedMoney: + / - / 0 / giá trị lớn
    ├── date_label_test.dart                         # [TẠO] unit relativeDayLabel bơm now: hôm nay/hôm qua/dd/MM
    ├── wallet_detail_screen_test.dart               # [TẠO] widget: hero ví thường & thẻ tín dụng; dòng thu(+teal)/
    │                                                #        chi(-coral)/transfer(trung tính, xuất hiện cả 2 ví);
    │                                                #        nhãn ngày; empty (Sổ tiết kiệm / bơm []); ví ẩn vẫn mở;
    │                                                #        cỡ chữ lớn + vùng an toàn không overflow; 3 nút + dòng
    │                                                #        chạm không mở màn; có BackButton trả về
    └── wallet_list_screen_test.dart                 # [SỬA] case "(h) tap hàng không mở" → tap ví → WalletDetailScreen;
                                                    #        "+ Thêm ví mới" vẫn no-op
```

Không đổi: pubspec.yaml (không thêm dependency), `Wallet`/`WalletSource` (PBI 5), main.dart, app.dart, shell/boot/PIN, `SubPageScaffold`, android/, ios/.

## Rủi ro & ngoại lệ có lý do

- **Bộ giao dịch mẫu trên thiết bị thật (kế thừa quyết định PBI 5)**: nguyên tắc PBI 4 "cấm số liệu minh họa" được gỡ vì spec PBI 6 **bắt buộc** bộ mẫu để kiểm chứng (SC-003: một ví 3 thu 2 chi 1 chuyển) và chưa có luồng ghi giao dịch. Số liệu rõ là demo, không nhận dạng người thật. Khi PBI Giao dịch (drift) đến → thay `TransactionSource` bằng đọc DB, interface `List<Transaction>` giữ nguyên.
- **Số dư hero đọc `wallet.balance` cấp thẳng, không tính lại từ giao dịch (⚠ quyết định mở #2 research)**: màn chi tiết hiển thị số dư suy ra nhưng nguồn là field `balance` (PBI 5), không phải cộng dồn giao dịch — vì model `Wallet` chưa có `initial_balance` và chưa có DB giao dịch để suy. Bộ mẫu được dàn để Σ signed + nền quy ước = balance, QA đối chiếu thủ công SC-003 được. Muốn màn **tự tính** balance từ giao dịch ngay → thêm `initial_balance` vào `Wallet` (báo trước khi implement). Khi PBI Giao dịch chốt, số dư thành đại lượng suy ra thật và cập nhật wiki.
- **Hero thẻ tín dụng để chữ trắng, không coral (lệch FR-005 "ngữ cảnh màu chi tiêu")**: coral trên nền teal tương phản kém; design system bắt "nền teal luôn đi kèm chữ trắng" → ưu tiên đọc rõ. Ngữ cảnh chi tiêu được thể hiện ở dòng giao dịch chi (coral). Đối chiếu mắt trên emulator; cần đổi → thêm chi tiết màu nhỏ (phần trăm/thanh) thay vì đổi dòng chữ lớn.
- **Test PBI 5 "tap hàng ví không mở màn" phải đổi**: PBI 6 FR-001 bắt hàng ví điều hướng sang chi tiết → case (h) sửa thành khẳng định đẩy `WalletDetailScreen`, riêng "+ Thêm ví mới" giữ no-op. Đây là thay đổi có chủ đích theo spec, không phải hồi quy.
- **Empty & số âm & giao dịch nhiều chỉ kiểm chứng bằng widget test**: thiết bị không tạo được 0 giao dịch / ví âm (không có luồng ghi). Tận dụng ví ẩn "Sổ tiết kiệm" (trống) cho QA mắt + widget test phủ các trường hợp còn lại; đánh giá định tính là đủ theo spec.
- **Cỡ chữ lớn / tên dài / vùng an toàn**: body cuộn toàn phần nên không nén vùng teal; dòng giao dịch bó `Expanded`/`Flexible` + ellipsis; widget test bơm textScale 2.0 + màn có safe inset kiểm không overflow. Nếu vẫn tràn trên thiết bị thật → điều chỉnh rồi ghi trạng thái sau thi công.
- **iOS chưa verify** (máy Windows): code thuần widget/material, rủi ro thấp; giữ trạng thái, verify khi có máy macOS.

## File đã tạo

- `.specify/specs/6/research.md`
- `.specify/specs/6/data-model.md`
- `.specify/specs/6/quickstart.md`
- `.specify/specs/6/plan.md`

Bước tiếp theo: chạy `/sora-task 6` để phân rã thành tasks.md.
