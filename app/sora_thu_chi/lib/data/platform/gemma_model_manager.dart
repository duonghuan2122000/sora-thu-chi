import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';

import '../../core/scan/model_manager.dart';
import 'hf_token_local.dart';

/// Nguồn model Tier B, định dạng `.litertlm`.
///
/// Model thật hiện dùng là **Gemma 4 E2B** (`litert-community/gemma-4-E2B-it-litert-lm`,
/// **không gated** — xác minh qua HF API `siblings` 2026-09, không cần token).
/// File `gemma-4-E2B-it.litertlm` là bản chung (không khoá riêng GPU/chip nào)
/// — repo còn nhiều biến thể tối ưu riêng chip (Qualcomm/Tensor/Intel/Web)
/// nhưng bản chung chạy được trên mọi máy, đơn giản hơn là dò chip để chọn.
///
/// ponytail: hằng số [kHuggingFaceToken] giữ lại (không xoá) — model gated
/// trước đó (Gemma 3n E2B, `google/...`) cần nó; nếu quay lại nguồn gated,
/// điền `hf_token_local.dart` là dùng được ngay, không phải nối dây lại.
const String kGemmaModelUrl =
    'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/'
    'resolve/main/gemma-4-E2B-it.litertlm';

String? get kHuggingFaceToken => hfTokenLocal.isEmpty ? null : hfTokenLocal;

/// Tải/xoá model Tier B bằng `flutter_gemma` (LiteRT-LM, R18).
///
/// Mọi lỗi (mạng, hết dung lượng, token thiếu, người dùng huỷ) → trả `false` và
/// **không** bật AI: luồng quét vẫn ở Chế độ cơ bản (FR-012).
class GemmaModelManager implements ScanModelManager {
  CancelToken? _cancelToken;

  @override
  Future<int> installedBytes() async {
    try {
      final stats = await FlutterGemma.getStorageInfo();
      return stats.totalSizeBytes;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<bool> download({void Function(int percent)? onProgress}) async {
    final token = CancelToken();
    _cancelToken = token;
    try {
      await FlutterGemma.initialize(
        inferenceEngines: [LiteRtLmEngine()],
        huggingFaceToken: kHuggingFaceToken,
      );
      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromNetwork(kGemmaModelUrl).withProgress((p) => onProgress?.call(p))
       .withCancelToken(token).install();
      return true;
    } catch (error, stack) {
      debugPrint('[Scan][GemmaDownload] lỗi: $error\n$stack');
      return false;
    } finally {
      _cancelToken = null;
    }
  }

  @override
  void cancelDownload() => _cancelToken?.cancel('Người dùng chọn Chế độ cơ bản');

  @override
  Future<void> delete() async {
    try {
      final installed = await FlutterGemma.listInstalledModels();
      for (final id in installed) {
        await FlutterGemma.uninstallModel(id);
      }
      await FlutterGemma.clearActiveInferenceIdentity();
    } catch (_) {
      // Xoá lỗi không chặn UI — lần đọc dung lượng sau phản ánh thực tế.
    }
  }
}
