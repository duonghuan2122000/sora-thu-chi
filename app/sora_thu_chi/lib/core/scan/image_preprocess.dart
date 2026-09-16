import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Tiền xử lý ảnh trước khi đưa vào OCR (FR-017): sửa chiều theo EXIF → thu nhỏ
/// cạnh dài về [maxSide] → tăng tương phản (+ bỏ màu nếu [grayscale]) → nén
/// JPEG.
///
/// [grayscale] mặc định `true` cho tầng OCR văn bản (ML Kit không cần màu).
/// Tier A (PBI 37) đọc ảnh trực tiếp bằng model đa phương thức — model **thấy**
/// màu/layout thật như ảnh gốc (khác OCR), bỏ màu làm sai lệch so với ảnh gốc
/// mà không đổi lại ích gì cho model ⇒ gọi với `grayscale: false` cho nhánh này
/// (`scan_processing_screen.dart`).
///
/// Hàm **thuần Dart** (không plugin) nên gọi được qua `compute()` từ màn xử lý
/// để không chặn UI.
///
/// ponytail: **không** dò biên/crop hóa đơn — theo R4 nhánh "dùng nguyên ảnh"
/// mà FR-017 cho phép; thêm Sobel/edge-detect chỉ khi đo được lợi ích thật.
Future<Uint8List> preprocessForOcr(
  Uint8List input, {
  int maxSide = 2000,
  bool grayscale = true,
}) async {
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
  image = img.adjustColor(image, contrast: 1.15, saturation: grayscale ? 0 : 1);
  return img.encodeJpg(image, quality: 88);
}

/// Tear-off cho `compute()` (yêu cầu hàm top-level, không truyền được tham số
/// đặt tên qua `compute(preprocessForOcr, bytes)`) — ảnh giữ màu cho model đa
/// phương thức đọc trực tiếp (Tier A, PBI 37).
Future<Uint8List> preprocessForLlmImage(Uint8List input) =>
    preprocessForOcr(input, grayscale: false);
