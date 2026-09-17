# Kế hoạch triển khai: Thông báo đường dẫn file xuất báo cáo

**Mã PBI**: 41
**Liên kết spec**: .specify/specs/41/spec.md
**Ngày tạo**: 2026-09-17

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart / Flutter (SDK ^3.12.2) |
| Framework / Thư viện chính | Flutter + GetX (state), màn hiện có `report_export_screen.dart` (PBI 27) |
| Lưu trữ dữ liệu | Không đụng DB (drift) — chỉ ghi file ra bộ nhớ thiết bị (Downloads công khai) qua **platform channel Kotlin/Swift tự viết** (`sora_thu_chi/report_downloads`, xem `research.md` Quyết định 1 — bản sửa sau khi `file_saver` được xác nhận không đáp ứng) |
| Kiểm thử | `flutter test` — seam giả lập `ShareExport` đã có + seam mới `SaveReportFile` (kiểu bơm bản giả tương tự, không đụng kênh native/plugin quyền trong test) |
| Nền tảng triển khai | Android (minSdk 26, compileSdk 37) là chính — kênh native đủ cả 2 nhánh (MediaStore API 29+, ghi trực tiếp + quyền runtime API 26–28); iOS có bản Swift tương ứng (ghi Documents) nhưng plan này QA chính trên Android theo khuôn PBI 27 → ghi chú "iOS chưa QA" nếu không có máy |
| Ràng buộc hiệu năng | Không có (ghi 1 file nhỏ, tác vụ tức thời, không cần isolate riêng ngoài `compute` đã có để dựng bytes) |
| Ràng buộc khác | Không đổi format tên tệp mặc định hiện có trừ khi trùng tên (thêm hậu tố ` (n)`); không giữ 2 nguồn bytes khác nhau cho lưu và chia sẻ (FR-007) |

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

*(Không có `.specify/memory/constitution.md` trong repo — bỏ qua bước đối chiếu hiến pháp, dùng nguyên tắc chung trong `CLAUDE.md`.)*

| Nguyên tắc (từ CLAUDE.md) | Tuân thủ? | Ghi chú |
|---|---|---|
| Đọc doc/wiki nghiệp vụ trước khi đổi | ✅ | Đã đọc `docs/report/bao-cao-thong-ke-giai-phap.md` §3.7 và code hiện có (`report_export_screen.dart`, `export_share.dart`) |
| Không phá luồng nghiệp vụ đã chốt khác | ✅ | Không đụng số dư ví/giao dịch/ngân sách; chỉ đổi hành vi xuất báo cáo |
| Design system (SnackBar, không popup mới) | ✅ | Dùng lại `ScaffoldMessenger`/SnackBar sẵn có trong màn, không thêm màn/hộp thoại mới |

## Giai đoạn 0 — Nghiên cứu

Xem `research.md`. Tóm tắt các quyết định chính:

- **Quyết định 1 (đã sửa sau khi thử thật)**: Ban đầu chọn dependency `file_saver` — đọc thẳng mã nguồn Android của cả 2 phiên bản đã thử (0.2.14 và 0.4.0) cho thấy `saveFile()` (đường tự động, không SAF dialog) chỉ ghi vào `getExternalFilesDir(null)` — thư mục **riêng app**, không phải Downloads công khai. Đã gỡ dependency này, thay bằng **platform channel Kotlin/Swift tự viết** (`sora_thu_chi/report_downloads`, theo khuôn `DeviceProbeChannel.kt`/`GenAiChannel.kt` đã có trong repo): MediaStore trên Android 10+ (không cần quyền, tự dò trùng tên), ghi trực tiếp + `permission_handler` xin quyền runtime trên Android 8–9. Xem chi tiết `research.md`.
- **Quyết định 2**: Thêm bước lưu file vào `_export()` của `report_export_screen.dart`, xen giữa dựng bytes và gọi `ShareExport`; đổi `ShareExport`/`defaultShareExport` sang chia sẻ từ file đã lưu (`XFile(path)`) thay vì bytes RAM. **Lý do**: FR-007, tránh 2 nguồn dữ liệu lệch nhau.
- **Quyết định 3**: Trùng tên → hệ thống (MediaStore trên Android 10+) hoặc kênh native (vòng lặp `File.exists()` trên Android 8–9/iOS) tự thêm hậu tố ` (2)`, ` (3)`... giữ nguyên phần mở rộng — xử lý hoàn toàn ở tầng native, Dart không cần logic dò trùng riêng.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: không áp dụng — tính năng không thêm/đổi thực thể dữ liệu bền vững (không bảng DB mới); bỏ qua `data-model.md`.
- **Hợp đồng giao diện**: không áp dụng — không có API/CLI công khai; bỏ qua `contracts/`.
- **Kịch bản khởi động nhanh**: xem `quickstart.md` (6 kịch bản A–F: xuất lần đầu, trùng tên, 3 định dạng, lỗi dựng tệp, từ chối quyền, Privacy mode).

### Thiết kế seam lưu file (để test được không cần plugin/kênh native thật)

Theo đúng khuôn seam đã dùng cho `ShareExport` (`core/report/export_share.dart`):

- Thêm `core/report/report_file_save.dart`:
  - `typedef SaveReportFile = Future<SavedReportFile> Function({required String fileName, required Uint8List bytes, required String mimeType})`.
  - `SavedReportFile { path, fileName }` — `fileName` là tên **thực tế** do native trả về sau khi tự dò trùng (FR-004), có thể khác `fileName` đầu vào.
  - `ReportStoragePermissionDeniedException` — riêng cho nhánh Android 8–9 từ chối quyền (FR-005), để UI hiện đúng thông báo khác với lỗi dựng/ghi tệp chung.
  - `defaultSaveReportFile` — gọi `MethodChannel('sora_thu_chi/report_downloads')`; nếu native trả mã lỗi `permission_denied` (chỉ Android 8–9), xin quyền qua `permission_handler` rồi gọi lại 1 lần; từ chối ⇒ ném `ReportStoragePermissionDeniedException`.
