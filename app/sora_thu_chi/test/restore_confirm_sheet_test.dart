import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/backup/backup_controller.dart';
import 'package:sora_thu_chi/core/backup/backup_data.dart';
import 'package:sora_thu_chi/core/backup/backup_file_meta.dart';
import 'package:sora_thu_chi/core/backup/backup_reader.dart';
import 'package:sora_thu_chi/core/backup/backup_writer.dart';
import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/data/local_backup_store_file_system.dart';
import 'package:sora_thu_chi/screens/restore_confirm_sheet.dart';

import 'fakes/fake_backup_crypto.dart';
import 'fakes/fake_backup_data_source.dart';
import 'fakes/fake_backup_prefs_store.dart';
import 'fakes/fake_backup_scheduler.dart';

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

/// `testWidgets` chạy trong đồng hồ giả — mọi thao tác `dart:io` thật (tạo thư
/// mục tạm, đọc/ghi file) phải nằm **trong** `tester.runAsync`, nếu không sẽ
/// treo vô thời hạn (không có exception, không timeout — khuôn US4
/// `report_export_screen_test.dart`, xem ghi chú tại `backup_controller.dart`).
Future<Directory> _tempDir(WidgetTester tester) async {
  late Directory dir;
  await tester.runAsync(() async {
    dir = await Directory.systemTemp.createTemp('sora_restore_sheet_test_');
  });
  return dir;
}

BackupController _controller(Directory tempDir) => BackupController(
  prefsStore: FakeBackupPrefsStore(),
  localStore: FileSystemLocalBackupStore(rootOverride: tempDir),
  crypto: FakeBackupCrypto(),
  dataSource: FakeBackupDataSource(_sampleData),
  scheduler: FakeBackupScheduler(),
);

Future<void> _pumpSheet(
  WidgetTester tester,
  BackupController controller,
  BackupFileMeta meta,
  String path,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RestoreConfirmSheet(controller: controller, path: path, meta: meta),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('nút khôi phục vô hiệu khi chưa tick, bật sau khi tick', (
    tester,
  ) async {
    final tempDir = await _tempDir(tester);
    addTearDown(
      () => tester.runAsync(() => tempDir.delete(recursive: true)),
    );

    late Uint8List bytes;
    late String path;
    await tester.runAsync(() async {
      final result = await buildBackupFile(
        data: _sampleData,
        crypto: FakeBackupCrypto(),
      );
      final file = File('${tempDir.path}/no_password.json');
      await file.writeAsBytes(result.bytes);
      bytes = result.bytes;
      path = file.path;
    });
    final meta = await BackupReader(FakeBackupCrypto()).readMeta(bytes);

    await _pumpSheet(tester, _controller(tempDir), meta, path);

    expect(find.byKey(const ValueKey('restore-summary')), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('restore-confirm-submit')),
    );
    expect(button.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('restore-confirm-checkbox-row')));
    await tester.pumpAndSettle();

    final buttonAfter = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('restore-confirm-submit')),
    );
    expect(buttonAfter.onPressed, isNotNull);
  });

  testWidgets(
    'file có mật khẩu → không hiện số liệu trước khi nhập đúng, sai vẫn cho thử lại',
    (tester) async {
      final tempDir = await _tempDir(tester);
      addTearDown(
        () => tester.runAsync(() => tempDir.delete(recursive: true)),
      );

      late Uint8List bytes;
      late String path;
      await tester.runAsync(() async {
        final result = await buildBackupFile(
          data: _sampleData,
          password: 'dung-123',
          crypto: FakeBackupCrypto(),
        );
        final file = File('${tempDir.path}/with_password.json');
        await file.writeAsBytes(result.bytes);
        bytes = result.bytes;
        path = file.path;
      });
      final meta = await BackupReader(FakeBackupCrypto()).readMeta(bytes);

      await _pumpSheet(tester, _controller(tempDir), meta, path);

      expect(find.byKey(const ValueKey('restore-summary')), findsNothing);
      expect(find.byKey(const ValueKey('restore-password-field')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('restore-password-field')),
        'sai',
      );
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('restore-password-submit')));
        await Future<void>.delayed(const Duration(milliseconds: 700));
      });
      await tester.pumpAndSettle();

      expect(find.text('Sai mật khẩu, vui lòng thử lại'), findsOneWidget);
      expect(find.byKey(const ValueKey('restore-summary')), findsNothing);
      // Vẫn cho thử lại — trường nhập vẫn còn, chưa khoá màn.
      expect(find.byKey(const ValueKey('restore-password-field')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('restore-password-field')),
        'dung-123',
      );
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('restore-password-submit')));
        await Future<void>.delayed(const Duration(milliseconds: 700));
      });
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('restore-summary')), findsOneWidget);
    },
  );
}
