import 'package:sora_thu_chi/core/scan/model_manager.dart';

/// Fake [ScanModelManager]: tải xong ngay (hoặc theo [downloadSucceeds]), ghi lại
/// số lần gọi để assert "tải bị ngắt thì không kích hoạt AI" (FR-012).
class FakeScanModelManager implements ScanModelManager {
  FakeScanModelManager({
    this.installed = 0,
    this.downloadSucceeds = true,
    this.progressSteps = const [50, 100],
  });

  int installed;
  bool downloadSucceeds;
  final List<int> progressSteps;

  int downloadCount = 0;
  int deleteCount = 0;
  bool cancelled = false;

  @override
  Future<int> installedBytes() async => installed;

  @override
  Future<bool> download({void Function(int percent)? onProgress}) async {
    downloadCount++;
    for (final step in progressSteps) {
      if (cancelled) return false;
      onProgress?.call(step);
    }
    if (!downloadSucceeds) return false;
    installed = kGemmaModelBytes;
    return true;
  }

  @override
  void cancelDownload() => cancelled = true;

  @override
  Future<void> delete() async {
    deleteCount++;
    installed = 0;
  }
}
