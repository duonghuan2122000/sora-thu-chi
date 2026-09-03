# Quickstart — PBI 1: Hạ tầng thư viện nền tảng

Kịch bản kiểm thử tích hợp nhanh + quy trình cài đặt lặp lại được (FR-006, SC-001). Làm theo từng bước trên **bản sao dự án sạch**.

## Tiền đề

- Flutter stable 3.44.x, Dart 3.12.x (khớp `environment.sdk` trong pubspec).
- Android emulator (API ≥ 24) khởi động sẵn — máy kiểm chứng này dùng API 37.
- Máy Windows: iOS chỉ kiểm chứng được khi có máy macOS.

## Bước 1 — Thêm thư viện (chạy từ `app/sora_thu_chi/`)

```bash
flutter pub add drift:^2.34.4 get:^4.7.3 fl_chart:^1.2.0 flutter_secure_storage:^11.0.0 local_auth:^3.0.2
```

Kết quả mong đợi: pubspec.yaml ghi 5 dependency kèm phiên bản khóa, `pubspec.lock` được tạo/cập nhật (commit lockfile).

## Bước 2 — Cấu hình nền tảng tối thiểu

1. `android/app/src/main/AndroidManifest.xml`: trong thẻ `<application>` thêm thuộc tính `android:allowBackup="false"`.
2. `ios/Runner/Info.plist`: thêm key `NSFaceIDUsageDescription` với nội dung tiếng Việt giải thích dùng FaceID để mở khóa app.

## Bước 3 — Kiểm tra tĩnh & biên dịch

```bash
flutter pub get
flutter analyze        # kỳ vọng: No issues found (không lỗi mới từ thư viện — FR-003/SC-004)
flutter build apk --debug   # kỳ vọng: build thành công
```

> Lưu ý (đã xác minh 2026-09-03): `flutter_secure_storage` 11 yêu cầu `compileSdk` ≥ 37, trong khi Flutter mặc định 36 → lần build đầu sẽ báo lỗi và tự cài Android SDK Platform 37. Nếu gặp lỗi "requires Android SDK version 37 or higher", chỉnh `compileSdk = 37` trong `android/app/build.gradle.kts` rồi build lại. `minSdk` mặc định 24 giữ nguyên.

## Bước 4 — Khởi động app trên thiết bị (FR-004/SC-002)

```bash
flutter run -d emulator-5554
```

Kỳ vọng: màn hình mặc định (counter) hiển thị bình thường, không crash khi khởi động.

## Bước 5 — Kiểm chứng từng thư viện (SC-003)

Tạo file smoke tạm `lib/smoke_verify.dart` (điểm vào chạy bằng `flutter run -t`), mỗi thư viện gọi 1 đối tượng chính và in PASS:

| Thư viện | Thao tác |
|---|---|
| drift | `NativeDatabase.memory()` + chạy 1 query |
| GetX | `Get.put(...)` + `GetMaterialApp` |
| fl_chart | dựng `PieChart(PieChartData(...))` |
| flutter_secure_storage | ghi → đọc 1 key |
| local_auth | `canCheckBiometrics` |

Chạy: `flutter run -t lib/smoke_verify.dart -d emulator-5554` → đủ 5 dòng PASS. Sau đó **xóa file** (code xác minh không ở lại repo).

## Bước 6 — Kết quả trên iOS

Máy Windows không build iOS được. Ghi trạng thái: cấu hình Info.plist đã thêm đúng chỗ; kiểm chứng build/chạy iOS + keychain entitlement **chờ máy macOS**, không bỏ ngang (SC-005).
