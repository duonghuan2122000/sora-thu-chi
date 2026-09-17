import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/scan/scan_log.dart';
import 'package:sora_thu_chi/core/scan/scan_log_image_store.dart';
import 'package:sora_thu_chi/data/db/app_database.dart';
import 'package:sora_thu_chi/data/scan_log_store_drift.dart';

const _skip = 'Host thiếu sqlite native — bỏ qua DAO drift tích hợp.';

Future<AppDatabase?> _tryMemoryDb() async {
  try {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    return db;
  } catch (_) {
    return null;
  }
}

/// Fake không đụng file system thật — chỉ đếm/ghi nhớ path đã xóa.
class _FakeScanLogImageStore implements ScanLogImageStore {
  final List<String> deleted = [];

  @override
  Future<String> save(String tempPath) async => tempPath;

  @override
  Future<void> delete(String path) async => deleted.add(path);
}

ScanExtractionLog _log({
  required DateTime createdAt,
  String? imagePath,
  ScanLogOutcome outcome = ScanLogOutcome.saved,
  String? finalValuesJson = '{"amount":1000}',
  String? errorMessage,
}) => ScanExtractionLog(
  createdAt: createdAt,
  imagePath: imagePath,
  rawText: 'ABC',
  outcome: outcome,
  finalValuesJson: outcome == ScanLogOutcome.saved ? finalValuesJson : null,
  errorMessage: outcome == ScanLogOutcome.error ? (errorMessage ?? 'lỗi') : null,
);

void main() {
  test('schema v11 (PBI 47 thêm bảng scan_extraction_logs)', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    expect(db.schemaVersion, 11);
  });

  test('bảng rỗng → loadAll trả []', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    final store = DriftScanLogStore(db, imageStore: _FakeScanLogImageStore());
    expect(await store.loadAll(), isEmpty);
  });

  test('append 3 dòng → loadAll mới nhất trước', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    final store = DriftScanLogStore(db, imageStore: _FakeScanLogImageStore());
    await store.append(_log(createdAt: DateTime(2026, 9, 1)));
    await store.append(_log(createdAt: DateTime(2026, 9, 5)));
    await store.append(_log(createdAt: DateTime(2026, 9, 10)));

    final items = await store.loadAll();
    expect(
      items.map((l) => l.createdAt),
      [DateTime(2026, 9, 10), DateTime(2026, 9, 5), DateTime(2026, 9, 1)],
    );
  });

  test('luật hợp lệ: saved có finalValuesJson, error có errorMessage', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    final store = DriftScanLogStore(db, imageStore: _FakeScanLogImageStore());
    await store.append(_log(createdAt: DateTime(2026, 9, 1), outcome: ScanLogOutcome.saved));
    await store.append(_log(createdAt: DateTime(2026, 9, 2), outcome: ScanLogOutcome.cancelled));
    await store.append(_log(createdAt: DateTime(2026, 9, 3), outcome: ScanLogOutcome.error));

    final items = await store.loadAll();
    final saved = items.firstWhere((l) => l.outcome == ScanLogOutcome.saved);
    final cancelled = items.firstWhere((l) => l.outcome == ScanLogOutcome.cancelled);
    final error = items.firstWhere((l) => l.outcome == ScanLogOutcome.error);
    expect(saved.finalValuesJson, isNotNull);
    expect(cancelled.finalValuesJson, isNull);
    expect(error.errorMessage, isNotNull);
  });

  test('trần 200: append 205 dòng → giữ đúng 200 MỚI NHẤT, dọn ảnh dòng cũ', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    final images = _FakeScanLogImageStore();
    final store = DriftScanLogStore(db, imageStore: images);
    for (var i = 1; i <= 205; i++) {
      await store.append(
        _log(
          createdAt: DateTime(2026, 9, 1).add(Duration(minutes: i)),
          imagePath: '/tmp/img_$i.jpg',
        ),
      );
    }

    final items = await store.loadAll();
    expect(items, hasLength(kMaxScanLogs));
    expect(items.first.rawText, 'ABC');
    // 5 dòng cũ nhất (1..5) bị trim ⇒ ảnh của chúng bị xóa.
    expect(images.deleted, containsAll(['/tmp/img_1.jpg', '/tmp/img_5.jpg']));
    expect(images.deleted, isNot(contains('/tmp/img_6.jpg')));
  });

  test('deleteOne: xóa đúng 1 dòng + xóa file ảnh', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    final images = _FakeScanLogImageStore();
    final store = DriftScanLogStore(db, imageStore: images);
    await store.append(_log(createdAt: DateTime(2026, 9, 1), imagePath: '/tmp/a.jpg'));
    await store.append(_log(createdAt: DateTime(2026, 9, 2), imagePath: '/tmp/b.jpg'));
    final target = (await store.loadAll()).firstWhere((l) => l.imagePath == '/tmp/a.jpg');

    await store.deleteOne(target.id);

    final remaining = await store.loadAll();
    expect(remaining, hasLength(1));
    expect(remaining.single.imagePath, '/tmp/b.jpg');
    expect(images.deleted, ['/tmp/a.jpg']);
  });

  test('deleteAll: xóa hết dòng + hết file ảnh', () async {
    final db = await _tryMemoryDb();
    if (db == null) {
      markTestSkipped(_skip);
      return;
    }
    addTearDown(db.close);

    final images = _FakeScanLogImageStore();
    final store = DriftScanLogStore(db, imageStore: images);
    await store.append(_log(createdAt: DateTime(2026, 9, 1), imagePath: '/tmp/a.jpg'));
    await store.append(_log(createdAt: DateTime(2026, 9, 2), imagePath: '/tmp/b.jpg'));
    await store.append(_log(createdAt: DateTime(2026, 9, 3)));

    await store.deleteAll();

    expect(await store.loadAll(), isEmpty);
    expect(images.deleted, containsAll(['/tmp/a.jpg', '/tmp/b.jpg']));
  });
}
