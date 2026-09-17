# Danh sách Task: Thông báo đường dẫn file xuất báo cáo

**Mã PBI**: 41
**Nguồn**: plan.md, spec.md, research.md, quickstart.md

Đường dẫn gốc dự án: `app/sora_thu_chi/`. Test hiện tại nằm **phẳng** dưới `test/` (không có `test/screens/`, `test/core/`).

> **Lệch so với bản gốc**: Task ban đầu dựa trên dependency `file_saver`. Khi thi công (T001), đọc thẳng mã nguồn Android của `file_saver` (cả 0.2.14 và 0.4.0) phát hiện `saveFile()` **không** ghi vào Downloads công khai — chỉ ghi thư mục riêng app. Đã gỡ dependency, chuyển sang **platform channel Kotlin/Swift tự viết** (`sora_thu_chi/report_downloads`) + `permission_handler` (chỉ xin quyền Android 8–9). Task T002–T006 dưới đây phản ánh đúng những gì đã làm, không phải bản dự thảo ban đầu. Xem `research.md` Quyết định 1 (bản đã sửa).

## Pha 1: Setup

- [X] T001 Thử dependency `file_saver` (0.2.14 rồi 0.4.0), xác nhận qua đọc mã nguồn Android (`FileSaverPlugin.kt`) là **không** ghi Downloads công khai ⇒ gỡ khỏi `app/sora_thu_chi/pubspec.yaml`; thêm `permission_handler: ^13.0.2` (chỉ dùng xin quyền runtime trên Android 8–9), `flutter pub get`

## Pha 2: Foundational

