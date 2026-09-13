/// Trạng thái chống dò PIN (data-model.md — key `lock_state`).
class PinLockState {
  const PinLockState({this.streak = 0, this.lockUntil});

  /// Số lần thử sai hoàn chỉnh liên tiếp (chưa có lần đúng xen giữa).
  final int streak;

  /// Mốc hết thời gian chặn (giờ thiết bị); null = không bị chặn.
  final DateTime? lockUntil;
}

/// Trạng thái công tắc sinh trắc học (data-model.md — key `biometric_state`).
/// Gắn với thiết bị hiện tại — không nằm trong backup/restore JSON (FR-011).
class BiometricState {
  const BiometricState({this.enabled = false, this.enrolledTypes = const []});

  /// Công tắc "Mở khóa sinh trắc học" đang bật hay đã bị hệ thống tự tắt.
  final bool enabled;

  /// Snapshot tên `BiometricType` đọc lúc bật — so khớp phát hiện đổi đăng ký
  /// (FR-008).
  final List<String> enrolledTypes;
}

/// Lưu trữ PIN + trạng thái chống dò — giữ trừu tượng để test bơm fake.
abstract class PinStore {
  Future<bool> get isPinSet;
  Future<void> savePin(String pin);
  Future<bool> verifyPin(String pin);
  Future<PinLockState> readLockState();
  Future<void> saveLockState(PinLockState state);
  Future<BiometricState> readBiometricState();
  Future<void> saveBiometricState(BiometricState state);
}
