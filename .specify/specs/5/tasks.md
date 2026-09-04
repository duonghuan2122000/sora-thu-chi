# Danh sách Task: Màn hình danh sách ví

**Mã PBI**: 5
**Nguồn**: plan.md, spec.md, research.md, data-model.md, quickstart.md

## Pha 1: Setup

Không có task độc lập — đợt này **không** thêm dependency, không wire drift/GetX, không scaffold mới (research Q10). Môi trường Flutter + shell + SubPageScaffold + token màu kế thừa từ PBI 1–4; mọi thay đổi nằm trong các pha dưới.

## Pha 2: Foundational

*(Nền tảng thuần Dart / token phải xong trước khi dựng màn hình — tái dùng toàn app sau này.)*

- [X] T001 Tạo `formatAmount(int)` (phân tách nghìn dấu chấm, không kèm `đ`, số âm có dấu trừ trước) và `formatMoney(int)` (= `formatAmount` + `' đ'`) tại `app/sora_thu_chi/lib/core/money_format.dart`
- [X] T002 [P] Thêm 2 token màu vào `app/sora_thu_chi/lib/theme/app_colors.dart`: `tealLightBg = Color(0xFFE1F5EE)` (nền tròn icon), `softCardBg = Color(0xFFF1EFE8)` (nền card tổng) — không nhúng hex cứng trong widget
- [X] T003 Tạo `Wallet` + enum `WalletType` (`cash/bank/credit/eWallet/savings`) tại `app/sora_thu_chi/lib/core/wallet/wallet.dart` gồm field: `id, name, type, icon(emoji String), balance(int VND), isDefault, isHidden, sortOrder, creditLimit?, creditUsed?`; kèm hàm thuần: `walletsByDisplayOrder` (không ẩn theo sortOrder rồi ẩn cuối), `activeTotal` (Σ balance ví không ẩn **và không phải credit**), `activeCount` (đếm mọi ví không ẩn, gồm credit), `creditUsedPercent` (`used*100 ~/ limit`, guard limit ≤ 0 → 0), `creditUsageLabel` (`'Đã dùng {formatAmount(used)} / {formatAmount(limit)} đ'`, import `money_format.dart`), `hiddenName` (`'{name} (đã ẩn)'`), `typeLabel` (tên loại tiếng Việt) — theo data-model.md §Giá trị suy dẫn
- [X] T004 Tạo `WalletSource.all()` tại `app/sora_thu_chi/lib/core/wallet/wallet_source.dart` trả **đúng 5 ví mẫu** khớp quickstart.md: Tiền mặt `cash` 3.200.000 **default**, Vietcombank `bank` 14.800.000, Thẻ tín dụng VIB `credit` limit 20.000.000 / used 6.500.000, Momo `eWallet` 1.450.000, Sổ tiết kiệm `savings` 9.000.000 **isHidden**; đúng 1 `isDefault`; tổng mong đợi activeTotal = **19.450.000**, activeCount = **4**

## Pha 3: User Story 1 - Màn danh sách ví (hiển thị + điểm vào) (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: Mở được màn list ví từ Cài đặt (FR-001/002), hiển thị đúng 5 ví mẫu theo mockup `wallet-list-screen.svg` — card tổng, hàng từng ví (loại/mặc định/thẻ tín dụng/ví ẩn), empty state, chế độ chỉ hiển thị (FR-003..015). Không tạo luồng tạo/sửa/ẩn/xóa (ngoài phạm vi).
**Tiêu chí kiểm thử độc lập**: `flutter test test/wallet_list_screen_test.dart` pass — bơm `List<Wallet>` qua constructor kiểm card tổng/hàng thẻ/hàng ẩn/empty/số âm/cỡ chữ lớn mà không cần thiết bị; hàng "Quản lý ví" ở Cài đặt điều hướng thật (settings_screen_test).

