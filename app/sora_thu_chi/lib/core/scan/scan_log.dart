import 'dart:convert';

import 'scan_result.dart';

/// Trần bản ghi nhật ký trích xuất AI (FR-011, spec PBI 47) — cưỡng chế ở tầng
/// ghi (`ScanLogStore.append`), cùng kỹ thuật [kMaxNotifications].
const int kMaxScanLogs = 200;

/// Kết thúc của một phiên quét (data-model.md §ScanExtractionLogs).
enum ScanLogOutcome { saved, cancelled, error }

/// Một thao tác trong phiên quét, đúng thứ tự thời gian (FR-004).
enum ScanLogEventType { edit, back, save }

/// Một sự kiện thao tác của người dùng trong phiên quét.
class ScanLogEvent {
  const ScanLogEvent({
    required this.type,
    this.field,
    this.fromValue,
    this.toValue,
    required this.atMillis,
  });

  final ScanLogEventType type;

  /// Tên trường bị sửa (`type`/`amount`/`date`/`category`/`merchant`); null khi
  /// `type != edit`.
  final String? field;
  final String? fromValue;
  final String? toValue;
  final int atMillis;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'field': field,
    'fromValue': fromValue,
    'toValue': toValue,
    'atMillis': atMillis,
  };

  factory ScanLogEvent.fromJson(Map<String, dynamic> json) => ScanLogEvent(
    type: ScanLogEventType.values.byName(json['type'] as String),
    field: json['field'] as String?,
    fromValue: json['fromValue'] as String?,
    toValue: json['toValue'] as String?,
    atMillis: json['atMillis'] as int,
  );
}

/// Một dòng `scan_extraction_logs` (data-model.md) — bản ghi hoàn chỉnh của 1
/// phiên quét hóa đơn AI, ghi **một lần** lúc phiên kết thúc.
class ScanExtractionLog {
  const ScanExtractionLog({
    this.id = 0,
    required this.createdAt,
    this.imagePath,
    this.rawText,
    this.extractionJson,
    this.engine,
    required this.outcome,
    this.finalValuesJson,
    this.errorMessage,
    this.events = const [],
  });

  final int id;
  final DateTime createdAt;
  final String? imagePath;
  final String? rawText;

  /// `ScanExtraction.toJson()` đã encode — kết quả AI đề xuất ban đầu.
  final String? extractionJson;
  final ScanEngine? engine;
  final ScanLogOutcome outcome;

  /// Giá trị cuối người dùng lưu (JSON) — chỉ có khi `outcome = saved`.
  final String? finalValuesJson;

  /// Chỉ có khi `outcome = error`.
  final String? errorMessage;
  final List<ScanLogEvent> events;

  String get eventsJson => jsonEncode(events.map((e) => e.toJson()).toList());

  static List<ScanLogEvent> decodeEvents(String eventsJson) {
    final raw = jsonDecode(eventsJson) as List;
    return raw
        .map((e) => ScanLogEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Dùng khi xuất file (FR-010) — mảng đủ field, giá trị lồng đã decode lại
  /// thành object thay vì chuỗi JSON kép.
  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'imagePath': imagePath,
    'rawText': rawText,
    'extraction': extractionJson == null ? null : jsonDecode(extractionJson!),
    'engine': engine?.name,
    'outcome': outcome.name,
    'finalValues': finalValuesJson == null
        ? null
        : jsonDecode(finalValuesJson!),
    'errorMessage': errorMessage,
    'events': events.map((e) => e.toJson()).toList(),
  };
}
