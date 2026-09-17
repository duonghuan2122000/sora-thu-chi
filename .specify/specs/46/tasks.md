# Danh sách Task: Chuẩn hoá điều hướng giữa màn hình

**Mã PBI**: 46
**Nguồn**: plan.md, spec.md, research.md, quickstart.md

## Pha 1: Setup

- [X] T001 Chạy baseline `flutter analyze` + `flutter test` trong `app/sora_thu_chi/` trước khi sửa, ghi lại số lượng test pass hiện tại để đối chiếu sau (theo `CLAUDE.md`: baseline hiện có test đỏ có sẵn không liên quan PBI này — không sửa test đó) — kết quả: analyze sạch, 1387/1387 test pass, không có test đỏ

## Pha 2: Foundational

*Không có task nền tảng riêng — mỗi điểm sửa độc lập theo file, không có thành phần dùng chung cần dựng trước.*

## Pha 3: User Story 1 - Khai báo tường minh kiểu trả về điều hướng (Ưu tiên: P1)

**Mục tiêu**: 21 điểm `MaterialPageRoute(` còn thiếu generic (12 file) được thêm `<T>` đúng kiểu đang dùng thực tế (FR-001, FR-002, FR-004), giữ nguyên hành vi (FR-003).
**Tiêu chí kiểm thử độc lập**: sau khi sửa 1 file, `flutter analyze` sạch cho file đó và luồng thao tác tương ứng trong `quickstart.md` (mục Kiểm thử tay) hoạt động y hệt trước khi sửa.

- [X] T002 [P] [US1] Thêm `<void>` cho `MaterialPageRoute(` tại `lib/core/widgets/txn_row_tile.dart:38`
- [X] T003 [P] [US1] Thêm `<bool>` cho `MaterialPageRoute(` tại `lib/core/app_shell.dart:148`
- [X] T004 [P] [US1] Thêm generic đúng kiểu cho 4 điểm `MaterialPageRoute(` tại `lib/core/scan/scan_flow.dart:39` (`<bool>`), `:49` (`<String>`), `:56` (`<ScanStepResult>`), `:77` (`<bool>`)
- [X] T005 [P] [US1] Thêm generic đúng kiểu cho 3 điểm `MaterialPageRoute(` tại `lib/screens/budget_overview_screen.dart:129` (`<bool>`), `:145` (`<void>`), `:162` (`<bool>`)
- [X] T006 [P] [US1] Thêm `<Category>` cho `MaterialPageRoute(` tại `lib/screens/budget_form_screen.dart:111`
- [X] T007 [P] [US1] Thêm `<bool>` cho `MaterialPageRoute(` tại `lib/screens/budget_detail_screen.dart:156`
- [X] T008 [P] [US1] Thêm generic đúng kiểu cho 3 điểm `MaterialPageRoute(` tại `lib/screens/add_transaction_screen.dart:275` (`<bool>`), `:311` (`<Category>`), `:363` (`<List<String>>`)
- [X] T009 [P] [US1] Thêm `<TxnSearchFilter>` cho `MaterialPageRoute(` tại `lib/screens/transaction_screen.dart:30`
- [X] T010 [P] [US1] Thêm `<bool>` cho 4 điểm `MaterialPageRoute(` tại `lib/screens/transaction_detail_screen.dart:204`, `:236`, `:299`, `:330`
- [X] T011 [P] [US1] Thêm generic đúng kiểu cho 2 điểm `MaterialPageRoute(` tại `lib/screens/wallet_detail_screen.dart:75` (`<Wallet>`), `:113` (`<bool>`)
- [X] T012 [P] [US1] Thêm `<Category>` cho `MaterialPageRoute(` tại `lib/screens/scan/scan_confirm_screen.dart:176`
- [X] T013 [P] [US1] Thêm `<bool>` cho `MaterialPageRoute(` tại `lib/screens/scan/scan_processing_screen.dart:124`

## Pha cuối: Polish & Cross-cutting

- [X] T014 Chạy `flutter analyze` toàn repo `app/sora_thu_chi/`, xác nhận sạch (SC-001) — kết quả: No issues found!
- [X] T015 Chạy `flutter test` toàn repo `app/sora_thu_chi/`, xác nhận số test pass không giảm so với baseline T001, không lỗi mới liên quan điều hướng (SC-002, SC-003) — kết quả: 1387/1387 pass, khớp baseline
- [ ] T016 QA tay theo `quickstart.md` — chạy đủ 8 kịch bản mục "Kiểm thử tay", xác nhận hành vi y hệt trước khi sửa (chờ QA tay trên emulator/máy thật)

## Sơ đồ phụ thuộc

- T001 (baseline) chạy trước toàn bộ T002–T013.
- T002–T013 độc lập file với nhau (`[P]`) — không phụ thuộc lẫn nhau, có thể làm song song hoặc theo thứ tự bất kỳ.
- T014–T016 chạy sau khi T002–T013 xong hết.

## Chiến lược triển khai

- Chỉ 1 user story (US1) — không có MVP con nhỏ hơn, PBI này là 1 lát cắt dọn nội bộ trọn vẹn.
- Thứ tự khuyến nghị: T001 → (T002…T013 song song theo file) → T014 → T015 → T016.
