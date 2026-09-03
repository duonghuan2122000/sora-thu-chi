/// Trạng thái chống dò PIN (data-model.md — key `lock_state`).
class PinLockState {
  const PinLockState({this.streak = 0, this.lockUntil});

  /// Số lần thử sai hoàn chỉnh liên tiếp (chưa có lần đúng xen giữa).
  final int streak;

  /// Mốc hết thời gian chặn (giờ thiết bị); null = không bị chặn.
  final DateTime? lockUntil;
}

/// Lưu trữ PIN + trạng thái chống dò — giữ trừu tượng để test bơm fake.
abstract class PinStore {
  Future<bool> get isPinSet;
  Future<void> savePin(String pin);
  Future<bool> verifyPin(String pin);
  Future<PinLockState> readLockState();
  Future<void> saveLockState(PinLockState state);
}
