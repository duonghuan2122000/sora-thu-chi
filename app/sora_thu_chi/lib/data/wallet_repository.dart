import '../core/category/category.dart';
import '../core/transaction/transaction.dart';
import '../core/wallet/wallet.dart';

/// Seam đọc/ghi ví & bút toán của ví — màn hình & controller chỉ phụ thuộc
/// interface này để test bơm fake (không cần sqlite native). Impl thật:
/// [DriftWalletRepository]. Transfer là thao tác domain **ví** chạm hai bảng
/// (`wallets` + `transactions`) trong một DB → đặt cùng một seam (research R6).
abstract class WalletRepository {
  /// Đọc toàn bộ ví, theo [Wallet.sortOrder] (ẩn không lọc — UI tự xử lý).
  Future<List<Wallet>> loadAll();

  /// Tạo ví mới từ [wallet] (id chưa dùng — repository gán) → trả ví đã lưu.
  Future<Wallet> insert(Wallet wallet);

  /// Cập nhật ví theo id; giữ nguyên trạng thái ẩn cũ (FR-012).
  Future<Wallet> update(Wallet wallet);

  /// Giao dịch của đúng ví [walletId], sắp mới nhất lên đầu (FR-008/014).
  /// Domain [Transaction] map 1-1 từ dòng `transactions` (không đổi model).
  Future<List<Transaction>> transactionsOf(int walletId);

  /// Toàn bộ giao dịch của thiết bị — mọi ví kể cả ví ẩn (giữ lịch sử, FR-004),
  /// sắp mới nhất lên đầu. Domain mang [Transaction.transferGroupId] để màn
  /// danh sách gộp 2 vế chuyển khoản thành 1 dòng (FR-007).
  Future<List<Transaction>> allTransactions();

  /// Ghi atomic một lần chuyển tiền (FR-012/015): trừ `balance` ví nguồn, cộng
  /// `balance` ví đích, ghi **2 dòng** `type=transfer` (vế nguồn `−amount`,
  /// vế đích `+amount`, cùng `date`/`note`) liên kết cùng `transfer_group_id`
  /// = id vế ghi trước (R7) — tất cả trong một `db.transaction()`.
  /// [amount] phải dương; validation nghiệp vụ do [transfer_rules]/UI đảm nhận,
  /// repository không tự chặn (T005).
  Future<void> performTransfer({
    required int fromWalletId,
    required int toWalletId,
    required int amount,
    required DateTime date,
    String note = '',
  });

  /// Danh mục **đang hoạt động** (`!isHidden`) thuộc [type] — gồm cha & con;
  /// UI tự tách cha-con bằng [Category.parentId]. Sắp theo sortOrder. (R3/R5)
  Future<List<Category>> categories({required CategoryType type});

  /// Ghi atomic một giao dịch **thu/chi** mới (FR-012/SC-003): bù `balance` ví
  /// (`income` +, `expense` −) và insert 1 dòng `transactions` có dấu theo loại
  /// (`income` `+x`, `expense` `−x`), `category_id = category.id`,
  /// `category = category.name`, trong một `db.transaction()` — không lệch phía.
  /// Đầu vào hợp lệ: [type] income/expense, [amount] > 0, `category.type` khớp
  /// [type], `category.id` > 0. Giao dịch mới để trống transferGroupId/tags/
  /// receiptImage/location (R3).
  Future<void> addTransaction({
    required int walletId,
    required TxnType type,
    required int amount,
    required Category category,
    required DateTime date,
    String note = '',
  });
}
