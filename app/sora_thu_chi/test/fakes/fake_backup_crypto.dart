import 'dart:convert';

import 'package:sora_thu_chi/core/backup/backup_crypto.dart';

/// Bản giả [BackupCrypto] — mã hoá/giải mã tức thời, không PBKDF2 thật.
///
/// Dùng cho test `testWidgets`: `CryptographyBackupCrypto` thật gọi
/// `Pbkdf2.deriveKeyFromPassword` (package `cryptography`), bên trong định kỳ
/// `await Future.delayed(...)` để nhường CPU — dưới `TestWidgetsFlutterBinding`
/// (đồng hồ giả), Timer đó không bao giờ tự bắn ⇒ treo test vô thời hạn. Test
/// thuần (`test()`, không `testWidgets`) không bị ảnh hưởng, vẫn dùng
/// `CryptographyBackupCrypto` thật (`backup_crypto_test.dart`,
/// `backup_controller_test.dart`...).
class FakeBackupCrypto implements BackupCrypto {
  @override
  Future<String> encrypt(String plaintext, String password) async {
    return 'FAKE:$password:${base64Encode(utf8.encode(plaintext))}';
  }

  @override
  Future<String> decrypt(String ciphertext, String password) async {
    final prefix = 'FAKE:$password:';
    if (!ciphertext.startsWith(prefix)) {
      throw const BackupDecryptException('Sai mật khẩu hoặc dữ liệu bị hỏng');
    }
    try {
      return utf8.decode(base64Decode(ciphertext.substring(prefix.length)));
    } catch (_) {
      throw const BackupDecryptException('Sai mật khẩu hoặc dữ liệu bị hỏng');
    }
  }
}
