# Danh sách Task: Chọn hành động cho bản sao lưu cũ

**Mã PBI**: 43
**Nguồn**: plan.md, spec.md, research.md, quickstart.md

## Định dạng task

`- [ ] [MãTask] [P?] [Story?] Mô tả kèm đường dẫn file`

## Pha 1: Foundational

*(Bắt buộc xong trước khi làm US1/US2 — dùng chung cho cả 2)*

- [X] T001 Thêm hàm dùng chung `defaultShareBackupFile(String path)` (dùng `SharePlus.instance.share(ShareParams(files: [XFile(path)]))`) tại `app/sora_thu_chi/lib/core/backup/backup_share.dart`
- [X] T002 Cập nhật `app/sora_thu_chi/lib/screens/backup_result_screen.dart`: xoá `_defaultShareBackupFile` cục bộ, dùng `defaultShareBackupFile` từ `backup_share.dart` làm giá trị mặc định của `shareFile`
- [X] T003 Thêm enum `_BackupEntryAction { share, restore }` và hàm `Future<_BackupEntryAction?> _showBackupEntryActionSheet(BuildContext context)` (bottom sheet 2 `ListTile`: "Chia sẻ file" icon `Icons.ios_share`/tương tự, "Khôi phục từ bản này" icon `Icons.settings_backup_restore`) tại `app/sora_thu_chi/lib/screens/backup_restore_screen.dart`

## Pha 2: User Story 1 - Chia sẻ file bản sao lưu cũ (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: Từ danh sách "CÁC BẢN SAO LƯU", người dùng chia sẻ được bất kỳ file backup nào (thủ công hoặc tự động) qua khay chia sẻ hệ thống, không đổi dữ liệu trên máy.
**Tiêu chí kiểm thử độc lập**: Chạm 1 bản trong danh sách → chọn "Chia sẻ file" → khay chia sẻ hệ thống mở đúng file đã chọn; dữ liệu/danh sách không đổi. Kiểm được độc lập kể cả khi US2 (khôi phục qua menu) chưa nối xong (hàng lúc đó tạm thời chưa có lựa chọn khôi phục cũng không ảnh hưởng US1).

- [X] T004 [US1] Đổi `_BackupList` (widget `onTap` truyền vào từ `_BackupRestoreScreenState._body`) tại `app/sora_thu_chi/lib/screens/backup_restore_screen.dart`: hàng `InkWell` không gọi thẳng `onTap(entry.path)` nữa, mà gọi hàm mới `_onTapBackupEntry(entry.path)` mở sheet hành động (T003) rồi phân nhánh theo lựa chọn
- [X] T005 [US1] Trong `_onTapBackupEntry`, nhánh `_BackupEntryAction.share`: gọi `widget.shareFile(path)` (thêm tham số `ShareBackupFile shareFile = defaultShareBackupFile` vào constructor `BackupRestoreScreen`, seam test giống `BackupResultScreen`), bọc `try/catch` lỗi đọc file → `_showError('Không tìm thấy file'.tr)` tại `app/sora_thu_chi/lib/screens/backup_restore_screen.dart`
- [X] T006 [P] [US1] Test "mở sheet hiện đúng 2 lựa chọn, không tự chạy hành động nào khi vừa mở" tại `app/sora_thu_chi/test/backup_restore_screen_test.dart`
- [X] T007 [P] [US1] Test "chọn 'Chia sẻ file' gọi đúng `shareFile` với path của bản đã chạm, không gọi `inspectBackupFile`/không mở `RestoreConfirmSheet`, danh sách/`prefs` controller không đổi" tại `app/sora_thu_chi/test/backup_restore_screen_test.dart`
- [X] T008 [US1] Test "chia sẻ bản tự động (`isAuto == true`) cũng gọi được `shareFile` bình thường, không bị chặn" tại `app/sora_thu_chi/test/backup_restore_screen_test.dart`
- [X] T009 [US1] Test "chọn 'Chia sẻ file' khi `shareFile` ném lỗi (giả lập file thiếu) → hiện thông báo lỗi rõ ràng, không crash" tại `app/sora_thu_chi/test/backup_restore_screen_test.dart`
- [X] T010 [US1] Test "đóng sheet không chọn gì (tap ra ngoài) → không gọi `shareFile` lẫn `inspectBackupFile`, dữ liệu/danh sách không đổi" tại `app/sora_thu_chi/test/backup_restore_screen_test.dart`
- [X] T011 [P] [US1] Cập nhật `app/sora_thu_chi/test/backup_result_screen_test.dart` cho phù hợp vị trí mới của hàm share mặc định (T002) nếu test cũ import/tham chiếu trực tiếp

