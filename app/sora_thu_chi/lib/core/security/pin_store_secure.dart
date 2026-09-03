import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'pin_store.dart';

/// Lưu PIN dạng `"{saltB64}.{hashB64}"` — salt 16 byte ngẫu nhiên, hash
/// SHA-256(salt + pin). Không lưu PIN đọc được (FR-011). Key tồn tại = PIN
/// đã thiết lập. Trạng thái chống dò lưu JSON riêng (data-model.md).
class PinStoreSecure implements PinStore {
  PinStoreSecure({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _pinKey = 'pin_salt_hash';
  static const _lockKey = 'lock_state';

  final FlutterSecureStorage _storage;

  @override
  Future<bool> get isPinSet async {
    final value = await _storage.read(key: _pinKey);
    return value != null && value.isNotEmpty;
  }

  @override
  Future<void> savePin(String pin) async {
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final saltB64 = base64Encode(salt);
    final hash = _hash(salt, pin);
    final hashB64 = base64Encode(hash);
    await _storage.write(key: _pinKey, value: '$saltB64.$hashB64');
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final value = await _storage.read(key: _pinKey);
    if (value == null) return false;
    final dot = value.indexOf('.');
    if (dot <= 0) return false;
    final salt = base64Decode(value.substring(0, dot));
    final stored = value.substring(dot + 1);
    return base64Encode(_hash(salt, pin)) == stored;
  }

  @override
  Future<PinLockState> readLockState() async {
    final raw = await _storage.read(key: _lockKey);
    if (raw == null) return const PinLockState();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final epoch = json['lockUntilEpochMs'] as int?;
      return PinLockState(
        streak: json['streak'] as int? ?? 0,
        lockUntil:
            epoch == null ? null : DateTime.fromMillisecondsSinceEpoch(epoch),
      );
    } catch (_) {
      return const PinLockState();
    }
  }

  @override
  Future<void> saveLockState(PinLockState state) async {
    await _storage.write(
      key: _lockKey,
      value: jsonEncode({
        'streak': state.streak,
        'lockUntilEpochMs': state.lockUntil?.millisecondsSinceEpoch,
      }),
    );
  }

  List<int> _hash(List<int> salt, String pin) {
    return sha256.convert([...salt, ...utf8.encode(pin)]).bytes;
  }
}
