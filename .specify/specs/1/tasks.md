# Danh sách Task: Hạ tầng thư viện nền tảng

**Mã PBI**: 1
**Nguồn**: plan.md, spec.md, research.md, quickstart.md

> PBI hạ tầng (không có user story nghiệp vụ — spec không liệt kê mức ưu tiên P1/P2/P3). Do đó **không dùng nhãn `[USn]`** ở bất kỳ task nào. Thứ tự thực thi là tuyến tính theo quickstart.md (bước 1→6).

## Pha 1: Setup

- [X] T001 Xác minh môi trường trong `app/sora_thu_chi/`: chạy `flutter --version` (kỳ vọng Flutter 3.44.6 / Dart 3.12.2, khớp `environment.sdk` trong `pubspec.yaml`) và `flutter doctor`; nếu Android toolchain thiếu cmdline-tools hoặc license chưa accept → chạy `flutter doctor --android-licenses`. Xác nhận emulator Android API ≥ 24 (máy kiểm chứng dùng API 37) sẵn sàng qua `flutter devices`. Nếu build vẫn bị chặn → ghi trạng thái và áp fallback (chạy web cho drift/GetX/fl_chart, ghi rõ secure_storage/local_auth chưa verify) theo `research.md` §Rủi ro, không bỏ ngang.

## Pha 2: Foundational

- [X] T002 Thêm 5 dependency runtime khóa phiên bản vào `app/sora_thu_chi/pubspec.yaml` bằng lệnh (chạy trong `app/sora_thu_chi/`): `flutter pub add drift:^2.34.4 get:^4.7.3 fl_chart:^1.2.0 flutter_secure_storage:^11.0.0 local_auth:^3.0.2`. Xác nhận `pubspec.yaml` ghi đủ 5 dòng dependency kèm phiên bản `^` cụ thể; `pubspec.lock` được tạo/cập nhật và phải được commit (không dùng `any`/không để phiên bản trôi — FR-001/FR-002).
- [X] T003 [P] Thêm thuộc tính `android:allowBackup="false"` vào thẻ `<application>` trong `app/sora_thu_chi/android/app/src/main/AndroidManifest.xml` (FR-005 — chống `InvalidKeyException` của flutter_secure_storage khi Android auto-backup/restore làm mất khóa mã hóa). Không thêm permission nào khác.
- [X] T004 [P] Thêm key `NSFaceIDUsageDescription` (chuỗi tiếng Việt giải thích dùng FaceID để mở khóa app) vào `app/sora_thu_chi/ios/Runner/Info.plist` (FR-005 — local_auth crash nếu thiếu key). Không thêm keychain entitlement (hoãn tới khi có máy macOS — plan §Rủi ro).
- [X] T005 Chạy `flutter pub get` rồi `flutter analyze` trong `app/sora_thu_chi/` → kỳ vọng "No issues found", không có lỗi phân tích mã nguồn mới phát sinh do thư viện (FR-003/SC-004).

## Pha 3: Kiểm chứng biên dịch, khởi động & từng thư viện

- [X] T006 Build APK debug trong `app/sora_thu_chi/`: `flutter build apk --debug` → build thành công. Nếu plugin đòi `compileSdk` cao hơn mặc định → nâng cụ thể `compileSdk` trong `app/sora_thu_chi/android/app/build.gradle.kts` và ghi lý do (plan §Rủi ro); `minSdk` mặc định 24 đã đủ, không chỉnh (research.md §minSdk).
- [X] T007 Khởi động app trên emulator: `flutter run -d <device-id>` trong `app/sora_thu_chi/` → màn hình mặc định (counter demo, `lib/main.dart`) hiển thị bình thường, không crash lúc khởi động do thư viện (FR-004/SC-002). Xác nhận không sửa `lib/main.dart`/logic nghiệp vụ.
- [X] T008 Tạo file smoke tạm `app/sora_thu_chi/lib/smoke_verify.dart` (điểm vào chạy bằng `flutter run -t`), mỗi thư viện gọi **1** đối tượng chính rồi in PASS: drift → `NativeDatabase.memory()` + chạy 1 query; GetX → `Get.put(...)` + dựng `GetMaterialApp`; fl_chart → dựng `PieChart(PieChartData(...))`; flutter_secure_storage → ghi→đọc round-trip 1 key; local_auth → `canCheckBiometrics`. Chú ý `WidgetsFlutterBinding.ensureInitialized()` và `await` đúng cho các plugin channel (SC-003).
- [X] T009 Chạy file smoke: `flutter run -t lib/smoke_verify.dart -d <device-id>` trong `app/sora_thu_chi/` → đủ 5 dòng PASS. Nếu drift báo thiếu native sqlite lúc chạy trên thiết bị → mở lại nghiên cứu, **không** quay về `sqlite3_flutter_libs` cũ (plan §Rủi ro). (SC-003)
- [X] T010 Sau khi smoke pass: xóa file tạm `app/sora_thu_chi/lib/smoke_verify.dart`, chạy lại `flutter analyze` trong `app/sora_thu_chi/` → vẫn sạch. Không để code xác minh ở lại repo (git history giữ kết quả).

