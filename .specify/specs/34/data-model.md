# Mô hình dữ liệu: Mở khóa bằng sinh trắc học (PBI 34)

Không đụng drift/sqlite — mở rộng đúng 2 key secure storage đã có từ PBI 3 (`pin_salt_hash`, `lock_state`) bằng **1 key mới**, cùng cơ chế `flutter_secure_storage`.

## Thực thể: Trạng thái sinh trắc học (thiết bị)

Key `biometric_state` trong `flutter_secure_storage`, giá trị JSON:

| Trường | Kiểu | Ý nghĩa |
|---|---|---|
| `enabled` | `bool` | Công tắc "Mở khóa sinh trắc học" đang bật hay đã bị hệ thống tự tắt |
| `enrolledTypes` | `List<String>` | Snapshot tên các `BiometricType` (`fingerprint`/`face`/`iris`/`strong`/`weak`) đọc từ `getAvailableBiometrics()` tại thời điểm **bật** — dùng để so khớp phát hiện đổi đăng ký (FR-008, xem `research.md` R5) |

- Key vắng ⇒ mặc định `{enabled: false, enrolledTypes: []}` (chưa từng bật) — parse tolerant, JSON hỏng cũng về mặc định này, không ném lỗi (đúng khuôn `PinStoreSecure.readLockState`).
- Ghi **toàn bộ object** mỗi lần đổi (không có ghi từng phần) — cùng khuôn `saveLockState`.

## Mở rộng `PinStore` (interface hiện có)

```dart
abstract class PinStore {
  // ... các phương thức PIN hiện có, không đổi ...
  Future<BiometricState> readBiometricState();
  Future<void> saveBiometricState(BiometricState state);
}

class BiometricState {
  const BiometricState({this.enabled = false, this.enrolledTypes = const []});
  final bool enabled;
  final List<String> enrolledTypes;
}
```

`PinStoreSecure` cài đặt 2 phương thức mới (đọc/ghi JSON key `biometric_state`, cùng khuôn try/catch của `readLockState`). `PinStoreFake` (test, PBI 3) bổ sung field in-memory tương ứng.

## Bảng chuyển trạng thái (gắn vào `PinController`)

| Trạng thái hiện tại | Sự kiện | Trạng thái mới |
|---|---|---|
| `biometricEnabled = false` | Bật công tắc, xác thực sinh trắc học **thành công** | `true`, lưu `enrolledTypes` hiện tại |
| `biometricEnabled = false` | Bật công tắc, xác thực **thất bại/huỷ** | giữ `false`, không ghi |
| `biometricEnabled = true` | Tắt công tắc thủ công | `false` (không cần xác thực gì thêm — FR-009) |
| `biometricEnabled = true` | Vào màn khóa, `canCheckBiometrics`/`isDeviceSupported` trả `false` | tự chuyển `false`, màn khóa hiện PIN (FR-007) |
| `biometricEnabled = true` | Vào màn khóa, `getAvailableBiometrics()` khác `enrolledTypes` đã lưu | tự chuyển `false`, màn khóa hiện PIN (FR-008) |
| `biometricEnabled = true` | Vào màn khóa, mọi kiểm tra khớp | Hiện màn mời sinh trắc học (mockup `03`) |

Không có trường/bảng nào khác bị ảnh hưởng — `wallets`/`transactions`/`categories`/`budgets`/`AppSettings`/`notifications` giữ nguyên.
