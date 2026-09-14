import 'package:sora_thu_chi/core/backup/backup_prefs.dart';
import 'package:sora_thu_chi/core/backup/backup_scheduler.dart';

class FakeBackupScheduler implements BackupScheduler {
  BackupFrequency? scheduledWith;
  bool cancelled = false;

  @override
  Future<void> schedule(BackupFrequency frequency) async {
    scheduledWith = frequency;
    cancelled = false;
  }

  @override
  Future<void> cancel() async {
    cancelled = true;
    scheduledWith = null;
  }
}
