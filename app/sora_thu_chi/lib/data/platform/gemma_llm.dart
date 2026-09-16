import 'dart:typed_data';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';

import '../../core/scan/llm_extractor.dart';
import '../../core/scan/scan_result.dart';
import 'gemma_model_manager.dart' show kHuggingFaceToken;

/// Tier B — Gemma 4 E2B chạy trên máy qua `flutter_gemma` (LiteRT-LM, R18).
///
/// Model đã tải do `GemmaModelManager` quản lý; ở đây chỉ mở một phiên cho mỗi
/// lần quét (FR-010) và đóng ngay sau khi lấy kết quả. Mọi lỗi (chưa tải model,
/// hết RAM, engine bận) đều **ném** để [LlmExtractor] rơi về bộ luật (FR-011).
///
/// Gemma 4 E2B đọc ảnh trực tiếp (đa phương thức, giống Tier A ở PBI 37) ⇒
/// [supportsImage] `true` — [LlmExtractor] gửi ảnh kèm prompt, bỏ văn bản OCR.
/// `getActiveModel`/`createSession` cần bật cờ vision tương ứng
/// (`supportImage`/`enableVisionModality`), mặc định tắt để phiên chat thuần
/// văn bản không tốn bộ nhớ nạp encoder ảnh khi không cần.
class GemmaLlm implements ScanLlm {
  GemmaLlm();

  bool _initialized = false;

  @override
  ScanEngine get engine => ScanEngine.gemma3nE2b;

  @override
  bool get supportsImage => true;

  @override
  Future<String> generate(String prompt, {Uint8List? image}) async {
    await _ensureEngine();
    final model = await FlutterGemma.getActiveModel(
      maxTokens: 2048,
      supportImage: image != null,
      maxNumImages: image != null ? 1 : null,
    );
    final session = await model.createSession(
      maxOutputTokens: 512,
      enableVisionModality: image != null,
    );
    try {
      final message = image != null
          ? Message.withImage(text: prompt, imageBytes: image, isUser: true)
          : Message.text(text: prompt, isUser: true);
      await session.addQueryChunk(message);
      final response = await session.getResponse();
      if (response.trim().isEmpty) {
        throw StateError('Gemma 4 không trả về nội dung');
      }
      return response;
    } finally {
      await session.close();
    }
  }

  /// `initialize` chỉ được gọi một lần cho cả tiến trình (đăng ký engine).
  Future<void> _ensureEngine() async {
    if (_initialized) return;
    await FlutterGemma.initialize(
      inferenceEngines: [LiteRtLmEngine()],
      huggingFaceToken: kHuggingFaceToken,
    );
    _initialized = true;
  }
}
