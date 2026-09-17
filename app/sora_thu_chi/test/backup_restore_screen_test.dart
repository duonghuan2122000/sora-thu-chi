import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/backup/backup_controller.dart';
import 'package:sora_thu_chi/core/backup/backup_data.dart';
import 'package:sora_thu_chi/core/backup/backup_prefs.dart';
import 'package:sora_thu_chi/core/backup/backup_writer.dart';
import 'package:sora_thu_chi/core/backup/local_backup_store.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/data/local_backup_store_file_system.dart';
import 'package:sora_thu_chi/screens/backup_restore_screen.dart';
import 'package:sora_thu_chi/screens/create_backup_sheet.dart';
import 'package:sora_thu_chi/screens/restore_confirm_sheet.dart';

import 'fakes/fake_backup_crypto.dart';
import 'fakes/fake_backup_data_source.dart';
import 'fakes/fake_backup_prefs_store.dart';
import 'fakes/fake_backup_scheduler.dart';
import 'fakes/fake_local_backup_store.dart';

final _sampleData = BackupData(
  wallets: const [
    Wallet(id: 1, name: 'Tiền mặt', type: WalletType.cash, balance: 100000),
  ],
  categories: const [],
  transactions: const [],
  budgets: const [],
  settings: const {},
);

/// `testWidgets` chạy trong đồng hồ giả — mọi thao tác `dart:io` thật phải
/// nằm trong `tester.runAsync` (xem ghi chú `backup_controller.dart`).
Future<Directory> _tempDir(WidgetTester tester) async {
  late Directory dir;
  await tester.runAsync(() async {
    dir = await Directory.systemTemp.createTemp('sora_restore_screen_test_');
  });
  return dir;
}

BackupController _controller({
  FakeBackupPrefsStore? prefsStore,
  FakeBackupScheduler? scheduler,
  LocalBackupStore? localStore,
}) => BackupController(
  prefsStore: prefsStore ?? FakeBackupPrefsStore(),
  localStore: localStore ?? FakeLocalBackupStore(),
  crypto: FakeBackupCrypto(),
  dataSource: FakeBackupDataSource(_sampleData),
  scheduler: scheduler ?? FakeBackupScheduler(),
);

