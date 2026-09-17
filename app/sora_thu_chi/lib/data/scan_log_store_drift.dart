import 'package:drift/drift.dart';

import '../core/scan/scan_log.dart';
import '../core/scan/scan_log_image_store.dart';
import '../core/scan/scan_log_store.dart';
import 'db/app_database.dart';

/// Impl thật (drift) của [ScanLogStore] — map bảng `ScanExtractionLogs` ↔
/// [ScanExtractionLog]. Trần [kMaxScanLogs] cưỡng chế **ngay trong [append]**
/// (cùng kỹ thuật `DriftNotificationHistoryStore`), kèm dọn file ảnh của các
/// dòng bị trim/xóa (research.md Quyết định 2 — notification không có file
/// kèm nên không cần bước này).
class DriftScanLogStore implements ScanLogStore {
  DriftScanLogStore(this._db, {ScanLogImageStore? imageStore})
    : _imageStore = imageStore ?? LocalScanLogImageStore();

  final AppDatabase _db;
  final ScanLogImageStore _imageStore;

  @override
  Future<void> append(ScanExtractionLog log) async {
    await _db
        .into(_db.scanExtractionLogs)
        .insert(
          ScanExtractionLogsCompanion.insert(
            createdAt: log.createdAt,
            imagePath: Value(log.imagePath),
            rawText: Value(log.rawText),
            extractionJson: Value(log.extractionJson),
            engine: Value(log.engine),
            outcome: log.outcome,
            finalValuesJson: Value(log.finalValuesJson),
            errorMessage: Value(log.errorMessage),
            eventsJson: Value(log.eventsJson),
          ),
        );
    await _trimToLimit();
  }

  @override
  Future<List<ScanExtractionLog>> loadAll() async {
    final rows =
        await (_db.select(_db.scanExtractionLogs)..orderBy([
              (r) => OrderingTerm.desc(r.createdAt),
              (r) => OrderingTerm.desc(r.id),
            ]))
            .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> deleteOne(int id) async {
    final row = await (_db.select(
      _db.scanExtractionLogs,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    final path = row?.imagePath;
    if (path != null) await _imageStore.delete(path);
    await (_db.delete(
      _db.scanExtractionLogs,
    )..where((r) => r.id.equals(id))).go();
  }

  @override
  Future<void> deleteAll() async {
    final rows = await _db.select(_db.scanExtractionLogs).get();
    for (final row in rows) {
      final path = row.imagePath;
      if (path != null) await _imageStore.delete(path);
    }
    await _db.delete(_db.scanExtractionLogs).go();
  }

  /// Xoá mọi dòng **ngoài top-[kMaxScanLogs]** theo `(createdAt DESC, id
  /// DESC)`, kèm xoá file ảnh của các dòng bị trim.
  Future<void> _trimToLimit() async {
    final keep =
        await (_db.selectOnly(_db.scanExtractionLogs)
              ..addColumns([_db.scanExtractionLogs.id])
              ..orderBy([
                OrderingTerm.desc(_db.scanExtractionLogs.createdAt),
                OrderingTerm.desc(_db.scanExtractionLogs.id),
              ])
              ..limit(kMaxScanLogs))
            .map((r) => r.read(_db.scanExtractionLogs.id)!)
            .get();
    if (keep.isEmpty) return;
    final overflow = await (_db.select(
      _db.scanExtractionLogs,
    )..where((r) => r.id.isNotIn(keep))).get();
    if (overflow.isEmpty) return;
    for (final row in overflow) {
      final path = row.imagePath;
      if (path != null) await _imageStore.delete(path);
    }
    await (_db.delete(
      _db.scanExtractionLogs,
    )..where((r) => r.id.isNotIn(keep))).go();
  }

  ScanExtractionLog _toDomain(ScanExtractionLogsRow row) => ScanExtractionLog(
    id: row.id,
    createdAt: row.createdAt,
    imagePath: row.imagePath,
    rawText: row.rawText,
    extractionJson: row.extractionJson,
    engine: row.engine,
    outcome: row.outcome,
    finalValuesJson: row.finalValuesJson,
    errorMessage: row.errorMessage,
    events: ScanExtractionLog.decodeEvents(row.eventsJson),
  );
}
