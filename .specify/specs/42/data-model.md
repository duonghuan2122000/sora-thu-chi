# Mô hình dữ liệu: PBI 42 — Đường dẫn file tự động sao lưu

Không có thực thể mới. Mở rộng 1 thực thể đã có từ PBI 35.

## `BackupPrefs` (mở rộng)

File: `app/sora_thu_chi/lib/core/backup/backup_prefs.dart`

| Trường | Kiểu | Mô tả | Ghi chú |
|---|---|---|---|
| `lastBackupPath` | `String?` | Đường dẫn tuyệt đối tới file của lần sao lưu gần nhất (đúng giá trị `LocalBackupEntry.path` tại thời điểm ghi file) | **Mới**. `null` nếu chưa từng sao lưu hoặc đọc từ row cũ chưa có key này |

Cập nhật kèm theo (không đổi kiểu, chỉ thêm field mới cạnh các field sẵn có):

- `toJson()` — thêm `'lastBackupPath': lastBackupPath`.
- `fromSettings()` — thêm `lastBackupPath: _string(decoded['lastBackupPath'])` (helper mới, theo mẫu `_dateTime`/`_counts`: sai kiểu → `null`, không ném lỗi).
- `copyWith()` — thêm tham số `String? lastBackupPath`.
- `operator ==` / `hashCode` — thêm `lastBackupPath` vào so sánh/hash.

**Ai ghi trường này**:
- `BackupController._writeBackup()` (nhánh `updatePrefs: true`, tức tạo backup thủ công) — set `lastBackupPath: entry.path`.
- `_runAutoBackup()` trong `backup_scheduler_workmanager.dart` (isolate nền, tự động sao lưu) — set `lastBackupPath: entry.path`.
- `BackupController.confirmRestore()` — **không** set (giữ nguyên giá trị cũ qua `copyWith` mặc định) vì không gắn với 1 file backup mới được ghi ở bước này (xem `plan.md` §Rủi ro).

**Ai đọc trường này**: `_LastBackupCard` (màn `backup_restore_screen.dart`) — đối chiếu với `controller.backups` để quyết định có hiện path hay không (xem `research.md` R2).

## `LocalBackupEntry` (không đổi)

Đã có sẵn `path` (String) và `isAuto` (bool) — dùng trực tiếp trong `_BackupList`, không cần sửa định nghĩa.
