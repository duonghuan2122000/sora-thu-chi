import 'package:sora_thu_chi/core/security/pin_store.dart';

/// `PinStore` in-memory cho test — PIN lưu plaintext để dễ seed/so sánh.
class PinStoreFake implements PinStore {
  PinStoreFake();

  PinStoreFake.withPin(String pin,
      {PinLockState lockState = const PinLockState()}) {
    _pin = pin;
    _lockState = lockState;
  }

  String? _pin;
  PinLockState _lockState = const PinLockState();

  @override
  Future<bool> get isPinSet async => _pin != null;

  @override
  Future<void> savePin(String pin) async {
    _pin = pin;
    _lockState = const PinLockState();
  }

  @override
  Future<bool> verifyPin(String pin) async => _pin != null && _pin == pin;

  @override
  Future<PinLockState> readLockState() async => _lockState;

  @override
  Future<void> saveLockState(PinLockState state) async {
    _lockState = state;
  }
}