- [X] T005 [US1] Tạo `WalletListScreen` tại `app/sora_thu_chi/lib/screens/wallet_list_screen.dart`: constructor `WalletListScreen({List<Wallet>? wallets})` default `WalletSource.all()`; body `SubPageScaffold(title: 'Quản lý ví')` + `Column[ _TotalCard, Expanded(ListView / _EmptyState), nút '+ Thêm ví mới' ]` bọc `SafeArea(top:false)`; widget con riêng trong file — `_TotalCard` (nền `softCardBg` bo 10: nhãn `'TỔNG SỐ DƯ TẤT CẢ VÍ'`, số `formatMoney(activeTotal)`, dòng `'N ví đang hoạt động'`), tiêu đề nhóm `'VÍ CỦA BẠN'`, `_WalletRow` (icon trong tròn `tealLightBg`, tên, dòng phụ: mặc định → nhãn teal `'Mặc định'` + `' • '` + `typeLabel`; credit → `creditUsageLabel` coral + `'NN%'` coral phải; ẩn → tên `hiddenName` mờ + `'Không tính vào tổng'` + số dư mờ; số dư `formatMoney` căn phải, âm in dấu trừ; tên/dòng phụ `Expanded` + ellipsis), `_EmptyState` (icon + `'Chưa có ví nào.'` + dòng phụ hướng dẫn); tap hàng/nút thêm **không** mở màn (FR-010); không hiển thị bottom nav (FR-002)
- [X] T006 [P] [US1] Tạo `app/sora_thu_chi/test/money_format_test.dart`: unit test `formatAmount`/`formatMoney` — 0 → `'0 đ'`, dương → `'1.234.567 đ'`, âm → dấu trừ trước `'-500.000 đ'`, giá trị lớn, không thừa số lẻ
- [X] T007 [US1] Tạo `app/sora_thu_chi/test/wallet_list_screen_test.dart`: widget test bơm `wallets` qua constructor — (a) 5 ví mẫu: đủ 5 hàng, card `'19.450.000 đ'` + `'4 ví đang hoạt động'`; (b) hàng Thẻ tín dụng VIB hiển thị `'Đã dùng 6.500.000 / 20.000.000 đ'` + `'32%'` màu coral, **không** hiển thị số dư dương; (c) Sổ tiết kiệm mờ cuối list, tên `'(đã ẩn)'`, dòng `'Không tính vào tổng'`, số dư vẫn hiện; (d) đúng 1 nhãn `'Mặc định'` trên hàng Tiền mặt; (e) danh sách rỗng → `_EmptyState` + nút thêm còn, không lỗi; (f) `balance` âm → hiển thị dấu trừ không gãy; (g) textScale 2.0 + `setSurfaceSize` màn có safe inset → không `RenderFlex overflow`; (h) tap từng hàng + nút `'+ Thêm ví mới'` → không route mới, không lỗi; (i) có `BackButton` trả về
- [X] T008 [US1] Sửa `app/sora_thu_chi/lib/screens/settings_screen.dart`: thêm tham số `onManageWalletTap` (`VoidCallback?`) vào `SettingsScreen`, `_SettingsRow` thêm `onTap` optional (bọc hàng trong tương tác có hiệu ứng), hàng `'Quản lý ví'` gọi onTap — nếu `onManageWalletTap == null` → `Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletListScreen()))`, ngược lại gọi callback; giữ `const` constructor; không đổi shell (AppShell giữ default → đẩy màn list ví, FR-001)
- [X] T009 [US1] Sửa `app/sora_thu_chi/test/settings_screen_test.dart`: bỏ `'Quản lý ví'` khỏi loop tap-không-mở (chỉ còn `'Tiền tệ mặc định'`, `'Đổi mã PIN'`); thêm test case: pump `MaterialApp` → tap hàng `'Quản lý ví'` → `pumpAndSettle` → expect có `WalletListScreen` + `BackButton`; trường hợp bơm `onManageWalletTap` → callback được gọi, không đẩy route

## Pha cuối: Polish & Cross-cutting

- [X] T010 Chạy `flutter analyze` (sạch, 0 warning) + `flutter test` (toàn bộ test PBI 2/3/4/5 pass) tại `app/sora_thu_chi/` — rà không có file/dependency dư (pubspec/`contracts/`/drift/GetX không đổi, plan.md mục "Không đổi")
- [X] T011 Kiểm chứng thủ công trên emulator theo `app/../.specify/specs/5/quickstart.md` nhóm A–F: vào Cài đặt → "Quản lý ví" (SC-001), đối chiếu card tổng `19.450.000 đ`/`4 ví đang hoạt động` + hàng thẻ `'Đã dùng…/…đ'` + `'32%'` coral + hàng ẩn mờ cuối (SC-002/003/004), tap toàn bộ hàng/nút thêm → 0 lỗi không mở màn (SC-005/008), nút thêm luôn hiện khi cuộn (FR-013), cỡ chữ lớn + vùng an toàn không vỡ (SC-007), back về Cài đặt đúng trạng thái (SC-001), đưa app xuống nền/mở lại → màn khóa PIN che (FR-015)

## Sơ đồ phụ thuộc

```text
Setup (trống)
  ↓
Foundational:  T001 money_format ──▶ T003 wallet.dart ──▶ T004 wallet_source.dart
                T002 app_colors ──────────────────▶ (T005)
                                                      │
US1:  T005 wallet_list_screen ──▶ T007 list_test
      │  ▲                        │
      │  (T006 format_test // T005)│
      T008 settings wiring ──▶ T009 settings_test
  ↓
Polish:  T010 analyze + test ──▶ T011 QA emulator
```

Thứ tự thực thi chính: `T001 → T002 → T003 → T004 → T005 → T007 → T008 → T009 → T010 → T011`. (`T002` chạy song song `T001`; `T006` song song `T005` sau khi `T001` xong.)

## Ví dụ chạy song song

```text
# Foundational (sau T001):
T001 money_format.dart
T002 [P] app_colors.dart

# US1 (sau khi T001 xong — T006 không chờ T005):
T005 [US1] wallet_list_screen.dart
T006 [P] [US1] test/money_format_test.dart
```

## Chiến lược triển khai

- **MVP**: PBI 5 gồm đúng 1 user story liền khối (màn list ví) → MVP = trọn US1 (mọi FR thuộc cùng màn, không tách được lát cắt nhỏ có giá trị dùng độc lập). Thứ tự giao hàng trong US1: nền thuần Dart (format/token/model/source) → màn hình + test widget → nối điều hướng từ Cài đặt + test → xác minh toàn cục + QA.
- **Giao hàng tăng dần**: US1 hoàn tất là đủ điều kiện chốt PBI 5; các luồng con (form ví, chi tiết ví, chuyển tiền) là PBI riêng theo đúng seam — `WalletListScreen` nhận `List<Wallet>` qua constructor, hàng ví / nút "+ Thêm ví mới" giữ là điểm vào chưa kích hoạt (FR-010).
