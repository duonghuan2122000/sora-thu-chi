# Research: PBI 41 — Thông báo đường dẫn file xuất báo cáo

## Quyết định 1 — Cách ghi file vào Downloads công khai

- **Quyết định (đã sửa sau khi thử thật)**: Tự viết **platform channel Kotlin** mới (theo đúng khuôn `DeviceProbeChannel.kt`/`GenAiChannel.kt` đã có trong `android/app/src/main/kotlin/com/sorathuchi/sora_thu_chi/`) gọi `MediaStore.Downloads` trên Android 10+ (API 29+), và ghi trực tiếp vào `Environment.DIRECTORY_DOWNLOADS` kèm xin quyền `WRITE_EXTERNAL_STORAGE` runtime trên Android 8–9 (API 26–28, khớp `minSdk 26` hiện tại).
- **Lý do đổi quyết định ban đầu**: Quyết định đầu tiên chọn dependency `file_saver` — nhưng khi đọc thẳng mã nguồn Android của cả `file_saver 0.2.14` **và** `0.4.0` (đã thử cài cả hai, xem `android/src/main/kotlin/.../FileSaverPlugin.kt`, hàm `saveFile()`), method `saveFile()` (không mở dialog) chỉ ghi vào `context.getExternalFilesDir(null)` — **thư mục riêng app**, không phải Downloads công khai. Chỉ `saveAs()` (mở hộp thoại SAF cho người dùng tự chọn nơi lưu) mới chạm được Downloads thật. Vì spec chốt "tự động lưu, không thao tác thêm" (Giả định #3), `file_saver` **không đáp ứng được FR-001/SC-002** — đã gỡ dependency này khỏi `pubspec.yaml`.
- **Lý do chọn platform channel tự viết**:
  - Không có dependency nào đã cài đặt/phổ biến giải quyết đúng việc "tự động ghi vào MediaStore Downloads, không SAF dialog" (đã kiểm chứng `file_saver` không làm được; `file_picker` — rung thang thấp hơn — buộc mở SAF dialog, cùng vấn đề).
  - `MediaStore.Downloads` là API nền tảng chuẩn của Android cho đúng việc này; code cần thiết ngắn (~1 file Kotlin, theo khuôn kênh native đã có sẵn trong repo).
  - Trên Android 10+ (chiếm hầu hết thiết bị thật năm 2026), insert qua `MediaStore.Downloads.EXTERNAL_CONTENT_URI` **không cần xin quyền runtime**, và **tự động đổi tên tránh trùng** (`DISPLAY_NAME` trùng ⇒ hệ thống tự thêm hậu tố) — giúp đơn giản hoá một phần FR-004 trên nền tảng này.
  - **Bẫy đã gặp khi QA tay (đã sửa)**: `RELATIVE_PATH` (`MediaStore.MediaColumns.RELATIVE_PATH = "Download"`) chỉ dùng để **ghi** qua MediaStore — không phải path thật để đọc lại. Bản đầu trả thẳng chuỗi `"Download/<tên>"` (tương đối) làm `path` cho seam `share`; `share_plus` (native `Share.kt`) mở file để copy vào cache chia sẻ bằng `File(path)` — path tương đối này không trỏ đúng chỗ ⇒ `PlatformException(Share failed, ... NoSuchFileException: Download/... doesn't exist.)`. Sửa bằng cách quy `path` trả về thành đường dẫn **tuyệt đối**: `File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), actualName).absolutePath` (tức `/storage/emulated/0/Download/<tên>`) — vẫn đúng vị trí file MediaStore vừa ghi vì `DIRECTORY_DOWNLOADS` ánh xạ tới đúng thư mục công khai đó trên bộ nhớ trong.
  - Trên Android 8–9 (API 26–28, đúng đáy `minSdk` hiện tại), scoped storage chưa áp dụng nhưng ghi vào thư mục công khai vẫn cần quyền `WRITE_EXTERNAL_STORAGE` runtime (API 23+) — channel tự xin quyền qua `ActivityCompat.requestPermissions` + `PluginRegistry.RequestPermissionsResultListener` (khuôn tương tự các plugin xin quyền khác), và tự dò trùng tên bằng vòng lặp `File.exists()` (MediaStore không áp dụng ở nhánh này).
  - iOS: ghi vào `NSSearchPathForDirectoriesInDomains(.documentDirectory)` của app rồi báo path đó — khớp Giả định #1 trong spec.md (không có khái niệm Downloads công khai y hệt Android, dùng thư mục gần nhất người dùng mở được qua app Files).
- **Phương án khác đã xem xét**:
  - `file_saver` (mọi phiên bản có trên pub.dev tại thời điểm viết) — loại vì lý do trên (đã thực nghiệm, không phải suy đoán).
  - `file_picker` với `FilePicker.platform.saveFile()` — mở SAF dialog mỗi lần, trái luồng chính "tự động lưu" đã chốt trong spec.
  - `permission_handler` + ghi `dart:io` trực tiếp path `/storage/emulated/0/Download` cho **mọi** phiên bản Android — vỡ trên Android 10+ (`compileSdk 37`) do scoped storage; chỉ dùng đường này riêng cho nhánh legacy API 26–28 như quyết định đã chọn.

## Quyết định 2 — Vị trí nối vào luồng xuất hiện có

- **Quyết định**: Thêm bước ghi file (seam mới, tương tự `ShareExport`) vào giữa bước dựng bytes và bước gọi `ShareExport` trong `_export()` của `report_export_screen.dart`; đổi `defaultShareExport`/`ShareExport` để chia sẻ **từ file đã lưu** (`XFile(path)`) thay vì `XFile.fromData(bytes)`.
- **Lý do**: FR-007 yêu cầu bảng chia sẻ dùng chính tệp đã ghi — tránh giữ 2 nguồn bytes khác nhau (RAM vs file) có thể lệch nhau; cũng bỏ được nhu cầu `fileNameOverrides` cũ (tên tệp giờ lấy thẳng từ file đã lưu).
- **Phương án khác đã xem xét**: Giữ nguyên `defaultShareExport` share bằng bytes RAM như cũ, chỉ ghi thêm 1 bản sao ra Downloads song song (2 nguồn độc lập) — bị loại vì tạo 2 lần ghi/encode không cần thiết và có nguy cơ tên tệp hiển thị trong thông báo lệch với tên tệp thật sự được chia sẻ.

## Quyết định 3 — Xử lý trùng tên tệp

- **Quyết định**: Trước khi ghi, kiểm tra tên đề xuất đã tồn tại trong Downloads chưa (qua kết quả trả về của `file_saver`/kiểm tra tồn tại nếu API hỗ trợ); nếu trùng, thêm hậu tố ` (2)`, ` (3)`... theo đúng quy ước đặt tên trùng quen thuộc của hệ điều hành, giữ nguyên phần mở rộng.
- **Lý do**: Khớp FR-004 và trường hợp biên đã chốt trong spec; quy ước ` (n)` là điều người dùng đã quen từ trình duyệt/hệ điều hành, không cần giải thích thêm trong UI.
- **Phương án khác đã xem xét**: Nhúng timestamp vào mọi tên tệp xuất (luôn duy nhất, không cần kiểm tra trùng) — bị loại vì đổi format tên tệp mặc định hiện có (`data.fileName` từ PBI 27, ví dụ theo khoảng ngày/bộ lọc) mà spec không yêu cầu đổi cho luồng không trùng tên.