- **Kênh native mới** (không phải dependency Flutter — code Kotlin/Swift trong chính app):
  - `android/app/src/main/kotlin/com/sorathuchi/sora_thu_chi/ReportDownloadsChannel.kt` — method `saveToDownloads`; API ≥29 dùng `MediaStore.Downloads` (không quyền, tự dò trùng); API 26–28 kiểm `WRITE_EXTERNAL_STORAGE` (đã xin từ Dart) rồi ghi thẳng `Environment.DIRECTORY_DOWNLOADS`, tự dò trùng bằng vòng lặp `File.exists()`.
  - `ios/Runner/ReportDownloadsChannel.swift` — ghi vào Documents của app (không có khái niệm Downloads công khai giống Android), cùng logic dò trùng.
  - Đăng ký trong `MainActivity.kt` (Android) và `AppDelegate.swift` (iOS), theo đúng khuôn `DeviceProbeChannel` đã có.
- `ReportExportScreen` nhận thêm tham số optional `save` (seam, giống `share`) — test bơm bản giả trả `SavedReportFile` cố định, không đụng kênh native thật.
- `_export()`:
  1. Dựng `bytes` như cũ (`compute`).
  2. Gọi `save` (mặc định `defaultSaveReportFile`) → nhận `SavedReportFile`.
  3. Hiện SnackBar path (FR-002) — dùng `SavedReportFile.path`/`fileName`.
  4. Gọi `share` (mặc định `defaultShareExport` đã đổi sang nhận path) với file vừa lưu (FR-007).
  5. Lỗi `ReportStoragePermissionDeniedException` ở bước 2 → SnackBar riêng "Cần quyền lưu trữ để lưu tệp báo cáo" (FR-005); lỗi khác ở bước 1/2 → nhánh lỗi hiện có (SnackBar "Không tạo được tệp báo cáo", FR-006); cả hai đều không sang bước 3/4.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Giữ nguyên hành vi lỗi hiện có (FR-006) | ✅ | Không đổi nhánh `catch` hiện có, chỉ chèn bước mới trước khi share |
| Không thêm màn hình/hộp thoại mới ngoài spec | ✅ | Chỉ 1 SnackBar bổ sung, đúng giả định trong spec.md |
| Test không phụ thuộc plugin native thật | ✅ | Seam `SaveReportFile` theo đúng khuôn `ShareExport` đã kiểm chứng ở PBI 27 |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── pubspec.yaml                                     # + dependency permission_handler (chỉ xin quyền Android 8–9)
├── android/app/src/main/AndroidManifest.xml         # + WRITE_EXTERNAL_STORAGE maxSdkVersion=28
├── android/app/src/main/kotlin/.../
│   ├── ReportDownloadsChannel.kt                     # MỚI: kênh native saveToDownloads (MediaStore / legacy + dò trùng)
│   └── MainActivity.kt                               # sửa: đăng ký kênh mới
├── ios/Runner/
│   ├── ReportDownloadsChannel.swift                  # MỚI: bản iOS (ghi Documents + dò trùng)
│   └── AppDelegate.swift                              # sửa: đăng ký kênh mới
├── lib/core/report/
│   ├── export_share.dart                             # sửa: share từ file path thay vì bytes RAM
│   └── report_file_save.dart                         # MỚI: seam SaveReportFile + defaultSaveReportFile (gọi kênh native + permission_handler)
├── lib/screens/report_export_screen.dart             # sửa: nhận seam `save`, chèn bước lưu + SnackBar path vào _export()
├── lib/core/locale/sora_translations.dart            # + 2 khóa dịch (thông báo path, thông báo thiếu quyền)
└── test/report_export_screen_test.dart                # sửa: bơm seam `save` giả, kiểm SnackBar path hiện trước khi gọi `share`
```

## Rủi ro & ngoại lệ có lý do

- **Rủi ro (đã xảy ra, đã sửa)**: Quyết định ban đầu chọn dependency `file_saver` sai — kiểm tra mã nguồn Android mới phát hiện `saveFile()` không ghi Downloads công khai. Đã gỡ dependency, chuyển sang platform channel tự viết; đã build `flutter build apk --debug` xanh để xác nhận code Kotlin biên dịch đúng.
- **Rủi ro**: thêm platform channel mới (Kotlin/Swift) ⇒ lặp lại bẫy đã gặp ở PBI 27 với `share_plus` (`MissingPluginException` nếu chỉ hot reload) — quickstart.md đã ghi rõ phải gỡ-cài-lại app trước khi QA tay.
- **Rủi ro**: hành vi lưu trên iOS khác Android (ghi Documents thay vì Downloads công khai, spec đã chấp nhận ở mục Giả định) — nếu không có máy iOS để QA, phải ghi rõ "iOS chưa QA" khi báo cáo hoàn tất (theo đúng lưu ý đã áp dụng ở PBI 27/38); code Swift chưa qua QA tay, chỉ mới đọc lại logic.
- **Không có vi phạm hiến pháp cần biện minh** — không có `constitution.md` trong repo, chỉ đối chiếu nguyên tắc chung trong `CLAUDE.md`, không phát sinh ngoại lệ.
