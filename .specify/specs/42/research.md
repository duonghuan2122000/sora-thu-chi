# Nghiên cứu kỹ thuật: PBI 42 — Đường dẫn file tự động sao lưu

## R1 — Nơi lưu `lastBackupPath`

**Quyết định**: Thêm trường `lastBackupPath: String?` vào JSON `backupPrefs` hiện có trong `AppSettings` (row key-value, không bảng riêng).

**Lý do**: `BackupPrefs` đã lưu `lastBackupAt`/`lastBackupCounts`/`lastBackupSizeBytes` theo đúng khuôn này (PBI 35). Thêm 1 trường string vào cùng JSON là thay đổi tối thiểu, không cần migration schema (field mới trong JSON tự nhận giá trị `null` khi đọc file cũ chưa có key này, đúng cơ chế `fromSettings` từng-trường-độc-lập đã có).

**Phương án khác đã xem xét**: Tạo bảng/migration mới `Drift` — không cần thiết, dữ liệu là 1 giá trị đơn, không có quan hệ, over-engineering so với nhu cầu.

## R2 — Xác định bản gần nhất có phải "tự động" hay không

**Quyết định**: Không thêm cờ `lastBackupIsAuto` riêng trong `BackupPrefs`. Khi hiển thị, đối chiếu `prefs.lastBackupPath` với `controller.backups` (danh sách `LocalBackupEntry` đã tải từ filesystem) để lấy `entry.isAuto` — chỉ hiện path khi tìm thấy entry khớp và `entry.isAuto == true`.

**Lý do**: `LocalBackupEntry.isAuto` đã là nguồn sự thật duy nhất (suy từ thư mục con filesystem, theo comment sẵn có trong `local_backup_store.dart`). Thêm 1 cờ boolean lưu riêng trong `BackupPrefs` tạo ra 2 nguồn có thể lệch nhau (ví dụ nếu sau này đổi logic phân loại thư mục). Cách tra cứu chéo cũng tự nhiên xử lý đúng trường hợp biên "bản đã bị dọn (rotate)" đã chốt trong spec: nếu path không còn trong danh sách hiện tại, không có gì để tra cứu, tự động không hiển thị path — không cần code xử lý riêng cho trường hợp này.

**Phương án khác đã xem xét**: Thêm `lastBackupIsAuto: bool` vào `BackupPrefs` song song `lastBackupPath` — đơn giản hơn về code nhưng tạo rủi ro lệch dữ liệu giữa 2 nguồn, không tuân nguyên tắc "1 nguồn sự thật" mà PBI 35 đã đặt ra cho danh sách backup local.

## R3 — Hiển thị đường dẫn trong danh sách "Các bản sao lưu"

**Quyết định**: Dùng trực tiếp `entry.path` (đã có sẵn trong `LocalBackupEntry`) — không cần thêm trường/seam mới, chỉ thêm 1 dòng `Text` trong widget `_BackupList` khi `entry.isAuto == true`.

**Lý do**: Dữ liệu đã tồn tại đầy đủ, đây thuần là thay đổi hiển thị (presentation-only).

## R4 — Xử lý đường dẫn dài trên màn hình nhỏ

**Quyết định**: `maxLines: 1` + `overflow: TextOverflow.ellipsis` (cắt ở cuối chuỗi) — cùng mẫu đã dùng cho `entry.fileName` trong `_BackupList` hiện có.

**Lý do**: Nhất quán với pattern sẵn có trong cùng file, không cần viết logic rút gọn ở giữa chuỗi (ví dụ `.../backups/auto/...`) — tên file (phần cuối đường dẫn, thường quan trọng nhất để nhận diện) vẫn có thể bị cắt nhưng đây là hành vi chấp nhận được cho 1 dòng phụ, không phải thông tin chính (tên file đã hiển thị riêng ở dòng trên).

**Phương án khác đã xem xét**: Rút gọn ở giữa chuỗi (`...`) để giữ cả đầu lẫn cuối — phức tạp hơn cho lợi ích nhỏ ở 1 dòng thông tin phụ; có thể nâng cấp sau nếu người dùng phản hồi cần.