## Pha cuối: Polish & Cross-cutting

- [X] T011 Đối chiếu quy trình trong `.specify/specs/1/quickstart.md` (6 bước, chạy trên bản sao dự án sạch) với kết quả thực thi thực tế → xác nhận cài đặt lặp lại được từ đầu, không bước nào phụ thuộc thao tác tay bí mật (FR-006/SC-001). Nếu bước nào lệch/thiếu → cập nhật `quickstart.md`.
- [X] T012 Ghi trạng thái iOS vào `.specify/specs/1/plan.md` §Rủi ro & ngoại lệ: `ios/Runner/Info.plist` đã thêm `NSFaceIDUsageDescription` đúng chỗ; build/chạy iOS + keychain entitlement chờ máy macOS — ghi rõ trạng thái và lý do, không bỏ ngang (SC-005).
- [X] T013 Rà soát phạm vi cuối: `git status` trong `app/sora_thu_chi/` chỉ gồm thay đổi file cấu hình cho phép + `pubspec.lock` theo plan.md §Cấu trúc dự án; không còn file code mới (ngoài `pubspec.lock`), không sửa `lib/main.dart`. Đối chiếu và ghi trạng thái đạt/không đạt của từng tiêu chí SC-001..SC-005 vào ghi chú cuối tasks.md này.

## Sơ đồ phụ thuộc

Thứ tự thực hiện (tuyến tính theo quickstart, chỉ T003/T004 song song với nhau):

```
T001 → T002 → (T003 ∥ T004) → T005 → T006 → T007 → T008 → T009 → T010 → (T011 → T012 → T013)
```

- `T003` (sửa AndroidManifest.xml) và `T004` (sửa Info.plist) **khác file, không phụ thuộc nhau** → chạy song song.
- Mọi task sau `T002` đều phụ thuộc dependency đã cài. `T005`–`T010` phụ thuộc cấu hình nền tảng (`T003`/`T004`) hoàn tất.
- `T006` → `T007` → `T008`/`T009` tuần tự (build xong mới run, run OK mới verify smoke).
- `T011`–`T013` là kiểm tra/ghi nhận cuối, làm sau khi toàn bộ pha trên xong.

## Chiến lược triển khai

- PBI không có user story riêng lẻ → không có "MVP = US1". Toàn bộ là 1 lát cắt hạ tầng: cài đặt → cấu hình → kiểm chứng.
- Điểm giao hàng tối thiểu dừng được sớm: sau `T005` (analyze sạch) + `T006` (build APK OK) — chứng minh thư viện không phá build; `T007`–`T010` là kiểm chứng chạy thật & từng thư viện (SC-003) bắt buộc để đóng spec.
- Thư viện codegen (`drift_dev`/`build_runner`) **không** cài đợt này — thêm khi module dữ liệu drift đầu tiên (research.md §Quyết định).

## Ghi chú cuối (2026-09-03, sau thi công T001–T013)

Đối chiếu tiêu chí thành công (spec.md §Tiêu chí thành công):

| Tiêu chí | Kết quả | Ghi chú |
|---|---|---|
| SC-001 — cài lại được từ bản sạch | ✅ ĐẠT | 5 dependency khóa `^` cụ thể; `pubspec.lock` tracked (sẽ commit); quickstart.md đã cập nhật lưu ý nâng `compileSdk = 37` cho máy sạch. |
| SC-002 — app khởi động không lỗi | ✅ ĐẠT | `flutter run` counter demo trên emulator API 37, màn hình hiển thị bình thường (xem screenshot T007), không crash. |
| SC-003 — từng thư viện hoạt động | ✅ ĐẠT | Smoke tạm 5/5 PASS trên thiết bị: drift (NativeDatabase.memory + SELECT 1), get (Get.put + GetMaterialApp), fl_chart (PieChart), flutter_secure_storage (round-trip), local_auth (canCheckBiometrics = true). File đã xóa. |
| SC-004 — analyze không lỗi từ thư viện | ✅ ĐẠT | `flutter analyze` sau khi dọn: "No issues found!". |
| SC-005 — nền tảng chưa verify ghi rõ | ✅ ĐẠT | Android verify đầy đủ. iOS: `NSFaceIDUsageDescription` đã thêm; build/chạy iOS + keychain entitlement chờ máy macOS — đã ghi vào plan.md §Rủi ro (mục "Trạng thái sau thi công"). |

Ngoài lề (ngoài phạm vi task): xuất hiện root `.gitignore` (template toptal flutter/dart) trong phiên thi công — không thuộc task nào tạo, nội dung lành tính (trùng pattern vốn đã có ở `.gitignore` cấp app), không ảnh hưởng kết quả. Người duyệt tự quyết giữ/commit/xóa.
