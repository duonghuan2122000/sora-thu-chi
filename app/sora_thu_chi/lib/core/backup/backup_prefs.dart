import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Khóa row cấu hình sao lưu trong bảng key-value `AppSettings` (schema giữ v10).
const String kKeyBackupPrefs = 'backupPrefs';

/// Tần suất tự động sao lưu (PBI 35, FR-006).
enum BackupFrequency { daily, weekly, monthly }

/// Cấu hình "Sao lưu & Khôi phục" (data-model.md §1) — gói trong **1 row JSON**
/// `backupPrefs` của `AppSettings`, theo khuôn `NotificationPrefs`. [maxKeepLocal]
/// là hằng số nghiệp vụ (không có công tắc nào cho người dùng đổi) nhưng vẫn nằm
/// trong khối này để không cần seam riêng chỉ vì 1 con số.
@immutable
class BackupPrefs {
  const BackupPrefs({
    this.autoEnabled = false,
    this.autoFrequency = BackupFrequency.weekly,
    this.maxKeepLocal = 5,
    this.lastBackupAt,
    this.lastBackupCounts,
    this.lastBackupSizeBytes,
  });

  static const BackupPrefs defaults = BackupPrefs();

  final bool autoEnabled;
  final BackupFrequency autoFrequency;
  final int maxKeepLocal;
  final DateTime? lastBackupAt;
  final Map<String, int>? lastBackupCounts;
  final int? lastBackupSizeBytes;

  Map<String, Object?> toJson() => {
    'autoEnabled': autoEnabled,
    'autoFrequency': autoFrequency.name,
    'maxKeepLocal': maxKeepLocal,
    'lastBackupAt': lastBackupAt?.toIso8601String(),
    'lastBackupCounts': lastBackupCounts,
    'lastBackupSizeBytes': lastBackupSizeBytes,
  };

  Map<String, String> toSettings() => {kKeyBackupPrefs: jsonEncode(toJson())};

  /// Row vắng / JSON hỏng → cả bộ mặc định; từng trường sai kiểu/ngoài miền →
  /// mặc định của riêng trường đó (không bao giờ ném — nếp PBI 24/28/29).
  factory BackupPrefs.fromSettings(Map<String, String> rows) {
    final raw = rows[kKeyBackupPrefs];
    if (raw == null) return defaults;
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return defaults;
    }
    if (decoded is! Map) return defaults;
    return BackupPrefs(
      autoEnabled: _bool(decoded['autoEnabled'], false),
      autoFrequency: _frequency(decoded['autoFrequency']),
      maxKeepLocal: _positiveInt(decoded['maxKeepLocal'], 5),
      lastBackupAt: _dateTime(decoded['lastBackupAt']),
      lastBackupCounts: _counts(decoded['lastBackupCounts']),
      lastBackupSizeBytes: _nullableNonNegativeInt(
        decoded['lastBackupSizeBytes'],
      ),
    );
  }

  static bool _bool(Object? raw, bool fallback) =>
      raw is bool ? raw : fallback;

  static BackupFrequency _frequency(Object? raw) {
    if (raw is! String) return BackupFrequency.weekly;
    for (final f in BackupFrequency.values) {
      if (f.name == raw) return f;
    }
    return BackupFrequency.weekly;
  }

  static int _positiveInt(Object? raw, int fallback) =>
      raw is int && raw > 0 ? raw : fallback;

  static int? _nullableNonNegativeInt(Object? raw) =>
      raw is int && raw >= 0 ? raw : null;

  static DateTime? _dateTime(Object? raw) {
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  static Map<String, int>? _counts(Object? raw) {
    if (raw is! Map) return null;
    final out = <String, int>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is String && value is int) out[key] = value;
    }
    return out.isEmpty ? null : out;
  }

  BackupPrefs copyWith({
    bool? autoEnabled,
    BackupFrequency? autoFrequency,
    int? maxKeepLocal,
    DateTime? lastBackupAt,
    Map<String, int>? lastBackupCounts,
    int? lastBackupSizeBytes,
  }) => BackupPrefs(
    autoEnabled: autoEnabled ?? this.autoEnabled,
    autoFrequency: autoFrequency ?? this.autoFrequency,
    maxKeepLocal: maxKeepLocal ?? this.maxKeepLocal,
    lastBackupAt: lastBackupAt ?? this.lastBackupAt,
    lastBackupCounts: lastBackupCounts ?? this.lastBackupCounts,
    lastBackupSizeBytes: lastBackupSizeBytes ?? this.lastBackupSizeBytes,
  );

  @override
  bool operator ==(Object other) =>
      other is BackupPrefs &&
      other.autoEnabled == autoEnabled &&
      other.autoFrequency == autoFrequency &&
      other.maxKeepLocal == maxKeepLocal &&
      other.lastBackupAt == lastBackupAt &&
      mapEquals(other.lastBackupCounts, lastBackupCounts) &&
      other.lastBackupSizeBytes == lastBackupSizeBytes;

  @override
  int get hashCode => Object.hash(
    autoEnabled,
    autoFrequency,
    maxKeepLocal,
    lastBackupAt,
    lastBackupCounts == null
        ? null
        : Object.hashAllUnordered(
            lastBackupCounts!.entries.map((e) => Object.hash(e.key, e.value)),
          ),
    lastBackupSizeBytes,
  );
}
