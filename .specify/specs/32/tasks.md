# Danh sách Task: Loại bỏ dữ liệu mẫu khi cài mới

**Mã PBI**: 32
**Nguồn**: plan.md, spec.md, research.md, quickstart.md

## Định dạng task

`- [ ] [MãTask] [P?] [Story?] Mô tả kèm đường dẫn file`

- `[P]`: có thể chạy song song (khác file, không phụ thuộc task chưa xong)
- `[Story]`: bắt buộc ở pha User Story (VD `[US1]`), không dùng ở Setup/Foundational/Polish

## Pha 1: Setup

*(Không cần — sửa trực tiếp trên project Flutter hiện có, không thêm dependency/cấu trúc mới)*

## Pha 2: Foundational

- [X] T001 Gỡ lệnh gọi `_seedSampleWallets()` và `_seedSampleTransactions()` khỏi `onCreate` (dòng ~211-216) và gỡ lệnh gọi `_seedSampleTransactions()` khỏi nhánh `onUpgrade from < 2` (dòng ~227-229) trong [app/sora_thu_chi/lib/data/db/app_database.dart](../../../app/sora_thu_chi/lib/data/db/app_database.dart); giữ nguyên `_seedCategories()` ở cả hai chỗ.
- [X] T002 Xoá hẳn 2 hàm `_seedSampleWallets()` (dòng ~324-345) và `_seedSampleTransactions()` (dòng ~347-...) cùng doc-comment liên quan (dòng ~21, ~71-72) trong [app/sora_thu_chi/lib/data/db/app_database.dart](../../../app/sora_thu_chi/lib/data/db/app_database.dart); xoá import `WalletSource`/`TransactionSource` nếu không còn dùng nơi nào khác trong file.
- [X] T003 Chạy `flutter analyze` tại `app/sora_thu_chi/` xác nhận sạch sau khi gỡ seed (không còn import/hàm thừa).

## Pha 3: User Story 1 - Cài mới sạch, không ví/giao dịch mẫu (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: Cài app lần đầu trên thiết bị sạch chỉ có danh mục mặc định, 0 ví, 0 giao dịch (FR-001, FR-002, FR-003, SC-001, SC-002).
**Tiêu chí kiểm thử độc lập**: Uninstall app trên emulator, `flutter run` lại, vào màn Ví/Giao dịch thấy danh sách trống, vào Cài đặt → Danh mục vẫn thấy đủ danh mục mặc định.

- [X] T004 [US1] Sửa `test/wallets_dao_test.dart`: bỏ assertion phụ thuộc 5 ví/11 giao dịch seed sẵn (dòng ~24, ~34, ~89, ~99, ~140-157) — đổi sang tự `insert` dữ liệu test cần thiết trong từng test, hoặc assert đúng trạng thái "0 ví/0 giao dịch" sau `onCreate`/`onUpgrade` mới.
- [X] T005 [US1] Sửa `test/budgets_dao_test.dart`: bỏ assertion `loadAll().length == 5` / `allTransactions().length == 11` (dòng ~140-157, ~342-349) — chuyển sang tự chèn fixture ví/giao dịch cần cho từng test.
- [X] T006 [US1] Chạy `flutter test` tại `app/sora_thu_chi/`, rà và sửa tiếp mọi file test khác báo đỏ vì ngầm định có sẵn ví/giao dịch seed (theo lỗi thực tế, không đoán trước danh sách).
- [X] T007 [US1] QA tay theo `quickstart.md` mục A bước 1-3, 7, 9: uninstall app trên emulator, cài lại, xác nhận màn Tổng quan 0 ví/0 giao dịch không lỗi, Cài đặt → Danh mục vẫn đủ danh mục mặc định, tạo ví + giao dịch mới hoạt động bình thường.

## Pha 4: User Story 2 - Màn hình xử lý đúng trạng thái rỗng (Ưu tiên: P2)

