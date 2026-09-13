import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Seam lưu ảnh hóa đơn vào kho đính kèm của app. Impl thật:
/// [LocalScanImageStore] (`<appDocuments>/receipts/<millis>.jpg`).
/// **Chỉ được gọi trong nhánh lưu** — huỷ giữa luồng không để lại file nào
/// (FR-036, R12).
abstract class ScanImageStore {
  /// Ghi ảnh [bytes] vào kho, trả đường dẫn tuyệt đối đã lưu.
  Future<String> save(Uint8List bytes);

  /// Xoá file tại [path] — dùng khi lưu giao dịch thất bại sau khi đã copy.
  Future<void> delete(String path);
}

/// Impl thật: copy ảnh vào `<appDocuments>/receipts/` (thư mục riêng của app,
/// không chia sẻ ra ngoài). Tên file = millis để không đè ảnh cũ.
class LocalScanImageStore implements ScanImageStore {
  @override
  Future<String> save(Uint8List bytes) async {
    final dir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'receipts'),
    );
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg'));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }
}
