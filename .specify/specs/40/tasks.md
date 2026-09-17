# Danh sách Task: Nhân bản giao dịch

**Mã PBI**: 40
**Nguồn**: plan.md, spec.md, research.md, data-model.md, quickstart.md

## Pha 1: Setup

- [X] T001 Chạy `flutter test` tại `app/sora_thu_chi` để ghi nhận baseline (số test pass/đỏ hiện có) trước khi sửa, làm mốc so sánh ở T013. — Baseline: 1371/1371 pass, 0 đỏ.

## Pha 2: Foundational

Không có task nền tảng riêng cho PBI này — không thêm bảng/trường/dependency mới (xem `research.md` quyết định 1–4, `data-model.md`). Mỗi user story bên dưới tự chứa đủ thay đổi cần thiết.

## Pha 3: User Story 1 - Nhân bản giao dịch Thu/Chi (Ưu tiên: P1)

**Mục tiêu**: Nút "Nhân bản" ở màn Chi tiết giao dịch, với giao dịch loại Thu/Chi, mở màn Thêm giao dịch đã điền sẵn dữ liệu gốc (trừ ngày giờ = hiện tại), lưu tạo bản ghi mới độc lập, không đụng bản gốc.

**Tiêu chí kiểm thử độc lập**: Từ 1 giao dịch Chi có sẵn, bấm "Nhân bản" → sửa hoặc giữ nguyên → Lưu → xuất hiện giao dịch mới đúng dữ liệu, giao dịch gốc không đổi, số dư ví cập nhật đúng 1 lần (Kịch bản A/B/C trong `quickstart.md`).

- [X] T002 [P] [US1] ~~Viết test riêng trong `add_transaction_screen_test.dart`~~ — phủ qua test tích hợp T003 (điền sẵn + lưu qua `addTransaction`, giao dịch gốc không đổi được assert trực tiếp ở đó); không viết trùng.
- [X] T003 [P] [US1] Viết test: bấm "Nhân bản" ở màn Chi tiết cho giao dịch Thu/Chi → điều hướng sang `AddTransactionScreen` với `initialCategory`/`initialWallet`/`initialNote`/`initialTags`/`initialReceiptImage` đúng dữ liệu gốc và **không** truyền `editing` tại `app/sora_thu_chi/test/transaction_detail_screen_test.dart`.
- [X] T004 [US1] Thêm 5 tham số optional `initialAmount` (int?), `initialNote` (String?), `initialDate` (DateTime?), `initialTags` (String?), `initialReceiptImage` (String?) vào constructor `AddTransactionScreen` tại `app/sora_thu_chi/lib/screens/add_transaction_screen.dart` (cạnh `initialCategory`/`initialWallet` hiện có). Thêm `initialAmount` so với research.md — số tiền cũng cần điền sẵn (FR-003), sót khỏi kế hoạch ban đầu.
- [X] T005 [US1] Dùng các tham số `initial*` mới (T004) để khởi tạo `_amountCtrl`, `_date`, `_noteCtrl.text`, `_tags`/`_initialTags`, `_receiptImagePath`/`_originalReceiptImage`, và baseline `_isDirty` khi `editing == null`; giữ nguyên nhánh đọc trực tiếp từ `editing` khi sửa, tại `app/sora_thu_chi/lib/screens/add_transaction_screen.dart`. Mở rộng thêm `_originalReceiptImage` (không có trong research.md ban đầu) để ảnh nhân bản — vẫn được giao dịch gốc tham chiếu trong DB — không bị xóa nhầm khi đổi ảnh/hủy màn.
- [X] T006 [US1] Thêm method `_duplicate(view)` trong `app/sora_thu_chi/lib/screens/transaction_detail_screen.dart`, bám cấu trúc `_edit(view)` (dòng 167-255): tải `Transaction`/`Category`/`Wallet` gốc qua `ensureWalletRepository()`; nhánh `view.type != TxnType.transfer` push `AddTransactionScreen` với `initialCategory`/`initialWallet`/`initialAmount`/`initialNote`/`initialTags`/`initialReceiptImage` từ bản gốc, `initialDate: DateTime.now()`, **không** truyền `editing`.
- [X] T007 [US1] Gán `onPressed: () => _duplicate(view)` cho nút "Nhân bản" tại `app/sora_thu_chi/lib/screens/transaction_detail_screen.dart` dòng ~123 (thay `onPressed: () {}` hiện tại, xóa comment no-op FR-012).
- [X] T008 [US1] Chạy `flutter test test/add_transaction_screen_test.dart test/transaction_detail_screen_test.dart` xác nhận pass. QA tay Kịch bản A/B/C trong `quickstart.md` **chưa chạy trên emulator thật** (chỉ test tự động).

## Pha 4: User Story 2 - Nhân bản giao dịch Chuyển khoản (Ưu tiên: P2)