## Pha 3: User Story 2 - Khôi phục từ danh sách qua menu hành động (Ưu tiên: P2)

**Mục tiêu**: Lối vào luồng khôi phục từ danh sách chuyển qua menu hành động (thay vì chạm-là-khôi-phục-ngay), nhưng toàn bộ luật bảo vệ của luồng khôi phục cũ (PBI 35) giữ nguyên 100%.
**Tiêu chí kiểm thử độc lập**: Chạm 1 bản → chọn "Khôi phục từ bản này" → đúng `RestoreConfirmSheet` hiện ra như trước đây (không rút gọn bước nào); có thể kiểm độc lập bằng cách chỉ cần T003+T004 đã xong (không phụ thuộc US1 hoàn tất).

- [X] T012 [US2] Trong `_onTapBackupEntry`, nhánh `_BackupEntryAction.restore`: gọi đúng `_startRestoreFlow(path)` hiện có (không đổi logic bên trong hàm đó) tại `app/sora_thu_chi/lib/screens/backup_restore_screen.dart`
- [X] T013 [P] [US2] Test "chọn 'Khôi phục từ bản này' → mở đúng `RestoreConfirmSheet` với tên file/ngày tạo/số liệu/banner cảnh báo/checkbox bắt buộc, giống hành vi cũ khi tap thẳng vào hàng" tại `app/sora_thu_chi/test/backup_restore_screen_test.dart`
- [X] T014 [US2] Test "chọn 'Khôi phục từ bản này' khi file đã bị xoá (`inspectBackupFile` ném lỗi) → hiện đúng thông báo lỗi có sẵn (`_restoreError`), không crash" tại `app/sora_thu_chi/test/backup_restore_screen_test.dart`

## Pha 4: Polish & Cross-cutting

- [X] T015 `flutter analyze` sạch tại `app/sora_thu_chi/`
- [X] T016 `flutter test` toàn bộ — xác nhận số test đỏ không tăng so với baseline hiện có (1 đỏ sẵn ở `transactions_dao_test`, PBI 11)
- [X] T017 QA tay theo `.specify/specs/43/quickstart.md` nhóm A–E trên emulator
- [X] T018 Dùng skill `sora-wiki` cập nhật `wiki-knowledge/` (mục "Sao lưu & Khôi phục" trong page liên quan) + `wiki-knowledge/log.md` cho hành vi mới: chạm bản sao lưu mở menu Chia sẻ/Khôi phục thay vì khôi phục ngay

## Sơ đồ phụ thuộc

```text
Foundational (T001-T003) → US1 (T004-T011) → US2 (T012-T014) → Polish (T015-T018)
```

US2 chỉ cần T003+T004 (khung sheet + wiring `_onTapBackupEntry`) đã có, không cần đợi toàn bộ test US1 xong — nhưng theo thứ tự file, làm tuần tự US1 trước US2 là hợp lý nhất vì cùng chỉnh 1 file `backup_restore_screen.dart`.

## Ví dụ chạy song song

```text
# Trong US1, các task test sau có thể chạy cùng lúc (khác nhóm test case, cùng file nhưng độc lập về logic viết):
T006 [P] [US1] ...
T007 [P] [US1] ...
T011 [P] [US1] ... (khác file: backup_result_screen_test.dart)

# Trong US2:
T013 [P] [US2] ...
```

## Chiến lược triển khai

- **MVP**: User Story 1 (chia sẻ file bản cũ) — giá trị chính mà PBI 43 yêu cầu.
- **Giao hàng tăng dần**: Foundational → US1 (chia sẻ) → US2 (khôi phục qua menu, chủ yếu là nối lại lối vào cũ) → Polish.
