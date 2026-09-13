import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

import 'scan_result.dart';

/// Seam OCR — màn xử lý chỉ phụ thuộc interface này để test bơm fake (không cần
/// ML Kit/sqlite). Impl thật: [MlKitReceiptOcr]. Giữ **mỏng nhất có thể**: chỉ
/// trả văn bản thô + vùng chuẩn hoá, mọi luật nằm ở `receipt_parser` (R7).
abstract class ReceiptOcr {
  /// Đọc chữ trong ảnh [bytes]; trả danh sách dòng kèm vùng chuẩn hoá 0..1.
  /// Ảnh không có chữ → danh sách rỗng (không ném).
  Future<List<ScanTextLine>> readText(Uint8List bytes);
}

/// Impl thật: ML Kit Text Recognition bản **bundled** (model Latin nằm trong
/// APK) ⇒ chạy offline ngay từ lần đầu (R2). Chỉ nối text từng dòng + chuẩn hoá
/// `boundingBox` pixel → [ScanRect] 0..1 theo kích thước ảnh thật (FR-018).
/// ML Kit chỉ nhận đường dẫn file nên adapter tự ghi file tạm rồi xoá — việc
/// riêng của plugin, không rò rỉ lên màn xử lý.
class MlKitReceiptOcr implements ReceiptOcr {
  @override
  Future<List<ScanTextLine>> readText(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return const [];
    final width = decoded.width.toDouble();
    final height = decoded.height.toDouble();

    final temp = File(
      '${Directory.systemTemp.path}/sora_ocr_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await temp.writeAsBytes(bytes);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(temp.path),
      );
      return [
        for (final block in result.blocks)
          for (final line in block.lines)
            ScanTextLine(
              text: line.text,
              rect: ScanRect(
                left: _norm(line.boundingBox.left / width),
                top: _norm(line.boundingBox.top / height),
                right: _norm(line.boundingBox.right / width),
                bottom: _norm(line.boundingBox.bottom / height),
              ),
            ),
      ];
    } finally {
      await recognizer.close();
      try {
        await temp.delete();
      } catch (_) {
        // File tạm không xoá được cũng không ảnh hưởng luồng.
      }
    }
  }

  static double _norm(double v) => v.clamp(0.0, 1.0);
}
