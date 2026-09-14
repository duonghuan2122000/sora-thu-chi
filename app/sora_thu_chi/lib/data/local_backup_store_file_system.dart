import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/backup/local_backup_store.dart';

/// Impl thật [LocalBackupStore] — 3 thư mục con `app_documents/backups/`:
/// `manual/`, `auto/`, `_safety/` (dùng `path_provider` đã có). [rootOverride]
/// là seam test (khuôn PBI 24/25): bơm thư mục tạm → không cần plugin thật.
class FileSystemLocalBackupStore implements LocalBackupStore {
  FileSystemLocalBackupStore({this.rootOverride});

  final Directory? rootOverride;

  Future<Directory> _root() async =>
      rootOverride ?? getApplicationDocumentsDirectory();

  String _folderName(BackupDestination destination) => switch (destination) {
    BackupDestination.manual => 'manual',
    BackupDestination.auto => 'auto',
    BackupDestination.safety => '_safety',
  };

  Future<Directory> _dir(String sub) async {
    final root = await _root();
    final dir = Directory(p.join(root.path, 'backups', sub));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @override
  Future<LocalBackupEntry> write({
    required Uint8List bytes,
    required String extension,
    required BackupDestination destination,
  }) async {
    final dir = await _dir(_folderName(destination));
    final now = DateTime.now();
    final fileName = 'thuchi_backup_${_stamp(now)}.$extension';
    final finalFile = File(p.join(dir.path, fileName));
    final tempFile = File('${finalFile.path}.tmp');
    try {
      await tempFile.writeAsBytes(bytes, flush: true);
      await tempFile.rename(finalFile.path);
    } on FileSystemException {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
    return LocalBackupEntry(
      path: finalFile.path,
      fileName: fileName,
      sizeBytes: bytes.length,
      createdAt: now,
      isAuto: destination == BackupDestination.auto,
      hasAttachments: extension == 'zip',
    );
  }

  @override
  Future<List<LocalBackupEntry>> list() async {
    final entries = <LocalBackupEntry>[];
    for (final dest in [BackupDestination.manual, BackupDestination.auto]) {
      final dir = await _dir(_folderName(dest));
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final stat = await entity.stat();
        entries.add(
          LocalBackupEntry(
            path: entity.path,
            fileName: p.basename(entity.path),
            sizeBytes: stat.size,
            createdAt: stat.modified,
            isAuto: dest == BackupDestination.auto,
            hasAttachments: entity.path.endsWith('.zip'),
          ),
        );
      }
    }
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> cleanupOldSafetySnapshots({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final dir = await _dir('_safety');
    final cutoff = DateTime.now().subtract(maxAge);
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final stat = await entity.stat();
      if (stat.modified.isBefore(cutoff)) {
        await entity.delete();
      }
    }
  }

  String _stamp(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}${two(dt.month)}${two(dt.day)}'
        '_${two(dt.hour)}${two(dt.minute)}${two(dt.second)}';
  }
}
