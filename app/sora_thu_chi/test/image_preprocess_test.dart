import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:sora_thu_chi/core/scan/image_preprocess.dart';

void main() {
  test('ảnh nhỏ hơn maxSide → giữ nguyên kích thước', () async {
    final source = img.encodeJpg(img.Image(width: 800, height: 600));
    final out = img.decodeImage(await preprocessForOcr(source, maxSide: 2000));
    expect(out!.width, 800);
    expect(out.height, 600);
  });

  test('ảnh lớn → thu cạnh dài về đúng maxSide, giữ tỉ lệ', () async {
    final source = img.encodeJpg(img.Image(width: 4000, height: 3000));
    final out = img.decodeImage(await preprocessForOcr(source, maxSide: 2000));
    expect(out!.width, 2000);
    expect(out.height, 1500);
  });

  test('ảnh dọc lớn → thu theo chiều cao', () async {
    final source = img.encodeJpg(img.Image(width: 3000, height: 4000));
    final out = img.decodeImage(await preprocessForOcr(source, maxSide: 2000));
    expect(out!.height, 2000);
    expect(out.width, 1500);
  });

  test('đầu vào PNG → ra JPEG đọc lại được', () async {
    final source = img.encodePng(img.Image(width: 100, height: 50));
    final bytes = await preprocessForOcr(source, maxSide: 2000);
    // JPEG bắt đầu bằng SOI 0xFFD8.
    expect(bytes[0], 0xFF);
    expect(bytes[1], 0xD8);
    expect(img.decodeJpg(bytes), isNotNull);
  });

  test('dữ liệu không phải ảnh → trả nguyên đầu vào, không ném', () async {
    final garbage = Uint8List.fromList([1, 2, 3, 4]);
    expect(await preprocessForOcr(garbage), garbage);
  });
}
