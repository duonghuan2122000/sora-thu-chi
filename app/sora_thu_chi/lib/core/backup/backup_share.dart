import 'package:share_plus/share_plus.dart';

/// Seam chia sẻ file backup (khuôn `ShareExport`, report_export) — test bơm
/// bản giả, không đụng bảng chia sẻ hệ thống thật trong `flutter test`.
typedef ShareBackupFile = Future<void> Function(String path);

/// Implementation mặc định của [ShareBackupFile] — dùng chung cho màn kết quả
/// tạo backup (PBI 35) và danh sách bản sao lưu cũ (PBI 43).
Future<void> defaultShareBackupFile(String path) =>
    SharePlus.instance.share(ShareParams(files: [XFile(path)]));
