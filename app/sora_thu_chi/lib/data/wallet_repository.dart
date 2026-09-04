import '../core/wallet/wallet.dart';

/// Seam đọc/ghi ví — màn hình & controller chỉ phụ thuộc interface này để test
/// bơm fake (không cần sqlite native). Impl thật: [DriftWalletRepository].
abstract class WalletRepository {
  /// Đọc toàn bộ ví, theo [Wallet.sortOrder] (ẩn không lọc — UI tự xử lý).
  Future<List<Wallet>> loadAll();

  /// Tạo ví mới từ [wallet] (id chưa dùng — repository gán) → trả ví đã lưu.
  Future<Wallet> insert(Wallet wallet);

  /// Cập nhật ví theo id; giữ nguyên trạng thái ẩn cũ (FR-012).
  Future<Wallet> update(Wallet wallet);
}
