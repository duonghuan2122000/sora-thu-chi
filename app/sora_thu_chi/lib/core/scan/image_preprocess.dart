import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Tiền xử lý ảnh trước khi đưa vào OCR (FR-017): sửa chiều theo EXIF → thu nhỏ
/// cạnh dài về [maxSide] → tăng tương phản + bỏ màu → nén JPEG.
///
/// Hàm **thuần Dart** (không plugin) nên gọi được qua `compute()` từ màn xử lý
/// để không chặn UI.
///
/// ponytail: **không** dò biên/crop hóa đơn — theo R4 nhánh "dùng nguyên ảnh"
/// mà FR-017 cho phép; thêm Sobel/edge-detect chỉ khi đo được lợi ích thật.
Future<Uint8List> preprocessForOcr(Uint8List input, {int maxSide = 2000}) async {
  // Ảnh hỏng/không phải ảnh → trả nguyên đầu vào để tầng OCR tự báo "không đọc
  // được" (FR-020), không làm sập luồng quét.
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(input);
  } catch (_) {
    return input;
  }
  if (decoded == null) return input;

  var image = img.bakeOrientation(decoded);
  final longest = image.width > image.height ? image.width : image.height;
  if (longest > maxSide) {
    image = image.width >= image.height
        ? img.copyResize(image, width: maxSide)
        : img.copyResize(image, height: maxSide);
  }
  image = img.adjustColor(image, contrast: 1.15, saturation: 0);
  return img.encodeJpg(image, quality: 88);
}
