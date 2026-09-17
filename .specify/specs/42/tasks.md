# Danh sách Task: Đường dẫn file tự động sao lưu

**Mã PBI**: 42
**Nguồn**: plan.md, spec.md, research.md, data-model.md, quickstart.md

## Pha 1: Setup

Không có — tái dùng toàn bộ hạ tầng backup đã có từ PBI 35 (không dependency mới, không file/thư mục mới).

## Pha 2: Foundational

- [X] T001 Thêm trường `lastBackupPath: String?` vào `BackupPrefs` tại `app/sora_thu_chi/lib/core/backup/backup_prefs.dart` (constructor, `toJson()`, `fromSettings()` kèm helper `_string()` cùng mẫu `_dateTime()`, `copyWith()`, `operator ==`, `hashCode`)
- [X] T002 [P] Mở rộng `app/sora_thu_chi/test/backup_prefs_test.dart`: test round-trip `lastBackupPath` qua `toJson()`/`fromSettings()`, test `null` khi row cũ không có key này, test `copyWith()`/`==`/`hashCode` bao gồm trường mới

**Checkpoint**: `BackupPrefs` đọc/ghi được `lastBackupPath`, chưa có nơi nào gọi tới — chạy `flutter test test/backup_prefs_test.dart` xanh trước khi sang Pha 3.

## Pha 3: User Story 1 - Hiển thị đường dẫn file tự động sao lưu (Ưu tiên: P1)

**Mục tiêu**: Người dùng mở màn "Sao lưu & Khôi phục" thấy đường dẫn file của các bản sao lưu **tự động** (mục "Sao lưu gần nhất" + danh sách "Các bản sao lưu"); bản thủ công không đổi hành vi hiển thị.

**Tiêu chí kiểm thử độc lập**: Chạy `flutter test test/backup_controller_test.dart test/backup_restore_screen_test.dart` xanh, cộng QA tay theo `quickstart.md` (4 kịch bản A–D).

- [X] T003 [US1] Ghi `lastBackupPath: entry.path` vào `copyWith()` trong nhánh `updatePrefs: true` của `_writeBackup()` tại `app/sora_thu_chi/lib/core/backup/backup_controller.dart` (dòng ~91-95, backup thủ công)
- [X] T004 [US1] Ghi `lastBackupPath: entry.path` vào `prefs.copyWith()` cuối `_runAutoBackup()` tại `app/sora_thu_chi/lib/data/backup_scheduler_workmanager.dart` (dòng ~83-89, isolate nền tự động sao lưu)
- [X] T005 [P] [US1] Mở rộng `app/sora_thu_chi/test/backup_controller_test.dart`: sau khi gọi `createManualBackup()`, assert `controller.prefs.value.lastBackupPath` bằng đúng path file vừa ghi (dùng `FakeLocalBackupStore` có sẵn ở `test/fakes/fake_local_backup_store.dart`); thêm test `confirmRestore()` **không** đổi `lastBackupPath` cũ
- [X] T006 [US1] Sửa `_LastBackupCard` tại `app/sora_thu_chi/lib/screens/backup_restore_screen.dart`: nhận thêm `List<LocalBackupEntry> entries`, tra `entries.firstWhereOrNull((e) => e.path == prefs.lastBackupPath && e.isAuto)` (hoặc vòng lặp thuần không cần thêm package `collection` nếu chưa có sẵn — kiểm tra `pubspec.yaml` trước khi thêm import), nếu tìm thấy thì thêm 1 dòng `Text` hiển thị `entry.path` (style nhỏ giống dòng số liệu hiện có, `maxLines: 1` + `TextOverflow.ellipsis` theo R4) ngay dưới dòng số liệu tóm tắt; cập nhật lời gọi `_LastBackupCard(prefs: prefs, colors: colors)` ở `_body()` thành truyền thêm `entries: _controller.backups`
- [X] T007 [US1] Sửa `_BackupList` tại `app/sora_thu_chi/lib/screens/backup_restore_screen.dart`: với mỗi `entry.isAuto == true`, thêm 1 dòng `Text(entry.path)` (`maxLines: 1` + `TextOverflow.ellipsis`) ngay dưới dòng `formatDateTimeLabel + 'Tự động'` hiện có trong `Column` của item; bản thủ công (`entry.isAuto == false`) giữ nguyên không đổi
- [X] T008 [P] [US1] Mở rộng `app/sora_thu_chi/test/backup_restore_screen_test.dart`: (a) card hiện dòng path khi `lastBackupPath` khớp 1 entry `isAuto: true` trong danh sách; (b) card **không** hiện dòng path khi bản gần nhất là thủ công; (c) card **không** hiện dòng path khi `lastBackupPath` không khớp entry nào còn trong danh sách (đã bị dọn); (d) mỗi item `_BackupList` có `isAuto: true` hiện dòng path, item `isAuto: false` không hiện

**Checkpoint**: Toàn bộ test backup xanh (`flutter test test/backup_prefs_test.dart test/backup_controller_test.dart test/backup_restore_screen_test.dart`), `flutter analyze` sạch, QA tay 4 kịch bản `quickstart.md` đạt.

## Pha cuối: Polish & Cross-cutting

- [X] T009 Chạy toàn bộ `flutter analyze` + `flutter test` (cả bộ, không chỉ file backup) xác nhận không có test đỏ mới phát sinh ngoài baseline đã biết (nếu có test đỏ có sẵn từ trước, đối chiếu với memory `MEMORY.md` để phân biệt đúng cái mới/cũ)

## Sơ đồ phụ thuộc

- Pha 2 (T001, T002) phải xong trước Pha 3 — `BackupPrefs` cần có trường mới trước khi controller/scheduler/UI dùng tới.
- T003 và T004 độc lập nhau (2 file khác nhau, không phụ thuộc) nhưng cả hai phải xong trước T005/T006/T007/T008 vì test/UI cần dữ liệu `lastBackupPath` đã được ghi thật.
- T006 và T007 cùng sửa `backup_restore_screen.dart` — làm tuần tự trong cùng file, không đánh dấu `[P]` với nhau dù về mặt nghiệp vụ độc lập (card vs list).
- Chỉ 1 user story (P1) — không có story khác phụ thuộc chờ.

## Chiến lược triển khai

- MVP = toàn bộ User Story 1 (tính năng chỉ có 1 story, không chia nhỏ thêm được).
- Thứ tự làm: T001 → T002 (nền tảng `BackupPrefs`) → T003+T004 song song (2 nơi ghi) → T005 (test controller) → T006 → T007 (UI) → T008 (test UI) → T009 (rà soát toàn cục).
