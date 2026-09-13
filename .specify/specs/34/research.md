# Nghiên cứu kỹ thuật: Mở khóa bằng sinh trắc học (PBI 34)

## R1 — Gói dùng: `local_auth` đã có sẵn, không thêm dependency mới

**Quyết định**: Dùng `local_auth: ^3.0.2` (đã khai báo trong `pubspec.yaml` từ trước, chưa có code nào dùng tới) — `LocalAuthentication().authenticate(localizedReason: ..., options: AuthenticationOptions(biometricOnly: true))`. Kiểm tra hỗ trợ bằng `canCheckBiometrics` + `isDeviceSupported()` + `getAvailableBiometrics()`.

**Lý do**: Đúng stack đã chốt (`CLAUDE.md` §Kiến trúc: "sinh trắc học `local_auth`"); gói đã nằm trong cây phụ thuộc từ trước (khai báo nhưng chưa dùng) ⇒ `flutter pub get` không đổi gì, không có rủi ro version mới.

**Phương án khác đã xem xét**: Không có — đây là gói duy nhất Flutter chính thức hỗ trợ BiometricPrompt/LAContext đa nền tảng.

## R2 — Nơi lưu trạng thái: mở rộng `PinStore` (secure storage), không dùng `AppSettings`

**Quyết định**: Thêm 1 key mới vào `flutter_secure_storage` — `biometric_state` (JSON `{enabled, enrolledTypes}`) — qua việc mở rộng `abstract class PinStore` (2 phương thức mới) thay vì thêm row vào bảng key-value `AppSettings` (nơi các công tắc UI như `hideBalance`/`scanEnabled` đang ở).

**Lý do**: FR-011 (spec) cấm đưa trạng thái này vào backup/restore JSON tương lai. `AppSettings` là bảng dữ liệu drift, về nguyên tắc **sẽ** nằm trong phạm vi backup JSON khi PBI backup/restore (GĐ3) triển khai. `flutter_secure_storage` (Keystore/Keychain) vốn không di chuyển được giữa thiết bị/cài đặt lại — đúng bản chất "cấu hình gắn thiết bị" mà FR-011 yêu cầu, và cùng domain bảo mật với `pin_salt_hash`/`lock_state` đã có (PBI 3).

**Phương án khác đã xem xét**: Thêm row `AppSettings` (khuôn PBI 17/24/28) — bị loại vì lệch FR-011; sẽ phải nhớ loại trừ thủ công khỏi backup sau này, dễ sót.

## R3 — Cấu trúc màn hình: gộp vào `PinLockScreen` bằng 2 chế độ nội bộ, không route riêng

**Quyết định**: `PinLockScreen` giữ nguyên là **một** route; thêm state nội bộ `_Mode { biometric, pin }`. Khi biometric đang bật và khả dụng → khởi tạo ở chế độ `biometric` (giao diện theo mockup `03-sinh-trac-hoc.svg`); nút "Dùng mã PIN thay thế" hoặc xác thực thất bại → `setState` chuyển `_Mode.pin` (giao diện PIN hiện có, không đổi). Ngược lại (không bật/không khả dụng) → khởi tạo thẳng ở `_Mode.pin` như hành vi cũ.

**Lý do**: Tránh nhân đôi route/callback `onUnlocked` ở 2 nơi gọi (`PinGate` cold-start + `app.dart` resume); giữ nguyên state chống dò PIN (`PinController`) không bị ảnh hưởng bởi việc chuyển qua lại 2 giao diện. Khuôn nhất quán "1 StatefulWidget nhiều chế độ" đã dùng ở `DailyReminderConfigScreen`/`ThemeScreen`.

**Phương án khác đã xem xét**: Route riêng `BiometricUnlockScreen` rồi `Navigator.pushReplacement` sang `PinLockScreen` khi fallback — bị loại vì tạo thêm 1 route/callback phải đồng bộ tay ở 2 điểm gọi, không có lợi ích thêm (không cần giữ back-stack riêng, `PopScope(canPop:false)` đã áp dụng cho cả cụm).

## R4 — Phát hiện quyền sinh trắc học bị thu hồi (FR-007)

