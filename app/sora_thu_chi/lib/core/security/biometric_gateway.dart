import 'package:local_auth/local_auth.dart';

/// Seam mỏng bọc `local_auth` — `PinController`/`PinLockScreen` gọi qua đây
/// để test bơm fake (gói gọi thẳng platform channel, không mock trực tiếp
/// được — research.md R1/cấu trúc plan.md).
abstract class BiometricGateway {
  /// Thiết bị có hỗ trợ sinh trắc học và còn dùng được (quyền chưa bị thu hồi).
  Future<bool> canUse();

  /// Tên các `BiometricType` (`fingerprint`/`face`/`iris`/`strong`/`weak`)
  /// đã đăng ký hiện tại trên thiết bị (research.md R5).
  Future<List<String>> availableTypes();

  /// Mời xác thực sinh trắc học (chỉ sinh trắc học, không cho fallback PIN/
  /// pattern của hệ điều hành — PIN của app luôn là lớp gốc, FR-010).
  Future<bool> authenticate({required String reason});

  /// Huỷ lượt xác thực đang chờ (nút "Hủy" — R6).
  Future<void> stopAuthentication();
}

class BiometricGatewayLocalAuth implements BiometricGateway {
  final _auth = LocalAuthentication();

  @override
  Future<bool> canUse() async {
    return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
  }

  @override
  Future<List<String>> availableTypes() async {
    final types = await _auth.getAvailableBiometrics();
    return types.map((t) => t.name).toList();
  }

  @override
  Future<bool> authenticate({required String reason}) {
    return _auth.authenticate(localizedReason: reason, biometricOnly: true);
  }

  @override
  Future<void> stopAuthentication() async {
    await _auth.stopAuthentication();
  }
}
