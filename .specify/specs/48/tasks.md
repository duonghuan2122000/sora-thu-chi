# Danh sách Task: Chế độ riêng tư trên Tổng quan (Privacy Mode Dashboard)

**Mã PBI**: 48
**Nguồn**: plan.md, spec.md, research.md, data-model.md, quickstart.md

## Pha 1: Setup

*(Không có task — không thêm dependency mới, không đổi cấu trúc thư mục ngoài các file tạo ở Pha Foundational.)*

## Pha 2: Foundational

Bắt buộc xong trước khi làm bất kỳ User Story nào — cả 2 story đều cần `PrivacyController` làm nguồn chân lý trạng thái Privacy mode.

- [X] T001 Tạo `PrivacyController extends GetxController` (Rx `hideBalance`, `amountCalculatorEnabled`, `revealed`; `load()` đọc `UtilitiesStore`; `setHideBalance(bool)`/`setAmountCalculatorEnabled(bool)` ghi qua `UtilitiesStore.save()` giữ nguyên cờ còn lại) tại app/sora_thu_chi/lib/core/privacy/privacy_controller.dart
- [X] T002 [P] Tạo `ensurePrivacyController()` (singleton GetX, cùng pattern `ensureUtilitiesStore`) tại app/sora_thu_chi/lib/data/privacy_deps.dart
- [X] T003 Viết unit test cho `PrivacyController` (load phản chiếu đúng `UtilitiesStore` giả; `setHideBalance` không đè `amountCalculatorEnabled` và ngược lại; `revealed` mặc định `false`) tại app/sora_thu_chi/test/privacy_controller_test.dart
- [X] T004 Sửa app/sora_thu_chi/lib/screens/utilities_screen.dart: bỏ state cục bộ `_prefs`/`_load`/`_setPrefs`, chuyển 2 công tắc "Ẩn số dư"/"Máy tính" sang đọc/ghi qua `ensurePrivacyController()` (bọc `Obx`), seam test `store`/`controller` vẫn cho phép bơm fake
- [X] T005 Cập nhật app/sora_thu_chi/test/utilities_screen_test.dart theo seam `PrivacyController` mới — seam `store:` giữ nguyên hành vi quan sát được nên toàn bộ 13 test cũ pass không sửa; case đồng bộ 2 chiều thật (Dashboard + UtilitiesScreen dùng chung singleton) chuyển sang T013

## Pha 3: User Story 1 - Ẩn số tiền trên Tổng quan + đồng bộ 2 chiều (Ưu tiên: P1)

**Mục tiêu**: Khi Privacy mode bật (từ Cài đặt → Tiện ích hoặc từ icon mắt trên Tổng quan), toàn bộ số tiền trên Tổng quan (số dư tổng, thẻ thu/chi tháng này, giao dịch gần đây) hiển thị dạng che; tắt đi thì hiện lại bình thường; hai nơi bật/tắt luôn khớp nhau.

**Tiêu chí kiểm thử độc lập**: Bật công tắc "Ẩn số dư" ở Cài đặt → mở Tổng quan thấy mọi số tiền bị che (dấu chấm, độ dài xấp xỉ số gốc), icon mắt đổi trạng thái "đang ẩn"; tắt công tắc → số hiện lại thật. Chạm icon mắt trên Tổng quan lúc đang tắt → Privacy mode bật, quay lại Cài đặt thấy công tắc đã bật.

- [X] T006 [US1] Thêm hàm `maskMoney(int value)` (che bằng `'•' * số-chữ-số` + `' đ'`, số chữ số = độ dài `value.abs().toString()`) tại app/sora_thu_chi/lib/core/money_format.dart
- [X] T007 [P] [US1] Thêm case kiểm thử `maskMoney` (số dương/âm/0/nhiều chữ số) vào app/sora_thu_chi/test/money_format_test.dart
- [X] T008 [US1] Thêm tham số `masked` (`bool`, mặc định `false`) vào `MonthStatRow`/`_StatBlock` tại app/sora_thu_chi/lib/core/widgets/month_stat_row.dart — dùng `maskMoney` thay `formatMoney` khi `true`
- [X] T009 [US1] Thêm tham số `masked` (`bool`, mặc định `false`) vào `TxnRowTile` tại app/sora_thu_chi/lib/core/widgets/txn_row_tile.dart — dùng `maskMoney` thay `formatMoney`/`formatSignedMoney` khi `true`, giữ nguyên logic màu/icon hiện có
- [X] T010 [US1] Sửa app/sora_thu_chi/lib/screens/dashboard_screen.dart: bọc `Obx` đọc `ensurePrivacyController().hideBalance`, dùng `maskMoney` cho số dư tổng ở header và truyền `masked: hideBalance` xuống `MonthStatRow`/`TxnRowTile`
- [X] T011 [US1] Thêm icon con mắt (48px, cạnh `_BellButton`) trong `Row` truyền vào `ScreenHeader.trailing` tại app/sora_thu_chi/lib/screens/dashboard_screen.dart — hiển thị mở/gạch chéo theo `hideBalance`; chạm khi đang tắt → `ensurePrivacyController().setHideBalance(true)`; chạm khi đang bật → tạm thời không làm gì (US2 sẽ thay bằng xem tạm thời)
- [X] T012 [P] [US1] Cập nhật app/sora_thu_chi/test/dashboard_screen_test.dart: case `hideBalance=false` hiển thị số thật, `hideBalance=true` hiển thị dạng che ở cả 3 vị trí (số dư tổng, thẻ thu/chi, giao dịch gần đây); chạm icon mắt lúc đang tắt → gọi `setHideBalance(true)` và phản ánh ngay trên `Obx`
- [X] T013 [P] [US1] Cập nhật app/sora_thu_chi/test/utilities_screen_test.dart: case bật icon mắt ở Tổng quan (qua `PrivacyController` dùng chung) → công tắc "Ẩn số dư" ở màn Tiện ích hiển thị đã bật

