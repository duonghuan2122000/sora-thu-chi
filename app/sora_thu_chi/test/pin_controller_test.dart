import 'package:flutter_test/flutter_test.dart';
import 'package:sora_thu_chi/core/security/pin_controller.dart';
import 'package:sora_thu_chi/core/security/pin_store.dart';

import 'fakes/pin_store_fake.dart';

void main() {
  late PinStoreFake store;
  late DateTime now;

  PinController buildController() {
    return PinController(store: store, now: () => now);
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
}
