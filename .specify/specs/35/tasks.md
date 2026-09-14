# Danh sách Task: Sao lưu & Khôi phục dữ liệu

**Mã PBI**: 35
**Nguồn**: spec.md, plan.md, data-model.md, research.md, quickstart.md

**Lưu ý lệch cấu trúc thư mục so với `plan.md`**: `plan.md` đề xuất `lib/ui/settings/backup/` — codebase thật dùng cấu trúc phẳng `lib/screens/*.dart` (không có `lib/ui/`), domain thuần ở `lib/core/<module>/`, impl seam (Drift/plugin) ở `lib/data/`, test phẳng ở `test/*.dart` (đối chiếu `lib/core/notification/`, `lib/screens/notification_settings_screen.dart`, `lib/data/notification_deps.dart`). Các task dưới đây theo đúng cấu trúc thật của repo, không theo cây thư mục gợi ý trong `plan.md`.

## Pha 1: Setup

- [X] T001 Thêm dependency `file_picker`, `cryptography`, `workmanager` vào `dependencies` và chuyển `archive: ^4.0.9` từ `dev_dependencies` sang `dependencies` trong `app/sora_thu_chi/pubspec.yaml`; chạy `flutter pub get`.
- [X] T002 Tạo thư mục `app/sora_thu_chi/lib/core/backup/` (domain thuần + seam) — không cần file rỗng, tạo cùng lúc với T003.

## Pha 2: Foundational (bắt buộc trước mọi User Story)

