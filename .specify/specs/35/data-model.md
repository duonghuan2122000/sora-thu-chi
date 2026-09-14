# Mô hình dữ liệu: Sao lưu & Khôi phục dữ liệu (PBI 35)

Không thêm bảng drift mới (schema giữ **v10**). Dữ liệu tính năng chia làm 2 phần: **cấu hình** (lưu trong `AppSettings` key-value đã có) và **nội dung backup** (file trên đĩa, không phải bản ghi DB).

## 1. `BackupPrefs` — domain thuần, gói trong 1 row JSON `backupPrefs` của `AppSettings`

| Trường | Kiểu | Mặc định | Ghi chú |
|---|---|---|---|
| `autoEnabled` | `bool` | `false` | Bật/tắt tự động sao lưu |
| `autoFrequency` | `enum {daily, weekly, monthly}` | `weekly` | Tần suất khi `autoEnabled` |
| `maxKeepLocal` | `int` | `5` | Số bản tự động giữ lại tối đa nội bộ (FIFO) — hằng số nghiệp vụ, không hiển thị cho người dùng chỉnh |
| `lastBackupAt` | `DateTime?` | `null` | Thời điểm sao lưu gần nhất (thủ công hoặc tự động) |
| `lastBackupCounts` | `Map<String,int>?` | `null` | Số liệu tóm tắt của lần sao lưu gần nhất (`wallets`/`categories`/`transactions`/...) để hiển thị thẻ "Sao lưu gần nhất" không cần đọc lại file |
| `lastBackupSizeBytes` | `int?` | `null` | Dung lượng file lần gần nhất |

**Quy tắc parse**: giống mọi row JSON khác trong `AppSettings` (PBI 24/28/29) — row vắng/JSON hỏng ⇒ cả bộ mặc định; từng trường sai kiểu/ngoài miền ⇒ mặc định của riêng trường đó, không bao giờ ném lỗi.

## 2. `BackupFileMeta` — đọc trực tiếp từ `meta` của file backup (không lưu DB)

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `schemaVersion` | `int` | Đối chiếu với phiên bản app hỗ trợ trước khi cho xem tiếp |
| `appVersion` | `String` | Hiển thị tham khảo |
| `exportedAt` | `DateTime` | Thời điểm tạo file |
| `currencyDefault` | `String` | |
| `counts` | `Map<String,int>` | Số ví/danh mục/giao dịch/ngân sách/mục tiêu/khoản vay — đọc nhanh không cần parse `data` |
| `hasAttachments` | `bool` | Quyết định file là `.json` hay `.zip` |
| `checksum` | `String` | SHA-256 của phần `data`, dùng phát hiện file hỏng/sửa tay |
| `hasPassword` | `bool` | Suy ra từ việc file có header mã hóa hay không (đọc được trước khi giải mã) |

**Luật hợp lệ**: `schemaVersion` phải ≤ phiên bản app hỗ trợ hiện tại; `checksum` phải khớp SHA-256 tính lại từ phần `data` sau khi giải mã (nếu có mật khẩu) — sai một trong hai ⇒ chặn khôi phục, không hiển thị bottom sheet xác nhận.

## 3. `BackupData` — toàn bộ dữ liệu nghiệp vụ trong `data` của file, ánh xạ 1-1 từ các entity hiện có

Không phải thực thể mới — là snapshot tuần tự hoá của các bảng đã có (`wallets`, `categories`, `transactions`, `budgets`, `app_settings`...) theo đúng schema JSON đã định trong `docs/backup/giai-phap-dong-bo-sao-luu-du-lieu.md §3`. Mọi bản ghi giữ nguyên `id` gốc để không đứt gãy khóa ngoại giữa giao dịch ↔ ví ↔ danh mục khi ghi đè.

## 4. `LocalBackupEntry` — 1 dòng trong danh sách "Các bản sao lưu", đọc trực tiếp từ hệ thống file (không lưu DB)

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `path` | `String` | Đường dẫn file trong `app_documents/backups/` |
| `fileName` | `String` | Tên file (theo quy ước `thuchi_backup_YYYYMMDD_HHmmss.json\|.zip`) |
| `sizeBytes` | `int` | Dung lượng thật trên đĩa |
| `isAuto` | `bool` | Suy từ thư mục con (`backups/auto/` vs `backups/manual/`) hoặc metadata đã đọc sẵn khi liệt kê |
| `hasAttachments` | `bool` | Đuôi `.zip` |

**Nguồn sự thật**: hệ thống file, không đồng bộ qua DB — tránh lệch khi người dùng xoá file ngoài app (xem R1 ở `research.md`).

## Luồng chuyển trạng thái (Restore)

```
Chọn file ─► Đọc BackupFileMeta ─► [không hợp lệ/không tương thích] ──► Báo lỗi, dừng
                     │
                     ▼ [hợp lệ]
        [có mật khẩu] ──► Yêu cầu nhập đúng mật khẩu trước khi hiện số liệu
                     │
                     ▼
     Hiển thị bottom sheet xác nhận (tick bắt buộc)
                     │
                     ▼
   Tạo safety-snapshot dữ liệu hiện tại (LocalBackupEntry mới, không share)
                     │
                     ▼
   1 db.transaction(): xoá dữ liệu cũ + ghi BackupData mới (all-or-nothing)
                     │
                     ▼
        Cập nhật BackupPrefs.lastBackup* ─► Màn thành công ─► Về Tổng quan
```
