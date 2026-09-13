import 'package:flutter_test/flutter_test.dart';
import 'package:sora_thu_chi/core/security/pin_controller.dart';
import 'package:sora_thu_chi/core/security/pin_store.dart';

import 'fakes/biometric_gateway_fake.dart';
import 'fakes/pin_store_fake.dart';

void main() {
  late PinStoreFake store;
  late DateTime now;

  PinController buildController({BiometricGatewayFake? gateway}) {
    return PinController(store: store, now: () => now, gateway: gateway);
  }

  setUp(() {
    store = PinStoreFake();
    now = DateTime(2026, 1, 1, 12);
  });

  test('savePin ghi PIN, reset chống dò, phiên mở không khóa', () async {
    final c = buildController();
    await c.init();
    expect(c.configured, isFalse);

    await c.savePin('1234');
    expect(c.configured, isTrue);
    expect(c.isLocked, isFalse);
    expect(c.isBlocked, isFalse);
    expect(await store.isPinSet, isTrue);
    expect(await store.verifyPin('1234'), isTrue);
  });

  test('verify đúng → reset streak + hết chặn', () async {
    store = PinStoreFake.withPin('1234');
    final c = buildController();
    await c.init();
    expect(c.isLocked, isTrue);

    expect(await c.verify('1234'), VerifyResult.success);
    expect(c.streak, 0);
    expect(c.lockUntil, isNull);
    expect(c.isBlocked, isFalse);
  });

  test('sai 5 lần hoàn chỉnh → chặn 30s; hết chặn sai tiếp → 1 phút', () async {
    store = PinStoreFake.withPin('1234');
    final c = buildController();
    await c.init();

    for (var i = 1; i <= 5; i++) {
      expect(await c.verify('9999'), VerifyResult.wrong);
    }
    expect(c.streak, 5);
    expect(c.isBlocked, isTrue);
    expect(c.remainingLockSeconds, 30);
    expect(c.lockUntil, now.add(const Duration(seconds: 30)));

    // Đang chặn → không xác minh được (guard).
    expect(await c.verify('1234'), VerifyResult.blocked);

    // Hết chặn → chỉ mở lại nhập, streak còn 5; sai tiếp = bậc 1 phút.
    now = now.add(const Duration(seconds: 31));
    expect(c.isBlocked, isFalse);
    expect(await c.verify('9999'), VerifyResult.wrong);
    expect(c.streak, 6);
    expect(c.isBlocked, isTrue);
    expect(c.lockUntil, now.add(const Duration(minutes: 1)));
  });

  test('chặn tăng dần và trần 15 phút (FR-009)', () async {
    store = PinStoreFake.withPin('1234');
    final c = buildController();
    await c.init();

    for (var i = 1; i <= 4; i++) {
      await c.verify('9999');
      // Bỏ qua thời gian chặn mỗi bậc (đã kiểm tra ở test trên) — dời clock.
      now = now.add(const Duration(hours: 1));
    }
    // Đủ 5 → bậc 1 (30s).
    await c.verify('9999');
    expect(c.lockUntil, now.add(const Duration(seconds: 30)));

    now = now.add(const Duration(hours: 1));
    await c.verify('9999'); // 6
    expect(c.lockUntil, now.add(const Duration(minutes: 1)));
    now = now.add(const Duration(hours: 1));
    await c.verify('9999'); // 7
    expect(c.lockUntil, now.add(const Duration(minutes: 5)));
    now = now.add(const Duration(hours: 1));
    await c.verify('9999'); // 8
    expect(c.lockUntil, now.add(const Duration(minutes: 15)));
    now = now.add(const Duration(hours: 1));
    await c.verify('9999'); // 9 — vượt trần vẫn 15 phút
    expect(c.lockUntil, now.add(const Duration(minutes: 15)));
  });

  test('remainingLockSeconds bằng 0 khi không chặn / hết hạn', () async {
    store = PinStoreFake.withPin('1234');
    final c = buildController();
    await c.init();
    expect(c.remainingLockSeconds, 0);
  });

  test('isWeakPin nhận diện dãy dễ đoán', () async {
    final c = buildController();
    await c.init();
    for (final weak in ['0000', '1111', '1234', '4321']) {
      expect(c.isWeakPin(weak), isTrue, reason: '$weak phải là PIN yếu');
    }
    for (final strong in ['2580', '1122', '1357', '1203']) {
      expect(c.isWeakPin(strong), isFalse, reason: '$strong không yếu');
    }
  });

  test('init đọc trạng thái chặn đã lưu (sống sót khi thoát app)', () async {
    final lockUntil = DateTime(2026, 1, 1, 12, 0, 30);
    store = PinStoreFake.withPin(
      '1234',
      lockState: PinLockState(streak: 5, lockUntil: lockUntil),
    );
    final c = buildController();
    await c.init();
    expect(c.streak, 5);
    expect(c.isBlocked, isTrue);
    expect(c.lockUntil, lockUntil);
  });

  group('Sinh trắc học (PBI 34)', () {
    late BiometricGatewayFake gateway;

    setUp(() {
      store = PinStoreFake.withPin('1234');
      gateway = BiometricGatewayFake();
    });

    test('deviceSupportsBiometric: hỗ trợ + có đăng ký → true', () async {
      final c = buildController(gateway: gateway);
      await c.init();
      expect(await c.deviceSupportsBiometric(), isTrue);
    });

    test('deviceSupportsBiometric: hỗ trợ nhưng chưa đăng ký → false (FR-001)',
        () async {
      gateway.availableTypesResult = [];
      final c = buildController(gateway: gateway);
      await c.init();
      expect(await c.deviceSupportsBiometric(), isFalse);
    });

    test('enableBiometric: xác thực thành công → bật + lưu enrolledTypes',
        () async {
      gateway.availableTypesResult = ['fingerprint', 'face'];
      final c = buildController(gateway: gateway);
      await c.init();
      expect(c.biometricEnabled, isFalse);

      expect(await c.enableBiometric(), isTrue);
      expect(c.biometricEnabled, isTrue);
      final saved = await store.readBiometricState();
      expect(saved.enabled, isTrue);
      expect(saved.enrolledTypes, ['fingerprint', 'face']);
    });

    test('enableBiometric: xác thực thất bại/huỷ → giữ tắt, không ghi store',
        () async {
      gateway.authenticateResult = false;
      final c = buildController(gateway: gateway);
      await c.init();

      expect(await c.enableBiometric(), isFalse);
      expect(c.biometricEnabled, isFalse);
      expect((await store.readBiometricState()).enabled, isFalse);
    });

    test('enableBiometric: hệ thống ném lỗi → giữ tắt, không crash', () async {
      gateway.authenticateResult = null;
      final c = buildController(gateway: gateway);
      await c.init();

      expect(await c.enableBiometric(), isFalse);
      expect(c.biometricEnabled, isFalse);
    });

    test('disableBiometric: tắt ngay không cần xác thực (FR-009)', () async {
      final c = buildController(gateway: gateway);
      await c.init();
      await c.enableBiometric();
      expect(c.biometricEnabled, isTrue);

      gateway.authenticateCallCount = 0;
      await c.disableBiometric();
      expect(c.biometricEnabled, isFalse);
      expect((await store.readBiometricState()).enabled, isFalse);
      expect(gateway.authenticateCallCount, 0);
    });

    test('canOfferBiometric: quyền bị thu hồi → tự tắt công tắc (FR-007)',
        () async {
      final c = buildController(gateway: gateway);
      await c.init();
      await c.enableBiometric();
      expect(c.biometricEnabled, isTrue);

      gateway.canUseResult = false;
      expect(await c.canOfferBiometric(), isFalse);
      expect(c.biometricEnabled, isFalse);
      expect((await store.readBiometricState()).enabled, isFalse);
    });

    test(
        'canOfferBiometric: tập đăng ký đổi loại → tự tắt công tắc, bật lại phải qua enableBiometric (FR-008)',
        () async {
      final c = buildController(gateway: gateway);
      await c.init();
      await c.enableBiometric(); // enrolledTypes = ['fingerprint']

      gateway.availableTypesResult = ['fingerprint', 'face'];
      expect(await c.canOfferBiometric(), isFalse);
      expect(c.biometricEnabled, isFalse);

      // Bật lại phải đi qua enableBiometric() đầy đủ, không có đường tắt.
      expect(await c.enableBiometric(), isTrue);
      expect(c.biometricEnabled, isTrue);
    });

    test('canOfferBiometric: mọi kiểm tra khớp → true, không tự tắt', () async {
      final c = buildController(gateway: gateway);
      await c.init();
      await c.enableBiometric();

      expect(await c.canOfferBiometric(), isTrue);
      expect(c.biometricEnabled, isTrue);
    });

    test('canOfferBiometric: công tắc đang tắt → false ngay, không gọi gateway',
        () async {
      final c = buildController(gateway: gateway);
      await c.init();

      expect(await c.canOfferBiometric(), isFalse);
    });

    test('authenticateBiometric: thành công/thất bại/lỗi đều không crash',
        () async {
      final c = buildController(gateway: gateway);
      await c.init();

      expect(await c.authenticateBiometric(), isTrue);
      gateway.authenticateResult = false;
      expect(await c.authenticateBiometric(), isFalse);
      gateway.authenticateResult = null;
      expect(await c.authenticateBiometric(), isFalse);
    });
  });
}
