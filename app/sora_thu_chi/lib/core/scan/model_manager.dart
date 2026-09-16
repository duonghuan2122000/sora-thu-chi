/// Dung lượng model Tier B (Gemma 4 E2B) hiển thị trên nút tải (mockup
/// `scan-10`). Con số chỉ để hiển thị — dung lượng thật do [ScanModelManager]
/// đọc từ file đã tải.
const int kGemmaModelBytes = 1800000000;

/// Seam tải/xoá model Tier B. Impl thật: `GemmaModelManager` (`flutter_gemma`);
/// test bơm fake để không chạm mạng/plugin.
abstract class ScanModelManager {
  /// Dung lượng model đang chiếm trên máy (byte); 0 = chưa tải.
  Future<int> installedBytes();

  /// Tải model, báo tiến trình 0..100. Trả `false` khi thất bại **hoặc** bị
  /// huỷ — tải bị ngắt thì không kích hoạt AI, vẫn ở Chế độ cơ bản (FR-012).
  Future<bool> download({void Function(int percent)? onProgress});

  /// Huỷ lần tải đang chạy (người dùng chọn "Dùng chế độ cơ bản" giữa chừng).
  void cancelDownload();

  /// Xoá model đã tải khỏi máy.
  Future<void> delete();
}