- [X] T003 [P] Tạo `BackupPrefs` (domain thuần, theo khuôn `NotificationPrefs`) tại `app/sora_thu_chi/lib/core/backup/backup_prefs.dart`: trường `autoEnabled`, `autoFrequency` (enum `daily/weekly/monthly`), `maxKeepLocal` (mặc định `5`, hằng số nghiệp vụ không đổi qua UI), `lastBackupAt`, `lastBackupCounts`, `lastBackupSizeBytes`; `toSettings()`/`fromSettings()` 1 row JSON `backupPrefs` trong `AppSettings` (parse tolerant như `NotificationPrefs.fromSettings`), `copyWith`, `==`/`hashCode`.
- [X] T004 [P] Viết test `BackupPrefs` tại `app/sora_thu_chi/test/backup_prefs_test.dart`: default khi row vắng, JSON hỏng → default, từng trường sai kiểu/ngoài miền → default riêng trường đó, roundtrip `toSettings`/`fromSettings`, `copyWith` chỉ đổi trường truyền vào.
- [X] T005 [P] Tạo seam `BackupPrefsStore` (theo khuôn `NotificationStore`) tại `app/sora_thu_chi/lib/core/backup/backup_prefs_store.dart`: `Future<BackupPrefs> load()`, `Future<void> save(BackupPrefs prefs)`.
- [X] T006 [P] Tạo `BackupFileMeta` tại `app/sora_thu_chi/lib/core/backup/backup_file_meta.dart`: trường `schemaVersion`, `appVersion`, `exportedAt`, `currencyDefault`, `counts` (Map<String,int>), `hasAttachments`, `checksum`, `hasPassword`; hàm `isSchemaSupported(int currentSupported)`.
- [X] T007 [P] Tạo `BackupData` tại `app/sora_thu_chi/lib/core/backup/backup_data.dart`: snapshot tuần tự hoá 1-1 các bảng hiện có (`wallets`, `categories`, `transactions`, `budgets`, `app_settings`...) theo schema JSON ở `docs/backup/giai-phap-dong-bo-sao-luu-du-lieu.md §3`; giữ nguyên `id` gốc mọi bản ghi; `toJson()`/`fromJson()` thuần Dart, không phụ thuộc drift.
- [X] T008 [P] Viết test `BackupData` tại `app/sora_thu_chi/test/backup_data_test.dart`: roundtrip `toJson`/`fromJson` giữ nguyên `id` và quan hệ khoá ngoại giữa ví/danh mục/giao dịch.
- [X] T009 Tạo `BackupCrypto` (seam mã hoá) tại `app/sora_thu_chi/lib/core/backup/backup_crypto.dart`: `abstract class BackupCrypto` với `Future<String> encrypt(String plaintext, String password)`, `Future<String> decrypt(String ciphertext, String password)`; impl thật `CryptographyBackupCrypto` dùng `package:cryptography` (AES-256-GCM + `Pbkdf2HmacSha256`, salt/nonce ngẫu nhiên lưu kèm ciphertext) trong cùng file hoặc file `app/sora_thu_chi/lib/data/backup_crypto_cryptography.dart`.
- [X] T010 [P] Viết test `BackupCrypto` tại `app/sora_thu_chi/test/backup_crypto_test.dart`: encrypt→decrypt đúng mật khẩu ra nguyên văn, sai mật khẩu ném lỗi rõ ràng (không trả dữ liệu rác), dùng fake/thật `CryptographyBackupCrypto` trực tiếp (pure Dart, không cần platform channel).
- [X] T011 Tạo `BackupWriter` tại `app/sora_thu_chi/lib/core/backup/backup_writer.dart`: hàm thuần Dart build nội dung file từ `BackupData` + tuỳ chọn `password` — JSON thuần (`meta` + `data`) khi không có ảnh đính kèm, gói `.zip` (`archive`, `data.json` + `/images/`) khi có; tính `checksum` SHA-256 (`package:crypto`) trên phần `data` trước khi mã hoá; chạy trong `compute()` khi gọi từ UI thread (không tự gọi `compute` bên trong hàm thuần, để test gọi trực tiếp).
- [X] T012 [P] Viết test `BackupWriter` tại `app/sora_thu_chi/test/backup_writer_test.dart`: không ảnh → `.json`, có ảnh → `.zip` đúng cấu trúc `data.json` + `/images/`, `checksum` khớp SHA-256 tính lại, có `password` → phần `data` đã mã hoá (không đọc được nguyên văn).
- [X] T013 Tạo `BackupReader` tại `app/sora_thu_chi/lib/core/backup/backup_reader.dart`: đọc file (`.json`/`.zip`) → `BackupFileMeta` (đọc nhanh, không giải mã `data` nếu không cần); hàm `readMeta(List<int> bytes)` trả lỗi rõ ràng khi sai định dạng/hỏng; hàm `readFullData(List<int> bytes, {String? password})` giải mã (nếu có mật khẩu) + validate `checksum` sau giải mã + gọi `migrateBackupSchema` trước khi trả `BackupData`.
- [X] T014 Tạo `migrateBackupSchema(int from, Map<String, Object?> json)` tại `app/sora_thu_chi/lib/core/backup/backup_schema_migration.dart`: khung rỗng trả nguyên trạng khi `from == phiên bản hiện tại` (hiện chỉ có v1), có `switch` sẵn chỗ mở rộng theo version sau.
- [X] T015 [P] Viết test `BackupReader` + migration tại `app/sora_thu_chi/test/backup_reader_test.dart`: file hợp lệ không mật khẩu đọc đúng meta+data; file có mật khẩu → `readMeta` không cần password, `readFullData` cần đúng password mới giải mã được; sai 1 byte (checksum sai) → lỗi rõ ràng; `schema_version` lớn hơn hỗ trợ → lỗi "không tương thích"; JSON không đúng cấu trúc → lỗi rõ ràng, không throw kiểu bắt được (crash).
- [X] T016 [P] Tạo `LocalBackupEntry` + seam `LocalBackupStore` tại `app/sora_thu_chi/lib/core/backup/local_backup_store.dart`: `LocalBackupEntry` (`path`, `fileName`, `sizeBytes`, `createdAt`, `isAuto`, `hasAttachments`); `abstract class LocalBackupStore` với `Future<List<LocalBackupEntry>> list()`, `Future<void> delete(String path)`, `Future<void> cleanupOldSafetySnapshots({Duration maxAge = const Duration(hours: 24)})`.
- [X] T017 Tạo impl `FileSystemLocalBackupStore` tại `app/sora_thu_chi/lib/data/local_backup_store_file_system.dart`: liệt kê `app_documents/backups/manual/`, `backups/auto/`, `backups/_safety/` (dùng `path_provider` đã có); `isAuto`/`hasAttachments` suy từ thư mục con/đuôi file; ghi file theo mẫu ghi-tạm-rồi-`rename` (R6) — bắt `FileSystemException`, xoá file tạm, ném lỗi rõ ràng khi ghi lỗi/hết dung lượng.
- [X] T018 [P] Viết test `FileSystemLocalBackupStore` tại `app/sora_thu_chi/test/local_backup_store_test.dart` (dùng thư mục tạm test, không cần plugin thật): liệt kê đúng theo thư mục con, xoá đúng file, dọn file `_safety/` quá 24h, mô phỏng ghi lỗi giữa chừng không để lại file dở (kiểm tra không còn file tạm sau khi bắt lỗi).
- [X] T019 Tạo `Deps` singleton tại `app/sora_thu_chi/lib/data/backup_deps.dart` (theo khuôn `notification_deps.dart`): `ensureBackupPrefsStore()`, `ensureLocalBackupStore()`, `ensureBackupCrypto()` — đăng ký impl Drift/FileSystem/Cryptography thật qua GetX `Get.put`/`Get.find` nếu chưa có.
- [X] T020 Tạo impl `DriftBackupPrefsStore` tại `app/sora_thu_chi/lib/data/backup_prefs_store_drift.dart`: đọc/ghi row `backupPrefs` qua `AppSettings` DAO đã có (không thêm bảng, không migration schema — schema giữ v10).

