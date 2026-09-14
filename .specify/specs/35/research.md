# Nghiên cứu kỹ thuật: Sao lưu & Khôi phục dữ liệu (PBI 35)

## R1 — Nơi lưu cấu hình (tự động sao lưu, "sao lưu gần nhất")

**Quyết định**: Thêm 1 row JSON `backupPrefs` trong bảng key-value `AppSettings` đã có (schema giữ **v10**, không migration), theo đúng khuôn `notificationPrefs`/`scanDeviceCheck` đã dùng ở PBI 24/28.

**Lý do**: Cấu hình nhỏ, đọc/ghi cả khối, không cần truy vấn theo cột. Tận dụng seam `AppSettingsStore`-family đã có pattern (domain thuần + `toSettings`/`fromSettings` + seam Store + `ensure...()` GetX singleton), không cần `build_runner`, không thêm bảng.

**Phương án khác đã xem xét**: Bảng drift riêng `backup_history` — bị loại vì danh sách "các bản sao lưu" thực chất là liệt kê thư mục file trên đĩa (nguồn sự thật là filesystem, không phải DB); dùng thêm bảng sẽ phải đồng bộ 2 nguồn dễ lệch khi người dùng xoá file bằng tay ngoài app.

## R2 — Định dạng đóng gói file backup

**Quyết định**: JSON thuần (`.json`) khi không có ảnh hóa đơn đính kèm; gói `.zip` (`data.json` + `/images/`) khi có, dùng package `archive` (đã có sẵn trong cây phụ thuộc qua `excel_community`, hiện khai báo ở `dev_dependencies` — **chuyển sang `dependencies`** vì nay dùng ở code chạy thật).

**Lý do**: Đúng nghiệp vụ đã chốt trong `docs/backup/giai-phap-dong-bo-sao-luu-du-lieu.md` §2; không cần thêm dependency mới, `archive ^4.0.9` đã tương thích `image ^4.9.2` (đã xác minh ở PBI 25/27).

**Phương án khác đã xem xét**: Luôn dùng `.zip` kể cả khi không ảnh — bị loại vì đơn giản hoá không cần thiết, file JSON thuần dễ đọc/debug hơn khi không có ảnh.

## R3 — Chọn file khi khôi phục

**Quyết định**: Package `file_picker` (dependency mới) để mở trình chọn file hệ thống, lọc đuôi `.json`/`.zip`.

**Lý do**: Không có API nền tảng thuần Dart để mở file picker; đây là thư viện chuẩn phổ biến nhất cho Flutter, đã hỗ trợ Android/iOS.

**Phương án khác đã xem xét**: Tự viết kênh native (MethodChannel) như `device_probe` — bị loại, việc này không có logic nghiệp vụ đặc thù, dùng lại thư viện có sẵn rẻ hơn nhiều so với PBI 24 (nơi cần đo phần cứng, không có package chuẩn).

## R4 — Chia sẻ file khi tạo backup thủ công

**Quyết định**: Dùng lại `share_plus` (đã có từ PBI 27).

**Lý do**: Đã tích hợp sẵn, đúng seam `ShareExport` hiện có (`lib/core/report/`) — có thể tái dùng hoặc nhân bản cho ngữ cảnh backup mà không thêm dependency.

## R5 — Mã hóa mật khẩu file backup (AES-256-GCM + PBKDF2)

**Quyết định**: Package `cryptography` (dependency mới, pure Dart, không cần binding native) cho AES-256-GCM + Pbkdf2HmacSha256.

**Lý do**: Đây là mã hóa **cho file khi rời khỏi máy** (khác lớp mã hóa DB local) — nghiệp vụ đã chốt thuật toán cụ thể (`docs/backup/... §4.4`). `cryptography` cung cấp cả hai nguyên thủy cần thiết trong 1 package, API rõ ràng, không cần ghép `encrypt` + `pointycastle` (2 package, API rời rạc hơn).

**Phương án khác đã xem xét**: `encrypt` + `pointycastle` — khả thi nhưng cần tự ghép PBKDF2 + AES-GCM từ 2 API riêng, rủi ro dùng sai tham số (IV/nonce) cao hơn.

