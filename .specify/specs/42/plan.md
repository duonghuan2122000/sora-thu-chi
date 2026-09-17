# Kế hoạch triển khai: Đường dẫn file tự động sao lưu

**Mã PBI**: 42
**Liên kết spec**: .specify/specs/42/spec.md
**Ngày tạo**: 2026-09-17

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart / Flutter (`sdk: ^3.12.2`) — không đổi so với PBI 35 |
| Framework / Thư viện chính | GetX (`BackupController` đã có) — không thêm dependency mới |
| Lưu trữ dữ liệu | `AppSettings` row JSON `backupPrefs` — thêm 1 trường `lastBackupPath` (String?) vào JSON hiện có, **không** migration schema (giống cách `lastBackupCounts`/`lastBackupSizeBytes` đã làm ở PBI 35) |
| Kiểm thử | `flutter_test` widget (`backup_restore_screen_test.dart`) + unit (`backup_prefs_test.dart`, `backup_controller_test.dart`) — mở rộng test hiện có, không thêm framework mới |
| Nền tảng triển khai | Android + iOS, kể cả đường ghi ở isolate nền WorkManager (`backup_scheduler_workmanager.dart`) |
| Ràng buộc hiệu năng | Không đáng kể — chỉ thêm 1 trường string + 1-2 dòng Text, không có tính toán nặng |
| Ràng buộc khác | Không đổi vị trí lưu file thực tế (vẫn `app_documents/backups/auto|manual/`); chỉ bổ sung hiển thị đường dẫn đã có sẵn trong `LocalBackupEntry.path` |

Không có `NEEDS CLARIFICATION` — toàn bộ điểm kỹ thuật đã xác định được từ code hiện có của PBI 35 (đọc `backup_prefs.dart`, `backup_controller.dart`, `backup_scheduler_workmanager.dart`, `backup_restore_screen.dart`).

Không có dependency mới.

## Kiểm tra theo hiến pháp dự án

Không có `.specify/memory/constitution.md`. Đối chiếu với nguyên tắc chốt trong `CLAUDE.md` gốc:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không server | ✅ | Chỉ thêm hiển thị đường dẫn file cục bộ, không network |
| Reuse trước khi thêm code mới (ponytail) | ✅ | Tái dùng `LocalBackupEntry.path`/`.isAuto` đã có ở PBI 35, không thêm store/seam mới |
| Tiếng Việt có dấu trong UI/tài liệu/commit | ✅ | Không thêm chuỗi hiển thị cố định mới cần dịch (đường dẫn file là dữ liệu thô, không phải nhãn UI) |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Tóm tắt:

- **R1**: Lưu `lastBackupPath` thêm vào JSON `backupPrefs` hiện có (như `lastBackupCounts`/`lastBackupSizeBytes`), không tạo bảng/migration mới.
- **R2**: Xác định "bản gần nhất có phải tự động không" bằng cách đối chiếu `prefs.lastBackupPath` với danh sách `LocalBackupEntry` đã tải (`controller.backups`) thay vì thêm cờ `lastBackupIsAuto` riêng — tránh 2 nguồn sự thật có thể lệch nhau khi bản bị dọn (rotate). Nếu không tìm thấy entry khớp (đã bị dọn/xoá) → không hiển thị đường dẫn, đúng hành vi ở trường hợp biên đã chốt trong spec.
- **R3**: Danh sách "Các bản sao lưu" không cần trường mới — `LocalBackupEntry.path` đã sẵn có, chỉ cần thêm 1 dòng hiển thị trong widget.
- **R4**: Đường dẫn dài rút gọn bằng `TextOverflow.ellipsis` kết hợp `maxLines: 1` (mẫu đã dùng cho `entry.fileName` trong cùng file) — không cần logic rút gọn ở giữa chuỗi riêng.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — mở rộng `BackupPrefs` (thêm `lastBackupPath: String?`), không thực thể mới.
- **Hợp đồng giao diện**: không có — thay đổi hoàn toàn nội bộ UI + local state, không có API/CLI. Bỏ qua `contracts/`.
- **Kịch bản khởi động nhanh**: xem `quickstart.md`.

## Cấu trúc dự án dự kiến

Sửa (không tạo file mới):

```
app/sora_thu_chi/lib/core/backup/backup_prefs.dart          # + lastBackupPath
app/sora_thu_chi/lib/core/backup/backup_controller.dart      # ghi lastBackupPath khi tạo backup thủ công (updatePrefs)
app/sora_thu_chi/lib/data/backup_scheduler_workmanager.dart  # ghi lastBackupPath trong _runAutoBackup (isolate nền)
app/sora_thu_chi/lib/screens/backup_restore_screen.dart      # _LastBackupCard: hiện path nếu bản gần nhất là auto;
                                                               # _BackupList: hiện path cho mỗi entry.isAuto
app/sora_thu_chi/test/backup_prefs_test.dart                 # test round-trip lastBackupPath
app/sora_thu_chi/test/backup_controller_test.dart             # test lastBackupPath được set sau khi tạo backup thủ công
app/sora_thu_chi/test/backup_restore_screen_test.dart         # test hiển thị path ở card + list cho bản auto, không hiện cho bản thủ công
```

## Rủi ro & ngoại lệ có lý do

- `confirmRestore()` trong `backup_controller.dart` cũng gọi `copyWith(lastBackupAt: ..., lastBackupCounts: ...)` nhưng không gắn với 1 file backup thật (chỉ cập nhật số liệu snapshot sau khôi phục) — **không** set `lastBackupPath` ở đây; giữ nguyên giá trị cũ qua `copyWith` mặc định. Vì R2 tra cứu chéo với danh sách entries hiện có, path cũ (nếu không còn khớp entry nào) tự động không hiển thị — không cần xử lý đặc biệt thêm.
- Đường ghi tự động chạy trong isolate nền riêng (`backup_scheduler_workmanager.dart`) không dùng chung `BackupController` — phải sửa **2 nơi** độc lập (controller cho thủ công, scheduler cho tự động) thay vì 1 chỗ, đây là ràng buộc kiến trúc có sẵn từ PBI 35 (isolate nền không có state GetX), không phải lựa chọn mới của PBI này.