/// [usesRealIo] — `true` cho controller nối `FileSystemLocalBackupStore` thật:
/// `initState` gọi `load()`/`cleanupOldSafetySnapshots()` chạm `dart:io` thật
/// nên phải bơm màn **trong** `runAsync` (khuôn ghi chú `backup_controller.dart`).
Future<void> _pumpScreen(
  WidgetTester tester,
  BackupController controller, {
  Future<String?> Function()? pickFile,
  Future<void> Function(String path)? shareFile,
  bool usesRealIo = false,
}) async {
  final widget = MaterialApp(
    home: BackupRestoreScreen(
      controller: controller,
      pickFile: pickFile ?? () async => null,
      shareFile: shareFile ?? (_) async {},
    ),
  );
  if (usesRealIo) {
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
  } else {
    await tester.pumpWidget(widget);
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('hiện đúng thẻ "Sao lưu gần nhất" khi chưa từng sao lưu', (
    tester,
  ) async {
    await _pumpScreen(tester, _controller());

    expect(find.byKey(const ValueKey('backup-last-card')), findsOneWidget);
    expect(find.text('Chưa từng sao lưu'), findsOneWidget);
  });

  testWidgets('danh sách rỗng khi chưa có bản nào', (tester) async {
    await _pumpScreen(tester, _controller());

    expect(find.byKey(const ValueKey('backup-list-empty')), findsOneWidget);
  });

  testWidgets('chạm "Tạo bản sao lưu mới" mở CreateBackupSheet', (tester) async {
    await _pumpScreen(tester, _controller());

    await tester.tap(find.byKey(const ValueKey('backup-create-button')));
    await tester.pumpAndSettle();

    expect(find.byType(CreateBackupSheet), findsOneWidget);
  });

  testWidgets('chọn file hỏng → hiện lỗi, không mở bottom sheet', (tester) async {
    final tempDir = await _tempDir(tester);
    addTearDown(() => tester.runAsync(() => tempDir.delete(recursive: true)));
    late String badPath;
    await tester.runAsync(() async {
      final badFile = File('${tempDir.path}/bad.json');
      await badFile.writeAsString('không phải json');
      badPath = badFile.path;
    });

    await _pumpScreen(
      tester,
      _controller(localStore: FileSystemLocalBackupStore(rootOverride: tempDir)),
      pickFile: () async => badPath,
      usesRealIo: true,
    );

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('backup-pick-restore-button')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.byType(RestoreConfirmSheet), findsNothing);
    expect(find.byKey(const ValueKey('backup-restore-error')), findsOneWidget);
  });

  testWidgets('chọn file hợp lệ → mở RestoreConfirmSheet đúng dữ liệu', (
    tester,
  ) async {
    final tempDir = await _tempDir(tester);
    addTearDown(() => tester.runAsync(() => tempDir.delete(recursive: true)));
    late String validPath;
    await tester.runAsync(() async {
      final result = await buildBackupFile(
        data: _sampleData,
        crypto: FakeBackupCrypto(),
      );
      final file = File('${tempDir.path}/valid.json');
      await file.writeAsBytes(result.bytes);
      validPath = file.path;
    });

    await _pumpScreen(
      tester,
      _controller(localStore: FileSystemLocalBackupStore(rootOverride: tempDir)),
      pickFile: () async => validPath,
      usesRealIo: true,
    );

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('backup-pick-restore-button')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.byType(RestoreConfirmSheet), findsOneWidget);
    final sheet = tester.widget<RestoreConfirmSheet>(
      find.byType(RestoreConfirmSheet),
    );
    expect(sheet.path, validPath);
  });

  testWidgets('bật công tắc tự động → hiện chọn tần suất; đổi tần suất phản ánh đúng trạng thái', (
    tester,
  ) async {
    final prefsStore = FakeBackupPrefsStore();
    final scheduler = FakeBackupScheduler();
    await _pumpScreen(
      tester,
      _controller(prefsStore: prefsStore, scheduler: scheduler),
    );

    expect(find.byKey(const ValueKey('backup-auto-frequency-daily')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('backup-auto-switch')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('backup-auto-frequency-daily')), findsOneWidget);
    expect(scheduler.scheduledWith, BackupFrequency.weekly);
    expect(prefsStore.storedPrefs.autoEnabled, isTrue);

    await tester.tap(find.byKey(const ValueKey('backup-auto-frequency-daily')));
    await tester.pumpAndSettle();

    expect(scheduler.scheduledWith, BackupFrequency.daily);
    expect(prefsStore.storedPrefs.autoFrequency, BackupFrequency.daily);
  });

  group('PBI 42 — đường dẫn file tự động sao lưu', () {
    testWidgets(
      'bản gần nhất là tự động → thẻ + danh sách hiện đường dẫn',
      (tester) async {
        final localStore = FakeLocalBackupStore();
        final entry = await localStore.write(
          bytes: Uint8List(0),
          extension: 'json',
          destination: BackupDestination.auto,
        );
        final prefsStore = FakeBackupPrefsStore(
          BackupPrefs.defaults.copyWith(
            lastBackupAt: entry.createdAt,
            lastBackupPath: entry.path,
          ),
        );

        await _pumpScreen(
          tester,
          _controller(localStore: localStore, prefsStore: prefsStore),
        );

        expect(
          find.byKey(const ValueKey('backup-last-auto-path')),
          findsOneWidget,
        );
        expect(find.text(entry.path), findsWidgets);
        expect(
          find.byKey(ValueKey('backup-entry-path-${entry.path}')),
          findsOneWidget,
        );
      },
    );

    testWidgets('bản gần nhất là thủ công → thẻ không hiện đường dẫn', (
      tester,
    ) async {
      final localStore = FakeLocalBackupStore();
      final entry = await localStore.write(
        bytes: Uint8List(0),
        extension: 'json',
        destination: BackupDestination.manual,
      );
      final prefsStore = FakeBackupPrefsStore(
        BackupPrefs.defaults.copyWith(
          lastBackupAt: entry.createdAt,
          lastBackupPath: entry.path,
        ),
      );

      await _pumpScreen(
        tester,
        _controller(localStore: localStore, prefsStore: prefsStore),
      );

      expect(
        find.byKey(const ValueKey('backup-last-auto-path')),
        findsNothing,
      );
      expect(
        find.byKey(ValueKey('backup-entry-path-${entry.path}')),
        findsNothing,
      );
    });

    testWidgets(
      'lastBackupPath không khớp entry nào còn lại (đã bị dọn) → không hiện đường dẫn',
      (tester) async {
        final localStore = FakeLocalBackupStore();
        final prefsStore = FakeBackupPrefsStore(
          BackupPrefs.defaults.copyWith(
            lastBackupAt: DateTime.now(),
            lastBackupPath: '/fake/backups/auto/backup_đã_xoá.json',
          ),
        );

        await _pumpScreen(
          tester,
          _controller(localStore: localStore, prefsStore: prefsStore),
        );

        expect(
          find.byKey(const ValueKey('backup-last-auto-path')),
          findsNothing,
        );
      },
    );
  });

  group('PBI 43 — chọn hành động cho bản sao lưu cũ', () {
    testWidgets('chạm 1 bản → sheet hiện đúng 2 lựa chọn, chưa gọi hành động nào', (
      tester,
    ) async {
      final localStore = FakeLocalBackupStore();
      final entry = await localStore.write(
        bytes: Uint8List(0),
        extension: 'json',
        destination: BackupDestination.manual,
      );
      var shareCalls = 0;
      await _pumpScreen(
        tester,
        _controller(localStore: localStore),
        shareFile: (_) async => shareCalls++,
      );

      await tester.tap(find.byKey(ValueKey('backup-entry-${entry.path}')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('backup-entry-action-share')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backup-entry-action-restore')),
        findsOneWidget,
      );
      expect(shareCalls, 0);
      expect(find.byType(RestoreConfirmSheet), findsNothing);
    });

    testWidgets('chọn "Chia sẻ file" gọi đúng shareFile với path đã chạm, không đổi dữ liệu', (
      tester,
    ) async {
      final localStore = FakeLocalBackupStore();
      final entry = await localStore.write(
        bytes: Uint8List(0),
        extension: 'json',
        destination: BackupDestination.manual,
      );
      final shared = <String>[];
      final prefsStore = FakeBackupPrefsStore();
      await _pumpScreen(
        tester,
        _controller(localStore: localStore, prefsStore: prefsStore),
        shareFile: (path) async => shared.add(path),
      );

      await tester.tap(find.byKey(ValueKey('backup-entry-${entry.path}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('backup-entry-action-share')));
      await tester.pumpAndSettle();

      expect(shared, [entry.path]);
      expect(find.byType(RestoreConfirmSheet), findsNothing);
      expect(localStore.entries.length, 1);
      expect(prefsStore.storedPrefs, BackupPrefs.defaults);
    });

    testWidgets('chia sẻ bản tự động cũng gọi được shareFile bình thường', (
      tester,
    ) async {
      final localStore = FakeLocalBackupStore();
      final entry = await localStore.write(
        bytes: Uint8List(0),
        extension: 'json',
        destination: BackupDestination.auto,
      );
      final shared = <String>[];
      await _pumpScreen(
        tester,
        _controller(localStore: localStore),
        shareFile: (path) async => shared.add(path),
      );

      await tester.tap(find.byKey(ValueKey('backup-entry-${entry.path}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('backup-entry-action-share')));
      await tester.pumpAndSettle();

      expect(shared, [entry.path]);
    });

    testWidgets('chọn "Chia sẻ file" khi shareFile lỗi (file thiếu) → báo lỗi, không crash', (
      tester,
    ) async {
      final localStore = FakeLocalBackupStore();
      final entry = await localStore.write(
        bytes: Uint8List(0),
        extension: 'json',
        destination: BackupDestination.manual,
      );
      await _pumpScreen(
        tester,
        _controller(localStore: localStore),
        shareFile: (_) async => throw const FileSystemException('missing'),
      );

      await tester.tap(find.byKey(ValueKey('backup-entry-${entry.path}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('backup-entry-action-share')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final errorLabel = tester.widget<Text>(
        find.byKey(const ValueKey('backup-restore-error')),
      );
      expect(errorLabel.data, 'Không tìm thấy file');
    });

    testWidgets('đóng sheet không chọn gì → không gọi shareFile, dữ liệu không đổi', (
      tester,
    ) async {
      final localStore = FakeLocalBackupStore();
      final entry = await localStore.write(
        bytes: Uint8List(0),
        extension: 'json',
        destination: BackupDestination.manual,
      );
      var shareCalls = 0;
      await _pumpScreen(
        tester,
        _controller(localStore: localStore),
        shareFile: (_) async => shareCalls++,
      );

      await tester.tap(find.byKey(ValueKey('backup-entry-${entry.path}')));
      await tester.pumpAndSettle();
      // Chạm ra ngoài sheet (vùng mờ phía trên) để đóng mà không chọn gì.
      await tester.tapAt(const Offset(200, 50));
      await tester.pumpAndSettle();

      expect(shareCalls, 0);
      expect(find.byType(RestoreConfirmSheet), findsNothing);
      expect(
        find.byKey(const ValueKey('backup-entry-action-share')),
        findsNothing,
      );
    });

    testWidgets('chọn "Khôi phục từ bản này" → mở đúng RestoreConfirmSheet', (
      tester,
    ) async {
      final tempDir = await _tempDir(tester);
      addTearDown(() => tester.runAsync(() => tempDir.delete(recursive: true)));
      final localStore = FileSystemLocalBackupStore(rootOverride: tempDir);
      late LocalBackupEntry entry;
      await tester.runAsync(() async {
        final result = await buildBackupFile(
          data: _sampleData,
          crypto: FakeBackupCrypto(),
        );
        entry = await localStore.write(
          bytes: result.bytes,
          extension: 'json',
          destination: BackupDestination.manual,
        );
      });

      await _pumpScreen(
        tester,
        _controller(localStore: localStore),
        usesRealIo: true,
      );

      await tester.runAsync(() async {
        await tester.tap(find.byKey(ValueKey('backup-entry-${entry.path}')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('backup-entry-action-restore')),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.byType(RestoreConfirmSheet), findsOneWidget);
      final sheet = tester.widget<RestoreConfirmSheet>(
        find.byType(RestoreConfirmSheet),
      );
      expect(sheet.path, entry.path);
    });

    testWidgets('chọn "Khôi phục từ bản này" khi file đã bị xoá → báo lỗi, không crash', (
      tester,
    ) async {
      final localStore = FakeLocalBackupStore();
      final entry = await localStore.write(
        bytes: Uint8List(0),
        extension: 'json',
        destination: BackupDestination.manual,
      );

      await _pumpScreen(tester, _controller(localStore: localStore));

      await tester.runAsync(() async {
        await tester.tap(find.byKey(ValueKey('backup-entry-${entry.path}')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('backup-entry-action-restore')),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(RestoreConfirmSheet), findsNothing);
      expect(
        find.byKey(const ValueKey('backup-restore-error')),
        findsOneWidget,
      );
    });
  });
}
