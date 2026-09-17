import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/scan/scan_log.dart';

void main() {
  test('ScanLogEvent round-trip toJson/fromJson', () {
    const event = ScanLogEvent(
      type: ScanLogEventType.edit,
      field: 'amount',
      fromValue: '10000',
      toValue: '20000',
      atMillis: 123456,
    );
    final decoded = ScanLogEvent.fromJson(event.toJson());
    expect(decoded.type, event.type);
    expect(decoded.field, event.field);
    expect(decoded.fromValue, event.fromValue);
    expect(decoded.toValue, event.toValue);
    expect(decoded.atMillis, event.atMillis);
  });

  test('ScanExtractionLog.eventsJson + decodeEvents round-trip, giữ thứ tự', () {
    final log = ScanExtractionLog(
      createdAt: DateTime(2026, 9, 1),
      outcome: ScanLogOutcome.saved,
      events: const [
        ScanLogEvent(type: ScanLogEventType.edit, field: 'amount', atMillis: 1),
        ScanLogEvent(type: ScanLogEventType.edit, field: 'category', atMillis: 2),
        ScanLogEvent(type: ScanLogEventType.save, atMillis: 3),
      ],
    );
    final decoded = ScanExtractionLog.decodeEvents(log.eventsJson);
    expect(decoded.map((e) => e.field), ['amount', 'category', null]);
    expect(decoded.map((e) => e.atMillis), [1, 2, 3]);
  });

  test('toJson() decode lồng extraction/finalValues thành object, không chuỗi kép', () {
    final log = ScanExtractionLog(
      createdAt: DateTime(2026, 9, 1),
      extractionJson: '{"amount":1000}',
      outcome: ScanLogOutcome.saved,
      finalValuesJson: '{"amount":2000}',
    );
    final json = log.toJson();
    expect(json['extraction'], {'amount': 1000});
    expect(json['finalValues'], {'amount': 2000});
    expect(json['outcome'], 'saved');
  });

  test('outcome error: extraction/finalValues có thể null', () {
    final log = ScanExtractionLog(
      createdAt: DateTime(2026, 9, 1),
      outcome: ScanLogOutcome.error,
      errorMessage: 'Không đọc được ảnh',
    );
    expect(log.toJson()['extraction'], isNull);
    expect(log.toJson()['finalValues'], isNull);
    expect(log.toJson()['errorMessage'], 'Không đọc được ảnh');
  });
}
