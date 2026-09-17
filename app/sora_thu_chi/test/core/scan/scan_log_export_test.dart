import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/scan/scan_log.dart';
import 'package:sora_thu_chi/core/scan/scan_log_export.dart';

import '../../fakes/fake_scan_log_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exportScanLogs ghi đúng số bản ghi + gọi share với file JSON hợp lệ', () async {
    final store = FakeScanLogStore()
      ..appended.addAll([
        ScanExtractionLog(
          createdAt: DateTime(2026, 9, 1),
          outcome: ScanLogOutcome.saved,
          extractionJson: '{"amount":1000}',
          finalValuesJson: '{"amount":1500}',
        ),
        ScanExtractionLog(createdAt: DateTime(2026, 9, 2), outcome: ScanLogOutcome.cancelled),
      ]);

    String? sharedPath;
    await exportScanLogs(
      store,
      share: (path) async => sharedPath = path,
      tempDir: () async => Directory.systemTemp,
    );

    expect(sharedPath, isNotNull);
    final file = File(sharedPath!);
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });
    expect(file.existsSync(), isTrue);

    final decoded = jsonDecode(await file.readAsString()) as List;
    expect(decoded, hasLength(2));
    expect(decoded[0]['outcome'], 'saved');
    expect(decoded[0]['finalValues'], {'amount': 1500});
    expect(decoded[1]['outcome'], 'cancelled');
  });
}
