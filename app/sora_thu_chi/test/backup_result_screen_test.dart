import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/screens/backup_result_screen.dart';

void main() {
  testWidgets('mode backup → hiện nút "Chia sẻ lại file"', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BackupResultScreen(
          mode: BackupResultMode.backup,
          filePath: '/fake/path/thuchi_backup.json',
        ),
      ),
    );

    expect(find.byKey(const ValueKey('backup-result-share-again')), findsOneWidget);
    expect(find.text('Xong'), findsOneWidget);
  });

  testWidgets('mode backup không có filePath → không hiện nút chia sẻ lại', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: BackupResultScreen(mode: BackupResultMode.backup)),
    );

    expect(find.byKey(const ValueKey('backup-result-share-again')), findsNothing);
  });

  testWidgets('mode restore → chạm nút chính điều hướng về Tổng quan', (
    tester,
  ) async {
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        home: BackupResultScreen(
          mode: BackupResultMode.restore,
          onDone: () => done = true,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('backup-result-share-again')), findsNothing);
    expect(find.text('Về Tổng quan'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('backup-result-done')));
    await tester.pumpAndSettle();

    expect(done, isTrue);
  });
}
