import '../core/backup/backup_data.dart';
import '../core/backup/backup_data_source.dart';
import 'backup_restorer_drift.dart';
import 'backup_snapshot_drift.dart';
import 'db/app_database.dart';

/// Impl thật [BackupDataSource] — gói [loadBackupData] (đọc) và [BackupRestorer]
/// (ghi đè trong transaction) trên cùng 1 connection drift.
class DriftBackupDataSource implements BackupDataSource {
  DriftBackupDataSource(this._db) : _restorer = BackupRestorer(_db);

  final AppDatabase _db;
  final BackupRestorer _restorer;

  @override
  Future<BackupData> loadCurrent() => loadBackupData(_db);

  @override
  Future<void> restore(BackupData data) => _restorer.restore(data);
}
