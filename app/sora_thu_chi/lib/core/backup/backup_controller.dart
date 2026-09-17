import 'dart:io';

import 'package:get/get.dart';

import 'backup_crypto.dart';
import 'backup_data.dart';
import 'backup_data_source.dart';
import 'backup_file_meta.dart';
import 'backup_prefs.dart';
import 'backup_prefs_store.dart';
import 'backup_reader.dart';
import 'backup_scheduler.dart';
import 'backup_summary.dart';
import 'backup_writer.dart';
import 'local_backup_store.dart';

/// Trạng thái + hành vi màn "Sao lưu & Khôi phục" (PBI 35, khuôn
/// `ScanController`/`ReportController`): sheet tạo backup, màn chính và sheet
/// khôi phục cùng đọc **một** controller ⇒ đổi công tắc tự động/thẻ "gần nhất"
/// phản ánh ngay ở mọi nơi hiển thị.
class BackupController extends GetxController {
  BackupController({
    required this.prefsStore,
    required this.localStore,
    required this.crypto,
    required this.dataSource,
    required this.scheduler,
  }) : _reader = BackupReader(crypto);

  final BackupPrefsStore prefsStore;
  final LocalBackupStore localStore;
  final BackupCrypto crypto;
  final BackupDataSource dataSource;
  final BackupScheduler scheduler;
  final BackupReader _reader;

  final Rx<BackupPrefs> prefs = BackupPrefs.defaults.obs;
  final RxList<LocalBackupEntry> backups = <LocalBackupEntry>[].obs;
  final RxBool loading = true.obs;

  Future<void> load() async {
    loading.value = true;
    prefs.value = await prefsStore.load();
    backups.value = await localStore.list();
    loading.value = false;
  }

  /// Dọn `_safety/` quá 24h (R10) — gọi mỗi lần mở màn `01` (T052).
  Future<void> cleanupOldSafetySnapshots() =>
      localStore.cleanupOldSafetySnapshots();

  Future<BackupSummary> currentSummary() async {
    final data = await dataSource.loadCurrent();
    return BackupSummary.fromData(data);
  }

  // ---- US1: sao lưu thủ công ----

  /// Tạo bản sao lưu thủ công vào `backups/manual/`, cập nhật thẻ "Sao lưu gần
  /// nhất" (FR-001..005/FR-008/FR-009) — trả path file vừa tạo để chia sẻ.
  Future<String> createManualBackup({String? password}) async {
    final entry = await _writeBackup(
      password: password,
      destination: BackupDestination.manual,
      updatePrefs: true,
    );
    return entry.path;
  }

  Future<LocalBackupEntry> _writeBackup({
    String? password,
    required BackupDestination destination,
    required bool updatePrefs,
  }) async {
    final data = await dataSource.loadCurrent();
    // ponytail: chạy trực tiếp trên isolate hiện tại thay vì `compute()` —
    // tránh được cả rủi ro tương thích isolate lẫn độ phức tạp thêm; nâng cấp
    // lại `compute()` nếu đo được người dùng thật có backup đủ lớn (nhiều
    // nghìn giao dịch + ảnh) làm giật UI đáng kể.
    final result = await buildBackupFile(
      data: data,
      password: password,
      crypto: crypto,
    );
    final entry = await localStore.write(
      bytes: result.bytes,
      extension: result.extension,
      destination: destination,
    );
    if (updatePrefs) {
      final next = prefs.value.copyWith(
        lastBackupAt: entry.createdAt,
        lastBackupCounts: data.counts,
        lastBackupSizeBytes: entry.sizeBytes,
        lastBackupPath: entry.path,
      );
      prefs.value = next;
      await prefsStore.save(next);
    }
    backups.value = await localStore.list();
    return entry;
  }

  // ---- US2: khôi phục ----

  /// Đọc nhanh `meta` để hiển thị bottom sheet xác nhận (FR-012). File **không**
  /// mật khẩu → xác thực checksum ngay (đọc thẳng `readFullData`) để chặn sớm
  /// file hỏng, đúng flow spec §4.3 bước 2; file có mật khẩu → checksum chỉ
  /// xác thực được sau khi nhập đúng mật khẩu (FR-016), hoãn tới [confirmRestore].
  Future<BackupFileMeta> inspectBackupFile(String path) async {
    final bytes = await File(path).readAsBytes();
    final meta = await _reader.readMeta(bytes);
    if (!meta.hasPassword) {
      await _reader.readFullData(bytes);
    }
    return meta;
  }

  /// Xác thực mật khẩu + đọc số liệu đầy đủ — **chỉ đọc**, chưa ghi đè gì (dùng
  /// ở `RestoreConfirmSheet` để hiện số liệu tóm tắt file có mật khẩu sau khi
  /// nhập đúng, FR-016). Sai mật khẩu ném [BackupDecryptException].
  Future<BackupData> previewBackupFile(String path, {String? password}) async {
    final bytes = await File(path).readAsBytes();
    return _reader.readFullData(bytes, password: password);
  }

  /// Xác nhận khôi phục (FR-013..017): tạo safety-snapshot dữ liệu **hiện có**
  /// trước, đọc + validate file mới, ghi đè trong 1 transaction, rồi cập nhật
  /// lại `BackupPrefs.lastBackup*` theo dữ liệu vừa khôi phục.
  Future<void> confirmRestore({required String path, String? password}) async {
    await _writeBackup(
      destination: BackupDestination.safety,
      updatePrefs: false,
    );

    final bytes = await File(path).readAsBytes();
    final data = await _reader.readFullData(bytes, password: password);
    await dataSource.restore(data);

    final next = prefs.value.copyWith(
      lastBackupAt: DateTime.now(),
      lastBackupCounts: data.counts,
    );
    prefs.value = next;
    await prefsStore.save(next);
  }

  // ---- US3: tự động sao lưu ----

  Future<void> setAutoEnabled(bool value) async {
    final next = prefs.value.copyWith(autoEnabled: value);
    prefs.value = next;
    if (value) {
      await scheduler.schedule(next.autoFrequency);
    } else {
      await scheduler.cancel();
    }
    await prefsStore.save(next);
  }

  Future<void> setAutoFrequency(BackupFrequency frequency) async {
    final next = prefs.value.copyWith(autoFrequency: frequency);
    prefs.value = next;
    if (next.autoEnabled) {
      await scheduler.schedule(frequency);
    }
    await prefsStore.save(next);
  }
}
