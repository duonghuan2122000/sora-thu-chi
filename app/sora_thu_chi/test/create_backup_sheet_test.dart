import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/backup/backup_controller.dart';
import 'package:sora_thu_chi/core/backup/backup_data.dart';
import 'package:sora_thu_chi/core/backup/backup_reader.dart';
import 'package:sora_thu_chi/core/backup/local_backup_store.dart';
import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/data/local_backup_store_file_system.dart';
import 'package:sora_thu_chi/screens/create_backup_sheet.dart';

import 'fakes/fake_backup_crypto.dart';
import 'fakes/fake_backup_data_source.dart';
import 'fakes/fake_backup_prefs_store.dart';
import 'fakes/fake_backup_scheduler.dart';
import 'fakes/fake_local_backup_store.dart';

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

BackupController _controller({LocalBackupStore? localStore}) => BackupController(
  prefsStore: FakeBackupPrefsStore(),
  localStore: localStore ?? FakeLocalBackupStore(),
  crypto: FakeBackupCrypto(),
  dataSource: FakeBackupDataSource(_sampleData),
  scheduler: FakeBackupScheduler(),
);

Future<void> _pump(WidgetTester tester, CreateBackupSheet sheet) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => sheet,
            ),
            child: const Text('mở'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('mở'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('hiện đúng số liệu tóm tắt', (tester) async {
    final controller = _controller();
    await _pump(
      tester,
      CreateBackupSheet(controller: controller, shareFile: (_) async {}),
    );

    expect(find.byKey(const ValueKey('create-backup-summary')), findsOneWidget);
    expect(find.textContaining('1 ví'), findsOneWidget);
    expect(find.textContaining('1 danh mục'), findsOneWidget);
  });

  testWidgets('bật công tắc mật khẩu hiện ô nhập', (tester) async {
    final controller = _controller();
    await _pump(
      tester,
      CreateBackupSheet(controller: controller, shareFile: (_) async {}),
    );

    expect(
      find.byKey(const ValueKey('create-backup-password-field')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('create-backup-password-switch')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('create-backup-password-field')),
      findsOneWidget,
    );
  });

  testWidgets(
    'chạm "Tạo & Chia sẻ" gọi đúng createManualBackup với password tương ứng',
    (tester) async {
      // `testWidgets` chạy trong đồng hồ giả — MỌI thao tác `dart:io` thật (kể
      // cả tạo thư mục tạm) phải nằm **trong** `runAsync`, kể cả thao tác chạm
      // nút kích hoạt việc ghi file, nếu không sẽ treo vô thời hạn.
      late Directory tempDir;
      late BackupController controller;
      String? sharedPath;
      Uint8List? bytes;

      await tester.runAsync(() async {
        tempDir = await Directory.systemTemp.createTemp('sora_sheet_test_');
        controller = _controller(
          localStore: FileSystemLocalBackupStore(rootOverride: tempDir),
        );
      });
      addTearDown(() => tempDir.delete(recursive: true));

      await _pump(
        tester,
        CreateBackupSheet(
          controller: controller,
          shareFile: (path) async => sharedPath = path,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('create-backup-password-switch')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('create-backup-password-field')),
        'bi-mat-123',
      );

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('create-backup-submit')));
        while (sharedPath == null) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        bytes = await File(sharedPath!).readAsBytes();
      });
      await tester.pumpAndSettle();

      expect(sharedPath, isNotNull);
      final meta = await BackupReader(FakeBackupCrypto()).readMeta(bytes!);
      expect(meta.hasPassword, isTrue);
    },
  );
}
