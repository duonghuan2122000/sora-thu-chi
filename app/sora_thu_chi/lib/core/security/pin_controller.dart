import 'dart:math';

import 'package:get/get.dart';

import 'pin_store.dart';

/// Kết quả xác minh một lần thử hoàn chỉnh (đủ 4 số).
enum VerifyResult { success, wrong, blocked }

/// Logic trạng thái khóa PIN (data-model.md — bảng chuyển trạng thái).
/// Clock bơm được qua `now()` để test định thời.
class PinController extends GetxController {
  PinController({required PinStore store, DateTime Function()? now})
      // ignore: prefer_initializing_formals — tham số public, field private (_store).
      : _store = store,
        _now = now ?? DateTime.now;

  /// Ladder chặn tăng dần, trần 15 phút (FR-009).
  static const ladder = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
  ];

  final PinStore _store;
  final DateTime Function() _now;

  bool configured = false;
  bool isLocked = false;
  int streak = 0;
  DateTime? lockUntil;

  /// Đọc store khi boot. Đã có PIN → phiên bắt đầu ở trạng thái khóa.
  Future<void> init() async {
    configured = await _store.isPinSet;
    streak = 0;
    lockUntil = null;
    if (configured) {
      final state = await _store.readLockState();
      streak = state.streak;
      lockUntil = state.lockUntil;
      isLocked = true;
    }
  }

  /// Ghi PIN + reset chống dò. Chỉ gọi 1 lần khi 2 lần nhập khớp ở thiết lập.
  Future<void> savePin(String pin) async {
    await _store.savePin(pin);
    await _store.saveLockState(const PinLockState());
    configured = true;
    isLocked = false;
    streak = 0;
    lockUntil = null;
  }

  bool get isBlocked => lockUntil != null && _now().isBefore(lockUntil!);

  /// Giây còn lại (làm tròn lên) cho tới khi hết chặn; 0 nếu không bị chặn.
  int get remainingLockSeconds {
    if (lockUntil == null) return 0;
    final ms = lockUntil!.difference(_now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  bool isWeakPin(String pin) {
    if (pin.length != 4) return false;
    // Giống hệt nhau (0000, 1111...).
    if (pin[0] == pin[1] && pin[1] == pin[2] && pin[2] == pin[3]) return true;
    // Dãy tăng-giảm liên tiếp (1234, 4321...).
    var ascending = true;
    var descending = true;
    for (var i = 1; i < pin.length; i++) {
      final step = pin.codeUnitAt(i) - pin.codeUnitAt(i - 1);
      if (step != 1) ascending = false;
      if (step != -1) descending = false;
    }
    return ascending || descending;
  }

  /// Kiểm tra một lần thử đủ 4 số. Sai hoàn chỉnh mới tăng streak (FR-008).
  /// Đúng → reset streak + hết chặn. Không cho mở khóa khi đang bị chặn.
  Future<VerifyResult> verify(String pin) async {
    if (isBlocked) return VerifyResult.blocked;
    if (await _store.verifyPin(pin)) {
      streak = 0;
      lockUntil = null;
      isLocked = false;
      await _store.saveLockState(const PinLockState());
      return VerifyResult.success;
    }
    streak += 1;
    if (streak >= 5) {
      final index = min(streak - 5, ladder.length - 1);
      lockUntil = _now().add(ladder[index]);
    }
    await _store.saveLockState(PinLockState(streak: streak, lockUntil: lockUntil));
    return VerifyResult.wrong;
  }
}
