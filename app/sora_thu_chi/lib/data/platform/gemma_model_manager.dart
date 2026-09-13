import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';

import '../../core/scan/model_manager.dart';

/// Nguồn model Tier B (Gemma 3n E2B, định dạng `.litertlm`).
///
/// ponytail: repo HuggingFace này **gated** ⇒ cần token để tải. Chưa chốt được
/// nguồn phân phối công khai cho bản phát hành (R18 ghi rõ phải kiểm chứng khi
/// thi công) — hiện để trống token nên lượt tải sẽ thất bại và người dùng ở lại
/// Chế độ cơ bản (đúng FR-012, không vỡ luồng). Chốt nguồn (tự host / repo không
/// gated) trước khi phát hành Tier B.
const String kGemmaModelUrl =
    'https://huggingface.co/litert-community/gemma-3n-E2B-it-litert-lm/'
    'resolve/main/gemma-3n-E2B-int4.litertlm';

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
      );
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
        fileType: ModelFileType.litertlm,
      ).fromNetwork(kGemmaModelUrl).withProgress((p) => onProgress?.call(p))
       .withCancelToken(token).install();
      return true;
    } catch (_) {
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
