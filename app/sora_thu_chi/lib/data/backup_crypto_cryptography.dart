import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../core/backup/backup_crypto.dart';

/// Impl thật [BackupCrypto] — AES-256-GCM, khoá dẫn xuất qua PBKDF2-HmacSha256
/// ≥100.000 vòng lặp + salt ngẫu nhiên (research R5, doc nghiệp vụ §4.4).
///
/// Định dạng chuỗi ra: base64( salt(16B) ++ nonce(12B) ++ mac(16B) ++ cipher )
/// — tự chứa mọi tham số cần để giải mã, không cần lưu riêng.
class CryptographyBackupCrypto implements BackupCrypto {
  static const int _saltLength = 16;
  static const int _pbkdf2Iterations = 100000;

  final AesGcm _algorithm = AesGcm.with256bits();

  @override
  Future<String> encrypt(String plaintext, String password) async {
    final salt = _randomBytes(_saltLength);
    final secretKey = await _deriveKey(password, salt);
    final secretBox = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
    );
    final out = BytesBuilder()
      ..add(salt)
      ..add(secretBox.nonce)
      ..add(secretBox.mac.bytes)
      ..add(secretBox.cipherText);
    return base64Encode(out.toBytes());
  }

  @override
  Future<String> decrypt(String ciphertext, String password) async {
    final Uint8List raw;
    try {
      raw = base64Decode(ciphertext);
    } catch (_) {
      throw const BackupDecryptException('Dữ liệu mã hoá không hợp lệ');
    }
    final nonceLength = _algorithm.nonceLength;
    const macLength = 16;
    final minLength = _saltLength + nonceLength + macLength;
    if (raw.length < minLength) {
      throw const BackupDecryptException('Dữ liệu mã hoá không hợp lệ');
    }
    final salt = raw.sublist(0, _saltLength);
    final nonce = raw.sublist(_saltLength, _saltLength + nonceLength);
    final mac = raw.sublist(
      _saltLength + nonceLength,
      _saltLength + nonceLength + macLength,
    );
    final cipherText = raw.sublist(_saltLength + nonceLength + macLength);
    final secretKey = await _deriveKey(password, salt);
    try {
      final clear = await _algorithm.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: secretKey,
      );
      return utf8.decode(clear);
    } on SecretBoxAuthenticationError {
      throw const BackupDecryptException('Sai mật khẩu hoặc dữ liệu bị hỏng');
    }
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: 256,
    );
    return pbkdf2.deriveKeyFromPassword(password: password, nonce: salt);
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}
