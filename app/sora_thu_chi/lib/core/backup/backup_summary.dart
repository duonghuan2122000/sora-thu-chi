import 'package:flutter/foundation.dart';

import 'backup_data.dart';

/// Số liệu tóm tắt hiện trên bottom sheet "Tạo bản sao lưu" (T021) — đếm thẳng
/// từ [BackupData] đã có trong bộ nhớ, **không** cần build file thật trước.
@immutable
class BackupSummary {
  const BackupSummary({required this.counts, required this.estimatedSizeBytes});

  final Map<String, int> counts;

  /// Ước tính thô theo số bản ghi (không phải dung lượng file thật sau khi
  /// build) — đủ để người dùng hình dung trước khi bấm "Tạo & Chia sẻ".
  final int estimatedSizeBytes;

  /// ~200 byte JSON mỗi bản ghi (id + vài trường ngắn) — số tròn, đủ dùng cho
  /// một ước tính hiển thị, không cần chính xác tuyệt đối.
  static const int _bytesPerRecord = 200;

  factory BackupSummary.fromData(BackupData data) {
    final counts = data.counts;
    final totalRecords = counts.values.fold(0, (sum, n) => sum + n);
    return BackupSummary(
      counts: counts,
      estimatedSizeBytes: totalRecords * _bytesPerRecord,
    );
  }
}
