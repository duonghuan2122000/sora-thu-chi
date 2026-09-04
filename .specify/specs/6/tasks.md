# Danh sách Task: Màn hình chi tiết ví

**Mã PBI**: 6
**Nguồn**: plan.md, spec.md, research.md, data-model.md, quickstart.md

## Pha 1: Setup

Không có task độc lập — đợt này **không** thêm dependency, không wire drift/GetX/controller mới, không scaffold mới (research Q11); không đổi `pubspec.yaml`. `Wallet`/`WalletSource`/`SubPageScaffold`/token màu + shell/PIN kế thừa từ PBI 1–5; mọi thay đổi nằm trong các pha dưới.

## Pha 2: Foundational

*(Nền tảng thuần Dart / token phải xong trước khi dựng màn hình — tái dùng toàn app sau này.)*

- [X] T001 [P] Thêm hàm thuần `formatSignedMoney(int)` vào `app/sora_thu_chi/lib/core/money_format.dart`: dấu `+`/`-` ASCII (đồng bộ `formatAmount`) + phân tách nghìn `.` + `đ` — dương `'+18.000.000 đ'`, âm `'-450.000 đ'`, `0` → `'0 đ'`; giữ nguyên `formatAmount`/`formatMoney` hiện có
- [X] T002 [P] Thêm 1 token màu vào `app/sora_thu_chi/lib/theme/app_colors.dart`: `coralLightBg = Color(0xFFFAECE7)` (nền tròn icon dòng chi — mockup, research Q10); không nhúng hex cứng trong widget
- [X] T003 [P] Tạo `app/sora_thu_chi/lib/core/date_label.dart`: hàm thuần `relativeDayLabel(DateTime date, {DateTime? now})` — cùng ngày lịch với `now` → `'Hôm nay'`, hôm qua → `'Hôm qua'`, khác → `'dd/MM'` (viết tay, không thêm `intl`; `now` truyền vào để test deterministic)
- [X] T004 [P] Tạo `app/sora_thu_chi/lib/core/transaction/transaction.dart`: enum `TxnType { income, expense, transfer, adjustment }` kèm `label` tiếng Việt ('Thu'/'Chi'/'Chuyển khoản'/'Điều chỉnh số dư'); class `Transaction { int id, int walletId, TxnType type, String category (rỗng với transfer/adjustment), String note, int amount (signed VND = tác động ròng lên ví chứa dòng), DateTime date }` + `typeLabel`; hàm thuần `transactionsForWallet(List<Transaction>, int walletId)` (lọc đúng ví) và `sortNewestFirst` (date giảm dần, trùng ngày ổn định theo id) — theo data-model.md §Thực thể & §Giá trị suy dẫn
- [X] T005 Tạo `app/sora_thu_chi/lib/core/transaction/transaction_source.dart`: hằng `TransactionSource.all()` trả bộ giao dịch mẫu khớp quickstart.md — Vietcombank (id 2): 3 thu + 2 chi + 1 chuyển khoản đi, `Σ signed` dàn để `nền 1.200.000 + Σ = 14.800.000` (đúng `WalletSource` PBI 5), đủ 3 dạng nhãn ngày (dùng `DateTime.now()`: Hôm nay / Hôm qua / dd/MM); Tiền mặt (id 1): 1–2 chi; Thẻ tín dụng VIB (id 3): 1–2 chi; Momo (id 4): 1 dòng chuyển khoản **đến** (vế đích, amount dương); Sổ tiết kiệm (id 5, ẩn): **rỗng** → empty state; phương thức `forWallet(int walletId)` = lọc + `sortNewestFirst`

## Pha 3: User Story 1 - Màn chi tiết ví (hiển thị + điểm vào) (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: Mở được màn chi tiết từng ví từ danh sách (FR-001/002) — hero teal (tên + icon + số dư/credit + loại), ba hành động nhanh treo, nhóm "GIAO DỊCH GẦN ĐÂY" đúng ví + màu ngữ cảnh (FR-003..015). Chỉ xem: không thao tác nào đổi dữ liệu (SC-008), không mở luồng con (chuyển tiền/sửa/ẩn/chi tiết giao dịch = PBI sau).
**Tiêu chí kiểm thử độc lập**: `flutter test test/wallet_detail_screen_test.dart` pass — bơm `wallet` + `transactions` qua constructor kiểm hero thường/thẻ tín dụng, dòng thu-chi-transfer màu+dấu, empty, ví ẩn mở, cỡ chữ lớn & vùng an toàn không overflow; test điều hướng list→detail ở `wallet_list_screen_test` (navigator thật).

