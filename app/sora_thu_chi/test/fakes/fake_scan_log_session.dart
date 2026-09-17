import 'package:sora_thu_chi/core/scan/scan_log.dart';
import 'package:sora_thu_chi/core/scan/scan_log_image_store.dart';
import 'package:sora_thu_chi/core/scan/scan_log_session.dart';
import 'package:sora_thu_chi/core/scan/scan_log_store.dart';

/// Fake [ScanLogStore] — ghi vào bộ nhớ, cho test đọc lại bản ghi đã `append`.
class FakeScanLogStore implements ScanLogStore {
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

/// Fake [ScanLogImageStore] — không đụng file system thật.
class FakeScanLogImageStore implements ScanLogImageStore {
  @override
  Future<String> save(String tempPath) async => '$tempPath.saved';

  @override
  Future<void> delete(String path) async {}
}

/// Dựng [ScanLogSession] cho test màn quét — [store] mặc định fake mới, cho
/// test truyền vào để đọc lại bản ghi đã ghi (assert instrumentation).
ScanLogSession fakeScanLogSession({FakeScanLogStore? store}) => ScanLogSession(
  store: store ?? FakeScanLogStore(),
  imageStore: FakeScanLogImageStore(),
);
