import 'dart:typed_data';

import 'package:sora_thu_chi/core/backup/local_backup_store.dart';

/// Bản bộ nhớ của [LocalBackupStore] — không đụng đĩa thật.
class FakeLocalBackupStore implements LocalBackupStore {
  final List<LocalBackupEntry> entries = [];
  int _seq = 0;

  @override
  Future<List<LocalBackupEntry>> list() async =>
      entries.where((e) => e.fileName.contains('__safety__') == false).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<LocalBackupEntry> write({
    required Uint8List bytes,
    required String extension,
    required BackupDestination destination,
  }) async {
    _seq++;
    final entry = LocalBackupEntry(
      path: '/fake/backups/${destination.name}/backup_$_seq.$extension',
      fileName:
          destination == BackupDestination.safety
              ? '__safety__backup_$_seq.$extension'
              : 'backup_$_seq.$extension',
      sizeBytes: bytes.length,
      createdAt: DateTime.now().add(Duration(milliseconds: _seq)),
      isAuto: destination == BackupDestination.auto,
      hasAttachments: extension == 'zip',
    );
    entries.add(entry);
    return entry;
  }

  @override
  Future<void> delete(String path) async {
    entries.removeWhere((e) => e.path == path);
  }

  bool cleanupCalled = false;

  @override
  Future<void> cleanupOldSafetySnapshots({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    cleanupCalled = true;
  }
}
