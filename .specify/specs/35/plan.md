# Kế hoạch triển khai: Sao lưu & Khôi phục dữ liệu

**Mã PBI**: 35
**Liên kết spec**: .specify/specs/35/spec.md
**Ngày tạo**: 2026-09-14

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart / Flutter (`sdk: ^3.12.2`) |
| Framework / Thư viện chính | GetX (state, đã có) + `drift` (DB local, đã có) |
| Lưu trữ dữ liệu | `AppSettings` key-value (1 row JSON `backupPrefs`, không migration) cho cấu hình; file JSON/ZIP trên đĩa (`app_documents/backups/`) cho nội dung backup — không thêm bảng, schema giữ **v10** |
| Kiểm thử | `flutter_test` widget + unit thuần Dart (giống PBI 24/27/31); drift transaction test trên sqlite in-memory |
| Nền tảng triển khai | Android + iOS (tự động sao lưu nền trên iOS là best-effort — xem `research.md` R7) |
| Ràng buộc hiệu năng | Tạo/đọc file backup vài nghìn giao dịch dưới 30s (SC-001); không chặn UI thread khi build JSON/ZIP lớn — chạy trong `compute()` như pattern PBI 27 |
| Ràng buộc khác | Offline hoàn toàn — không gọi API cloud nào; mật khẩu backup độc lập PIN app |

Không có `NEEDS CLARIFICATION` — mọi quyết định kỹ thuật đã đóng ở `research.md` dựa trên nghiệp vụ đã chốt trong `docs/backup/giai-phap-dong-bo-sao-luu-du-lieu.md`.

**Dependency mới** (không có `.specify/memory/constitution.md` để đối chiếu — áp dụng nguyên tắc chung của CLAUDE.md: tái dùng trước, thêm dependency chỉ khi cần thật):
- `file_picker` — chọn file khi khôi phục.
- `cryptography` — AES-256-GCM + PBKDF2 cho mật khẩu bảo vệ file.
- `workmanager` — lịch chạy tự động sao lưu nền.
- `archive` — **chuyển từ `dev_dependencies` sang `dependencies`** (đã có sẵn qua `excel_community`, nay dùng ở code chạy thật để đóng gói `.zip`).