**Điểm kiểm tra**: `flutter analyze` sạch, `flutter test test/backup_prefs_test.dart test/backup_data_test.dart test/backup_crypto_test.dart test/backup_writer_test.dart test/backup_reader_test.dart test/local_backup_store_test.dart` pass. Foundational xong — sẵn sàng cho mọi User Story.

## Pha 3: User Story 1 - Sao lưu thủ công (Ưu tiên: P1)

**Mục tiêu**: Người dùng vào Cài đặt → "Sao lưu & Khôi phục" → tạo bản sao lưu thủ công (tuỳ chọn mật khẩu) → chia sẻ file qua share sheet hệ thống → thấy màn thành công → thẻ "Sao lưu gần nhất" và danh sách "Các bản sao lưu" cập nhật đúng (FR-001…FR-005, FR-008, FR-009, FR-018).

**Tiêu chí kiểm thử độc lập**: Từ Cài đặt mở màn mới, tạo 1 bản sao lưu (có và không mật khẩu), xác nhận file xuất hiện trong danh sách + thẻ "Sao lưu gần nhất" đúng số liệu — độc lập với luồng khôi phục.

- [X] T021 [US1] Tạo `BackupSummary` (số liệu tóm tắt trước khi tạo) tại `app/sora_thu_chi/lib/core/backup/backup_summary.dart`: hàm thuần đếm số ví/danh mục/giao dịch hiện có + ước tính dung lượng (dựa trên số bản ghi, không cần build file thật trước).
- [X] T022 [US1] Tạo `BackupController` (GetX, theo khuôn `ScanController`/`ReportController`) tại `app/sora_thu_chi/lib/core/backup/backup_controller.dart`: `Rx<BackupPrefs>` từ `ensureBackupPrefsStore()`, `Rx<List<LocalBackupEntry>>` từ `ensureLocalBackupStore()`, hàm `createManualBackup({String? password})` gọi `BackupWriter` trong `compute()`, ghi file qua `LocalBackupStore`, cập nhật `BackupPrefs.lastBackupAt/lastBackupCounts/lastBackupSizeBytes`, trả về path file vừa tạo.
- [X] T023 [P] [US1] Viết test `BackupController` (fake `BackupPrefsStore`/`LocalBackupStore`/`BackupCrypto`) tại `app/sora_thu_chi/test/backup_controller_test.dart`: `createManualBackup` cập nhật đúng `lastBackup*`, danh sách bản sao lưu có thêm 1 phần tử, có `password` → gọi `BackupCrypto.encrypt`.
- [X] T024 [US1] Tạo màn `BackupRestoreScreen` (màn 01, mockup `docs/backup/01-man-hinh-sao-luu-khoi-phuc.svg`) tại `app/sora_thu_chi/lib/screens/backup_restore_screen.dart`: thẻ "Sao lưu gần nhất" (thời điểm + số liệu, đọc `BackupController`), nút "Tạo bản sao lưu mới", nút "Chọn file khôi phục" (điểm vào, nối ở US2), khối công tắc "Tự động sao lưu" (điểm vào, nối ở US3), danh sách "Các bản sao lưu" (trạng thái rỗng khi chưa có bản nào — FR-009).
- [X] T025 [US1] Tạo bottom sheet `CreateBackupSheet` (màn 02, mockup `02-bottom-sheet-tao-sao-luu.svg`) tại `app/sora_thu_chi/lib/screens/create_backup_sheet.dart`: hiển thị `BackupSummary`, công tắc "Đặt mật khẩu bảo vệ file" + ô nhập mật khẩu khi bật, nút "Tạo & Chia sẻ" gọi `BackupController.createManualBackup` rồi `share_plus` (tái dùng seam `ShareExport`/tương đương ở `lib/core/report/export_share.dart` hoặc gọi trực tiếp `Share.shareXFiles`), điều hướng sang `BackupResultScreen` khi xong.
- [X] T026 [US1] Tạo màn `BackupResultScreen` (màn 04, mockup `04-man-hinh-thanh-cong.svg`) tại `app/sora_thu_chi/lib/screens/backup_result_screen.dart`: tham số `mode` (`backup`/`restore`) quyết định nội dung + hành động chính (backup → tuỳ chọn "Chia sẻ lại file" FR-018; restore → nối ở US2 điều hướng về Tổng quan).
- [X] T027 [US1] Nối điểm vào từ `SettingsScreen`: thêm hàng "Sao lưu & Khôi phục" trong nhóm "KHÁC" tại `app/sora_thu_chi/lib/screens/settings_screen.dart` (theo khuôn `_openManageNotifications`/seam `onManageBackupTap`), điều hướng `MaterialPageRoute` sang `BackupRestoreScreen`.
- [X] T028 [P] [US1] Viết test widget `BackupRestoreScreen` tại `app/sora_thu_chi/test/backup_restore_screen_test.dart`: hiển thị đúng thẻ "Sao lưu gần nhất" (kể cả trạng thái chưa từng sao lưu), danh sách rỗng khi chưa có bản nào, chạm "Tạo bản sao lưu mới" mở `CreateBackupSheet`.
- [X] T029 [P] [US1] Viết test widget `CreateBackupSheet` tại `app/sora_thu_chi/test/create_backup_sheet_test.dart`: hiện đúng số liệu tóm tắt, bật công tắc mật khẩu hiện ô nhập, chạm "Tạo & Chia sẻ" gọi đúng `BackupController.createManualBackup` với `password` tương ứng.
- [X] T030 [P] [US1] Viết test widget `BackupResultScreen` (mode `backup`) tại `app/sora_thu_chi/test/backup_result_screen_test.dart`: hiện nút "Chia sẻ lại file" khi `mode == backup`.
- [X] T031 [US1] Viết test cập nhật `settings_screen_test.dart` (file test hiện có) tại `app/sora_thu_chi/test/settings_screen_test.dart`: hàng "Sao lưu & Khôi phục" điều hướng đúng sang `BackupRestoreScreen` (dùng seam callback như các hàng khác).