- [X] T006 [US1] Tạo `app/sora_thu_chi/lib/screens/wallet_detail_screen.dart`: `WalletDetailScreen({required Wallet wallet, List<Transaction>? transactions})`, default `TransactionSource.forWallet(wallet.id)`; body = `SubPageScaffold(title: wallet.name)` + một scroll duy nhất bọc `SafeArea(top:false)` chứa: `_Hero` (nền teal nối app bar: tròn icon trắng alpha ~0.15 + dòng chính — ví thường `formatMoney(wallet.balance)` trắng cỡ lớn, thẻ tín dụng → `creditUsageLabel` cỡ vừa + dòng phụ `'${wallet.creditUsedPercent}% hạn mức đã dùng'`; chữ trắng mọi loại — research Q7) + dòng phụ `typeLabel` (`white70`); `_QuickActions` 3 cột tròn 48 `tealLightBg` icon line Material + nhãn 11 `listLabel`: **Chuyển tiền** `swap_horiz`, **Sửa ví** `edit_outlined`, **Ẩn ví** `visibility_off_outlined`, mỗi nút `onPressed: () {}` no-op (FR-007); `SectionHeader('GIAO DỊCH GẦN ĐÂY')`; danh sách `_TxnRow` mỗi dòng (bọc tương tác có hiệu ứng mực): tròn icon 40 theo dấu (↑ dương / ↓ âm) **màu theo type** — income tròn `tealLightBg` icon/số `teal` dấu `+`, expense tròn `coralLightBg` icon/số `coral` dấu `-`, transfer/adjustment tròn `softCardBg` icon/số `listLabel` (trung tính, FR-010); tiêu đề = `note` khác rỗng nếu có, ngược lại `category` (transfer/adjustment rỗng → `typeLabel`); dòng phụ `'${category} · ${relativeDayLabel(date)}'` hoặc `'${typeLabel} · ${relativeDayLabel(date)}'` khi không category; trailing `formatSignedMoney` căn phải, dòng bó `Expanded`/`Flexible` + ellipsis; rỗng → `_EmptyTransactions` (icon `🧾` + `'Chưa có giao dịch nào.'` + dòng phụ `'Giao dịch của ví sẽ xuất hiện tại đây.'`), hero + hành động + tiêu đề nhóm vẫn hiện (FR-012); chạm dòng giao dịch `onTap: () {}` không mở màn (FR-011) — theo plan/research Q5/Q6/Q7/Q8, đúng design system (không hex cứng)
- [X] T007 [P] [US1] Sửa `app/sora_thu_chi/test/money_format_test.dart`: thêm case `formatSignedMoney` — `0` → `'0 đ'`, dương → `'+1.234.567 đ'`, âm → `'-500.000 đ'`, giá trị lớn không thừa số lẻ; giữ nguyên test `formatAmount`/`formatMoney`
- [X] T008 [P] [US1] Tạo `app/sora_thu_chi/test/date_label_test.dart`: unit test `relativeDayLabel` bơm `now` — cùng ngày → `'Hôm nay'`, hôm qua → `'Hôm qua'`, `now - 2 ngày`/khác tháng → `'dd/MM'` đúng hai chữ số, đổi mốc `now` sang ngày khác vẫn đúng
- [X] T009 [P] [US1] Tạo `app/sora_thu_chi/test/transaction_test.dart`: unit test `transactionsForWallet` (lọc đúng ví — dòng ví khác bị loại) + `sortNewestFirst` (ngày mới nhất lên đầu; trùng ngày ổn định theo id) — bơm list qua hàm thuần, không cần thiết bị
- [X] T010 [US1] Tạo `app/sora_thu_chi/test/wallet_detail_screen_test.dart`: widget test bơm `wallet` + `transactions` qua constructor — (a) hero ví thường `bank` hiện `'14.800.000 đ'` trắng + `typeLabel` `'Tài khoản ngân hàng'`; (b) hero thẻ tín dụng hiện `creditUsageLabel` `'Đã dùng 6.500.000 / 20.000.000 đ'` + `'32% hạn mức đã dùng'`, **không** hiện số dư dương; (c) nhóm `'GIAO DỊCH GẦN ĐÂY'` chỉ liệt kê giao dịch đúng ví — dòng income số teal dấu `+`/↑, expense số coral dấu `-`/↓, transfer màu trung tính `listLabel`, giao dịch ví khác không xuất hiện; (d) 1 lần transfer = dòng trên ví nguồn hiện `-1.000.000 đ` trung tính + dòng trên ví đích hiện `+1.000.000 đ` trung tính; (e) dòng có `note` → tiêu đề là note, dòng phụ `'Ăn uống · Hôm nay'`; đủ dạng nhãn ngày Hôm nay/Hôm qua/dd/MM; (f) ví `savings` (ẩn, không giao dịch) vẫn mở được, nhóm hiện `'Chưa có giao dịch nào.'` không vỡ; (g) bơm `[]` → empty state, hero + hành động + tiêu đề vẫn hiện; (h) chạm lần lượt Chuyển tiền/Sửa ví/Ẩn ví + từng dòng giao dịch → không route mới, không lỗi (SC-005); (i) textScale 2.0 + `setSurfaceSize` màn có safe inset → không `RenderFlex overflow` (SC-007); (j) có `BackButton` trả về (SC-001)
- [X] T011 [US1] Sửa `app/sora_thu_chi/lib/screens/wallet_list_screen.dart`: bọc hàng ví `_WalletRow` trong `InkWell`, `onTap` → `Navigator.of(context).push(MaterialPageRoute(builder: (_) => WalletDetailScreen(wallet: wallet)))` — mở **mọi** ví kể cả ví ẩn (FR-001, spec #7); không thêm seam callback (research Q9); giữ nguyên nút `'+ Thêm ví mới'` no-op và toàn bộ phần còn lại
- [X] T012 [US1] Sửa `app/sora_thu_chi/test/wallet_list_screen_test.dart`: thay case "(h) tap hàng không mở" bằng khẳng định điều hướng — tap hàng ví (VD Vietcombank) → `pumpAndSettle` → có `WalletDetailScreen` hiển thị đúng tên ví + `BackButton`, back về list đúng trạng thái; riêng tap `'+ Thêm ví mới'` giữ không mở route (research Q9, plan Rủi ro)

## Pha cuối: Polish & Cross-cutting

- [X] T013 Chạy `flutter analyze` (sạch, 0 warning) + `flutter test` (toàn bộ test PBI 2/3/4/5/6 pass) tại `app/sora_thu_chi/` — rà không có file/dependency dư (pubspec.yaml/`contracts/`/drift/GetX/controller không đổi; `Wallet`/`WalletSource`/`SubPageScaffold`/main.dart/app.dart/shell/PIN không đổi theo plan.md mục "Không đổi")
- [X] T014 Kiểm chứng thủ công trên emulator theo `.specify/specs/6/quickstart.md` nhóm A–H: chạm Vietcombank từ danh sách mở detail ≤ 1 chạm (SC-001), đối chiếu hero `'14.800.000 đ'` + `'Tài khoản ngân hàng'` và phép cộng/trừ tay `nền 1.200.000 + Σ signed = 14.800.000` (SC-003/004), nhóm "GIAO DỊCH GẦN ĐÂY" chỉ giao dịch đúng ví + màu/dấu thu-chi-transfer + nhãn ngày thân thiện (SC-003/004), thẻ VIB hiển thị dạng "Đã dùng…" không số dư dương (SC-002), chạm Sổ tiết kiệm (ẩn, rỗng) → mở được + empty state không vỡ (SC-006), chạm 3 nút + từng dòng → 0 lỗi không mở màn (SC-005/008), back về list đúng trạng thái (SC-001), cỡ chữ lớn + vùng an toàn không vỡ (SC-007), đưa app xuống nền/mở lại → màn khóa PIN che nội dung (FR-016) — số âm/giao dịch nhiều đã phủ bằng widget test, ghi kết quả vào trạng thái PBI

## Sơ đồ phụ thuộc

```text
Setup (trống)
  ↓
Foundational:  T001 money_format ────────────────────────────────▶
               T002 [P] app_colors ──────────────────────────────▶
               T003 [P] date_label ──────────────────────────────▶ (T006 detail_screen)
               T004 [P] transaction.dart ──▶ T005 transaction_source
  ↓
US1:  T006 wallet_detail_screen ──▶ T010 detail_test
      │  ▲
      │  (T007 format_test // T006 — sau T001)
      │  (T008 date_label_test // T006 — sau T003)
      │  (T009 transaction_test // T006 — sau T004)
      T011 list wiring ──▶ T012 list_test update
  ↓
Polish:  T013 analyze + test ──▶ T014 QA emulator
```

Thứ tự thực thi chính: `T001 → T002 → T003 → T004 → T005 → T006 → T010 → T011 → T012 → T013 → T014`. (`T001–T004` chạy song song nhau; `T007`/`T008`/`T009` chạy song song `T006` sau khi foundational file tương ứng xong; `T010` sau `T006`.)

## Ví dụ chạy song song

```text
# Foundational (cùng lúc — khác file, không phụ thuộc):
T001 [P] money_format.dart — formatSignedMoney
T002 [P] app_colors.dart — coralLightBg
T003 [P] date_label.dart — relativeDayLabel
T004 [P] transaction.dart — model + hàm thuần

# US1 (sau khi foundational file tương ứng xong — test không chờ T006):
T006 [US1] wallet_detail_screen.dart
T007 [P] [US1] money_format_test.dart
T008 [P] [US1] date_label_test.dart
T009 [P] [US1] transaction_test.dart
```

## Chiến lược triển khai

- **MVP**: PBI 6 gồm đúng 1 user story liền khối (màn chi tiết ví — hiển thị + điểm vào) → MVP = trọn US1 (mọi FR thuộc cùng màn, không tách lát cắt nhỏ có giá trị dùng độc lập). Thứ tự giao hàng trong US1: nền thuần Dart (`formatSignedMoney`/token/`relativeDayLabel`/model `Transaction` + `TransactionSource`) → màn hình `WalletDetailScreen` + test widget → nối điều hướng list→detail + cập nhật test PBI 5 → xác minh toàn cục + QA emulator.
- **Giao hàng tăng dần**: US1 hoàn tất là đủ điều kiện chốt PBI 6; nút FR-007/FR-011 là điểm vào của PBI sau (chuyển tiền, thêm-sửa ví, chi tiết giao dịch) — đúng seam, `WalletDetailScreen` nhận `wallet` + `List<Transaction>` qua constructor, `TransactionSource.forWallet` thay bằng đọc drift khi PBI Giao dịch đến mà interface giữ nguyên.
