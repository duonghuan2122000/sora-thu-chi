# Kế hoạch triển khai: Hạ tầng thư viện nền tảng

**Mã PBI**: 1
**Liên kết spec**: .specify/specs/1/spec.md
**Ngày tạo**: 2026-09-03

## Ngữ cảnh kỹ thuật

- Ngôn ngữ / Runtime: Dart 3.12.2 (Flutter 3.44.6 stable — khảo sát trên máy)
- Framework / Thư viện chính: Flutter Mobile (Android/iOS); bổ sung `drift` 2.34.4, `get` 4.7.3, `fl_chart` 1.2.0, `flutter_secure_storage` 11.0.0, `local_auth` 3.0.2
- Lưu trữ dữ liệu: drift trên SQLite (`sqlite3` 3.x tự bundle native — không dùng `sqlite3_flutter_libs` đã EOL)
- Kiểm thử: `flutter analyze` sạch + build debug APK + chạy emulator Android (API 37); máy Windows không verify iOS
- Nền tảng triển khai: Android (kiểm chứng chính), iOS (chờ máy macOS)
- Ràng buộc hiệu năng: không áp dụng cho PBI cài thư viện
- Ràng buộc khác: app offline hoàn toàn; `minSdkVersion` mặc định 24 đáp ứng mọi thư viện (không chỉnh); giao diện/tài liệu/commit tiếng Việt có dấu

## Kiểm tra theo hiến pháp dự án

Không có `.specify/memory/constitution.md`. Đối chiếu quy ước trong `CLAUDE.md`:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không server | ✅ | Chỉ thêm thư viện local, không thư viện mạng |
| Đúng stack đã chốt trong docs | ✅ | 5 thư viện khớp §Stack kỹ thuật Flutter |
| App shell / nghiệp vụ để PBI riêng | ✅ | Không sửa logic `lib/`, giữ counter demo |
| Tài liệu & commit tiếng Việt có dấu | ✅ | plan/research/quickstart viết tiếng Việt |

Không có ngoại lệ.

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Tóm tắt quyết định chính:
- Khóa 5 thư viện runtime (bảng phiên bản trong research); commit `pubspec.lock`.
- **Bỏ `sqlite3_flutter_libs`** (EOL) — drift 2.34 dùng sqlite3 3.x tự bundle native.
- **Không thêm `drift_dev`/`build_runner`** đợt này (chưa có bảng dữ liệu — thêm khi module drift đầu tiên).
- `minSdk` mặc định 24 đủ → không sửa build.gradle.kts.
- Cấu hình nền tảng tối thiểu: `android:allowBackup="false"` (chống InvalidKeyException secure_storage) + `NSFaceIDUsageDescription` (bắt buộc local_auth iOS).
- Kiểm chứng thư viện bằng file smoke tạm trên emulator, pass rồi xóa.

## Giai đoạn 1 — Thiết kế

- Mô hình dữ liệu: **không tạo** — chưa có thực thể nghiệp vụ, ngoài phạm vi spec.
- Hợp đồng giao diện: **không tạo** — app nội bộ, không API/CLI công khai.
- Kịch bản khởi động nhanh: xem `quickstart.md` — quy trình 6 bước từ máy sạch (đồng thời là bằng chứng FR-006/SC-001).

## Cấu trúc dự án dự kiến

Chỉ sửa file cấu hình, không thêm file code ở lại:

```
app/sora_thu_chi/
├── pubspec.yaml                         # [SỬA] thêm 5 dependency khóa phiên bản
├── pubspec.lock                         # [TẠO] cập nhật khi pub get — commit
├── android/app/src/main/AndroidManifest.xml   # [SỬA] allowBackup="false"
├── ios/Runner/Info.plist                # [SỬA] NSFaceIDUsageDescription
├── lib/smoke_verify.dart                # [TẠM] tạo để kiểm chứng SC-003 → XÓA sau khi pass
```

Không đổi: `lib/main.dart` (counter demo chứng minh app khởi động), `android/` còn lại, `ios/` còn lại.

## Rủi ro & ngoại lệ có lý do

- **Android toolchain cảnh báo** (flutter doctor: thiếu cmdline-tools, license chưa accept): có thể chặn build APK. Xử lý: `flutter doctor --android-licenses`; emulator API 37 đã chạy sẵn. Fallback nếu vẫn chặn: kiểm chứng drift/GetX/fl_chart bằng `flutter test` host, ghi rõ trạng thái còn lại.
- **flutter_secure_storage 11 & local_auth 3 yêu cầu nền tảng mới nhất**: minSdk đã đủ (24); nếu plugin đòi compileSdk cao hơn mặc định → nâng `compileSdk` cụ thể trong build.gradle.kts, ghi lý do.
- **iOS chưa kiểm chứng được** (máy Windows): cấu hình Info.plist thêm sẵn đúng chỗ; keychain entitlement + build/chạy thật hoãn tới khi có máy macOS — ghi trạng thái, không bỏ ngang (SC-005).

### Trạng thái sau thi công (PBI 1, 2026-09-03)

- **Android — ĐÃ xác minh**: `compileSdk` nâng lên **37** trong `android/app/build.gradle.kts` (flutter_secure_storage 11 yêu cầu ≥ 37; ghi chú lý do trong file). SDK Platform 37 được Gradle tự cài & accept license khi build. `minSdk` mặc định 24 giữ nguyên.
- **iOS — CHỜ máy macOS**: `ios/Runner/Info.plist` đã thêm `NSFaceIDUsageDescription` (chuỗi tiếng Việt) đúng chỗ theo tài liệu local_auth. Chưa build/chạy iOS, chưa thêm keychain entitlement (`keychain-access-groups` theo README flutter_secure_storage) — máy Windows không verify được. Việc thêm entitlement làm cùng phase kiểm chứng iOS trên macOS, không bỏ ngang.
- **sqlite3 native**: drift chạy ổn trên emulator qua cơ chế sqlite3 3.x tự bundle (`NativeDatabase.memory()` PASS) — không cần quay về sqlite3_flutter_libs (EOL).

## File đã tạo

- `.specify/specs/1/research.md`
- `.specify/specs/1/quickstart.md`
- `.specify/specs/1/plan.md`

Bước tiếp theo: chạy `/sora-task 1` để phân rã thành tasks.md.