**Điểm kiểm tra**: `flutter test` toàn bộ pass; QA tay theo `quickstart.md` mục 2–3 (sao lưu thủ công, có/không mật khẩu) đạt.

## Pha 4: User Story 2 - Khôi phục dữ liệu (Ưu tiên: P2)

**Mục tiêu**: Người dùng chọn file (từ máy hoặc danh sách cục bộ) → xem tóm tắt (sau khi nhập đúng mật khẩu nếu có) → tick xác nhận bắt buộc → hệ thống tự snapshot an toàn rồi ghi đè toàn phần-hoặc-không → màn thành công → về Tổng quan (FR-010…FR-017).

**Tiêu chí kiểm thử độc lập**: Từ màn 01, chọn 1 file backup hợp lệ đã tạo ở US1, xác nhận tick bắt buộc, khôi phục thành công và dữ liệu Tổng quan khớp đúng nội dung file — độc lập với việc bật tự động sao lưu (US3).

- [X] T032 [US2] Tạo `BackupRestorer` tại `app/sora_thu_chi/lib/core/backup/backup_restorer.dart`: hàm `restore(BackupData data)` chạy trong **1** `db.transaction()` duy nhất (theo pattern PBI 24) — xoá dữ liệu các bảng liên quan rồi ghi lại từ `BackupData`, giữ nguyên `id` gốc; ném lỗi để transaction tự rollback nếu có bước ghi lỗi (FR-015).
- [X] T033 [P] [US2] Viết test `BackupRestorer` (drift in-memory) tại `app/sora_thu_chi/test/backup_restorer_test.dart`: restore thành công thay thế đúng toàn bộ dữ liệu cũ bằng dữ liệu mới; giả lập lỗi giữa chừng (VD ràng buộc khoá ngoại sai) → dữ liệu cũ **không** bị mất một phần (rollback).
- [X] T034 [US2] Bổ sung `BackupController`: hàm `pickRestoreFile()` (dùng `file_picker`, lọc `.json`/`.zip`), `inspectBackupFile(String path)` gọi `BackupReader.readMeta` trả `BackupFileMeta` hoặc lỗi, `confirmRestore({required String path, String? password})` — gọi safety-snapshot (tái dùng `createManualBackup`-style ghi vào `backups/_safety/`, không mật khẩu, không share) rồi `BackupReader.readFullData` + `BackupRestorer.restore` + cập nhật `BackupPrefs.lastBackup*`.
- [X] T035 [P] [US2] Viết test bổ sung `BackupController` (restore) tại `app/sora_thu_chi/test/backup_controller_test.dart`: file hỏng/checksum sai → `inspectBackupFile` trả lỗi, không tạo safety-snapshot; file hợp lệ → `confirmRestore` tạo đúng 1 safety-snapshot trước khi ghi đè; file `schema_version` không tương thích → lỗi rõ ràng.
- [X] T036 [US2] Tạo bottom sheet `RestoreConfirmSheet` (màn 03, mockup `03-bottom-sheet-xac-nhan-khoi-phuc.svg`) tại `app/sora_thu_chi/lib/screens/restore_confirm_sheet.dart`: hiển thị tên file/thời điểm tạo/số liệu tóm tắt, banner cảnh báo màu coral "dữ liệu hiện tại sẽ bị ghi đè hoàn toàn", checkbox "Tôi hiểu và muốn tiếp tục" (nút khôi phục vô hiệu khi chưa tick — FR-013), gọi `BackupController.confirmRestore` khi chạm nút, điều hướng sang `BackupResultScreen(mode: restore)` rồi về Tổng quan (FR-017).
- [X] T037 [US2] Tạo ô nhập mật khẩu cho file có bảo vệ: widget `_PasswordPromptSheet` hoặc mở rộng `RestoreConfirmSheet` tại cùng file `restore_confirm_sheet.dart` — không hiển thị bất kỳ số liệu tóm tắt nào cho tới khi giải mã đúng mật khẩu (FR-016); nhập sai → vẫn cho thử lại, độ trễ tăng dần (VD `Future.delayed` nhân đôi mỗi lần sai, có trần hợp lý) theo `_PasswordAttemptDelay` tại `app/sora_thu_chi/lib/core/backup/backup_password_attempt.dart`.
- [X] T038 [P] [US2] Viết test `_PasswordAttemptDelay`/`backup_password_attempt.dart` tại `app/sora_thu_chi/test/backup_password_attempt_test.dart`: độ trễ tăng dần theo số lần sai liên tiếp, reset về 0 sau lần đúng.
- [X] T039 [US2] Nối `BackupRestoreScreen`: nút "Chọn file khôi phục" gọi `pickRestoreFile` → `inspectBackupFile`; file hỏng/không tương thích → `SnackBar`/dialog báo lỗi rõ ràng, **không** mở `RestoreConfirmSheet` (FR-012); file hợp lệ → mở `RestoreConfirmSheet`. Chạm 1 dòng trong danh sách "Các bản sao lưu" cũng khởi động cùng luồng (FR-010).
- [X] T040 [P] [US2] Viết test widget `RestoreConfirmSheet` tại `app/sora_thu_chi/test/restore_confirm_sheet_test.dart`: nút khôi phục vô hiệu khi chưa tick, bật sau khi tick; file có mật khẩu → không hiện số liệu tóm tắt trước khi nhập đúng mật khẩu; nhập sai nhiều lần vẫn cho thử lại.
- [X] T041 [P] [US2] Viết test widget cập nhật `BackupRestoreScreen` (restore) tại `app/sora_thu_chi/test/backup_restore_screen_test.dart`: chọn file hỏng → hiện lỗi, không mở bottom sheet; chọn file hợp lệ → mở `RestoreConfirmSheet` đúng dữ liệu.
- [X] T042 [P] [US2] Viết test widget `BackupResultScreen` (mode `restore`) tại `app/sora_thu_chi/test/backup_result_screen_test.dart`: chạm nút chính điều hướng về Tổng quan (dùng seam callback như các màn thành công khác trong repo).

