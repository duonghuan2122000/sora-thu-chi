/// Seam chia sẻ file backup (khuôn `ShareExport`, report_export) — test bơm
/// bản giả, không đụng bảng chia sẻ hệ thống thật trong `flutter test`.
typedef ShareBackupFile = Future<void> Function(String path);
