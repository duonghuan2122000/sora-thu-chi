import 'dart:convert';

import 'scan_log.dart';
import 'scan_log_image_store.dart';
import 'scan_log_store.dart';
import 'scan_result.dart';

/// Bộ đệm 1 phiên quét — tích lũy trong bộ nhớ suốt luồng chụp → xử lý → xác
/// nhận, ghi xuống [ScanLogStore] **một lần** lúc phiên kết thúc (research.md
/// Quyết định 1). [finish] tự chống gọi lặp — an toàn khi cả `PopScope` lẫn
/// nhánh lỗi cùng cố kết thúc phiên.
class ScanLogSession {
  ScanLogSession({
    required this._store,
    required this._imageStore,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ScanLogStore _store;
  final ScanLogImageStore _imageStore;
  final DateTime Function() _now;

  /// Ảnh tạm trong cache camera — set ngay khi có ảnh, trước khi OCR chạy.
  String? tempImagePath;
  String? rawText;
  String? _extractionJson;
  ScanEngine? _engine;
  final List<ScanLogEvent> _events = [];
  bool _finished = false;

  void addEvent(ScanLogEvent event) => _events.add(event);

  void setExtraction(ScanExtraction extraction) {
    _extractionJson = jsonEncode(extraction.toJson());
    _engine = extraction.engine;
  }

  /// Kết thúc phiên: copy ảnh (nếu có) vào kho riêng của nhật ký rồi ghi 1
  /// dòng. Gọi lần 2 trở đi là no-op.
  Future<void> finish({
    required ScanLogOutcome outcome,
    String? finalValuesJson,
    String? errorMessage,
  }) async {
    if (_finished) return;
    _finished = true;
    String? savedImagePath;
    final temp = tempImagePath;
    if (temp != null) {
      try {
        savedImagePath = await _imageStore.save(temp);
      } catch (_) {
        savedImagePath = null;
      }
    }
    await _store.append(
      ScanExtractionLog(
        createdAt: _now(),
        imagePath: savedImagePath,
        rawText: rawText,
        extractionJson: _extractionJson,
        engine: _engine,
        outcome: outcome,
        finalValuesJson: finalValuesJson,
        errorMessage: errorMessage,
        events: List.unmodifiable(_events),
      ),
    );
  }
}