**Điểm kiểm tra**: `flutter test` pass; QA tay theo `quickstart.md` mục 5–8 (khôi phục thành công, mật khẩu, file hỏng/không tương thích, safety-snapshot) đạt.

## Pha 5: User Story 3 - Tự động sao lưu (Ưu tiên: P3)

**Mục tiêu**: Người dùng bật "Tự động sao lưu", chọn tần suất → hệ thống tự tạo file backup nội bộ theo lịch (không mở share sheet), tự dọn bản cũ vượt quá `maxKeepLocal`, gửi thông báo nhẹ xác nhận (FR-006, FR-007).

**Tiêu chí kiểm thử độc lập**: Bật công tắc, chọn tần suất, xác nhận cấu hình được lưu và giữ nguyên khi thoát/mở lại màn — không cần chờ lịch chạy thật để coi là "test được" (theo `quickstart.md` mục 4, QA lịch chạy thật để riêng sau khi có build thật do giới hạn nền iOS — R7).

- [X] T043 [US3] Tạo seam `BackupScheduler` tại `app/sora_thu_chi/lib/core/backup/backup_scheduler.dart`: `abstract class BackupScheduler` với `Future<void> schedule(BackupFrequency frequency)`, `Future<void> cancel()`.
- [X] T044 [US3] Tạo impl `WorkmanagerBackupScheduler` tại `app/sora_thu_chi/lib/data/backup_scheduler_workmanager.dart`: đăng ký task định kỳ qua `workmanager` theo tần suất; callback nền gọi `BackupController.createManualBackup()`-tương đương (không share) rồi `LocalBackupStore` tự xoá bản cũ vượt `maxKeepLocal` (FIFO — bản cũ nhất xoá trước), bắn thông báo nhẹ qua engine thông báo đã có (`lib/core/notification/`).
- [X] T045 [US3] Thêm cấu hình Android cần thiết cho `workmanager` (kiểm tra `android/app/build.gradle.kts`, `AndroidManifest.xml` theo hướng dẫn plugin) — chỉ thêm nếu bản mặc định của plugin chưa đủ.
- [X] T046 [US3] Bổ sung `BackupController`: `setAutoEnabled(bool)`, `setAutoFrequency(BackupFrequency)` — gọi `BackupScheduler.schedule`/`cancel` tương ứng rồi lưu `BackupPrefs` qua `ensureBackupPrefsStore()`.
- [X] T047 [P] [US3] Viết test `BackupController` (auto) tại `app/sora_thu_chi/test/backup_controller_test.dart` (fake `BackupScheduler`): bật/tắt và đổi tần suất gọi đúng seam + lưu đúng `BackupPrefs`, không gọi `BackupScheduler` thật.
- [X] T048 [US3] Nối khối "Tự động sao lưu" trong `BackupRestoreScreen`: công tắc bật/tắt + chọn tần suất (dialog/segmented control) đọc/ghi qua `BackupController`.
- [X] T049 [P] [US3] Viết test widget bổ sung `BackupRestoreScreen` (auto) tại `app/sora_thu_chi/test/backup_restore_screen_test.dart`: bật công tắc → hiện chọn tần suất; đổi tần suất phản ánh đúng trạng thái đã lưu.