- [X] T002 Thêm quyền `WRITE_EXTERNAL_STORAGE` (`android:maxSdkVersion="28"`) vào `app/sora_thu_chi/android/app/src/main/AndroidManifest.xml` — chỉ hiệu lực Android 8–9, Android 10+ dùng MediaStore không cần quyền này
- [X] T003 Viết kênh native Android `app/sora_thu_chi/android/app/src/main/kotlin/com/sorathuchi/sora_thu_chi/ReportDownloadsChannel.kt` (method channel `sora_thu_chi/report_downloads`, method `saveToDownloads`): API ≥29 dùng `MediaStore.Downloads` (không quyền, hệ thống tự dò trùng `DISPLAY_NAME`); API 26–28 kiểm `WRITE_EXTERNAL_STORAGE` rồi ghi thẳng `Environment.DIRECTORY_DOWNLOADS`, tự dò trùng bằng vòng lặp `File.exists()` + hậu tố ` (n)` (FR-004); đăng ký kênh trong `MainActivity.kt`
- [X] T004 Viết kênh native iOS `app/sora_thu_chi/ios/Runner/ReportDownloadsChannel.swift` (cùng tên method), ghi vào thư mục Documents của app (không có Downloads công khai giống Android — khớp Giả định #1 spec.md) + dò trùng tên; đăng ký trong `AppDelegate.swift`
- [X] T005 Tạo `app/sora_thu_chi/lib/core/report/report_file_save.dart`: `typedef SaveReportFile`, lớp `SavedReportFile { path, fileName }`, `ReportStoragePermissionDeniedException`, và `defaultSaveReportFile` gọi `MethodChannel('sora_thu_chi/report_downloads')` — nếu native trả lỗi `permission_denied` (chỉ Android 8–9), xin quyền qua `permission_handler` rồi gọi lại 1 lần; từ chối ⇒ ném `ReportStoragePermissionDeniedException`
- [X] T006 Sửa `app/sora_thu_chi/lib/core/report/export_share.dart`: đổi `ShareExport`/`defaultShareExport` sang chia sẻ bằng `XFile(filePath, ...)` từ tệp đã lưu thay vì `XFile.fromData(bytes)`; bỏ `fileNameOverrides` (không còn cần vì tên lấy thẳng từ file thật)

**Checkpoint**: `flutter build apk --debug` xanh (xác nhận Kotlin biên dịch đúng), `flutter analyze` sạch.

## Pha 3: User Story 1 - Thông báo đường dẫn khi xuất thành công (Ưu tiên: P1)

**Mục tiêu**: Xuất báo cáo thành công (PDF/Excel/CSV) → file được ghi vào Downloads công khai → SnackBar báo đường dẫn/tên tệp trước khi mở bảng chia sẻ hệ thống, độc lập với việc người dùng thao tác tiếp trên bảng chia sẻ hay không (FR-001, FR-002, FR-003, FR-007, SC-001, SC-002).

**Tiêu chí kiểm thử độc lập**: Chạy widget test với seam `save`/`share` giả — bấm "Xuất báo cáo" → SnackBar chứa tên tệp/đường dẫn xuất hiện **trước** khi seam `share` được gọi, và seam `share` nhận đúng path đã lưu.

- [X] T007 [US1] Sửa `app/sora_thu_chi/lib/screens/report_export_screen.dart`: thêm tham số optional `save` (kiểu `SaveReportFile?`) vào constructor `ReportExportScreen`, mặc định dùng `defaultSaveReportFile` khi gọi
- [X] T008 [US1] Sửa `_export()` trong `app/sora_thu_chi/lib/screens/report_export_screen.dart`: sau khi dựng `bytes`, gọi `save(...)` → nhận `SavedReportFile`; bắt riêng `ReportStoragePermissionDeniedException` (SnackBar "Cần quyền lưu trữ để lưu tệp báo cáo", FR-005) tách khỏi nhánh lỗi chung "Không tạo được tệp báo cáo" (FR-006) — cả hai đều không hiện SnackBar path, không gọi `share`
- [X] T009 [US1] Trong `_export()`, sau khi `save` thành công: `ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(...)` với nội dung nêu tên tệp + "Tải xuống" (khóa `.trParams`) — thực hiện **trước** khi gọi `share`; `clearSnackBars()` thêm vào cả 2 nhánh lỗi để tránh SnackBar xếp hàng làm test/thực tế không xác định
- [X] T010 [US1] Đổi lời gọi `share` trong `_export()` để truyền `fileName`/`filePath` từ `SavedReportFile` (khớp chữ ký đã sửa ở T006) thay vì bytes RAM (FR-007)
- [X] T011 [P] [US1] Thêm khóa dịch mới vào `app/sora_thu_chi/lib/core/locale/sora_translations.dart`: `'Đã lưu @file vào Tải xuống'` và `'Cần quyền lưu trữ để lưu tệp báo cáo'` (bản tiếng Anh trong map `_en`)
- [X] T012 [US1] Sửa `app/sora_thu_chi/test/report_export_screen_test.dart`: thêm `_FakeSave` (seam `SaveReportFile` giả, ghi lại lời gọi, hỗ trợ cờ `fail`/`permissionDenied`), đổi `_FakeShare` sang chữ ký mới (`filePath` thay `bytes`), thêm tham số `save` vào `_pump()`, cập nhật mọi test case tap "export-button" hiện có để bơm cả `save` lẫn `share` giả (bytes giờ được assert ở phía `save.calls`, không còn ở `share.calls`)
- [X] T013 [US1] Thêm test case trong `app/sora_thu_chi/test/report_export_screen_test.dart`: bấm "Xuất báo cáo" thành công → SnackBar chứa tên tệp hiện ra, `share.calls` nhận đúng `filePath` khớp `save` trả về (FR-002, FR-003, FR-007)
- [X] T014 [US1] Thêm 2 test case trong `app/sora_thu_chi/test/report_export_screen_test.dart`: (a) seam `save` ném lỗi thường → SnackBar "Không tạo được tệp báo cáo", `share` không được gọi (FR-006); (b) seam `save` ném `ReportStoragePermissionDeniedException` → SnackBar "Cần quyền lưu trữ để lưu tệp báo cáo" riêng biệt, `share` không được gọi (FR-005)

**Checkpoint**: `flutter test test/report_export_screen_test.dart` xanh (27/27), `flutter analyze` sạch.

## Pha cuối: Polish & Cross-cutting

- [X] T015 Docblock ở `export_share.dart`/`report_file_save.dart`/`ReportDownloadsChannel.kt`/`ReportDownloadsChannel.swift` đã viết mô tả đúng hành vi mới ngay khi tạo (chia sẻ từ file đã lưu, không còn "không giữ tệp nào sau khi chia sẻ") — không có comment cũ sai sót cần dọn thêm
- [X] T016 Chạy toàn bộ `flutter test` (1376/1376 pass, 0 đỏ — test đỏ có sẵn trước đây ở `transactions_dao_test` đã được sửa ở PBI nào đó trước PBI 41, không còn tồn tại) + `flutter analyze` (sạch) + `flutter build apk --debug` (xanh) tại `app/sora_thu_chi/`
- [X] T017 QA tay theo `quickstart.md` trên thiết bị Android thật — người dùng xác nhận đạt sau khi sửa lỗi path tuyệt đối bên dưới. iOS chưa QA (không có máy).

### Lỗi QA đã sửa

- **Lỗi**: QA thật trên máy phát hiện chia sẻ báo `PlatformException(Share failed, ... NoSuchFileException: Download/bao-cao-thu-chi_....xlsx: The source file doesn't exist.)` ngay sau khi lưu thành công (SnackBar path hiện đúng, nhưng bước gọi `share` sau đó lỗi).
- **Nguyên nhân**: `saveViaMediaStore` trong `ReportDownloadsChannel.kt` trả `path` **tương đối** (`"Download/<tên>"`, từ `RELATIVE_PATH` dùng để ghi qua MediaStore) thay vì path tuyệt đối; `share_plus` mở file bằng `File(path)` nên không tìm thấy.
- **Đã sửa**: đổi sang trả `File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), actualName).absolutePath` (path tuyệt đối thật, ví dụ `/storage/emulated/0/Download/<tên>`) — xem `research.md` Quyết định 1, đoạn "Bẫy đã gặp khi QA tay". `flutter build apk --debug` lại xanh sau khi sửa; cần QA lại Kịch bản A ở `quickstart.md` để xác nhận chia sẻ không còn lỗi.

## Sơ đồ phụ thuộc

- Pha 1 (T001) → Pha 2 (T002–T006) → Pha 3/US1 (T007–T014) → Pha cuối (T015–T017).
- T002/T003 (Android) độc lập với T004 (iOS) — có thể song song, nhưng đã làm tuần tự trong phiên này.
- T006 phải xong trước T010 (chữ ký `share` mới).
- T012 phải xong trước T013/T014 (cần helper `_pump`/`_FakeSave` mới).
- Chỉ có **1 User Story** (spec.md không chia P1/P2/P3 nhiều luồng).

## Chiến lược triển khai

- **MVP đề xuất**: toàn bộ Pha 1–3 (T001–T014) — đã hoàn tất, đây là toàn bộ phạm vi tính năng.
- **Thứ tự đã triển khai**: Setup (thử & loại `file_saver`, chọn hướng đúng) → Foundational (kênh native 2 nền tảng + seam Dart + đổi seam chia sẻ) → US1 (nối vào UI + SnackBar + test) → Polish (build xanh, test xanh; QA tay còn lại).
- **Còn lại duy nhất**: T017 (QA tay trên thiết bị/emulator thật) — cần người dùng thực hiện, không tự động hoá được trong phiên này.
