import 'package:sora_thu_chi/core/backup/backup_prefs.dart';
import 'package:sora_thu_chi/core/backup/backup_prefs_store.dart';

/// Bản bộ nhớ của [BackupPrefsStore] — dùng cho test controller/widget, không
/// cần sqlite native.
class FakeBackupPrefsStore implements BackupPrefsStore {
  FakeBackupPrefsStore([BackupPrefs? initial])
    : _prefs = initial ?? BackupPrefs.defaults;

  BackupPrefs _prefs;

  BackupPrefs get storedPrefs => _prefs;

  @override
  Future<BackupPrefs> load() async => _prefs;

  @override
  Future<void> save(BackupPrefs prefs) async => _prefs = prefs;
}
