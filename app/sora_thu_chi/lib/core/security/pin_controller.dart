import 'dart:math';

import 'package:get/get.dart';

import 'biometric_gateway.dart';
import 'pin_store.dart';

/// Kết quả xác minh một lần thử hoàn chỉnh (đủ 4 số).
enum VerifyResult { success, wrong, blocked }

/// Logic trạng thái khóa PIN (data-model.md — bảng chuyển trạng thái).
/// Clock bơm được qua `now()` để test định thời.
class PinController extends GetxController {
  PinController({
    required PinStore store,
    DateTime Function()? now,
    BiometricGateway? gateway,
  })
      // ignore: prefer_initializing_formals — tham số public, field private (_store).
      : _store = store,
        _now = now ?? DateTime.now,
        _gateway = gateway ?? BiometricGatewayLocalAuth();

  /// Ladder chặn tăng dần, trần 15 phút (FR-009).
  static const ladder = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
  ];

  final PinStore _store;
  final DateTime Function() _now;
  final BiometricGateway _gateway;

  bool configured = false;
  bool isLocked = false;
  int streak = 0;
  DateTime? lockUntil;
  bool biometricEnabled = false;

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
    biometricEnabled = (await _store.readBiometricState()).enabled;
  }

  /// Thiết bị đủ điều kiện bật công tắc (FR-001): có cảm biến **và** đã đăng
  /// ký ít nhất một vân tay/khuôn mặt.
  Future<bool> deviceSupportsBiometric() async {
    if (!await _gateway.canUse()) return false;
    return (await _gateway.availableTypes()).isNotEmpty;
  }

  /// Bật công tắc "Mở khóa sinh trắc học" (FR-002) — chỉ ghi nhận khi xác thực
  /// sinh trắc học **thành công** ngay lúc bật (research.md R7); thất bại/huỷ
  /// giữ nguyên tắt, không ghi gì.
  Future<bool> enableBiometric() async {
    final bool success;
    try {
      success = await _gateway.authenticate(reason: 'Mở khóa Sora Thu Chi'.tr);
    } catch (_) {
      return false;
    }
    if (!success) return false;
    final enrolledTypes = await _gateway.availableTypes();
    await _store.saveBiometricState(
      BiometricState(enabled: true, enrolledTypes: enrolledTypes),
    );
    biometricEnabled = true;
    return true;
  }

  /// Tắt công tắc — có hiệu lực ngay, không cần xác thực gì thêm (FR-009).
  Future<void> disableBiometric() async {
    await _store.saveBiometricState(const BiometricState(enabled: false));
    biometricEnabled = false;
  }

  /// Còn mời sinh trắc học được không (màn khóa gọi trước khi vào chế độ
  /// biometric). Tự tắt công tắc khi phát hiện quyền bị thu hồi (FR-007) hoặc
  /// tập đăng ký đã đổi so với lúc bật (FR-008, giới hạn: chỉ bắt đổi *loại*).
  Future<bool> canOfferBiometric() async {
    if (!biometricEnabled) return false;
    if (!await _gateway.canUse()) {
      await disableBiometric();
      return false;
    }
    final saved = await _store.readBiometricState();
    final current = await _gateway.availableTypes();
    if (!_sameTypes(saved.enrolledTypes, current)) {
      await disableBiometric();
      return false;
    }
    return true;
  }

  bool _sameTypes(List<String> a, List<String> b) {
    return a.toSet().length == b.toSet().length &&
        a.toSet().containsAll(b);
  }

  /// Mời xác thực sinh trắc học tại màn khóa (FR-003). Thất bại/lỗi/huỷ →
  /// `false`, không tính vào chống dò PIN (FR-005).
  Future<bool> authenticateBiometric() async {
    try {
      return await _gateway.authenticate(reason: 'Mở khóa Sora Thu Chi'.tr);
    } catch (_) {
      return false;
    }
  }

  /// Huỷ lượt xác thực đang chờ — nút "Hủy" (R6, ở lại màn mời).
  Future<void> stopBiometricAuthentication() => _gateway.stopAuthentication();

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