## R6 — Kiểm tra dung lượng trống trước khi ghi file

**Quyết định**: **Không** thêm package `disk_space` riêng. Ghi file backup ra đường dẫn tạm trước, `rename` sang tên thật chỉ khi ghi xong; nếu ghi lỗi (hết dung lượng) thì bắt `FileSystemException`, xoá file tạm, báo lỗi ngay — không để lại file dở dang.

**Lý do**: Việc kiểm tra dung lượng trống *trước* khi ghi là "nice-to-have" (giảm 1 lượt thử-sai), nhưng bắt lỗi *khi* ghi đã đáp ứng đúng yêu cầu nghiệp vụ ("báo lỗi sớm, không ghi dở") mà không cần thêm dependency chỉ để đọc dung lượng đĩa — tránh 1 package cho 1 edge case hiếm gặp.

**Phương án khác đã xem xét**: `disk_space`/kênh native đo dung lượng — để dành nếu sau này đo được người dùng thật gặp lỗi ghi dở thường xuyên.

## R7 — Tự động sao lưu nền (lịch chạy khi app đóng)

**Quyết định**: Package `workmanager` (dependency mới) cho Android (WorkManager thật, chạy nền tin cậy). Trên iOS, tự động sao lưu là **best-effort** (BGTaskScheduler qua cùng plugin) — hệ điều hành có thể trì hoãn/bỏ qua theo pin/mạng, không cam kết đúng tần suất đã chọn.

**Lý do**: Đúng gợi ý stack trong doc nghiệp vụ; giới hạn nền của iOS là giới hạn nền tảng, không phải lỗi thiết kế — ghi nhận rõ trong plan thay vì cố khắc phục bằng giải pháp phức tạp hơn (đồng bộ với "⚠ Việc cần làm tiếp theo" của doc nghiệp vụ, để lại quyết định tần suất/độ tin cậy iOS thực tế cho một đợt QA riêng sau khi có bản build thật).

**Phương án khác đã xem xét**: `android_alarm_manager_plus` — bị loại vì chỉ chạy Android, phải ghép thêm giải pháp riêng cho iOS; PBI 31 (thông báo đẩy) cũng từng cân nhắc và loại phương án tương tự.

## R8 — Checksum & migration schema cũ

**Quyết định**: Dùng lại `crypto` (đã có, PBI 3) để tính SHA-256 cho `meta.checksum`. Khi restore file có `schema_version` cũ hơn hiện tại, chạy hàm `migrateBackupSchema(int from, Map json)` thuần Dart (bảng chuyển đổi tuần tự từng version), **hiện tại chỉ có 1 bản schema (v1)** nên hàm là khung rỗng trả về nguyên trạng — sẵn sàng mở rộng khi có thay đổi cấu trúc backup thật.

**Lý do**: Không thêm dependency; nhất quán cách tính checksum đã dùng cho hash PIN.

## R9 — Ghi dữ liệu khôi phục toàn phần-hoặc-không

**Quyết định**: Toàn bộ việc xoá dữ liệu cũ + ghi dữ liệu mới từ file backup chạy trong **một `db.transaction()`** duy nhất của drift.

**Lý do**: Đúng pattern đã dùng khi ghi 1 phiên quét hóa đơn (PBI 24) — drift transaction đảm bảo rollback tự động nếu lỗi giữa chừng, đáp ứng FR-015 (toàn phần-hoặc-không) mà không cần tự viết cơ chế rollback thủ công.

## R10 — Bản sao lưu an toàn tạm thời trước khi ghi đè (safety-snapshot)

**Quyết định**: Trước khi ghi đè, tự tạo 1 bản backup (không mật khẩu, định dạng như backup tự động) lưu vào thư mục nội bộ `app_documents/backups/_safety/`, gắn timestamp; dọn file quá 24h mỗi lần mở màn "Sao lưu & Khôi phục" hoặc trước khi tạo snapshot mới.

**Lý do**: Đúng nghiệp vụ đã chốt (`docs/backup/... §4.3.5`); tái dùng cùng hàm build file backup đã có cho luồng thủ công/tự động, không cần logic ghi riêng.
