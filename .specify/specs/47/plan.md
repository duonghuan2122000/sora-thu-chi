# Kế hoạch triển khai: Nhật ký trích xuất AI

**Mã PBI**: 47
**Liên kết spec**: .specify/specs/47/spec.md
**Ngày tạo**: 2026-09-17

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart / Flutter (Android/iOS), khớp `app/sora_thu_chi` hiện có |
| Framework / Thư viện chính | GetX (state), `drift` (DB local), `share_plus` (xuất file — đã có sẵn trong pubspec, không thêm dependency mới) |
| Lưu trữ dữ liệu | drift, thêm bảng `ScanExtractionLogs` (schema **v11**, `lib/data/db/app_database.dart`) + thư mục ảnh riêng `<appDocuments>/scan_logs/` |
| Kiểm thử | `flutter test` — unit test cho store (FIFO, luật hợp lệ outcome), widget test cho 2 màn mới |
| Nền tảng triển khai | Android/iOS, offline hoàn toàn — không có backend |
| Ràng buộc hiệu năng | Ghi log không được làm chậm cảm nhận luồng quét hiện có (SC-005) — ghi DB 1 lần cuối phiên (async, không block UI thoát màn) |
| Ràng buộc khác | Không gửi dữ liệu ra ngoài app trừ khi user chủ động bấm "Xuất file" (FR-012) |

## Kiểm tra theo hiến pháp dự án

Không có `.specify/memory/constitution.md` trong repo — bỏ qua bước đối chiếu hiến pháp.

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết `research.md`. Tóm tắt 6 quyết định chính:

1. Chuỗi sự kiện lưu dạng JSON 1 dòng, ghi 1 lần cuối phiên (không insert từng bước) — theo pattern `ScanSessions.parsedJson`.
2. Trần FIFO `kMaxScanLogs = 200`, tái dùng kỹ thuật `NotificationHistoryStore._trimToLimit()`, mở rộng thêm bước xoá file ảnh của dòng bị trim.
3. Ảnh log lưu ở store riêng `ScanLogImageStore` (không dùng chung `ScanImageStore` vốn chỉ lưu khi tạo giao dịch thành công).
4. Theo dõi sửa trường bằng instrument trực tiếp trong `ScanConfirmScreen` (đẩy sự kiện ngay khi setState), không diff lúc lưu.
5. Xuất file tái dùng pattern `share_plus` đã chuẩn hoá (`export_share.dart`/`backup_share.dart`).
6. Màn hình mới đặt trong Cài đặt → Tiện ích, cạnh mục "Quét hóa đơn AI" hiện có.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — bảng `ScanExtractionLogs` (schema v11) + model thuần `ScanLogEvent`/`ScanLogSession`.
- **Hợp đồng giao diện**: không áp dụng — app nội bộ, không có API/CLI công khai ra bên ngoài.
- **Kịch bản khởi động nhanh**: xem `quickstart.md` — 6 kịch bản (lưu thành công, hủy, lỗi, FIFO, xuất file, rỗng).

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/lib/
├── core/scan/
│   ├── scan_result.dart          (không đổi — tái dùng ScanExtraction/ScanEngine)
│   ├── scan_log.dart             (MỚI: ScanLogEvent, ScanLogEventType, ScanLogSession, ScanExtractionLog model + toJson/fromJson)
│   └── scan_flow.dart            (SỬA: tạo ScanLogSession khi startScanFlow(), truyền qua các bước, gọi finish() ở mọi lối ra)
├── data/
│   ├── db/app_database.dart      (SỬA: thêm bảng ScanExtractionLogs, schemaVersion → 11, migration if (from < 11))
│   ├── scan_log_store_drift.dart (MỚI: ScanLogStore — append() + _trimToLimit(), theo khuôn notification_history_store_drift.dart)
│   └── scan_log_image_store.dart (MỚI: ScanLogImageStore — copy ảnh tạm vào scan_logs/, xoá theo path khi trim)
├── screens/scan/
│   ├── scan_confirm_screen.dart  (SỬA: instrument mỗi setState đổi trường → đẩy ScanLogEvent; bắt back/cancel/save → gọi session.finish())
│   ├── scan_log_list_screen.dart (MỚI: danh sách nhật ký, mới nhất trước, nút xoá tất cả + xuất file)
│   └── scan_log_detail_screen.dart (MỚI: chi tiết 1 bản ghi — ảnh, OCR, AI đề xuất, giá trị cuối, timeline sự kiện, nút xoá)
├── core/scan/scan_log_export.dart (MỚI: build file JSON toàn bộ nhật ký, tái dùng share_plus theo pattern export_share.dart)
└── screens/settings/...          (SỬA: thêm mục "Nhật ký trích xuất AI" trong màn Tiện ích, cạnh "Quét hóa đơn AI")

app/sora_thu_chi/test/
├── data/scan_log_store_drift_test.dart      (MỚI: FIFO, luật hợp lệ outcome, xoá file ảnh khi trim)
├── core/scan/scan_log_test.dart             (MỚI: serialize/deserialize ScanLogEvent/ScanExtractionLog)
└── screens/scan/scan_log_list_screen_test.dart (MỚI: widget test danh sách + trạng thái rỗng)
```

## Rủi ro & ngoại lệ có lý do

- **Rủi ro**: instrument `ScanConfirmScreen` ở nhiều điểm setState có thể bỏ sót 1 trường nếu code hiện tại có nhiều đường sửa giá trị (ví dụ sửa qua picker riêng cho ngày/danh mục). → Task triển khai cần rà toàn bộ hàm `setState` trong file trước khi thêm instrument, không chỉ thêm ở chỗ dễ thấy.
- **Rủi ro**: ảnh log (`scan_logs/`) là bản sao độc lập với ảnh giao dịch (`receipts/`) → tốn thêm dung lượng máy khi cả 2 cùng tồn tại cho 1 phiên đã lưu. Chấp nhận được vì trần FIFO 200 bản ghi giới hạn tổng dung lượng; không tối ưu chia sẻ file giữa 2 store ở PBI này để tránh đụng luồng `ScanImageStore` hiện có.
- **Ngoại lệ có lý do**: không thêm màn cấu hình bật/tắt ghi log (đã ghi trong "Ngoài phạm vi" của spec) — mặc định luôn ghi, đúng theo spec đã chốt.
