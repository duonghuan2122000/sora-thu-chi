# Research — PBI 1: Hạ tầng thư viện nền tảng

**Ngày**: 2026-09-03
**Môi trường khảo sát**: Flutter 3.44.6 (stable) / Dart 3.12.2, máy Windows 11, Android emulator API 37 (Android 17) đang chạy.

## Quyết định: danh sách thư viện & phiên bản

Phạm vi MVP theo spec §Giả định — khóa app, ví, giao dịch, danh mục, báo cáo cơ bản.

| Năng lực | Thư viện | Phiên bản khóa | Loại |
|---|---|---|---|
| Lưu trữ & truy vấn dữ liệu local | `drift` | ^2.34.4 | runtime |
| Quản lý state & điều hướng | `get` (GetX) | ^4.7.3 | runtime |
| Vẽ biểu đồ báo cáo | `fl_chart` | ^1.2.0 | runtime |
| Lưu bí mật (mã PIN, khóa) | `flutter_secure_storage` | ^11.0.0 | runtime |
| Xác thực sinh trắc học | `local_auth` | ^3.0.2 | runtime |

- **Lý do chọn**: đúng danh sách đã chốt trong `docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md` §Stack kỹ thuật Flutter.
- **Khóa phiên bản**: dùng `^` với phiên bản cụ thể đang là latest stable (không dùng `any`/không để trôi); `pubspec.lock` của app được commit → cài lặp lại được (SC-001).
- **Phương án khác đã xem xét**: không xem xét thay thế — stack đã đóng trong docs, spec không mở lại lựa chọn thư viện.

## Quyết định: KHÔNG thêm sqlite3_flutter_libs

- drift 2.34.x phụ thuộc runtime vào `sqlite3` 3.x, bản thân sqlite3 3.x tự bundle native SQLite cho Flutter (Android/iOS).
- `sqlite3_flutter_libs` đã **EOL** (0.6.0+eol) — chỉ còn là dependency guard chặn sqlite3 2.x, không bundle gì.
- **Quyết định**: chỉ thêm `drift`. Nếu khi chạy trên thiết bị drift báo thiếu native sqlite → mở lại, nhưng không được quay về sqlite3_flutter_libs 0.5.x.

## Quyết định: KHÔNG thêm drift_dev / build_runner trong PBI này

- drift_dev + build_runner là công cụ sinh code (codegen) **chỉ dùng khi có bảng dữ liệu**. PBI này chưa có bảng nào.
- Thêm vào lúc PBI module dữ liệu đầu tiên (bảng drift đầu tiên), cài phiên bản đi kèm đúng drift — tránh phình dependency, tránh lệch phiên bản.
- **Phương án khác**: thêm ngay để "đủ toolchain" — từ chối vì YAGNI, dev-only, không ảnh hưởng build/runtime.

## Quyết định: minSdk — không chỉnh

- Flutter 3.44.6 default `minSdkVersion = 24` (FlutterExtension.kt).
- `flutter_secure_storage` 11 cần minSdk 23; `local_auth` 3 cần SDK 24+, iOS 13+.
- → 24 đáp ứng cả hai. Không sửa `android/app/build.gradle.kts`.

## Quyết định: cấu hình nền tảng tối thiểu (FR-005)

1. **Android** — `android/app/src/main/AndroidManifest.xml`: thêm `android:allowBackup="false"` vào `<application>`.
   - Lý do: flutter_secure_storage README — tránh `InvalidKeyException` khi Android auto-backup/restore làm mất khóa mã hóa (Android 6+).
   - Khớp nghiệp vụ: app offline, backup là thủ công bằng file JSON (GĐ3) → không cần auto-backup của hệ thống.
   - Không thêm permission USE_BIOMETRIC: dùng local_auth riêng cho sinh trắc học, không lưu khóa biometric trong secure_storage ở phạm vi này.
2. **iOS** — `ios/Runner/Info.plist`: thêm `NSFaceIDUsageDescription` (chuỗi tiếng Việt giải thích lý do dùng FaceID).
   - Yêu cầu của local_auth: thiếu key → app crash khi gọi FaceID.
3. **iOS Keychain entitlement (keychain-access-groups)**: theo README flutter_secure_storage nên thêm, nhưng **hoãn** — máy Windows không thể build/kiểm chứng iOS; thêm khi có máy macOS ở phase kiểm chứng iOS. Ghi vào rủi ro, không bỏ ngang (đúng SC-005).

## Quyết định: cách kiểm chứng từng thư viện (SC-003)

- **Phương án**: file smoke tạm (không phải logic nghiệp vụ, không phải tính năng) chạy trên Android emulator, mỗi thư viện gọi 1 lần vào đối tượng chính và in `PASS`:
  - drift → mở DB trong bộ nhớ `NativeDatabase.memory()` + query đơn giản
  - GetX → `Get.put` + dựng `GetMaterialApp`
  - fl_chart → dựng `PieChart(PieChartData(...))`
  - flutter_secure_storage → ghi/đọc round-trip 1 key
  - local_auth → `canCheckBiometrics`
- **Sau khi pass**: xóa file smoke. Tránh để code xác minh chết trong repo; lịch sử git giữ kết quả.
- **Phương án khác**: giữ file test vĩnh viễn — từ chối vì đòi dependency `integration_test` + bảo trì thừa, vi phạm tinh thần "không dựng logic".
- **Rủi ro**: nếu build Android bị chặn bởi lỗi doctor (thiếu cmdline-tools / license chưa accept) → xử: accept license `flutter doctor --android-licenses`, fallback chạy trên Chrome (web) cho phần drift/GetX/fl_chart, secure_storage web chỉ chạy trên https/localhost, local_auth không hỗ trợ web → ghi trạng thái, không bỏ ngang.

## Quyết định: không sửa code nghiệp vụ

- PBI này không đụng `lib/` logic. `lib/main.dart` counter demo giữ nguyên để chứng minh app khởi động (FR-004). Mọi thư viện chỉ khai báo, chưa import vào luồng app.
