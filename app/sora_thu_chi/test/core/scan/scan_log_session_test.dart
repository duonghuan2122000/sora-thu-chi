import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/scan/scan_log.dart';
import 'package:sora_thu_chi/core/scan/scan_log_image_store.dart';
import 'package:sora_thu_chi/core/scan/scan_log_session.dart';
import 'package:sora_thu_chi/core/scan/scan_log_store.dart';
import 'package:sora_thu_chi/core/scan/scan_result.dart';

class _FakeStore implements ScanLogStore {
  final List<ScanExtractionLog> appended = [];

  @override
  Future<void> append(ScanExtractionLog log) async => appended.add(log);

  @override
  Future<void> deleteAll() async {}

  @override
  Future<void> deleteOne(int id) async {}

  @override
  Future<List<ScanExtractionLog>> loadAll() async => appended;
}

class _FakeImageStore implements ScanLogImageStore {
  int saveCalls = 0;

  @override
  Future<String> save(String tempPath) async {
    saveCalls++;
    return '$tempPath.saved';
  }

  @override
  Future<void> delete(String path) async {}
}

void main() {
  test('finish(saved) ghi đúng 1 dòng có finalValuesJson + copy ảnh', () async {
    final store = _FakeStore();
    final images = _FakeImageStore();
    final session = ScanLogSession(
      store: store,
      imageStore: images,
      now: () => DateTime(2026, 9, 1),
    );
    session.tempImagePath = '/cache/receipt.jpg';
    session.addEvent(
      const ScanLogEvent(
        type: ScanLogEventType.edit,
        field: 'amount',
        fromValue: '1000',
        toValue: '2000',
        atMillis: 1,
      ),
    );

    await session.finish(outcome: ScanLogOutcome.saved, finalValuesJson: '{"amount":2000}');

    expect(store.appended, hasLength(1));
    final log = store.appended.single;
    expect(log.outcome, ScanLogOutcome.saved);
    expect(log.finalValuesJson, '{"amount":2000}');
    expect(log.imagePath, '/cache/receipt.jpg.saved');
    expect(images.saveCalls, 1);
    expect(log.events, hasLength(1));
  });

  test('finish(cancelled) không có finalValuesJson', () async {
    final store = _FakeStore();
    final session = ScanLogSession(store: store, imageStore: _FakeImageStore());

    await session.finish(outcome: ScanLogOutcome.cancelled);

    expect(store.appended.single.finalValuesJson, isNull);
  });

  test('gọi finish() lần 2 là no-op (idempotent)', () async {
    final store = _FakeStore();
    final session = ScanLogSession(store: store, imageStore: _FakeImageStore());

    await session.finish(outcome: ScanLogOutcome.error, errorMessage: 'lỗi 1');
    await session.finish(outcome: ScanLogOutcome.saved, finalValuesJson: '{}');

    expect(store.appended, hasLength(1));
    expect(store.appended.single.outcome, ScanLogOutcome.error);
  });

  test('setExtraction gán extractionJson + engine trước khi finish', () async {
    final store = _FakeStore();
    final session = ScanLogSession(store: store, imageStore: _FakeImageStore());
    session.setExtraction(const ScanExtraction(engine: ScanEngine.geminiNano));

    await session.finish(outcome: ScanLogOutcome.cancelled);

    final log = store.appended.single;
    expect(log.engine, ScanEngine.geminiNano);
    expect(log.extractionJson, isNotNull);
  });

  test('nhiều sự kiện edit liên tiếp giữ đúng thứ tự thời gian', () async {
    final store = _FakeStore();
    final session = ScanLogSession(store: store, imageStore: _FakeImageStore());
    session.addEvent(
      const ScanLogEvent(type: ScanLogEventType.edit, field: 'amount', atMillis: 1),
    );
    session.addEvent(
      const ScanLogEvent(type: ScanLogEventType.edit, field: 'amount', atMillis: 2),
    );
    session.addEvent(
      const ScanLogEvent(type: ScanLogEventType.edit, field: 'category', atMillis: 3),
    );

    await session.finish(outcome: ScanLogOutcome.cancelled);

    expect(store.appended.single.events.map((e) => e.atMillis), [1, 2, 3]);
  });
}
