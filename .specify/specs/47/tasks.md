# Danh sách Task: Nhật ký trích xuất AI

**Mã PBI**: 47
**Nguồn**: plan.md, spec.md, data-model.md, research.md, quickstart.md

## Pha 1: Setup

- [X] T001 Xác nhận `pubspec.yaml` (`app/sora_thu_chi/pubspec.yaml`) đã có `share_plus` — không thêm dependency mới cho PBI này (đối chiếu research.md Quyết định 5)

## Pha 2: Foundational

**Chặn mọi User Story bên dưới — phải xong trước khi bắt đầu Pha 3.**

- [X] T002 Thêm bảng `ScanExtractionLogs` vào `app/sora_thu_chi/lib/data/db/app_database.dart` (cột theo data-model.md: id, createdAt, imagePath, rawText, extractionJson, engine, outcome, finalValuesJson, errorMessage, eventsJson), tăng `schemaVersion` lên **11**, thêm bước migration `if (from < 11)` tạo bảng mới
- [X] T003 [P] Tạo `app/sora_thu_chi/lib/core/scan/scan_log.dart`: enum `ScanLogEventType` (edit/back/cancel/save), class `ScanLogEvent` (field/fromValue/toValue/atMillis) + `toJson()`/`fromJson()`, class `ScanExtractionLog` (map đúng cột bảng T002) + `toJson()`/`fromJson()`
- [X] T004 [P] Thêm hằng số `kMaxScanLogs = 200` vào `app/sora_thu_chi/lib/core/scan/scan_log.dart`
- [X] T005 [P] Tạo `app/sora_thu_chi/lib/core/scan/scan_log_image_store.dart` (đổi vị trí so với kế hoạch ban đầu — cùng thư mục `core/scan/` với `ScanImageStore`, không phải `data/`, vì không phụ thuộc AppDatabase): class `ScanLogImageStore` — `save(tempPath) → String newPath` (copy vào `<appDocuments>/scan_logs/<millis>.jpg`), `delete(path)`
- [X] T006 Tạo `app/sora_thu_chi/lib/data/scan_log_store_drift.dart`: class `ScanLogStore` — `append(ScanExtractionLog)` insert + gọi `_trimToLimit()` (theo khuôn `notification_history_store_drift.dart:52`, sắp theo `(createdAt DESC, id DESC)`, xoá dòng vượt `kMaxScanLogs` **và** gọi `ScanLogImageStore.delete()` cho `imagePath` của dòng bị xoá), `watchAll()`/`getAll()` mới nhất trước, `deleteOne(id)`, `deleteAll()` (phụ thuộc T002, T003, T005)
- [X] T007 Tạo `app/sora_thu_chi/lib/core/scan/scan_log_session.dart`: class `ScanLogSession` — buffer `tempImagePath`/`rawText`/`extraction`/`engine`/`events`, method `addEvent(ScanLogEvent)`, `finish({required outcome, finalValues, errorMessage})` → build `ScanExtractionLog`, copy ảnh qua `ScanLogImageStore`, gọi `ScanLogStore.append()` (phụ thuộc T003, T005, T006)
- [X] T008 [P] Test `app/sora_thu_chi/test/core/scan/scan_log_test.dart`: serialize/deserialize `ScanLogEvent`/`ScanExtractionLog` round-trip đúng field
- [X] T009 [P] Test `app/sora_thu_chi/test/data/scan_log_store_drift_test.dart`: insert > 200 bản ghi → còn đúng 200, dòng cũ nhất bị xoá, file ảnh dòng bị trim không còn tồn tại; luật hợp lệ `outcome=saved` có `finalValuesJson`, `outcome=error` có `errorMessage`

**Checkpoint**: schema v11 + store + session buffer sẵn sàng, mọi test T008/T009 pass trước khi sang Pha 3.

## Pha 3: User Story 1 - Tự động ghi nhật ký mỗi phiên quét + xem trong app (Ưu tiên: P1)

**Mục tiêu**: Mỗi phiên quét hóa đơn AI (lưu/hủy/lỗi) tự động sinh 1 bản ghi nhật ký đầy đủ; người dùng xem được danh sách và chi tiết trong app.
**Tiêu chí kiểm thử độc lập**: Quét → sửa 1 trường → Lưu (hoặc back giữa chừng) → mở Cài đặt → Tiện ích → "Nhật ký trích xuất AI" → thấy bản ghi mới nhất với đủ dữ liệu (ảnh, OCR, AI đề xuất, giá trị cuối/outcome, timeline sự kiện đúng thứ tự).

