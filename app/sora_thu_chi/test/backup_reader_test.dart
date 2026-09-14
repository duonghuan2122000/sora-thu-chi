import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/backup/backup_crypto.dart';
import 'package:sora_thu_chi/core/backup/backup_data.dart';
import 'package:sora_thu_chi/core/backup/backup_reader.dart';
import 'package:sora_thu_chi/core/backup/backup_writer.dart';
import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/data/backup_crypto_cryptography.dart';

final _sampleData = BackupData(
  wallets: const [
    Wallet(id: 1, name: 'Tiền mặt', type: WalletType.cash, balance: 100000),
  ],
  categories: const [
    Category(
      id: 1,
      name: 'Ăn uống',
      type: CategoryType.expense,
      icon: 'food',
      color: 0xFFAABBCC,
    ),
  ],
  transactions: const [],
  budgets: const [],
  settings: const {},
);

void main() {
  final crypto = CryptographyBackupCrypto();
  final reader = BackupReader(crypto);

  test('file hợp lệ không mật khẩu → đọc đúng meta + data', () async {
    final result = await buildBackupFile(data: _sampleData, crypto: crypto);
    final meta = await reader.readMeta(result.bytes);
    expect(meta.hasPassword, isFalse);
    expect(meta.counts, {'wallets': 1, 'categories': 1, 'transactions': 0, 'budgets': 0});

    final data = await reader.readFullData(result.bytes);
    expect(data.wallets.single.id, 1);
    expect(data.categories.single.name, 'Ăn uống');
  });

  test('file có mật khẩu → readMeta không cần password, readFullData cần đúng password', () async {
    final result = await buildBackupFile(
      data: _sampleData,
      password: 'bi-mat-123',
      crypto: crypto,
    );
    final meta = await reader.readMeta(result.bytes);
    expect(meta.hasPassword, isTrue);

    expect(
      () => reader.readFullData(result.bytes),
      throwsA(isA<BackupDecryptException>()),
    );
    expect(
      () => reader.readFullData(result.bytes, password: 'sai'),
      throwsA(isA<BackupDecryptException>()),
    );

    final data = await reader.readFullData(
      result.bytes,
      password: 'bi-mat-123',
    );
    expect(data.wallets.single.id, 1);
  });

  test('sai 1 byte (checksum sai) → BackupFormatException', () async {
    final result = await buildBackupFile(data: _sampleData, crypto: crypto);
    final text = utf8.decode(result.bytes);
    // Sửa tay 1 ký tự trong tên ví (nằm trong `data`, không đụng `meta`) để
    // checksum tính lại không còn khớp `meta.checksum`.
    final tampered = utf8.encode(text.replaceFirst('Tiền mặt', 'Tien mat'));
    expect(
      () => reader.readFullData(tampered),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('schema_version lớn hơn hỗ trợ → BackupIncompatibleException', () async {
    final result = await buildBackupFile(data: _sampleData, crypto: crypto);
    final json = jsonDecode(utf8.decode(result.bytes)) as Map<String, Object?>;
    (json['meta'] as Map)['schema_version'] = 999;
    final tampered = utf8.encode(jsonEncode(json));
    expect(
      () => reader.readFullData(tampered),
      throwsA(isA<BackupIncompatibleException>()),
    );
  });

  test('JSON không đúng cấu trúc → BackupFormatException, không crash', () async {
    expect(
      () => reader.readMeta(utf8.encode('không phải json')),
      throwsA(isA<BackupFormatException>()),
    );
    expect(
      () => reader.readMeta(utf8.encode('{"khong_co_meta":true}')),
      throwsA(isA<BackupFormatException>()),
    );
  });
}
