import 'dart:async';

import 'package:sora_thu_chi/core/security/biometric_gateway.dart';

/// Fake `BiometricGateway` cho test — bơm tay kết quả `canUse`/`availableTypes`
/// và kết quả (hoặc lỗi) của `authenticate`.
class BiometricGatewayFake implements BiometricGateway {
  bool canUseResult = true;
  List<String> availableTypesResult = ['fingerprint'];

  /// `null` → `authenticate` ném [Exception] (mô phỏng lỗi hệ thống).
  bool? authenticateResult = true;

  /// Đặt tay để giữ `authenticate()` chưa hoàn tất (mô phỏng hộp thoại hệ
  /// thống đang mở) — test hoàn tất bằng `pendingAuthenticate!.complete(...)`.
  Completer<bool>? pendingAuthenticate;

  int authenticateCallCount = 0;
  int stopAuthenticationCallCount = 0;

  @override
  Future<bool> canUse() async => canUseResult;

  @override
  Future<List<String>> availableTypes() async => availableTypesResult;

  @override
  Future<bool> authenticate({required String reason}) async {
    authenticateCallCount++;
    final pending = pendingAuthenticate;
    if (pending != null) return pending.future;
    final result = authenticateResult;
    if (result == null) throw Exception('Lỗi sinh trắc học giả lập');
    return result;
  }

  @override
  Future<void> stopAuthentication() async {
    stopAuthenticationCallCount++;
  }
}