- [X] T010 [US1] Sửa `app/sora_thu_chi/lib/screens/scan/scan_processing_screen.dart` (đổi so với kế hoạch — `scan_flow.dart` không có state để giữ session; `ScanProcessingScreen` mới có `imagePath`/OCR/extraction): tạo `ScanLogSession` trong `initState`, gán `tempImagePath` ngay, gán `rawText` sau OCR và `extraction`/`engine` sau khi trích xuất; lỗi trước khi tới `ScanConfirmScreen` (OCR rỗng hoặc exception) → `session.finish(outcome: error, errorMessage: ...)`; back giữa xử lý → `finish(cancelled)`
- [X] T011 [US1] Sửa `app/sora_thu_chi/lib/screens/scan/scan_confirm_screen.dart`: nhận `ScanLogSession` qua constructor (`logSession`), instrument `_switchType`/`_appendDigit`/`_backspace`/`_pickDateTime`/`_pickCategory` → `addEvent(edit, field, from, to)` đúng thời điểm; trường "cửa hàng/ghi chú" không có callback rời rạc → diff tại thời điểm lưu (ghi trong tasks.md gốc dự tính diff cuối cho mọi trường qua `_finalExtraction()`, thực tế chỉ áp dụng cho trường này — các trường còn lại instrument trực tiếp tại điểm sửa)
- [X] T012 [US1] Sửa `scan_confirm_screen.dart`: bọc `PopScope(canPop: true, onPopInvokedWithResult: ...)` → `addEvent(back)` rồi `finish(cancelled)` nếu chưa lưu (cờ `_saved`)
- [X] T013 [US1] Không có nút "Hủy" riêng trong `scan_confirm_screen.dart` (chỉ back) — task gộp vào T012, không tạo thêm sự kiện `cancel` riêng (enum `ScanLogEventType` rút còn `edit`/`back`/`save`, bỏ `cancel` không dùng tới)
- [X] T014 [US1] Sửa `scan_confirm_screen.dart`: `_save()` gọi `_logSave()` (mới) → diff merchant + `addEvent(save)` + `finish(outcome: saved, finalValuesJson: {...})` trước `Navigator.pop(true)`
- [X] T015 [US1] Tạo `app/sora_thu_chi/lib/screens/scan_log_list_screen.dart`: danh sách `ScanLogStore.loadAll()` mới nhất trước (thời điểm, icon outcome, nhãn), trạng thái rỗng, chạm 1 dòng mở `ScanLogDetailScreen` (dùng `loadAll()` một lần khi mở màn thay vì `watchAll()` — không cần reactive, nhất quán `UtilitiesStore.load()`)
- [X] T016 [US1] Tạo `app/sora_thu_chi/lib/screens/scan_log_detail_screen.dart`: ảnh gốc (`Image.file`), OCR text, AI đề xuất ban đầu vs giá trị cuối (decode JSON), timeline sự kiện, badge outcome + `errorMessage`
- [X] T017 [US1] Sửa `app/sora_thu_chi/lib/screens/settings_screen.dart` (đổi so với kế hoạch — mục "Quét hóa đơn AI" nằm ở `_ScanGroup` trong `settings_screen.dart`, không phải `utilities_screen.dart`): thêm hàng "Nhật ký trích xuất AI" điều hướng sang `ScanLogListScreen`
- [X] T018 [P] [US1] Test `app/sora_thu_chi/test/screens/scan_log_list_screen_test.dart`: trạng thái rỗng, danh sách mới nhất trước, chạm dòng mở chi tiết
- [X] T019 [P] [US1] Test `app/sora_thu_chi/test/core/scan/scan_log_session_test.dart`: `finish(saved)` có `finalValuesJson` + copy ảnh; `finish(cancelled)` không có; `finish()` gọi 2 lần no-op; thứ tự `events` đúng thời gian

**Checkpoint**: US1 hoàn chỉnh, chạy độc lập được toàn bộ — đây là MVP.

## Pha 4: User Story 2 - Xóa bản ghi nhật ký (Ưu tiên: P2)

**Mục tiêu**: Người dùng xóa được từng bản ghi hoặc toàn bộ nhật ký.
**Tiêu chí kiểm thử độc lập**: Từ màn danh sách/chi tiết, xóa 1 bản ghi → biến mất khỏi danh sách + file ảnh liên quan bị xóa; xóa toàn bộ → danh sách về trạng thái rỗng.

