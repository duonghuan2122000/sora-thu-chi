import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/scan/scan_log.dart';
import 'package:sora_thu_chi/screens/scan_log_detail_screen.dart';
import 'package:sora_thu_chi/screens/scan_log_list_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import '../fakes/fake_scan_log_session.dart';

ScanExtractionLog _log({
  required int id,
  required DateTime createdAt,
  ScanLogOutcome outcome = ScanLogOutcome.saved,
}) => ScanExtractionLog(
  id: id,
  createdAt: createdAt,
  outcome: outcome,
  finalValuesJson: outcome == ScanLogOutcome.saved ? '{"amount":1000}' : null,
);

Future<void> _pump(WidgetTester tester, FakeScanLogStore store) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: ScanLogListScreen(store: store, share: (_) async {}),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Bảng rỗng → trạng thái rỗng, ẩn nút xuất/xóa tất cả', (tester) async {
    await _pump(tester, FakeScanLogStore());

    expect(find.byKey(const ValueKey('scan-log-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-log-export')), findsNothing);
    expect(find.byKey(const ValueKey('scan-log-delete-all')), findsNothing);
  });

  testWidgets('Có dữ liệu → hiện danh sách mới nhất trước', (tester) async {
    final store = FakeScanLogStore()
      ..appended.addAll([
        _log(id: 1, createdAt: DateTime(2026, 9, 1)),
        _log(id: 2, createdAt: DateTime(2026, 9, 10)),
      ]);
    await _pump(tester, store);

    expect(find.byKey(const ValueKey('scan-log-empty')), findsNothing);
    expect(find.byKey(const ValueKey('scan-log-row-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-log-row-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-log-export')), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-log-delete-all')), findsOneWidget);
  });

  testWidgets('Chạm 1 dòng → mở màn chi tiết', (tester) async {
    final store = FakeScanLogStore()
      ..appended.add(_log(id: 5, createdAt: DateTime(2026, 9, 1)));
    await _pump(tester, store);

    await tester.tap(find.byKey(const ValueKey('scan-log-row-5')));
    await tester.pumpAndSettle();

    expect(find.byType(ScanLogDetailScreen), findsOneWidget);
  });
}
