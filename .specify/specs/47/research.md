# Nghiên cứu kỹ thuật: PBI 47 — Nhật ký trích xuất AI

## Quyết định 1: Lưu chuỗi sự kiện thao tác dạng JSON trong 1 dòng, không tách bảng con

- **Quyết định**: Bảng `ScanExtractionLogs` có cột `eventsJson` (TEXT) chứa mảng JSON các sự kiện `{type, field, fromValue, toValue, atMillis}`; ghi **một lần** khi phiên quét kết thúc (lưu/hủy/lỗi), không insert từng bước.
- **Lý do**: Không có nhu cầu truy vấn/lọc theo từng sự kiện riêng lẻ (spec chỉ cần xem cả chuỗi khi mở chi tiết 1 bản ghi) — đúng pattern đã dùng cho `ScanSessions.parsedJson` (`lib/data/db/app_database.dart:96`). Ghi 1 lần cuối phiên tránh row dở dang khi app bị kill giữa chừng, đơn giản hơn update nhiều lần.
- **Phương án khác đã xem xét**: Bảng con `ScanLogEvents` (1-n) — bị loại vì thêm JOIN/migration không cần thiết cho nhu cầu hiện tại.

## Quyết định 2: Trần lưu trữ FIFO tái dùng pattern `NotificationHistoryStore`, thêm dọn file ảnh

- **Quyết định**: Hằng số `kMaxScanLogs = 200` (giống `kMaxNotifications`). Sau mỗi lần ghi log, `_trimToLimit()` xoá các dòng vượt trần theo `(createdAt DESC, id DESC)` — cùng kỹ thuật `notification_history_store_drift.dart:52`. Khác biệt: trước khi xoá dòng, đọc `imagePath` của các dòng bị trim và xoá file ảnh tương ứng trên đĩa (notification không có file kèm nên không cần bước này).
- **Lý do**: Nhất quán với tiền lệ đã có trong repo, tránh phát minh cơ chế mới; xoá file ảnh để không rò rỉ dung lượng máy khi trim DB row.
- **Phương án khác đã xem xét**: Xoá theo thời gian (TTL) — phức tạp hơn (cần job nền định kỳ), không có tiền lệ trong repo.

## Quyết định 3: Ảnh log lưu độc lập, không dùng chung `ScanImageStore`

- **Quyết định**: Thêm `ScanLogImageStore` (thư mục riêng `<appDocuments>/scan_logs/`), copy ảnh tạm vào đây tại thời điểm ghi log (cuối phiên), bất kể outcome.
- **Lý do**: `ScanImageStore` hiện tại (`lib/core/scan/scan_image_store.dart:23`) chỉ lưu ảnh khi **lưu giao dịch thành công** (`scan_confirm_screen.dart:217`). Nhật ký cần ảnh cả khi người dùng hủy/back hoặc trích xuất lỗi (FR-005/FR-006) → không thể tái dùng store hiện có nguyên trạng, cần store riêng để không đổi hành vi cũ.
- **Phương án khác đã xem xét**: Sửa `ScanImageStore.save()` để luôn gọi bất kể outcome — bị loại vì sẽ đổi ý nghĩa/side-effect của store đang phục vụ luồng tạo giao dịch, rủi ro ảnh hưởng luồng cũ ngoài phạm vi PBI này.

## Quyết định 4: Theo dõi sửa trường bằng instrument trực tiếp trong `ScanConfirmScreen`, không diff cuối

- **Quyết định**: Mỗi setState đổi giá trị trường (số tiền, ngày, loại GD, danh mục, mô tả) trong `ScanConfirmScreen` đẩy 1 sự kiện `edit` vào bộ đệm log của phiên (kèm giá trị trước/sau, thời điểm), thay vì so sánh giá trị cuối với `widget.extraction` lúc lưu.
- **Lý do**: FR-004 yêu cầu **đúng thứ tự thời gian** kể cả khi user sửa đi sửa lại nhiều lần trước khi lưu — diff cuối chỉ cho biết trạng thái cuối, mất thông tin quá trình.
- **Phương án khác đã xem xét**: Diff `_finalExtraction()` (dòng 244) với `widget.extraction` lúc `_save()` — đơn giản hơn nhưng không đáp ứng trường hợp biên "sửa đi sửa lại nhiều lần" trong spec.

## Quyết định 5: Xuất file tái dùng pattern `share_plus` đã có (không thêm dependency)

- **Quyết định**: Xuất toàn bộ nhật ký thành 1 file JSON (mảng các bản ghi), ghi ra thư mục tạm rồi gọi `SharePlus.instance.share(...)` — cùng khuôn `lib/core/report/export_share.dart:17` và `lib/core/backup/backup_share.dart:10`.
- **Lý do**: Đã có 2 tiền lệ dùng chung 1 package (`share_plus`), không cần thêm dependency mới, giữ tính nhất quán trải nghiệm chia sẻ file trong app.
- **Phương án khác đã xem xét**: Không có — pattern đã chuẩn hoá trong repo.

## Quyết định 6: Vị trí màn hình mới

- **Quyết định**: Màn "Nhật ký trích xuất AI" đặt trong mục Cài đặt/Tiện ích, cạnh mục "Quét hóa đơn AI" hiện có (PBI 24 chặng 1).
- **Lý do**: Cùng nhóm chức năng liên quan tới AI quét hóa đơn trong Cài đặt, người dùng dễ tìm.
- **Phương án khác**: Đặt trong màn Chi tiết giao dịch — bị loại vì nhật ký tồn tại độc lập với giao dịch (kể cả phiên bị hủy, không có giao dịch nào để gắn vào).

## NEEDS CLARIFICATION đã giải quyết

Không còn điểm nào — mọi quyết định kỹ thuật đã chốt ở trên dựa theo pattern sẵn có trong repo.
