import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import 'backup_crypto.dart';
import 'backup_data.dart';
import 'backup_file_meta.dart';
import 'backup_schema_migration.dart';

/// File sai định dạng/thiếu trường/checksum không khớp — lỗi rõ ràng, không
/// phải kiểu ném "bắt được" ngẫu nhiên (T015).
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// `schema_version` của file cao hơn phiên bản app đang hỗ trợ (spec §4.3).
class BackupIncompatibleException implements Exception {
  const BackupIncompatibleException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Đọc + validate + migrate file backup (`.json`/`.zip`) — [readMeta] đọc
/// nhanh không giải mã `data`; [readFullData] giải mã (nếu có mật khẩu) +
/// validate checksum + migrate schema trước khi trả [BackupData].
class BackupReader {
  BackupReader(this._crypto);

  final BackupCrypto _crypto;

  Future<BackupFileMeta> readMeta(List<int> bytes) async {
    final json = _extractFileJson(bytes);
    return _parseMeta(json);
  }

  Future<BackupData> readFullData(
    List<int> bytes, {
    String? password,
  }) async {
    final json = _extractFileJson(bytes);
    final meta = _parseMeta(json);
    if (!meta.isSchemaSupported(kBackupSchemaVersion)) {
      throw const BackupIncompatibleException(
        'File backup từ phiên bản app mới hơn, không tương thích. '
        'Vui lòng cập nhật app.',
      );
    }
    final dataField = json['data'];
    final String dataJsonString;
    if (meta.hasPassword) {
      if (dataField is! String) {
        throw const BackupFormatException('File backup không hợp lệ');
      }
      if (password == null || password.isEmpty) {
        throw const BackupDecryptException('Cần nhập mật khẩu');
      }
      dataJsonString = await _crypto.decrypt(dataField, password);
    } else {
      dataJsonString = jsonEncode(dataField);
    }
    final checksum = sha256.convert(utf8.encode(dataJsonString)).toString();
    if (checksum != meta.checksum) {
      throw const BackupFormatException(
        'File backup bị hỏng hoặc đã bị chỉnh sửa (checksum không khớp)',
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(dataJsonString);
    } catch (_) {
      throw const BackupFormatException('File backup không hợp lệ');
    }
    if (decoded is! Map) {
      throw const BackupFormatException('File backup không hợp lệ');
    }
    final migrated = migrateBackupSchema(
      meta.schemaVersion,
      Map<String, Object?>.from(decoded),
    );
    return BackupData.fromJson(migrated);
  }

  BackupFileMeta _parseMeta(Map<String, Object?> json) {
    final metaRaw = json['meta'];
    if (metaRaw is! Map) {
      throw const BackupFormatException('File backup không hợp lệ');
    }
    try {
      return BackupFileMeta.fromJson(Map<String, Object?>.from(metaRaw));
    } on FormatException {
      throw const BackupFormatException('File backup không hợp lệ');
    }
  }

  /// `.zip` (chữ ký `PK`) → đọc `data.json` bên trong; ngược lại coi là `.json`
  /// thuần. Lỗi giải nén/parse JSON → [BackupFormatException] rõ ràng.
  Map<String, Object?> _extractFileJson(List<int> bytes) {
    final isZip =
        bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B;
    String text;
    if (isZip) {
      try {
        final archive = ZipDecoder().decodeBytes(
          Uint8List.fromList(bytes),
        );
        final entry = archive.files.firstWhere(
          (f) => f.name == 'data.json',
          orElse: () => throw const BackupFormatException(
            'File .zip không có data.json',
          ),
        );
        text = utf8.decode(entry.content as List<int>);
      } on BackupFormatException {
        rethrow;
      } catch (_) {
        throw const BackupFormatException('File .zip bị hỏng');
      }
    } else {
      try {
        text = utf8.decode(bytes);
      } catch (_) {
        throw const BackupFormatException('File backup không hợp lệ');
      }
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      throw const BackupFormatException('File backup không hợp lệ');
    }
    if (decoded is! Map) {
      throw const BackupFormatException('File backup không hợp lệ');
    }
    return Map<String, Object?>.from(decoded);
  }
}
