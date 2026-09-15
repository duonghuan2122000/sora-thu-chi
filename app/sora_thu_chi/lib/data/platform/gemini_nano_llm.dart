import 'dart:typed_data';

import '../../core/scan/llm_extractor.dart';
import '../../core/scan/scan_result.dart';
import 'device_probe_platform.dart';

/// Tier A — Gemini Nano (model do AICore hệ thống quản lý, **không** tải về
/// app), gọi qua kênh native dùng chung `sora_thu_chi/device_probe` (R18).
///
/// Đọc ảnh trực tiếp qua prompt đa phương thức (PBI 37) — [supportsImage] báo
/// cho [LlmExtractor] biết để gửi ảnh thay vì nhét văn bản OCR vào prompt.
///
/// Mọi lỗi kênh (máy không hỗ trợ, model chưa sẵn sàng, engine bận) đều **ném**
/// để [LlmExtractor] bắt và rơi về bộ luật — người dùng không bao giờ kẹt
/// (FR-011/SC-009).
class GeminiNanoLlm implements ScanLlm {
  const GeminiNanoLlm();

  @override
  ScanEngine get engine => ScanEngine.geminiNano;

  @override
  bool get supportsImage => true;

  @override
  Future<String> generate(String prompt, {Uint8List? image}) async {
    final text = await kDeviceProbeChannel.invokeMethod<String>(
      'genAiGenerate',
      {'prompt': prompt, 'image': ?image},
    );
    if (text == null || text.trim().isEmpty) {
      throw StateError('Gemini Nano không trả về nội dung');
    }
    return text;
  }
}
