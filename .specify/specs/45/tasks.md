# Danh sách Task: Dọn màn Tiện ích & Cá nhân hóa

**Mã PBI**: 45
**Nguồn**: plan.md, spec.md, research.md, quickstart.md

## Định dạng task

`- [ ] [MãTask] [P?] [Story?] Mô tả kèm đường dẫn file`

## Pha 1: Setup

*(Không cần — sửa trực tiếp file UI hiện có, không thêm phụ thuộc/công cụ mới.)*

## Pha 2: Foundational

*(Không có task nền tảng — thay đổi chỉ nằm gọn trong 1 màn hiện có.)*

## Pha 3: User Story 1 - Ẩn hàng chưa implement khỏi màn Tiện ích (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: Màn Tiện ích & Cá nhân hóa chỉ còn hiển thị hàng có phản hồi thật (5 hàng/2 nhóm), bỏ 3 hàng chevron giả không làm gì.
**Tiêu chí kiểm thử độc lập**: Mở màn Tiện ích, xác nhận không còn "Định dạng & Tiền tệ", "Tìm kiếm toàn cục", "Quản lý Tag" và không còn nhãn nhóm "DỮ LIỆU & TÌM KIẾM"; 5 hàng còn lại vẫn hoạt động như cũ.

- [X] T001 [US1] Xoá 3 lời gọi `_navRow(...)` (Định dạng & Tiền tệ, Tìm kiếm toàn cục, Quản lý Tag) khỏi `_body()` tại `app/sora_thu_chi/lib/screens/utilities_screen.dart:214-220,250-264`
- [X] T002 [US1] Xoá nhãn nhóm `_SectionLabel('DỮ LIỆU & TÌM KIẾM'.tr)` và block `..._rows(...)` rỗng còn lại của nhóm đó tại `app/sora_thu_chi/lib/screens/utilities_screen.dart:248-265` (nhóm HIỂN THỊ chỉ còn 2 hàng, giữ nguyên `_SectionLabel`/divider của nhóm này)
- [X] T003 [US1] Cập nhật docstring đầu class `_UtilitiesScreenState`/file tại `app/sora_thu_chi/lib/screens/utilities_screen.dart:17-36` — sửa "3 nhóm / 8 hàng" thành "2 nhóm / 5 hàng", bỏ nhắc 3 hàng đã xoá
- [X] T004 [US1] Cập nhật `groupOrder` trong `app/sora_thu_chi/test/utilities_screen_test.dart:94-102` — bỏ "Định dạng & Tiền tệ" khỏi 'HIỂN THỊ', xoá hẳn key 'DỮ LIỆU & TÌM KIẾM'
- [X] T005 [US1] Sửa test `'Bố cục mockup...'` tại `app/sora_thu_chi/test/utilities_screen_test.dart:107-146` — bỏ icon `Icons.tune`, `Icons.search`, `Icons.sell_outlined` khỏi danh sách assert icon (còn 5 icon)
- [X] T006 [US1] Sửa test `'Trailing mặc định...'` tại `app/sora_thu_chi/test/utilities_screen_test.dart:148-157` — đổi `findsNWidgets(5)` (chevron) thành `findsNWidgets(2)` (chỉ Giao diện + Ngôn ngữ còn chevron)
- [X] T007 [US1] Xoá test `'3 hàng điều hướng còn no-op...'` tại `app/sora_thu_chi/test/utilities_screen_test.dart:239-260` (3 hàng đã bị xoá khỏi UI, test không còn đối tượng để chạm)
- [X] T008 [US1] Xoá test `'Quản lý Tag không hiện số tag giả...'` tại `app/sora_thu_chi/test/utilities_screen_test.dart:348-354` (hàng "Quản lý Tag" đã bị xoá khỏi UI)
- [X] T009 [US1] Sửa test `'Cỡ chữ lớn + màn nhỏ...'` tại `app/sora_thu_chi/test/utilities_screen_test.dart:356-382` — đổi hàng cuộn tới đích từ `'Quản lý Tag'` (đã xoá) sang `'Máy tính khi nhập số tiền'` (hàng cuối còn lại)

## Pha cuối: Polish & Cross-cutting

- [X] T010 [P] Chạy `flutter analyze` và `flutter test test/utilities_screen_test.dart` tại `app/sora_thu_chi/` — đảm bảo sạch lint, toàn bộ test pass (không có test đỏ mới ngoài test đỏ có sẵn đã biết từ trước). **Phát sinh ngoài kế hoạch**: `flutter test` full suite lộ 1 test đỏ khác ở `test/dark_theme_smoke_test.dart` (assert cũ tìm "Quản lý Tag" đã xoá) — đã sửa cùng T010, full suite hiện **1387 test pass, 0 đỏ**.
- [X] T011 [P] Rà `wiki-knowledge/entity/Hồ sơ & Bảo mật.md` (nhắc "8 hàng"/"3 nhóm" của màn Tiện ích) — cập nhật nếu có nhắc số hàng/nhóm cũ, append `wiki-knowledge/log.md` nếu có sửa. Đã sửa thêm `wiki-knowledge/concept/Lộ trình phát triển.md` (cùng nội dung cũ).
- [ ] T012 QA tay trên emulator theo từng bước tại `.specify/specs/45/quickstart.md` — **cần người dùng tự chạy**, không tự động hoá được.

## Sơ đồ phụ thuộc

```text
T001 → T002 → T003 (cùng file utilities_screen.dart, làm tuần tự)
T004 → T005 → T006 → T007 → T008 → T009 (cùng file test, làm tuần tự, chạy sau khi UI đã sửa xong T001-T003)
(T001-T009) → T010 → T012
T011 độc lập, làm song song bất kỳ lúc nào sau khi đã xác nhận thay đổi cuối cùng
```

## Ví dụ chạy song song

```text
# T010 và T011 có thể chạy cùng lúc sau khi US1 code+test xong:
T010 [P] flutter analyze + flutter test
T011 [P] Rà & cập nhật wiki
```

## Chiến lược triển khai

- **MVP**: toàn bộ US1 (chỉ có 1 story) — PBI này là một lát cắt nhỏ, không chia thêm P2/P3.
- **Giao hàng**: một lần, US1 xong là đóng PBI 45.