Tái dùng nguyên trạng: `share_plus` (chia sẻ file), `crypto` (SHA-256 checksum), `path_provider` (đường dẫn thư mục nội bộ), `drift` (transaction all-or-nothing khi restore).

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md`. Đối chiếu với nguyên tắc chốt trong `CLAUDE.md` gốc:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không server | ✅ | Toàn bộ luồng qua file cục bộ + share sheet hệ thống, 0 API cloud |
| Số dư ví là đại lượng suy ra | ✅ | Restore ghi lại `wallets`/`transactions` gốc, số dư vẫn tính lại như mọi luồng khác, không ghi tay |
| Seam pattern (domain thuần + Store interface + `ensure...()` GetX singleton) | ✅ | `BackupPrefsStore`, `BackupFileService`, `BackupCrypto` đều tách seam để test không cần plugin thật |
| Tiếng Việt có dấu trong UI/tài liệu/commit | ✅ | |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Tóm tắt các quyết định chính:

- **R1**: Cấu hình lưu 1 row JSON `backupPrefs` trong `AppSettings` (không bảng mới).
- **R2**: JSON thuần khi không ảnh, `.zip` (`archive`) khi có ảnh đính kèm.
- **R3**: `file_picker` cho chọn file khôi phục.
- **R4**: Tái dùng `share_plus` để chia sẻ file backup.
- **R5**: `cryptography` cho AES-256-GCM + PBKDF2.
- **R6**: Không thêm package đo dung lượng đĩa — ghi file tạm rồi rename, bắt lỗi ghi để báo sớm.
- **R7**: `workmanager` cho lịch chạy nền; iOS best-effort, không cam kết đúng giờ.
- **R8**: Checksum dùng lại `crypto` (SHA-256); migration schema backup là khung rỗng (hiện chỉ có v1).
- **R9**: Ghi dữ liệu khôi phục trong 1 `db.transaction()` duy nhất.
- **R10**: Safety-snapshot trước khi ghi đè, tái dùng hàm build backup sẵn có.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — `BackupPrefs` (row JSON), `BackupFileMeta`/`BackupData` (nội dung file, không lưu DB), `LocalBackupEntry` (liệt kê filesystem).
- **Hợp đồng giao diện**: không có — tính năng hoàn toàn nội bộ, không expose API/CLI ra ngoài. Bỏ qua `contracts/`.
- **Kịch bản khởi động nhanh**: xem `quickstart.md`.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn | ✅ | Không đổi sau thiết kế |
| Seam pattern | ✅ | 3 seam mới đều theo đúng khuôn interface + fake cho test |
| Schema drift tối thiểu | ✅ | Không thêm bảng, chỉ 1 row `AppSettings`, schema giữ v10 |
| Toàn phần-hoặc-không khi ghi dữ liệu tài chính | ✅ | `db.transaction()` bọc toàn bộ bước restore |

Không có ngoại lệ cần biện minh.

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/lib/
├── core/backup/                          # domain thuần + seam (mới)
│   ├── backup_prefs.dart                 # BackupPrefs, toSettings/fromSettings, defaults
│   ├── backup_prefs_store.dart           # abstract BackupPrefsStore + DriftBackupPrefsStore
│   ├── backup_file_meta.dart             # BackupFileMeta, parse/validate checksum + schema_version
│   ├── backup_writer.dart                # build JSON/ZIP thuần Dart từ snapshot DB (chạy trong compute)
│   ├── backup_reader.dart                # đọc + validate + migrate file backup
│   ├── backup_crypto.dart                # seam mã hoá/giải mã AES-256-GCM + PBKDF2 (impl CryptographyBackupCrypto)
│   ├── local_backup_store.dart           # liệt kê/dọn file trong app_documents/backups/ (manual/auto/_safety)
│   ├── backup_restorer.dart              # db.transaction() xoá + ghi dữ liệu mới
│   └── backup_scheduler.dart             # seam lịch chạy nền (impl WorkmanagerBackupScheduler)
├── ui/settings/backup/                   # màn hình (mới)
│   ├── backup_restore_screen.dart        # màn 01
│   ├── create_backup_sheet.dart          # bottom sheet 02
│   ├── restore_confirm_sheet.dart        # bottom sheet 03
│   └── backup_result_screen.dart         # màn 04 (dùng chung backup/restore thành công)
└── ui/settings/settings_screen.dart      # thêm điểm vào (sửa)

app/sora_thu_chi/test/
├── core/backup/                          # test domain thuần + seam (Fake store/crypto/scheduler)
└── ui/settings/backup/                   # test widget các màn/bottom sheet

app/sora_thu_chi/pubspec.yaml             # thêm file_picker, cryptography, workmanager; chuyển archive sang dependencies (sửa)
android/app/build.gradle.kts              # cấu hình WorkManager nếu cần (kiểm tra khi implement)
```

## Rủi ro & ngoại lệ có lý do

- **Tự động sao lưu trên iOS không đảm bảo đúng lịch** (giới hạn BGTaskScheduler của hệ điều hành) — đã ghi nhận ở R7, không phải lỗi triển khai; cần QA tay trên thiết bị thật trước khi cam kết tần suất "hàng ngày" với người dùng (đúng như "Việc cần làm tiếp theo" của doc nghiệp vụ gốc).
- **Nguồn phân phối model AI Tier B vẫn còn ⚠ quyết định mở** (PBI 24, không liên quan trực tiếp PBI này) — không ảnh hưởng phạm vi backup, nêu ở đây chỉ để không nhầm lẫn khi đọc song song `wiki-knowledge/concept/Lộ trình phát triển.md`.
- Nếu sau khi thi công phát hiện file backup lớn (nhiều ảnh) làm chậm UI dù đã chạy trong `compute()`, cân nhắc thêm progress indicator — chưa đưa vào phạm vi vì spec không yêu cầu hiển thị tiến trình chi tiết.
