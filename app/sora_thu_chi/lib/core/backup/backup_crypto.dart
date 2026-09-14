/// Seam mã hoá/giải mã **file** backup (khác lớp mã hoá DB local, R5) — màn/
/// controller chỉ phụ thuộc interface này để test bơm fake. Impl thật dùng
/// `package:cryptography` (AES-256-GCM + PBKDF2), xem `backup_crypto_cryptography.dart`.
abstract class BackupCrypto {
  /// Mã hoá [plaintext] bằng khoá dẫn xuất từ [password] — trả chuỗi có thể
  /// ghi thẳng vào file (đã gồm salt/nonce, tự chứa để [decrypt] dùng lại).
  Future<String> encrypt(String plaintext, String password);

  /// Giải mã [ciphertext] — sai [password] hoặc dữ liệu hỏng ném lỗi rõ ràng,
  /// **không** trả dữ liệu rác.
  Future<String> decrypt(String ciphertext, String password);
}

/// Sai mật khẩu hoặc phần đã mã hoá bị hỏng/sửa tay.
class BackupDecryptException implements Exception {
  const BackupDecryptException(this.message);

  final String message;

  @override
  String toString() => message;
}