**Điểm kiểm tra**: `flutter test` pass; QA tay `quickstart.md` mục 4 (bật/tắt, đổi tần suất không lỗi, giữ cấu hình qua vào/ra màn) đạt. Lịch chạy nền thật + độ tin cậy trên iOS: QA riêng trên thiết bị thật, không chặn hoàn thành PBI (đã ghi nhận rủi ro ở `plan.md`).

## Pha cuối: Polish & Cross-cutting

- [X] T050 [P] Bổ sung chuỗi dịch (`.tr`) cho toàn bộ nhãn mới (màn 01/02/03/04, thông báo lỗi, banner cảnh báo) — đối chiếu cách làm PBI 19; kiểm tra không tràn chữ ở English + cỡ chữ hệ thống lớn.
- [X] T051 [P] QA tay theme Tối + màn hẹp cho cả 4 màn/bottom sheet mới (theo `quickstart.md` mục 10) — thêm case vào `app/sora_thu_chi/test/dark_theme_smoke_test.dart` nếu file này gom smoke test theo danh sách màn.
- [X] T052 Dọn dẹp: gọi `LocalBackupStore.cleanupOldSafetySnapshots()` mỗi lần mở `BackupRestoreScreen` (init state) — theo đúng R10 (dọn khi mở màn hoặc trước khi tạo snapshot mới).
- [X] T053 Rà lại toàn bộ `flutter analyze` sạch (0 warning/lint mới) và `flutter test` toàn bộ (bao gồm test có sẵn) pass trước khi coi PBI hoàn thành.

