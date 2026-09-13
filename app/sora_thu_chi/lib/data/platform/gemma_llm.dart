import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';

import '../../core/scan/llm_extractor.dart';
import '../../core/scan/scan_result.dart';

/// Tier B — Gemma 3n E2B chạy trên máy qua `flutter_gemma` (LiteRT-LM, R18).
///
/// Model đã tải do `GemmaModelManager` quản lý; ở đây chỉ mở một phiên cho mỗi
/// lần quét (FR-010) và đóng ngay sau khi lấy kết quả. Mọi lỗi (chưa tải model,
/// hết RAM, engine bận) đều **ném** để [LlmExtractor] rơi về bộ luật (FR-011).
class GemmaLlm implements ScanLlm {
  GemmaLlm();

  bool _initialized = false;

  @override
  ScanEngine get engine => ScanEngine.gemma3nE2b;

  @override
  Future<String> generate(String prompt) async {
    await _ensureEngine();
    final model = await FlutterGemma.getActiveModel(maxTokens: 2048);
    final session = await model.createSession(maxOutputTokens: 512);
    try {
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      final response = await session.getResponse();
      if (response.trim().isEmpty) {
        throw StateError('Gemma 3n không trả về nội dung');
      }
      return response;
    } finally {
      await session.close();
    }
  }

  /// `initialize` chỉ được gọi một lần cho cả tiến trình (đăng ký engine).
  Future<void> _ensureEngine() async {
    if (_initialized) return;
    await FlutterGemma.initialize(inferenceEngines: [LiteRtLmEngine()]);
    _initialized = true;
  }
}