**Mục tiêu**: Nút "Nhân bản" với giao dịch loại Chuyển khoản mở màn Chuyển tiền đã điền sẵn ví nguồn/đích/số tiền/ghi chú (trừ ngày giờ = hiện tại), lưu tạo giao dịch chuyển khoản mới độc lập.

**Tiêu chí kiểm thử độc lập**: Từ 1 giao dịch Chuyển khoản có sẵn, bấm "Nhân bản" → Lưu → xuất hiện giao dịch chuyển khoản mới (group id mới), giao dịch gốc không đổi, số dư 2 ví cập nhật đúng (Kịch bản D trong `quickstart.md`).

- [X] T009 [P] [US2] Viết test: bấm "Nhân bản" cho giao dịch Chuyển khoản → điều hướng sang `WalletTransferScreen` với `sourceWallet`/`destinationWallet`/`initialAmount`/`initialNote` đúng dữ liệu gốc, `initialDate` = hiện tại, và **không** truyền `editingTransferGroupId` tại `app/sora_thu_chi/test/transaction_detail_screen_test.dart` — assert 4 vế (2 gốc + 2 mới), vế gốc không đổi.
- [X] T010 [P] [US2] ~~Viết test riêng trong `wallet_transfer_screen_test.dart`~~ — đã có coverage tương đương end-to-end ở T009 (xác nhận `WalletController.transfer` được gọi, không phải `updateTransfer`, qua số vế transfer tăng gấp đôi); không viết trùng.
- [X] T011 [US2] Mở rộng `_duplicate(view)` (từ T006) nhánh `view.type == TxnType.transfer`: push `WalletTransferScreen` với `sourceWallet`, `destinationWallet`, `initialAmount`, `initialNote` từ bản gốc, `initialDate: DateTime.now()`, **không** truyền `editingTransferGroupId`, tại `app/sora_thu_chi/lib/screens/transaction_detail_screen.dart`.
- [X] T012 [US2] Chạy `flutter test test/wallet_transfer_screen_test.dart test/transaction_detail_screen_test.dart` xác nhận pass. QA tay Kịch bản D trong `quickstart.md` **chưa chạy trên emulator thật** (chỉ test tự động).

## Pha cuối: Polish & Cross-cutting

- [X] T013 Chạy toàn bộ `flutter test` + `flutter analyze` tại `app/sora_thu_chi`, đối chiếu với baseline T001 — không phát sinh test đỏ mới, analyze sạch. — Kết quả: 1373/1373 pass (baseline 1371 + 2 test mới), 0 đỏ, analyze sạch. Phát sinh sửa ngoài kế hoạch: thêm bản dịch `en` cho snackbar lỗi mới trong `sora_translations.dart` (test `sora_translations_test.dart` bắt được thiếu bản dịch).
- [X] T014 Cập nhật `wiki-knowledge/entity/Giao dịch.md` mục "Sửa / xóa / nhân bản" — chuyển "Nhân bản (Duplicate)" từ trạng thái "chưa triển khai" sang đã triển khai (PBI 40, tóm tắt cơ chế điền-sẵn-không-liên-kết), dùng skill `sora-wiki`.
- [X] T015 Cập nhật `wiki-knowledge/concept/Lộ trình phát triển.md` — ghi nhận "Nhân bản giao dịch (PBI 40) — đã triển khai" trong phần ghi chú giai đoạn/quyết định mở liên quan, dùng skill `sora-wiki`.
- [X] T016 Append `wiki-knowledge/log.md` ghi nhận đợt cập nhật wiki cho PBI 40, dùng skill `sora-wiki`. Cũng cập nhật `index.md`.

## Sơ đồ phụ thuộc

- Pha 1 (T001) → chạy trước tất cả.
- Pha 3 (US1: T002-T008) độc lập, có thể triển khai và release riêng như MVP.
- Pha 4 (US2: T009-T012) phụ thuộc T006 (cùng sửa method `_duplicate` trong `transaction_detail_screen.dart`) — nên làm **sau** T006, có thể song song với T007/T008 nếu cẩn thận tránh xung đột merge trên cùng file, nhưng an toàn nhất là làm tuần tự sau khi US1 xong.
- Pha cuối (T013-T016) chạy sau khi cả US1 và US2 hoàn tất.

Trong mỗi story, cặp task test (T002+T003, T009+T010) có thể chạy song song `[P]` vì khác file nhau; các task sửa code chung 1 file (T004→T005, T006→T007→T011) phải làm tuần tự.

## Chiến lược triển khai

- **MVP đề xuất**: User Story 1 (Nhân bản Thu/Chi) — chiếm phần lớn tần suất dùng thực tế theo mô tả nghiệp vụ gốc (đổ xăng, đi chợ).
- **Thứ tự giao hàng tăng dần**: Setup (T001) → US1 (T002-T008, release được ngay) → US2 (T009-T012, bổ sung Chuyển khoản) → Polish/wiki (T013-T016).
