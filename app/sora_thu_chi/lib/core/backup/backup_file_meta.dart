import 'package:flutter/foundation.dart';

/// Phiên bản schema hiện tại của file backup (data-model.md §2). Tăng khi đổi
/// cấu trúc `data`; [migrateBackupSchema] (backup_schema_migration.dart) nâng
/// file cũ hơn lên phiên bản này trước khi đọc.
const int kBackupSchemaVersion = 1;

/// Thông tin tóm tắt đọc trực tiếp từ khối `meta` của file backup — không cần
/// giải mã/parse toàn bộ `data` để hiển thị (data-model.md §2).
@immutable
class BackupFileMeta {
  const BackupFileMeta({
    required this.schemaVersion,
    required this.appVersion,
    required this.exportedAt,
    required this.currencyDefault,
    required this.counts,
    required this.hasAttachments,
    required this.checksum,
    required this.hasPassword,
  });

  final int schemaVersion;
  final String appVersion;
  final DateTime exportedAt;
  final String currencyDefault;
  final Map<String, int> counts;
  final bool hasAttachments;
  final String checksum;
  final bool hasPassword;

  /// File từ phiên bản app **tương lai** (schema cao hơn phiên bản đang hỗ trợ)
  /// → không tương thích, chặn khôi phục (spec §4.3/kịch bản 7).
  bool isSchemaSupported(int currentSupported) =>
      schemaVersion <= currentSupported;

  Map<String, Object?> toJson() => {
    'schema_version': schemaVersion,
    'app_version': appVersion,
    'exported_at': exportedAt.toIso8601String(),
    'currency_default': currencyDefault,
    'counts': counts,
    'has_attachments': hasAttachments,
    'checksum': checksum,
    'has_password': hasPassword,
  };

  /// Ném [FormatException] khi thiếu trường bắt buộc/sai kiểu — khác
  /// [BackupPrefs.fromSettings] (tolerant): đây là file ngoài app, đọc phải
  /// biết rõ hỏng ở đâu để [BackupReader] báo lỗi rõ ràng (FR-012).
  factory BackupFileMeta.fromJson(Map<String, Object?> json) {
    final schemaVersion = json['schema_version'];
    final appVersion = json['app_version'];
    final exportedAtRaw = json['exported_at'];
    final currencyDefault = json['currency_default'];
    final countsRaw = json['counts'];
    final hasAttachments = json['has_attachments'];
    final checksum = json['checksum'];
    final hasPassword = json['has_password'];
    if (schemaVersion is! int ||
        appVersion is! String ||
        exportedAtRaw is! String ||
        currencyDefault is! String ||
        countsRaw is! Map ||
        hasAttachments is! bool ||
        checksum is! String ||
        hasPassword is! bool) {
      throw const FormatException('Thiếu hoặc sai kiểu trường trong meta');
    }
    final exportedAt = DateTime.tryParse(exportedAtRaw);
    if (exportedAt == null) {
      throw const FormatException('exported_at không hợp lệ');
    }
    final counts = <String, int>{};
    for (final entry in countsRaw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is String && value is int) counts[key] = value;
    }
    return BackupFileMeta(
      schemaVersion: schemaVersion,
      appVersion: appVersion,
      exportedAt: exportedAt,
      currencyDefault: currencyDefault,
      counts: counts,
      hasAttachments: hasAttachments,
      checksum: checksum,
      hasPassword: hasPassword,
    );
  }
}
