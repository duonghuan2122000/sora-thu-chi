import 'package:sora_thu_chi/core/backup/backup_data.dart';
import 'package:sora_thu_chi/core/backup/backup_data_source.dart';

const _emptyBackupData = BackupData(
  wallets: [],
  categories: [],
  transactions: [],
  budgets: [],
  settings: {},
);

/// Bản bộ nhớ của [BackupDataSource] — [current] giả lập dữ liệu "hiện có";
/// [restoredWith] ghi lại lần restore gần nhất để test assert.
class FakeBackupDataSource implements BackupDataSource {
  FakeBackupDataSource([this.current = _emptyBackupData]);

  BackupData current;
  BackupData? restoredWith;
  int restoreCallCount = 0;

  @override
  Future<BackupData> loadCurrent() async => current;

  @override
  Future<void> restore(BackupData data) async {
    restoreCallCount++;
    restoredWith = data;
    current = data;
  }
}
