import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/backup/backup_controller.dart';
import 'package:sora_thu_chi/core/backup/backup_data.dart';
import 'package:sora_thu_chi/core/backup/backup_prefs.dart';
import 'package:sora_thu_chi/core/backup/backup_reader.dart';
import 'package:sora_thu_chi/core/backup/local_backup_store.dart';
import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/data/backup_crypto_cryptography.dart';
import 'package:sora_thu_chi/data/local_backup_store_file_system.dart';

import 'fakes/fake_backup_data_source.dart';
import 'fakes/fake_backup_prefs_store.dart';
import 'fakes/fake_backup_scheduler.dart';
import 'fakes/fake_local_backup_store.dart';

/// [localStore] tùy chọn — mặc định [FakeLocalBackupStore] (thuần bộ nhớ,
/// nhanh cho test chỉ đếm/đọc `BackupPrefs`); test cần đọc lại file thật trên
/// đĩa (khôi phục) truyền [FileSystemLocalBackupStore] trỏ thư mục tạm.
BackupController _controller({
  FakeBackupPrefsStore? prefsStore,
  LocalBackupStore? localStore,
  FakeBackupDataSource? dataSource,
  FakeBackupScheduler? scheduler,
}) => BackupController(
  prefsStore: prefsStore ?? FakeBackupPrefsStore(),
  localStore: localStore ?? FakeLocalBackupStore(),
  crypto: CryptographyBackupCrypto(),
  dataSource: dataSource ?? FakeBackupDataSource(),
  scheduler: scheduler ?? FakeBackupScheduler(),
);

final _sampleData = BackupData(
  wallets: const [
    Wallet(id: 1, name: 'Tiền mặt', type: WalletType.cash, balance: 100000),
  ],
  categories: const [
    Category(
      id: 1,
      name: 'Ăn uống',
      type: CategoryType.expense,
      icon: 'food',
      color: 0xFFAABBCC,
    ),
  ],
  transactions: const [],
  budgets: const [],
  settings: const {},
);

void main() {
  group('US1 — sao lưu thủ công', () {
    test(
      'createManualBackup cập nhật đúng lastBackup*, thêm 1 phần tử vào danh sách',
      () async {
        final prefsStore = FakeBackupPrefsStore();
        final localStore = FakeLocalBackupStore();
        final dataSource = FakeBackupDataSource(_sampleData);
        final controller = _controller(
          prefsStore: prefsStore,
          localStore: localStore,
          dataSource: dataSource,
        );

        final path = await controller.createManualBackup();

        expect(path, isNotEmpty);
        expect(controller.backups.length, 1);
        expect(controller.prefs.value.lastBackupAt, isNotNull);
        expect(controller.prefs.value.lastBackupCounts, {
          'wallets': 1,
          'categories': 1,
          'transactions': 0,
          'budgets': 0,
        });
        expect(prefsStore.storedPrefs.lastBackupAt, isNotNull);
      },
    );

    test('có password → BackupCrypto.encrypt được gọi (data đã mã hoá)', () async {
      final tempDir = await Directory.systemTemp.createTemp('sora_ctrl_test_');
      addTearDown(() => tempDir.delete(recursive: true));
      final localStore = FileSystemLocalBackupStore(rootOverride: tempDir);
      final controller = _controller(
        localStore: localStore,
        dataSource: FakeBackupDataSource(_sampleData),
      );

      final path = await controller.createManualBackup(password: 'bi-mat-123');

      final bytes = await File(path).readAsBytes();
      final meta = await BackupReader(CryptographyBackupCrypto()).readMeta(bytes);
      expect(meta.hasPassword, isTrue);
    });
  });

  group('US2 — khôi phục', () {
    test('file hỏng/checksum sai → inspectBackupFile ném lỗi, không tạo safety-snapshot', () async {
      final tempDir = await Directory.systemTemp.createTemp('sora_ctrl_test_');
      addTearDown(() => tempDir.delete(recursive: true));
      final localStore = FileSystemLocalBackupStore(rootOverride: tempDir);
      final controller = _controller(localStore: localStore);

      final badFile = File('${tempDir.path}/bad.json');
      await badFile.writeAsString('không phải json');

      expect(
        () => controller.inspectBackupFile(badFile.path),
        throwsA(isA<BackupFormatException>()),
      );
      expect(await localStore.list(), isEmpty);
    });

    test('confirmRestore tạo đúng 1 safety-snapshot trước khi ghi đè', () async {
      final tempDir = await Directory.systemTemp.createTemp('sora_ctrl_test_');
      addTearDown(() => tempDir.delete(recursive: true));
      final localStore = FileSystemLocalBackupStore(rootOverride: tempDir);
      final dataSource = FakeBackupDataSource(_sampleData);
      final controller = _controller(
        localStore: localStore,
        dataSource: dataSource,
      );

      final backupPath = await controller.createManualBackup();

      // Dữ liệu "hiện có" đổi khác trước khi restore — safety-snapshot phải
      // chụp đúng trạng thái NÀY (trước khi ghi đè).
      dataSource.current = const BackupData(
        wallets: [],
        categories: [],
        transactions: [],
        budgets: [],
        settings: {},
      );

      await controller.confirmRestore(path: backupPath);

      final safetyDir = Directory('${tempDir.path}/backups/_safety');
      expect(await safetyDir.list().length, 1);
      expect(dataSource.restoreCallCount, 1);
      expect(dataSource.restoredWith!.wallets.single.id, 1);
    });

    test('file schema_version không tương thích → BackupIncompatibleException', () async {
      final tempDir = await Directory.systemTemp.createTemp('sora_ctrl_test_');
      addTearDown(() => tempDir.delete(recursive: true));
      final localStore = FileSystemLocalBackupStore(rootOverride: tempDir);
      final controller = _controller(
        localStore: localStore,
        dataSource: FakeBackupDataSource(_sampleData),
      );

      final path = await controller.createManualBackup();
      final file = File(path);
      final text = await file.readAsString();
      final tampered = text.replaceFirst(
        RegExp(r'"schema_version":\d+'),
        '"schema_version":999',
      );
      final tamperedFile = File('${tempDir.path}/tampered.json');
      await tamperedFile.writeAsString(tampered);

      expect(
        () => controller.confirmRestore(path: tamperedFile.path),
        throwsA(isA<BackupIncompatibleException>()),
      );
    });
  });

  group('US3 — tự động sao lưu', () {
    test('bật/tắt và đổi tần suất gọi đúng seam + lưu đúng BackupPrefs', () async {
      final prefsStore = FakeBackupPrefsStore();
      final scheduler = FakeBackupScheduler();
      final controller = _controller(
        prefsStore: prefsStore,
        scheduler: scheduler,
      );

      await controller.setAutoEnabled(true);
      expect(scheduler.scheduledWith, BackupFrequency.weekly);
      expect(prefsStore.storedPrefs.autoEnabled, isTrue);

      await controller.setAutoFrequency(BackupFrequency.daily);
      expect(scheduler.scheduledWith, BackupFrequency.daily);
      expect(prefsStore.storedPrefs.autoFrequency, BackupFrequency.daily);

      await controller.setAutoEnabled(false);
      expect(scheduler.cancelled, isTrue);
      expect(prefsStore.storedPrefs.autoEnabled, isFalse);
    });
  });
}
