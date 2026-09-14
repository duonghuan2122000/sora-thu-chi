import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/backup/local_backup_store.dart';
import 'package:sora_thu_chi/data/local_backup_store_file_system.dart';

void main() {
  late Directory tempDir;
  late FileSystemLocalBackupStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sora_backup_test_');
    store = FileSystemLocalBackupStore(rootOverride: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('liệt kê đúng theo thư mục con (manual/auto), không gồm _safety', () async {
    await store.write(
      bytes: Uint8List.fromList([1]),
      extension: 'json',
      destination: BackupDestination.manual,
    );
    await store.write(
      bytes: Uint8List.fromList([2]),
      extension: 'zip',
      destination: BackupDestination.auto,
    );
    await store.write(
      bytes: Uint8List.fromList([3]),
      extension: 'json',
      destination: BackupDestination.safety,
    );

    final entries = await store.list();
    expect(entries.length, 2);
    expect(entries.where((e) => e.isAuto).length, 1);
    expect(entries.where((e) => e.hasAttachments).length, 1);
  });

  test('xoá đúng file', () async {
    final entry = await store.write(
      bytes: Uint8List.fromList([1]),
      extension: 'json',
      destination: BackupDestination.manual,
    );
    await store.delete(entry.path);
    expect(await store.list(), isEmpty);
  });

  test('dọn file _safety quá 24h, giữ file mới', () async {
    await store.write(
      bytes: Uint8List.fromList([1]),
      extension: 'json',
      destination: BackupDestination.safety,
    );
    final safetyDir = Directory('${tempDir.path}/backups/_safety');
    final oldFile = File('${safetyDir.path}/old.json');
    await oldFile.writeAsBytes([9]);
    await oldFile.setLastModified(
      DateTime.now().subtract(const Duration(hours: 25)),
    );

    await store.cleanupOldSafetySnapshots();

    final remaining = await safetyDir.list().toList();
    expect(remaining.length, 1);
    expect(await oldFile.exists(), isFalse);
  });

  test('ghi lỗi giữa chừng không để lại file tạm', () async {
    final entry = await store.write(
      bytes: Uint8List.fromList([1, 2, 3]),
      extension: 'json',
      destination: BackupDestination.manual,
    );
    final manualDir = Directory('${tempDir.path}/backups/manual');
    final tmpFiles = await manualDir
        .list()
        .where((e) => e.path.endsWith('.tmp'))
        .toList();
    expect(tmpFiles, isEmpty, reason: 'ghi xong phải rename hết, không sót .tmp');
    expect(await File(entry.path).exists(), isTrue);
  });
}