**Mục tiêu**: Mọi màn phụ thuộc ví/giao dịch hiển thị đúng trạng thái rỗng, không lỗi, và luồng thêm giao dịch dẫn người dùng tạo ví trước khi chưa có ví nào (FR-004, FR-005, SC-003).
**Tiêu chí kiểm thử độc lập**: Trên thiết bị cài mới (0 ví), lần lượt vào Tổng quan/Ví/Giao dịch/Báo cáo/Ngân sách và bấm FAB thêm giao dịch — không màn nào lỗi hoặc crash.

- [X] T008 [US2] QA tay theo `quickstart.md` mục A bước 4-6, 8: màn Ví trống có lối tạo ví mới, màn Giao dịch đúng trạng thái rỗng, bấm FAB "Thêm giao dịch" khi chưa có ví dẫn tới tạo ví trước (không crash, không chọn ví rỗng ngầm định), màn Báo cáo/Ngân sách đúng trạng thái rỗng không lỗi.
- [X] T009 [US2] Nếu T008 phát hiện màn nào lỗi/crash ở trạng thái rỗng: sửa trực tiếp tại file màn hình tương ứng (xác định cụ thể theo lỗi thực tế phát sinh), rồi lặp lại QA bước đó tới khi đạt. — Không phát hiện lỗi/crash nào ở T008 (mọi màn xử lý đúng trạng thái rỗng sẵn có); không cần sửa.

## Pha 5: User Story 3 - Nâng cấp giữ nguyên dữ liệu đã có (Ưu tiên: P3)

**Mục tiêu**: Thiết bị nâng cấp từ bản cũ (đã có ví/giao dịch, kể cả dữ liệu mẫu cũ) không bị tự động xoá dữ liệu (FR-006, SC-004).
**Tiêu chí kiểm thử độc lập**: Cài bản trước PBI 32 tạo dữ liệu mẫu + dữ liệu thật, cài đè bản sau PBI 32, xác nhận toàn bộ dữ liệu cũ còn nguyên.

- [X] T010 [US3] QA tay theo `quickstart.md` mục B: cài bản app trước PBI 32 (checkout commit trước khi gỡ seed, build cài lên emulator) để tạo DB có 5 ví/11 giao dịch mẫu, tự tạo thêm 1 ví + 1 giao dịch thật, sau đó cài đè bản sau PBI 32 (không uninstall) và xác nhận toàn bộ ví/giao dịch cũ (mẫu + thật) vẫn còn nguyên, không phát sinh thêm dữ liệu mới ngoài ý muốn.

## Pha cuối: Polish & Cross-cutting

- [X] T011 Chạy hồi quy đầy đủ theo `quickstart.md` mục C: `flutter analyze` sạch, `flutter test` toàn bộ pass tại `app/sora_thu_chi/`.

## Sơ đồ phụ thuộc

```text
Foundational (T001-T003) → US1 (T004-T007) → US2 (T008-T009) → US3 (T010) → Polish (T011)
```

US2/US3 chỉ QA tay, không phụ thuộc code lẫn nhau — có thể đổi thứ tự QA nếu thuận tiện hơn cho môi trường test, nhưng T001-T007 (gỡ seed + sửa test) phải xong trước cả hai.

## Ví dụ chạy song song

```text
# Trong Foundational, có thể làm song song:
T001 (onCreate/onUpgrade) và T002 (xoá hàm/import) đều sửa cùng 1 file → làm tuần tự, không song song.

# Trong US1, T004 và T005 sửa 2 file test khác nhau → chạy song song được:
T004 [US1] sửa test/wallets_dao_test.dart
T005 [US1] sửa test/budgets_dao_test.dart
```

## Chiến lược triển khai

- **MVP**: US1 (T001-T007) — đã thoả FR-001/002/003, SC-001/002, là phần lõi của PBI.
- **Giao hàng tăng dần**: US1 (gỡ seed + test xanh) → US2 (QA màn rỗng, vá nếu lộ lỗi) → US3 (QA nâng cấp không mất dữ liệu) → Polish (hồi quy toàn bộ).
