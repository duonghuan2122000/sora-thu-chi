import 'dart:async';
import 'dart:typed_data';

import 'package:sora_thu_chi/core/scan/receipt_ocr.dart';
import 'package:sora_thu_chi/core/scan/scan_result.dart';

/// Fake [ReceiptOcr] — trả [lines] dựng sẵn (mặc định rỗng = ảnh không đọc được).
/// [gate] giữ `readText` chờ → test widget quan sát được trạng thái "đang chạy".
class FakeScanOcr implements ReceiptOcr {
  FakeScanOcr([this.lines = const []]);

  List<ScanTextLine> lines;
  Completer<void>? gate;
  int readCount = 0;

  @override
  Future<List<ScanTextLine>> readText(Uint8List bytes) async {
    readCount++;
    if (gate != null) await gate!.future;
    return lines;
  }
}
