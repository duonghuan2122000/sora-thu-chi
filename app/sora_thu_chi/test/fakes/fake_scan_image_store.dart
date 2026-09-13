import 'dart:typed_data';

import 'package:sora_thu_chi/core/scan/scan_image_store.dart';

/// Fake [ScanImageStore] — ghi vào bộ nhớ, đếm số lần lưu/xoá để assert
/// "huỷ giữa luồng không để lại file" (FR-036).
class FakeScanImageStore implements ScanImageStore {
  final List<Uint8List> saved = [];
  final List<String> deleted = [];

  @override
  Future<String> save(Uint8List bytes) async {
    saved.add(bytes);
    return '/fake/receipts/${saved.length}.jpg';
  }

  @override
  Future<void> delete(String path) async {
    deleted.add(path);
  }
}
