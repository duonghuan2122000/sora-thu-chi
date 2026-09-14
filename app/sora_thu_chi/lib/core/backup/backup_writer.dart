import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import 'backup_crypto.dart';
import 'backup_data.dart';
import 'backup_file_meta.dart';

/// Phiên bản app hiển thị tham khảo trong `meta.app_version` — hằng đơn giản
/// (không thêm `package_info_plus` chỉ để đọc lại đúng số đã có trong `pubspec.yaml`).
const String kBackupAppVersion = '1.0.0';

/// Kết quả build file backup — [extension] quyết định tên file khi ghi ra đĩa.
class BackupWriteResult {
  const BackupWriteResult({required this.bytes, required this.extension});

  final Uint8List bytes;

  /// `'json'` khi không ảnh đính kèm, `'zip'` khi có (research R2).
  final String extension;
}

/// Build nội dung file backup từ [data] — JSON thuần khi [attachments] rỗng,
/// gói `.zip` (`data.json` + `/images/`) khi có (R2). [attachments] là
/// `đường dẫn gốc → bytes ảnh` đã đọc sẵn — hàm này thuần, không tự đọc đĩa.
///
/// Có [password] → phần `data` được mã hoá qua [crypto] trước khi ghi (chỉ
/// `data`, `meta` luôn đọc được không cần mật khẩu — FR-016).
///
/// ponytail: [BackupController] gọi hàm này trực tiếp trên isolate hiện tại
/// (không bọc `compute()`) — tránh rủi ro tương thích isolate, đơn giản hơn;
/// nâng cấp lại nếu backup thật đủ lớn (nhiều nghìn giao dịch + ảnh) làm giật
/// UI đáng kể.
Future<BackupWriteResult> buildBackupFile({
  required BackupData data,
  String? password,
  Map<String, Uint8List> attachments = const {},
  required BackupCrypto crypto,
}) async {
  final dataJson = jsonEncode(data.toJson());
  final checksum = sha256.convert(utf8.encode(dataJson)).toString();
  final hasPassword = password != null && password.isNotEmpty;

  final Object dataField = hasPassword
      ? await crypto.encrypt(dataJson, password)
      : data.toJson();

  final meta = BackupFileMeta(
    schemaVersion: kBackupSchemaVersion,
    appVersion: kBackupAppVersion,
    exportedAt: DateTime.now(),
    currencyDefault: 'VND',
    counts: data.counts,
    hasAttachments: attachments.isNotEmpty,
    checksum: checksum,
    hasPassword: hasPassword,
  );

  final fileJson = jsonEncode({'meta': meta.toJson(), 'data': dataField});

  if (attachments.isEmpty) {
    return BackupWriteResult(
      bytes: Uint8List.fromList(utf8.encode(fileJson)),
      extension: 'json',
    );
  }

  final archive = Archive()
    ..addFile(
      ArchiveFile.string('data.json', fileJson)..lastModTime = 0,
    );
  for (final entry in attachments.entries) {
    final name = 'images/${entry.key.split(RegExp(r'[\\/]')).last}';
    archive.addFile(ArchiveFile(name, entry.value.length, entry.value));
  }
  final zipBytes = ZipEncoder().encode(archive);
  return BackupWriteResult(
    bytes: Uint8List.fromList(zipBytes),
    extension: 'zip',
  );
}
