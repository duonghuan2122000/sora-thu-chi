import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/backup/backup_crypto.dart';
import 'package:sora_thu_chi/data/backup_crypto_cryptography.dart';

void main() {
  test('encrypt → decrypt đúng mật khẩu ra nguyên văn', () async {
    final crypto = CryptographyBackupCrypto();
    const plaintext = '{"wallets":[{"id":1,"name":"Tiền mặt"}]}';
    final cipher = await crypto.encrypt(plaintext, 'mat-khau-123');
    expect(cipher, isNot(contains('Tiền mặt')));
    final decrypted = await crypto.decrypt(cipher, 'mat-khau-123');
    expect(decrypted, plaintext);
  });

  test('sai mật khẩu ném BackupDecryptException, không trả dữ liệu rác', () async {
    final crypto = CryptographyBackupCrypto();
    final cipher = await crypto.encrypt('dữ liệu bí mật', 'dung');
    expect(
      () => crypto.decrypt(cipher, 'sai'),
      throwsA(isA<BackupDecryptException>()),
    );
  });

  test('ciphertext hỏng ném BackupDecryptException', () async {
    final crypto = CryptographyBackupCrypto();
    expect(
      () => crypto.decrypt('không-phải-base64!!', 'mat-khau'),
      throwsA(isA<BackupDecryptException>()),
    );
  });
}
