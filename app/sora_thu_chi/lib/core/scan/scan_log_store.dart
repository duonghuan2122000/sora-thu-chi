import 'scan_log.dart';

/// Seam lưu nhật ký trích xuất AI (PBI 47). Impl thật: `DriftScanLogStore`
/// (`data/scan_log_store_drift.dart`) — trần [kMaxScanLogs] cưỡng chế ngay
/// trong [append] (FR-011), cùng kỹ thuật `NotificationHistoryStore`.
abstract class ScanLogStore {
  /// Ghi 1 bản ghi (phiên quét đã kết thúc) rồi cắt bớt nếu vượt trần.
  Future<void> append(ScanExtractionLog log);

  /// Mới nhất trước (FR-007).
  Future<List<ScanExtractionLog>> loadAll();

  Future<void> deleteOne(int id);

  Future<void> deleteAll();
}