## Pha 4: User Story 2 - Xem tạm thời & tự ẩn khi rời Tổng quan (Ưu tiên: P2)

**Mục tiêu**: Khi Privacy mode đang bật, chạm icon mắt hiện số tiền thật ngay lập tức không cần xác thực; chạm lại hoặc rời khỏi Tổng quan (đổi tab/mở lại app) thì tự ẩn lại.

**Tiêu chí kiểm thử độc lập**: Bật Privacy mode → chạm icon mắt → số hiện ngay; chạm lại → ẩn lại; chuyển sang tab khác rồi quay lại Tổng quan → số ẩn lại (không còn ở trạng thái xem tạm).

- [X] T014 [US2] (Đã cài cùng T011) Xử lý chạm icon mắt tại app/sora_thu_chi/lib/screens/dashboard_screen.dart: khi `hideBalance == true`, chạm đảo `revealed`; `masked` = `hideBalance && !revealed`
- [X] T015 [US2] Sửa app/sora_thu_chi/lib/core/app_shell.dart `_onTabSelected`: rời tab Tổng quan → reset `revealed = false`
- [X] T016 [P] [US2] (Đã có ở case (l) trong dashboard_screen_test.dart, viết cùng T012) chạm icon mắt lúc `hideBalance=true` → hiện tạm, chạm lại → ẩn lại
- [X] T017 [P] [US2] Thêm app/sora_thu_chi/test/app_shell_test.dart: case rời tab Tổng quan (chọn tab khác) → `PrivacyController.revealed` reset về `false`

## Pha cuối: Polish & Cross-cutting

- [X] T018 Chạy `flutter analyze` và `flutter test` toàn bộ tại app/sora_thu_chi/, sửa lỗi phát sinh (nếu có) trước khi coi PBI 48 hoàn tất
- [ ] T019 QA tay trên emulator theo kịch bản ở [quickstart.md](.specify/specs/48/quickstart.md) (7 bước) — xác nhận không có hồi quy ở tab Giao dịch (số tiền vẫn hiện bình thường dù Privacy mode đang bật)

## Sơ đồ phụ thuộc

```
Pha 2 (Foundational: T001–T005)
        │
        ▼
Pha 3 (US1: T006–T013)  ──── độc lập kiểm thử được (MVP)
        │
        ▼
Pha 4 (US2: T014–T017)  ──── cần icon mắt + Obx đã dựng ở US1 (T011)
        │
        ▼
Pha cuối (T018–T019)
```

Trong Pha 2: T001 → T002 → (T003 song song T004) → T005.
Trong Pha 3: T006 → (T007 song song T008, T009) → T010 → T011 → (T012 song song T013).
Trong Pha 4: (T014, T015 làm khác file, T015 có thể chạy song song T014) → (T016 song song T017).

## Ví dụ chạy song song

- Pha 2: `T003` (unit test PrivacyController) và `T004` (sửa UtilitiesScreen) chạm 2 file khác nhau, chạy song song sau khi `T001`/`T002` xong.
- Pha 3: `T008` (month_stat_row.dart) và `T009` (txn_row_tile.dart) độc lập file, chạy song song sau `T006`. `T012`/`T013` (2 file test khác nhau) chạy song song sau `T011`.
- Pha 4: `T016`/`T017` (2 file test khác nhau) chạy song song sau `T014`/`T015`.

## Chiến lược triển khai

- **MVP đề xuất**: User Story 1 (T001–T013) — riêng phần này đã đưa Privacy mode có tác dụng thật trên Tổng quan và đồng bộ đúng với Cài đặt, đáp ứng giá trị cốt lõi ("không lộ số liệu khi dùng ở nơi công cộng").
- **Giao hàng tăng dần**: Foundational → US1 (ẩn/hiện + đồng bộ) → US2 (tiện ích xem tạm thời) → Polish/QA. Có thể dừng sau US1 nếu cần release sớm; US2 không phá vỡ hành vi US1 (chỉ thay nhánh "chạm khi đang bật" từ no-op sang có tác dụng).
