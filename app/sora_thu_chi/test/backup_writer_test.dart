import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/backup/backup_crypto.dart';
import 'package:sora_thu_chi/core/backup/backup_data.dart';
import 'package:sora_thu_chi/core/backup/backup_writer.dart';

class _FakeCrypto implements BackupCrypto {
  String? lastPlaintext;
  String? lastPassword;

  @override
  Future<String> encrypt(String plaintext, String password) async {
    lastPlaintext = plaintext;
    lastPassword = password;
    return 'ENC(${base64Encode(utf8.encode(plaintext))})';
  }

  @override
  Future<String> decrypt(String ciphertext, String password) async {
    final inner = ciphertext.substring(4, ciphertext.length - 1);
    return utf8.decode(base64Decode(inner));
  }
}

const _emptyData = BackupData(
  wallets: [],
  categories: [],
  transactions: [],
  budgets: [],
  settings: {},
);

void main() {
  test('không ảnh → .json', () async {
    final result = await buildBackupFile(
      data: _emptyData,
      crypto: _FakeCrypto(),
    );
    expect(result.extension, 'json');
    final json = jsonDecode(utf8.decode(result.bytes)) as Map;
    expect(json['meta'], isNotNull);
    expect(json['data'], isA<Map>());
  });

  test('có ảnh → .zip đúng cấu trúc data.json + /images/', () async {
    final result = await buildBackupFile(
      data: _emptyData,
      crypto: _FakeCrypto(),
      attachments: {'/local/path/hoadon.png': Uint8List.fromList([1, 2, 3])},
    );
    expect(result.extension, 'zip');
    final archive = ZipDecoder().decodeBytes(result.bytes);
    final names = archive.files.map((f) => f.name).toSet();
    expect(names, contains('data.json'));
    expect(names, contains('images/hoadon.png'));
  });

  test('checksum khớp SHA-256 tính lại trên phần data', () async {
    final result = await buildBackupFile(
      data: _emptyData,
      crypto: _FakeCrypto(),
    );
    final json = jsonDecode(utf8.decode(result.bytes)) as Map;
    final meta = json['meta'] as Map;
    final dataJson = jsonEncode(json['data']);
    final recomputed = sha256.convert(utf8.encode(dataJson)).toString();
    expect(meta['checksum'], recomputed);
  });

  test('có password → phần data đã mã hoá, không đọc được nguyên văn', () async {
    final crypto = _FakeCrypto();
    final result = await buildBackupFile(
      data: _emptyData,
      password: 'bi-mat',
      crypto: crypto,
    );
    final json = jsonDecode(utf8.decode(result.bytes)) as Map;
    expect(json['data'], isA<String>());
    expect((json['meta'] as Map)['has_password'], isTrue);
    expect(crypto.lastPassword, 'bi-mat');
  });
}