**Quyết định**: Mỗi lần chuẩn bị mời sinh trắc học (khởi tạo `PinLockScreen` ở chế độ biometric, và khi bật công tắc trong Cài đặt) đều gọi lại `canCheckBiometrics && await isDeviceSupported()`. Kết quả `false` → coi như đã mất hiệu lực: nếu đang khởi tạo màn khóa thì bỏ qua bước mời, vào thẳng `_Mode.pin`; đồng thời ghi `enabled=false` vào `biometric_state` (tắt công tắc) để lần vào Cài đặt sau phản ánh đúng (FR-007).

**Lý do**: `local_auth` không phát tín hiệu chủ động khi quyền đổi (không có stream lắng nghe) — cách khả thi duy nhất là hỏi lại tại thời điểm cần dùng, đúng vòng đời app đã có (mỗi lần vào màn khóa/mở Cài đặt).

**Phương án khác đã xem xét**: Polling nền định kỳ — bị loại, vi phạm nguyên tắc app offline không có tiến trình nền (đã loại tương tự ở PBI 31 cho lịch nhắc).

## R5 — Phát hiện đổi vân tay/khuôn mặt đã đăng ký (FR-008)

**Quyết định**: Tại thời điểm bật công tắc (FR-002), chụp lại `getAvailableBiometrics()` (danh sách `BiometricType`) thành `enrolledTypes`, lưu cùng `biometric_state`. Mỗi lần chuẩn bị mời sinh trắc học, so khớp `enrolledTypes` đã lưu với danh sách hiện tại — **khác tập hợp** (thêm/bớt loại, VD máy trước chỉ có `fingerprint` nay có thêm `face`) → coi là "đã đổi đăng ký sinh trắc học", tự vô hiệu hoá (tắt `enabled`, vào thẳng PIN, yêu cầu bật lại theo đúng luồng FR-002).

**Lý do**: `local_auth` không hỗ trợ gắn `CryptoObject`/khoá Keystore bị vô hiệu hoá tự động khi đổi sinh trắc học (khả năng gốc của Android `BiometricPrompt` + `setInvalidatedByBiometricEnrollment`, nhưng plugin Flutter không expose) — đây là giới hạn của chính gói, không phải chọn sai công cụ.

> **⚠ Giới hạn đã biết (ceiling)**: cách này chỉ phát hiện đổi **loại** sinh trắc học (thêm/bớt phương thức: vân tay ↔ khuôn mặt). **Không phát hiện được** khi người dùng thêm/xoá một dấu vân tay khác nhưng vẫn cùng loại `fingerprint` (OS không lộ thông tin này cho ứng dụng qua `local_auth`). Muốn chặt hơn cần viết kênh native riêng dùng Keystore key có `setInvalidatedByBiometricEnrollment(true)` (tương tự kênh `sora_thu_chi/device_probe` đã có ở PBI 24) — để ngoài phạm vi đợt này, ghi nhận vào [[Lộ trình phát triển]] nếu cần nâng cấp sau.

**Phương án khác đã xem xét**: Bỏ qua FR-008 hoàn toàn — bị loại vì spec đã chốt yêu cầu này (kịch bản chấp nhận #4); cách đã chọn là mức tối thiểu **có thực thi được** bằng gói hiện có, không phải không làm gì.

## R6 — Nút "Hủy" trên màn mời sinh trắc học

**Quyết định**: "Hủy" chỉ gọi lại `LocalAuthentication.stopAuthentication()` (huỷ lượt xác thực đang chờ nếu có) và không đổi `_Mode` — người dùng vẫn đứng ở màn biometric, có thể chạm lại icon để thử tiếp. Không điều hướng, không tự chuyển PIN (đúng giả định đã ghi trong spec.md).

**Lý do**: Khớp giả định spec đã chốt; tránh nhầm với "Dùng mã PIN thay thế" (2 nút phải khác hành vi).

## R7 — Luồng bật công tắc (FR-002)

**Quyết định**: Bấm bật → gọi `authenticate()` ngay (không hộp thoại app tự vẽ trung gian — dùng thẳng UI hệ thống của BiometricPrompt/FaceID). Thành công → `store.saveBiometricEnabled(enabled: true, enrolledTypes: <chụp hiện tại>)`, `Switch` bật. Thất bại/huỷ → giữ nguyên tắt, không ghi gì (đúng trường hợp biên đã ghi trong spec).

**Lý do**: Đúng chốt phương án A của câu hỏi làm rõ (chỉ cần sinh trắc học, không bắt nhập PIN).
