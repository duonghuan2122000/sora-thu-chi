import 'backup_file_meta.dart';

/// Nâng cấp `data` của file backup cũ lên [kBackupSchemaVersion] hiện tại
/// (research R8). Hiện chỉ có **1** phiên bản (v1) nên đây là khung rỗng — trả
/// nguyên trạng khi [from] đã là phiên bản hiện tại; sẵn chỗ mở rộng `switch`
/// khi có phiên bản backup mới thật sự đổi cấu trúc `data`.
Map<String, Object?> migrateBackupSchema(int from, Map<String, Object?> json) {
  switch (from) {
    case kBackupSchemaVersion:
      return json;
    default:
      return json;
  }
}