## Sơ đồ phụ thuộc

```
Pha 1 (Setup) → Pha 2 (Foundational)
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
   US1 (P1)       US2 (P2)      US3 (P3)
  Sao lưu thủ    Khôi phục      Tự động
  công           (dùng file    sao lưu
  (tạo được      US1 tạo ra    (độc lập UI,
  file để        để QA;        chỉ cần
  US2 dùng       BackupRestorer Foundational)
  QA khôi        độc lập code)
  phục)                │
        └──────────────┴──────────────┘
                      ▼
              Pha cuối (Polish)
```

US2 phụ thuộc **file thật** do US1 tạo ra để QA tay đầy đủ (`quickstart.md` dùng file từ bước 2–3 để test khôi phục ở bước 5–8), nhưng code (`BackupRestorer`, `BackupReader`) không phụ thuộc code US1 — có thể thi công song song nếu dùng file backup mẫu dựng tay trong test. US3 hoàn toàn độc lập code với US1/US2, chỉ cần chung `BackupController`/`BackupPrefs` từ Pha Foundational.

## Ví dụ chạy song song

- Trong Pha Foundational: T003/T004, T006, T007/T008, T009/T010, T016 có thể chạy song song (khác file, không phụ thuộc nhau) — T011 cần T006+T007+T009 xong trước; T013 cần T006+T014 xong trước; T017 cần T016 xong trước.
- Trong US1: T028, T029, T030 (test widget 3 màn/sheet khác nhau) chạy song song sau khi T024–T026 xong.
- Trong US2: T033, T035, T038 chạy song song; T040, T041, T042 chạy song song sau khi T036/T037/T039 xong.
- Trong US3: T047, T049 chạy song song sau khi T043–T046, T048 xong.

## Chiến lược triển khai

- **MVP đề xuất**: Pha 1 + Pha 2 (Foundational) + Pha 3 (US1 — Sao lưu thủ công). Đã đáp ứng SC-001 và giá trị cốt lõi "có nơi lưu dữ liệu ra ngoài app" dù chưa có khôi phục.
- **Thứ tự giao hàng tăng dần**: Setup+Foundational → US1 (sao lưu) → US2 (khôi phục, giá trị hoàn chỉnh "an toàn dữ liệu") → US3 (tự động, tiện lợi thêm) → Polish.
- Có thể dừng sau US2 nếu cần cắt phạm vi gấp — US3 (tự động sao lưu) là tính năng độc lập, không tính năng nào khác phụ thuộc nó.