- [X] T020 [US2] Sửa `app/sora_thu_chi/lib/screens/scan_log_detail_screen.dart`: nút "Xóa" (app bar) → xác nhận → `ScanLogStore.deleteOne(id)` → quay lại danh sách
- [X] T021 [US2] Sửa `app/sora_thu_chi/lib/screens/scan_log_list_screen.dart`: nút "Xóa toàn bộ" (app bar, ẩn khi rỗng) → xác nhận → `ScanLogStore.deleteAll()`
- [X] T022 [P] [US2] Test bổ sung trong `app/sora_thu_chi/test/data/scan_log_store_drift_test.dart`: `deleteOne` xóa đúng 1 dòng + file ảnh; `deleteAll` xóa hết dòng + toàn bộ file (đã viết cùng đợt Foundational T009, không tách lần ghi riêng)

**Checkpoint**: US1 + US2 cùng hoạt động, xóa không ảnh hưởng ghi log mới.

## Pha 5: User Story 3 - Xuất file nhật ký chia sẻ ra ngoài app (Ưu tiên: P3)

**Mục tiêu**: Người dùng xuất toàn bộ nhật ký ra 1 file JSON và chia sẻ qua bảng hệ thống.
**Tiêu chí kiểm thử độc lập**: Ở màn danh sách, bấm "Xuất file" → bảng chia sẻ hệ thống mở với 1 file `.json` chứa đúng toàn bộ bản ghi hiện có.

- [X] T023 [US3] Tạo `app/sora_thu_chi/lib/core/scan/scan_log_export.dart`: `writeScanLogExportFile` (JSON tạm) + `exportScanLogs`/`defaultShareScanLogExport` theo khuôn `backup_share.dart`/`export_share.dart`
- [X] T024 [US3] Sửa `app/sora_thu_chi/lib/screens/scan_log_list_screen.dart`: nút "Xuất file" (app bar, ẩn khi rỗng) gọi `exportScanLogs`
- [X] T025 [P] [US3] Test `app/sora_thu_chi/test/core/scan/scan_log_export_test.dart`: file JSON hợp lệ, đúng số bản ghi, `finalValues`/`outcome` đúng field

**Checkpoint**: Toàn bộ 3 user story hoạt động độc lập và cùng nhau.

## Pha cuối: Polish & Cross-cutting

- [X] T026 `flutter analyze` sạch tại `app/sora_thu_chi/` sau toàn bộ thay đổi (0 issue)
- [X] T027 `flutter test` toàn bộ — 1407/1407 pass (baseline 1352 + ~55 test mới/sửa của PBI 47), không hồi quy
- [X] T028 QA tay trên emulator theo `quickstart.md` — người dùng xác nhận đạt (2026-09-17)
- [X] T029 Cập nhật `wiki-knowledge/` (entity Giao dịch hoặc Hồ sơ & Bảo mật + Lộ trình phát triển + `log.md`) theo skill `sora-wiki` — nhật ký trích xuất AI là tính năng nghiệp vụ mới chưa có trong wiki

## Sơ đồ phụ thuộc

- Pha 1 → Pha 2 (Foundational) → Pha 3 (US1, P1) **bắt buộc trước** Pha 4 (US2) và Pha 5 (US3) vì US2/US3 thao tác trên dữ liệu do US1 sinh ra.
- Pha 4 (US2) và Pha 5 (US3) **độc lập với nhau** — có thể làm song song sau khi US1 xong (khác file: `scan_log_detail_screen.dart`/`scan_log_list_screen.dart` xóa vs `scan_log_export.dart`; tuy 2 story cùng chạm `scan_log_list_screen.dart` nên tránh chạy đồng thời trên cùng file, làm tuần tự nếu 1 người/1 agent).
- Trong mỗi pha, các task đánh `[P]` khác file có thể chạy song song; task không đánh `[P]` phải làm tuần tự theo thứ tự liệt kê (thường vì cùng sửa 1 file).

## Chiến lược triển khai

- **MVP đề xuất**: Pha 1 + Pha 2 + Pha 3 (User Story 1) — đã đủ giá trị cốt lõi: tự động ghi nhật ký mọi phiên quét + xem trong app.
- **Thứ tự giao hàng tăng dần**: MVP (US1) → US2 (xóa, dọn dẹp) → US3 (xuất file, mục tiêu cuối cùng "dữ liệu cho dev tinh chỉnh prompt") → Polish.
- Tổng **29 task**: Setup 1, Foundational 8, US1 10, US2 3, US3 3, Polish 4.
